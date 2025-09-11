# 🔍 LEANN Semantic Search - Query Examples

This document provides practical examples for using LEANN Vector Database with semantic search capabilities.

## 🚀 Quick Start

### Basic Search Query
```bash
curl -X POST http://localhost:3001/search \
  -H "Authorization: Bearer leann_api_2025" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "docker container networking",
    "index": "myvault",
    "top_k": 5
  }'
```

### Health Check
```bash
curl http://localhost:3001/health
```

## 📚 Search Categories

### 🏗️ Infrastructure & DevOps

#### Docker & Containers
```bash
# Find Docker networking information
curl -X POST http://localhost:3001/search \
  -H "Authorization: Bearer leann_api_2025" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "docker compose networking bridge host",
    "index": "myvault",
    "top_k": 5
  }'

# Container orchestration and scaling
curl -X POST http://localhost:3001/search \
  -H "Authorization: Bearer leann_api_2025" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "container scaling load balancing orchestration",
    "index": "myvault",
    "top_k": 3
  }'
```

#### SSL/TLS and Security
```bash
# SSL certificate management
curl -X POST http://localhost:3001/search \
  -H "Authorization: Bearer leann_api_2025" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "ssl certificate letsencrypt traefik https",
    "index": "myvault",
    "top_k": 5
  }'

# Security best practices
curl -X POST http://localhost:3001/search \
  -H "Authorization: Bearer leann_api_2025" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "security authentication authorization api keys",
    "index": "myvault",
    "top_k": 4
  }'
```

### 🤖 AI & Automation

#### n8n Workflows
```bash
# Workflow automation patterns
curl -X POST http://localhost:3001/search \
  -H "Authorization: Bearer leann_api_2025" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "n8n workflow automation webhook trigger",
    "index": "myvault",
    "top_k": 5
  }'

# AI agent integration
curl -X POST http://localhost:3001/search \
  -H "Authorization: Bearer leann_api_2025" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "ai agent leann integration semantic search",
    "index": "myvault",
    "top_k": 6
  }'
```

#### LEANN System
```bash
# LEANN configuration and usage
curl -X POST http://localhost:3001/search \
  -H "Authorization: Bearer leann_api_2025" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "leann vector database openai embedding redis cache",
    "index": "myvault",
    "top_k": 5
  }'

# Performance optimization
curl -X POST http://localhost:3001/search \
  -H "Authorization: Bearer leann_api_2025" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "redis cache performance optimization hit rate",
    "index": "myvault",
    "top_k": 4
  }'
```

### 📊 Monitoring & Observability

#### Prometheus & Grafana
```bash
# Monitoring setup
curl -X POST http://localhost:3001/search \
  -H "Authorization: Bearer leann_api_2025" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "prometheus grafana monitoring metrics dashboard",
    "index": "myvault",
    "top_k": 5
  }'

# Alerting configuration
curl -X POST http://localhost:3001/search \
  -H "Authorization: Bearer leann_api_2025" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "alertmanager alerts notification rules thresholds",
    "index": "myvault",
    "top_k": 4
  }'
```

### 💡 Knowledge Management

#### PARA System
```bash
# PARA methodology
curl -X POST http://localhost:3001/search \
  -H "Authorization: Bearer leann_api_2025" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "PARA projects areas resources archive organization",
    "index": "myvault",
    "top_k": 5
  }'

# Zettelkasten method
curl -X POST http://localhost:3001/search \
  -H "Authorization: Bearer leann_api_2025" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "zettelkasten permanent notes linking knowledge graph",
    "index": "myvault",
    "top_k": 4
  }'
```

#### Content Organization
```bash
# Tagging and categorization
curl -X POST http://localhost:3001/search \
  -H "Authorization: Bearer leann_api_2025" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "tags categorization taxonomy content organization",
    "index": "myvault",
    "top_k": 5
  }'
```

## 🔧 Advanced Queries

### Troubleshooting Scenarios
```bash
# Port conflicts and networking issues
curl -X POST http://localhost:3001/search \
  -H "Authorization: Bearer leann_api_2025" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "port conflict docker networking troubleshooting connection refused",
    "index": "myvault",
    "top_k": 6
  }'

# SSL certificate problems
curl -X POST http://localhost:3001/search \
  -H "Authorization: Bearer leann_api_2025" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "ssl certificate error expired renewal traefik acme",
    "index": "myvault",
    "top_k": 5
  }'

# Service startup issues
curl -X POST http://localhost:3001/search \
  -H "Authorization: Bearer leann_api_2025" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "service failed to start docker container restart",
    "index": "myvault",
    "top_k": 4
  }'
```

