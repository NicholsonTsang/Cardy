# Docker Compose Quick Start Guide

Docker Compose makes running the relay server much simpler!

---

## 🚀 Quick Start

### 1. Configure Environment

```bash
cd openai-relay-server

# Copy environment template
cp .env.docker .env

# Edit .env file
nano .env
```

Add your OpenAI API key:
```bash
OPENAI_API_KEY=sk-your-actual-key-here
ALLOWED_ORIGINS=*
NODE_ENV=production
```

### 2. Start the Server

```bash
# Build and start (one command!)
docker-compose up -d

# View logs
docker-compose logs -f

# Check status
docker-compose ps
```

**Done!** Server is running at `http://localhost:8080` ✅

---

## 📋 Common Commands

### Start/Stop

```bash
# Start server (build if needed)
docker-compose up -d

# Stop server
docker-compose down

# Restart server
docker-compose restart

# Stop and remove volumes
docker-compose down -v
```

### Logs

```bash
# View logs
docker-compose logs

# Follow logs (real-time)
docker-compose logs -f

# Last 100 lines
docker-compose logs --tail=100
```

### Build

```bash
# Rebuild image
docker-compose build

# Rebuild without cache
docker-compose build --no-cache

# Pull latest and rebuild
docker-compose up -d --build
```

### Status

```bash
# Check service status
docker-compose ps

# View service details
docker-compose top
```

---

## 🔧 Configuration

### Environment Variables

Edit `.env` file to configure:

```bash
# Required
OPENAI_API_KEY=sk-your-key-here

# Optional (defaults shown)
NODE_ENV=production
ALLOWED_ORIGINS=*
```

### Port Configuration

Change port in `docker-compose.yml`:

```yaml
ports:
  - "8080:8080"  # Change first 8080 to desired port
```

Example for port 3000:
```yaml
ports:
  - "3000:8080"
```

Then access at `http://localhost:3000`

### Resource Limits

Adjust in `docker-compose.yml`:

```yaml
deploy:
  resources:
    limits:
      cpus: '1'      # Max 1 CPU core
      memory: 512M   # Max 512MB RAM
```

---

## 🧪 Testing

### Test Health Endpoint

```bash
curl http://localhost:8080/health
```

**Expected response:**
```json
{
  "status": "healthy",
  "timestamp": "2025-10-28T...",
  "uptime": 123.456,
  "version": "1.0.0"
}
```

### Test from Browser

Open browser console:
```javascript
fetch('http://localhost:8080/health')
  .then(r => r.json())
  .then(console.log)
```

---

## 📊 Service Management

### View Service Details

```bash
# Service status
docker-compose ps

# Running processes
docker-compose top

# Resource usage
docker stats openai-relay
```

### Health Check

Docker Compose automatically monitors health:

```bash
# Check health status
docker-compose ps

# Should show: healthy
```

If unhealthy:
```bash
# View logs for errors
docker-compose logs --tail=50
```

---

## 🔄 Updates

### Update Code

```bash
# 1. Pull/edit code
git pull
# or edit files

# 2. Rebuild and restart
docker-compose up -d --build

# 3. Verify
curl http://localhost:8080/health
```

### Update Dependencies

```bash
# If package.json changed
docker-compose build --no-cache
docker-compose up -d
```

---

## 🛠️ Troubleshooting

### Server Won't Start

```bash
# Check logs
docker-compose logs

# Common issues:
# 1. Port already in use
sudo lsof -i :8080

# 2. Missing environment variable
cat .env | grep OPENAI_API_KEY

# 3. Docker daemon not running
docker ps
```

### CORS Errors

```bash
# Check CORS configuration
docker-compose exec openai-relay env | grep ALLOWED_ORIGINS

# Update .env and restart
nano .env
docker-compose restart
```

### Container Keeps Restarting

```bash
# View recent logs
docker-compose logs --tail=50

# Check health
docker-compose ps

# Common causes:
# - Missing OPENAI_API_KEY
# - Invalid API key
# - Port conflict
```

