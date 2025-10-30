# OpenAI Realtime API Relay Server - Deployment Summary

This document provides a complete overview of deploying the OpenAI Realtime API relay server for your CardStudio application.

---

## 📋 Overview

The relay server enables OpenAI's Realtime API (WebRTC voice mode) to work in browsers by proxying WebRTC connections. Direct browser connections are blocked by CORS, so this relay server is **required** for Realtime voice mode to work.

**Location:** `openai-relay-server/` directory

---

## ✅ Deployment Readiness Check

### Server Components

- ✅ **Docker Configuration**: Multi-stage Dockerfile with Alpine Linux
- ✅ **Docker Compose**: Full orchestration with health checks
- ✅ **Security**: Non-root user, rate limiting, CORS configuration
- ✅ **Monitoring**: Health endpoint, graceful shutdown, logging
- ✅ **Documentation**: Complete deployment guides

### Frontend Integration

- ✅ **Environment Variable**: `VITE_OPENAI_RELAY_URL` configured
- ✅ **Error Handling**: Graceful fallback to Chat Mode if relay unavailable
- ✅ **User Messaging**: Clear error messages guide users
- ✅ **Type Safety**: TypeScript definitions for environment variables

### Testing & Verification

- ✅ **Health Endpoint**: `/health` for monitoring
- ✅ **Test Script**: `test-relay.sh` for local testing
- ✅ **Verification Script**: `verify-deployment.sh` for production checks

---

## 📚 Available Deployment Guides

| Guide | Purpose | Time | Link |
|-------|---------|------|------|
| **Quick Deploy** | Fastest production setup with HTTPS | 15 min | [DEPLOY_QUICK.md](./openai-relay-server/DEPLOY_QUICK.md) |
| **Production Guide** | Complete production deployment with security | 30 min | [PRODUCTION_DEPLOYMENT_GUIDE.md](./openai-relay-server/PRODUCTION_DEPLOYMENT_GUIDE.md) |
| **Docker Compose** | Docker Compose commands and tips | Reference | [DOCKER_COMPOSE_GUIDE.md](./openai-relay-server/DOCKER_COMPOSE_GUIDE.md) |
| **SSH Deployment** | Detailed step-by-step SSH guide | 45 min | [DEPLOYMENT_SSH.md](./openai-relay-server/DEPLOYMENT_SSH.md) |
| **CORS Configuration** | CORS setup and troubleshooting | Reference | [CORS_CONFIGURATION.md](./openai-relay-server/CORS_CONFIGURATION.md) |

---

## 🚀 Quick Start (Local Development)

### Option 1: Chat Mode (No Relay Needed) - Recommended

For local development, **use Chat Mode** instead of Realtime Mode:

```bash
# No relay server needed!
# Chat Mode uses:
# - Whisper API for voice input (STT)
# - GPT-4o-mini for responses
# - OpenAI TTS for voice output
```

**Advantages:**
- ✅ No relay server setup needed
- ✅ Works immediately with just OpenAI API key
- ✅ ~60x cheaper than Realtime Mode
- ✅ Supports text and voice input

### Option 2: Local Relay Server (For Realtime Testing)

If you need to test Realtime Mode locally:

```bash
cd openai-relay-server

# 1. Configure environment
cp .env.example .env
nano .env  # Add your OPENAI_API_KEY

# 2. Start server
docker-compose up -d

# 3. Add to frontend .env.local
echo "VITE_OPENAI_RELAY_URL=http://localhost:8080" >> ../.env.local

# 4. Restart frontend
npm run dev
```

---

## 🌐 Production Deployment (Recommended Path)

### Step 1: Choose Deployment Method

**Recommended:** Follow [DEPLOY_QUICK.md](./openai-relay-server/DEPLOY_QUICK.md) for fastest setup.

### Step 2: Server Requirements

- **Operating System**: Ubuntu 20.04+ (or similar)
- **Memory**: 512MB minimum, 1GB recommended
- **CPU**: 1 core minimum, 2 cores recommended
- **Disk**: 10GB minimum
- **Bandwidth**: Unmetered preferred (voice streaming uses bandwidth)

### Step 3: Prerequisites

- [ ] VPS server with SSH access
- [ ] Domain name (e.g., `relay.your-domain.com`)
- [ ] OpenAI API key from https://platform.openai.com
- [ ] DNS access to point domain to server

### Step 4: Deploy Relay Server

```bash
# SSH to server
ssh user@your-server-ip

# Install Docker
curl -fsSL https://get.docker.com | sh

# Clone repository
cd /opt
sudo mkdir relay && sudo chown $USER:$USER relay
cd relay
git clone https://github.com/your-org/your-repo.git .
cd openai-relay-server

# Configure environment
cat > .env << 'EOF'
OPENAI_API_KEY=sk-your-key-here
NODE_ENV=production
ALLOWED_ORIGINS=https://your-frontend-domain.com
EOF

# Start service
docker-compose up -d

# Verify
curl http://localhost:8080/health
```

