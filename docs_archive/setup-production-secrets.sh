#!/bin/bash

# ============================================================================
# Production Secrets Setup Script
# ============================================================================
# This script helps you set up all required secrets for Edge Functions.
# See EDGE_FUNCTIONS_CONFIG.md for detailed documentation.
# ============================================================================

set -e  # Exit on any error

# Color codes
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo "============================================================================"
echo -e "${BLUE}🔐 Supabase Edge Functions - Production Secrets Setup${NC}"
echo "============================================================================"
echo ""

# Warning
echo -e "${YELLOW}⚠️  WARNING: This script will set production secrets${NC}"
echo -e "${YELLOW}   Make sure you're targeting the correct Supabase project!${NC}"
echo ""
echo "Current Supabase project:"
npx supabase projects list 2>/dev/null || echo "Not linked to a project"
echo ""

read -p "Continue? (y/N): " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 1
fi

echo ""
echo "============================================================================"
echo -e "${BLUE}Required Secrets${NC}"
echo "============================================================================"
echo ""

# Stripe Secret Key
echo -e "${YELLOW}1. Stripe Secret Key${NC}"
echo "   Get from: https://dashboard.stripe.com/apikeys"
echo "   Format: sk_live_... (for production) or sk_test_... (for testing)"
echo ""
read -p "Enter STRIPE_SECRET_KEY: " STRIPE_KEY

if [ -z "$STRIPE_KEY" ]; then
  echo -e "${RED}❌ Stripe key is required!${NC}"
  exit 1
fi

# Stripe Webhook Secret
echo ""
echo -e "${YELLOW}2. Stripe Webhook Secret${NC}"
echo "   Get from: https://dashboard.stripe.com/webhooks"
echo "   Format: whsec_..."
echo "   Note: Create webhook endpoint first, then copy the signing secret"
echo ""
read -p "Enter STRIPE_WEBHOOK_SECRET: " STRIPE_WEBHOOK_SECRET

if [ -z "$STRIPE_WEBHOOK_SECRET" ]; then
  echo -e "${RED}❌ Stripe webhook secret is required!${NC}"
  exit 1
fi

# OpenAI API Key
echo ""
echo -e "${YELLOW}3. OpenAI API Key${NC}"
echo "   Get from: https://platform.openai.com/api-keys"
echo "   Format: sk-proj-..."
echo ""
read -p "Enter OPENAI_API_KEY: " OPENAI_KEY

if [ -z "$OPENAI_KEY" ]; then
  echo -e "${RED}❌ OpenAI key is required!${NC}"
  exit 1
fi

# Optional configurations
echo ""
echo "============================================================================"
echo -e "${BLUE}Optional Configurations (press Enter to use defaults)${NC}"
echo "============================================================================"
echo ""

# OpenAI Audio Model
echo -e "${YELLOW}4. OpenAI Audio Model${NC}"
echo "   Options:"
echo "     • gpt-4o-mini-audio-preview (cost-effective, recommended)"
echo "     • gpt-4o-audio-preview (premium quality)"
echo "   Default: gpt-4o-mini-audio-preview"
echo ""
read -p "Enter OPENAI_AUDIO_MODEL [gpt-4o-mini-audio-preview]: " OPENAI_MODEL
OPENAI_MODEL=${OPENAI_MODEL:-gpt-4o-mini-audio-preview}

# OpenAI Max Tokens
echo ""
echo -e "${YELLOW}5. OpenAI Max Tokens${NC}"
echo "   Maximum tokens for AI responses"
echo "   Default: 3500"
echo ""
read -p "Enter OPENAI_MAX_TOKENS [3500]: " OPENAI_TOKENS
OPENAI_TOKENS=${OPENAI_TOKENS:-3500}

