# OpenAI Relay Server - Production Deployment Guide

This guide will walk you through deploying the OpenAI Realtime API relay server to production.

## 🎯 Deployment Readiness

✅ **Docker Compose Ready**: Multi-stage Dockerfile with health checks  
✅ **Frontend Integration**: Full environment variable support  
✅ **Security**: CORS configuration, rate limiting, non-root user  
✅ **Monitoring**: Health checks, graceful shutdown, logging  
✅ **Documentation**: Complete setup and troubleshooting guides  

---

## 📋 Pre-Deployment Checklist

Before deploying, ensure you have:

- [ ] **VPS/Server**: Ubuntu 20.04+ or similar (DigitalOcean, AWS, etc.)
- [ ] **OpenAI API Key**: From https://platform.openai.com/api-keys
- [ ] **Domain Name** (optional but recommended): e.g., `relay.your-domain.com`
- [ ] **SSH Access**: To your server
- [ ] **Docker Installed**: Or ability to install it

---

## 🚀 Quick Deploy (Production)

### Step 1: Prepare Your Server

```bash
# SSH into your server
ssh user@your-server-ip

# Update system packages
sudo apt update && sudo apt upgrade -y

# Install Docker & Docker Compose
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER

# Verify installation
docker --version
docker-compose --version
```

Log out and back in for Docker group changes to take effect.

### Step 2: Upload Relay Server Files

**Option A: Using Git** (Recommended)
```bash
# On your server
cd /opt
sudo mkdir relay
sudo chown $USER:$USER relay
cd relay

# Clone your repository
git clone https://github.com/your-org/cardy.git .
cd openai-relay-server
```

**Option B: Using rsync** (From local machine)
```bash
# From your local machine
rsync -avz --exclude 'node_modules' --exclude 'dist' \
  openai-relay-server/ user@your-server:/opt/relay/
```

**Option C: Using SCP** (From local machine)
```bash
# From your local machine
cd openai-relay-server
scp -r * user@your-server:/opt/relay/
```

### Step 3: Configure Environment

```bash
# On your server, in /opt/relay directory
cd /opt/relay

# Create environment file
cat > .env << 'EOF'
# OpenAI Configuration
OPENAI_API_KEY=sk-your-actual-production-key-here

# Server Configuration
NODE_ENV=production

# CORS Configuration - IMPORTANT!
# Replace with your actual frontend domain(s)
ALLOWED_ORIGINS=https://your-domain.com,https://www.your-domain.com
EOF

# Secure the environment file
chmod 600 .env
```

⚠️ **Security Warning**: Never use `ALLOWED_ORIGINS=*` in production!

### Step 4: Deploy with Docker Compose

```bash
# Build and start the service
docker-compose up -d

# View startup logs
docker-compose logs -f

# Wait for "Server running on port 8080" message
# Press Ctrl+C to exit logs (server keeps running)
```

### Step 5: Verify Deployment

```bash
# Check service status
docker-compose ps

# Should show:
# NAME            STATUS              PORTS
# openai-relay    Up X minutes (healthy)    0.0.0.0:8080->8080/tcp

# Test health endpoint
curl http://localhost:8080/health

# Expected response:
# {"status":"healthy","timestamp":"...","uptime":...,"version":"1.0.0"}
```

### Step 6: Configure Frontend

Update your frontend `.env` (or production environment variables):

```bash
# For HTTP (if no SSL yet)
VITE_OPENAI_RELAY_URL=http://your-server-ip:8080

# For HTTPS (after setting up SSL - see below)
VITE_OPENAI_RELAY_URL=https://relay.your-domain.com
```

Then rebuild and redeploy your frontend.

---

## 🔒 Production Security Setup (Recommended)

### Option A: Nginx Reverse Proxy with SSL

This is the **recommended** approach for production.

#### 1. Install Nginx

```bash
sudo apt install nginx certbot python3-certbot-nginx -y
```

#### 2. Configure Nginx

```bash
# Create Nginx config
sudo nano /etc/nginx/sites-available/openai-relay
```

Add this configuration:

```nginx
server {
    listen 80;
    server_name relay.your-domain.com;

    location / {
        proxy_pass http://localhost:8080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

#### 3. Enable Site

```bash
# Enable the site
sudo ln -s /etc/nginx/sites-available/openai-relay /etc/nginx/sites-enabled/

