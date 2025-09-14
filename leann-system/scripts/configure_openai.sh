#!/bin/bash

# LEANN OpenAI Configuration Script
# This script configures OpenAI API key for LEANN semantic search

set -e

echo "🔧 LEANN OpenAI Configuration"
echo "================================"

# Check if API key is provided as argument
if [ $# -eq 0 ]; then
    echo "📝 Please provide your OpenAI API key:"
    echo "Usage: $0 <your-openai-api-key>"
    echo ""
    echo "Example: $0 sk-..."
    echo ""
    echo "ℹ️  You can get your API key from: https://platform.openai.com/account/api-keys"
    exit 1
fi

API_KEY="$1"

# Validate API key format
if [[ ! $API_KEY =~ ^sk-[a-zA-Z0-9_-]{48,}$ ]]; then
    echo "❌ Invalid API key format. OpenAI keys start with 'sk-' followed by at least 48 characters."
    exit 1
fi

echo "🔑 Configuring OpenAI API key..."

# Add to current session
export OPENAI_API_KEY="$API_KEY"

# Add to /etc/environment for system-wide persistence
echo "📝 Adding to /etc/environment for persistence..."
if grep -q "OPENAI_API_KEY" /etc/environment; then
    # Replace existing entry
    sudo sed -i "s/^OPENAI_API_KEY=.*/OPENAI_API_KEY=$API_KEY/" /etc/environment
    echo "✅ Updated existing OPENAI_API_KEY in /etc/environment"
else
    # Add new entry
    echo "OPENAI_API_KEY=$API_KEY" | sudo tee -a /etc/environment > /dev/null
    echo "✅ Added OPENAI_API_KEY to /etc/environment"
fi

# Add to .bashrc for user sessions
if grep -q "OPENAI_API_KEY" ~/.bashrc; then
    sed -i "s/^export OPENAI_API_KEY=.*/export OPENAI_API_KEY=$API_KEY/" ~/.bashrc
    echo "✅ Updated OPENAI_API_KEY in ~/.bashrc"
else
    echo "export OPENAI_API_KEY=$API_KEY" >> ~/.bashrc
    echo "✅ Added OPENAI_API_KEY to ~/.bashrc"
fi

# Test the API key
echo "🧪 Testing OpenAI API connection..."
if command -v python3 &> /dev/null; then
    python3 -c "
import os
import urllib.request
import json

api_key = os.environ.get('OPENAI_API_KEY', '$API_KEY')
if not api_key:
    print('❌ API key not found')
    exit(1)

try:
    req = urllib.request.Request(
        'https://api.openai.com/v1/models',
        headers={'Authorization': f'Bearer {api_key}'}
    )
    with urllib.request.urlopen(req, timeout=10) as response:
        data = json.loads(response.read())
        if 'data' in data:
            print('✅ OpenAI API connection successful!')
            print(f'📊 Available models: {len(data[\"data\"])}')
        else:
            print('❌ Unexpected API response')
except Exception as e:
    print(f'❌ API test failed: {str(e)}')
"
else
    echo "⚠️  Python3 not found, skipping API test"
fi

# Restart LEANN MCP server to pick up new environment
echo "🔄 Restarting LEANN MCP server..."
if systemctl is-active --quiet leann-mcp 2>/dev/null; then
    sudo systemctl restart leann-mcp
    echo "✅ LEANN MCP server restarted"
else
    echo "ℹ️  LEANN MCP server not running as systemd service"
fi

echo ""
echo "🎉 OpenAI configuration completed!"
echo ""
echo "📋 Next steps:"
echo "1. Restart your terminal or run: source ~/.bashrc"
echo "2. Test LEANN with: leann ask myvault --interactive"
echo "3. Try semantic search: leann search myvault 'your question'"
echo ""
echo "💡 The API key is now configured for:"
echo "   - Current session ✅"
echo "   - System-wide (/etc/environment) ✅" 
echo "   - User sessions (~/.bashrc) ✅"