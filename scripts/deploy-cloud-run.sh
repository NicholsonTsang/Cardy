#!/bin/bash

# OpenAI Relay Server - Cloud Run Deployment Script
# This script deploys the relay server to Google Cloud Run

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   CardStudio Backend - Cloud Run Deployment           ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

# Navigate to the backend directory relative to the script location
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
BACKEND_DIR=$( realpath "$SCRIPT_DIR/../backend-server" )

echo -e "${YELLOW}Changing directory to backend: ${BACKEND_DIR}${NC}"
cd "$BACKEND_DIR"

# Check if .env file exists
if [ ! -f ".env" ]; then
    echo -e "${RED}✗ .env file not found${NC}"
    echo "  Create it with: cp .env.example .env"
    echo "  Then edit it with your OPENAI_API_KEY and ALLOWED_ORIGINS"
    exit 1
fi

# Load environment variables from .env
source .env

# Configuration
echo -e "${BLUE}[1/8]${NC} Configuration"
echo "Please provide your deployment details:"
echo ""

# Get Project ID
read -p "Enter your GCP Project ID: " PROJECT_ID
if [ -z "$PROJECT_ID" ]; then
    echo -e "${RED}✗ Project ID is required${NC}"
    exit 1
fi

# Get Region
echo ""
echo "Common regions:"
echo "  us-central1 (Iowa)"
echo "  us-west1 (Oregon)"
echo "  asia-northeast1 (Tokyo)"
echo "  asia-east1 (Taiwan)"
echo "  europe-west1 (Belgium)"
read -p "Enter region [us-central1]: " REGION
REGION=${REGION:-us-central1}

# Service name
SERVICE_NAME="cardstudio-backend"

# Get CORS origins
echo ""
read -p "Enter allowed CORS origins [${ALLOWED_ORIGINS}]: " INPUT_ORIGINS
ALLOWED_ORIGINS=${INPUT_ORIGINS:-$ALLOWED_ORIGINS}

# Verify OpenAI API key
if [ -z "$OPENAI_API_KEY" ] || [ "$OPENAI_API_KEY" == "your_openai_api_key_here" ]; then
    echo -e "${RED}✗ OPENAI_API_KEY not set in .env${NC}"
    read -p "Enter your OpenAI API Key: " OPENAI_API_KEY
    if [ -z "$OPENAI_API_KEY" ]; then
        echo -e "${RED}✗ API key is required${NC}"
        exit 1
    fi
fi

echo ""
echo -e "${GREEN}Configuration:${NC}"
echo "  Project ID: $PROJECT_ID"
echo "  Region: $REGION"
echo "  Service: $SERVICE_NAME"
echo "  CORS Origins: $ALLOWED_ORIGINS"
echo "  API Key: ${OPENAI_API_KEY:0:10}..."
echo ""
read -p "Continue with deployment? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Deployment cancelled"
    exit 0
fi

# Set project
echo ""
echo -e "${BLUE}[2/8]${NC} Setting GCP project..."
gcloud config set project $PROJECT_ID

# Enable APIs
echo ""
echo -e "${BLUE}[3/8]${NC} Enabling required APIs..."
gcloud services enable run.googleapis.com --quiet
gcloud services enable containerregistry.googleapis.com --quiet
gcloud services enable cloudbuild.googleapis.com --quiet
echo -e "${GREEN}✓${NC} APIs enabled"

# Verify required files
echo ""
echo -e "${BLUE}[4/7]${NC} Verifying required files..."
REQUIRED_FILES=("package.json" "package-lock.json" "Dockerfile" "tsconfig.json")
for file in "${REQUIRED_FILES[@]}"; do
    if [ ! -f "$file" ]; then
        echo -e "${RED}✗ Required file missing: $file${NC}"
        exit 1
    fi
done
echo -e "${GREEN}✓${NC} All required files present"

# Build container image
echo ""
echo -e "${BLUE}[5/7]${NC} Building container image (this may take 2-3 minutes)..."
gcloud builds submit --tag gcr.io/$PROJECT_ID/$SERVICE_NAME . --quiet
echo -e "${GREEN}✓${NC} Container image built and pushed"

# Prepare environment variables (excluding reserved ones)
echo ""
echo -e "${BLUE}[6/7]${NC} Preparing environment variables..."

# Reserved variables that Cloud Run sets automatically
RESERVED_VARS=("PORT" "K_SERVICE" "K_REVISION" "K_CONFIGURATION")

# Build env vars string from .env file
ENV_VARS_STRING=""
while IFS='=' read -r key value; do
  # Skip comments and empty lines
  if [[ $key =~ ^#.*$ ]] || [[ -z "$key" ]]; then
    continue
  fi
  
  key=$(echo "$key" | xargs)
  value=$(echo "$value" | xargs)
  
  # Skip reserved variables
  if [[ " ${RESERVED_VARS[@]} " =~ " ${key} " ]]; then
    continue
  fi
  
  # Skip empty values
  if [[ -z "$value" ]]; then
    continue
  fi
  
  # Remove quotes from value
  value="${value%\"}"
  value="${value#\"}"
  
  # Add to env vars string
  if [[ -z "$ENV_VARS_STRING" ]]; then
    ENV_VARS_STRING="${key}=${value}"
  else
    ENV_VARS_STRING="${ENV_VARS_STRING},${key}=${value}"
  fi
done < .env

echo -e "${GREEN}✓${NC} Environment variables prepared"

# Deploy to Cloud Run
echo ""
echo -e "${BLUE}[7/8]${NC} Deploying to Cloud Run..."
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

echo -e "${GREEN}✓${NC} Service deployed"

# Get service URL
echo ""
echo -e "${BLUE}[8/8]${NC} Getting service URL..."
SERVICE_URL=$(gcloud run services describe $SERVICE_NAME \
  --region $REGION \
  --format 'value(status.url)')

echo -e "${GREEN}✓${NC} Service URL: $SERVICE_URL"

# Test health endpoint
echo ""
echo -e "${BLUE}Testing health endpoint...${NC}"
sleep 5  # Wait for service to be ready
HEALTH_RESPONSE=$(curl -s $SERVICE_URL/health)

if echo "$HEALTH_RESPONSE" | grep -q "healthy"; then
    echo -e "${GREEN}✓${NC} Health check passed"
    echo "  Response: $HEALTH_RESPONSE"
else
    echo -e "${RED}✗${NC} Health check failed"
    echo "  Response: $HEALTH_RESPONSE"
fi

# Summary
echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                 Deployment Complete!                   ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}Service URL:${NC}"
echo "  $SERVICE_URL"
echo ""
echo -e "${GREEN}Health Endpoint:${NC}"
echo "  curl $SERVICE_URL/health"
echo ""
echo -e "${GREEN}Update your frontend .env:${NC}"
echo "  VITE_BACKEND_URL=$SERVICE_URL"
echo ""
echo -e "${GREEN}View logs:${NC}"
echo "  gcloud run services logs tail $SERVICE_NAME --region $REGION"
echo ""
echo -e "${GREEN}Cloud Console:${NC}"
echo "  https://console.cloud.google.com/run/detail/$REGION/$SERVICE_NAME?project=$PROJECT_ID"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "  1. Update frontend .env with new VITE_BACKEND_URL"
echo "  2. Restart frontend dev server (or rebuild for production)"
echo "  3. Test translation, payment, and AI features"
echo "  4. (Optional) Set up custom domain"
echo ""

