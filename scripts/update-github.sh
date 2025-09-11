#!/bin/bash
# AI Infrastructure Stack - GitHub Update Script
# Automated sync between local system and GitHub repository

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
REPO_PATH="/tmp/ai-infrastructure-stack"
GITHUB_REPO="git@github.com:fredericosanntana/ai-infrastructure-stack.git"
SOURCE_PATHS=(
    "/opt/n8n-agents"
    "/opt/docker-compose"
    "/opt/leann"
    "/var/lib/docker/volumes/docker-compose_obsidian-vaults/_data/MyVault/02-Zettelkasten/Permanent"
)

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

# Check if we're in the repository
check_repository() {
    if [ ! -d "$REPO_PATH/.git" ]; then
        error "Repository not found at $REPO_PATH"
    fi
    
    cd "$REPO_PATH"
    
    if ! git remote get-url origin | grep -q "ai-infrastructure-stack"; then
        error "Not in the correct repository"
    fi
    
    log "Repository verified ✅"
}

# Update AI agents from live system
update_ai_agents() {
    log "🤖 Updating AI Agents..."
    
    if [ -d "/opt/n8n-agents" ]; then
        # Copy latest AI agent workflows
        cp -r /opt/n8n-agents/* ai-agents/workflows/ 2>/dev/null || warn "Some AI agents files couldn't be copied"
        log "AI Agents updated ✅"
    else
        warn "AI agents directory not found"
    fi
}

# Update LEANN system files
update_leann_system() {
    log "🧠 Updating LEANN system..."
    
    if [ -d "/opt/leann" ]; then
        # Update LEANN scripts
        cp /opt/leann/*.py leann-system/scripts/ 2>/dev/null || warn "Some LEANN scripts couldn't be copied"
        cp /opt/leann/*.sh leann-system/scripts/ 2>/dev/null || warn "Some LEANN shell scripts couldn't be copied"
        
        # Update API files if they exist
        if [ -f "/opt/leann/leann_http_wrapper_redis.py" ]; then
            cp /opt/leann/leann_http_wrapper_redis.py leann-system/api/
        fi
        
        log "LEANN system updated ✅"
    else
        warn "LEANN directory not found"
    fi
}

# Update Docker Compose configurations
update_docker_configs() {
    log "🐳 Updating Docker configurations..."
    
    if [ -d "/opt/docker-compose" ]; then
        # Update main docker-compose file (sanitized version)
        if [ -f "/opt/docker-compose/docker-compose.yml" ]; then
            # Create sanitized version removing sensitive data
            sed -E 's/(API_KEY|PASSWORD|SECRET|TOKEN)=.*/\1=YOUR_\1_HERE/g' \
                /opt/docker-compose/docker-compose.yml > docker-compose/docker-compose.yml
        fi
        
        # Update monitoring configurations
        if [ -d "/opt/docker-compose/monitoring" ]; then
            cp -r /opt/docker-compose/monitoring/* docker-compose/monitoring/ 2>/dev/null || warn "Some monitoring configs couldn't be copied"
        fi
        
        log "Docker configurations updated ✅"
    else
        warn "Docker compose directory not found"
    fi
}

# Update documentation from MyVault
update_documentation() {
    log "📚 Updating documentation..."
    
    local vault_path="/var/lib/docker/volumes/docker-compose_obsidian-vaults/_data/MyVault"
    if [ -d "$vault_path" ]; then
        # Update key documentation files
        local docs=(
            "02-Zettelkasten/Permanent/055-n8n-AI-Agents-System.md"
            "02-Zettelkasten/Permanent/015-LEANN-Vector-Database.md"
            "02-Zettelkasten/Permanent/009-Infrastructure-Overview.md"
            "02-Zettelkasten/Permanent/027-MOC-AI-Automation.md"
        )
        
        for doc in "${docs[@]}"; do
            if [ -f "$vault_path/$doc" ]; then
                cp "$vault_path/$doc" "documentation/obsidian-vault/$(basename "$doc")"
                log "Updated $(basename "$doc")"
            fi
        done
        
        log "Documentation updated ✅"
    else
        warn "MyVault not accessible"
    fi
}

# Check for changes and commit
check_and_commit_changes() {
    log "🔍 Checking for changes..."
    
    if git diff --quiet && git diff --cached --quiet; then
        log "No changes detected ✅"
        return 0
    fi
    
    log "Changes detected, creating commit..."
    
    # Add all changes
    git add .
    
    # Generate commit message based on changed files
    local changed_files=$(git diff --cached --name-only | wc -l)
    local commit_msg="🔄 Update infrastructure components

Updated $changed_files files from live system:
$(git diff --cached --name-status | sed 's/^/- /')

🤖 Generated with Claude Code

Co-Authored-By: Claude <noreply@anthropic.com>"
    
    git commit -m "$commit_msg"
    log "Commit created ✅"
    return 1  # Changes were made
}

# Push changes to GitHub
push_to_github() {
    log "📤 Pushing changes to GitHub..."
    
    git push origin main
    log "Changes pushed to GitHub ✅"
}

# Generate release if significant changes
create_release_if_needed() {
    local changes_made=$1
    
    if [ $changes_made -eq 0 ]; then
        return  # No changes, no release needed
    fi
    
    log "🏷️ Checking if release is needed..."
    
    # Count commits since last tag
    local commits_since_tag=$(git rev-list $(git describe --tags --abbrev=0)..HEAD --count)
    
    if [ $commits_since_tag -ge 5 ]; then
        log "🎯 Creating new release (5+ commits since last release)"
        
        # Generate next version (patch increment)
        local last_version=$(git describe --tags --abbrev=0)
        local next_version=$(echo $last_version | awk -F. '{$3 = $3 + 1} 1' OFS=.)
        
        # Create release tag
        git tag -a "$next_version" -m "🎉 Release $next_version: Infrastructure Updates

Automated release with latest system updates:
- AI agents improvements
- LEANN system enhancements  
- Docker configuration updates
- Documentation sync

🤖 Generated with Claude Code"
        
        git push origin "$next_version"
        log "Release $next_version created and pushed ✅"
    else
        log "Release not needed ($commits_since_tag commits since last release)"
    fi
}

# Display update summary
show_summary() {
    log "📊 Update Summary:"
    echo "   🔗 Repository: https://github.com/fredericosanntana/ai-infrastructure-stack"
    echo "   📝 Commits: $(git rev-list --all --count)"
    echo "   🏷️ Tags: $(git tag | wc -l)"
    echo "   📁 Files: $(git ls-files | wc -l)"
    echo "   ⏰ Last update: $(date)"
    echo "   📊 Status: $(git status --porcelain | wc -l) pending changes"
}

# Main execution
main() {
    log "🚀 Starting GitHub repository update..."
    echo
    
    check_repository
    update_ai_agents
    update_leann_system  
    update_docker_configs
    update_documentation
    
    # Check for changes and commit if needed
    local changes_made=0
    if ! check_and_commit_changes; then
        changes_made=1
        push_to_github
        create_release_if_needed $changes_made
    fi
    
    show_summary
    
    echo
    log "✨ GitHub repository update completed!"
}

# Command line options
case "${1:-}" in
    --dry-run)
        log "🔍 Dry run mode - checking for changes only"
        check_repository
        git status
        ;;
    --force-release)
        log "🏷️ Force release mode"
        main
        create_release_if_needed 1
        ;;
    *)
        main
        ;;
esac