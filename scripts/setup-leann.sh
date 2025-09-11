#!/bin/bash
# AI Infrastructure Stack - LEANN Setup Script
# Complete setup for LEANN Vector Database with Redis cache

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING:${NC} $1"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR:${NC} $1"
    exit 1
}

# Check prerequisites
check_prerequisites() {
    log "Checking LEANN prerequisites..."
    
    # Check if OpenAI API key is set
    if [ -z "$OPENAI_API_KEY" ]; then
        error "OPENAI_API_KEY environment variable is not set. Please configure your OpenAI API key."
    fi
    
    # Check if uv is installed
    if ! command -v uv &> /dev/null; then
        log "Installing uv package manager..."
        curl -LsSf https://astral.sh/uv/install.sh | sh
        source ~/.bashrc
    fi
    
    log "Prerequisites check completed ✅"
}

# Install LEANN Core
install_leann() {
    log "Installing LEANN Core..."
    
    # Install LEANN via uv
    uv tool install leann-core
    
    # Verify installation
    if command -v leann &> /dev/null; then
        local version=$(leann --version)
        log "LEANN installed successfully: $version ✅"
    else
        error "LEANN installation failed"
    fi
}

# Setup LEANN HTTP API
setup_leann_api() {
    log "Setting up LEANN HTTP API..."
    
    # Create LEANN API directory
    mkdir -p /opt/leann
    
    # Create LEANN API service script
    cat > /opt/leann/leann_http_api.py << 'EOF'
#!/usr/bin/env python3
import asyncio
import json
import os
import sys
import time
from contextlib import asynccontextmanager
from typing import Optional

import redis
from fastapi import FastAPI, HTTPException, Depends, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from pydantic import BaseModel
import uvicorn

# LEANN imports
sys.path.append('/root/.local/share/uv/tools/leann-core/lib/python3.11/site-packages')
from leann_backend_hnsw import HNSWBackend

# Configuration
REDIS_URL = os.getenv('REDIS_URL', 'redis://localhost:6379/0')
API_TOKEN = os.getenv('LEANN_API_TOKEN', 'leann_api_2025')
LEANN_DATA_PATH = os.getenv('LEANN_DATA_PATH', '/opt/leann/data')

# Redis client
redis_client = None
leann_backend = None

# Security
security = HTTPBearer()

class SearchRequest(BaseModel):
    query: str
    index: str = "myvault"
    top_k: int = 5
    use_cache: bool = True

class HealthResponse(BaseModel):
    status: str
    timestamp: float
    redis_connected: bool
    leann_ready: bool

@asynccontextmanager
async def lifespan(app: FastAPI):
    global redis_client, leann_backend
    
    # Initialize Redis
    try:
        redis_client = redis.Redis.from_url(REDIS_URL, decode_responses=True)
        redis_client.ping()
        print("✅ Redis connected")
    except Exception as e:
        print(f"❌ Redis connection failed: {e}")
        redis_client = None
    
    # Initialize LEANN backend
    try:
        leann_backend = HNSWBackend(data_path=LEANN_DATA_PATH)
        print("✅ LEANN backend initialized")
    except Exception as e:
        print(f"❌ LEANN backend initialization failed: {e}")
        leann_backend = None
    
    yield
    
    # Cleanup
    if redis_client:
        redis_client.close()

app = FastAPI(
    title="LEANN HTTP API",
    description="Semantic search API with Redis caching",
    version="1.0.0",
    lifespan=lifespan
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

def verify_token(credentials: HTTPAuthorizationCredentials = Depends(security)):
    if credentials.credentials != API_TOKEN:
        raise HTTPException(status_code=401, detail="Invalid API token")
    return credentials

@app.get("/health", response_model=HealthResponse)
async def health_check():
    return HealthResponse(
        status="healthy",
        timestamp=time.time(),
        redis_connected=redis_client is not None and redis_client.ping(),
        leann_ready=leann_backend is not None
    )

@app.post("/search")
async def search(request: SearchRequest, credentials: HTTPAuthorizationCredentials = Depends(verify_token)):
    if not leann_backend:
        raise HTTPException(status_code=503, detail="LEANN backend not available")
    
    # Generate cache key
    cache_key = f"search:{hash(request.query + request.index + str(request.top_k))}"
    
    # Try cache first
    if request.use_cache and redis_client:
        try:
            cached_result = redis_client.get(cache_key)
            if cached_result:
                return {"results": json.loads(cached_result), "cached": True}
        except Exception as e:
            print(f"Cache read error: {e}")
    
    # Perform search
    try:
        results = leann_backend.search(
            query=request.query,
            index=request.index,
            top_k=request.top_k
        )
        
        # Cache results
        if request.use_cache and redis_client:
            try:
                redis_client.setex(cache_key, 3600, json.dumps(results))  # 1 hour TTL
            except Exception as e:
                print(f"Cache write error: {e}")
        
        return {"results": results, "cached": False}
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Search failed: {str(e)}")

@app.get("/cache/stats")
async def cache_stats(credentials: HTTPAuthorizationCredentials = Depends(verify_token)):
    if not redis_client:
        raise HTTPException(status_code=503, detail="Redis not available")
    
    try:
        info = redis_client.info()
        return {
            "connected_clients": info.get("connected_clients"),
            "used_memory_human": info.get("used_memory_human"),
            "keyspace_hits": info.get("keyspace_hits"),
            "keyspace_misses": info.get("keyspace_misses"),
            "hit_rate": info.get("keyspace_hits", 0) / max(info.get("keyspace_hits", 0) + info.get("keyspace_misses", 1), 1)
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Stats failed: {str(e)}")

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=3001)
EOF

    chmod +x /opt/leann/leann_http_api.py
    
    log "LEANN HTTP API setup completed ✅"
}

# Create systemd service
create_systemd_service() {
    log "Creating LEANN HTTP API systemd service..."
    
    cat > /etc/systemd/system/leann-api.service << EOF
[Unit]
Description=LEANN HTTP API Service
After=network.target redis.service
Wants=redis.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/leann
Environment=PYTHONPATH=/root/.local/share/uv/tools/leann-core/lib/python3.11/site-packages
Environment=OPENAI_API_KEY=${OPENAI_API_KEY}
Environment=LEANN_API_TOKEN=leann_api_2025
Environment=LEANN_DATA_PATH=/opt/leann/data
Environment=REDIS_URL=redis://localhost:6379/0
ExecStart=/root/.local/share/uv/tools/leann-core/bin/python /opt/leann/leann_http_api.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable leann-api
    
    log "Systemd service created ✅"
}

# Build initial LEANN index
build_initial_index() {
    log "Building initial LEANN index..."
    
    # Check if Obsidian vault exists
    local vault_path="/var/lib/docker/volumes/docker-compose_obsidian-vaults/_data/MyVault"
    if [ ! -d "$vault_path" ]; then
        warn "Obsidian vault not found at $vault_path. Please ensure Obsidian is running."
        return
    fi
    
    # Create LEANN data directory
    mkdir -p /opt/leann/data
    
    # Build index
    log "Building LEANN index from Obsidian vault..."
    cd /opt/leann
    
    leann build myvault \
        --docs "$vault_path" \
        --file-types .md \
        --embedding-mode openai \
        --embedding-model text-embedding-3-small \
        --force
    
    log "LEANN index built successfully ✅"
}

# Setup auto-reindexing
setup_auto_reindex() {
    log "Setting up LEANN auto-reindexing..."
    
    # Create auto-reindex script
    cat > /opt/leann/leann_auto_reindex.py << 'EOF'
#!/usr/bin/env python3
import os
import sys
import time
import hashlib
import json
import logging
import subprocess
from pathlib import Path
from datetime import datetime

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('/var/log/leann-auto-reindex.log'),
        logging.StreamHandler()
    ]
)

