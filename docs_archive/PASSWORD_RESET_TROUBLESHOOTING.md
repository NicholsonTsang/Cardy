# Password Reset Link Troubleshooting

## Your Reset Link Analysis

**Link from email:**
```
https://mzgusshseqxrdrkvamrg.supabase.co/auth/v1/verify?token=09070ede6d87805aec89a9485feb67260a80fd759fc5bb6ad58d07f7&type=recovery&redirect_to=http://localhost:5173/reset-password
```

**Link breakdown:**
- ✅ Supabase endpoint: `https://mzgusshseqxrdrkvamrg.supabase.co/auth/v1/verify`
- ✅ Token: `09070ede6d87805aec89a9485feb67260a80fd759fc5bb6ad58d07f7`
- ✅ Type: `recovery` (correct for password reset)
- ✅ Redirect URL: `http://localhost:5173/reset-password`

**The link format is correct!**

## Expected Flow vs Actual Flow

### What SHOULD Happen:
1. You click the email link
2. Supabase verifies the token
3. Supabase redirects to: `http://localhost:5173/reset-password#access_token=xxx&type=recovery&...`
4. App loads reset password page
5. You see the password reset form

### What's ACTUALLY Happening:
1. You click the email link
2. Supabase verifies the token
3. ❌ **Something goes wrong here**
4. You end up on login page

## Troubleshooting Steps

### Step 1: Check Supabase URL Configuration

Go to this exact URL:
```
https://app.supabase.com/project/mzgusshseqxrdrkvamrg/auth/url-configuration
```

In the **"Redirect URLs"** section, you should see:

**Required entry (EXACT match, no trailing slash):**
```
http://localhost:5173/reset-password
```

**Common mistakes:**
- ❌ `http://localhost:5173/reset-password/` (trailing slash - wrong!)
- ❌ `https://localhost:5173/reset-password` (https instead of http - wrong!)
- ❌ `http://localhost:5173/*` (wildcard only - not enough!)

**Correct configuration:**
```
http://localhost:5173/reset-password
http://localhost:5173/*
```

### Step 2: Test the Link with Console Open

1. **Open a new incognito/private browser window** (to avoid session conflicts)
2. **Open Developer Tools FIRST** (F12 or Cmd+Option+I)
3. Go to the **Console tab**
4. **Paste and click this link:**
   ```
   https://mzgusshseqxrdrkvamrg.supabase.co/auth/v1/verify?token=09070ede6d87805aec89a9485feb67260a80fd759fc5bb6ad58d07f7&type=recovery&redirect_to=http://localhost:5173/reset-password
   ```

5. **Immediately watch the console output**

**Look for these messages:**

✅ **Good signs:**
```
Auth state change: PASSWORD_RECOVERY {...}
Password recovery event detected
Already on reset-password page, keeping hash parameters
```

❌ **Bad signs:**
```
Failed to redirect to: http://localhost:5173/reset-password
Invalid redirect URL
Redirect URL not allowed
```

### Step 3: Check the URL in Browser Address Bar

After clicking the link, what URL do you see?

**Scenario A - Supabase Blocks Redirect:**
```
https://mzgusshseqxrdrkvamrg.supabase.co/auth/v1/verify?error=invalid_redirect&message=...
```
**Cause:** Redirect URL not whitelisted in Supabase
**Fix:** Add the exact URL to Supabase redirect URLs

**Scenario B - Redirects to App but Wrong Page:**
```
http://localhost:5173/login
```
**Cause:** App logic redirecting away
**Fix:** Check router guards and auth state handler

**Scenario C - Correct Redirect:**
```
http://localhost:5173/reset-password#access_token=xxx&expires_in=3600&type=recovery&...
```
**This is what you want!**

### Step 4: Manual URL Test

Try accessing the reset password page directly:

1. Open browser
2. Paste this URL:
   ```
   http://localhost:5173/reset-password
   ```
3. Press Enter

**What happens?**
- ✅ You see the "Reset Password" form → Router is OK
- ❌ Redirected to login → Router guard issue

### Step 5: Network Tab Analysis

1. Open DevTools (F12)
2. Go to **Network tab**
3. Check **Preserve log**
4. Click the password reset link
5. Watch the network requests

**Look for:**
1. Request to Supabase verify endpoint
2. Response status (should be 302 redirect)
3. Location header (should be your reset-password URL)
4. Any errors in the redirect chain

## Common Issues and Fixes

### Issue 1: Redirect URL Mismatch

**Problem:** URL in whitelist doesn't exactly match redirect_to parameter

**Check:**
- No trailing slash: ❌ `/reset-password/`
- Correct protocol: ✅ `http://` (not `https://` for localhost)
- Correct port: ✅ `5173`
- Exact path: ✅ `/reset-password`

### Issue 2: Token Expired

**Problem:** Link is older than 1 hour

**Fix:** 
1. Go to login page
2. Click "Forgot Password?"
3. Request a NEW reset email
4. Use the NEW link (don't use old one)

### Issue 3: Session Conflict

**Problem:** You're already logged in, causing auth state confusion

**Fix:**
1. Sign out from the app
2. Clear browser cookies/localStorage for localhost
3. Try the reset link again in incognito mode

### Issue 4: Dev Server Not Running

**Problem:** App isn't running when you click the link

**Fix:**
1. Make sure dev server is running: `npm run dev`
2. Verify it's on port 5173
3. Then click the reset link

## Test Commands

### Restart Dev Server with Fresh State
```bash
# Stop server
Ctrl+C

# Start fresh
npm run dev
```

### Clear Browser Storage (Console)
```javascript
// Paste in browser console
localStorage.clear()
sessionStorage.clear()
location.reload()
```

### Check Current Auth State (Console)
```javascript
// Paste in browser console to check current session
const { data } = await window.supabase.auth.getSession()
console.log('Current session:', data)
```

## What to Share for Further Help

If still not working, share:

1. **Console output** - Screenshot or copy-paste console messages
2. **Network tab** - Screenshot showing the redirect chain
3. **Final URL** - What URL shows in address bar after clicking link
4. **Supabase config** - Screenshot of your Redirect URLs section
5. **Direct access test** - What happens when you visit `/reset-password` directly

## Quick Checklist

Before testing the link again:

- [ ] Dev server is running (`npm run dev`)
- [ ] Redirect URL added to Supabase (exact: `http://localhost:5173/reset-password`)
- [ ] Browser DevTools console is open
- [ ] Using a fresh/incognito browser window
- [ ] Link is fresh (less than 1 hour old)
- [ ] Signed out from any existing session

## Expected Success Flow

When everything works:

1. Click email link
2. Console shows: `Password recovery event detected`
3. URL becomes: `http://localhost:5173/reset-password#access_token=xxx&type=recovery...`
4. Reset password form appears
5. Enter new password
6. Success message
7. Redirect to login
8. Can login with new password

## Next Steps

1. **Check Supabase redirect URLs** (most common issue)
2. **Request a NEW reset email** (your link might be expired)
3. **Test with console open** and share the console output
4. **Try in incognito mode** to eliminate session conflicts

