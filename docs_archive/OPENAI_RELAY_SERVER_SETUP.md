# OpenAI Realtime API Relay Server - Setup Guide

## Overview

This guide walks you through setting up the OpenAI Realtime API relay server to enable AI voice conversations in regions where OpenAI is blocked.

## Problem Statement

If your application users are in a region where OpenAI's API is blocked (e.g., China, certain countries), they cannot directly connect to `wss://api.openai.com/v1/realtime`. The relay server solves this by:

1. **Running in an accessible region** (e.g., US, Europe, Singapore)
2. **Proxying WebSocket connections** between your users and OpenAI
3. **Maintaining full functionality** with zero changes to the AI experience

## Architecture

```
User (Blocked Region)  →  Relay Server (Accessible Region)  →  OpenAI API
         ↓                          ↓                              ↓
    Vue Frontend              Express.js Server              Realtime API
    WebSocket Client          WebSocket Proxy                 WebSocket
```

## Quick Start

### Option 1: Local Development (Testing)

Perfect for testing the relay server locally before deployment.

1. **Navigate to relay server**:
```bash
cd openai-relay-server
```

2. **Install dependencies**:
```bash
npm install
```

3. **Start the server**:
```bash
npm run dev
```

4. **Configure frontend** (`.env` or `.env.local`):
```bash
VITE_OPENAI_RELAY_URL=ws://localhost:8080
```

5. **Test the connection**:
- Open your CardStudio app
- Click "Ask AI Assistant"
- Select a language
- Switch to "Live Call" mode (phone icon)
- Click "Start Live Call"
- You should see relay connection logs in the server console

### Option 2: Docker Deployment (Production)

Recommended for production deployments.

1. **Navigate to relay server**:
```bash
cd openai-relay-server
```

2. **Create environment file**:
```bash
cp .env.example .env
```

Edit `.env` with production settings:
```bash
NODE_ENV=production
PORT=8080
MAX_CONNECTIONS=200
ALLOWED_ORIGINS=https://cardstudio.org,https://app.cardstudio.org
HEARTBEAT_INTERVAL=30000
INACTIVITY_TIMEOUT=300000
DEBUG=false
```

3. **Build and start with Docker Compose**:
```bash
docker-compose up -d
```

4. **Verify deployment**:
```bash
# Check health
curl http://localhost:8080/health

# View logs
docker-compose logs -f

# Check stats
curl http://localhost:8080/stats
```

## Deployment Platforms

### Railway (Easiest - Recommended for Quick Setup)

Railway provides automatic deployments with WebSocket support out of the box.

1. **Push code to GitHub**:
```bash
git add openai-relay-server/
git commit -m "Add OpenAI relay server"
git push
```

