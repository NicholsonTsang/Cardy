# Deploy Password Reset Fix - Quick Guide

## What Was Fixed

The password reset flow was not working because:
1. Missing `PASSWORD_RECOVERY` event handler in the auth store
2. Missing redirect URL configuration in Supabase

## Code Changes (Already Done ✅)

1. **src/stores/auth.ts** - Added PASSWORD_RECOVERY event handler
2. **.env.example** - Documented redirect URL configuration
3. **CLAUDE.md** - Added to common issues section
4. **PASSWORD_RESET_FIX.md** - Full documentation created

## Deployment Steps

### Step 1: Deploy Code Changes
The code changes are already made and ready to commit. Simply deploy as usual:

```bash
git add .
git commit -m "Fix: Password reset redirect flow"
git push
```

### Step 2: Configure Supabase (CRITICAL ⚠️)

**You MUST configure this in Supabase Dashboard for password reset to work:**

1. Go to [Supabase Dashboard](https://app.supabase.com)
2. Select your project
3. Navigate to: **Authentication** → **URL Configuration**
4. Scroll to the **Redirect URLs** section
5. Click **Add URL** for each of the following:

**For Local Development:**
```
http://localhost:5173/reset-password
```

**For Production:**
```
https://your-production-domain.com/reset-password
```

**Optional - Wildcards (if you want to allow any path):**
```
http://localhost:5173/*
https://your-production-domain.com/*
```

6. Click **Save**

### Step 3: Test the Flow

**Local Testing:**
1. Run `npm run dev`
2. Go to `http://localhost:5173/login`
3. Click "Forgot Password?"
4. Enter your email
5. Check email for reset link
6. Click the link
7. **Verify**: You should be redirected to `http://localhost:5173/reset-password`
8. Enter new password
9. **Verify**: Password updates successfully

**Production Testing:**
1. Go to your production login page
2. Repeat the same steps as local testing
3. Verify the reset link redirects to your production `/reset-password` page

## What Happens Now

### Before the Fix ❌
- User clicks reset link in email
- Supabase tries to redirect to `/reset-password`
- Redirect fails because URL is not whitelisted
- User sees an error or blank page

### After the Fix ✅
- User clicks reset link in email
- Supabase redirects to whitelisted `/reset-password` URL
- `PASSWORD_RECOVERY` event fires
- App automatically navigates to reset password page
- User can enter new password
- Password updates successfully

## Troubleshooting

**Q: User still not being redirected**
- Check that you added the redirect URL to Supabase Dashboard
- Check that the URL exactly matches (including http/https)
- Clear browser cache and try again

**Q: "Invalid or expired reset link" error**
- Links expire after 1 hour
- Request a new reset link
- Check that user has a valid session

**Q: Reset email not received**
- Check spam folder
- Verify email in Supabase Auth logs
- Check Supabase SMTP configuration

**Q: Works locally but not in production**
- Verify production domain is added to Supabase redirect URLs
- Check that production URL uses HTTPS (not HTTP)
- Clear browser cache

## Important Notes

- Reset links expire after **1 hour** (Supabase default)
- Access tokens are **one-time use**
- You must add redirect URLs for **every domain** you want to support (dev, staging, prod)
- The `PASSWORD_RECOVERY` event handler is now automatic - no user action needed

## Reference

See `PASSWORD_RESET_FIX.md` for complete technical documentation including:
- Full flow diagrams
- Security notes
- Code explanations
- Future improvements

## Support

If issues persist after following these steps:
1. Check browser console for errors
2. Check Supabase Auth logs
3. Verify all redirect URLs are correctly configured
4. Review `PASSWORD_RESET_FIX.md` for detailed troubleshooting


