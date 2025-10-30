# Quick Fix for Docker Compose Errors

**Status:** Both errors are now fixed! Follow the steps below.

---

## ✅ Fixed Issues

1. ❌ `ERROR: Version in "./docker-compose.yml" is unsupported`
2. ❌ `ERROR: Invalid interpolation format ... "NODE_ENV=${NODE_ENV:-production}"`

Both issues have been resolved in the updated `docker-compose.yml`.

---

## 🚀 Quick Fix Steps

### On Your Server

```bash
# 1. Navigate to relay directory
cd ~/Cardy/openai-relay-server

# 2. Pull latest changes (with fixed docker-compose.yml)
git pull origin main

# 3. Ensure .env file exists and is configured
ls -la .env

# If .env doesn't exist, create it:
cp .env.example .env
nano .env
```

### Configure .env File

Make sure your `.env` file has these three required variables:

```bash
# Required
OPENAI_API_KEY=sk-your-actual-key-here

# Server settings
NODE_ENV=production

# CORS - Update with your actual frontend domain!
ALLOWED_ORIGINS=https://your-frontend-domain.com
```

**Important:** Replace `your-frontend-domain.com` with your actual domain!

### Test and Start

```bash
# 4. Test configuration (should show no errors)
docker-compose config

# 5. Start the service
docker-compose up -d

# 6. Check status
docker-compose ps

# Should show: Up X seconds

# 7. Test health endpoint
curl http://localhost:8080/health

# Expected: {"status":"healthy","timestamp":"...","uptime":...}
```

---

## ✅ Success Checklist

- [ ] `git pull` completed successfully
- [ ] `.env` file exists with all required variables
- [ ] `docker-compose config` runs without errors
- [ ] `docker-compose ps` shows container as "Up"
- [ ] `curl http://localhost:8080/health` returns 200 OK with JSON response

---

## 🔧 What Was Changed

### docker-compose.yml Updates (For Old Docker Compose Compatibility)

1. **Changed version to '2'** (maximum compatibility):
   ```yaml
   # Before: version: '3.8' (or no version)
   # After:  version: '2'
   ```

2. **Changed environment syntax** (key: value format):
   ```yaml
   # Before:
   environment:
     - NODE_ENV=${NODE_ENV:-production}
     - ALLOWED_ORIGINS=${ALLOWED_ORIGINS:-*}
   
   # After:
   environment:
     NODE_ENV: ${NODE_ENV}
     ALLOWED_ORIGINS: ${ALLOWED_ORIGINS}
   ```

3. **Simplified resource limits** (v2 compatible):
   ```yaml
   # Before: deploy.resources (v3 syntax)
   # After: mem_limit, cpu_shares (v2 syntax)
   ```

4. **Removed healthcheck** (not supported in older versions):
   - Health checks removed for compatibility
   - Monitor manually with: `curl http://localhost:8080/health`

**Why:** Maximum compatibility with Docker Compose v1.5+ (older versions on CentOS, Ubuntu 16.04, etc.)

---

## 🚨 Troubleshooting

### Error: "OPENAI_API_KEY variable is not set"

```bash
# Check .env file
cat .env | grep OPENAI_API_KEY

# Should show: OPENAI_API_KEY=sk-...
# If blank or missing, edit .env:
nano .env
```

### Error: "Container keeps restarting"

```bash
# Check logs for errors
docker-compose logs --tail=50

# Common issues:
# - Missing or invalid OPENAI_API_KEY
# - Port 8080 already in use
# - Network issues
```

### Container not running

```bash
# Check if container is up
docker-compose ps

# If not running or exited:
docker-compose logs --tail=50
```

---

## 📝 Complete Deployment Command Sequence

Copy-paste this entire sequence:

```bash
# Navigate to directory
cd ~/Cardy/openai-relay-server

# Pull latest fixes
git pull origin main

# Ensure .env exists
if [ ! -f .env ]; then
    cp .env.example .env
    echo "⚠️  Please edit .env with your OPENAI_API_KEY and ALLOWED_ORIGINS"
    nano .env
fi

# Show current .env (check it's configured)
echo "Current .env configuration:"
cat .env

# Test configuration
echo "Testing docker-compose configuration..."
docker-compose config > /dev/null && echo "✅ Configuration valid"

# Stop any existing containers
docker-compose down

# Start service
echo "Starting service..."
docker-compose up -d

# Wait for container to start
echo "Waiting for container to start (10 seconds)..."
sleep 10

# Check status
docker-compose ps

# Test health endpoint
echo "Testing health endpoint..."
curl -s http://localhost:8080/health | jq .

echo ""
echo "✅ Deployment complete!"
echo "Next step: Update frontend VITE_OPENAI_RELAY_URL"
```

---

## 🎯 Next Steps After Deployment

1. **Verify container is running**:
   ```bash
   docker-compose ps
   # Should show: Up X seconds
   
   # Test health endpoint
   curl http://localhost:8080/health
   # Should return: {"status":"healthy",...}
   ```

2. **Set up Nginx + SSL** (if not done yet):
   - See: [DEPLOY_QUICK.md](./DEPLOY_QUICK.md#step-5-configure-https-5-min)

3. **Update frontend environment variable**:
   ```bash
   # Production frontend .env
   VITE_OPENAI_RELAY_URL=https://relay.your-domain.com
   ```

4. **Test end-to-end**:
   - Open AI Assistant in your app
   - Switch to "Live Call" mode
   - Verify: No CORS errors, voice works

---

## 📚 Additional Resources

- **Full deployment guide**: [DEPLOY_QUICK.md](./DEPLOY_QUICK.md)
- **Troubleshooting**: [PRODUCTION_DEPLOYMENT_GUIDE.md](./PRODUCTION_DEPLOYMENT_GUIDE.md#-troubleshooting)
- **Docker Compose fixes**: [DOCKER_COMPOSE_VERSION_FIX.md](./DOCKER_COMPOSE_VERSION_FIX.md)

---

## ✅ Summary

**Both errors fixed:**
1. ✅ Removed `version: '3.8'` from docker-compose.yml
2. ✅ Removed `${VAR:-default}` syntax (defaults now in .env)

**What you need to do:**
1. Pull latest changes: `git pull`
2. Ensure .env is configured with all required variables
3. Start service: `docker-compose up -d`

**That's it!** 🚀

---

*Last updated: October 30, 2025*

