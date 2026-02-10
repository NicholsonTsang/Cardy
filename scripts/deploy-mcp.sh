#!/bin/bash

# FunTell MCP Server - Cloud Run Deployment Script

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   FunTell MCP Server - Cloud Run Deployment           ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

# Navigate to mcp-server directory
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
MCP_DIR=$( realpath "$SCRIPT_DIR/../mcp-server" )

echo -e "${YELLOW}Working directory: ${MCP_DIR}${NC}"
cd "$MCP_DIR"

# Check .env file
if [ ! -f ".env" ]; then
    echo -e "${RED}✗ .env file not found in mcp-server/${NC}"
    echo "  Create it with required variables: SUPABASE_URL, SUPABASE_ANON_KEY, BACKEND_URL"
    exit 1
fi

source .env

# Verify required env vars
if [ -z "$SUPABASE_URL" ]; then
    echo -e "${RED}✗ SUPABASE_URL not set in .env${NC}"
    exit 1
fi
if [ -z "$SUPABASE_ANON_KEY" ]; then
    echo -e "${RED}✗ SUPABASE_ANON_KEY not set in .env${NC}"
    exit 1
fi

# Configuration
echo -e "${BLUE}[1/7]${NC} Configuration"

read -p "Enter your GCP Project ID: " PROJECT_ID
if [ -z "$PROJECT_ID" ]; then
    echo -e "${RED}✗ Project ID is required${NC}"
    exit 1
fi

echo ""
echo "Common regions:"
echo "  asia-east1 (Taiwan)"
echo "  us-central1 (Iowa)"
echo "  asia-northeast1 (Tokyo)"
echo "  europe-west1 (Belgium)"
read -p "Enter region [asia-east1]: " REGION
REGION=${REGION:-asia-east1}

SERVICE_NAME="funtell-mcp"

echo ""
echo -e "${GREEN}Configuration:${NC}"
echo "  Project ID: $PROJECT_ID"
echo "  Region: $REGION"
echo "  Service: $SERVICE_NAME"
echo "  Supabase URL: ${SUPABASE_URL:0:40}..."
echo "  Backend URL: $BACKEND_URL"
echo ""
read -p "Continue with deployment? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Deployment cancelled"
    exit 0
fi

# Set project
echo ""
echo -e "${BLUE}[2/7]${NC} Setting GCP project..."
gcloud config set project $PROJECT_ID

# Enable APIs
echo ""
echo -e "${BLUE}[3/7]${NC} Enabling required APIs..."
gcloud services enable run.googleapis.com --quiet
gcloud services enable cloudbuild.googleapis.com --quiet
echo -e "${GREEN}✓${NC} APIs enabled"

# Build TypeScript
echo ""
echo -e "${BLUE}[4/7]${NC} Building TypeScript..."
npm run build
echo -e "${GREEN}✓${NC} Build complete"

# Build container
echo ""
echo -e "${BLUE}[5/7]${NC} Building container image..."
gcloud builds submit --tag gcr.io/$PROJECT_ID/$SERVICE_NAME . --quiet
echo -e "${GREEN}✓${NC} Container image built"

# Prepare env vars
echo ""
echo -e "${BLUE}[6/7]${NC} Deploying to Cloud Run..."

RESERVED_VARS=("PORT" "K_SERVICE" "K_REVISION" "K_CONFIGURATION")
ENV_VARS_STRING=""
while IFS='=' read -r key value; do
  if [[ $key =~ ^#.*$ ]] || [[ -z "$key" ]]; then continue; fi
  key=$(echo "$key" | xargs)
  value=$(echo "$value" | xargs)
  if [[ " ${RESERVED_VARS[@]} " =~ " ${key} " ]]; then continue; fi
  if [[ -z "$value" ]]; then continue; fi
  value="${value%\"}"
  value="${value#\"}"
  if [[ -z "$ENV_VARS_STRING" ]]; then
    ENV_VARS_STRING="${key}=${value}"
  else
    ENV_VARS_STRING="${ENV_VARS_STRING},${key}=${value}"
  fi
done < .env

gcloud run deploy $SERVICE_NAME \
  --image gcr.io/$PROJECT_ID/$SERVICE_NAME \
  --platform managed \
  --region $REGION \
  --allow-unauthenticated \
  --port 8080 \
  --memory 512Mi \
  --cpu 1 \
  --min-instances 0 \
  --max-instances 10 \
  --timeout 300 \
  --set-env-vars "$ENV_VARS_STRING" \
  --quiet

echo -e "${GREEN}✓${NC} Deployed"

# Get URL
echo ""
echo -e "${BLUE}[7/7]${NC} Getting service URL..."
SERVICE_URL=$(gcloud run services describe $SERVICE_NAME \
  --region $REGION \
  --format 'value(status.url)')

echo -e "${GREEN}✓${NC} Service URL: $SERVICE_URL"

# Health check
echo ""
echo -e "${BLUE}Testing health endpoint...${NC}"
sleep 5
HEALTH_RESPONSE=$(curl -s $SERVICE_URL/health)

if echo "$HEALTH_RESPONSE" | grep -q "ok"; then
    echo -e "${GREEN}✓${NC} Health check passed: $HEALTH_RESPONSE"
else
    echo -e "${RED}✗${NC} Health check failed: $HEALTH_RESPONSE"
fi

# Summary
echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║              Deployment Complete!                      ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}MCP Endpoint:${NC}"
echo "  $SERVICE_URL/mcp"
echo ""
echo -e "${GREEN}Health Check:${NC}"
echo "  curl $SERVICE_URL/health"
echo ""
echo -e "${GREEN}View Logs:${NC}"
echo "  gcloud run services logs tail $SERVICE_NAME --region $REGION"
echo ""
echo -e "${GREEN}Connect from Claude Code (.mcp.json):${NC}"
echo '  {'
echo '    "mcpServers": {'
echo '      "funtell": {'
echo '        "type": "streamable-http",'
echo "        \"url\": \"$SERVICE_URL/mcp\""
echo '      }'
echo '    }'
echo '  }'
echo ""
echo -e "${GREEN}Connect from OpenAI Agents SDK:${NC}"
echo "  MCPServerStreamableHttp(url=\"$SERVICE_URL/mcp\")"
echo ""