VAULT_PATH = "/var/lib/docker/volumes/docker-compose_obsidian-vaults/_data/MyVault"
LEANN_DATA_PATH = "/opt/leann/data"
STATE_FILE = "/opt/leann/reindex_state.json"
CHECK_INTERVAL = 300  # 5 minutes
MIN_REINDEX_INTERVAL = 2700  # 45 minutes

def get_content_hash():
    """Generate hash of all markdown files in vault"""
    hasher = hashlib.md5()
    
    for md_file in sorted(Path(VAULT_PATH).rglob("*.md")):
        try:
            with open(md_file, 'rb') as f:
                hasher.update(f.read())
        except Exception as e:
            logging.warning(f"Could not read {md_file}: {e}")
    
    return hasher.hexdigest()

def load_state():
    """Load previous state"""
    if os.path.exists(STATE_FILE):
        try:
            with open(STATE_FILE, 'r') as f:
                return json.load(f)
        except Exception as e:
            logging.warning(f"Could not load state: {e}")
    
    return {
        "last_hash": "",
        "last_reindex": 0,
        "reindex_count": 0
    }

def save_state(state):
    """Save current state"""
    try:
        with open(STATE_FILE, 'w') as f:
            json.dump(state, f, indent=2)
    except Exception as e:
        logging.error(f"Could not save state: {e}")

