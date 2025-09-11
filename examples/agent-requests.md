# 🤖 AI Agents API Usage Examples

This document provides practical examples for interacting with the AI agents deployed in n8n.

## 🔗 Base Configuration

All agents are accessible through n8n webhooks at:
- **Base URL**: `https://your-n8n-domain.com/webhook/`
- **Method**: POST
- **Content-Type**: application/json

## 📚 Knowledge Manager Agent

**Endpoint**: `/webhook/km-agent-test`

### Purpose
Automated knowledge management using PARA methodology with LEANN semantic search.

### Example Request
```bash
curl -X POST https://your-n8n-domain.com/webhook/km-agent-test \
  -H "Content-Type: application/json" \
  -d '{
    "content": "Docker Compose setup for microservices with Traefik reverse proxy",
    "source": "technical-documentation",
    "tags": ["docker", "infrastructure", "devops"],
    "metadata": {
      "author": "DevOps Team",
      "created": "2025-01-15",
      "priority": "high"
    }
  }'
```

### Example Response
```json
{
  "analysis": {
    "suggested_category": "Projects",
    "suggested_area": "Infrastructure Management",
    "confidence": 0.89,
    "reasoning": "Technical documentation about Docker Compose suggests active project work"
  },
  "similar_content": [
    {
      "title": "Docker Networking Best Practices",
      "similarity": 0.87,
      "location": "02-Zettelkasten/Permanent/026-Docker-Networks.md"
    }
  ],
  "recommended_actions": [
    "Create project entry in 01-PARA/Projects/",
    "Link to existing Docker documentation",
    "Add to Infrastructure knowledge base"
  ],
  "leann_search_time": "15ms",
  "cached": true
}
```

## 🎯 Task Intelligence Agent

**Endpoint**: `/webhook/task-intelligence`

### Purpose
Intelligent task analysis with contextual search and conditional auto-execution.

### Example Request
```bash
curl -X POST https://your-n8n-domain.com/webhook/task-intelligence \
  -H "Content-Type: application/json" \
  -d '{
    "task": "Update SSL certificates for all services",
    "priority": "high",
    "auto_execute": false,
    "context": {
      "services": ["traefik", "n8n", "grafana"],
      "environment": "production"
    }
  }'
```

### Example Response
```json
{
  "analysis": {
    "task_type": "infrastructure_maintenance",
    "estimated_duration": "30-45 minutes",
    "risk_level": "medium",
    "automation_recommendation": "semi-automated"
  },
  "execution_plan": [
    {
      "step": 1,
      "action": "Backup current certificates",
      "command": "docker exec traefik ls -la /acme/",
      "estimated_time": "2 minutes"
    },
    {
      "step": 2,
      "action": "Force certificate renewal",
      "command": "docker exec traefik traefik update-certificates",
      "estimated_time": "10 minutes"
    }
  ],
  "related_documentation": [
    {
      "title": "SSL Certificate Management",
      "path": "infrastructure/ssl-management.md",
      "relevance": 0.94
    }
  ],
  "auto_execute_decision": {
    "recommended": false,
    "reason": "High-priority production task requires manual oversight"
  }
}
```

## 🌐 Content Intelligence Agent

**Endpoint**: `/webhook/content-intelligence`

### Purpose
Web content analysis with LEANN similarity detection and duplicate prevention.

### Example Request
```bash
curl -X POST https://your-n8n-domain.com/webhook/content-intelligence \
  -H "Content-Type: application/json" \
  -d '{
    "url": "https://docs.docker.com/compose/networking/",
    "analyze_similarity": true,
    "extract_metadata": true,
    "categorization": "automatic"
  }'
```

### Example Response
```json
{
  "content_analysis": {
    "title": "Docker Compose Networking Guide",
    "word_count": 2847,
    "reading_time": "12 minutes",
    "topics": ["docker", "networking", "compose", "containers"],
    "quality_score": 0.91
  },
  "similarity_check": {
    "duplicate_found": true,
    "similar_content": [
      {
        "title": "Container Networking Basics",
        "similarity": 0.76,
        "location": "Resources/Docker/networking.md",
        "recommendation": "Update existing content instead of creating new"
      }
    ]
  },
  "categorization": {
    "suggested_location": "01-PARA/Resources/Development/Docker/",
    "tags": ["#docker", "#networking", "#infrastructure", "#reference"],
    "para_category": "Resources"
  },
  "extraction_metadata": {
    "author": "Docker Inc.",
    "last_updated": "2024-12-15",
    "canonical_url": "https://docs.docker.com/compose/networking/",
    "content_type": "technical_documentation"
  }
}
```