### Step 5: Configure HTTPS (Nginx + Let's Encrypt)

```bash
# Install Nginx and Certbot
sudo apt install nginx certbot python3-certbot-nginx -y

# Configure Nginx (see DEPLOY_QUICK.md for config)
sudo nano /etc/nginx/sites-available/openai-relay

# Get SSL certificate
sudo certbot --nginx -d relay.your-domain.com

# Test
curl https://relay.your-domain.com/health
```

### Step 6: Update Frontend

```bash
# In your frontend .env or production environment
VITE_OPENAI_RELAY_URL=https://relay.your-domain.com
```

Rebuild and redeploy frontend.

### Step 7: Verify End-to-End

```bash
# On server
./verify-deployment.sh

# Test from frontend
# 1. Open AI Assistant
# 2. Switch to "Live Call" mode
# 3. Start speaking
# 4. Should work without CORS errors
```

---

## 🔧 Configuration

### Relay Server (.env)

```bash
# Required
OPENAI_API_KEY=sk-your-key-here

# Recommended
NODE_ENV=production
ALLOWED_ORIGINS=https://your-domain.com

# Optional
PORT=8080
```

### Frontend (.env)

```bash
# Required for Realtime Mode
VITE_OPENAI_RELAY_URL=https://relay.your-domain.com

# Other OpenAI settings
VITE_OPENAI_REALTIME_MODEL=gpt-realtime-mini-2025-10-06
```

---

## 🔒 Security Checklist

