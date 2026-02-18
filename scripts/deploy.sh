#!/bin/bash
# =============================================================================
# FunTell - Full Deployment Script
# =============================================================================
# Orchestrates the complete deployment of the FunTell platform:
#   1. Pre-flight checks
#   2. Database SQL (manual copy-paste reminder + verification)
#   3. Backend → Google Cloud Run
#   4. MCP Server → Google Cloud Run (optional)
#   5. Frontend build
#   6. Post-deploy smoke tests
#
# Usage:
#   ./scripts/deploy.sh              # Full deployment (backend + frontend)
#   ./scripts/deploy.sh --backend    # Backend only
#   ./scripts/deploy.sh --frontend   # Frontend build only
#   ./scripts/deploy.sh --mcp        # MCP server only
#   ./scripts/deploy.sh --check      # Pre-flight checks only
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
err()     { echo -e "  ${RED}✗${NC} $1"; exit 1; }
info()    { echo -e "  ${BLUE}ℹ${NC}  $1"; }
step()    { echo -e "${BLUE}${BOLD}[$1]${NC} $2"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(realpath "$SCRIPT_DIR/..")"
BACKEND_DIR="$ROOT_DIR/backend-server"

DO_BACKEND=true
DO_FRONTEND=true
DO_MCP=false   # MCP is opt-in; use --mcp or prompted during full deploy
CHECK_ONLY=false

case "${1:-}" in
    --backend)  DO_FRONTEND=false; DO_MCP=false ;;
    --frontend) DO_BACKEND=false;  DO_MCP=false ;;
    --mcp)      DO_BACKEND=false;  DO_FRONTEND=false; DO_MCP=true ;;
    --check)    CHECK_ONLY=true ;;
esac

# ═══════════════════════════════════════════════════════════════════════════════
echo ""
echo -e "${BLUE}${BOLD}╔══════════════════════════════════════════╗${NC}"
echo -e "${BLUE}${BOLD}║   FunTell Deployment                     ║${NC}"
echo -e "${BLUE}${BOLD}╚══════════════════════════════════════════╝${NC}"
echo ""

# ═══════════════════════════════════════════════════════════════════════════════
header "Pre-flight Checks"
# ═══════════════════════════════════════════════════════════════════════════════
CHECKS_PASSED=true

# ── Tool checks ─────────────────────────────────────────────────────────────
section "Required Tools"
for tool in node npm gcloud curl; do
    if command -v "$tool" &>/dev/null; then
        ok "$tool $(${tool} --version 2>&1 | head -1)"
    else
        err "Missing required tool: $tool"
        CHECKS_PASSED=false
    fi
done

# ── .env files ──────────────────────────────────────────────────────────────
section "Environment Files"
if [[ -f "$BACKEND_DIR/.env" ]]; then
    ok "backend-server/.env exists"
else
    warn "backend-server/.env not found — run: ./scripts/setup-env.sh --backend"
    CHECKS_PASSED=false
fi

if [[ -f "$ROOT_DIR/.env" ]]; then
    ok ".env (frontend) exists"
else
    warn ".env not found — run: ./scripts/setup-env.sh --frontend"
    CHECKS_PASSED=false
fi

# ── Backend .env required keys ───────────────────────────────────────────────
if [[ -f "$BACKEND_DIR/.env" ]]; then
    section "Backend .env — Required Keys"
    source "$BACKEND_DIR/.env" 2>/dev/null || true
    REQUIRED_BACKEND_KEYS=(
        SUPABASE_URL
        SUPABASE_SERVICE_ROLE_KEY
        OPENAI_API_KEY
        GOOGLE_APPLICATION_CREDENTIALS
        STRIPE_SECRET_KEY
        STRIPE_WEBHOOK_SECRET
        STRIPE_STARTER_PRICE_ID
        STRIPE_PREMIUM_PRICE_ID
        STRIPE_ENTERPRISE_PRICE_ID
        UPSTASH_REDIS_REST_URL
        UPSTASH_REDIS_REST_TOKEN
    )
    for key in "${REQUIRED_BACKEND_KEYS[@]}"; do
        val="${!key}"
        if [[ -z "$val" || "$val" == "price_" || "$val" == "https://xxxx.supabase.co" || "$val" == "https://xxx.upstash.io" ]]; then
            warn "$key is not set or still has placeholder value"
            CHECKS_PASSED=false
        else
            ok "$key is set"
        fi
    done

    # Gemini credentials file
    if [[ -n "$GOOGLE_APPLICATION_CREDENTIALS" && ! -f "$BACKEND_DIR/$GOOGLE_APPLICATION_CREDENTIALS" && ! -f "$GOOGLE_APPLICATION_CREDENTIALS" ]]; then
        warn "GOOGLE_APPLICATION_CREDENTIALS file not found: $GOOGLE_APPLICATION_CREDENTIALS"
        CHECKS_PASSED=false
    fi