### Configuration Management
```bash
# Environment variables and secrets
curl -X POST http://localhost:3001/search \
  -H "Authorization: Bearer leann_api_2025" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "environment variables secrets api keys configuration",
    "index": "myvault",
    "top_k": 5
  }'

# Service configuration files
curl -X POST http://localhost:3001/search \
  -H "Authorization: Bearer leann_api_2025" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "docker compose yaml configuration service setup",
    "index": "myvault",
    "top_k": 4
  }'
```

## 📊 Performance Analysis

### Cache Statistics
```bash
# Check Redis cache performance
curl -H "Authorization: Bearer leann_api_2025" \
  http://localhost:3001/cache/stats
```

Expected response:
```json
{
  "connected_clients": 2,
  "used_memory_human": "15.2M",
  "keyspace_hits": 1847,
  "keyspace_misses": 203,
  "hit_rate": 0.9009
}
```

### Search Performance Comparison
- **Cached Search**: ~15ms response time
- **Uncached Search**: ~2-5s response time
- **Cache Hit Rate**: >90% in production
- **Performance Boost**: 99.97% improvement

## 🎯 Query Optimization Tips

### Effective Search Patterns
```bash
# ✅ Good: Specific and contextual
"docker traefik ssl certificate configuration"

# ✅ Good: Problem-focused
"n8n workflow webhook not triggering troubleshooting"

# ✅ Good: Technical with context
"redis cache performance optimization memory usage"

# ❌ Avoid: Too generic
"help"

# ❌ Avoid: Single words
"docker"

# ❌ Avoid: Unrelated terms
"weather docker food"
```

### Language Support
LEANN supports both English and Portuguese queries:

```bash
# English query
curl -X POST http://localhost:3001/search \
  -H "Authorization: Bearer leann_api_2025" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "infrastructure monitoring setup guide",
    "index": "myvault",
    "top_k": 5
  }'

# Portuguese query
curl -X POST http://localhost:3001/search \
  -H "Authorization: Bearer leann_api_2025" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "configuração monitoramento infraestrutura guia",
    "index": "myvault",
    "top_k": 5
  }'
```

## 🔄 Integration Examples

### With n8n Workflows
```javascript
// n8n HTTP Request node for LEANN search
{
  "method": "POST",
  "url": "http://172.18.0.1:3001/search",
  "headers": {
    "Authorization": "Bearer leann_api_2025",
    "Content-Type": "application/json"
  },
  "body": {
    "query": "{{$json.search_term}}",
    "index": "myvault",
    "top_k": 5,
    "use_cache": true
  }
}
```

### With Python Scripts
```python
import requests

def leann_search(query, top_k=5):
    response = requests.post(
        "http://localhost:3001/search",
        headers={
            "Authorization": "Bearer leann_api_2025",
            "Content-Type": "application/json"
        },
        json={
            "query": query,
            "index": "myvault",
            "top_k": top_k
        }
    )
    return response.json()

# Example usage
results = leann_search("docker networking best practices")
for result in results["results"]:
    print(f"📄 {result['title']}: {result['score']:.2f}")
```

## 🎲 Random Search Examples

Try these varied queries to explore the knowledge base:

```bash
# Architecture and design
curl -X POST http://localhost:3001/search -H "Authorization: Bearer leann_api_2025" -H "Content-Type: application/json" -d '{"query": "microservices architecture patterns best practices", "index": "myvault", "top_k": 4}'

# Development workflows  
curl -X POST http://localhost:3001/search -H "Authorization: Bearer leann_api_2025" -H "Content-Type: application/json" -d '{"query": "git workflow branching strategy deployment", "index": "myvault", "top_k": 5}'

# System administration
curl -X POST http://localhost:3001/search -H "Authorization: Bearer leann_api_2025" -H "Content-Type: application/json" -d '{"query": "linux system administration monitoring logs", "index": "myvault", "top_k": 4}'

# Email server management
curl -X POST http://localhost:3001/search -H "Authorization: Bearer leann_api_2025" -H "Content-Type: application/json" -d '{"query": "email server smtp imap configuration postfix", "index": "myvault", "top_k": 5}'

# Backup and recovery
curl -X POST http://localhost:3001/search -H "Authorization: Bearer leann_api_2025" -H "Content-Type: application/json" -d '{"query": "backup strategy data recovery disaster planning", "index": "myvault", "top_k": 4}'
```

---

## 🎯 Best Practices

1. **Be Specific**: Include context and technical details
2. **Use Technical Terms**: LEANN understands domain-specific vocabulary
3. **Combine Concepts**: Multi-term queries often yield better results
4. **Leverage Cache**: Repeated queries benefit from Redis caching
5. **Check Performance**: Monitor cache hit rates and response times

The LEANN system is designed to understand context and provide highly relevant results for technical infrastructure and knowledge management queries.