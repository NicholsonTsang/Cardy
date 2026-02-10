# FunTell MCP Server

MCP (Model Context Protocol) server for managing FunTell projects — turn any information into an AI-powered, multilingual content experience. Supports products, venues, education, storytelling, knowledge bases, portfolios, and more. Exposes 22 tools for project creation, content management, AI configuration, and distribution (QR codes, links, embeds) over Streamable HTTP transport.

## Quick Start

```bash
cd mcp-server
npm install
npm run build
npm start            # Starts at http://localhost:3001/mcp
```

Requires a `.env` file:
```
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=eyJ...
BACKEND_URL=http://localhost:8080
```

## Architecture

```
mcp-server/
├── src/
│   ├── index.ts              # HTTP server, session management, graceful shutdown
│   ├── server.ts             # McpServer factory, tool registration
│   ├── supabase.ts           # Supabase client, authentication
│   ├── auth-guard.ts         # Auth middleware for tools
│   ├── backend.ts            # Backend API client (AI settings)
│   └── tools/
│       ├── projects.ts       # 5 tools: list, get, create, update, delete
│       ├── content.ts        # 7 tools: list, create, batch, update, delete, reorder, move
│       ├── access-tokens.ts  # 4 tools: list, create, update, delete
│       ├── ai-config.ts      # 2 tools: generate settings, optimize description
│       └── account.ts        # 2 tools: subscription, credits
├── build/                    # Compiled JS output
├── Dockerfile                # Cloud Run container
├── .dockerignore
├── package.json
└── tsconfig.json
```

## Tools (22 total)

| Category | Tools | Data Source |
|----------|-------|-------------|
| Auth | `login`, `get_workflow` | Supabase Auth |
| Account | `get_subscription`, `get_credit_balance` | Supabase RPC |
| Projects | `list_projects`, `get_project`, `create_project`, `update_project`, `delete_project` | Supabase RPC |
| Content | `list_content_items`, `create_content_item`, `create_content_items_batch`, `update_content_item`, `delete_content_item`, `reorder_content_item`, `move_content_item` | Supabase RPC |
| AI | `generate_ai_settings`, `optimize_description` | Backend API |
| QR Codes | `list_access_tokens`, `create_access_token`, `update_access_token`, `delete_access_token` | Supabase RPC |

## How It Works

1. LLM client connects via HTTP to `/mcp` endpoint
2. Client sends MCP `initialize` request — server creates a fresh `McpServer` + `StreamableHTTPServerTransport` pair
3. Creator authenticates via `login` tool (Supabase `signInWithPassword`)
4. All subsequent tool calls use the authenticated session (RLS-enforced)
5. Session expires after 30 minutes of inactivity

## Scripts

| Command | Description |
|---------|-------------|
| `npm run build` | Compile TypeScript to `build/` |
| `npm start` | Start server (reads `.env` file) |
| `npm run dev` | Watch mode (auto-recompile) |

## Production Features

- **Session management**: UUID-based sessions with 30-minute TTL
- **Graceful shutdown**: SIGTERM/SIGINT close all sessions before exit
- **Request limits**: 10 MB max body size
- **Timeout handling**: 60-second timeout on backend API calls
- **Health check**: `GET /health` returns status and session count
- **Docker**: Production-optimized container with health probe

## Documentation

| Document | Description |
|----------|-------------|
| [DEPLOYMENT.md](DEPLOYMENT.md) | Cloud Run deployment guide, env vars, Docker setup |
| [USAGE.md](USAGE.md) | Creator usage guide with examples and tool reference |

## Related

| Directory | Description |
|-----------|-------------|
| `../funtell-plugin/` | Claude Code plugin for creators (bundles MCP config + workflow skill) |
| `../backend-server/` | Express.js backend (AI settings, translations, payments) |
| `../sql/storeproc/` | Stored procedures called by MCP tools |
