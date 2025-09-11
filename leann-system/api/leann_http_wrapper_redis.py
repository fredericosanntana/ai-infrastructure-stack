#!/usr/bin/env python3
"""
LEANN HTTP API Wrapper with Redis Cache
Provides REST API endpoints for LEANN semantic search functionality with Redis caching
"""

import os
import sys
import json
import subprocess
import logging
import hashlib
import redis
from datetime import datetime, timedelta
from flask import Flask, request, jsonify
from functools import wraps
import secrets

app = Flask(__name__)

# Configuration
LEANN_COMMAND = "leann"
DEFAULT_INDEX = "myvault"
API_TOKEN = os.getenv("LEANN_API_TOKEN", "leann_api_2025")
PORT = int(os.getenv("LEANN_API_PORT", "3001"))
HOST = os.getenv("LEANN_API_HOST", "0.0.0.0")

# Redis Configuration
REDIS_HOST = "billionmail-redis-billionmail-1"
REDIS_PORT = 6379
REDIS_PASSWORD = "zKLnZQr3riFpcS2lEy3MOtfncztaCGKp"  # From BillionMail .env
REDIS_DB = 1  # Use DB 1 to avoid conflict with BillionMail (uses DB 0)
CACHE_TTL_SECONDS = 3600  # 1 hour cache
CACHE_ENABLED = os.getenv("REDIS_CACHE_ENABLED", "true").lower() == "true"

# Logging setup
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('/var/log/leann-api.log'),
        logging.StreamHandler(sys.stdout)
    ]
)
logger = logging.getLogger(__name__)

# Initialize Redis connection
redis_client = None
if CACHE_ENABLED:
    try:
        redis_client = redis.Redis(
            host=REDIS_HOST,
            port=REDIS_PORT,
            password=REDIS_PASSWORD,
            db=REDIS_DB,
            decode_responses=True,
            socket_timeout=5,
            socket_connect_timeout=5
        )
        # Test connection
        redis_client.ping()
        logger.info(f"Redis cache enabled: {REDIS_HOST}:{REDIS_PORT}/DB{REDIS_DB}")
    except Exception as e:
        logger.warning(f"Redis connection failed, running without cache: {str(e)}")
        redis_client = None
        CACHE_ENABLED = False
else:
    logger.info("Redis cache disabled by configuration")

def generate_cache_key(operation, index_name, query, **kwargs):
    """Generate a cache key for the operation"""
    key_data = {
        'operation': operation,
        'index': index_name,
        'query': query,
        **kwargs
    }
    key_string = json.dumps(key_data, sort_keys=True)
    return f"leann:{hashlib.md5(key_string.encode()).hexdigest()}"

def get_from_cache(cache_key):
    """Get result from Redis cache"""
    if not redis_client:
        return None
    
    try:
        cached_data = redis_client.get(cache_key)
        if cached_data:
            result = json.loads(cached_data)
            logger.info(f"Cache HIT: {cache_key}")
            return result
    except Exception as e:
        logger.error(f"Cache get error: {str(e)}")
    
    return None

def set_cache(cache_key, data):
    """Set result in Redis cache"""
    if not redis_client:
        return
    
    try:
        redis_client.setex(
            cache_key, 
            CACHE_TTL_SECONDS, 
            json.dumps(data, default=str)
        )
        logger.info(f"Cache SET: {cache_key} (TTL: {CACHE_TTL_SECONDS}s)")
    except Exception as e:
        logger.error(f"Cache set error: {str(e)}")

def require_auth(f):
    """Simple token-based authentication decorator"""
    @wraps(f)
    def decorated_function(*args, **kwargs):
        token = request.headers.get('Authorization', '').replace('Bearer ', '')
        if not token or token != API_TOKEN:
            return jsonify({'error': 'Unauthorized', 'message': 'Valid API token required'}), 401
        return f(*args, **kwargs)
    return decorated_function

def run_leann_command(command_args):
    """Execute LEANN command and return result"""
    try:
        cmd = [LEANN_COMMAND] + command_args
        logger.info(f"Executing: {' '.join(cmd)}")
        
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=60,
            cwd="/root"
        )
        
        if result.returncode != 0:
            logger.error(f"LEANN command failed: {result.stderr}")
            return {
                'success': False,
                'error': 'LEANN command failed',
                'stderr': result.stderr,
                'returncode': result.returncode
            }
        
        return {
            'success': True,
            'stdout': result.stdout,
            'stderr': result.stderr
        }
        
    except subprocess.TimeoutExpired:
        logger.error("LEANN command timed out")
        return {
            'success': False,
            'error': 'Command timed out after 60 seconds'
        }
    except Exception as e:
        logger.error(f"Exception running LEANN command: {str(e)}")
        return {
            'success': False,
            'error': f'Exception: {str(e)}'
        }