# Test configuration
sudo nginx -t

# Reload Nginx
sudo systemctl reload nginx
```

#### 4. Get SSL Certificate

```bash
# Get free SSL certificate from Let's Encrypt
sudo certbot --nginx -d relay.your-domain.com

# Follow the prompts
# Choose: Redirect HTTP to HTTPS
```

#### 5. Verify SSL

```bash
# Test HTTPS endpoint
curl https://relay.your-domain.com/health
```

#### 6. Update Frontend

```bash
# In your frontend .env
VITE_OPENAI_RELAY_URL=https://relay.your-domain.com
```

### Option B: Cloudflare Proxy (Alternative)

If you use Cloudflare for DNS:

1. Add an A record pointing `relay.your-domain.com` to your server IP
2. Enable the orange cloud (proxy) ☁️
3. Cloudflare provides SSL automatically
4. Set `ALLOWED_ORIGINS` in relay `.env` to your frontend domains

---

## 🔥 Firewall Configuration

```bash
# Allow SSH, HTTP, HTTPS
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Enable firewall
sudo ufw enable

# Check status
sudo ufw status

# If NOT using Nginx (relay directly exposed):
sudo ufw allow 8080/tcp
```

⚠️ **Best Practice**: Use Nginx reverse proxy instead of exposing port 8080 directly.

---

## 📊 Monitoring & Maintenance

### View Logs

```bash
# Real-time logs
docker-compose logs -f

# Last 100 lines
docker-compose logs --tail=100

# Only show errors
docker-compose logs --tail=50 | grep -i error
```

### Check Resource Usage

```bash
# Container stats
docker stats openai-relay

# Disk usage
docker system df
```

### Health Monitoring

Set up external monitoring (UptimeRobot, Pingdom, etc.):

- **Endpoint**: `https://relay.your-domain.com/health`
- **Method**: GET
- **Expected**: 200 OK with JSON response
- **Check Interval**: Every 5 minutes

### Restart Service

```bash
# Graceful restart
docker-compose restart

# Force restart
docker-compose down && docker-compose up -d
```

### Update Deployment

```bash
# Pull latest code
git pull

# Rebuild and restart
docker-compose up -d --build

# View logs
docker-compose logs -f
```

---

## 🛠️ Common Operations

### Change Port

Edit `docker-compose.yml`:

```yaml
ports:
  - "3000:8080"  # Change 3000 to desired external port
```

Then restart:

```bash
docker-compose up -d
```

### Update Environment Variables

```bash
# Edit .env
nano .env

# Restart to apply changes
docker-compose restart
```

### Rotate OpenAI API Key

```bash
# Update .env with new key
nano .env

# Restart
docker-compose restart

# Verify
curl http://localhost:8080/health
```

### Clean Up Old Images

```bash
# Remove unused images
docker image prune -a

# Remove all unused data
docker system prune -a --volumes
```

---

## 🚨 Troubleshooting

### Service Won't Start

```bash
# Check logs
docker-compose logs

# Common issues:
# 1. Port already in use
sudo lsof -i :8080
sudo netstat -tulpn | grep 8080

# 2. Missing environment variable
cat .env | grep OPENAI_API_KEY

# 3. Syntax error in docker-compose.yml
docker-compose config
```

### "Unhealthy" Status

```bash
# Check detailed health status
docker inspect openai-relay | grep -A 20 Health

# Check if server is responding
curl http://localhost:8080/health

# Check logs for errors
docker-compose logs --tail=50
```

### Frontend CORS Errors

```bash
# Verify CORS settings
docker-compose exec openai-relay env | grep ALLOWED_ORIGINS

# Update .env with correct origins
nano .env
ALLOWED_ORIGINS=https://your-actual-domain.com

# Restart
docker-compose restart
```

### High Memory Usage

```bash
# Check current usage
docker stats openai-relay

# Adjust limits in docker-compose.yml
nano docker-compose.yml

deploy:
  resources:
    limits:
      memory: 1024M  # Increase if needed
```

### SSL Certificate Renewal

```bash
# Certbot auto-renews, but you can force renewal:
sudo certbot renew --dry-run

# If successful, run actual renewal:
sudo certbot renew
```

