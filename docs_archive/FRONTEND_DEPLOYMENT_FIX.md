# Frontend Deployment Fix - Module Loading Error

## 🔴 Problem

```
Failed to load module script: Expected a JavaScript module script but the server responded with a MIME type of "text/html"
```

**Root Cause:** Your server is returning `index.html` (MIME type: `text/html`) when the browser requests JavaScript modules. This happens when the server isn't configured correctly for Single Page Applications (SPA).

---

## ✅ Solutions by Hosting Platform

### Option 1: Vercel (Recommended - Easiest)

**File created:** `vercel.json`

```json
{
  "rewrites": [
    {
      "source": "/(.*)",
      "destination": "/index.html"
    }
  ]
}
```

**Deploy:**
```bash
npm install -g vercel
vercel login
vercel --prod
```

✅ **Benefits:**
- Zero configuration
- Automatic HTTPS
- CDN included
- Deploy in 2 minutes

---

### Option 2: Netlify

**Files created:** 
- `netlify.toml` (configuration)
- `public/_redirects` (fallback rules)

**Deploy:**

1. **Via CLI:**
```bash
npm install -g netlify-cli
netlify login
netlify deploy --prod --dir=dist
```

2. **Via Git:**
- Push to GitHub
- Connect repo at https://app.netlify.com
- Build command: `npm run build`
- Publish directory: `dist`

✅ **Benefits:**
- Free tier generous
- Automatic HTTPS
- Easy Git integration

---

### Option 3: Your Own Server (Nginx)

**File created:** `nginx.conf.example`

#### Step 1: Install Nginx

```bash
# Ubuntu/Debian
sudo apt update
sudo apt install nginx

# Check status
sudo systemctl status nginx
```

#### Step 2: Build Frontend

```bash
npm run build:production
```

This creates the `dist/` folder with your production build.

#### Step 3: Upload to Server

```bash
# Create directory
ssh your-server 'sudo mkdir -p /var/www/cardstudio'

# Upload build
rsync -avz --progress dist/ your-server:/var/www/cardstudio/dist/

# Set permissions
ssh your-server 'sudo chown -R www-data:www-data /var/www/cardstudio'
```

#### Step 4: Configure Nginx

```bash
# Copy example config
scp nginx.conf.example your-server:/tmp/cardstudio.conf

# SSH to server
ssh your-server

# Move to sites-available
sudo mv /tmp/cardstudio.conf /etc/nginx/sites-available/cardstudio

# Create symlink
sudo ln -s /etc/nginx/sites-available/cardstudio /etc/nginx/sites-enabled/

# Remove default site (if exists)
sudo rm /etc/nginx/sites-enabled/default

# Test config
sudo nginx -t

# Reload Nginx
sudo systemctl reload nginx
```

#### Step 5: Setup HTTPS with Certbot

```bash
# Install Certbot
sudo apt install certbot python3-certbot-nginx

# Get certificate
sudo certbot --nginx -d cardstudio.org -d www.cardstudio.org

# Test auto-renewal
sudo certbot renew --dry-run
```

#### Step 6: Update Frontend Environment

Edit your `.env.production`:
```bash
VITE_SUPABASE_URL=https://your-project.supabase.co
VITE_SUPABASE_ANON_KEY=your-anon-key
VITE_OPENAI_RELAY_URL=https://your-relay-url
# ... other vars
```

Rebuild and redeploy:
```bash
npm run build:production
rsync -avz --progress dist/ your-server:/var/www/cardstudio/dist/
```

---

## 🔍 Debugging

### Check if files are being served correctly

```bash
# Test index.html
curl -I https://cardstudio.org/

# Test JS module (should be text/javascript, NOT text/html)
curl -I https://cardstudio.org/assets/index-KTZFtB0Y.js
```

**Expected response:**
```
HTTP/2 200
content-type: text/javascript; charset=utf-8
cache-control: public, max-age=31536000, immutable
```

