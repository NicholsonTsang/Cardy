#!/bin/bash

# Frontend Deployment Verification Script
# Checks if the frontend is deployed and serving files correctly

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SITE_URL="${1:-https://cardstudio.org}"
TIMEOUT=10

echo -e "${BLUE}╔════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Frontend Deployment Verification                 ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}Testing site: ${YELLOW}$SITE_URL${NC}"
echo ""

# Function to check HTTP status and content type
check_endpoint() {
    local url=$1
    local expected_status=$2
    local description=$3
    
    echo -e "${BLUE}Checking: ${NC}$description"
    echo -e "${BLUE}URL: ${NC}$url"
    
    # Get headers
    response=$(curl -s -o /dev/null -w "%{http_code}|%{content_type}" --max-time $TIMEOUT "$url" || echo "000|error")
    status_code=$(echo "$response" | cut -d'|' -f1)
    content_type=$(echo "$response" | cut -d'|' -f2)
    
    if [ "$status_code" = "$expected_status" ]; then
        echo -e "${GREEN}✓ Status: $status_code${NC}"
    else
        echo -e "${RED}✗ Status: $status_code (expected $expected_status)${NC}"
        return 1
    fi
    
    if [ "$content_type" != "error" ]; then
        echo -e "${GREEN}✓ Content-Type: $content_type${NC}"
    else
        echo -e "${RED}✗ Connection failed${NC}"
        return 1
    fi
    
    echo ""
    return 0
}

# Function to check JavaScript MIME type
check_js_mime() {
    local url=$1
    
    echo -e "${BLUE}Checking: ${NC}JavaScript MIME type"
    echo -e "${BLUE}URL: ${NC}$url"
    
    response=$(curl -s -I "$url" --max-time $TIMEOUT || echo "error")
    
    if echo "$response" | grep -qi "content-type:.*javascript"; then
        echo -e "${GREEN}✓ JavaScript served with correct MIME type${NC}"
        echo "$response" | grep -i "content-type"
    elif echo "$response" | grep -qi "content-type:.*html"; then
        echo -e "${RED}✗ JavaScript served as HTML - THIS IS THE PROBLEM!${NC}"
        echo "$response" | grep -i "content-type"
        echo -e "${YELLOW}→ Server is returning HTML instead of JavaScript${NC}"
        echo -e "${YELLOW}→ Check your server configuration (see FRONTEND_DEPLOYMENT_FIX.md)${NC}"
        return 1
    else
        echo -e "${YELLOW}⚠ Could not determine MIME type${NC}"
        echo "$response" | grep -i "content-type" || echo "No content-type header found"
    fi
    
    echo ""
    return 0
}

# Counter for passed tests
passed=0
total=0

# Test 1: Homepage
total=$((total + 1))
if check_endpoint "$SITE_URL/" 200 "Homepage"; then
    passed=$((passed + 1))
fi

# Test 2: Card route (SPA routing)
total=$((total + 1))
if check_endpoint "$SITE_URL/c/test-card-id" 200 "SPA Routing (Card URL)"; then
    passed=$((passed + 1))
fi

# Test 3: Dashboard route (SPA routing)
total=$((total + 1))
if check_endpoint "$SITE_URL/cms/mycards" 200 "SPA Routing (Dashboard)"; then
    passed=$((passed + 1))
fi

# Test 4: Try to find a JavaScript file
echo -e "${BLUE}Checking: ${NC}JavaScript module files"
echo -e "${YELLOW}→ Looking for JS files in page source...${NC}"

# Get homepage and extract JS file URL
js_file=$(curl -s "$SITE_URL/" | grep -oP '/assets/index-[^"]+\.js' | head -1 || echo "")

if [ -n "$js_file" ]; then
    echo -e "${GREEN}✓ Found JS file: $js_file${NC}"
    echo ""
    
    total=$((total + 1))
    if check_js_mime "$SITE_URL$js_file"; then
        passed=$((passed + 1))
    fi
else
    echo -e "${YELLOW}⚠ Could not find JavaScript files in homepage${NC}"
    echo -e "${YELLOW}→ Page might not be built correctly${NC}"
    echo ""
fi

# Test 5: HTTPS check
total=$((total + 1))
echo -e "${BLUE}Checking: ${NC}HTTPS/SSL"
if echo "$SITE_URL" | grep -q "https://"; then
    if curl -s -I "$SITE_URL" --max-time $TIMEOUT | grep -q "HTTP/2 200\|HTTP/1.1 200"; then
        echo -e "${GREEN}✓ HTTPS is working${NC}"
        passed=$((passed + 1))
    else
        echo -e "${YELLOW}⚠ HTTPS connection issue${NC}"
    fi
else
    echo -e "${YELLOW}⚠ Testing HTTP (not HTTPS)${NC}"
    echo -e "${YELLOW}→ Recommended: Use HTTPS in production${NC}"
fi
echo ""

# Test 6: Check for mixed content
total=$((total + 1))
echo -e "${BLUE}Checking: ${NC}Mixed Content (HTTP resources on HTTPS page)"
if echo "$SITE_URL" | grep -q "https://"; then
    page_content=$(curl -s "$SITE_URL/" || echo "")
    if echo "$page_content" | grep -qE 'http://[^"]+\.(js|css)'; then
        echo -e "${RED}✗ Found HTTP resources on HTTPS page${NC}"
        echo -e "${YELLOW}→ This will cause 'Mixed Content' errors${NC}"
        echo -e "${YELLOW}→ Check .env.production and ensure all URLs use HTTPS${NC}"
    else
        echo -e "${GREEN}✓ No mixed content detected${NC}"
        passed=$((passed + 1))
    fi
else
    echo -e "${YELLOW}⚠ Skipped (not using HTTPS)${NC}"
fi
echo ""

# Summary
echo -e "${BLUE}╔════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Test Summary                                      ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════╝${NC}"
echo ""

if [ $passed -eq $total ]; then
    echo -e "${GREEN}✓ All tests passed ($passed/$total)${NC}"
    echo -e "${GREEN}✓ Frontend is deployed correctly!${NC}"
    exit 0
elif [ $passed -gt $((total / 2)) ]; then
    echo -e "${YELLOW}⚠ Some tests passed ($passed/$total)${NC}"
    echo -e "${YELLOW}→ Check warnings above${NC}"
    exit 1
else
    echo -e "${RED}✗ Multiple tests failed ($passed/$total)${NC}"
    echo -e "${RED}→ Frontend deployment has issues${NC}"
    echo ""
    echo -e "${YELLOW}Common fixes:${NC}"
    echo -e "  1. Check server configuration (Nginx/Apache)"
    echo -e "  2. Ensure SPA routing is configured"
    echo -e "  3. Verify build files are uploaded to correct location"
    echo -e "  4. Check MIME types for JavaScript files"
    echo -e "  5. Review: ${BLUE}FRONTEND_DEPLOYMENT_FIX.md${NC}"
    exit 1
fi

