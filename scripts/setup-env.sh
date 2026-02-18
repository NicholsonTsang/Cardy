#!/bin/bash
# =============================================================================
# FunTell - Interactive Environment Setup
# =============================================================================
# Guides you through creating both .env files from scratch.
# Run once before first deployment or dev setup.
#
# Usage:
#   ./scripts/setup-env.sh              # Interactive full setup
#   ./scripts/setup-env.sh --backend    # Backend .env only
#   ./scripts/setup-env.sh --frontend   # Frontend .env only
# =============================================================================

set -e

# ─── Colors ───────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

# ─── Helpers ──────────────────────────────────────────────────────────────────
header()  { echo ""; echo -e "${BLUE}${BOLD}══════════════════════════════════════════${NC}"; echo -e "${BLUE}${BOLD}  $1${NC}"; echo -e "${BLUE}${BOLD}══════════════════════════════════════════${NC}"; echo ""; }
section() { echo ""; echo -e "${CYAN}${BOLD}▸ $1${NC}"; echo ""; }
ok()      { echo -e "  ${GREEN}✓${NC} $1"; }
warn()    { echo -e "  ${YELLOW}⚠${NC}  $1"; }
err()     { echo -e "  ${RED}✗${NC} $1"; }
info()    { echo -e "  ${BLUE}ℹ${NC}  $1"; }

# Prompt with optional default. Stores result in REPLY.
prompt() {
    local label="$1" default="$2" secret="$3"
    if [[ -n "$default" ]]; then
        printf "  %s [%s]: " "$label" "$default"
    else
        printf "  %s: " "$label"
    fi
    if [[ "$secret" == "secret" ]]; then
        read -s REPLY; echo ""
    else
        read REPLY
    fi
    if [[ -z "$REPLY" && -n "$default" ]]; then REPLY="$default"; fi
}

