# Edge Functions Import Fix

## ✅ Issue Resolved

**Problem**: Deno standard library CDN (`https://deno.land/std@...`) was unreachable, causing import errors when deploying Edge Functions.

**Error Messages**:
```
Import 'https://deno.land/std@0.168.0/http/server.ts' failed: 
error sending request for url
```

## 🔧 Solution Applied

**Changed ALL Edge Functions to use JSR (new Deno registry)**:

### **Before (Old CDN)**:
```typescript
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
```

### **After (JSR - New Standard)**:
```typescript
import { serve } from 'jsr:@std/http@1/server'
```

## 📋 Files Updated

All Edge Functions have been updated:

1. ✅ `supabase/functions/chat-with-audio/index.ts` (NEW)
2. ✅ `supabase/functions/create-checkout-session/index.ts`
3. ✅ `supabase/functions/handle-checkout-success/index.ts`
4. ✅ `supabase/functions/get-openai-ephemeral-token/index.ts`
5. ✅ `supabase/functions/openai-realtime-proxy/index.ts`

## 🚀 Ready to Deploy

Now you can deploy the functions without import errors!

### **Option A: Via Dashboard** (Recommended - No CLI needed)

1. **Go to**: https://supabase.com/dashboard/project/mzgusshseqxrdrkvamrg
2. **Click**: "Edge Functions" in sidebar
3. **For each function, click** "Create a new function" or edit existing:
   - Copy code from `supabase/functions/[function-name]/index.ts`
   - Paste in dashboard editor
   - Click "Deploy"

4. **Set secrets** (Dashboard → Edge Functions → Manage secrets):
   ```
   OPENAI_API_KEY=sk-your_key_here
   OPENAI_AUDIO_MODEL=gpt-4o-audio-preview
   OPENAI_TTS_VOICE=alloy
   OPENAI_AUDIO_FORMAT=wav
   ```

### **Option B: Install Supabase CLI**

```bash
# macOS
brew install supabase/tap/supabase

# Login and link
supabase login
supabase link --project-ref mzgusshseqxrdrkvamrg

# Deploy all functions
supabase functions deploy chat-with-audio
supabase functions deploy create-checkout-session
supabase functions deploy handle-checkout-success
supabase functions deploy get-openai-ephemeral-token
supabase functions deploy openai-realtime-proxy

# Set secrets
supabase secrets set OPENAI_API_KEY=sk-...
supabase secrets set OPENAI_AUDIO_MODEL=gpt-4o-audio-preview
```

## 📊 What Changed?

### **JSR (JavaScript Registry)**
- Modern Deno package registry
- More reliable than old CDN
- Better caching
- Faster downloads
- Standard for new Deno projects

### **Import Format**
- `jsr:@std/http@1/server` - JSR import
  - `@std` - Standard library namespace
  - `http` - Module name
  - `@1` - Major version
  - `/server` - Specific export

### **Benefits**
- ✅ More reliable (no CDN timeouts)
- ✅ Faster deployment
- ✅ Future-proof (Deno's new standard)
- ✅ Better error messages
- ✅ Automatic caching

## 🧪 Testing After Update

### **Test Locally** (if you have Supabase CLI):
```bash
# Start local Supabase
supabase start

# Test function
supabase functions serve chat-with-audio

# In another terminal, test with curl
curl -X POST 'http://localhost:54321/functions/v1/chat-with-audio' \
  -H 'Authorization: Bearer [ANON_KEY]' \
  -H 'Content-Type: application/json' \
  -d '{
    "messages": [],
    "systemPrompt": "You are helpful",
    "language": "en"
  }'
```

### **Test in Browser**:
1. Deploy functions via Dashboard
2. Set secrets
3. `npm run dev`
4. Navigate to card with content
5. Click "Ask AI Assistant"
6. Try text input: "Hello"
7. Should work! ✅

## 🔍 Verify Import Changes

Check that all functions use JSR imports:

```bash
# Should show jsr:@std/http@1/server for all
grep -r "import.*serve" supabase/functions/*/index.ts
```

Expected output:
```
chat-with-audio/index.ts:import { serve } from 'jsr:@std/http@1/server'
create-checkout-session/index.ts:import { serve } from 'jsr:@std/http@1/server'
...
```

## 📝 Summary

**Before**: 🔴 Import errors, deployment failures
**After**: ✅ Clean imports, ready to deploy

**Next Steps**:
1. Deploy via Supabase Dashboard (easiest)
2. Set OpenAI API key in secrets
3. Test the AI assistant
4. Enjoy! 🎉

---

## 🐛 If You Still Get Errors

### **Error**: "jsr: not found"
**Solution**: Make sure you're using Supabase CLI v1.27.0 or newer
```bash
supabase --version
# If old, upgrade:
brew upgrade supabase
```

### **Error**: "Module not found: jsr:@std/http@1/server"
**Solution**: This shouldn't happen with JSR, but if it does:
- Clear Deno cache: `deno cache --reload`
- Redeploy function

### **Error**: Still getting CORS
**Solution**: Function not deployed yet
- Verify in Dashboard → Edge Functions
- Check function status is "Active"
- Wait 10-15 seconds after deployment

---

## ✨ Conclusion

All Edge Functions are now using modern JSR imports and ready for deployment! 🚀

The `chat-with-audio` function is ready to power your AI assistant with native audio support!

