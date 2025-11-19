# CardStudio - Digital Souvenir & Exhibition Platform

[![Vue.js](https://img.shields.io/badge/Vue.js-3-4FC08D.svg)](https://vuejs.org/)
[![TypeScript](https://img.shields.io/badge/TypeScript-blue.svg)](https://www.typescriptlang.org/)
[![Supabase](https://img.shields.io/badge/Supabase-3ECF8E.svg)](https://supabase.io/)
[![Express.js](https://img.shields.io/badge/Express.js-4.x-000000.svg)](https://expressjs.com/)
[![Google Cloud Run](https://img.shields.io/badge/Google_Cloud_Run-4285F4.svg)](https://cloud.google.com/run)

CardStudio is a comprehensive **digital souvenir and exhibition platform** that creates interactive experiences for museums, tourist attractions, and cultural sites. The platform enables institutions to provide visitors with rich, AI-powered digital content accessible through QR codes on physical souvenir cards, offering detailed explanations, guidance, and multimedia experiences about exhibits, artifacts, and locations.

## Project Overview

### Business Model & Architecture

-   **Three-Tier Ecosystem**:
    1.  **Card Issuers** (B2B) - Museums, exhibitions, tourist attractions creating digital souvenir experiences.
    2.  **Administrators** (Platform) - CardStudio operators managing verifications and operations.
    3.  **Visitors** (B2C) - Tourists and museum guests scanning QR codes for free digital content and AI guidance.

-   **Core Value Proposition**:
    -   **Interactive Digital Souvenirs**: Physical cards with QR codes link to rich multimedia content.
    -   **Credit-Based System**: Institutions purchase credits for card issuance and AI-powered translations.
    -   **Advanced AI Voice Conversations**: Real-time voice-based AI using OpenAI for natural conversations.
    -   **Multi-Language Support**: AI-powered, one-click translation of card content into multiple languages.

---

## Core Architecture

The project follows a modern web architecture with a decoupled frontend, backend, and database.

### 1. Frontend (Vue 3)

-   **Framework**: Vue 3 with Composition API and TypeScript
-   **UI**: PrimeVue 4 and Tailwind CSS
-   **State Management**: Pinia
-   **Routing**: Vue Router
-   **Build Tool**: Vite

### 2. Backend (Express.js)

The backend is an Express.js server located in the `backend-server/` directory. It handles all business logic that requires secure, server-side execution.

-   **Framework**: Express.js with TypeScript
-   **Authentication**: JWT validation via middleware, integrated with Supabase Auth.
-   **Key Services**:
    -   **Background Translation Job Processor**: Asynchronous translation processing using Supabase Realtime with automatic polling fallback
    -   Card content translation (OpenAI GPT-4.1-nano / Gemini)
    -   Payment processing (Stripe checkout and webhooks)
    -   AI chat and voice features (OpenAI)
    -   Real-time progress updates (Socket.IO)
    -   Ephemeral token generation for WebRTC connections

### 3. Database & Services (Supabase)

-   **Database**: Supabase PostgreSQL for all data storage.
-   **Database Access**: All database operations are exclusively handled via `supabase.rpc()` calls to stored procedures. **Direct table access is disabled for security.**
-   **Authentication**: Supabase Auth for user management and JWT issuance.
-   **Storage**: Supabase Storage for user-uploaded images (card images, content images).
-   **Realtime**: Supabase Realtime for instant translation job notifications (with automatic polling fallback for reliability).

---

## Local Development Setup

### Prerequisites

-   Node.js (v18+)
-   Supabase CLI (`npm install -g supabase`)
-   Stripe CLI (for webhook testing)

### Step 1: Clone and Install Dependencies

```bash
git clone <repo-url>
cd Cardy

# Install frontend dependencies
npm install

# Install backend dependencies
cd backend-server
npm install
cd ..
```

### Step 2: Configure Environment Variables

You will need to configure `.env` files for both the frontend and backend.

**Frontend (`.env`):**

```bash
# In the root directory
cp .env.example .env
```

Edit the `.env` file and set your Supabase and Stripe public keys.

**Backend (`backend-server/.env`):**

```bash
# In the backend-server directory
cd backend-server
cp .env.example .env
```

Edit the `.env` file and set all required API keys and secrets:
-   `OPENAI_API_KEY` - Your OpenAI API key for translations and AI features
-   `SUPABASE_URL` - Your Supabase project URL
-   `SUPABASE_SERVICE_ROLE_KEY` (⚠️ **CRITICAL: Keep this secret!**)
-   `STRIPE_SECRET_KEY` - Your Stripe secret key for payment processing
-   `STRIPE_WEBHOOK_SECRET` - Your Stripe webhook secret for webhook validation

**Optional Configuration** (with sensible defaults):
-   `TRANSLATION_JOB_MAX_CONCURRENT_JOBS=3` - Maximum concurrent translation jobs
-   `TRANSLATION_JOB_MAX_CONCURRENT_LANGUAGES=3` - Languages processed concurrently per job
-   `TRANSLATION_JOB_BATCH_SIZE=10` - Content items per translation batch
-   `TRANSLATION_JOB_POLLING_INTERVAL_MS=5000` - Fallback polling interval if Realtime unavailable

See `backend-server/ENVIRONMENT_VARIABLES.md` for complete documentation of all configuration options.

### Step 3: Start Local Services

1.  **Start Local Supabase**:
    ```bash
    supabase start
    # Note the local URL and keys, update frontend .env if needed
    ```

2.  **Apply Database Schema** (includes Realtime setup):
    ```bash
    # Realtime is automatically enabled when you run schema.sql
    # No manual dashboard configuration needed!
    ```
    The `schema.sql` file includes `ALTER PUBLICATION supabase_realtime ADD TABLE translation_jobs;` which automatically enables Realtime for instant translation job notifications.
    
    ⚠️ **Note**: If Realtime setup fails or is disabled, the system will automatically fallback to polling mode (5s intervals).

3.  **Start Backend Server**:
    ```bash
    cd backend-server
    npm run dev
    # Server will run on the port specified in .env (e.g., http://localhost:8085)
    # Watch for: ✅ Realtime subscription active
    ```

4.  **Start Frontend Development Server**:
    ```bash
    # From the root directory
    npm run dev
    # Frontend will be available at http://localhost:5173
    ```

---

## Project Structure

```
Cardy/
├── backend-server/    # Express.js Backend
│   ├── src/
│   │   ├── routes/         # API routes (translation, payment, ai, webhooks)
│   │   ├── services/       # Background services
│   │   │   ├── translation-job-processor.ts  # Background translation processor
│   │   │   └── socket.service.ts             # Socket.IO real-time updates
│   │   ├── middleware/     # Auth middleware
│   │   ├── config/         # Supabase client config
│   │   └── index.ts        # Server entry point
│   ├── Dockerfile          # For Cloud Run deployment
│   ├── deploy-cloud-run.sh # All-in-one deployment script
│   ├── ENVIRONMENT_VARIABLES.md     # Complete env var documentation
│   ├── REALTIME_JOB_PROCESSOR.md    # Realtime implementation guide
│   └── package.json
│
├── public/                 # Static assets for frontend
├── src/                    # Vue.js Frontend Source
│   ├── assets/
│   ├── components/
│   │   ├── Card/
│   │   │   ├── TranslationJobsPanel.vue     # Job management UI
│   │   │   ├── TranslationDialog.vue         # Translation dialog
│   │   │   └── CardTranslationSection.vue    # Translation section
│   ├── stores/             # Pinia stores
│   ├── utils/
│   ├── views/
│   └── main.ts
│
├── sql/                    # Database Schema & Stored Procedures
│   ├── schema.sql          # All tables, enums, indexes
│   ├── all_stored_procedures.sql  # GENERATED - Do not edit directly
│   ├── storeproc/          # Source files for stored procedures
│   │   ├── client-side/
│   │   └── server-side/
│   ├── policy.sql          # RLS policies
│   └── triggers.sql        # Database triggers (includes updated_at triggers)
│
├── supabase/               # Supabase local configuration
│   └── config.toml
│
├── scripts/                # Utility scripts
│   ├── combine-storeproc.sh  # Combines SQL files (includes triggers)
│   └── deploy-cloud-run.sh   # Backend deployment script
│
├── docs_archive/           # Historical documentation and logs
│   ├── backend/            # Backend-specific archival docs
│   └── ...                 # Feature implementation details, bug fixes logs
│
├── CLAUDE.md               # AI assistant project overview and recent updates
├── .env.example            # Frontend environment template
└── package.json            # Frontend dependencies
```

---

## Maintenance & Handover

### Documentation Strategy
-   **Active Documentation**: `README.md` (this file) and `CLAUDE.md` (recent updates/context) are the primary sources of truth.
-   **Historical Documentation**: Detailed implementation logs, feature specs, and bug fix reports are archived in the `docs_archive/` directory. Refer to these for deep dives into specific past decisions.

### Security Best Practices
-   **HTML Sanitization**: The project uses `dompurify` in `src/utils/markdownRenderer.ts` to sanitize HTML rendered from Markdown. Always use `renderMarkdown()` when displaying user-generated content.
-   **Environment Variables**: Never commit `.env` files. Use `.env.example` for templates.
-   **Database Access**: All database access is via Stored Procedures (`.rpc()`). Direct table access (SELECT/INSERT/UPDATE/DELETE) should remain disabled for the `anon` and `authenticated` roles in production to ensure business logic encapsulation.

### Common Maintenance Tasks
-   **Updating Database Schema**:
    1.  Modify files in `sql/` (schema or storeproc).
    2.  Run `./scripts/combine-storeproc.sh` to regenerate `all_stored_procedures.sql`.
    3.  Apply changes via Supabase Dashboard SQL Editor.
-   **Adding New Translations**: Update `src/i18n/locales/*.json` files.
-   **Updating Backend**:
    1.  Make changes in `backend-server/`.
    2.  Test locally with `npm run dev`.
    3.  Deploy using `./scripts/deploy-cloud-run.sh`.

---

## Background Translation System

CardStudio uses a **production-ready background translation job processing system** that provides instant, reliable translations with zero job loss.

### Architecture

**Mode: Supabase Realtime with Automatic Polling Fallback**

-   **Primary**: Supabase Realtime for instant job notifications (<100ms latency)
-   **Fallback**: Automatic polling every 5 seconds if Realtime unavailable
-   **Reliability**: Multiple safeguards ensure zero job loss
-   **Scalability**: Works seamlessly with multiple Cloud Run instances

### Key Features

✅ **Instant Job Pickup** - Supabase Realtime WebSocket notifications (<100ms)  
✅ **Automatic Reconnection** - Exponential backoff with up to 10 retry attempts  
✅ **Health Monitoring** - Periodic connection verification every 30 seconds  
✅ **Polling Fallback** - Seamless degradation if Realtime unavailable  
✅ **Zero Job Loss** - Multiple redundant safeguards  
✅ **Concurrent Processing** - 3 jobs × 3 languages = up to 9 translations simultaneously  
✅ **Row-Level Locking** - PostgreSQL `FOR UPDATE SKIP LOCKED` prevents duplicate processing  
✅ **Credit Safety** - Credits reserved upfront, refunded on failure  
✅ **Real-time Progress** - Socket.IO updates for connected clients  
✅ **Job Management UI** - Visual panel showing ongoing/failed jobs with retry/cancel buttons

### Documentation Links (Archived)

For detailed implementation details, refer to the following files in `docs_archive/`:
-   **`BACKGROUND_TRANSLATION_JOBS.md`** - Complete system architecture and implementation
-   **`CONCURRENCY_FIX_TRANSLATION_JOBS.md`** - Row-level locking for multi-instance safety
-   **`TRANSLATION_JOBS_TESTING_GUIDE.md`** - Comprehensive testing scenarios
-   **`JOB_MANAGEMENT_UI_SUMMARY.md`** - Job management UI overview

For current backend configuration, see:
-   **`backend-server/REALTIME_JOB_PROCESSOR.md`** - Realtime connection handling and monitoring
-   **`backend-server/ENVIRONMENT_VARIABLES.md`** - All configuration options

### Monitoring

**Watch these logs:**

```bash
# Healthy Realtime connection
✅ Realtime subscription active
📬 Realtime: New job created [id]
📥 Found 1 pending job(s)

# Automatic fallback (if needed)
⚠️  Realtime subscription closed
🔄 Attempting Realtime reconnection...
📊 Switching to polling mode (temporary)
```

---

## Deployment

The project is deployed in two parts: the backend to **Google Cloud Run** and the frontend to a **static host** (like Vercel or Netlify).

### Backend Deployment (Google Cloud Run)

The `backend-server/` directory contains the source code, but the deployment script is now centralized in the `scripts/` directory.

**Prerequisites**:
-   Google Cloud SDK (`gcloud`) installed and authenticated.
-   Your backend `.env` file is correctly configured with all production keys.

**To Deploy:**

```bash
./scripts/deploy-cloud-run.sh
```

The script will guide you through the process:
1.  Prompts for your **GCP Project ID** and **Region**.
2.  Builds the Docker container using `Dockerfile`.
3.  Pushes the container to Google Container Registry.
4.  Deploys the container to Cloud Run.
5.  **Automatically uploads all environment variables** from your `.env` file to the Cloud Run service.
6.  Tests the health endpoint and provides you with the final service URL.

**✅ Realtime Automatic Setup**: Supabase Realtime is automatically enabled when you deploy the `schema.sql` file (via `ALTER PUBLICATION supabase_realtime ADD TABLE translation_jobs;`). No manual dashboard configuration needed! The system will automatically fallback to polling mode if Realtime is unavailable.

After deployment, update your frontend's `.env` file with the new production `VITE_BACKEND_URL`.

### Frontend Deployment

1.  **Build for Production**:
    ```bash
    npm run build
    ```
2.  **Deploy**: Deploy the generated `dist/` directory to your preferred static hosting provider (Vercel, Netlify, etc.).
3.  **Environment Variables**: Ensure your hosting provider is configured with the production environment variables from your `.env` file, especially:
    -   `VITE_SUPABASE_URL`
    -   `VITE_SUPABASE_ANON_KEY`
    -   `VITE_BACKEND_URL` (from the backend deployment step)
    -   `VITE_STRIPE_PUBLISHABLE_KEY`