@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    redis_status = "disabled"
    if CACHE_ENABLED and redis_client:
        try:
            redis_client.ping()
            redis_status = "connected"
        except:
            redis_status = "error"
    
    return jsonify({
        'status': 'healthy',
        'service': 'LEANN HTTP API Wrapper with Redis Cache',
        'timestamp': datetime.utcnow().isoformat(),
        'version': '2.0.0',
        'cache': {
            'enabled': CACHE_ENABLED,
            'status': redis_status,
            'ttl_seconds': CACHE_TTL_SECONDS if CACHE_ENABLED else None
        }
    })

@app.route('/cache/stats', methods=['GET'])
@require_auth
def cache_stats():
    """Get cache statistics"""
    if not redis_client:
        return jsonify({'error': 'Redis cache not available'}), 503
    
    try:
        info = redis_client.info()
        keys = redis_client.keys("leann:*")
        
        return jsonify({
            'cache_enabled': CACHE_ENABLED,
            'total_keys': len(keys),
            'memory_usage': info.get('used_memory_human'),
            'hits': info.get('keyspace_hits', 0),
            'misses': info.get('keyspace_misses', 0),
            'connected_clients': info.get('connected_clients', 0),
            'uptime_seconds': info.get('uptime_in_seconds', 0),
            'timestamp': datetime.utcnow().isoformat()
        })
    except Exception as e:
        return jsonify({'error': f'Cache stats error: {str(e)}'}), 500

@app.route('/cache/clear', methods=['POST'])
@require_auth
def clear_cache():
    """Clear LEANN cache"""
    if not redis_client:
        return jsonify({'error': 'Redis cache not available'}), 503
    
    try:
        keys = redis_client.keys("leann:*")
        if keys:
            deleted = redis_client.delete(*keys)
            logger.info(f"Cleared {deleted} cache entries")
            return jsonify({
                'success': True,
                'message': f'Cleared {deleted} cache entries',
                'timestamp': datetime.utcnow().isoformat()
            })
        else:
            return jsonify({
                'success': True,
                'message': 'No cache entries to clear',
                'timestamp': datetime.utcnow().isoformat()
            })
    except Exception as e:
        logger.error(f"Cache clear error: {str(e)}")
        return jsonify({'error': f'Cache clear error: {str(e)}'}), 500

@app.route('/search', methods=['POST'])
@require_auth
def search():
    """Search in LEANN index with caching"""
    try:
        data = request.get_json()
        if not data:
            return jsonify({'error': 'JSON body required'}), 400
        
        query = data.get('query', '').strip()
        index_name = data.get('index', DEFAULT_INDEX)
        top_k = data.get('top_k', 5)
        
        if not query:
            return jsonify({'error': 'query parameter required'}), 400
        
        # Check cache first
        cache_key = generate_cache_key('search', index_name, query, top_k=top_k)
        cached_result = get_from_cache(cache_key)
        
        if cached_result:
            cached_result['cached'] = True
            cached_result['timestamp'] = datetime.utcnow().isoformat()
            return jsonify(cached_result)
        
        # Run LEANN search command - need to quote the query
        cmd_args = ['search', index_name, f'"{query}"']
        if top_k != 5:
            cmd_args.extend(['--top-k', str(top_k)])
        
        result = run_leann_command(cmd_args)
        
        if not result['success']:
            return jsonify({
                'error': 'LEANN search failed',
                'details': result
            }), 500
        
        response_data = {
            'success': True,
            'query': query,
            'index': index_name,
            'top_k': top_k,
            'results': result['stdout'],
            'cached': False,
            'timestamp': datetime.utcnow().isoformat()
        }
        
        # Cache the result
        set_cache(cache_key, response_data)
        
        return jsonify(response_data)
        
    except Exception as e:
        logger.error(f"Search endpoint error: {str(e)}")
        return jsonify({'error': f'Internal server error: {str(e)}'}), 500