---

## 📈 Performance Optimization

### 1. Resource Limits

Adjust based on your traffic:

```yaml
# docker-compose.yml
deploy:
  resources:
    limits:
      cpus: '2'       # For high traffic
      memory: 1024M
    reservations:
      cpus: '0.5'
      memory: 256M
```

### 2. Rate Limiting

Edit `src/index.ts` to adjust rate limits:

```typescript
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 200, // Increase for high traffic
})
```

Rebuild after changes:

```bash
docker-compose up -d --build
```

### 3. Scaling (Multiple Instances)

For high traffic, run multiple instances behind a load balancer:

```bash
# Scale to 3 instances
docker-compose up -d --scale openai-relay=3
```

Then configure Nginx to load balance between them.

---

## 🧪 Testing Production Deployment

### Test from Server

```bash
# Health check
curl http://localhost:8080/health

# Should return: {"status":"healthy",...}
```

### Test from External Network

```bash
# From your local machine
curl https://relay.your-domain.com/health

# Should return: {"status":"healthy",...}
```

### Test Frontend Integration

1. Update frontend environment variable:
   ```bash
   VITE_OPENAI_RELAY_URL=https://relay.your-domain.com
   ```

2. Rebuild frontend:
   ```bash
   npm run build
   ```

3. Test Realtime mode in your app:
   - Open a card with AI assistant
   - Switch to "Live Call" mode
   - Start speaking
   - Should connect without CORS errors

---

## 📝 Deployment Checklist

- [ ] Server prepared with Docker installed
- [ ] Relay server files uploaded to `/opt/relay`
- [ ] `.env` file created with production API key
- [ ] `ALLOWED_ORIGINS` set to actual frontend domain(s)
- [ ] Service started with `docker-compose up -d`
- [ ] Health check passing (`/health` returns 200)
- [ ] Nginx reverse proxy configured (recommended)
- [ ] SSL certificate obtained with Certbot
- [ ] Firewall configured (`ufw`)
- [ ] Frontend `VITE_OPENAI_RELAY_URL` updated
- [ ] Frontend rebuilt and redeployed
- [ ] External monitoring set up (UptimeRobot, etc.)
- [ ] Tested Realtime mode end-to-end

---

## 🔄 Rollback Plan

If deployment fails:

```bash
# Stop the service
docker-compose down

# Restore previous .env
cp .env.backup .env

# Restart with old config
docker-compose up -d
```

---

## 📚 Additional Resources

- **Docker Compose Guide**: [DOCKER_COMPOSE_GUIDE.md](./DOCKER_COMPOSE_GUIDE.md)
- **CORS Configuration**: [CORS_CONFIGURATION.md](./CORS_CONFIGURATION.md)
- **SSH Deployment**: [DEPLOYMENT_SSH.md](./DEPLOYMENT_SSH.md)
- **Quick Start**: [QUICKSTART.md](./QUICKSTART.md)

---

## 💡 Best Practices Summary

✅ **Use Nginx reverse proxy** instead of exposing Docker directly  
✅ **Enable SSL** with Let's Encrypt (free)  
✅ **Restrict CORS** to actual frontend domains only  
✅ **Set up monitoring** with external health checks  
✅ **Regular backups** of `.env` configuration  
✅ **Keep Docker images updated** with `docker-compose pull`  
✅ **Monitor logs** regularly for errors  
✅ **Test before deploying** changes to production  

---

## 🎉 Success!

Your OpenAI Realtime API relay server is now running in production!

**Frontend Configuration**:
```bash
VITE_OPENAI_RELAY_URL=https://relay.your-domain.com
```

**Test URL**:
```
https://relay.your-domain.com/health
```

Users can now use Realtime voice mode in your CardStudio app! 🎤✨

---

## 🆘 Need Help?

- Check [DOCKER_COMPOSE_GUIDE.md](./DOCKER_COMPOSE_GUIDE.md) for common commands
- Check [CORS_CONFIGURATION.md](./CORS_CONFIGURATION.md) for CORS issues
- Review logs: `docker-compose logs -f`
- Test health: `curl https://relay.your-domain.com/health`

For OpenAI API issues: https://platform.openai.com/docs

