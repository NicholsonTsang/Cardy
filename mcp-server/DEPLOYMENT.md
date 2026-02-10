# FunTell MCP Server — Deployment Guide

## Architecture Overview

```
LLM Client (Claude / OpenAI / Gemini / etc.)
    |  Streamable HTTP (POST/GET/DELETE /mcp)
    v
Cloud Run (funtell-mcp)
    |  Node.js HTTP Server
    v
StreamableHTTPServerTransport
    |  MCP Protocol
    v
McpServer (22 tools)
    |
    +---> Supabase (PostgreSQL via RPC)
    +---> Backend Server (AI settings)
```

## Prerequisites

- Google Cloud project with billing enabled
- `gcloud` CLI installed and authenticated
- Node.js 20+ (for local builds)
- FunTell backend server deployed (for AI and translation tools)

## Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `SUPABASE_URL` | Yes | Supabase project URL |
| `SUPABASE_ANON_KEY` | Yes | Supabase anonymous/public key |
| `BACKEND_URL` | Yes | FunTell backend server URL (e.g., `https://funtell-backend-xxx.run.app`) |
| `PORT` | No | HTTP port (Cloud Run sets this automatically, defaults to 8080) |
| `MCP_HTTP_PORT` | No | Override port (falls back to `PORT`, then 3001) |
| `MCP_HTTP_HOST` | No | Bind address (defaults to `0.0.0.0`) |

## Local Development

### Setup

```bash
cd mcp-server
npm install
```

### Create `.env` file

```bash
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=eyJ...your-anon-key
BACKEND_URL=http://localhost:8080
```

### Build and run

```bash
npm run build
npm start
```

Server starts at `http://localhost:3001/mcp`.

### Development mode

```bash
npm run dev          # Watch mode (auto-recompile on changes)
npm start            # In another terminal
```

### Verify

```bash
curl http://localhost:3001/health
# {"status":"ok","sessions":0}
```

## Cloud Run Deployment

### Option 1: Source-based deploy (recommended)

Build and deploy in one command:

```bash
cd mcp-server
npm run build

gcloud run deploy funtell-mcp \
  --source . \
  --region asia-east1 \
  --allow-unauthenticated \
  --memory 512Mi \
  --cpu 1 \
  --min-instances 0 \
  --max-instances 10 \
  --timeout 300 \
  --set-env-vars "SUPABASE_URL=https://your-project.supabase.co,SUPABASE_ANON_KEY=eyJ...,BACKEND_URL=https://funtell-backend-xxx.run.app"
```

### Option 2: Docker build + deploy

```bash
cd mcp-server
npm run build

# Build container
gcloud builds submit --tag gcr.io/YOUR_PROJECT_ID/funtell-mcp .

# Deploy
gcloud run deploy funtell-mcp \
  --image gcr.io/YOUR_PROJECT_ID/funtell-mcp \
  --platform managed \
  --region asia-east1 \
  --allow-unauthenticated \
  --port 8080 \
  --memory 512Mi \
  --cpu 1 \
  --min-instances 0 \
  --max-instances 10 \
  --timeout 300 \
  --set-env-vars "SUPABASE_URL=...,SUPABASE_ANON_KEY=...,BACKEND_URL=..."
```

### Option 3: Deploy script

```bash
./scripts/deploy-mcp.sh
```

### Get service URL

```bash
gcloud run services describe funtell-mcp \
  --region asia-east1 \
  --format 'value(status.url)'
# https://funtell-mcp-xxxxx.run.app
```

### Verify deployment

```bash
curl https://funtell-mcp-xxxxx.run.app/health
# {"status":"ok","sessions":0}
```

## Docker Configuration

The `Dockerfile` uses:
- `node:20-slim` base image
- Production-only dependencies (`npm ci --production`)
- Only copies `build/` directory (no source code)
- Built-in health check (30s interval)
- Graceful shutdown on SIGTERM

## Security

### Authentication model

The MCP server uses **Supabase anon key** (not service role). All database access goes through stored procedures with Row-Level Security (RLS) enforcing per-user ownership. The `login` tool authenticates individual creators via `signInWithPassword`.

### Cloud Run access

`--allow-unauthenticated` is used because:
- The MCP protocol itself handles user authentication via the `login` tool
- LLM clients need direct HTTP access to the `/mcp` endpoint
- Adding Cloud Run IAM would prevent LLM clients from connecting

### Session management

- Each MCP client gets a unique session with a UUID
- Sessions expire after 30 minutes of inactivity
- Stale sessions are cleaned up every 5 minutes
- Request body size is limited to 10 MB

## Monitoring

### View logs

```bash
gcloud run services logs tail funtell-mcp --region asia-east1
```

### Key log messages

| Message | Meaning |
|---------|---------|
| `FunTell MCP server started on http://...` | Server ready |
| `Session initialized: <uuid>` | New client connected |
| `Authenticated as <email>` | Creator logged in |
| `Session expired and cleaned up: <uuid>` | Idle session removed |
| `Session closed: <uuid>` | Client disconnected |

### Health check

`GET /health` returns:
```json
{"status": "ok", "sessions": 2}
```

## Updating

After code changes:

```bash
cd mcp-server
npm run build
gcloud run deploy funtell-mcp --source . --region asia-east1
```

Cloud Run performs zero-downtime rolling updates automatically.

## Troubleshooting

| Issue | Cause | Fix |
|-------|-------|-----|
| `Missing required environment variables` | `SUPABASE_URL` or `SUPABASE_ANON_KEY` not set | Set env vars in Cloud Run or `.env` file |
| `BACKEND_URL is not configured` | `BACKEND_URL` not set | Set env var — needed for AI and translation tools |
| `Login failed` | Wrong credentials | Ensure using FunTell platform credentials, not Supabase admin |
| Health check fails | Port mismatch | Cloud Run sets `PORT` env var; code reads it automatically |
| `Backend request timed out` | Backend server down or slow | Check backend server status; timeout is 60s |
