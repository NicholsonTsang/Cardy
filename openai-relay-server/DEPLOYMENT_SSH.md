# SSH Deployment Guide

Complete step-by-step guide to deploy the OpenAI Relay Server to your VPS via SSH.

## Prerequisites

- Ubuntu 20.04+ or Debian 11+ server
- SSH access with sudo privileges
- Domain name (optional but recommended)
- OpenAI API key

## Step 1: Server Setup

### Connect to your server

```bash
ssh user@your-server-ip
```

### Update system packages

```bash
sudo apt update
sudo apt upgrade -y
```

### Install Node.js 18 LTS

```bash
# Install Node.js from NodeSource repository
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs

# Verify installation
node --version  # Should show v18.x.x
npm --version   # Should show 8.x.x or higher
```

### Install build tools

```bash
sudo apt install -y build-essential git
```

## Step 2: Create Application User

```bash
# Create dedicated user for the application
sudo useradd -r -s /bin/bash -m -d /opt/openai-relay nodejs

# Switch to the new user
sudo su - nodejs
```

## Step 3: Deploy Application

### Clone or upload your code

**Option A: Using Git**

```bash
cd /opt/openai-relay
git clone <your-repo-url> .
```

**Option B: Upload via SCP (from your local machine)**

```bash
# On your local machine
cd /path/to/Cardy
tar -czf relay-server.tar.gz openai-relay-server/

# Upload to server
scp relay-server.tar.gz user@your-server-ip:/tmp/

# On server, as nodejs user
cd /opt/openai-relay
tar -xzf /tmp/relay-server.tar.gz --strip-components=1
rm /tmp/relay-server.tar.gz
```

