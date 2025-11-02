# CORS Configuration Guide

## Overview

The relay server uses CORS (Cross-Origin Resource Sharing) to control which websites can connect to it.

---

## 🔓 Allow All Origins (Development/Testing)

**Default setting in `.env.example`**

```bash
ALLOWED_ORIGINS=*
```

### ✅ When to Use
- Local development
- Testing from multiple domains
- Internal tools/demos
- Development/staging environments

### ⚠️ Security Warning
- **Not recommended for production** if your relay is publicly accessible
- Anyone can use your relay server
- Could lead to unexpected API costs if abused

### How It Works
```javascript
// Relay server allows ANY origin
Browser (localhost:5173)    → ✅ Allowed
Browser (localhost:3000)    → ✅ Allowed
Browser (your-domain.com)   → ✅ Allowed
Browser (any-other-site.com) → ✅ Allowed
```

---

## 🔒 Restrict to Specific Origins (Production)

**Recommended for production**

### Single Origin
```bash
ALLOWED_ORIGINS=https://your-app.com
```

### Multiple Origins
```bash
ALLOWED_ORIGINS=https://your-app.com,https://admin.your-app.com,https://staging.your-app.com
```

### ✅ When to Use
- Production deployments
- Public-facing relay servers
- When you want to control access

### Security Benefits
- Only specified websites can connect
- Prevents unauthorized usage
- Protects against API cost abuse
- Better security posture

### How It Works
```javascript
// With ALLOWED_ORIGINS=https://your-app.com,https://staging.your-app.com

Browser (your-app.com)      → ✅ Allowed
Browser (staging.your-app.com) → ✅ Allowed
Browser (localhost:5173)    → ❌ Blocked (CORS error)
Browser (other-site.com)    → ❌ Blocked (CORS error)
```

---

## 📋 Configuration Examples

### Example 1: Local Development

```bash
# .env
OPENAI_API_KEY=sk-your-key-here
PORT=8080
NODE_ENV=development
ALLOWED_ORIGINS=*
```

**Result**: Any website can connect (easy for testing)

---

### Example 2: Production (Single Domain)

```bash
# .env
OPENAI_API_KEY=sk-your-production-key
PORT=8080
NODE_ENV=production
ALLOWED_ORIGINS=https://your-domain.com
```

**Result**: Only `https://your-domain.com` can connect

---

### Example 3: Production (Multiple Domains)

```bash
# .env
OPENAI_API_KEY=sk-your-production-key
PORT=8080
NODE_ENV=production
ALLOWED_ORIGINS=https://your-app.com,https://admin.your-app.com,https://staging.your-app.com
```

**Result**: Only your specified domains can connect

---

### Example 4: Local + Production Testing

```bash
# .env
OPENAI_API_KEY=sk-your-key
PORT=8080
NODE_ENV=development
ALLOWED_ORIGINS=http://localhost:5173,http://localhost:3000,https://your-domain.com
```

**Result**: Local development + your production domain

---

## 🔧 How to Change Configuration

### Step 1: Edit `.env` file

```bash
cd openai-relay-server
nano .env
```

### Step 2: Set ALLOWED_ORIGINS

**For development:**
```bash
ALLOWED_ORIGINS=*
```

**For production:**
```bash
ALLOWED_ORIGINS=https://your-actual-domain.com
```

### Step 3: Restart relay server

**With PM2:**
```bash
pm2 restart openai-relay
```

**With npm:**
```bash
# Stop server (Ctrl+C)
# Start again
npm run dev
```

**With Docker:**
```bash
docker restart openai-relay
```

---

## 🧪 Test Your Configuration

### Test 1: Check Server Logs

When relay starts, you'll see:
```
🌐 Allowed origins: *
```
or
```
🌐 Allowed origins: https://your-app.com, https://staging.your-app.com
```

### Test 2: Test from Browser

Open browser DevTools Console and try:

```javascript
// Test if your origin is allowed
fetch('http://localhost:8080/health')
  .then(r => r.json())
  .then(console.log)
  .catch(console.error)
```