# Write a key=value line to a file, quoting values with spaces
writenv() { echo "${1}=${2}" >> "$3"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(realpath "$SCRIPT_DIR/..")"
BACKEND_DIR="$ROOT_DIR/backend-server"

DO_BACKEND=true
DO_FRONTEND=true
[[ "$1" == "--backend"  ]] && DO_FRONTEND=false
[[ "$1" == "--frontend" ]] && DO_BACKEND=false

# ═══════════════════════════════════════════════════════════════════════════════
echo ""
echo -e "${BLUE}${BOLD}╔══════════════════════════════════════════╗${NC}"
echo -e "${BLUE}${BOLD}║   FunTell Environment Setup              ║${NC}"
echo -e "${BLUE}${BOLD}╚══════════════════════════════════════════╝${NC}"
echo ""
echo -e "  This script will create your ${BOLD}.env${NC} files interactively."
echo -e "  Press ${BOLD}Enter${NC} to accept the [default value] shown in brackets."
echo ""

# ─── Mode ─────────────────────────────────────────────────────────────────────
prompt "Is this a production deployment? (y/n)" "n"
IS_PROD=false
[[ "$REPLY" =~ ^[Yy]$ ]] && IS_PROD=true

if $IS_PROD; then
    info "Mode: ${BOLD}PRODUCTION${NC}"
else
    info "Mode: ${BOLD}DEVELOPMENT${NC}"
fi

# ═══════════════════════════════════════════════════════════════════════════════
# BACKEND .env
# ═══════════════════════════════════════════════════════════════════════════════
if $DO_BACKEND; then

header "Backend Configuration  (backend-server/.env)"

BACKEND_ENV="$BACKEND_DIR/.env"
if [[ -f "$BACKEND_ENV" ]]; then
    warn "backend-server/.env already exists."
    prompt "Overwrite it? (y/n)" "n"
    [[ ! "$REPLY" =~ ^[Yy]$ ]] && { info "Skipping backend .env."; DO_BACKEND=false; }
fi

if $DO_BACKEND; then
    > "$BACKEND_ENV"   # truncate/create

    # ── Supabase ────────────────────────────────────────────────────────────
    section "Supabase (Database & Auth)"
    info "Find these at: supabase.com → Project Settings → API"
    prompt "Supabase Project URL" "https://xxxx.supabase.co"
    SUPA_URL="$REPLY"
    prompt "Supabase Service Role Key (secret)" "" secret
    SUPA_KEY="$REPLY"

    {
        echo "# Supabase"
        writenv SUPABASE_URL         "$SUPA_URL"
        writenv SUPABASE_SERVICE_ROLE_KEY "$SUPA_KEY"
        echo ""
    } >> "$BACKEND_ENV"

    # ── OpenAI ──────────────────────────────────────────────────────────────
    section "OpenAI (Voice TTS & Realtime)"
    info "Find at: platform.openai.com → API Keys"
    prompt "OpenAI API Key (secret)" "" secret
    OAI_KEY="$REPLY"

    {
        echo "# OpenAI"
        writenv OPENAI_API_KEY              "$OAI_KEY"
        writenv OPENAI_TEXT_MODEL           "gpt-4o-mini"
        writenv OPENAI_TTS_MODEL            "tts-1"
        writenv OPENAI_TTS_VOICE            "alloy"
        writenv OPENAI_AUDIO_FORMAT         "wav"
        writenv OPENAI_MAX_TOKENS           "3500"
        writenv OPENAI_REALTIME_MODEL       "gpt-realtime-mini-2025-12-15"
        echo ""
    } >> "$BACKEND_ENV"

    # ── Google Gemini ────────────────────────────────────────────────────────
    section "Google Gemini (Chat & Translations)"
    info "Create a service account at: console.cloud.google.com"
    info "Enable the 'Generative Language API' and download the JSON key."
    prompt "Path to Gemini service account JSON" "gemini-service-account.json"
    GEMINI_CREDS="$REPLY"

    {
        echo "# Google Gemini"
        writenv GOOGLE_APPLICATION_CREDENTIALS "$GEMINI_CREDS"
        writenv GEMINI_CHAT_MODEL              "gemini-2.5-flash-lite"
        writenv GEMINI_CHAT_MAX_TOKENS         "3500"
        writenv GEMINI_CHAT_TEMPERATURE        "0.7"
        writenv GEMINI_TRANSLATION_MODEL       "gemini-2.5-flash-lite"
        writenv GEMINI_TRANSLATION_MAX_TOKENS  "30000"
        writenv GEMINI_TRANSLATION_TEMPERATURE "0.3"
        echo ""
    } >> "$BACKEND_ENV"

    # ── Stripe ───────────────────────────────────────────────────────────────
    section "Stripe (Payments)"
    info "Find at: dashboard.stripe.com → Developers → API Keys"
    if $IS_PROD; then
        info "Use LIVE keys (sk_live_..., pk_live_...)"
    else
        info "Use TEST keys (sk_test_..., pk_test_...)"
    fi
    prompt "Stripe Secret Key (secret)" "" secret
    STRIPE_SK="$REPLY"
    prompt "Stripe Webhook Secret (secret — from Stripe CLI or Dashboard)" "" secret
    STRIPE_WH="$REPLY"
    echo ""
    info "Create 3 recurring prices in Stripe Dashboard (monthly):"
    info "  Starter: \$40/mo | Premium: \$280/mo | Enterprise: \$1,000/mo"
    prompt "Stripe Starter Price ID"  "price_"
    STRIPE_STARTER="$REPLY"
    prompt "Stripe Premium Price ID"  "price_"
    STRIPE_PREMIUM="$REPLY"
    prompt "Stripe Enterprise Price ID" "price_"
    STRIPE_ENTERPRISE="$REPLY"

    {
        echo "# Stripe"
        writenv STRIPE_SECRET_KEY          "$STRIPE_SK"
        writenv STRIPE_WEBHOOK_SECRET      "$STRIPE_WH"
        writenv STRIPE_API_VERSION         "2025-08-27.basil"
        writenv STRIPE_STARTER_PRICE_ID    "$STRIPE_STARTER"
        writenv STRIPE_PREMIUM_PRICE_ID    "$STRIPE_PREMIUM"
        writenv STRIPE_ENTERPRISE_PRICE_ID "$STRIPE_ENTERPRISE"
        echo ""
    } >> "$BACKEND_ENV"

    # ── Redis ────────────────────────────────────────────────────────────────
    section "Upstash Redis (Session Tracking & Caching)"
    info "Create a free Redis database at: console.upstash.com"
    prompt "Upstash Redis REST URL" "https://xxx.upstash.io"
    REDIS_URL="$REPLY"
    prompt "Upstash Redis REST Token (secret)" "" secret
    REDIS_TOKEN="$REPLY"

    {
        echo "# Upstash Redis"
        writenv UPSTASH_REDIS_REST_URL   "$REDIS_URL"
        writenv UPSTASH_REDIS_REST_TOKEN "$REDIS_TOKEN"
        echo ""
    } >> "$BACKEND_ENV"

    # ── CORS / Server ────────────────────────────────────────────────────────
    section "Server & CORS"
    if $IS_PROD; then
        prompt "Allowed CORS origins (comma-separated, e.g. https://app.com)" "https://funtell.ai"
    else
        prompt "Allowed CORS origins" "*"
    fi
    CORS_ORIGINS="$REPLY"

    {
        echo "# Server"
        writenv PORT             "8080"
        writenv NODE_ENV         "$($IS_PROD && echo 'production' || echo 'development')"
        writenv ALLOWED_ORIGINS  "$CORS_ORIGINS"
        echo ""
        echo "# Rate Limiting"
        writenv RATE_LIMIT_WINDOW_MS   "900000"
        writenv RATE_LIMIT_MAX_REQUESTS "$($IS_PROD && echo '200' || echo '100')"
        echo ""
        echo "# Subscription Tiers"
        writenv FREE_TIER_PROJECT_LIMIT         "3"
        writenv FREE_TIER_MONTHLY_SESSION_LIMIT "50"
        writenv STARTER_PROJECT_LIMIT           "5"
        writenv STARTER_MONTHLY_FEE_USD         "40"
        writenv STARTER_MONTHLY_BUDGET_USD      "40"
        writenv STARTER_AI_ENABLED_SESSION_COST_USD  "0.05"
        writenv STARTER_AI_DISABLED_SESSION_COST_USD "0.025"
        writenv STARTER_MAX_LANGUAGES           "2"
        writenv PREMIUM_PROJECT_LIMIT           "35"
        writenv PREMIUM_MONTHLY_FEE_USD         "280"
        writenv PREMIUM_MONTHLY_BUDGET_USD      "280"
        writenv PREMIUM_AI_ENABLED_SESSION_COST_USD  "0.04"
        writenv PREMIUM_AI_DISABLED_SESSION_COST_USD "0.02"
        writenv ENTERPRISE_PROJECT_LIMIT           "100"
        writenv ENTERPRISE_MONTHLY_FEE_USD         "1000"
        writenv ENTERPRISE_MONTHLY_BUDGET_USD      "1000"
        writenv ENTERPRISE_AI_ENABLED_SESSION_COST_USD  "0.02"
        writenv ENTERPRISE_AI_DISABLED_SESSION_COST_USD "0.01"
        writenv OVERAGE_CREDITS_PER_BATCH       "5"
        echo ""
        echo "# Voice Credits"
        writenv VOICE_CREDIT_PACKAGE_SIZE      "35"
        writenv VOICE_CREDIT_PACKAGE_PRICE_USD "5"
        writenv VOICE_CALL_HARD_LIMIT_SECONDS  "180"
        echo ""
        echo "# Session Tracking"
        writenv SESSION_EXPIRATION_SECONDS    "1800"
        writenv SESSION_DEDUP_WINDOW_SECONDS  "1800"
        writenv SCAN_DEDUP_WINDOW_SECONDS     "1800"
        writenv CACHE_CARD_CONTENT_TTL        "300"
        echo ""
        echo "# Debug (set to true for verbose logs)"
        writenv DEBUG_REQUESTS "false"
        writenv DEBUG_AUTH     "false"
        writenv DEBUG_USAGE    "false"
    } >> "$BACKEND_ENV"

    ok "backend-server/.env created"
fi

fi  # DO_BACKEND

# ═══════════════════════════════════════════════════════════════════════════════
# FRONTEND .env
# ═══════════════════════════════════════════════════════════════════════════════
if $DO_FRONTEND; then

header "Frontend Configuration  (.env)"

FRONTEND_ENV="$ROOT_DIR/.env"
if [[ -f "$FRONTEND_ENV" ]]; then
    warn ".env already exists."
    prompt "Overwrite it? (y/n)" "n"
    [[ ! "$REPLY" =~ ^[Yy]$ ]] && { info "Skipping frontend .env."; DO_FRONTEND=false; }
fi

if $DO_FRONTEND; then
    > "$FRONTEND_ENV"

    # ── Backend URL ──────────────────────────────────────────────────────────
    section "Backend URL"
    if $IS_PROD; then
        info "This is the Cloud Run service URL (set after backend deployment)."
        info "You can update this later by re-running: ./scripts/setup-env.sh --frontend"
        prompt "Backend API URL" "https://funtell-backend-xxxx.a.run.app"
    else
        prompt "Backend API URL" "http://localhost:8080"
    fi
    BACKEND_URL="$REPLY"

    # ── Supabase (Frontend) ──────────────────────────────────────────────────
    section "Supabase (Frontend)"
    info "Use the same project as the backend. Find at: supabase.com → Project Settings → API"
    prompt "Supabase Project URL" "$SUPA_URL"
    VITE_SUPA_URL="$REPLY"
    prompt "Supabase Anon Key (public, not the service role key)" ""
    VITE_SUPA_ANON="$REPLY"

    # ── App URL ──────────────────────────────────────────────────────────────
    section "App URL"
    if $IS_PROD; then
        prompt "Production app URL (for SEO & sharing)" "https://funtell.ai"
    else
        prompt "App URL" "http://localhost:5173"
    fi
    APP_URL="$REPLY"

    # ── Stripe (Frontend) ────────────────────────────────────────────────────
    section "Stripe Publishable Key"
    info "Find at: dashboard.stripe.com → Developers → API Keys"
    prompt "Stripe Publishable Key" "pk_test_"
    VITE_STRIPE_PK="$REPLY"

    # ── Success URL ──────────────────────────────────────────────────────────
    STRIPE_SUCCESS="$APP_URL/cms/credits"

    {
        echo "# Backend"
        writenv VITE_BACKEND_URL "$BACKEND_URL"
        echo ""
        echo "# Supabase"
        writenv VITE_SUPABASE_URL             "$VITE_SUPA_URL"
        writenv VITE_SUPABASE_ANON_KEY        "$VITE_SUPA_ANON"
        writenv VITE_SUPABASE_USER_FILES_BUCKET "userfiles"
        echo ""
        echo "# App"
        writenv VITE_APP_URL "$APP_URL"
        echo ""
        echo "# Stripe"
        writenv VITE_STRIPE_PUBLISHABLE_KEY "$VITE_STRIPE_PK"
        writenv VITE_STRIPE_SUCCESS_URL      "$STRIPE_SUCCESS"
        echo ""
        echo "# Subscription Tiers (must match backend values)"
        writenv VITE_FREE_TIER_PROJECT_LIMIT         "3"
        writenv VITE_FREE_TIER_MONTHLY_SESSION_LIMIT "50"
        writenv VITE_STARTER_PROJECT_LIMIT           "5"
        writenv VITE_STARTER_MONTHLY_FEE_USD         "40"
        writenv VITE_STARTER_MONTHLY_BUDGET_USD      "40"
        writenv VITE_STARTER_AI_ENABLED_SESSION_COST_USD  "0.05"
        writenv VITE_STARTER_AI_DISABLED_SESSION_COST_USD "0.025"
        writenv VITE_STARTER_MAX_LANGUAGES           "2"
        writenv VITE_PREMIUM_PROJECT_LIMIT           "35"
        writenv VITE_PREMIUM_MONTHLY_FEE_USD         "280"
        writenv VITE_PREMIUM_MONTHLY_BUDGET_USD      "280"
        writenv VITE_PREMIUM_AI_ENABLED_SESSION_COST_USD  "0.04"
        writenv VITE_PREMIUM_AI_DISABLED_SESSION_COST_USD "0.02"
        writenv VITE_ENTERPRISE_PROJECT_LIMIT           "100"
        writenv VITE_ENTERPRISE_MONTHLY_FEE_USD         "1000"
        writenv VITE_ENTERPRISE_MONTHLY_BUDGET_USD      "1000"
        writenv VITE_ENTERPRISE_AI_ENABLED_SESSION_COST_USD  "0.02"
        writenv VITE_ENTERPRISE_AI_DISABLED_SESSION_COST_USD "0.01"
        writenv VITE_OVERAGE_CREDITS_PER_BATCH       "5"
        echo ""
        echo "# Voice Credits"
        writenv VITE_VOICE_CREDIT_PACKAGE_SIZE      "35"
        writenv VITE_VOICE_CREDIT_PACKAGE_PRICE_USD "5"
        writenv VITE_VOICE_CALL_HARD_LIMIT_SECONDS  "180"
        echo ""
        echo "# Content Pagination"
        writenv VITE_CONTENT_PAGE_SIZE          "20"
        writenv VITE_CONTENT_PREVIEW_LENGTH     "200"
        writenv VITE_LARGE_CARD_THRESHOLD       "50"
        writenv VITE_INFINITE_SCROLL_THRESHOLD  "200"
        echo ""
        echo "# Realtime Voice Activity Detection"
        writenv VITE_REALTIME_VAD_THRESHOLD       "0.65"
        writenv VITE_REALTIME_VAD_PREFIX_PADDING  "300"
        writenv VITE_REALTIME_VAD_SILENCE_DURATION "800"
        echo ""
        echo "# Contact"
        writenv VITE_CONTACT_EMAIL        "inquiry@funtell.com"
        writenv VITE_CONTACT_WHATSAPP_URL "https://wa.me/85255992159"
        writenv VITE_CONTACT_PHONE        "+852 5599 2159"
        echo ""
        echo "# Aspect Ratios"
        writenv VITE_CARD_ASPECT_RATIO_WIDTH    "2"
        writenv VITE_CARD_ASPECT_RATIO_HEIGHT   "3"
        writenv VITE_CONTENT_ASPECT_RATIO_WIDTH  "4"
        writenv VITE_CONTENT_ASPECT_RATIO_HEIGHT "3"
        echo ""
        echo "# Digital Access"
        writenv VITE_DIGITAL_ACCESS_DEFAULT_DAILY_LIMIT "500"
    } >> "$FRONTEND_ENV"

    ok ".env created"
fi

fi  # DO_FRONTEND

# ═══════════════════════════════════════════════════════════════════════════════
echo ""
echo -e "${GREEN}${BOLD}╔══════════════════════════════════════════╗${NC}"
echo -e "${GREEN}${BOLD}║   Environment Setup Complete!            ║${NC}"
echo -e "${GREEN}${BOLD}╚══════════════════════════════════════════╝${NC}"
echo ""

$DO_BACKEND  && ok "backend-server/.env"
$DO_FRONTEND && ok ".env (frontend)"

echo ""
echo -e "${YELLOW}${BOLD}Next Steps:${NC}"
echo ""
if ! $IS_PROD; then
    echo -e "  1. Apply database schema → see ${BOLD}docs/developer/DEPLOYMENT.md${NC}"
    echo -e "  2. Start backend:  ${CYAN}cd backend-server && npm run dev${NC}"
    echo -e "  3. Start frontend: ${CYAN}npm run dev${NC}"
else
    echo -e "  1. Apply database schema → see ${BOLD}docs/developer/DEPLOYMENT.md${NC}"
    echo -e "  2. Deploy backend:  ${CYAN}./scripts/deploy-cloud-run.sh${NC}"
    echo -e "  3. Update VITE_BACKEND_URL in .env with the Cloud Run URL"
    echo -e "  4. Build frontend:  ${CYAN}npm run build:production${NC}"
    echo -e "  5. Upload ${CYAN}dist/${NC} to your static host (Vercel / Netlify / Firebase)"
fi
echo ""
warn "Never commit .env files to git — they contain secrets."
echo ""
