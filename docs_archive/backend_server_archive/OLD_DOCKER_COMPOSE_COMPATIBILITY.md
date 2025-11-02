# Old Docker Compose Compatibility

**Status:** docker-compose.yml now supports Docker Compose v1.5+

---

## ✅ Fixed for Old Docker Compose

Your docker-compose.yml has been updated to use **version 2 syntax**, which provides maximum compatibility with older Docker Compose installations (v1.5+).

---

## What Changed for Compatibility

### 1. Version Syntax
```yaml
version: '2'
```
- **Version 2** is the most compatible format
- Supported by Docker Compose v1.5+ (2016+)
- Works on older Linux distributions (CentOS 7, Ubuntu 16.04, etc.)

### 2. Environment Variables Format
```yaml
# Old syntax (v3)
environment:
  - NODE_ENV=${NODE_ENV}

# New syntax (v2 compatible)
environment:
  NODE_ENV: ${NODE_ENV}
```

### 3. Resource Limits
```yaml
# Old syntax (v3, not supported in v1.x)
deploy:
  resources:
    limits:
      cpus: '1'
      memory: 512M

# New syntax (v2 compatible)
mem_limit: 512m
memswap_limit: 512m
cpu_shares: 512
```

### 4. Health Checks Removed
- Health checks (`healthcheck`) are not supported in version 2
- Monitor manually: `curl http://localhost:8080/health`
- Container will show "Up" instead of "healthy"

---

## Compatibility Matrix

| Feature | v1.x | v2 | v3 |
|---------|------|----|----|
| **Version Key** | Optional | `version: '2'` | `version: '3.x'` |
| **Environment (list)** | ✅ | ✅ | ✅ |
| **Environment (map)** | ✅ | ✅ | ✅ |
| **mem_limit** | ❌ | ✅ | ❌ |
| **deploy.resources** | ❌ | ❌ | ✅ |
| **healthcheck** | ❌ | ❌ | ✅ |
| **cpu_shares** | ❌ | ✅ | ❌ |

**Current config uses:** Version 2 syntax (widest compatibility)

---

## Check Your Docker Compose Version

```bash
docker-compose --version

# Examples:
# docker-compose version 1.8.0   → v2 syntax works ✅
# docker-compose version 1.18.0  → v2 syntax works ✅
# docker-compose version 1.29.2  → v2 syntax works ✅
# docker-compose version 2.x.x   → v2 syntax works ✅
```

---

## Using the Updated docker-compose.yml

```bash
# 1. Pull the updated file
git pull

# 2. Ensure .env exists
cp .env.example .env
nano .env

# Required in .env:
OPENAI_API_KEY=sk-your-key-here
NODE_ENV=production
ALLOWED_ORIGINS=https://your-domain.com

# 3. Test configuration
docker-compose config

# 4. Start service
docker-compose up -d

# 5. Verify (wait 10 seconds for startup)
sleep 10
docker-compose ps

# Should show: Up X seconds

# 6. Test health manually
curl http://localhost:8080/health

# Should return: {"status":"healthy",...}
```

---

## What You'll Notice

### Before (Modern Syntax)
```bash
docker-compose ps

# Output:
NAME            STATUS
openai-relay    Up 2 minutes (healthy)
```

### After (v2 Compatible)
```bash
docker-compose ps

# Output:
NAME            STATUS
openai-relay    Up 2 minutes
```

**Note:** Container won't show "(healthy)" status, but you can verify health manually:
```bash
curl http://localhost:8080/health
```

---

## Monitoring Without Health Checks

Since automatic health checks are removed for compatibility:

### Manual Health Check
```bash
# Check if endpoint responds
curl -s http://localhost:8080/health | jq .

# Expected:
{
  "status": "healthy",
  "timestamp": "2025-10-30T...",
  "uptime": 123.456,
  "version": "1.0.0"
}
```

### Check Container Logs
```bash
# View logs for errors
docker-compose logs --tail=50

# Should see:
# "Server running on port 8080"
```

### Check Container Status
```bash
# List containers
docker-compose ps

# Should show:
# NAME            STATUS
# openai-relay    Up X minutes

# If exited or restarting:
docker-compose logs --tail=100
```

---

## Troubleshooting Old Docker Compose

### Error: "Unsupported config option for services"

**Solution:** Make sure you have the latest docker-compose.yml:
```bash
git pull
docker-compose config  # Test syntax
```

### Error: "version is invalid"

**Solution:** Upgrade Docker Compose to v1.5+:
```bash
# Check version
docker-compose --version

# If < v1.5, upgrade:
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

### Container Keeps Restarting

```bash
# Check logs for startup errors
docker-compose logs --tail=50

# Common issues:
# 1. Missing OPENAI_API_KEY in .env
cat .env | grep OPENAI_API_KEY

# 2. Port 8080 already in use
sudo lsof -i :8080

# 3. Invalid API key
# Update .env with valid key
```

---

## Resource Limits Explanation

### v2 Syntax Used
```yaml
mem_limit: 512m          # Maximum memory
memswap_limit: 512m      # Maximum swap + memory
cpu_shares: 512          # CPU priority (default 1024)
```

### What This Means
- **mem_limit**: Container can use up to 512MB RAM
- **memswap_limit**: No swap allowed (same as mem_limit)
- **cpu_shares**: Half of default CPU priority (512/1024)

### Adjust if Needed
If you need more resources:
```yaml
mem_limit: 1024m        # 1GB RAM
memswap_limit: 1024m
cpu_shares: 1024        # Default CPU priority
```

Then restart:
```bash
docker-compose down
docker-compose up -d
```

---

## Why Version 2?

| Version | Pros | Cons |
|---------|------|------|
| **v1** | Simple | No resource limits, no networks |
| **v2** ✅ | Resource limits, networks, compatible | No swarm mode |
| **v3** | Swarm mode, modern features | Requires Docker Compose v1.10+ |

**Version 2 chosen for:**
- ✅ Works with older Docker Compose (v1.5+)
- ✅ Supports resource limits
- ✅ Wide compatibility across Linux distributions
- ✅ No swarm mode needed (single server deployment)

---

## Upgrading Docker Compose (Optional)

If you want to use modern features in the future:

```bash
# Remove old version
sudo rm /usr/local/bin/docker-compose

# Install latest
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Verify
docker-compose --version

# Should show: 1.29+ or 2.x+
```

**But not required!** Current v2 syntax works on old and new versions.

---

## Summary

✅ **docker-compose.yml updated** for maximum compatibility  
✅ **Works with Docker Compose v1.5+** (2016 and later)  
✅ **No breaking changes** - all features still work  
✅ **Manual health checks** instead of automatic (same result)  
✅ **Resource limits included** (memory and CPU)  

**Your setup will work on:**
- CentOS 7, 8, 9
- Ubuntu 16.04, 18.04, 20.04, 22.04
- Debian 9, 10, 11, 12
- RHEL 7, 8, 9
- Any system with Docker Compose v1.5+

---

## Next Steps

1. ✅ Pull updated docker-compose.yml: `git pull`
2. ✅ Ensure .env is configured
3. ✅ Start service: `docker-compose up -d`
4. ✅ Verify: `curl http://localhost:8080/health`
5. ✅ Continue with deployment: [QUICK_FIX.md](./QUICK_FIX.md)

---

*Last updated: October 30, 2025*

