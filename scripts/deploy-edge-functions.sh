#!/bin/bash

# ============================================================================
# Edge Functions Deployment Script
# ============================================================================
# This script deploys all Edge Functions to Supabase.
# See EDGE_FUNCTIONS_CONFIG.md for configuration details.
# ============================================================================

set -e  # Exit on any error

echo "🚀 Deploying Edge Functions to Supabase..."
echo ""

# Color codes for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if user wants to deploy all or specific functions
if [ "$1" == "--help" ] || [ "$1" == "-h" ]; then
  echo "Usage: ./scripts/deploy-edge-functions.sh [function-name]"
  echo ""
  echo "Options:"
  echo "  (no args)                    Deploy all Edge Functions"
  echo "  create-checkout-session      Deploy payment checkout function"
  echo "  handle-checkout-success      Deploy payment success handler"
  echo "  chat-with-audio             Deploy AI chat function (audio model)"
  echo "  chat-with-audio-stream      Deploy AI chat streaming function (text only)"
  echo "  generate-tts-audio          Deploy TTS audio generation function"
  echo "  get-openai-ephemeral-token  Deploy OpenAI token generator (legacy)"
  echo "  openai-realtime-proxy       Deploy OpenAI WebRTC proxy (legacy)"
  echo "  --verify                    Verify secrets before deployment"
  echo "  --help, -h                  Show this help message"
  echo ""
  echo "Examples:"
  echo "  ./scripts/deploy-edge-functions.sh                    # Deploy all"
  echo "  ./scripts/deploy-edge-functions.sh chat-with-audio    # Deploy one"
  echo "  ./scripts/deploy-edge-functions.sh --verify           # Check config"
  exit 0
fi

# Verify secrets if requested
if [ "$1" == "--verify" ]; then
  echo -e "${BLUE}📋 Verifying Supabase Secrets...${NC}"
  echo ""
  
  # Check if secrets are configured
  echo "Configured secrets:"
  npx supabase secrets list
  
  echo ""
  echo -e "${YELLOW}⚠️  Note: Values are hidden for security${NC}"
  echo ""
  echo "Required secrets for Edge Functions:"
  echo "  ✓ STRIPE_SECRET_KEY (for payment functions)"
  echo "  ✓ OPENAI_API_KEY (for AI functions)"
  echo ""
  echo "Optional secrets (have defaults):"
  echo "  • OPENAI_TEXT_MODEL (for text generation)"
  echo "  • OPENAI_AUDIO_MODEL (for STT)"
  echo "  • OPENAI_MAX_TOKENS (max response length)"
  echo "  • OPENAI_TTS_MODEL (TTS model)"
  echo "  • OPENAI_TTS_VOICE (TTS voice)"
  echo "  • OPENAI_AUDIO_FORMAT (audio format)"
  echo ""
  echo -e "${BLUE}📖 See EDGE_FUNCTIONS_CONFIG.md for details${NC}"
  exit 0
fi

# List of all Edge Functions
FUNCTIONS=(
  "create-checkout-session"
  "handle-checkout-success"
  "chat-with-audio"
  "chat-with-audio-stream"
  "generate-tts-audio"
  "get-openai-ephemeral-token"
  "openai-realtime-proxy"
)

# Deploy specific function if provided
if [ ! -z "$1" ]; then
  FUNCTIONS=("$1")
fi

# Deploy each function
DEPLOYED=0
FAILED=0

for func in "${FUNCTIONS[@]}"; do
  echo -e "${BLUE}📦 Deploying: ${func}${NC}"
  
  if npx supabase functions deploy "$func"; then
    echo -e "${GREEN}✅ Successfully deployed: ${func}${NC}"
    DEPLOYED=$((DEPLOYED + 1))
  else
    echo -e "${RED}❌ Failed to deploy: ${func}${NC}"
    FAILED=$((FAILED + 1))
  fi
  
  echo ""
done

# Summary
echo "============================================================================"
if [ $FAILED -eq 0 ]; then
  echo -e "${GREEN}🎉 All Edge Functions deployed successfully!${NC}"
  echo -e "${GREEN}✅ Deployed: ${DEPLOYED} functions${NC}"
else
  echo -e "${YELLOW}⚠️  Deployment completed with errors${NC}"
  echo -e "${GREEN}✅ Deployed: ${DEPLOYED} functions${NC}"
  echo -e "${RED}❌ Failed: ${FAILED} functions${NC}"
fi
echo "============================================================================"
echo ""
echo -e "${BLUE}📖 Configuration: See EDGE_FUNCTIONS_CONFIG.md${NC}"
echo -e "${BLUE}🔍 Verify deployment: https://supabase.com/dashboard${NC}"
echo ""

exit $FAILED

