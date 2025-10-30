#!/bin/bash

# OpenAI Relay Server - Deployment Verification Script
# This script verifies that your relay server is properly deployed and configured

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters
PASSED=0
FAILED=0
WARNINGS=0

echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   OpenAI Relay Server - Deployment Verification       ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

# Function to print test result
pass() {
    echo -e "${GREEN}✓${NC} $1"
    ((PASSED++))
}

fail() {
    echo -e "${RED}✗${NC} $1"
    ((FAILED++))
}

warn() {
    echo -e "${YELLOW}⚠${NC} $1"
    ((WARNINGS++))
}

# Check 1: Docker is installed
echo -e "\n${BLUE}[1/12]${NC} Checking Docker installation..."
if command -v docker &> /dev/null; then
    DOCKER_VERSION=$(docker --version | awk '{print $3}' | sed 's/,//')
    pass "Docker installed (version $DOCKER_VERSION)"
else
    fail "Docker is not installed"
    echo "   Install with: curl -fsSL https://get.docker.com | sh"
fi

# Check 2: Docker Compose is available
echo -e "\n${BLUE}[2/12]${NC} Checking Docker Compose..."
if docker-compose --version &> /dev/null 2>&1 || docker compose version &> /dev/null 2>&1; then
    pass "Docker Compose is available"
else
    fail "Docker Compose is not available"
    echo "   Install with: sudo apt install docker-compose-plugin"
fi

# Check 3: .env file exists
echo -e "\n${BLUE}[3/12]${NC} Checking environment configuration..."
if [ -f ".env" ]; then
    pass ".env file exists"
else
    fail ".env file not found"
    echo "   Create with: cp .env.example .env && nano .env"
    exit 1
fi

# Check 4: OpenAI API key is set
echo -e "\n${BLUE}[4/12]${NC} Checking OpenAI API key..."
if grep -q "^OPENAI_API_KEY=sk-" .env 2>/dev/null; then
    pass "OpenAI API key is configured"
else
    fail "OpenAI API key not set in .env"
    echo "   Add: OPENAI_API_KEY=sk-your-key-here"
fi

# Check 5: CORS configuration
echo -e "\n${BLUE}[5/12]${NC} Checking CORS configuration..."
ALLOWED_ORIGINS=$(grep "^ALLOWED_ORIGINS=" .env 2>/dev/null | cut -d'=' -f2)
if [ -n "$ALLOWED_ORIGINS" ]; then
    if [ "$ALLOWED_ORIGINS" = "*" ]; then
        warn "CORS allows all origins (*)"
        echo "   For production, specify exact domains: ALLOWED_ORIGINS=https://your-domain.com"
    else
        pass "CORS configured: $ALLOWED_ORIGINS"
    fi
else
    warn "ALLOWED_ORIGINS not set in .env"
fi

# Check 6: Docker Compose file exists
echo -e "\n${BLUE}[6/12]${NC} Checking Docker Compose configuration..."
if [ -f "docker-compose.yml" ]; then
    pass "docker-compose.yml exists"
else
    fail "docker-compose.yml not found"
    exit 1
fi

# Check 7: Docker service is running
echo -e "\n${BLUE}[7/12]${NC} Checking Docker service..."
if systemctl is-active --quiet docker 2>/dev/null || pgrep -x dockerd > /dev/null; then
    pass "Docker daemon is running"
else
    fail "Docker daemon is not running"
    echo "   Start with: sudo systemctl start docker"
fi

# Check 8: Container is running
echo -e "\n${BLUE}[8/12]${NC} Checking relay container..."
if docker ps | grep -q "openai-relay"; then
    pass "Relay container is running"
    
    # Check container health
    HEALTH=$(docker inspect --format='{{.State.Health.Status}}' openai-relay 2>/dev/null || echo "unknown")
    if [ "$HEALTH" = "healthy" ]; then
        pass "Container health: healthy"
    elif [ "$HEALTH" = "starting" ]; then
        warn "Container health: starting (waiting for health check...)"
    elif [ "$HEALTH" = "unhealthy" ]; then
        fail "Container health: unhealthy"
        echo "   Check logs with: docker-compose logs --tail=50"
    fi
else
    warn "Relay container is not running"
    echo "   Start with: docker-compose up -d"
fi