# OpenAI TTS Voice
echo ""
echo -e "${YELLOW}6. OpenAI TTS Voice${NC}"
echo "   Options: alloy, echo, fable, onyx, nova, shimmer"
echo "   Default: alloy"
echo ""
read -p "Enter OPENAI_TTS_VOICE [alloy]: " OPENAI_VOICE
OPENAI_VOICE=${OPENAI_VOICE:-alloy}

# OpenAI Audio Format
echo ""
echo -e "${YELLOW}7. OpenAI Audio Format${NC}"
echo "   Options: wav, mp3"
echo "   Default: wav"
echo ""
read -p "Enter OPENAI_AUDIO_FORMAT [wav]: " OPENAI_FORMAT
OPENAI_FORMAT=${OPENAI_FORMAT:-wav}

# Confirmation
echo ""
echo "============================================================================"
echo -e "${BLUE}Review Configuration${NC}"
echo "============================================================================"
echo ""
echo "Required:"
echo "  STRIPE_SECRET_KEY: ${STRIPE_KEY:0:20}... (${#STRIPE_KEY} chars)"
echo "  STRIPE_WEBHOOK_SECRET: ${STRIPE_WEBHOOK_SECRET:0:20}... (${#STRIPE_WEBHOOK_SECRET} chars)"
echo "  OPENAI_API_KEY: ${OPENAI_KEY:0:20}... (${#OPENAI_KEY} chars)"
echo ""
echo "Optional:"
echo "  OPENAI_AUDIO_MODEL: $OPENAI_MODEL"
echo "  OPENAI_MAX_TOKENS: $OPENAI_TOKENS"
echo "  OPENAI_TTS_VOICE: $OPENAI_VOICE"
echo "  OPENAI_AUDIO_FORMAT: $OPENAI_FORMAT"
echo ""

read -p "Proceed with setting these secrets? (y/N): " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 1
fi

# Set secrets
echo ""
echo "============================================================================"
echo -e "${BLUE}Setting Secrets...${NC}"
echo "============================================================================"
echo ""

echo -e "${YELLOW}Setting STRIPE_SECRET_KEY...${NC}"
npx supabase secrets set STRIPE_SECRET_KEY="$STRIPE_KEY"

echo -e "${YELLOW}Setting STRIPE_WEBHOOK_SECRET...${NC}"
npx supabase secrets set STRIPE_WEBHOOK_SECRET="$STRIPE_WEBHOOK_SECRET"

echo -e "${YELLOW}Setting OPENAI_API_KEY...${NC}"
npx supabase secrets set OPENAI_API_KEY="$OPENAI_KEY"

echo -e "${YELLOW}Setting OPENAI_AUDIO_MODEL...${NC}"
npx supabase secrets set OPENAI_AUDIO_MODEL="$OPENAI_MODEL"

echo -e "${YELLOW}Setting OPENAI_MAX_TOKENS...${NC}"
npx supabase secrets set OPENAI_MAX_TOKENS="$OPENAI_TOKENS"

echo -e "${YELLOW}Setting OPENAI_TTS_VOICE...${NC}"
npx supabase secrets set OPENAI_TTS_VOICE="$OPENAI_VOICE"

echo -e "${YELLOW}Setting OPENAI_AUDIO_FORMAT...${NC}"
npx supabase secrets set OPENAI_AUDIO_FORMAT="$OPENAI_FORMAT"

# Verify
echo ""
echo "============================================================================"
echo -e "${BLUE}Verifying Secrets...${NC}"
echo "============================================================================"
echo ""
npx supabase secrets list

# Success
echo ""
echo "============================================================================"
echo -e "${GREEN}✅ All secrets configured successfully!${NC}"
echo "============================================================================"
echo ""
echo "Next steps:"
echo "  1. Deploy Edge Functions: ./scripts/deploy-edge-functions.sh"
echo "  2. Test functions in Dashboard"
echo "  3. Monitor logs for any issues"
echo ""
echo -e "${BLUE}📖 See EDGE_FUNCTIONS_CONFIG.md for more details${NC}"
echo ""

