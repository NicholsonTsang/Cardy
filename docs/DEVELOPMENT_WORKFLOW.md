# Development Workflow

This guide covers setting up your local environment and common development tasks.

## Prerequisites

- Node.js 18+
- npm or yarn
- Git
- Supabase CLI (optional, for local database)

## Initial Setup

### 1. Clone and Install

```bash
git clone <repository-url>
cd Cardy

# Install frontend dependencies
npm install

# Install backend dependencies
cd backend-server
npm install
cd ..
```

### 2. Environment Configuration

**Frontend** (`.env`):
```env
VITE_BACKEND_URL=http://localhost:3001
VITE_SUPABASE_URL=<your-supabase-url>
VITE_SUPABASE_ANON_KEY=<your-supabase-anon-key>
VITE_STRIPE_PUBLISHABLE_KEY=<your-stripe-publishable-key>
```

**Backend** (`backend-server/.env`):
```env
PORT=3001
SUPABASE_URL=<your-supabase-url>
SUPABASE_SERVICE_ROLE_KEY=<your-service-role-key>
OPENAI_API_KEY=<your-openai-key>
STRIPE_SECRET_KEY=<your-stripe-secret-key>
STRIPE_WEBHOOK_SECRET=<your-webhook-secret>
UPSTASH_REDIS_REST_URL=<your-upstash-url>
UPSTASH_REDIS_REST_TOKEN=<your-upstash-token>
```

See [backend-server/ENVIRONMENT_VARIABLES.md](/backend-server/ENVIRONMENT_VARIABLES.md) for complete variable list.

### 3. Running Locally

**Terminal 1 - Frontend:**
```bash
npm run dev
```

**Terminal 2 - Backend:**
```bash
cd backend-server
npm run dev
```

Frontend runs at `http://localhost:5173`, backend at `http://localhost:3001`.

## Common Development Tasks

### Adding Translations

1. Update files in `src/i18n/locales/`:
   - `en.json` (required)
   - `zh-Hant.json` (required)
   - `zh-Hans.json` (required for mobile)
   - Other languages as needed

2. Use the `$t()` function in components:
```vue
<template>
  <p>{{ $t('feature.message') }}</p>
</template>
```

### Updating Stored Procedures

1. Edit the appropriate file in `sql/storeproc/`:
   - `client-side/` - Frontend-accessible (uses auth)
   - `server-side/` - Backend-only (uses service role)

2. Regenerate combined file:
```bash
./scripts/combine-stored-procedures.sh
```

3. Deploy via Supabase Dashboard:
   - Go to SQL Editor
   - Paste the procedure SQL
   - Execute

### Adding a New API Route

1. Create or edit route file in `backend-server/src/routes/`
2. Register in `backend-server/src/routes/index.ts`
3. All database access must use stored procedures (`.rpc()`)

### Building for Production

**Frontend:**
```bash
npm run build
```

**Backend:**
```bash
cd backend-server
npm run build
```

## Git Workflow

### Branch Naming

- `feature/` - New features
- `fix/` - Bug fixes
- `refactor/` - Code refactoring
- `docs/` - Documentation updates

### Commit Messages

Use clear, descriptive commit messages:
```
Add credit confirmation dialog for batch creation

- Display credit cost before consumption
- Show balance before/after
- Add low balance warning
```

### Pull Requests

1. Create feature branch from `main`
2. Make changes and commit
3. Push and create PR
4. Ensure CI passes
5. Request review

## Deployment

### Backend (Google Cloud Run)

```bash
./scripts/deploy-cloud-run.sh
```

### Database Changes

Manual deployment via Supabase Dashboard SQL Editor:
1. Copy SQL from schema or stored procedure file
2. Execute in SQL Editor
3. Verify changes

## Troubleshooting

### Frontend not connecting to backend

- Check `VITE_BACKEND_URL` in `.env`
- Ensure backend is running
- Check CORS configuration

### Database errors

- Verify stored procedure exists
- Check parameter names match
- Ensure proper permissions (client vs server procedures)

### Redis connection issues

- Verify Upstash credentials in backend `.env`
- Check rate limiting configuration

## Code Quality

### Linting

```bash
npm run lint
```

### Type Checking

```bash
npm run typecheck
```

### Styling Guidelines

- Use Tailwind CSS for styling
- Don't override PrimeVue component styles
- Use PrimeVue props for component customization