**Option C: Manual upload (if you don't have git)**

```bash
# On your local machine, in the openai-relay-server directory
rsync -avz --exclude 'node_modules' --exclude 'dist' \
  . user@your-server-ip:/tmp/relay-upload/

# On server
sudo mkdir -p /opt/openai-relay
sudo chown nodejs:nodejs /opt/openai-relay
sudo mv /tmp/relay-upload/* /opt/openai-relay/
sudo su - nodejs
```

### Install dependencies

```bash
cd /opt/openai-relay
npm install
```

### Build the application

```bash
npm run build
```

### Configure environment

```bash
cp .env.example .env
nano .env
```

Edit the file with your settings:
```bash
OPENAI_API_KEY=sk-your-actual-openai-key-here
PORT=8080
NODE_ENV=production
ALLOWED_ORIGINS=https://your-frontend-domain.com,https://your-staging-domain.com
```

Save and exit (Ctrl+X, Y, Enter).

### Test the application

```bash
npm start
```

You should see:
```
🚀 OpenAI Realtime API Relay Server
=====================================
📡 Server listening on port 8080
...
```

Press Ctrl+C to stop.

## Step 4: Install PM2 Process Manager

Exit from nodejs user and return to your regular user:

```bash
exit  # Exit from nodejs user
```

Install PM2 globally:

```bash
sudo npm install -g pm2
```

Switch back to nodejs user and start the application:

```bash
sudo su - nodejs
cd /opt/openai-relay
pm2 start ecosystem.config.js
```

### Configure PM2 auto-start

```bash
# Generate startup script (run as nodejs user)
pm2 startup

# This will show a command like:
# sudo env PATH=$PATH:/usr/bin pm2 startup systemd -u nodejs --hp /opt/openai-relay
# Copy and run that command (exit to your regular user first)

exit  # Exit from nodejs user

# Run the command PM2 showed you (example):
sudo env PATH=$PATH:/usr/bin pm2 startup systemd -u nodejs --hp /opt/openai-relay

# Switch back to nodejs user and save PM2 configuration
sudo su - nodejs
pm2 save
```

### Verify PM2 is running

```bash
pm2 status
pm2 logs openai-relay
```

## Step 5: Configure Nginx Reverse Proxy

Exit from nodejs user and return to your regular user:

```bash
exit  # Exit from nodejs user
```

### Install Nginx

```bash
sudo apt install -y nginx
```

### Create Nginx configuration

```bash
sudo nano /etc/nginx/sites-available/openai-relay
```

Add this configuration:

```nginx
server {
    listen 80;
    server_name relay.your-domain.com;  # Change to your domain

    # Rate limiting
    limit_req_zone $binary_remote_addr zone=relay_limit:10m rate=10r/s;
    limit_req zone=relay_limit burst=20 nodelay;

    location / {
        proxy_pass http://localhost:8080;
        proxy_http_version 1.1;
        
        # Headers
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
        
        # WebSocket support (if needed in future)
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }

    # Health check endpoint
    location /health {
        proxy_pass http://localhost:8080/health;
        access_log off;
    }
}
```

Save and exit.

### Enable the site

```bash
sudo ln -s /etc/nginx/sites-available/openai-relay /etc/nginx/sites-enabled/
sudo nginx -t  # Test configuration
sudo systemctl restart nginx
```

## Step 6: Configure SSL with Let's Encrypt

### Install Certbot

```bash
sudo apt install -y certbot python3-certbot-nginx
```

### Obtain SSL certificate

```bash
sudo certbot --nginx -d relay.your-domain.com
```

Follow the prompts:
1. Enter your email
2. Agree to terms
3. Choose whether to redirect HTTP to HTTPS (recommended: yes)

Certbot will automatically:
- Obtain the certificate
- Configure Nginx with SSL
- Set up automatic renewal

### Verify SSL renewal

```bash
sudo certbot renew --dry-run
```

## Step 7: Configure Firewall

```bash
# Allow SSH (if not already allowed)
sudo ufw allow 22/tcp

# Allow HTTP and HTTPS
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Enable firewall
sudo ufw enable

# Check status
sudo ufw status
```

## Step 8: Test Deployment

### Test health endpoint

```bash
curl http://relay.your-domain.com/health
# or
curl https://relay.your-domain.com/health
```

Should return:
```json
{
  "status": "healthy",
  "timestamp": "...",
  "uptime": 123.456,
  "version": "1.0.0"
}
```

### Test from your frontend

Update your frontend `.env.local`:
```bash
VITE_OPENAI_RELAY_URL=https://relay.your-domain.com
```

Restart your frontend and test Realtime Mode.

## Step 9: Monitoring and Logs

### View PM2 status

```bash
sudo su - nodejs
pm2 status
pm2 monit  # Real-time monitoring
```

### View logs

```bash
# PM2 logs
pm2 logs openai-relay

# Last 100 lines
pm2 logs openai-relay --lines 100

# Error logs only
pm2 logs openai-relay --err

# Nginx access logs
sudo tail -f /var/log/nginx/access.log

# Nginx error logs
sudo tail -f /var/log/nginx/error.log
```

## Step 10: Maintenance

### Update application

```bash
# As nodejs user
sudo su - nodejs
cd /opt/openai-relay

# Pull latest code (if using git)
git pull

# Or upload new code via SCP

# Install any new dependencies
npm install

# Rebuild
npm run build

# Restart
pm2 restart openai-relay
```

### Restart services

```bash
# Restart relay server
pm2 restart openai-relay

# Restart Nginx
sudo systemctl restart nginx

# Restart both
pm2 restart openai-relay && sudo systemctl restart nginx
```

### Check server resources

```bash
# CPU and memory usage
htop

# Disk usage
df -h

# PM2 process info
pm2 show openai-relay
```

## Troubleshooting

### Server won't start

1. Check PM2 logs:
```bash
pm2 logs openai-relay --err
```

2. Verify environment variables:
```bash
cat /opt/openai-relay/.env
```

3. Check if port is in use:
```bash
sudo lsof -i :8080
```

### Nginx errors

1. Test Nginx configuration:
```bash
sudo nginx -t
```

2. Check error logs:
```bash
sudo tail -f /var/log/nginx/error.log
```

3. Verify Nginx is running:
```bash
sudo systemctl status nginx
```

### SSL certificate issues

1. Check certificate status:
```bash
sudo certbot certificates
```

2. Renew manually if needed:
```bash
sudo certbot renew
```

3. Verify domain DNS points to your server IP

### High memory usage

```bash
# Restart PM2 process
pm2 restart openai-relay

# Check memory limit in ecosystem.config.js
nano /opt/openai-relay/ecosystem.config.js
```

### Can't connect from frontend

1. Verify firewall allows HTTPS:
```bash
sudo ufw status
```

2. Check CORS configuration in `.env`:
```bash
cat /opt/openai-relay/.env | grep ALLOWED_ORIGINS
```

3. Test relay endpoint directly:
```bash
curl https://relay.your-domain.com/health
```

## Security Checklist

- [ ] Server packages updated
- [ ] Firewall configured (only ports 22, 80, 443 open)
- [ ] SSH key authentication enabled (password auth disabled recommended)
- [ ] Application running as non-root user (nodejs)
- [ ] SSL certificate installed and auto-renewal configured
- [ ] CORS configured with specific origins (not `*`)
- [ ] OpenAI API key stored in environment variable
- [ ] Regular backups configured
- [ ] Monitoring set up (optional: UptimeRobot, Pingdom)

## Performance Optimization

### Enable Nginx caching (optional)

```bash
sudo nano /etc/nginx/sites-available/openai-relay
```

Add above `location /` block:
```nginx
proxy_cache_path /var/cache/nginx levels=1:2 keys_zone=relay_cache:10m max_size=100m inactive=60m;
```

### Increase file limits for Node.js

```bash
sudo nano /etc/security/limits.conf
```

Add:
```
nodejs soft nofile 65536
nodejs hard nofile 65536
```

## Backup Strategy

### Backup script

Create `/opt/scripts/backup-relay.sh`:

```bash
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/opt/backups/relay"
mkdir -p $BACKUP_DIR

# Backup application
tar -czf $BACKUP_DIR/relay-$DATE.tar.gz \
  /opt/openai-relay \
  --exclude='node_modules' \
  --exclude='dist' \
  --exclude='logs'

# Keep only last 7 backups
find $BACKUP_DIR -name "relay-*.tar.gz" -mtime +7 -delete

echo "Backup completed: relay-$DATE.tar.gz"
```

Make executable and add to crontab:
```bash
sudo chmod +x /opt/scripts/backup-relay.sh
sudo crontab -e
```

Add:
```
0 2 * * * /opt/scripts/backup-relay.sh
```

## Cost Estimate

Typical VPS requirements:
- **Small deployment**: 1 vCPU, 1GB RAM, $5-10/month (DigitalOcean, Linode, Vultr)
- **Medium deployment**: 2 vCPU, 2GB RAM, $10-20/month
- **High traffic**: 4 vCPU, 4GB RAM, $20-40/month

Additional costs:
- Domain name: ~$10/year
- SSL certificate: Free (Let's Encrypt)

## Next Steps

1. Set up monitoring (UptimeRobot, Pingdom)
2. Configure backup strategy
3. Set up alerting (email/SMS for downtime)
4. Consider CDN (Cloudflare) for DDoS protection
5. Load test your relay server

## Support

If you encounter issues:
1. Check logs (PM2, Nginx)
2. Review troubleshooting section above
3. Verify all prerequisites met
4. Test each component individually

## Reference Commands

```bash
# Start/Stop/Restart
pm2 start openai-relay
pm2 stop openai-relay
pm2 restart openai-relay
pm2 delete openai-relay

# Logs
pm2 logs openai-relay
pm2 logs openai-relay --lines 100
pm2 logs openai-relay --err

# Status
pm2 status
pm2 show openai-relay
pm2 monit

# Nginx
sudo systemctl start nginx
sudo systemctl stop nginx
sudo systemctl restart nginx
sudo systemctl status nginx
sudo nginx -t

# SSL
sudo certbot certificates
sudo certbot renew
sudo certbot renew --dry-run
```

---

**Deployment complete!** Your relay server should now be running at `https://relay.your-domain.com`

