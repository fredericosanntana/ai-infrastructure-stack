# 🔄 Repository Update Process

This document explains how to keep the GitHub repository synchronized with your live AI Infrastructure Stack.

## 🎯 **Overview**

The repository includes automated systems to keep your GitHub backup current with:
- AI agent workflows from n8n
- LEANN system updates and configurations  
- Docker Compose stack changes
- Documentation updates from MyVault
- Monitoring and script improvements

## 🤖 **Automatic Updates**

### **Setup Automated Updates**
```bash
# Run once to set up daily automatic updates
./scripts/setup-auto-update.sh
```

This configures:
- ✅ **Systemd timer**: Daily updates at 6 AM
- ✅ **Cron backup**: Redundant scheduling
- ✅ **Log rotation**: Automatic log management
- ✅ **Service monitoring**: Systemd integration

### **Automatic Update Features**
- 🔍 **Smart detection**: Only commits when changes exist
- 🧹 **Data sanitization**: Removes sensitive information
- 🏷️ **Auto-versioning**: Creates releases every 5 commits
- 📊 **Comprehensive logging**: Full audit trail
- 🔄 **Failure recovery**: Robust error handling

## 🛠️ **Manual Updates**

### **Run Update Now**
```bash
# Full update with commit and push
./scripts/update-github.sh

# Check what would be updated (no changes made)
./scripts/update-github.sh --dry-run

# Force create a new release
./scripts/update-github.sh --force-release
```

### **Update Process Details**

#### **1. AI Agents Sync**
- Copies workflows from `/opt/n8n-agents/` to `ai-agents/workflows/`
- Updates all JSON workflow definitions
- Preserves workflow versions and metadata

#### **2. LEANN System Updates**  
- Syncs scripts from `/opt/leann/` to `leann-system/scripts/`
- Updates API wrappers and HTTP services
- Maintains auto-reindex configurations

#### **3. Docker Configuration Sync**
- Updates `docker-compose.yml` (sanitized)
- Syncs monitoring configurations  
- Preserves Traefik and service definitions
- **Removes sensitive data** (API keys, passwords)

#### **4. Documentation Updates**
- Pulls key docs from MyVault Obsidian
- Updates architecture documentation
- Syncs MOC (Map of Content) files
- Maintains knowledge base consistency

## 📊 **Monitoring Updates**

### **Check Update Status**
```bash
# View systemd timer status
sudo systemctl status github-repo-update.timer

# Check last update log
sudo journalctl -u github-repo-update.service --no-pager

# View cron-based update logs
tail -f /var/log/github-update.log
```

### **Update Statistics**
```bash
# Repository status
cd /tmp/ai-infrastructure-stack
git status
git log --oneline -10

# Check for pending changes
git diff --name-status
```

## 🔧 **Troubleshooting**

### **Common Issues**

#### **SSH Authentication Problems**
```bash
# Test SSH connection
ssh -T git@github.com

# If fails, check SSH key
cat ~/.ssh/github_key.pub
# Re-add to GitHub if needed
```

#### **Permission Denied**
```bash
# Fix script permissions
chmod +x scripts/*.sh

# Check repository permissions
ls -la /tmp/ai-infrastructure-stack/
```

#### **Update Service Failures**
```bash
# Check service logs
sudo journalctl -u github-repo-update.service -f

# Restart timer if needed
sudo systemctl restart github-repo-update.timer
```

#### **Merge Conflicts**
```bash
# If GitHub has newer changes
git fetch origin
git merge origin/main

# Or reset to GitHub version
git reset --hard origin/main
```

### **Manual Recovery**
```bash
# If automatic updates fail completely
cd /tmp/ai-infrastructure-stack

# Save current state
git stash

# Pull latest from GitHub
git pull origin main

# Re-run manual update
./scripts/update-github.sh
```

## 📋 **Update Workflow**

### **Recommended Process**

1. **Monitor automatic updates** (daily at 6 AM)
2. **Check logs weekly** for any issues
3. **Manual update** after major system changes
4. **Force release** for significant milestones

### **Before Major Changes**
```bash
# Create backup branch
git checkout -b backup-$(date +%Y%m%d)
git push origin backup-$(date +%Y%m%d)

# Then proceed with updates
git checkout main
./scripts/update-github.sh
```

### **After System Upgrades**
```bash
# Force immediate update after infrastructure changes  
./scripts/update-github.sh --force-release
```

## 🎯 **Best Practices**

### **Do's ✅**
- Let automatic updates handle daily sync
- Check logs regularly for issues
- Use dry-run mode before major updates
- Create backup branches before major changes
- Monitor repository size and clean up if needed

### **Don'ts ❌**
- Don't disable automatic updates without backup plan
- Don't commit sensitive data manually
- Don't force push to main branch
- Don't ignore systemd service failures
- Don't skip testing after major system changes

## 📈 **Repository Health**

### **Key Metrics to Monitor**
- **Update frequency**: Should be daily if changes exist
- **Commit size**: Usually < 50 files per commit  
- **Repository size**: Should stay < 100MB
- **Failed updates**: Should be < 5% of attempts

### **Maintenance Tasks**
- **Weekly**: Review update logs
- **Monthly**: Check repository size and clean up
- **Quarterly**: Review and update documentation
- **Annually**: Audit and refresh SSH keys

## 🚀 **Advanced Features**

### **Custom Update Triggers**
```bash
# Trigger update after specific events
echo './scripts/update-github.sh' >> /opt/post-deployment-hook.sh

# Update after n8n workflow changes
# (Add to n8n webhook or automation)
```

### **Selective Updates**
```bash
# Update only specific components
cd /tmp/ai-infrastructure-stack

# Update only AI agents
cp -r /opt/n8n-agents/* ai-agents/workflows/
git add ai-agents/ && git commit -m "Update AI agents only"

# Update only documentation  
cp /path/to/updated/docs documentation/
git add documentation/ && git commit -m "Update documentation only"
```

---

## 📞 **Need Help?**

- **GitHub Issues**: Report problems at repository issues page
- **System Logs**: Check `/var/log/github-update.log`
- **Service Status**: `sudo systemctl status github-repo-update.timer`
- **Manual Testing**: `./scripts/update-github.sh --dry-run`

Your AI Infrastructure Stack repository will stay automatically synchronized with your live system! 🎉