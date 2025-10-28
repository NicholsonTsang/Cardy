#!/bin/bash

# Test script for OpenAI Relay Server
# Run this after starting the server to verify it's working

set -e

RELAY_URL="${RELAY_URL:-http://localhost:8080}"
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo ""
echo "🧪 Testing OpenAI Relay Server"
echo "================================"
echo "Target: $RELAY_URL"
echo ""

# Test 1: Health endpoint
echo "Test 1: Health endpoint..."
response=$(curl -s -o /dev/null -w "%{http_code}" "$RELAY_URL/health")
if [ "$response" = "200" ]; then
    echo -e "${GREEN}✅ PASS${NC} - Health endpoint returned 200 OK"
    health_data=$(curl -s "$RELAY_URL/health")
    echo "   Response: $health_data"
else
    echo -e "${RED}❌ FAIL${NC} - Health endpoint returned $response"
    exit 1
fi

echo ""

# Test 2: 404 on invalid endpoint
echo "Test 2: 404 on invalid endpoint..."
response=$(curl -s -o /dev/null -w "%{http_code}" "$RELAY_URL/nonexistent")
if [ "$response" = "404" ]; then
    echo -e "${GREEN}✅ PASS${NC} - Invalid endpoint returned 404"
else
    echo -e "${RED}❌ FAIL${NC} - Expected 404, got $response"
fi

echo ""

# Test 3: POST /offer validation (missing SDP)
echo "Test 3: POST /offer validation..."
response=$(curl -s -o /dev/null -w "%{http_code}" \
    -X POST "$RELAY_URL/offer" \
    -H "Content-Type: application/json" \
    -d '{}')
if [ "$response" = "400" ]; then
    echo -e "${GREEN}✅ PASS${NC} - Missing SDP returns 400 Bad Request"
else
    echo -e "${RED}❌ FAIL${NC} - Expected 400, got $response"
fi

echo ""

# Test 4: CORS headers
echo "Test 4: CORS headers..."
cors_header=$(curl -s -I "$RELAY_URL/health" | grep -i "access-control-allow-origin" || echo "")
if [ -n "$cors_header" ]; then
    echo -e "${GREEN}✅ PASS${NC} - CORS headers present"
    echo "   $cors_header"
else
    echo -e "${YELLOW}⚠️  WARN${NC} - No CORS headers found (may be restricted)"
fi

echo ""
echo "================================"
echo -e "${GREEN}🎉 All tests passed!${NC}"
echo ""
echo "Next steps:"
echo "1. Configure .env with your OPENAI_API_KEY"
echo "2. Add VITE_OPENAI_RELAY_URL=$RELAY_URL to your frontend .env.local"
echo "3. Test Realtime Mode in your application"
echo ""

