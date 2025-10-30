# Docker Daemon Not Running - Quick Fix

**Error:** `Couldn't connect to Docker daemon at http+docker://localhost - is it running?`

**Solution:** Start the Docker daemon and ensure your user has permissions.

---

## 🔍 Diagnose the Issue

Run these commands on your server to check Docker status:

```bash
# Check if Docker is installed
docker --version

# Check if Docker daemon is running
sudo systemctl status docker

# Check if your user is in docker group
groups $USER | grep docker
```

---

## ✅ Quick Fix (Copy-Paste This)

```bash
# 1. Start Docker daemon
sudo systemctl start docker

# 2. Enable Docker to start on boot
sudo systemctl enable docker

# 3. Add your user to docker group (avoid sudo every time)
sudo usermod -aG docker $USER

# 4. Apply group changes (IMPORTANT!)
newgrp docker

# Or alternatively, log out and back in:
# exit
# ssh user@your-server

# 5. Verify Docker is running
sudo systemctl status docker

# 6. Test Docker without sudo
docker ps

# Should work without "permission denied" error
```

---

## 📋 Step-by-Step Fix

### Step 1: Check Docker Installation

```bash
docker --version
```

**If not installed:**
```bash
# Install Docker
curl -fsSL https://get.docker.com | sh
```

### Step 2: Start Docker Service

```bash
# Start Docker
sudo systemctl start docker

# Check status
sudo systemctl status docker

# Should show: "active (running)"
```

**If it shows "inactive (dead)":**
```bash
# Start it
sudo systemctl start docker

# Enable auto-start on boot
sudo systemctl enable docker
```

### Step 3: Fix Permissions

The error occurs because your user doesn't have permission to access Docker socket.

```bash
# Add your user to docker group
sudo usermod -aG docker $USER

# IMPORTANT: Apply group changes
newgrp docker

# OR log out and back in
exit
ssh user@your-server
```

### Step 4: Verify It Works

```bash
# Test Docker (should work WITHOUT sudo)
docker ps

# If this works, you're good!

# Test docker-compose
docker-compose --version

# Should show version without errors
```

---

## 🚀 Now Deploy Relay Server

Once Docker is running:

```bash
# Navigate to directory
cd ~/Cardy/openai-relay-server

# Ensure .env exists
ls -la .env

# If not:
cp .env.example .env
nano .env

# Test configuration
docker-compose config

# Start service
docker-compose up -d

# Wait 10 seconds
sleep 10

# Check status
docker-compose ps

# Test health
curl http://localhost:8080/health
```

---

## 🚨 Common Issues

### Issue 1: "Permission denied" after adding to docker group

**Problem:** Group changes require re-login

**Solution:**
```bash
# Option 1: Use newgrp (immediate)
newgrp docker

# Option 2: Log out and back in (recommended)
exit
ssh user@your-server
```

### Issue 2: Docker fails to start

```bash
# Check logs
sudo journalctl -u docker.service -n 50

# Common causes:
# - Port conflicts
# - Storage driver issues
# - Firewall blocking
```

**Try restarting:**
```bash
sudo systemctl restart docker
```

### Issue 3: "docker: command not found"

**Problem:** Docker not installed

**Solution:**
```bash
# Install Docker
curl -fsSL https://get.docker.com | sh

# Start service
sudo systemctl start docker
sudo systemctl enable docker
```

### Issue 4: Docker installed but systemctl doesn't work

**On systems without systemd (older distributions):**

```bash
# Start Docker manually
sudo service docker start

# Check status
sudo service docker status

# Enable on boot
sudo chkconfig docker on
```

---

## 🔧 Complete Diagnostic Script

Copy-paste this to diagnose all issues:

```bash
#!/bin/bash

echo "=== Docker Diagnostics ==="

# Check Docker installation
echo -e "\n1. Docker Installation:"
if command -v docker &> /dev/null; then
    docker --version
    echo "✅ Docker is installed"
else
    echo "❌ Docker is NOT installed"
    echo "   Install with: curl -fsSL https://get.docker.com | sh"
fi

# Check Docker service
echo -e "\n2. Docker Service Status:"
if sudo systemctl is-active --quiet docker 2>/dev/null; then
    echo "✅ Docker daemon is running"
else
    echo "❌ Docker daemon is NOT running"
    echo "   Start with: sudo systemctl start docker"
fi

# Check user permissions
echo -e "\n3. User Permissions:"
if groups $USER | grep -q docker; then
    echo "✅ User is in docker group"
else
    echo "❌ User is NOT in docker group"
    echo "   Fix with: sudo usermod -aG docker $USER"
    echo "   Then: newgrp docker"
fi

# Test Docker access
echo -e "\n4. Docker Access Test:"
if docker ps &> /dev/null; then
    echo "✅ Can access Docker (without sudo)"
else
    echo "❌ Cannot access Docker"
    echo "   Try: newgrp docker"
    echo "   Or: log out and back in"
fi

# Check docker-compose
echo -e "\n5. Docker Compose:"
if command -v docker-compose &> /dev/null; then
    docker-compose --version
    echo "✅ docker-compose is installed"
else
    echo "❌ docker-compose is NOT installed"
    echo "   Install with: sudo apt install docker-compose-plugin"
fi

echo -e "\n=== End Diagnostics ==="
```

**Run it:**
```bash
# Save the script
cat > check-docker.sh << 'EOF'
[paste the script above]
EOF

# Make executable
chmod +x check-docker.sh

# Run it
./check-docker.sh
```

---

## ✅ Success Criteria

You know Docker is ready when:

1. ✅ `docker --version` shows version
2. ✅ `sudo systemctl status docker` shows "active (running)"
3. ✅ `docker ps` works WITHOUT sudo
4. ✅ `docker-compose --version` works

---

## 🎯 Quick Fix Summary

```bash
# One-liner to fix everything:
sudo systemctl start docker && \
sudo systemctl enable docker && \
sudo usermod -aG docker $USER && \
newgrp docker && \
docker ps && \
echo "✅ Docker is ready!"
```

**Then deploy:**
```bash
cd ~/Cardy/openai-relay-server
docker-compose up -d
```

---

## 📚 Additional Resources

- **Docker Installation**: https://docs.docker.com/engine/install/
- **Post-installation steps**: https://docs.docker.com/engine/install/linux-postinstall/
- **Docker systemd**: https://docs.docker.com/config/daemon/systemd/

---

*Last updated: October 30, 2025*

