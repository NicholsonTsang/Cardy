# Quick Deployment Guide - OpenAI Relay Server

This is the **fastest** way to deploy the relay server to production. For detailed explanations, see [PRODUCTION_DEPLOYMENT_GUIDE.md](./PRODUCTION_DEPLOYMENT_GUIDE.md).

---

## 🎯 Goal

Deploy relay server with HTTPS in **under 15 minutes**.

**What you need:**
- A VPS server (Ubuntu 20.04+)
- A domain name (e.g., `relay.your-domain.com`)
- OpenAI API key

---

## 📦 Step 1: Prepare Server (5 min)

```bash
# SSH into your server
ssh user@your-server-ip

# Install Docker
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER

# Install Nginx & Certbot
sudo apt update
sudo apt install nginx certbot python3-certbot-nginx -y

# Log out and back in for Docker group to take effect
exit
ssh user@your-server-ip
```

---

## 📂 Step 2: Upload Files (2 min)

### Option A: Git Clone (Recommended)

```bash
cd /opt
sudo mkdir relay
sudo chown $USER:$USER relay
cd relay

# Clone repository
git clone https://github.com/your-org/your-repo.git .
cd openai-relay-server
```

### Option B: Direct Upload

```bash
# From your local machine
cd openai-relay-server
rsync -avz --exclude 'node_modules' --exclude 'dist' \
  ./ user@your-server:/opt/relay/
```

---

## ⚙️ Step 3: Configure Environment (2 min)

```bash
# On server, in /opt/relay
cd /opt/relay

# Create .env file
cat > .env << 'EOF'
OPENAI_API_KEY=sk-your-actual-key-here
NODE_ENV=production
ALLOWED_ORIGINS=https://your-frontend-domain.com
EOF

# Secure it
chmod 600 .env
```

**Important:** Replace:
- `sk-your-actual-key-here` with your real OpenAI API key
- `https://your-frontend-domain.com` with your actual frontend URL

---

## 🚀 Step 4: Start Service (1 min)

```bash
# Build and start
docker-compose up -d

# Wait for health check (30-40 seconds)
watch -n 2 'docker-compose ps'

# Press Ctrl+C when status shows "healthy"
```

Test locally:

```bash
curl http://localhost:8080/health

# Should return: {"status":"healthy",...}
```

---

## 🔒 Step 5: Configure HTTPS (5 min)

### 5.1 Point Domain to Server

In your DNS provider (Cloudflare, NameCheap, etc.):
- Add **A record**: `relay` → `your-server-ip`
- Wait 1-5 minutes for DNS propagation

Test: `ping relay.your-domain.com`

### 5.2 Configure Nginx

```bash
# Create Nginx config
sudo nano /etc/nginx/sites-available/openai-relay
```

Paste this (replace `relay.your-domain.com`):

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

Save and enable:

```bash
# Enable site
sudo ln -s /etc/nginx/sites-available/openai-relay /etc/nginx/sites-enabled/

# Test config
sudo nginx -t

# Reload
sudo systemctl reload nginx
```

### 5.3 Get SSL Certificate

```bash
# Get free SSL from Let's Encrypt (auto-configures Nginx)
sudo certbot --nginx -d relay.your-domain.com

# Follow prompts:
# - Enter email
# - Agree to terms
# - Choose: Redirect HTTP to HTTPS (option 2)
```

### 5.4 Configure Firewall

```bash
sudo ufw allow 22/tcp   # SSH
sudo ufw allow 80/tcp   # HTTP
sudo ufw allow 443/tcp  # HTTPS
sudo ufw enable
```

---

## ✅ Step 6: Verify Deployment (1 min)

```bash
# Test from server
curl https://relay.your-domain.com/health

# Should return: {"status":"healthy",...}

# Or run verification script
./verify-deployment.sh
```

**From your local machine:**

```bash
curl https://relay.your-domain.com/health
```

---

## 🎨 Step 7: Update Frontend

### Update Environment Variable

```bash
# In your frontend .env or production config
VITE_OPENAI_RELAY_URL=https://relay.your-domain.com
```

### Rebuild Frontend

```bash
# From your frontend directory
npm run build

# Deploy to your hosting (Vercel, Netlify, etc.)
```

---

## 🎉 Done!

Your relay server is now live at:

**`https://relay.your-domain.com`**

Test it:
1. Open your CardStudio app
2. Scan a QR code with AI enabled
3. Open AI Assistant
4. Switch to "Live Call" mode
5. Start speaking

Should work without CORS errors! ✨

---

## 🔧 Quick Commands

```bash
# View logs
docker-compose logs -f

# Restart service
docker-compose restart

# Stop service
docker-compose down

# Update code
git pull
docker-compose up -d --build

# Check SSL renewal (auto-renews)
sudo certbot renew --dry-run
```

---

## 🚨 Troubleshooting

### Container Not Starting

```bash
docker-compose logs
# Check for missing env vars or port conflicts
```

### CORS Errors

```bash
# Check .env
cat .env | grep ALLOWED_ORIGINS

# Should match your frontend domain exactly
# Update and restart:
nano .env
docker-compose restart
```

### Health Check Failing

```bash
# Wait 30-40 seconds after starting
docker-compose ps

# If still unhealthy:
docker-compose logs --tail=50
```

### SSL Certificate Issues

```bash
# Check certificate status
sudo certbot certificates

# Manual renewal
sudo certbot renew

# Check Nginx config
sudo nginx -t
```

---

## 📊 Monitoring

Set up free monitoring with [UptimeRobot](https://uptimerobot.com):

- **Monitor URL**: `https://relay.your-domain.com/health`
- **Check interval**: Every 5 minutes
- **Alert method**: Email

---

## 🔄 Updates

To update the relay server:

```bash
# SSH to server
ssh user@your-server-ip
cd /opt/relay

# Pull latest code
git pull

# Rebuild and restart
docker-compose up -d --build

# Verify
curl https://relay.your-domain.com/health
```

---

## 📚 More Information

- **Full Guide**: [PRODUCTION_DEPLOYMENT_GUIDE.md](./PRODUCTION_DEPLOYMENT_GUIDE.md)
- **Docker Compose**: [DOCKER_COMPOSE_GUIDE.md](./DOCKER_COMPOSE_GUIDE.md)
- **CORS Config**: [CORS_CONFIGURATION.md](./CORS_CONFIGURATION.md)

---

## 💡 Pro Tips

✅ **Always use HTTPS** in production (handled by Certbot above)  
✅ **Set exact CORS origins** (never use `*` in production)  
✅ **Monitor health endpoint** with external service  
✅ **Backup .env file** regularly  
✅ **Check logs** weekly for errors  
✅ **Test SSL renewal** quarterly: `sudo certbot renew --dry-run`

---

**Total time:** ~15 minutes

**Result:** Production-ready HTTPS relay server! 🚀