## 📊 Monitoring Analytics Agent

**Endpoint**: `/webhook/monitoring-analytics`

### Purpose
Infrastructure monitoring with health checks and performance analysis.

### Example Request
```bash
curl -X POST https://your-n8n-domain.com/webhook/monitoring-analytics \
  -H "Content-Type: application/json" \
  -d '{
    "check_type": "full_health",
    "include_recommendations": true,
    "check_leann_performance": true,
    "alert_thresholds": {
      "response_time": 5000,
      "memory_usage": 80,
      "disk_usage": 85
    }
  }'
```

### Example Response
```json
{
  "system_health": {
    "overall_status": "healthy",
    "uptime": "15 days, 7 hours",
    "last_check": "2025-01-15T10:30:00Z"
  },
  "service_status": {
    "traefik": {
      "status": "running",
      "response_time": "12ms",
      "certificates_expiry": "89 days"
    },
    "n8n": {
      "status": "running",
      "active_workflows": 4,
      "executions_today": 127
    },
    "leann_api": {
      "status": "running",
      "cache_hit_rate": 0.94,
      "avg_search_time": "15ms",
      "total_searches_today": 89
    }
  },
  "performance_metrics": {
    "cpu_usage": 23.4,
    "memory_usage": 67.8,
    "disk_usage": 45.2,
    "network_io": "normal"
  },
  "recommendations": [
    {
      "priority": "low",
      "area": "optimization",
      "suggestion": "Consider clearing old n8n execution logs",
      "impact": "Reduce disk usage by ~500MB"
    }
  ],
  "alerts": [],
  "leann_performance": {
    "index_size": "2.4GB",
    "total_documents": 1247,
    "cache_efficiency": "excellent",
    "last_reindex": "2025-01-15T08:15:00Z"
  }
}
```

## 🔧 Common Patterns

### Authentication
All agents use n8n's webhook system and don't require additional authentication if accessing from allowed origins.

### Error Handling
```json
{
  "error": {
    "code": "LEANN_UNAVAILABLE",
    "message": "LEANN API is not responding",
    "timestamp": "2025-01-15T10:30:00Z",
    "retry_after": 300
  }
}
```

### Rate Limiting
- Each agent can handle ~10 concurrent requests
- LEANN searches are cached for 1 hour
- Heavy operations (like web scraping) have built-in delays

### Monitoring Agent Requests
```bash
# Check n8n execution logs
curl -X GET https://your-n8n-domain.com/api/v1/executions \
  -H "X-N8N-API-KEY: your-api-key"

# Monitor LEANN API performance
curl -H "Authorization: Bearer leann_api_2025" \
  http://localhost:3001/cache/stats
```

## 🔍 Integration with LEANN

All agents leverage LEANN for contextual intelligence:

### Direct LEANN API Access
```bash
# Search for context
curl -X POST http://localhost:3001/search \
  -H "Authorization: Bearer leann_api_2025" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "docker networking configuration",
    "index": "myvault",
    "top_k": 5
  }'
```

### Cache Performance
- **Cache Hit Rate**: >90%
- **Cached Response**: ~15ms
- **Uncached Response**: ~2-5s
- **Cache TTL**: 1 hour

## 🎯 Use Cases

### Development Workflow
1. **Content Intelligence** → Analyze new documentation
2. **Knowledge Manager** → Organize in PARA system
3. **Task Intelligence** → Plan implementation tasks
4. **Monitoring Analytics** → Track system health

### Content Management
1. Check for duplicates before adding content
2. Automatically categorize using PARA methodology
3. Generate contextual tags and links
4. Monitor knowledge base health

### Infrastructure Maintenance
1. Automated health checks and reporting
2. Intelligent task analysis and planning
3. Performance monitoring and optimization
4. Proactive issue detection

---

These examples demonstrate the power of combining n8n workflow automation with LEANN semantic search for intelligent infrastructure management.