# ⚡ Systemd Services

Production automation services for AI Infrastructure Stack.

## Quick Install
```bash
sudo ./install-services.sh
```

## Services Included
- **leann-api.service**: LEANN HTTP API with local embeddings
- **leann-auto-reindex.service**: Automatic knowledge base reindexing
- **n8n-mcp.service**: Model Context Protocol server
- **activity-agent.service**: PARA/Zettelkasten automated reports

## Management
```bash
# Start all services
sudo systemctl start leann-api leann-auto-reindex n8n-mcp activity-agent

# Check status
sudo systemctl status leann-api

# View logs
sudo journalctl -u leann-auto-reindex -f
```

## Features
- Automated health checks
- Resource limits
- Secure secret management
- Production logging