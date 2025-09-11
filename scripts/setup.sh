#!/bin/bash
# AI Infrastructure Stack - Complete Setup Script
# This script automates the complete deployment of the infrastructure

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
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
    log "Checking prerequisites..."
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        error "Docker is not installed. Please install Docker first."
    fi
    
    # Check Docker Compose
    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        error "Docker Compose is not installed. Please install Docker Compose first."
    fi
    
    # Check if running as root (needed for some operations)
    if [[ $EUID -eq 0 ]]; then
        warn "Running as root. Consider using a non-root user with Docker permissions."
    fi
    
    log "Prerequisites check completed ✅"
}

# Setup environment configuration
setup_environment() {
    log "Setting up environment configuration..."
    
    if [ ! -f "docker-compose/.env" ]; then
        if [ -f "docker-compose/.env.example" ]; then
            cp docker-compose/.env.example docker-compose/.env
            log "Created .env file from .env.example"
            warn "Please edit docker-compose/.env with your actual configuration values before continuing."
            read -p "Press Enter after configuring .env file..."
        else
            error ".env.example file not found. Please ensure you have the complete repository."
        fi
    else
        log ".env file already exists ✅"
    fi
}

# Create necessary directories
create_directories() {
    log "Creating necessary directories..."
    
    # Create data directories
    mkdir -p data/{leann,n8n,obsidian,traefik-acme,portainer}
    mkdir -p logs/{leann,n8n,monitoring}
    
    # Set permissions
    chmod 755 data logs
    chmod -R 755 data/* logs/*
    
    log "Directories created ✅"
}

# Deploy infrastructure services
deploy_infrastructure() {
    log "Deploying infrastructure services..."
    
    cd docker-compose
    
    # Pull latest images
    log "Pulling Docker images..."
    docker compose pull
    
    # Start services
    log "Starting services..."
    docker compose up -d
    
    # Wait for services to be ready
    log "Waiting for services to start..."
    sleep 30
    
    cd ..
    log "Infrastructure deployment completed ✅"
}

# Verify service health
verify_services() {
    log "Verifying service health..."
    
    local services=("traefik" "n8n" "obsidian" "portainer")
    
    for service in "${services[@]}"; do
        if docker ps | grep -q "$service"; then
            log "$service is running ✅"
        else
            warn "$service is not running ❌"
        fi
    done
    
    # Check Traefik dashboard
    if curl -s http://localhost:8080 > /dev/null; then
        log "Traefik dashboard accessible ✅"
    else
        warn "Traefik dashboard not accessible ❌"
    fi
}

# Setup LEANN system
setup_leann() {
    log "Setting up LEANN vector database..."
    
    # Check if LEANN is available
    if [ -d "leann-system" ]; then
        log "Installing LEANN dependencies..."
        
        # Setup LEANN API
        cd leann-system/api
        if [ -f "package.json" ]; then
            npm install
            log "LEANN API dependencies installed ✅"
        fi
        cd ../..
        
        # Make scripts executable
        chmod +x leann-system/scripts/*.sh leann-system/scripts/*.py
        
        log "LEANN system setup completed ✅"
    else
        warn "LEANN system directory not found. Skipping LEANN setup."
    fi
}

# Import AI agents
import_ai_agents() {
    log "Importing AI agents to n8n..."
    
    if [ -d "ai-agents/workflows" ]; then
        log "AI agent workflows found. Please import them manually using n8n interface."
        log "Workflow files location: ai-agents/workflows/"
        log "Deployment guide: ai-agents/deployment-guide.md"
    else
        warn "AI agents directory not found. Skipping agents import."
    fi
}

# Setup monitoring
setup_monitoring() {
    log "Setting up monitoring stack..."
    
    # Check if monitoring stack is running
    if docker ps | grep -q "prometheus"; then
        log "Prometheus is running ✅"
    else
        log "Starting monitoring stack..."
        cd docker-compose
        docker compose up -d prometheus grafana alertmanager
        cd ..
    fi
    
    log "Monitoring stack setup completed ✅"
}

# Display final information
show_completion_info() {
    log "🎉 AI Infrastructure Stack deployment completed!"
    echo
    echo -e "${BLUE}📋 Service Access Information:${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🌐 Traefik Dashboard: http://localhost:8080"
    echo "🤖 n8n Workflows: http://localhost:5678"
    echo "📚 Obsidian: http://localhost:3000"  
    echo "📊 Grafana: http://localhost:3001"
    echo "🐳 Portainer: http://localhost:9000"
    echo
    echo -e "${BLUE}🔧 Next Steps:${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "1. Configure your domains in .env file for SSL"
    echo "2. Import AI agents using deployment guide"
    echo "3. Setup LEANN vector database with your content"
    echo "4. Configure monitoring dashboards"
    echo
    echo -e "${BLUE}📖 Documentation:${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "• Complete Guide: documentation/CLAUDE.md"
    echo "• Architecture: documentation/architecture/ARCHITECTURE.md"
    echo "• AI Agents: ai-agents/deployment-guide.md"
    echo "• LEANN Setup: leann-system/README-leann.md"
    echo
    echo -e "${GREEN}✨ Your AI Infrastructure Stack is ready!${NC}"
}

# Main execution
main() {
    log "🚀 Starting AI Infrastructure Stack deployment..."
    echo
    
    check_prerequisites
    setup_environment
    create_directories
    deploy_infrastructure
    verify_services
    setup_leann
    import_ai_agents
    setup_monitoring
    show_completion_info
}

# Execute main function
main "$@"