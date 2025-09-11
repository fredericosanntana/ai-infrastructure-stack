# 🤝 Contributing to AI Infrastructure Stack

We welcome contributions to make this AI infrastructure stack even better! This guide will help you get started.

## 🎯 Ways to Contribute

### 🐛 Bug Reports
- Use GitHub Issues with the "bug" label
- Include system information and reproduction steps
- Provide relevant logs and error messages

### ✨ Feature Requests
- Use GitHub Issues with the "enhancement" label
- Describe the use case and expected behavior
- Consider if it fits the AI-first architecture

### 📝 Documentation
- Fix typos, improve clarity, or add examples
- Update API documentation and usage guides
- Contribute to architecture documentation

### 🔧 Code Contributions
- AI agent improvements and new agents
- LEANN integration enhancements
- Monitoring and observability improvements
- Docker Compose optimizations

## 🚀 Development Setup

### Prerequisites
```bash
# Install Docker and Docker Compose
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER

# Install development tools
sudo apt-get update
sudo apt-get install git curl jq

# Clone the repository
git clone https://github.com/yourusername/ai-infrastructure-stack.git
cd ai-infrastructure-stack
```

### Local Development Environment
```bash
# Copy and configure environment
cp docker-compose/.env.example docker-compose/.env
# Edit .env with your development values

# Start development stack
cd docker-compose
docker compose up -d

# Verify services are running
docker compose ps
```

## 🔄 Development Workflow

### 1. Fork and Clone
```bash
# Fork the repo on GitHub, then:
git clone https://github.com/yourusername/ai-infrastructure-stack.git
cd ai-infrastructure-stack
git remote add upstream https://github.com/originaluser/ai-infrastructure-stack.git
```

### 2. Create Feature Branch
```bash
git checkout -b feature/your-feature-name
# or
git checkout -b fix/issue-description
```

### 3. Make Changes
- Follow existing code patterns and conventions
- Update documentation as needed
- Add tests where applicable
- Ensure Docker services still work properly

### 4. Test Your Changes
```bash
# Test the complete stack
./scripts/health-check.sh

# Test specific components
docker compose logs traefik
docker compose logs n8n
curl http://localhost:3001/health

# Test AI agents
curl -X POST http://localhost:5678/webhook/km-agent-test \
  -H "Content-Type: application/json" \
  -d '{"content": "test content", "source": "development"}'
```

### 5. Submit Pull Request
```bash
# Push to your fork
git push origin feature/your-feature-name

# Create PR via GitHub web interface
```

## 📋 Coding Standards

### Docker Compose
```yaml
# Use consistent service naming
services:
  service-name:
    container_name: ai-stack-service-name
    restart: unless-stopped
    labels:
      - "traefik.enable=true"
      - "traefik.http.services.service.loadbalancer.server.port=8080"
```

### Environment Variables
```bash
# Use clear, descriptive names
SERVICE_API_KEY=your-api-key
SERVICE_DOMAIN=service.example.com
SERVICE_DEBUG=false

# Document in .env.example with comments
# OpenAI API Key for LEANN embeddings
OPENAI_API_KEY=sk-your-openai-api-key-here
```

### Shell Scripts
```bash
#!/bin/bash
# Script description and purpose

set -e  # Exit on error

# Use consistent logging
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

# Include error handling
error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR:${NC} $1"
    exit 1
}
```

### n8n Workflows
```json
{
  "name": "Descriptive Agent Name",
  "nodes": [
    {
      "name": "Webhook",
      "type": "n8n-nodes-base.webhook",
      "parameters": {
        "path": "descriptive-endpoint-name",
        "httpMethod": "POST"
      }
    }
  ]
}
```

## 🧪 Testing Guidelines

### Infrastructure Testing
```bash
# Health checks
./scripts/health-check.sh

# Service accessibility
curl -s http://localhost:8080  # Traefik
curl -s http://localhost:5678  # n8n
curl -s http://localhost:3001/health  # LEANN API
```

### AI Agent Testing
```bash
# Test each agent with sample data
curl -X POST http://localhost:5678/webhook/km-agent-test \
  -H "Content-Type: application/json" \
  -d '{
    "content": "Test knowledge management",
    "source": "testing",
    "tags": ["test"]
  }'
```

### LEANN Integration Testing
```bash
# Test semantic search
curl -X POST http://localhost:3001/search \
  -H "Authorization: Bearer leann_api_2025" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "test search",
    "index": "myvault",
    "top_k": 3
  }'
```

## 📚 Documentation Standards

### README Updates
- Keep the main README concise and focused
- Update service tables and feature lists
- Include performance benchmarks if changed

### API Documentation
- Document all webhook endpoints
- Include request/response examples
- Note any breaking changes

### Architecture Documentation
- Update diagrams when adding new components
- Document integration patterns
- Include performance considerations

## 🔧 Component-Specific Guidelines

### AI Agents
- Use descriptive webhook paths (`/webhook/agent-name`)
- Include comprehensive error handling
- Integrate with LEANN for contextual intelligence
- Provide meaningful response structures

### LEANN Integration
- Use Redis caching for performance
- Handle API authentication properly
- Include proper error responses
- Document search patterns and optimization

### Monitoring
- Add Prometheus metrics for new components
- Create Grafana dashboards for visualization
- Include proper alerting rules
- Document monitoring capabilities

### Docker Services
- Use health checks in docker-compose.yml
- Include proper restart policies
- Use consistent labeling for Traefik
- Document resource requirements

## 🎯 Pull Request Guidelines

### PR Title Format
```
type(scope): description

Examples:
feat(agents): add content summarization agent
fix(leann): resolve Redis connection timeout
docs(api): update webhook endpoint documentation
```

### PR Description Template
```markdown
## Changes
- Describe what you changed and why

## Testing
- [ ] Health check script passes
- [ ] All services start successfully
- [ ] New functionality works as expected
- [ ] Documentation updated

## Breaking Changes
- List any breaking changes

## Additional Notes
- Any other relevant information
```

### Review Criteria
- Code follows established patterns
- Documentation is updated
- Tests pass (where applicable)
- No sensitive information exposed
- Performance impact considered

## 🏷️ Issue Labels

- **bug**: Something isn't working
- **enhancement**: New feature or request
- **documentation**: Improvements to documentation
- **good first issue**: Good for newcomers
- **help wanted**: Extra attention needed
- **priority-high**: High priority issue
- **ai-agents**: Related to AI agents
- **leann**: Related to LEANN system
- **monitoring**: Related to monitoring stack
- **infrastructure**: Related to Docker/compose

## 🎉 Recognition

Contributors will be recognized in:
- README.md acknowledgments section
- Release notes for significant contributions
- GitHub contributor statistics

## 🆘 Getting Help

- **GitHub Issues**: For bugs and feature requests
- **GitHub Discussions**: For questions and general discussion
- **Documentation**: Check docs/ folder for detailed guides

## 📄 License

By contributing, you agree that your contributions will be licensed under the same MIT License that covers the project.

---

Thank you for contributing to making AI infrastructure more accessible and powerful! 🚀