#!/bin/bash
# AI Infrastructure Stack - Health Check Script
# Comprehensive health monitoring for all system components

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Health check results
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0

# Logging functions
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING:${NC} $1"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR:${NC} $1"
}

success() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] SUCCESS:${NC} $1"
}

# Health check function
check_health() {
    local service=$1
    local check_command=$2
    local expected_result=$3
    
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    
    echo -n "🔍 Checking $service... "
    
    if eval "$check_command" > /dev/null 2>&1; then
        echo -e "${GREEN}✅${NC}"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
        return 0
    else
        echo -e "${RED}❌${NC}"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
        return 1
    fi
}

# Check Docker services
check_docker_services() {
    log "🐳 Checking Docker services..."
    
    local services=("traefik" "n8n" "obsidian" "portainer" "leann-api" "n8n-mcp" "firecrawl-mcp")
    
    for service in "${services[@]}"; do
        check_health "$service container" "docker ps | grep -q '$service'"
    done
}

# Check HTTP endpoints
check_http_endpoints() {
    log "🌐 Checking HTTP endpoints..."
    
    # Local endpoints
    check_health "Traefik dashboard" "curl -s -o /dev/null -w '%{http_code}' http://localhost:8080 | grep -q '200'"
    check_health "n8n interface" "curl -s -o /dev/null -w '%{http_code}' http://localhost:5678 | grep -q '200'"
    check_health "Obsidian interface" "curl -s -o /dev/null -w '%{http_code}' http://localhost:3000 | grep -q '200'"
    check_health "Portainer interface" "curl -s -o /dev/null -w '%{http_code}' http://localhost:9000 | grep -q '200'"
    
    # Internal APIs
    check_health "LEANN HTTP API" "curl -s -o /dev/null -w '%{http_code}' http://localhost:3001/health | grep -q '200'"
}

# Check LEANN system
check_leann_system() {
    log "🧠 Checking LEANN system..."
    
    # Check LEANN API health
    if curl -s http://localhost:3001/health > /dev/null 2>&1; then
        local leann_response=$(curl -s http://localhost:3001/health)
        if echo "$leann_response" | grep -q '"status":"healthy"'; then
            success "LEANN API is healthy ✅"
            PASSED_CHECKS=$((PASSED_CHECKS + 1))
        else
            error "LEANN API unhealthy ❌"
            FAILED_CHECKS=$((FAILED_CHECKS + 1))
        fi
        TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    else
        error "LEANN API not accessible ❌"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
        TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    fi
    
    # Check auto-reindex service if available
    if command -v systemctl &> /dev/null; then
        check_health "LEANN auto-reindex service" "systemctl is-active --quiet leann-auto-reindex"
    fi
    
    # Check Redis cache if available
    if docker ps | grep -q redis; then
        check_health "Redis cache" "docker exec \$(docker ps -q -f name=redis) redis-cli ping | grep -q PONG"
    fi
}

# Check AI Agents
check_ai_agents() {
    log "🤖 Checking AI Agents..."
    
    local agents=(
        "Knowledge Manager:km-agent-test"
        "Task Intelligence:task-intelligence"
        "Content Intelligence:content-intelligence"
        "Monitoring Analytics:monitoring-analytics"
    )
    
    for agent_info in "${agents[@]}"; do
        IFS=':' read -r agent_name agent_endpoint <<< "$agent_info"
        
        # Check if webhook is accessible (should return method not allowed or similar)
        if curl -s -o /dev/null -w '%{http_code}' "http://localhost:5678/webhook/$agent_endpoint" | grep -E '(405|404|200)' > /dev/null; then
            success "$agent_name Agent endpoint accessible ✅"
            PASSED_CHECKS=$((PASSED_CHECKS + 1))
        else
            error "$agent_name Agent endpoint not accessible ❌"
            FAILED_CHECKS=$((FAILED_CHECKS + 1))
        fi
        TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    done
}

# Check monitoring stack
check_monitoring() {
    log "📊 Checking monitoring stack..."
    
    # Check if monitoring services are running
    local monitoring_services=("prometheus" "grafana" "alertmanager")
    
    for service in "${monitoring_services[@]}"; do
        if docker ps | grep -q "$service"; then
            success "$service is running ✅"
            PASSED_CHECKS=$((PASSED_CHECKS + 1))
        else
            warn "$service is not running ❌"
            FAILED_CHECKS=$((FAILED_CHECKS + 1))
        fi
        TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    done
    
    # Check Prometheus targets if accessible
    if curl -s http://localhost:9090/-/healthy > /dev/null 2>&1; then
        success "Prometheus is healthy ✅"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
    else
        warn "Prometheus health check failed ❌"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
    fi
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
}

# Check system resources
check_system_resources() {
    log "💽 Checking system resources..."
    
    # Check disk space
    local disk_usage=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
    if [ "$disk_usage" -lt 80 ]; then
        success "Disk usage is acceptable ($disk_usage%) ✅"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
    else
        warn "Disk usage is high ($disk_usage%) ⚠️"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
    fi
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    
    # Check memory usage
    local mem_usage=$(free | grep Mem | awk '{printf "%.0f", $3/$2 * 100.0}')
    if [ "$mem_usage" -lt 85 ]; then
        success "Memory usage is acceptable ($mem_usage%) ✅"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
    else
        warn "Memory usage is high ($mem_usage%) ⚠️"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
    fi
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    
    # Check Docker daemon
    check_health "Docker daemon" "docker info > /dev/null 2>&1"
}

# Check SSL certificates (if configured)
check_ssl_certificates() {
    log "🔒 Checking SSL certificates..."
    
    # This would check actual SSL certificates if domains are configured
    # For now, just check if Let's Encrypt directory exists
    if [ -d "docker-compose/traefik-acme" ] || docker volume ls | grep -q traefik-acme; then
        success "SSL certificate storage configured ✅"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
    else
        warn "SSL certificate storage not found ⚠️"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
    fi
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
}

# Generate health report
generate_report() {
    echo
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "${BLUE}📋 AI Infrastructure Stack Health Report${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🕐 Report Time: $(date)"
    echo "📊 Total Checks: $TOTAL_CHECKS"
    echo -e "✅ Passed: ${GREEN}$PASSED_CHECKS${NC}"
    echo -e "❌ Failed: ${RED}$FAILED_CHECKS${NC}"
    
    local success_rate=$((PASSED_CHECKS * 100 / TOTAL_CHECKS))
    echo "📈 Success Rate: $success_rate%"
    
    if [ $FAILED_CHECKS -eq 0 ]; then
        echo -e "${GREEN}🎉 All systems operational!${NC}"
        exit 0
    elif [ $success_rate -ge 80 ]; then
        echo -e "${YELLOW}⚠️  System mostly healthy with some issues${NC}"
        exit 1
    else
        echo -e "${RED}🚨 System has significant issues${NC}"
        exit 2
    fi
}

# Main execution
main() {
    log "🚀 Starting comprehensive health check..."
    echo
    
    check_docker_services
    echo
    check_http_endpoints
    echo
    check_leann_system
    echo
    check_ai_agents
    echo
    check_monitoring
    echo
    check_system_resources
    echo
    check_ssl_certificates
    
    generate_report
}

# Execute main function
main "$@"