fi

# ── Frontend .env required keys ──────────────────────────────────────────────
if [[ -f "$ROOT_DIR/.env" ]]; then
    section "Frontend .env — Required Keys"
    # Read without sourcing (avoid VITE_ prefix conflicts)
    check_vite_key() {
        local key="$1"
        local val
        val=$(grep "^${key}=" "$ROOT_DIR/.env" | cut -d'=' -f2-)
        if [[ -z "$val" || "$val" == "pk_test_" || "$val" == "https://xxxx.supabase.co" ]]; then
            warn "$key is not set or still has placeholder value"
            CHECKS_PASSED=false
        else
            ok "$key is set"
        fi
    }
    check_vite_key VITE_BACKEND_URL
    check_vite_key VITE_SUPABASE_URL
    check_vite_key VITE_SUPABASE_ANON_KEY
    check_vite_key VITE_STRIPE_PUBLISHABLE_KEY
fi

# ── MCP .env (if mcp-server/ exists and --mcp flag used) ────────────────────
MCP_DIR="$ROOT_DIR/mcp-server"
if [[ -d "$MCP_DIR" ]]; then
    if $DO_MCP; then
        section "MCP Server .env — Required Keys"
        check_mcp_key() {
            local key="$1"
            local val
            val=$(grep "^${key}=" "$MCP_DIR/.env" 2>/dev/null | cut -d'=' -f2-)
            if [[ -z "$val" || "$val" == "https://xxxx.supabase.co" ]]; then
                warn "$key is not set in mcp-server/.env"
                CHECKS_PASSED=false
            else
                ok "$key is set"
            fi
        }
        if [[ -f "$MCP_DIR/.env" ]]; then
            check_mcp_key SUPABASE_URL
            check_mcp_key SUPABASE_ANON_KEY
            check_mcp_key BACKEND_URL
        else
            warn "mcp-server/.env not found — run: ./scripts/setup-env.sh --mcp"
            CHECKS_PASSED=false
        fi
    fi
fi

# ── Docker / Cloud Run files ─────────────────────────────────────────────────
if $DO_BACKEND; then
    section "Backend Build Files"
    for f in "Dockerfile" "package.json" "package-lock.json" "tsconfig.json"; do
        if [[ -f "$BACKEND_DIR/$f" ]]; then
            ok "$f"
        else
            warn "Missing: backend-server/$f"
            CHECKS_PASSED=false
        fi
    done
fi

echo ""
if $CHECKS_PASSED; then
    ok "All pre-flight checks passed"
else
    warn "Some checks failed — review warnings above before proceeding"
fi

$CHECK_ONLY && { echo ""; info "Check-only mode. Done."; echo ""; exit 0; }

echo ""
if ! $CHECKS_PASSED; then
    read -rp "  Continue anyway? (y/n) [n]: " CONTINUE
    [[ ! "$CONTINUE" =~ ^[Yy]$ ]] && { echo "Aborted."; exit 1; }
fi

# ═══════════════════════════════════════════════════════════════════════════════
header "Database"
# ═══════════════════════════════════════════════════════════════════════════════
echo -e "  Database schema is deployed ${BOLD}manually${NC} via Supabase Dashboard."
echo ""
echo -e "  ${BOLD}SQL files to apply (in order):${NC}"
echo -e "    1. ${CYAN}sql/schema.sql${NC}               — tables, enums, indexes"
echo -e "    2. ${CYAN}sql/triggers.sql${NC}             — automatic triggers"
echo -e "    3. ${CYAN}sql/policy.sql${NC}               — RLS policies"
echo -e "    4. ${CYAN}sql/storage_policies.sql${NC}     — Storage bucket policies"
echo -e "    5. ${CYAN}sql/all_stored_procedures.sql${NC} — all stored procedures (generated)"
echo ""
echo -e "  ${BOLD}Steps:${NC}"
echo -e "    a. Open ${CYAN}https://supabase.com/dashboard${NC}"
echo -e "    b. Select your project → SQL Editor"
echo -e "    c. Paste and run each file in the order above"
echo ""
read -rp "  Have you applied the database SQL? (y/n) [n]: " DB_DONE
if [[ ! "$DB_DONE" =~ ^[Yy]$ ]]; then
    warn "Skipping deployment — apply database SQL first, then re-run this script."
    exit 0