def reindex_leann():
    """Perform LEANN reindexing"""
    try:
        cmd = [
            "leann", "build", "myvault",
            "--docs", VAULT_PATH,
            "--file-types", ".md",
            "--embedding-mode", "openai",
            "--embedding-model", "text-embedding-3-small",
            "--force"
        ]
        
        result = subprocess.run(
            cmd,
            cwd="/opt/leann",
            capture_output=True,
            text=True,
            timeout=300
        )
        
        if result.returncode == 0:
            logging.info("✅ Reindexação LEANN concluída com sucesso")
            
            # Try to clear Redis cache
            try:
                import redis
                r = redis.Redis(host='localhost', port=6379, db=0)
                r.flushdb()
                logging.info("🗑️ Cache Redis limpo com sucesso")
            except Exception as e:
                logging.warning(f"⚠️ Erro ao limpar cache Redis: {e}")
            
            return True
        else:
            logging.error(f"❌ Reindexação LEANN falhou: {result.stderr}")
            return False
            
    except Exception as e:
        logging.error(f"❌ Erro na reindexação LEANN: {e}")
        return False

def main():
    logging.info("🚀 Iniciando monitoramento LEANN auto-reindex")
    logging.info(f"📁 Monitorando: {VAULT_PATH}")
    logging.info(f"⏰ Intervalo de verificação: {CHECK_INTERVAL}s")
    
    while True:
        try:
            # Count markdown files
            md_files = list(Path(VAULT_PATH).rglob("*.md"))
            logging.info(f"📊 Verificação: {len(md_files)} arquivos .md encontrados")
            
            # Get current content hash
            current_hash = get_content_hash()
            
            # Load previous state
            state = load_state()
            
            # Check if reindexing is needed
            content_changed = current_hash != state["last_hash"]
            time_since_reindex = time.time() - state["last_reindex"]
            min_interval_passed = time_since_reindex >= MIN_REINDEX_INTERVAL
            
            if content_changed and min_interval_passed:
                logging.info("🔄 Reindexação necessária: Conteúdo modificado")
                logging.info("🔄 Iniciando reindexação LEANN...")
                
                if reindex_leann():
                    state["last_hash"] = current_hash
                    state["last_reindex"] = time.time()
                    state["reindex_count"] += 1
                    save_state(state)
                    
                    logging.info(f"✅ Reindexação #{state['reindex_count']} concluída")
                else:
                    logging.error("❌ Reindexação falhou")
                    
            elif content_changed and not min_interval_passed:
                remaining_time = (MIN_REINDEX_INTERVAL - time_since_reindex) / 60
                logging.info(f"⏳ Aguardando intervalo mínimo: {remaining_time:.1f} min")
            else:
                logging.info("✅ Nenhuma mudança detectada")
            
            logging.info(f"😴 Próxima verificação em {CHECK_INTERVAL/60:.1f} min")
            time.sleep(CHECK_INTERVAL)
            
        except KeyboardInterrupt:
            logging.info("🛑 Parando monitoramento auto-reindex")
            break
        except Exception as e:
            logging.error(f"❌ Erro no monitoramento: {e}")
            time.sleep(60)

