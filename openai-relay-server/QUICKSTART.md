# Quick Start Guide

Get the relay server running in 5 minutes.

## Local Development

```bash
# 1. Navigate to relay server directory
cd openai-relay-server

# 2. Install dependencies
npm install

# 3. Configure environment
cp .env.example .env
nano .env  # Add your OPENAI_API_KEY

# 4. Run development server
npm run dev
```

Server runs at `http://localhost:8080`

## Test It Works

```bash
# Test health endpoint
curl http://localhost:8080/health

# Should return:
# {
#   "status": "healthy",
#   "timestamp": "...",
#   "uptime": 123.456,
#   "version": "1.0.0"
# }
```

## Connect Frontend

Add to your frontend `.env.local`:
```bash
VITE_OPENAI_RELAY_URL=http://localhost:8080
```

Restart frontend:
```bash
npm run dev
```

Now Realtime Mode should work!

## Production Deployment

### Option 1: Docker (Recommended - Easiest!)

**Why Docker**: Simpler, self-contained, no dependency management

```bash
# 1. SSH to your server
ssh user@your-server-ip

# 2. Install Docker (if not already installed)
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# 3. Upload code
cd /path/to/Cardy
rsync -avz openai-relay-server/ user@your-server-ip:/opt/openai-relay/

# 4. On server: Build and run
cd /opt/openai-relay
docker build -t openai-relay:latest .

docker run -d \
  --name openai-relay \
  -p 8080:8080 \
  -e OPENAI_API_KEY=your_key_here \
  -e ALLOWED_ORIGINS=https://your-domain.com \
  --restart unless-stopped \
  openai-relay:latest

# Check logs
docker logs -f openai-relay

# Done! ✅
```

### Option 2: PM2 (Alternative)

**Why PM2**: If you prefer running directly on host without Docker

```bash
# 1. SSH to your server
ssh user@your-server-ip

# 2. Install Node.js 18
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs

# 3. Upload code
rsync -avz --exclude 'node_modules' --exclude 'dist' \
  openai-relay-server/ user@your-server-ip:/opt/openai-relay/

# 4. On server: Install and build
cd /opt/openai-relay
npm install
npm run build
cp .env.example .env
nano .env  # Add OPENAI_API_KEY and ALLOWED_ORIGINS

# 5. Start with PM2
sudo npm install -g pm2
pm2 start ecosystem.config.js
pm2 startup
pm2 save
```

**See [DEPLOYMENT_SSH.md](./DEPLOYMENT_SSH.md) for complete step-by-step guides for both options.**

## Common Issues

### Port already in use

```bash
# Find what's using port 8080
lsof -i :8080

# Kill the process or change PORT in .env
```

### CORS errors

Make sure `ALLOWED_ORIGINS` in `.env` includes your frontend URL:
```bash
ALLOWED_ORIGINS=http://localhost:5173,http://localhost:3000
```

### OpenAI API errors

Verify your API key:
```bash
curl https://api.openai.com/v1/models \
  -H "Authorization: Bearer $OPENAI_API_KEY"
```

## Next Steps

- [README.md](./README.md) - Full documentation
- [DEPLOYMENT_SSH.md](./DEPLOYMENT_SSH.md) - Production SSH deployment guide
- Configure SSL with Let's Encrypt (see DEPLOYMENT_SSH.md)
- Set up monitoring (UptimeRobot, Pingdom)

## File Structure

```
openai-relay-server/
├── src/
│   └── index.ts          # Main server code
├── package.json          # Dependencies
├── tsconfig.json         # TypeScript config
├── ecosystem.config.js   # PM2 config
├── Dockerfile            # Docker config
├── .env.example          # Environment template
├── README.md            # Full documentation
├── DEPLOYMENT_SSH.md    # SSH deployment guide
└── QUICKSTART.md        # This file
```

## Support

For issues:
1. Check logs: `pm2 logs openai-relay` or `docker logs openai-relay`
2. Verify environment variables: `cat .env`
3. Test health endpoint: `curl http://localhost:8080/health`
4. See troubleshooting in README.md

Happy relaying! 🚀