2. **Create Railway project**:
   - Go to [railway.app](https://railway.app)
   - Click "New Project" → "Deploy from GitHub repo"
   - Select your repository
   - Select root path: `openai-relay-server`

3. **Configure environment variables** in Railway dashboard:
```
NODE_ENV=production
PORT=8080
MAX_CONNECTIONS=200
ALLOWED_ORIGINS=https://cardstudio.org,https://app.cardstudio.org
```

4. **Get your Railway URL**:
   - Railway automatically provides a URL like: `https://openai-relay-production-xxxx.up.railway.app`
   - Note: Railway supports both `wss://` (WebSocket Secure) automatically

5. **Update frontend** (`.env.production`):
```bash
VITE_OPENAI_RELAY_URL=wss://openai-relay-production-xxxx.up.railway.app
```

### DigitalOcean App Platform

DigitalOcean provides affordable hosting with easy WebSocket setup.

1. **Push to GitHub** (same as above)

2. **Create App Platform app**:
   - Go to DigitalOcean Console
   - Apps → Create App
   - Connect GitHub repository
   - Set source directory: `openai-relay-server`

3. **Configure build settings**:
   - Build Command: `npm install && npm run build`
   - Run Command: `npm start`
   - HTTP Port: `8080`

4. **Add environment variables**:
```
NODE_ENV=production
MAX_CONNECTIONS=200
ALLOWED_ORIGINS=https://cardstudio.org
```

5. **Enable WebSocket** in App settings

6. **Get your App URL** and update frontend:
```bash
VITE_OPENAI_RELAY_URL=wss://your-app.ondigitalocean.app
```

### AWS (ECS/Fargate)

For enterprise deployments requiring scalability and AWS integration.

1. **Build and push Docker image**:
```bash
cd openai-relay-server

# Login to ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin YOUR_ACCOUNT.dkr.ecr.us-east-1.amazonaws.com

# Build and tag
docker build -t openai-realtime-relay:latest .
docker tag openai-realtime-relay:latest YOUR_ACCOUNT.dkr.ecr.us-east-1.amazonaws.com/openai-realtime-relay:latest

# Push to ECR
docker push YOUR_ACCOUNT.dkr.ecr.us-east-1.amazonaws.com/openai-realtime-relay:latest
```

2. **Create ECS Task Definition**:
   - Container image: ECR image URI
   - Port mapping: `8080`
   - Health check: `/health`
   - Environment variables: Add all required vars

3. **Create ECS Service**:
   - Launch type: Fargate
   - Desired tasks: 2 (for high availability)
   - Load balancer: Application Load Balancer (ALB)
   - Target type: IP
   - Health check path: `/health`

4. **Configure ALB for WebSocket**:
   - Enable stickiness (session affinity)
   - Idle timeout: 300 seconds
   - Enable WebSocket support

5. **Get ALB DNS name** and update frontend:
```bash
VITE_OPENAI_RELAY_URL=wss://relay-alb-xxxxx.us-east-1.elb.amazonaws.com
```

### Google Cloud Run

Serverless container deployment with automatic scaling.

1. **Build and push to Artifact Registry**:
```bash
cd openai-relay-server

# Configure Docker for GCR
gcloud auth configure-docker

# Build and push
docker build -t gcr.io/YOUR_PROJECT/openai-realtime-relay:latest .
docker push gcr.io/YOUR_PROJECT/openai-realtime-relay:latest
```

2. **Deploy to Cloud Run**:
```bash
gcloud run deploy openai-realtime-relay \
  --image gcr.io/YOUR_PROJECT/openai-realtime-relay:latest \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated \
  --port 8080 \
  --set-env-vars NODE_ENV=production,MAX_CONNECTIONS=200
```

3. **Enable WebSocket support**:
   - Cloud Run supports WebSockets by default
   - Set timeout to 300 seconds for long-lived connections

4. **Get Cloud Run URL** and update frontend:
```bash
VITE_OPENAI_RELAY_URL=wss://openai-realtime-relay-xxxxx-uc.a.run.app
```

## SSL/TLS Setup (Production)

For production, you must use `wss://` (WebSocket Secure) instead of `ws://`.

### Option 1: Platform-Managed SSL (Easiest)

Railway, DigitalOcean App Platform, and Cloud Run automatically provide SSL certificates. Just use their provided `https://` URLs as `wss://`.

### Option 2: Nginx SSL Termination

If deploying to a VPS or custom server:

1. **Install Certbot** (Let's Encrypt):
```bash
sudo apt update
sudo apt install certbot python3-certbot-nginx
```

2. **Configure Nginx**:
```nginx
# /etc/nginx/sites-available/relay
server {
    listen 443 ssl http2;
    server_name relay.yourdomain.com;

    ssl_certificate /etc/letsencrypt/live/relay.yourdomain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/relay.yourdomain.com/privkey.pem;

    location / {
        proxy_pass http://localhost:8080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # WebSocket timeout
        proxy_read_timeout 300s;
        proxy_send_timeout 300s;
    }
}

# Redirect HTTP to HTTPS
server {
    listen 80;
    server_name relay.yourdomain.com;
    return 301 https://$server_name$request_uri;
}
```

3. **Get SSL certificate**:
```bash
sudo certbot --nginx -d relay.yourdomain.com
```

4. **Update frontend**:
```bash
VITE_OPENAI_RELAY_URL=wss://relay.yourdomain.com
```

## Frontend Configuration

### Development

For local testing with relay:

**File**: `.env` or `.env.local`
```bash
# Connect to local relay server
VITE_OPENAI_RELAY_URL=ws://localhost:8080
```

### Production

**File**: `.env.production`
```bash
# Connect to production relay server
VITE_OPENAI_RELAY_URL=wss://relay.yourdomain.com
```

### No Relay (Direct Connection)

If you don't need a relay (users can access OpenAI directly):

```bash
# Leave empty or comment out
VITE_OPENAI_RELAY_URL=
```

The frontend automatically falls back to direct OpenAI connection.

## Testing

### 1. Test Health Endpoint

```bash
curl https://relay.yourdomain.com/health
```

Expected response:
```json
{
  "status": "healthy",
  "uptime": 12345,
  "stats": {
    "totalConnections": 0,
    "activeConnections": 0,
    "messagesRelayed": 0,
    "errors": 0
  },
  "timestamp": "2025-10-08T12:00:00.000Z"
}
```

### 2. Test WebSocket Connection

Using `wscat`:
```bash
npm install -g wscat

wscat -c "wss://relay.yourdomain.com/realtime?model=gpt-4o-realtime-preview-2024-12-17" \
  --subprotocol "realtime" \
  --subprotocol "openai-insecure-api-key.YOUR_EPHEMERAL_TOKEN" \
  --subprotocol "openai-beta.realtime-v1"
```

### 3. Test from Frontend

1. Start your CardStudio app with relay configured
2. Open browser console (F12)
3. Click "Ask AI Assistant"
4. Switch to "Live Call" mode
5. Click "Start Live Call"

Look for console logs:
```
🔄 Connecting via relay server: wss://relay.yourdomain.com/realtime?model=...
✅ Realtime connection established
```

## Monitoring

### Health Checks

Set up automated health monitoring:

```bash
# Cron job (every 5 minutes)
*/5 * * * * curl -f https://relay.yourdomain.com/health || echo "Relay server down!" | mail -s "Alert" admin@yourdomain.com
```

### Logs

**Docker**:
```bash
docker-compose logs -f openai-realtime-relay
```

**Railway**: Check logs in dashboard

**Cloud platforms**: Use their built-in logging (CloudWatch, Stackdriver, etc.)

### Metrics to Monitor

1. **Active Connections**: Should stay below `MAX_CONNECTIONS`
2. **Message Throughput**: Indicates usage
3. **Error Rate**: Should be < 1%
4. **Memory Usage**: Should be stable (no leaks)
5. **CPU Usage**: Should be low for idle server

## Troubleshooting

### "Connection refused"

**Cause**: Server not running or port blocked

**Solution**:
```bash
# Check if server is running
curl http://localhost:8080/health

# Check Docker status
docker ps | grep openai-realtime-relay

# Check firewall
sudo ufw status
sudo ufw allow 8080/tcp
```

### "WebSocket connection failed"

**Cause**: SSL/TLS issues or CORS

**Solution**:
1. Verify `ALLOWED_ORIGINS` includes your frontend domain
2. Check SSL certificate validity
3. Ensure using `wss://` (not `ws://`) in production
4. Check browser console for specific error

### "Authentication failed"

**Cause**: Invalid or expired ephemeral token

**Solution**:
1. Check Edge Function `openai-realtime-relay` is working
2. Verify token generation is successful
3. Check token expiration time
4. Review browser console for token errors

### High memory usage

**Cause**: Too many concurrent connections or memory leak

**Solution**:
1. Reduce `MAX_CONNECTIONS`
2. Enable garbage collection: `node --expose-gc dist/index.js`
3. Check for connection leaks in logs
4. Restart server: `docker-compose restart`

### OpenAI connection errors

**Cause**: Network issues or API problems

**Solution**:
1. Verify server can reach `api.openai.com`
```bash
curl -I https://api.openai.com
```
2. Check OpenAI API status: https://status.openai.com
3. Review relay server logs for specific errors

## Security Best Practices

1. **Use HTTPS/WSS**: Always use secure connections in production
2. **Restrict CORS**: Set `ALLOWED_ORIGINS` to specific domains (not `*`)
3. **Rate Limiting**: Add rate limiting per IP (consider using Nginx or Cloudflare)
4. **Monitor Logs**: Watch for suspicious activity
5. **Keep Updated**: Regularly update dependencies
6. **Use Secrets**: Never commit sensitive data to git
7. **Firewall Rules**: Only expose necessary ports

## Cost Considerations

### Server Costs

| Platform | Estimated Monthly Cost | Notes |
|----------|----------------------|-------|
| Railway | $5-20 | Pay per usage, free tier available |
| DigitalOcean | $12-24 | Basic or Professional Droplet |
| AWS ECS | $20-50 | Fargate pricing, depends on usage |
| Cloud Run | $5-15 | Serverless, pay per request |

### OpenAI Costs

The relay server **does not change** OpenAI costs. You still pay:
- **Realtime API**: ~$0.06 per minute (input + output)
- Same as direct connection

### Optimization Tips

1. **Enable compression**: Reduces bandwidth
2. **Adjust timeouts**: Close idle connections faster
3. **Use edge caching**: For health checks (Cloudflare)
4. **Monitor usage**: Set up alerts for unusual activity

## Scaling

### Vertical Scaling (Single Server)

Increase resources:
```yaml
# docker-compose.yml
deploy:
  resources:
    limits:
      cpus: '4'
      memory: 2G
```

Increase connection limit:
```bash
MAX_CONNECTIONS=500
```

### Horizontal Scaling (Multiple Servers)

Use a load balancer:

**Nginx**:
```nginx
upstream relay_servers {
    least_conn;  # Use least connections algorithm
    server relay1.internal:8080;
    server relay2.internal:8080;
    server relay3.internal:8080;
}

server {
    listen 443 ssl;
    server_name relay.yourdomain.com;
    
    location / {
        proxy_pass http://relay_servers;
        # ... WebSocket config ...
    }
}
```

**AWS ALB**: Automatically distributes WebSocket connections

## Maintenance

### Graceful Shutdowns

The server handles SIGTERM/SIGINT for zero-downtime deployments:

```bash
# Graceful shutdown
docker-compose stop

# Forceful shutdown (if needed)
docker-compose down
```

### Updates

```bash
# Pull latest code
git pull

# Rebuild and restart
docker-compose build
docker-compose up -d
```

### Backups

No persistent data to back up! The relay server is stateless.

## Support

For issues:
1. Check logs: `docker-compose logs`
2. Review troubleshooting section above
3. Test health endpoint
4. Check OpenAI API status
5. Review browser console errors

---

**You're all set!** 🎉

Your CardStudio app can now provide AI voice experiences to users worldwide, regardless of regional restrictions.

