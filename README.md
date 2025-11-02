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
    -   Card content translation (OpenAI)
    -   Payment processing (Stripe checkout and webhooks)
    -   AI chat and voice features (OpenAI)
    -   Ephemeral token generation for WebRTC connections

### 3. Database & Services (Supabase)

-   **Database**: Supabase PostgreSQL for all data storage.
-   **Database Access**: All database operations are exclusively handled via `supabase.rpc()` calls to stored procedures. **Direct table access is disabled for security.**
-   **Authentication**: Supabase Auth for user management and JWT issuance.
-   **Storage**: Supabase Storage for user-uploaded images (card images, content images).

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
-   `OPENAI_API_KEY`
-   `SUPABASE_URL`
-   `SUPABASE_SERVICE_ROLE_KEY` (⚠️ **CRITICAL: Keep this secret!**)
-   `STRIPE_SECRET_KEY`
-   `STRIPE_WEBHOOK_SECRET`

### Step 3: Start Local Services

1.  **Start Local Supabase**:
    ```bash
    supabase start
    # Note the local URL and keys, update frontend .env if needed
    ```

2.  **Start Backend Server**:
    ```bash
    cd backend-server
    npm run dev
    # Server will run on the port specified in .env (e.g., http://localhost:8085)
    ```

3.  **Start Frontend Development Server**:
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
│   │   ├── middleware/     # Auth middleware
│   │   ├── config/         # Supabase client config
│   │   └── index.ts        # Server entry point
│   ├── Dockerfile          # For Cloud Run deployment
│   ├── deploy-cloud-run.sh # All-in-one deployment script
│   └── package.json
│
├── public/                 # Static assets for frontend
├── src/                    # Vue.js Frontend Source
│   ├── assets/
│   ├── components/
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
│   └── triggers.sql        # Database triggers
│
├── supabase/               # Supabase local configuration
│   └── config.toml
│
├── scripts/                # Utility scripts
│   ├── combine-storeproc.sh  # Combines SQL files
│   └── deploy-cloud-run.sh # DEPLOY SCRIPT MOVED HERE
│
├── .env.example            # Frontend environment template
└── package.json            # Frontend dependencies
```

---

## Database Management

All database schema, RLS policies, and stored procedures are managed as SQL files. **Direct modifications in the Supabase Dashboard are discouraged.**

**Update Workflow:**

1.  **Edit Source Files**: Modify the relevant files in `sql/` (e.g., `sql/schema.sql` or files in `sql/storeproc/`).
2.  **Generate Combined File**: If you edited stored procedures, run the script to combine them:
    ```bash
    ./scripts/combine-storeproc.sh
    ```
3.  **Manual Deployment**: Navigate to the **SQL Editor** in your Supabase Dashboard and execute the contents of the modified files in the following order:
    1.  `sql/schema.sql`
    2.  `sql/all_stored_procedures.sql`
    3.  `sql/policy.sql`
    4.  `sql/triggers.sql`

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