fi
ok "Database confirmed"

# ═══════════════════════════════════════════════════════════════════════════════
# BACKEND DEPLOYMENT
# ═══════════════════════════════════════════════════════════════════════════════
if $DO_BACKEND; then
    header "Backend — Google Cloud Run"
    info "This calls the existing deploy-cloud-run.sh script."
    echo ""
    read -rp "  Deploy backend to Cloud Run now? (y/n) [y]: " DEPLOY_BACKEND
    DEPLOY_BACKEND="${DEPLOY_BACKEND:-y}"
    if [[ "$DEPLOY_BACKEND" =~ ^[Yy]$ ]]; then
        echo ""
        bash "$SCRIPT_DIR/deploy-cloud-run.sh"
        echo ""
        ok "Backend deployment complete"
        echo ""
        warn "Copy the Cloud Run service URL shown above."
        echo -e "  Then update ${BOLD}VITE_BACKEND_URL${NC} in your frontend ${BOLD}.env${NC}:"
        echo -e "    ${CYAN}./scripts/setup-env.sh --frontend${NC}  (re-run to update)"
        echo -e "  Or edit ${BOLD}.env${NC} directly:  ${CYAN}VITE_BACKEND_URL=https://your-service-url${NC}"
        echo ""
        read -rp "  Press Enter once you have updated VITE_BACKEND_URL..." _
    else
        info "Skipping backend deployment."
    fi
fi

# ═══════════════════════════════════════════════════════════════════════════════
# MCP SERVER DEPLOYMENT (opt-in)
# ═══════════════════════════════════════════════════════════════════════════════
if [[ -d "$ROOT_DIR/mcp-server" ]] && ! $DO_MCP && $DO_BACKEND; then
    # During a full deploy, ask if they also want to deploy MCP
    echo ""
    read -rp "  Also deploy the MCP server? (optional — y/n) [n]: " DEPLOY_MCP_PROMPT
    [[ "$DEPLOY_MCP_PROMPT" =~ ^[Yy]$ ]] && DO_MCP=true
fi

if $DO_MCP; then
    header "MCP Server — Google Cloud Run"
    info "The MCP server exposes FunTell tools to LLM clients (Claude Code, OpenAI, etc.)"
    echo ""
    read -rp "  Deploy MCP server to Cloud Run now? (y/n) [y]: " DEPLOY_MCP_NOW
    DEPLOY_MCP_NOW="${DEPLOY_MCP_NOW:-y}"
    if [[ "$DEPLOY_MCP_NOW" =~ ^[Yy]$ ]]; then
        bash "$SCRIPT_DIR/deploy-mcp.sh"
        ok "MCP server deployment complete"
    else
        info "Skipping MCP server deployment."
    fi
fi

# ═══════════════════════════════════════════════════════════════════════════════
# FRONTEND BUILD
# ═══════════════════════════════════════════════════════════════════════════════
if $DO_FRONTEND; then
    header "Frontend — Build"

    cd "$ROOT_DIR"

    section "Installing dependencies"
    npm ci --silent
    ok "Dependencies installed"

    section "Running type check"
    if npm run typecheck 2>&1; then
        ok "Type check passed"
    else
        warn "Type errors found — build may still succeed. Check output above."
    fi

    section "Building for production"
    npm run build
    ok "Build complete — output in ${BOLD}dist/${NC}"

    echo ""
    echo -e "  ${BOLD}Upload dist/ to your static host:${NC}"
    echo ""
    echo -e "  ${CYAN}Vercel:${NC}"
    echo -e "    vercel --prod"
    echo ""
    echo -e "  ${CYAN}Netlify:${NC}"
    echo -e "    netlify deploy --prod --dir dist"
    echo ""
    echo -e "  ${CYAN}Firebase Hosting:${NC}"
    echo -e "    firebase deploy --only hosting"
    echo ""
    echo -e "  ${CYAN}Manual / any CDN:${NC}"
    echo -e "    Upload the contents of ${BOLD}dist/${NC} to your hosting provider."
    echo ""
fi

