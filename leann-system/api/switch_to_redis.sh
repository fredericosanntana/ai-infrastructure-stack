#!/bin/bash
# Script to switch LEANN API to Redis-enabled version

echo "🔄 Switching LEANN API to Redis-enabled version..."

# Stop the current service
echo "Stopping current LEANN API service..."
sudo systemctl stop leann-api

# Install Python Redis client
echo "Installing Redis Python client..."
pip install redis==5.0.1

# Backup original version
if [ ! -f "/opt/leann-api/leann_http_wrapper.py.backup" ]; then
    echo "Creating backup of original version..."
    cp /opt/leann-api/leann_http_wrapper.py /opt/leann-api/leann_http_wrapper.py.backup
fi

# Switch to Redis version
echo "Switching to Redis-enabled version..."
cp /opt/leann-api/leann_http_wrapper_redis.py /opt/leann-api/leann_http_wrapper.py

# Update systemd service file to use Redis version
echo "Updating systemd service..."
sudo tee /etc/systemd/system/leann-api.service > /dev/null << 'EOF'
[Unit]
Description=LEANN HTTP API Wrapper with Redis Cache
After=network.target
Wants=network-online.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/leann-api
ExecStart=/usr/bin/python3 /opt/leann-api/leann_http_wrapper.py
Restart=always
RestartSec=5
Environment=REDIS_CACHE_ENABLED=true
Environment=LEANN_API_PORT=3001
Environment=LEANN_API_TOKEN=leann_api_2025

# Logging
StandardOutput=append:/var/log/leann-api-stdout.log
StandardError=append:/var/log/leann-api-stderr.log

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd and restart
echo "Reloading systemd daemon..."
sudo systemctl daemon-reload

echo "Starting LEANN API with Redis cache..."
sudo systemctl start leann-api

# Check status
sleep 3
echo "Checking service status..."
sudo systemctl status leann-api --no-pager -l

echo ""
echo "✅ LEANN API with Redis cache is now active!"
echo "📊 Check cache stats: curl -H 'Authorization: Bearer leann_api_2025' http://localhost:3001/cache/stats"
echo "🔄 Health check: curl http://localhost:3001/health"