**If allowed**: You'll see `{status: "healthy", ...}`
**If blocked**: You'll see CORS error

### Test 3: Check CORS Headers

```bash
curl -I http://localhost:8080/health
```

Look for:
```
access-control-allow-origin: *
```
or
```
access-control-allow-origin: https://your-app.com
```

---

## 🚨 Troubleshooting

### Problem: CORS Error in Browser

**Error message:**
```
Access to fetch at 'http://localhost:8080/...' from origin 'http://localhost:5173' 
has been blocked by CORS policy
```

**Solution 1: Allow All Origins (Development)**
```bash
# In relay server .env
ALLOWED_ORIGINS=*
```

**Solution 2: Add Your Origin (Production)**
```bash
# In relay server .env
ALLOWED_ORIGINS=http://localhost:5173,https://your-domain.com
```

**Then restart:**
```bash
pm2 restart openai-relay
```

---

### Problem: Configuration Not Taking Effect

**Check 1: Verify .env file**
```bash
cat .env | grep ALLOWED_ORIGINS
```

**Check 2: Restart server**
```bash
pm2 restart openai-relay
# or
# Stop and start npm run dev
```

**Check 3: Check server logs**
```bash
pm2 logs openai-relay
```

Look for: `🌐 Allowed origins: ...`

---

### Problem: Some Origins Work, Others Don't

**Cause**: Origins must match **exactly**

**Wrong:**
```bash
# .env has https://your-app.com
# Browser is on https://www.your-app.com  ← ❌ Different (www)
# Browser is on http://your-app.com       ← ❌ Different (http vs https)
```

**Correct:**
```bash
# Include all variations you need
ALLOWED_ORIGINS=https://your-app.com,https://www.your-app.com,http://your-app.com
```

---

## 📊 Security Comparison

| Configuration | Security | Convenience | Recommended For |
|--------------|----------|-------------|-----------------|
| `ALLOWED_ORIGINS=*` | ⚠️ Low | ✅ High | Development/Testing |
| `ALLOWED_ORIGINS=https://your-app.com` | ✅ High | ⚠️ Low | Production |
| `ALLOWED_ORIGINS=localhost,your-domain` | ⚡ Medium | ⚡ Medium | Mixed dev/prod testing |

---

## 🎯 Best Practices

### Development
```bash
✅ Use: ALLOWED_ORIGINS=*
✅ Easy testing from any origin
✅ No CORS headaches during development
```

### Staging
```bash
⚡ Use: ALLOWED_ORIGINS=https://staging.your-app.com,http://localhost:5173
⚡ Test production CORS behavior
⚡ Allow local testing too
```

### Production
```bash
✅ Use: ALLOWED_ORIGINS=https://your-app.com
✅ Specify exact production domains
✅ Never use * in production
✅ Include www and non-www if needed
```

---

## 🔐 Additional Security

Even with `ALLOWED_ORIGINS=*`, the relay is still protected by:

- ✅ **Rate Limiting** - 100 requests per 15 minutes per IP
- ✅ **Input Validation** - All request fields validated
- ✅ **Error Handling** - No sensitive data leaked
- ✅ **API Key Security** - OpenAI key never exposed to browser

However, restrictive CORS is still recommended for production!

---

## 📚 Related Documentation

- [Relay Server README](README.md) - Full documentation
- [Security Best Practices](README.md#security-considerations)
- [Deployment Guide](DEPLOYMENT_SSH.md) - Production setup

---

## ✅ Quick Reference

**Allow all origins (development):**
```bash
ALLOWED_ORIGINS=*
```

**Restrict to your domain (production):**
```bash
ALLOWED_ORIGINS=https://your-actual-domain.com
```

**Multiple domains:**
```bash
ALLOWED_ORIGINS=https://site1.com,https://site2.com,https://site3.com
```

**Restart to apply:**
```bash
pm2 restart openai-relay
```

---

**Remember**: The default configuration now uses `ALLOWED_ORIGINS=*` for easy setup. Change this to your specific domains when deploying to production!