# ═══════════════════════════════════════════════════════════════════════════════
header "Post-Deploy Smoke Tests"
# ═══════════════════════════════════════════════════════════════════════════════

# Load backend URL for health check
if [[ -f "$BACKEND_DIR/.env" ]]; then
    source "$BACKEND_DIR/.env" 2>/dev/null || true
fi

# Try to get service URL from Cloud Run
BACKEND_SERVICE_URL=""
if command -v gcloud &>/dev/null; then
    BACKEND_SERVICE_URL=$(gcloud run services describe funtell-backend --region "${REGION:-us-central1}" --format 'value(status.url)' 2>/dev/null || true)
fi

if [[ -z "$BACKEND_SERVICE_URL" ]]; then
    # Fallback: parse from frontend .env
    BACKEND_SERVICE_URL=$(grep "^VITE_BACKEND_URL=" "$ROOT_DIR/.env" 2>/dev/null | cut -d'=' -f2- | tr -d '"' || true)
fi

if [[ -n "$BACKEND_SERVICE_URL" ]]; then
    section "Backend Health Check"
    echo -e "  Checking ${CYAN}${BACKEND_SERVICE_URL}/health${NC} ..."
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 15 "${BACKEND_SERVICE_URL}/health" 2>/dev/null || echo "000")
    if [[ "$HTTP_CODE" == "200" ]]; then
        ok "Health check passed (HTTP $HTTP_CODE)"
    else
        warn "Health check returned HTTP $HTTP_CODE — service may still be starting up"
        info "Retry manually: curl ${BACKEND_SERVICE_URL}/health"
    fi
else
    warn "Could not determine backend URL — skipping health check"
fi

# ═══════════════════════════════════════════════════════════════════════════════
echo ""
echo -e "${GREEN}${BOLD}╔══════════════════════════════════════════╗${NC}"
echo -e "${GREEN}${BOLD}║   Deployment Complete!                   ║${NC}"
echo -e "${GREEN}${BOLD}╚══════════════════════════════════════════╝${NC}"
echo ""

echo -e "${YELLOW}${BOLD}Post-deploy checklist:${NC}"
echo ""
echo -e "  ${BOLD}1. Stripe webhooks${NC}"
echo -e "     Register your backend URL in Stripe Dashboard:"
echo -e "     ${CYAN}https://dashboard.stripe.com/webhooks${NC}"
echo -e "     Endpoint: ${CYAN}${BACKEND_SERVICE_URL:-<your-backend-url>}/api/webhooks/stripe${NC}"
echo -e "     Events:   checkout.session.completed, customer.subscription.updated,"
echo -e "               customer.subscription.deleted, invoice.paid, invoice.payment_failed"
echo ""
echo -e "  ${BOLD}2. Supabase Auth callback URL${NC}"
echo -e "     Add your frontend domain to Supabase Auth allowed URLs:"
echo -e "     ${CYAN}https://supabase.com/dashboard → Auth → URL Configuration${NC}"
echo ""
echo -e "  ${BOLD}3. Smoke tests${NC}"
echo -e "     • Open the frontend URL and sign in"
echo -e "     • Create a test project"
echo -e "     • Scan a QR code on a mobile device"
echo -e "     • Test AI chat and voice features"
echo ""
echo -e "  ${BOLD}4. Monitor logs${NC}"
echo -e "     Backend:  ${CYAN}gcloud run services logs tail funtell-backend --region \${REGION:-us-central1}${NC}"
echo -e "     MCP:      ${CYAN}gcloud run services logs tail funtell-mcp --region \${REGION:-asia-east1}${NC}"
echo -e "     Supabase: ${CYAN}https://supabase.com/dashboard → Logs${NC}"
echo ""
if $DO_MCP; then
    echo -e "  ${BOLD}5. Connect Claude Code to MCP${NC}"
    MCP_URL=$(gcloud run services describe funtell-mcp --region "${REGION:-asia-east1}" --format 'value(status.url)' 2>/dev/null || echo "https://funtell-mcp-xxxx.run.app")
    echo -e "     Add to ${CYAN}.mcp.json${NC}:"
    echo -e '     {'
    echo -e '       "mcpServers": {'
    echo -e '         "funtell": {'
    echo -e '           "type": "streamable-http",'
    echo -e "           \"url\": \"${MCP_URL}/mcp\""
    echo -e '         }'
    echo -e '       }'
    echo -e '     }'
    echo ""
fi
