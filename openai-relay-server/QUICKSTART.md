# OpenAI Relay Server - Quick Start Guide

Get the relay server running in **5 minutes**.

## Local Development

### Step 1: Install Dependencies

```bash
cd openai-relay-server
npm install
```

### Step 2: Start Server

```bash
npm run dev
```

Server will start on `http://localhost:8080`

### Step 3: Configure Frontend

In your main project root, create or edit `.env`:

```bash
VITE_OPENAI_RELAY_URL=ws://localhost:8080
```

### Step 4: Test

```bash
# Check health
curl http://localhost:8080/health

# Should return:
# {"status":"healthy","uptime":X,"stats":{...}}
```

### Step 5: Use in App

1. Start your frontend: `npm run dev`
2. Open AI Assistant
3. Switch to "Live Call" mode
4. Click "Start Live Call"
5. Check console for: `🔄 Connecting via relay server`

**Done!** ✅

---

## Docker Deployment

### Step 1: Create Environment File

```bash
cd openai-relay-server
cp .env.example .env
```

Edit `.env`:
```bash
NODE_ENV=production
PORT=8080
MAX_CONNECTIONS=100
ALLOWED_ORIGINS=*
```

### Step 2: Start with Docker Compose

```bash
docker-compose up -d
```

### Step 3: Verify

```bash
# Check container
docker ps | grep openai-realtime-relay

# Check health
curl http://localhost:8080/health

# View logs
docker-compose logs -f
```

**Done!** ✅

---

## Production Deployment (Railway)

### Step 1: Push to GitHub

```bash
cd ..  # Go to project root
git add openai-relay-server/
git commit -m "Add OpenAI relay server"
git push
```

### Step 2: Deploy to Railway

1. Go to [railway.app](https://railway.app)
2. Click "New Project"
3. Select "Deploy from GitHub repo"
4. Choose your repository
5. Set root path: `openai-relay-server`
6. Click "Deploy"

### Step 3: Configure Environment

In Railway dashboard, add variables:
```
NODE_ENV=production
MAX_CONNECTIONS=200
ALLOWED_ORIGINS=https://yourdomain.com
```

### Step 4: Get Railway URL

Railway provides a URL like:
```
https://openai-relay-production-xxxx.up.railway.app
```

### Step 5: Update Frontend

Edit `.env.production`:
```bash
VITE_OPENAI_RELAY_URL=wss://openai-relay-production-xxxx.up.railway.app
```

### Step 6: Deploy Frontend

```bash
npm run build:production
# Deploy to your hosting
```

**Done!** ✅

---

## Troubleshooting

### Can't Connect Locally

```bash
# Check if server is running
curl http://localhost:8080/health

# If not, check logs
npm run dev
```

### Docker Won't Start

```bash
# Check logs
docker-compose logs

# Rebuild
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```

### Frontend Can't Connect

1. Check `VITE_OPENAI_RELAY_URL` is set
2. Restart frontend dev server
3. Check browser console for errors
4. Verify relay server is running

### "CORS Error"

Update relay server `.env`:
```bash
ALLOWED_ORIGINS=http://localhost:5173,https://yourdomain.com
```

Restart relay server.

---

## Common Commands

```bash
# Development
npm run dev          # Start with hot-reload
npm run build        # Build TypeScript
npm start            # Start production server

# Docker
docker-compose up -d      # Start in background
docker-compose logs -f    # View logs
docker-compose restart    # Restart
docker-compose down       # Stop and remove

# Testing
curl http://localhost:8080/health        # Health check
curl http://localhost:8080/stats         # Statistics
```

---

## Configuration Quick Reference

### Environment Variables

| Variable | Default | Purpose |
|----------|---------|---------|
| `PORT` | `8080` | Server port |
| `MAX_CONNECTIONS` | `100` | Connection limit |
| `ALLOWED_ORIGINS` | `*` | CORS origins |
| `HEARTBEAT_INTERVAL` | `30000` | Ping interval (ms) |
| `INACTIVITY_TIMEOUT` | `300000` | Timeout (ms) |

### Frontend Environment

```bash
# Use relay server
VITE_OPENAI_RELAY_URL=ws://localhost:8080         # Local
VITE_OPENAI_RELAY_URL=wss://relay.yourdomain.com  # Production

# Direct connection (no relay)
VITE_OPENAI_RELAY_URL=                            # Empty
```

---

## Next Steps

✅ **Local working?** → Try Docker deployment
✅ **Docker working?** → Deploy to Railway/DigitalOcean
✅ **Production deployed?** → Set up monitoring and SSL

**Need more help?** See:
- Full setup guide: `OPENAI_RELAY_SERVER_SETUP.md`
- Server docs: `README.md`
- Implementation summary: `../OPENAI_RELAY_IMPLEMENTATION_SUMMARY.md`

---

**Happy deploying!** 🚀