**Wrong response (current problem):**
```
HTTP/2 200
content-type: text/html; charset=utf-8
```

### Check SPA routing

```bash
# These should all return 200 and serve index.html
curl -I https://cardstudio.org/
curl -I https://cardstudio.org/cms/mycards
curl -I https://cardstudio.org/c/some-card-id
```

### Browser DevTools

1. Open DevTools → Network tab
2. Reload page
3. Check failed request (red)
4. Click on it → Preview tab
5. If you see HTML instead of JavaScript → server misconfigured

---

## 📋 Verification Checklist

After deploying, verify:

- [ ] Homepage loads: `https://cardstudio.org/`
- [ ] Direct card URL works: `https://cardstudio.org/c/{card-id}`
- [ ] Dashboard routes work: `https://cardstudio.org/cms/mycards`
- [ ] No console errors about MIME types
- [ ] All assets load (check Network tab)
- [ ] JavaScript modules have correct MIME type
- [ ] HTTPS is working (no mixed content)
- [ ] Mobile web app meta tags work (no warnings)

---

## 🚀 Quick Fix for Emergency

If you need an immediate fix while configuring the server:

### Use Hash Router (Temporary!)

Edit `src/router/index.ts`:

```typescript
import { createRouter, createWebHashHistory } from 'vue-router'

const router = createRouter({
  history: createWebHashHistory(import.meta.env.BASE_URL), // Changed!
  routes: [...]
})
```

This changes URLs from:
- ❌ `https://cardstudio.org/c/card-id`
- ✅ `https://cardstudio.org/#/c/card-id`

**Drawbacks:**
- URLs look worse (has `#`)
- Less SEO friendly
- Not recommended for production

**Better:** Fix server configuration properly!

---

## 📖 Additional Resources

- [Vite - Deploying a Static Site](https://vitejs.dev/guide/static-deploy.html)
- [Vue Router - Server Configuration](https://router.vuejs.org/guide/essentials/history-mode.html#example-server-configurations)
- [Nginx - SPA Configuration](https://router.vuejs.org/guide/essentials/history-mode.html#nginx)

---

## ❓ Still Not Working?

1. **Clear browser cache:**
   - Chrome: `Ctrl+Shift+Delete` → Clear cache
   - Or use Incognito mode

2. **Check build output:**
   ```bash
   npm run build:production
   ls -la dist/
   ls -la dist/assets/
   ```

3. **Verify environment variables:**
   ```bash
   cat .env.production
   ```

4. **Test locally:**
   ```bash
   npm run preview
   # Opens http://localhost:4173
   # Should work perfectly
   ```

5. **Check server logs:**
   ```bash
   # Nginx
   sudo tail -f /var/log/nginx/error.log
   
   # Or check access log
   sudo tail -f /var/log/nginx/access.log
   ```

---

## 🎯 Recommended Deployment (Fastest)

**For Production:**
1. Use **Vercel** or **Netlify** (zero config, works immediately)
2. Or use **Nginx** with provided `nginx.conf.example`

**Current setup files:**
- ✅ `vercel.json` - Ready to use
- ✅ `netlify.toml` - Ready to use
- ✅ `public/_redirects` - Netlify fallback
- ✅ `nginx.conf.example` - Nginx template
- ✅ `index.html` - Fixed meta tag deprecation

**Deploy now:**
```bash
# Vercel (recommended)
npm install -g vercel
vercel --prod

# Or Netlify
npm install -g netlify-cli
netlify deploy --prod --dir=dist
```

---

## ✅ Meta Tag Deprecation Fixed

**Before:**
```html
<meta name="apple-mobile-web-app-capable" content="yes">
```

**After (fixed in index.html):**
```html
<meta name="mobile-web-app-capable" content="yes">
<meta name="apple-mobile-web-app-capable" content="yes">
```

Now includes both the new standard (`mobile-web-app-capable`) and keeps the old one for backward compatibility.

---

**Questions?** Check your server logs and browser DevTools Network tab for more details!

