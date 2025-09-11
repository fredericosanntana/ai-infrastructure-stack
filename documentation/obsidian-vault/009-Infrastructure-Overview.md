# 009 - Infrastructure Overview

## Infrastructure Setup

Este ambiente foi configurado com gerenciamento de infraestrutura containerizada:

### Services Installed
- **Docker Engine**: Container runtime platform
- **Traefik v3.0**: Reverse proxy and load balancer with automatic service discovery
- **Portainer CE**: Web-based container management interface

### Service Access
- Traefik Dashboard: http://localhost:8080 (insecure mode for development)
- Portainer UI: http://portainer.localhost (requires /etc/hosts entry or DNS)
- All services use the `traefik` Docker network for internal communication

### Docker Commands

Start all services:
```bash
cd /opt/docker-compose
docker compose up -d
```

Stop all services:
```bash
cd /opt/docker-compose
docker compose down
```

View service status:
```bash
cd /opt/docker-compose
docker compose ps
```

### Configuration Files
- `/opt/docker-compose/docker-compose.yml`: Main service definitions
- `/opt/docker-compose/traefik/traefik.yml`: Traefik main configuration
- `/opt/docker-compose/traefik/dynamic_conf.yml`: Traefik dynamic configuration

## Container Infrastructure
- **Reverse Proxy**: Traefik handles all incoming traffic on ports 80/443
- **SSL/TLS**: Automatic HTTPS redirection configured, Let's Encrypt ready
- **Service Discovery**: Traefik automatically discovers containers with proper labels
- **Networking**: All services communicate through the `traefik` Docker network
- **Volumes**: Persistent storage for Portainer data and Traefik ACME certificates
- **Monitoring**: Prometheus metrics exposed on port 8082

### Adding New Services
To add new Docker services behind Traefik:
1. Add the service to `docker-compose.yml`
2. Include it in the `traefik` network: `docker-compose_traefik`
3. Add Traefik labels for routing

**Important Guidelines**: 
- Always use `tls=true` for HTTPS
- Specify `docker.network` to ensure proper network routing
- Use unique service names to avoid Traefik conflicts
- Test with `curl -H "Host: domain.com" http://localhost/` first

---
Links: [[001-Traefik]] | [[003-Portainer]] | [[004-Prometheus]]
Tags: #infrastructure #docker #containers #networking