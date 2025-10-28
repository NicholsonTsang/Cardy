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

## Production Deployment via SSH

See [DEPLOYMENT_SSH.md](./DEPLOYMENT_SSH.md) for complete production deployment guide.

### Quick SSH Deployment Steps

```bash
# 1. SSH to your server
ssh user@your-server-ip

# 2. Install Node.js 18
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs

# 3. Create app directory
sudo mkdir -p /opt/openai-relay
sudo chown $USER:$USER /opt/openai-relay

# 4. Upload code (from your local machine)
cd /path/to/Cardy
rsync -avz --exclude 'node_modules' --exclude 'dist' \
  openai-relay-server/ user@your-server-ip:/opt/openai-relay/

# 5. On server: Install and build
cd /opt/openai-relay
npm install
npm run build

# 6. Configure environment
cp .env.example .env
nano .env  # Add OPENAI_API_KEY and ALLOWED_ORIGINS

# 7. Install PM2 and start
sudo npm install -g pm2
pm2 start ecosystem.config.js
pm2 startup  # Follow the instructions
pm2 save

# 8. Install Nginx (optional, for SSL)
sudo apt install -y nginx
# See DEPLOYMENT_SSH.md for Nginx configuration
```

## Docker Deployment

```bash
# Build image
docker build -t openai-relay:latest .

# Run container
docker run -d \
  --name openai-relay \
  -p 8080:8080 \
  -e OPENAI_API_KEY=your_key_here \
  -e ALLOWED_ORIGINS=https://your-domain.com \
  --restart unless-stopped \
  openai-relay:latest

# Check logs
docker logs -f openai-relay
```

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