# Check 9: Health endpoint responds
echo -e "\n${BLUE}[9/12]${NC} Testing health endpoint..."
if curl -sf http://localhost:8080/health > /dev/null 2>&1; then
    pass "Health endpoint responds on http://localhost:8080"
    
    # Get detailed health info
    HEALTH_DATA=$(curl -s http://localhost:8080/health)
    UPTIME=$(echo "$HEALTH_DATA" | grep -o '"uptime":[0-9.]*' | cut -d':' -f2)
    if [ -n "$UPTIME" ]; then
        pass "Server uptime: ${UPTIME}s"
    fi
else
    fail "Health endpoint not responding"
    echo "   Check if container is running: docker ps"
    echo "   Check logs: docker-compose logs --tail=50"
fi

# Check 10: Port 8080 is listening
echo -e "\n${BLUE}[10/12]${NC} Checking port availability..."
if lsof -Pi :8080 -sTCP:LISTEN -t >/dev/null 2>&1 || netstat -tuln 2>/dev/null | grep -q ":8080"; then
    pass "Port 8080 is listening"
else
    warn "Port 8080 is not listening"
fi

# Check 11: Nginx (optional)
echo -e "\n${BLUE}[11/12]${NC} Checking Nginx reverse proxy (optional)..."
if command -v nginx &> /dev/null; then
    if systemctl is-active --quiet nginx 2>/dev/null; then
        pass "Nginx is installed and running"
        
        # Check if relay config exists
        if [ -f "/etc/nginx/sites-enabled/openai-relay" ]; then
            pass "Nginx relay configuration found"
        else
            warn "Nginx relay configuration not found in sites-enabled"
        fi
    else
        warn "Nginx is installed but not running"
    fi
else
    warn "Nginx not installed (optional but recommended for production)"
fi

# Check 12: SSL certificate (optional)
echo -e "\n${BLUE}[12/12]${NC} Checking SSL certificate (optional)..."
if command -v certbot &> /dev/null; then
    pass "Certbot is installed"
    
    # Check for certificates
    CERT_COUNT=$(sudo certbot certificates 2>/dev/null | grep -c "Certificate Name:" || echo "0")
    if [ "$CERT_COUNT" -gt 0 ]; then
        pass "SSL certificates found: $CERT_COUNT"
    else
        warn "No SSL certificates found"
        echo "   Get certificate: sudo certbot --nginx -d relay.your-domain.com"
    fi
else
    warn "Certbot not installed (optional but recommended for production)"
    echo "   Install with: sudo apt install certbot python3-certbot-nginx"
fi

# Summary
echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                    Test Summary                        ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "  ${GREEN}Passed:${NC}   $PASSED"
echo -e "  ${RED}Failed:${NC}   $FAILED"
echo -e "  ${YELLOW}Warnings:${NC} $WARNINGS"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ All critical checks passed!${NC}"
    echo ""
    echo -e "${BLUE}Next Steps:${NC}"
    echo "1. If warnings exist, review and fix them for production"
    echo "2. Update frontend environment variable:"
    echo "   VITE_OPENAI_RELAY_URL=http://your-server-ip:8080"
    echo "   (or https://relay.your-domain.com if using SSL)"
    echo "3. Rebuild and redeploy your frontend"
    echo "4. Test Realtime mode in your app"
    echo ""
else
    echo -e "${RED}✗ Some checks failed. Please fix the issues above.${NC}"
    echo ""
    exit 1
fi

# Additional checks - only if container is running
if docker ps | grep -q "openai-relay"; then
    echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║              Container Information                     ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # Get container stats
    echo -e "${BLUE}Resource Usage:${NC}"
    docker stats openai-relay --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}"
    
    echo ""
    echo -e "${BLUE}Container Ports:${NC}"
    docker port openai-relay
    
    echo ""
    echo -e "${BLUE}Recent Logs (last 5 lines):${NC}"
    docker-compose logs --tail=5
fi

echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                 Useful Commands                        ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
echo ""
echo "  View logs:      docker-compose logs -f"
echo "  Restart:        docker-compose restart"
echo "  Stop:           docker-compose down"
echo "  Start:          docker-compose up -d"
echo "  Rebuild:        docker-compose up -d --build"
echo "  Health check:   curl http://localhost:8080/health"
echo ""

