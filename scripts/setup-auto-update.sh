#!/bin/bash
# Setup automatic GitHub repository updates

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

log "🔄 Setting up automatic GitHub repository updates..."

# Create systemd service for regular updates
log "📝 Creating systemd service..."

sudo tee /etc/systemd/system/github-repo-update.service > /dev/null << 'EOF'
[Unit]
Description=AI Infrastructure Stack GitHub Repository Update
After=network.target

[Service]
Type=oneshot
User=root
WorkingDirectory=/tmp/ai-infrastructure-stack
Environment=PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
ExecStart=/tmp/ai-infrastructure-stack/scripts/update-github.sh
StandardOutput=journal
StandardError=journal
EOF

# Create systemd timer for regular execution
log "⏰ Creating systemd timer..."

sudo tee /etc/systemd/system/github-repo-update.timer > /dev/null << 'EOF'
[Unit]
Description=Run AI Infrastructure Stack GitHub Repository Update
Requires=github-repo-update.service

[Timer]
# Run daily at 6 AM
OnCalendar=*-*-* 06:00:00
# Also run 1 hour after system boot
OnBootSec=1h
# Run if missed (e.g., system was off)
Persistent=true

[Install]
WantedBy=timers.target
EOF

# Enable and start the timer
log "🚀 Enabling automatic updates..."
sudo systemctl daemon-reload
sudo systemctl enable github-repo-update.timer
sudo systemctl start github-repo-update.timer

# Add manual cron job as backup
log "📅 Setting up cron backup..."
(crontab -l 2>/dev/null; echo "0 6 * * * /tmp/ai-infrastructure-stack/scripts/update-github.sh > /var/log/github-update.log 2>&1") | crontab -

# Create log rotation
log "📋 Setting up log rotation..."
sudo tee /etc/logrotate.d/github-update > /dev/null << 'EOF'
/var/log/github-update.log {
    daily
    missingok
    rotate 7
    compress
    delaycompress
    notifempty
    copytruncate
}
EOF

log "✅ Automatic GitHub repository updates configured!"
echo
echo -e "${BLUE}📊 Configuration Summary:${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "⏰ Automatic updates: Daily at 6 AM"
echo "🔄 Backup cron job: Daily at 6 AM"
echo "📋 Logs: /var/log/github-update.log"
echo "🔧 Manual update: /tmp/ai-infrastructure-stack/scripts/update-github.sh"
echo
echo -e "${BLUE}🎯 Manual Commands:${NC}"
echo "• Check timer status: sudo systemctl status github-repo-update.timer"
echo "• Run update now: sudo systemctl start github-repo-update.service"
echo "• View logs: journalctl -u github-repo-update.service"
echo "• Disable auto-update: sudo systemctl disable github-repo-update.timer"
echo
echo -e "${GREEN}✨ Your GitHub repository will now stay automatically updated!${NC}"