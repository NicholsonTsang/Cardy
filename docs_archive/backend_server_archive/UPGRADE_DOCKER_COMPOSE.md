# Upgrade Docker Compose - Fix Old Version

**Error:** `client version 1.22 is too old. Minimum supported API version is 1.24`

**Solution:** Upgrade docker-compose to the latest version

---

## 🚀 Quick Fix (Copy-Paste on Your Server)

```bash
# 1. Remove old docker-compose
sudo rm /usr/local/bin/docker-compose
sudo rm /usr/bin/docker-compose

# 2. Install latest docker-compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

# 3. Make it executable
sudo chmod +x /usr/local/bin/docker-compose

# 4. Verify installation
docker-compose --version

# Should show: docker-compose version 1.29+ or 2.x+

# 5. Now deploy
cd ~/Cardy/openai-relay-server
docker-compose up -d
```

---

## 📋 Step-by-Step Upgrade

### Step 1: Check Current Version

```bash
docker-compose --version

# Output: docker-compose version 1.22.x
# ❌ Too old! Need 1.24+
```

### Step 2: Remove Old Version

```bash
# Find where docker-compose is installed
which docker-compose

# Common locations:
# /usr/local/bin/docker-compose
# /usr/bin/docker-compose

# Remove old version
sudo rm /usr/local/bin/docker-compose
sudo rm /usr/bin/docker-compose

# If installed via apt:
sudo apt remove docker-compose
```

### Step 3: Install Latest Version

**Option A: Direct Download (Recommended)**

```bash
# Get latest version
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

# Make executable
sudo chmod +x /usr/local/bin/docker-compose

# Verify
docker-compose --version
```

**Option B: Specific Version**

```bash
# Install specific version (e.g., 1.29.2)
VERSION="1.29.2"
sudo curl -L "https://github.com/docker/compose/releases/download/${VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

# Make executable
sudo chmod +x /usr/local/bin/docker-compose
```

**Option C: Via pip (Python)**

```bash
# Install Python pip if not available
sudo apt install python3-pip -y

# Install docker-compose
sudo pip3 install docker-compose

# Verify
docker-compose --version
```

### Step 4: Verify Installation

```bash
# Check version
docker-compose --version

# Should show: 1.29+ or 2.x+
# ✅ Ready to use!

# Test with your config
cd ~/Cardy/openai-relay-server
docker-compose config

# Should work without errors
```

---

## 🎯 Complete Upgrade Script

```bash
#!/bin/bash

echo "=== Upgrading Docker Compose ==="

# Show current version
echo -e "\nCurrent version:"
docker-compose --version 2>/dev/null || echo "Not installed"

# Remove old versions
echo -e "\nRemoving old version..."
sudo rm -f /usr/local/bin/docker-compose
sudo rm -f /usr/bin/docker-compose
sudo apt remove -y docker-compose 2>/dev/null

# Download latest
echo -e "\nDownloading latest docker-compose..."
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

# Make executable
sudo chmod +x /usr/local/bin/docker-compose

# Verify
echo -e "\nNew version:"
docker-compose --version

echo -e "\n✅ Upgrade complete!"
```

**Run it:**

```bash
# Copy script to file
cat > upgrade-docker-compose.sh << 'EOF'
[paste script above]
EOF

# Make executable
chmod +x upgrade-docker-compose.sh

# Run
./upgrade-docker-compose.sh
```

---

## ✅ After Upgrade - Deploy Relay Server

```bash
# Navigate to directory
cd ~/Cardy/openai-relay-server

# Ensure .env exists
if [ ! -f .env ]; then
    cp .env.example .env
    echo "⚠️  Edit .env with your settings"
    nano .env
fi

# Test configuration
docker-compose config

# Start service
docker-compose up -d

# Wait for startup
sleep 10

# Check status
docker-compose ps

# Test health
curl http://localhost:8080/health

# Expected: {"status":"healthy",...}
```

---

## 🚨 Troubleshooting

### Error: "curl: command not found"

```bash
# Install curl
sudo apt update
sudo apt install curl -y

# Then try upgrade again
```

### Error: "Permission denied"

```bash
# Make sure using sudo
sudo curl -L ...

# Or switch to root temporarily
sudo su
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
exit
```

### Error: "Cannot download from GitHub"

**Option 1: Use specific version URL**
```bash
# Try with specific version
VERSION="1.29.2"
sudo curl -L "https://github.com/docker/compose/releases/download/${VERSION}/docker-compose-Linux-x86_64" -o /usr/local/bin/docker-compose
```

**Option 2: Install via pip**
```bash
sudo apt install python3-pip -y
sudo pip3 install docker-compose
```

### Still shows old version after upgrade

```bash
# Check all locations
which -a docker-compose

# Remove all old copies
sudo rm /usr/local/bin/docker-compose
sudo rm /usr/bin/docker-compose
sudo rm ~/bin/docker-compose

# Reinstall to /usr/local/bin
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Reload shell
hash -r

# Check again
docker-compose --version
```

---

## 📊 Version Compatibility

| Docker Compose | API Version | Status |
|----------------|-------------|--------|
| 1.22.x | 1.22 | ❌ Too old |
| 1.24.x | 1.24 | ⚠️ Minimum |
| 1.29.x | 1.41 | ✅ Good |
| 2.x.x | Latest | ✅ Best |

**Your current:** 1.22 ❌  
**Required:** 1.24+  
**Recommended:** 1.29+ or 2.x

---

## 🔍 Version Check Commands

```bash
# Check docker-compose version
docker-compose --version

# Check Docker daemon version
docker version

# Check API version
docker version --format '{{.Client.APIVersion}}'
```

---

## 🌐 Manual Download (If Script Fails)

Visit: https://github.com/docker/compose/releases/latest

Find the file for your system:
- Linux x86_64: `docker-compose-Linux-x86_64`
- Linux ARM: `docker-compose-Linux-armv7l`

Download and install:
```bash
# Replace URL with the file you downloaded
wget https://github.com/docker/compose/releases/download/v2.x.x/docker-compose-linux-x86_64

# Move to bin
sudo mv docker-compose-linux-x86_64 /usr/local/bin/docker-compose

# Make executable
sudo chmod +x /usr/local/bin/docker-compose

# Verify
docker-compose --version
```

---

## 📦 Alternative: Docker Compose Plugin

Modern Docker includes Compose as a plugin:

```bash
# Install Docker Compose plugin
sudo apt update
sudo apt install docker-compose-plugin -y

# Use with: docker compose (note: space, not dash)
docker compose version

# Deploy with:
docker compose up -d
```

**Note:** Command is `docker compose` (with space) not `docker-compose` (with dash)

---

## ✅ Success Checklist

- [ ] Old docker-compose removed
- [ ] New docker-compose downloaded
- [ ] Executable permissions set
- [ ] `docker-compose --version` shows 1.24+
- [ ] `docker-compose config` works in your project
- [ ] Ready to deploy!

---

## 🎉 Quick Summary

**Problem:** docker-compose version 1.22 is too old  
**Solution:** Upgrade to 1.29+ or 2.x  

**One-liner:**
```bash
sudo rm /usr/local/bin/docker-compose /usr/bin/docker-compose 2>/dev/null; sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose && sudo chmod +x /usr/local/bin/docker-compose && docker-compose --version
```

**Then deploy:**
```bash
cd ~/Cardy/openai-relay-server && docker-compose up -d
```

---

*Last updated: October 30, 2025*

