# Password Reset Fix

## Problem
The password reset email from Supabase was not redirecting users to the correct reset password page. Users who clicked the reset link in their email were not being routed to `/reset-password` where they could enter their new password.

## Root Cause
The issue had two components:

1. **Missing Redirect URL Whitelist**: The `/reset-password` URL was not configured in Supabase's redirect URL whitelist
2. **Missing Auth State Handler**: The application was not listening for the `PASSWORD_RECOVERY` auth event from Supabase

## Solution

### 1. Updated Auth Store
Added a `PASSWORD_RECOVERY` event handler in `src/stores/auth.ts` that automatically redirects users to the reset password page when they click the email link:

```typescript
if (event === 'PASSWORD_RECOVERY') {
  console.log('Password recovery event detected, redirecting to reset-password page')
  router.push('/reset-password')
}
```

### 2. Documented Required Configuration
Updated `.env.example` to clearly document that redirect URLs must be whitelisted in Supabase.

### 3. Required Supabase Configuration

**CRITICAL**: You must configure the redirect URL in your Supabase Dashboard:

1. Go to **Supabase Dashboard** → **Authentication** → **URL Configuration**
2. Find the **Redirect URLs** section
3. Add the following URLs to the whitelist:
   - For local development: `http://localhost:5173/reset-password`
   - For production: `https://your-production-domain.com/reset-password`
   - For preview deployments: Add each preview URL as needed

**Example Configuration:**
```
http://localhost:5173/reset-password
http://localhost:5173/*
https://cardstudio.app/reset-password
https://cardstudio.app/*
```

## How Password Reset Works

### User Flow
1. User clicks "Forgot Password?" on login page
2. User enters email address in dialog
3. Frontend calls `authStore.sendPasswordResetEmail(email)`
4. Supabase sends email with reset link to user
5. User clicks link in email
6. Supabase redirects to: `https://your-app.com/reset-password#access_token=...&type=recovery`
7. Auth state change event fires with `PASSWORD_RECOVERY`
8. App automatically navigates to `/reset-password` page
9. ResetPassword component validates the access token
10. User enters new password
11. Password is updated via `authStore.updatePassword()`
12. User is redirected to login page

### Technical Flow

**Email Sent:**
```typescript
// src/stores/auth.ts (line 199-234)
const redirectUrl = `${window.location.origin}/reset-password`
await supabase.auth.resetPasswordForEmail(email_value, {
  redirectTo: redirectUrl
})
```

**Supabase Email Link:**
```
https://your-project.supabase.co/auth/v1/verify?token=...&type=recovery&redirect_to=https://your-app.com/reset-password
```

**After User Clicks:**
```
https://your-app.com/reset-password#access_token=xxx&expires_in=3600&refresh_token=xxx&token_type=bearer&type=recovery
```

**Auth State Handler:**
```typescript
// src/stores/auth.ts (line 40-43)
if (event === 'PASSWORD_RECOVERY') {
  router.push('/reset-password')
}
```

**Reset Password Component:**
```vue
<!-- src/views/Dashboard/ResetPassword.vue (line 152-159) -->
onMounted(() => {
  const hashParams = new URLSearchParams(window.location.hash.substring(1));
  const accessToken = hashParams.get('access_token');
  
  if (!accessToken) {
    errorMessage.value = 'Invalid or expired reset link. Please request a new one.';
  }
});
```

## Testing the Fix

### Local Testing
1. Start local dev server: `npm run dev`
2. Navigate to `http://localhost:5173/login`
3. Click "Forgot Password?"
4. Enter a valid email address
5. Check email inbox for reset link
6. Click the link in the email
7. Verify you are redirected to `http://localhost:5173/reset-password`
8. Enter new password and confirm
9. Verify password is updated successfully

### Production Testing
1. Deploy the updated code to production
2. Ensure production domain is in Supabase redirect URL whitelist
3. Test the full flow on production domain

## Deployment Checklist

- [ ] Code changes deployed to production
- [ ] Production domain added to Supabase redirect URL whitelist: `https://your-domain.com/reset-password`
- [ ] Local development URL added to Supabase redirect URL whitelist: `http://localhost:5173/reset-password`
- [ ] Tested password reset flow in production
- [ ] Tested password reset flow in local development
- [ ] Email template reviewed (optional - Supabase default is fine)

## Common Issues

### Issue 1: "Invalid or expired reset link"
**Cause**: The redirect URL is not whitelisted in Supabase
**Solution**: Add the URL to Supabase Dashboard → Authentication → URL Configuration → Redirect URLs

### Issue 2: User clicks link but nothing happens
**Cause**: Either the redirect URL is wrong or the auth state handler is not working
**Solution**: 
- Check browser console for errors
- Verify `PASSWORD_RECOVERY` event is firing
- Ensure router is properly initialized

### Issue 3: Redirects to wrong page
**Cause**: Multiple auth state handlers or router guards interfering
**Solution**: Check that only one `PASSWORD_RECOVERY` handler exists in auth.ts

### Issue 4: Email not received
**Cause**: Email might be in spam, or Supabase SMTP not configured
**Solution**: 
- Check spam folder
- Verify email in Supabase Auth logs
- Check Supabase SMTP configuration

## Files Changed

1. `src/stores/auth.ts` - Added PASSWORD_RECOVERY event handler
2. `.env.example` - Documented redirect URL configuration requirements

## Related Files

- `src/views/Dashboard/SignIn.vue` - Forgot password dialog
- `src/views/Dashboard/ResetPassword.vue` - Reset password form
- `src/router/index.ts` - Reset password route configuration

## Security Notes

- Reset links expire after 1 hour (Supabase default)
- Access tokens are one-time use
- Password requirements: minimum 6 characters (enforced in UI and validation)
- Links are invalidated after successful password reset
- No authentication required to access reset page (by design)

## Future Improvements

Consider implementing:
- Custom email templates with branded design
- Password strength meter on reset page
- Rate limiting for reset requests
- Multi-factor authentication reset flow
- Password history to prevent reuse