---

## 🌐 Production Deployment

### 1. Upload Files

```bash
# From local machine
rsync -avz openai-relay-server/ user@server:/opt/relay/
```

### 2. SSH to Server

```bash
ssh user@server
cd /opt/relay
```

### 3. Install Docker & Docker Compose

```bash
# Install Docker
curl -fsSL https://get.docker.com | sh

# Install Docker Compose (if not included)
sudo apt install docker-compose-plugin
```

### 4. Configure

```bash
# Copy and edit environment
cp .env.docker .env
nano .env
```

Add your production values:
```bash
OPENAI_API_KEY=sk-your-production-key
NODE_ENV=production
ALLOWED_ORIGINS=https://your-domain.com
```

### 5. Start Service

```bash
docker-compose up -d
```

### 6. Verify

```bash
# Check status
docker-compose ps

# Test health
curl http://localhost:8080/health

# View logs
docker-compose logs -f
```

---

## 🔒 Security Best Practices

### 1. Restrict CORS in Production

```bash
# .env for production
ALLOWED_ORIGINS=https://your-app.com,https://admin.your-app.com
```

### 2. Use Secrets Management

For sensitive production deployments:

```bash
# Use Docker secrets instead of .env
echo "sk-your-key" | docker secret create openai_key -
```

Then update `docker-compose.yml`:
```yaml
secrets:
  - openai_key

environment:
  - OPENAI_API_KEY_FILE=/run/secrets/openai_key
```

### 3. Run Behind Reverse Proxy

Use Nginx or Traefik for SSL:

```yaml
# docker-compose.yml
services:
  nginx:
    image: nginx:alpine
    ports:
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
      - ./ssl:/etc/nginx/ssl
    depends_on:
      - openai-relay
```

---

## 📁 File Structure

```
openai-relay-server/
├── docker-compose.yml     # Docker Compose configuration
├── Dockerfile             # Docker image definition
├── .env                   # Your environment variables (git ignored)
├── .env.docker            # Environment template
├── package.json
├── src/
│   └── index.ts
└── logs/                  # Container logs (created automatically)
```

---

## 🎯 Comparison: Docker vs Docker Compose

| Task | Docker Command | Docker Compose |
|------|----------------|----------------|
| **Start** | `docker run -d -p 8080:8080 -e KEY=... relay` | `docker-compose up -d` |
| **Stop** | `docker stop openai-relay` | `docker-compose down` |
| **Logs** | `docker logs -f openai-relay` | `docker-compose logs -f` |
| **Restart** | `docker restart openai-relay` | `docker-compose restart` |
| **Update** | `docker stop ... && docker rm ... && docker run ...` | `docker-compose up -d --build` |

**Winner: Docker Compose** ✅ (Much simpler!)

---

## 🚀 Advanced: Multi-Service Setup

You can extend `docker-compose.yml` for multiple services:

```yaml
# Note: Modern Docker Compose (v2+) doesn't require version key
services:
  openai-relay:
    # ... existing config ...
  
  nginx:
    image: nginx:alpine
    ports:
      - "443:443"
    depends_on:
      - openai-relay
  
  prometheus:
    image: prom/prometheus
    ports:
      - "9090:9090"
```

---

## ✅ Quick Reference

```bash
# Start
docker-compose up -d

# Stop
docker-compose down

# Logs
docker-compose logs -f

# Restart
docker-compose restart

# Rebuild
docker-compose up -d --build

# Status
docker-compose ps

# Health check
curl http://localhost:8080/health
```

---

## 📚 More Information

- **Official Docker Compose Docs**: https://docs.docker.com/compose/
- **Compose File Reference**: https://docs.docker.com/compose/compose-file/
- **Deployment Guide**: See `DEPLOYMENT_SSH.md`

---

**Docker Compose makes deployment simple! Just `docker-compose up -d` and you're running!** 🚀


