# TTS Audio Generation Authentication Fix

## Issue

The `generate-tts-audio` Edge Function was failing with `ERR_CONNECTION_CLOSED` error when users tried to play audio responses in the AI Assistant.

### Error Message
```
Failed to load resource: net::ERR_CONNECTION_CLOSED
TTS generation error: TypeError: Failed to fetch
```

## Root Cause

The `generateAndPlayTTS` function in `useChatCompletion.ts` was incorrectly using the **Supabase anon key** as the Bearer token when calling the Edge Function:

```typescript
// ❌ INCORRECT - Using anon key
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY as string
const response = await fetch(`${supabaseUrl}/functions/v1/generate-tts-audio`, {
  headers: {
    'Authorization': `Bearer ${supabaseAnonKey}`,
  }
})
```

**Why this fails:**
- The anon key is meant for **public/unauthenticated** API calls
- Edge Functions expect a **user JWT token** to authenticate requests
- Without proper authentication, the Edge Function connection closes prematurely

## Fix

Updated the function to use the user's session JWT token:

```typescript
// ✅ CORRECT - Using user's JWT token
const { data: { session } } = await supabase.auth.getSession()
const token = session?.access_token

if (!token) {
  throw new Error('No authentication token available')
}

const response = await fetch(`${supabaseUrl}/functions/v1/generate-tts-audio`, {
  headers: {
    'Authorization': `Bearer ${token}`,
  }
})
```

## Changes Made

### 1. Fixed Authentication in `useChatCompletion.ts`
**File:** `src/views/MobileClient/components/AIAssistant/composables/useChatCompletion.ts`

- Lines 195-201: Added session token retrieval and validation
- Line 209: Changed Authorization header to use user's JWT token instead of anon key
- Removed unused `VITE_SUPABASE_ANON_KEY` import

### 2. Updated Documentation in `CLAUDE.md`

Added comprehensive Edge Functions authentication guidance:

**New section:**
- **Edge Functions Authentication** with client-side call pattern showing proper token usage
- Clear distinction between client-side calls (use JWT token) and Edge Function validation (service role)

**New common issue:**
- **Edge Function Connection Closed (ERR_CONNECTION_CLOSED)**: Documents this specific error and how to diagnose/fix it

## Best Practices

### ✅ DO: Use User JWT Token for Authenticated Edge Function Calls

```typescript
const { data: { session } } = await supabase.auth.getSession()
const token = session?.access_token

fetch(`${supabaseUrl}/functions/v1/my-function`, {
  headers: { 'Authorization': `Bearer ${token}` }
})
```

### ❌ DON'T: Use Anon Key for Authenticated Endpoints

```typescript
// WRONG - Only for public endpoints
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY
fetch(`${supabaseUrl}/functions/v1/my-function`, {
  headers: { 'Authorization': `Bearer ${supabaseAnonKey}` }
})
```

## When to Use Anon Key vs JWT Token

| Scenario | Use | Example |
|----------|-----|---------|
| **Public card viewing** | Anon Key | `get_public_card_content()` without authentication |
| **AI Assistant (authenticated users)** | JWT Token | TTS generation, chat completions |
| **Credit purchases** | JWT Token | Stripe checkout session creation |
| **Translation** | JWT Token | Card content translation |
| **Admin operations** | JWT Token | User management, batch oversight |

## Testing

After applying this fix:

1. **Test TTS Audio Generation:**
   - Open mobile AI Assistant
   - Send a text message
   - Click the play button on the response
   - ✅ Audio should generate and play successfully
   - ❌ Before fix: Connection closed error

2. **Verify in DevTools:**
   - Open Network tab
   - Filter for `generate-tts-audio`
   - Check request headers contain `Authorization: Bearer <jwt_token>`
   - Check response status is `200 OK`
   - Check response type is `audio/wav`

3. **Check Edge Function Logs:**
   ```bash
   npx supabase functions logs generate-tts-audio --follow
   ```
   - Should see successful TTS generation logs
   - No authentication errors

## Related Files

- `src/views/MobileClient/components/AIAssistant/composables/useChatCompletion.ts` - Fixed authentication
- `CLAUDE.md` - Updated documentation
- `supabase/functions/generate-tts-audio/index.ts` - Edge Function (no changes needed)

## Deployment

✅ **No deployment required** - This is a frontend-only fix.

The change affects only client-side JavaScript code. Users will get the fix automatically when they refresh the app after the frontend is deployed.

## Lessons Learned

1. **Always use JWT tokens for authenticated Edge Function calls** - Anon keys are for public endpoints only
2. **Follow established patterns** - The `getAIResponse` function already had the correct pattern, should have been used consistently
3. **Document authentication patterns** - Clear documentation prevents similar issues in the future
4. **ERR_CONNECTION_CLOSED often indicates authentication issues** - Check token validity first when debugging this error

## Status

✅ **Fix Complete** - Authentication corrected and documentation updated.

