# Docker Compose Compatibility Fixes

**Issues:** Compatibility errors with Docker Compose

---

## Issue 1: Unsupported Version

**Error:**
```
ERROR: Version in "./docker-compose.yml" is unsupported.
```

### ✅ Fixed

Removed the `version` key from docker-compose.yml (modern best practice).

---

## Issue 2: Invalid Interpolation Format

**Error:**
```
ERROR: Invalid interpolation format for "openai-relay" option in service "services": 
"NODE_ENV=${NODE_ENV:-production}"
```

### ✅ Fixed

The `${VAR:-default}` syntax (default value interpolation) isn't supported in older Docker Compose versions.

**Changed:** Removed default value syntax - defaults are now in `.env.example` instead.

The `docker-compose.yml` file has been updated to **remove the version key**, which is the modern best practice for Docker Compose v2+.

### What Changed

#### Change 1: Removed Version Key

**Before:**
```yaml
version: '3.8'

services:
  openai-relay:
    # ...
```

**After:**
```yaml
services:
  openai-relay:
    # ...
```

#### Change 2: Simplified Environment Variables

**Before:**
```yaml
environment:
  - NODE_ENV=${NODE_ENV:-production}
  - ALLOWED_ORIGINS=${ALLOWED_ORIGINS:-*}
```

**After:**
```yaml
environment:
  - NODE_ENV=${NODE_ENV}
  - ALLOWED_ORIGINS=${ALLOWED_ORIGINS}
```

**Note:** Default values are now in `.env` file instead of docker-compose.yml

---

## Why This Change?

Modern Docker Compose (v2.0+) introduced a **version-less format** where:

- ✅ **Version key is optional** and not recommended
- ✅ **Automatic detection** of features based on Docker Compose version
- ✅ **Simpler syntax** - one less line to maintain
- ✅ **Better compatibility** across different Docker Compose versions

**Official Docker documentation:**
> "The Compose Specification is the latest and recommended version. It is implemented by Docker Compose 1.27.0+. This version merges the 2.x and 3.x file formats."

---

## What This Means for You

### If Using Docker Compose v2+ (Recommended)

✅ **No action needed** - The fix is already applied

```bash
# Check your version
docker-compose version

# Or
docker compose version

# If v2.0+, you're good to go!
```

### If Using Docker Compose v1.x (Legacy)

If you're still using Docker Compose v1.x (released before 2020), you have two options:

**Option 1: Upgrade Docker Compose (Recommended)**
```bash
# Remove old version
sudo apt remove docker-compose

# Install latest
sudo apt install docker-compose-plugin

# Or use Docker's install script
curl -fsSL https://get.docker.com | sh
```

**Option 2: Add Version Back (Not Recommended)**
```yaml
version: '3.3'  # Use 3.3 for v1.x compatibility

services:
  openai-relay:
    # ... rest of config
```

---

## Verify the Fix

### Step 1: Ensure .env File Exists

```bash
# Check if .env exists
ls -la .env

# If not, create it from example
cp .env.example .env

# Edit with your values
nano .env
```

**Required in .env:**
```bash
OPENAI_API_KEY=sk-your-actual-key-here
NODE_ENV=production
ALLOWED_ORIGINS=https://your-frontend-domain.com
```

### Step 2: Test Configuration

```bash
# Test configuration syntax
docker-compose config

# Should output the parsed configuration without errors
```

### Step 3: Start Service

```bash
# Start the service
docker-compose up -d

# Check status
docker-compose ps

# Should show: Up X seconds (healthy)
```

---

## Migration for Existing Deployments

If you've already deployed and encounter this error:

```bash
# 1. Pull the latest changes
cd /opt/relay  # Or your deployment directory
git pull

# 2. Verify the fix
docker-compose config

# 3. Restart services
docker-compose down
docker-compose up -d

# 4. Verify deployment
./verify-deployment.sh
```

---

## Docker Compose Version Guide

| Version | Status | Version Key Required? | Recommendation |
|---------|--------|----------------------|----------------|
| **v2.x** | ✅ Current | ❌ No (omit it) | **Use this** |
| **v1.27+** | ✅ Supported | ❌ Optional | Upgrade to v2 |
| **v1.x** | ⚠️ Legacy | ✅ Yes (`3.3` or lower) | Upgrade ASAP |

Check your version:
```bash
docker-compose version
# or
docker compose version
```

---

## Compatibility Notes

The version-less format is compatible with:

- ✅ Docker Compose v2.0+ (standalone)
- ✅ Docker Compose v2.0+ (plugin: `docker compose`)
- ✅ Docker Desktop (Mac/Windows) with Docker Compose v2
- ✅ Podman Compose 1.0+

---

## Additional Resources

- **Docker Compose Specification**: https://docs.docker.com/compose/compose-file/
- **Docker Compose v2 Release Notes**: https://docs.docker.com/compose/release-notes/
- **Migration Guide**: https://docs.docker.com/compose/migrate/

---

## Summary

✅ **Fix applied**: Version key removed from docker-compose.yml  
✅ **Modern best practice**: Version-less format for Docker Compose v2+  
✅ **No breaking changes**: All features still work  
✅ **Better compatibility**: Works across Docker Compose versions  

**No action needed if using Docker Compose v2+** (which most systems have as of 2023+)

---

*Last updated: October 30, 2025*