- [ ] **CORS**: Set `ALLOWED_ORIGINS` to exact frontend domains (never `*` in production)
- [ ] **HTTPS**: Always use HTTPS in production (use Certbot/Let's Encrypt)
- [ ] **API Key**: Store in environment variables, never commit to git
- [ ] **Firewall**: Only expose ports 22, 80, 443
- [ ] **Updates**: Keep Docker images and packages updated
- [ ] **Monitoring**: Set up health check monitoring (UptimeRobot, etc.)
- [ ] **Backups**: Regular backups of `.env` configuration
- [ ] **Rate Limiting**: Default 100 req/15min per IP (adjust if needed)

---

## 📊 Architecture Flow

```
┌─────────────┐
│   Browser   │
│  (Frontend) │
└──────┬──────┘
       │ WebRTC SDP Offer
       │ (via fetch with JWT)
       ↓
┌──────────────────┐
│   Relay Server   │
│   (Express.js)   │
│   Port 8080      │
└──────┬───────────┘
       │ POST /offer
       │ (with ephemeral token)
       ↓
┌──────────────────┐
│  OpenAI API      │
│  Realtime WebRTC │
│  rtc.openai.com  │
└──────────────────┘
```

**Why relay is needed:** OpenAI's Realtime API doesn't accept direct browser connections due to CORS restrictions.

---

## 🧪 Testing

### Local Testing

```bash
cd openai-relay-server

# Run test script
./test-relay.sh

# Manual test
curl http://localhost:8080/health
```

### Production Testing

```bash
# SSH to server
ssh user@your-server-ip
cd /opt/relay

# Run verification script
./verify-deployment.sh

# Manual test
curl https://relay.your-domain.com/health
```

### Frontend Testing

1. Open CardStudio app
2. Scan QR code with AI-enabled card
3. Open AI Assistant
4. Switch to "Live Call" mode
5. Start speaking
6. Verify:
   - ✅ Connection successful
   - ✅ Voice is transmitted
   - ✅ AI responds with voice
   - ✅ No CORS errors in console

---

## 🚨 Troubleshooting

### Issue: Container Not Starting

```bash
# Check logs
docker-compose logs

# Common causes:
# - Missing OPENAI_API_KEY in .env
# - Port 8080 already in use
# - Syntax error in .env or docker-compose.yml
```

### Issue: CORS Errors

```bash
# Verify CORS configuration
cat .env | grep ALLOWED_ORIGINS

# Should match frontend domain exactly
# Update and restart
nano .env
docker-compose restart
```

### Issue: Frontend Can't Connect

```bash
# Check frontend .env
echo $VITE_OPENAI_RELAY_URL

# Test relay from browser console
fetch('https://relay.your-domain.com/health')
  .then(r => r.json())
  .then(console.log)

# If blocked by CORS, update relay .env ALLOWED_ORIGINS
```

### Issue: SSL Certificate Problems

```bash
# Check certificate
sudo certbot certificates

# Renew if needed
sudo certbot renew

# Test Nginx config
sudo nginx -t
```

---

## 📈 Monitoring

### Health Checks

Set up external monitoring:

- **Service**: UptimeRobot, Pingdom, StatusCake
- **URL**: `https://relay.your-domain.com/health`
- **Method**: GET
- **Expected**: 200 OK, JSON response
- **Interval**: Every 5 minutes
- **Alert**: Email/SMS on failure

### Logs

```bash
# View real-time logs
docker-compose logs -f

# Check for errors
docker-compose logs --tail=100 | grep -i error

# View resource usage
docker stats openai-relay
```

### Metrics

Monitor:
- **CPU usage**: Should be <20% idle, <80% under load
- **Memory usage**: ~50-100MB base, up to 512MB under load
- **Network I/O**: Varies with usage (voice streaming)
- **Response time**: Health endpoint should respond <100ms

---

## 🔄 Maintenance

### Daily

- [ ] Check container health status
- [ ] Monitor health endpoint availability

### Weekly

- [ ] Review logs for errors
- [ ] Check resource usage trends
- [ ] Verify SSL certificate validity

### Monthly

- [ ] Update Docker images
- [ ] Review and rotate API keys (if needed)
- [ ] Check for security updates
- [ ] Backup configuration files

### Quarterly

- [ ] Test SSL certificate renewal
- [ ] Review CORS configuration
- [ ] Performance optimization review
- [ ] Disaster recovery test

---

## 💰 Cost Estimates

### Infrastructure (Monthly)

- **VPS Server**: $5-10 (DigitalOcean, Vultr, Hetzner)
- **Domain**: $1-2/month (or amortized yearly cost)
- **SSL Certificate**: Free (Let's Encrypt)

**Total:** ~$6-12/month

### OpenAI API Costs

Relay server doesn't add API costs. Costs depend on usage:

- **Realtime Mode**: ~$0.06-0.24 per minute
- **Chat Mode**: ~$0.001-0.01 per conversation

See [Cost Optimization Guide](./docs_archive/REALTIME_AUDIO_FULL_IMPLEMENTATION.md) for details.

---

## 📖 Additional Resources

### Documentation

- [Quick Deploy Guide](./openai-relay-server/DEPLOY_QUICK.md)
- [Production Deployment Guide](./openai-relay-server/PRODUCTION_DEPLOYMENT_GUIDE.md)
- [Docker Compose Guide](./openai-relay-server/DOCKER_COMPOSE_GUIDE.md)
- [CORS Configuration](./openai-relay-server/CORS_CONFIGURATION.md)

### External Resources

- [OpenAI Realtime API Docs](https://platform.openai.com/docs/guides/realtime)
- [Docker Documentation](https://docs.docker.com/)
- [Let's Encrypt SSL](https://letsencrypt.org/)

---

## 🎯 Deployment Checklist

### Pre-Deployment

- [ ] Server prepared with Ubuntu 20.04+
- [ ] Docker installed
- [ ] Domain name pointing to server
- [ ] OpenAI API key ready
- [ ] Frontend code ready for environment update

### Relay Server Deployment

- [ ] Files uploaded to server
- [ ] `.env` configured with API key
- [ ] `ALLOWED_ORIGINS` set to frontend domain(s)
- [ ] Service started with `docker-compose up -d`
- [ ] Health check passing
- [ ] Nginx configured as reverse proxy
- [ ] SSL certificate obtained
- [ ] Firewall configured

### Frontend Integration

- [ ] `VITE_OPENAI_RELAY_URL` updated
- [ ] Frontend rebuilt
- [ ] Frontend redeployed
- [ ] Environment variables verified

### Testing

- [ ] Health endpoint responding
- [ ] HTTPS working correctly
- [ ] CORS configured properly
- [ ] Frontend can connect to relay
- [ ] Realtime Mode works end-to-end
- [ ] No errors in browser console

### Production

- [ ] External monitoring set up
- [ ] Alert notifications configured
- [ ] Documentation updated with URLs
- [ ] Team notified of new endpoints
- [ ] Rollback plan documented

---

## ✅ Success Criteria

Your deployment is successful when:

1. ✅ Relay server health endpoint returns 200 OK
2. ✅ HTTPS is working (SSL certificate valid)
3. ✅ Frontend connects without CORS errors
4. ✅ Users can use Realtime voice mode
5. ✅ Monitoring alerts are working
6. ✅ No errors in server logs

---

## 🎉 Next Steps After Deployment

1. **Test thoroughly**: Have multiple users test Realtime Mode
2. **Monitor performance**: Watch logs and metrics for first week
3. **Document URLs**: Update team docs with relay URL
4. **Set up backups**: Backup configuration and deployment scripts
5. **Plan scaling**: If traffic grows, consider horizontal scaling

---

## 💡 Alternative: Chat Mode (No Relay Required)

If you don't want to manage a relay server, **use Chat Mode** instead:

**Chat Mode Features:**
- ✅ Text input and voice recording
- ✅ Streaming responses
- ✅ Text-to-Speech output
- ✅ No relay server needed
- ✅ ~60x cheaper than Realtime Mode

**When to use Realtime Mode (with relay):**
- Low-latency voice conversations needed (<1s response)
- Natural bidirectional voice chat
- Real-time interruption support

**When to use Chat Mode (no relay):**
- Budget-conscious deployment
- Voice recording + text is acceptable
- Lower infrastructure complexity preferred

---

**For questions or issues, refer to the troubleshooting sections in the individual deployment guides.**

**Deployment guides:** [`openai-relay-server/`](./openai-relay-server/)