if __name__ == "__main__":
    main()
EOF

    chmod +x /opt/leann/leann_auto_reindex.py
    
    # Create systemd service for auto-reindex
    cat > /etc/systemd/system/leann-auto-reindex.service << EOF
[Unit]
Description=LEANN Auto-Reindex Service
After=network.target leann-api.service
Wants=leann-api.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/leann
Environment=PYTHONPATH=/root/.local/share/uv/tools/leann-core/lib/python3.11/site-packages
Environment=OPENAI_API_KEY=${OPENAI_API_KEY}
ExecStart=/root/.local/share/uv/tools/leann-core/bin/python /opt/leann/leann_auto_reindex.py
Restart=always
RestartSec=30

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable leann-auto-reindex
    
    log "Auto-reindexing setup completed ✅"
}

# Start services
start_services() {
    log "Starting LEANN services..."
    
    systemctl start leann-api
    systemctl start leann-auto-reindex
    
    # Wait for services to start
    sleep 10
    
    # Check status
    if systemctl is-active --quiet leann-api; then
        log "LEANN API service started ✅"
    else
        warn "LEANN API service failed to start"
    fi
    
    if systemctl is-active --quiet leann-auto-reindex; then
        log "LEANN auto-reindex service started ✅"
    else
        warn "LEANN auto-reindex service failed to start"
    fi
}

# Test LEANN installation
test_leann() {
    log "Testing LEANN installation..."
    
    # Wait for API to be ready
    sleep 5
    
    # Test health endpoint
    if curl -s http://localhost:3001/health > /dev/null; then
        local health_response=$(curl -s http://localhost:3001/health)
        if echo "$health_response" | grep -q '"status":"healthy"'; then
            log "LEANN API health check passed ✅"
        else
            warn "LEANN API health check failed"
        fi
    else
        warn "LEANN API not accessible"
    fi
    
    # Test search (if index exists)
    if [ -d "/opt/leann/data/myvault" ]; then
        log "Testing LEANN search..."
        local search_result=$(curl -s -X POST http://localhost:3001/search \
            -H "Authorization: Bearer leann_api_2025" \
            -H "Content-Type: application/json" \
            -d '{"query": "test", "index": "myvault", "top_k": 1}' 2>/dev/null || echo "")
        
        if echo "$search_result" | grep -q "results"; then
            log "LEANN search test passed ✅"
        else
            warn "LEANN search test failed"
        fi
    fi
}

# Display completion information
show_completion_info() {
    log "🎉 LEANN setup completed!"
    echo
    echo -e "${BLUE}📋 LEANN System Information:${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🌐 API Endpoint: http://localhost:3001"
    echo "🔑 API Token: leann_api_2025"
    echo "📊 Health Check: curl http://localhost:3001/health"
    echo "🔍 Search Example: curl -X POST http://localhost:3001/search -H 'Authorization: Bearer leann_api_2025' -H 'Content-Type: application/json' -d '{\"query\": \"test\", \"index\": \"myvault\"}'"
    echo
    echo -e "${BLUE}🔧 Service Management:${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "• LEANN API: systemctl [start|stop|restart|status] leann-api"
    echo "• Auto-reindex: systemctl [start|stop|restart|status] leann-auto-reindex"
    echo "• View API logs: journalctl -u leann-api -f"
    echo "• View reindex logs: tail -f /var/log/leann-auto-reindex.log"
    echo
    echo -e "${GREEN}✨ LEANN Vector Database is ready for semantic search!${NC}"
}

# Main execution
main() {
    log "🚀 Starting LEANN setup..."
    echo
    
    check_prerequisites
    install_leann
    setup_leann_api
    create_systemd_service
    build_initial_index
    setup_auto_reindex
    start_services
    test_leann
    show_completion_info
}

# Execute main function
main "$@"