@app.route('/ask', methods=['POST'])
@require_auth
def ask():
    """Ask question to LEANN index with caching"""
    try:
        data = request.get_json()
        if not data:
            return jsonify({'error': 'JSON body required'}), 400
        
        question = data.get('question', '').strip()
        index_name = data.get('index', DEFAULT_INDEX)
        
        if not question:
            return jsonify({'error': 'question parameter required'}), 400
        
        # Check cache first
        cache_key = generate_cache_key('ask', index_name, question)
        cached_result = get_from_cache(cache_key)
        
        if cached_result:
            cached_result['cached'] = True
            cached_result['timestamp'] = datetime.utcnow().isoformat()
            return jsonify(cached_result)
        
        # Run LEANN ask command - need to quote the question
        cmd_args = ['ask', index_name, f'"{question}"']
        result = run_leann_command(cmd_args)
        
        if not result['success']:
            return jsonify({
                'error': 'LEANN ask failed',
                'details': result
            }), 500
        
        response_data = {
            'success': True,
            'question': question,
            'index': index_name,
            'answer': result['stdout'],
            'cached': False,
            'timestamp': datetime.utcnow().isoformat()
        }
        
        # Cache the result
        set_cache(cache_key, response_data)
        
        return jsonify(response_data)
        
    except Exception as e:
        logger.error(f"Ask endpoint error: {str(e)}")
        return jsonify({'error': f'Internal server error: {str(e)}'}), 500

@app.route('/indexes', methods=['GET'])
@require_auth
def list_indexes():
    """List available LEANN indexes"""
    try:
        result = run_leann_command(['list'])
        
        if not result['success']:
            return jsonify({
                'error': 'Failed to list indexes',
                'details': result
            }), 500
        
        return jsonify({
            'success': True,
            'indexes': result['stdout'],
            'timestamp': datetime.utcnow().isoformat()
        })
        
    except Exception as e:
        logger.error(f"List indexes error: {str(e)}")
        return jsonify({'error': f'Internal server error: {str(e)}'}), 500

@app.route('/api/docs', methods=['GET'])
def api_docs():
    """API documentation"""
    docs = {
        'service': 'LEANN HTTP API Wrapper with Redis Cache',
        'version': '2.0.0',
        'description': 'REST API wrapper for LEANN semantic search with Redis caching',
        'authentication': 'Bearer token in Authorization header',
        'cache': {
            'enabled': CACHE_ENABLED,
            'ttl_seconds': CACHE_TTL_SECONDS if CACHE_ENABLED else None
        },
        'endpoints': {
            'GET /health': 'Health check with cache status',
            'GET /indexes': 'List available indexes (auth required)',
            'POST /search': 'Search in index with caching (auth required)',
            'POST /ask': 'Ask question to index with caching (auth required)',
            'GET /cache/stats': 'Cache statistics (auth required)',
            'POST /cache/clear': 'Clear cache (auth required)',
            'GET /api/docs': 'This documentation'
        },
        'examples': {
            'search': {
                'method': 'POST',
                'url': '/search',
                'headers': {'Authorization': 'Bearer YOUR_TOKEN'},
                'body': {
                    'query': 'n8n workflow automation',
                    'index': 'myvault',
                    'top_k': 5
                }
            },
            'ask': {
                'method': 'POST',
                'url': '/ask',
                'headers': {'Authorization': 'Bearer YOUR_TOKEN'},
                'body': {
                    'question': 'How to configure n8n webhooks?',
                    'index': 'myvault'
                }
            },
            'cache_stats': {
                'method': 'GET',
                'url': '/cache/stats',
                'headers': {'Authorization': 'Bearer YOUR_TOKEN'}
            }
        }
    }
    return jsonify(docs)

@app.errorhandler(404)
def not_found(error):
    return jsonify({'error': 'Not found', 'message': 'Endpoint not available'}), 404

@app.errorhandler(500)
def internal_error(error):
    return jsonify({'error': 'Internal server error'}), 500

if __name__ == '__main__':
    logger.info(f"Starting LEANN HTTP API Wrapper with Redis Cache on {HOST}:{PORT}")
    logger.info(f"API Token: {API_TOKEN}")
    logger.info(f"Default Index: {DEFAULT_INDEX}")
    logger.info(f"Cache Enabled: {CACHE_ENABLED}")
    if CACHE_ENABLED:
        logger.info(f"Redis: {REDIS_HOST}:{REDIS_PORT}/DB{REDIS_DB} (TTL: {CACHE_TTL_SECONDS}s)")
    
    app.run(
        host=HOST,
        port=PORT,
        debug=False,
        threaded=True
    )