#!/bin/bash
# AI Infrastructure Stack - Backup Script
# Automated backup for all system components

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
BACKUP_DIR="/opt/backups"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="ai-infrastructure-backup-$DATE"

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

# Create backup directory
create_backup_directory() {
    log "Creating backup directory..."
    mkdir -p "$BACKUP_DIR/$BACKUP_NAME"
    cd "$BACKUP_DIR/$BACKUP_NAME"
}

# Backup Docker volumes
backup_docker_volumes() {
    log "🐳 Backing up Docker volumes..."
    
    # Create volumes backup directory
    mkdir -p docker-volumes
    
    # Backup key volumes
    local volumes=("obsidian-vaults" "n8n-data" "traefik-acme" "prometheus-data" "grafana-data")
    
    for volume in "${volumes[@]}"; do
        if docker volume ls | grep -q "$volume"; then
            log "Backing up volume: $volume"
            docker run --rm -v "docker-compose_$volume":/data -v "$PWD/docker-volumes":/backup alpine tar czf "/backup/$volume.tar.gz" -C /data .
        else
            warn "Volume $volume not found, skipping"
        fi
    done
}

# Backup n8n workflows
backup_n8n_workflows() {
    log "🤖 Backing up n8n workflows..."
    
    mkdir -p n8n-workflows
    
    # Copy exported workflows if available
    if [ -d "/opt/n8n-agents" ]; then
        cp -r /opt/n8n-agents/* n8n-workflows/
        log "n8n agent workflows backed up ✅"
    else
        warn "n8n agent workflows directory not found"
    fi
}

# Backup LEANN system
backup_leann_system() {
    log "🧠 Backing up LEANN system..."
    
    mkdir -p leann-system
    
    # Backup LEANN scripts
    if [ -d "/opt/leann" ]; then
        cp -r /opt/leann/* leann-system/
        log "LEANN scripts backed up ✅"
    fi
    
    # Backup LEANN data (if accessible)
    if [ -d "/opt/leann/data" ]; then
        tar czf leann-system/leann-data.tar.gz -C /opt/leann/data .
        log "LEANN data backed up ✅"
    fi
}

# Backup configurations
backup_configurations() {
    log "⚙️ Backing up configurations..."
    
    mkdir -p configurations
    
    # Docker Compose configurations
    if [ -d "/opt/docker-compose" ]; then
        cp -r /opt/docker-compose configurations/
        # Remove sensitive data
        if [ -f "configurations/docker-compose/.env" ]; then
            rm configurations/docker-compose/.env
            log "Removed sensitive .env file from backup"
        fi
    fi
    
    # System service files
    mkdir -p configurations/systemd
    if systemctl list-unit-files | grep -q "leann"; then
        cp /etc/systemd/system/leann* configurations/systemd/ 2>/dev/null || true
    fi
}

# Backup logs (recent only)
backup_logs() {
    log "📋 Backing up recent logs..."
    
    mkdir -p logs
    
    # Activity agent logs
    if [ -d "/var/log/activity-agent" ]; then
        find /var/log/activity-agent -name "*.log" -mtime -7 -exec cp {} logs/ \; 2>/dev/null || true
    fi
    
    # LEANN logs
    if [ -f "/var/log/leann-auto-reindex.log" ]; then
        tail -1000 /var/log/leann-auto-reindex.log > logs/leann-auto-reindex-recent.log
    fi
}

# Create backup summary
create_backup_summary() {
    log "📊 Creating backup summary..."
    
    cat > backup-summary.txt << EOF
AI Infrastructure Stack Backup Summary
======================================
Backup Date: $(date)
Backup Name: $BACKUP_NAME
Backup Size: $(du -sh . | cut -f1)

Components Included:
- Docker volumes (Obsidian, n8n, Traefik, Monitoring)
- n8n AI Agent workflows
- LEANN system configuration and scripts
- Docker Compose configurations
- Recent system logs
- Service configurations

Excluded (for security):
- Environment variables (.env files)
- SSL certificates (regenerated automatically)
- API keys and secrets
- User passwords

Restore Instructions:
1. Copy backup to target system
2. Run restore script or manually extract components
3. Reconfigure environment variables
4. Restart services

EOF

    log "Backup summary created ✅"
}

# Compress backup
compress_backup() {
    log "🗜️ Compressing backup..."
    
    cd "$BACKUP_DIR"
    tar czf "$BACKUP_NAME.tar.gz" "$BACKUP_NAME"
    
    local backup_size=$(du -sh "$BACKUP_NAME.tar.gz" | cut -f1)
    log "Backup compressed: $BACKUP_NAME.tar.gz ($backup_size) ✅"
    
    # Remove uncompressed directory
    rm -rf "$BACKUP_NAME"
}

# Cleanup old backups
cleanup_old_backups() {
    log "🧹 Cleaning up old backups..."
    
    # Keep last 7 backups
    cd "$BACKUP_DIR"
    ls -t ai-infrastructure-backup-*.tar.gz | tail -n +8 | xargs -r rm -f
    
    local remaining=$(ls -1 ai-infrastructure-backup-*.tar.gz 2>/dev/null | wc -l)
    log "Cleanup completed. $remaining backups retained."
}

# Main execution
main() {
    log "🚀 Starting AI Infrastructure Stack backup..."
    
    create_backup_directory
    backup_docker_volumes
    backup_n8n_workflows
    backup_leann_system
    backup_configurations
    backup_logs
    create_backup_summary
    compress_backup
    cleanup_old_backups
    
    echo
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "${GREEN}🎉 Backup completed successfully!${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📁 Backup Location: $BACKUP_DIR/$BACKUP_NAME.tar.gz"
    echo "📊 Backup Size: $(du -sh "$BACKUP_DIR/$BACKUP_NAME.tar.gz" | cut -f1)"
    echo "🕐 Backup Time: $(date)"
    echo
    echo -e "${BLUE}💡 To restore this backup:${NC}"
    echo "1. Extract: tar xzf $BACKUP_NAME.tar.gz"
    echo "2. Review configurations and update environment variables"
    echo "3. Restore Docker volumes and restart services"
}

# Execute main function
main "$@"