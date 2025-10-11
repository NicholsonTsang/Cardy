# Deploy AI Assistant - Quick Guide

## ✅ Fixed Issue
Updated `get-openai-ephemeral-token/index.ts` to use Deno std@0.168.0 (was 0.177.0 which was causing download errors).

---

## 🚀 Deployment Options

### **Option 1: Deploy via Supabase CLI (Recommended)**

If you have Supabase CLI installed:

```bash
# Deploy the new chat-with-audio function
supabase functions deploy chat-with-audio

# Verify deployment
supabase functions list
```

### **Option 2: Deploy via Supabase Dashboard**

1. **Go to Supabase Dashboard**
   - Navigate to: https://supabase.com/dashboard
   - Select your project

2. **Navigate to Edge Functions**
   - Click "Edge Functions" in the left sidebar
   - Click "Create a new function" or "Deploy from local"

3. **Upload the Function**
   - Function name: `chat-with-audio`
   - Upload file: `supabase/functions/chat-with-audio/index.ts`
   - Or copy-paste the code from the file

4. **Set Secrets**
   - Go to "Manage secrets"
   - Add the following secrets:
     ```
     OPENAI_API_KEY=sk-your_key_here
     OPENAI_AUDIO_MODEL=gpt-4o-audio-preview
     OPENAI_TTS_VOICE=alloy
     OPENAI_AUDIO_FORMAT=wav
     ```

5. **Deploy**
   - Click "Deploy function"
   - Wait for deployment to complete

---

## 🧪 Testing After Deployment

### **Test Locally First**

```bash
# Start your dev server
npm run dev

# Navigate to a card with content
# Click "Ask AI Assistant"
# Try both text and voice input
```

### **Test Edge Function Directly**

```bash
# Get your Supabase URL and anon key from .env
curl -X POST 'https://your-project.supabase.co/functions/v1/chat-with-audio' \
  -H 'Authorization: Bearer YOUR_ANON_KEY' \
  -H 'Content-Type: application/json' \
  -d '{
    "messages": [
      {"role": "user", "content": "Hello"}
    ],
    "systemPrompt": "You are a helpful assistant.",
    "language": "en",
    "modalities": ["text"]
  }'
```

Expected response:
```json
{
  "success": true,
  "message": {
    "role": "assistant",
    "content": "Hello! How can I help you?",
    "audio": null
  }
}
```

---

## 📊 Monitor Deployment

### **Check Function Logs**

Via Dashboard:
1. Go to Edge Functions → chat-with-audio
2. Click "Logs" tab
3. Monitor for errors

### **Common Issues**

**Issue**: "OPENAI_API_KEY not configured"
- **Fix**: Set the secret in Dashboard → Edge Functions → Manage secrets

**Issue**: "OpenAI API error"
- **Fix**: Verify your OpenAI API key is valid and has credits
- Check: https://platform.openai.com/api-keys

**Issue**: "Model not found: gpt-4o-audio-preview"
- **Fix**: Ensure you have access to the audio preview model
- Check: https://platform.openai.com/docs/models

---

## 🔧 Alternative: Use Supabase Local Development

If you want to test locally with Supabase:

```bash
# Install Supabase CLI (if not installed)
# macOS
brew install supabase/tap/supabase

# Start local Supabase
supabase start

# Deploy function locally
supabase functions serve chat-with-audio

# Test locally
curl -X POST 'http://localhost:54321/functions/v1/chat-with-audio' \
  -H 'Authorization: Bearer YOUR_ANON_KEY' \
  -H 'Content-Type: application/json' \
  -d '{"messages": [{"role": "user", "content": "test"}], "systemPrompt": "test", "language": "en"}'
```

---

## 📝 Deployment Checklist

- [x] Fixed Deno import version issue
- [ ] Deploy `chat-with-audio` Edge Function
- [ ] Set `OPENAI_API_KEY` secret
- [ ] Set `OPENAI_AUDIO_MODEL` secret
- [ ] Set `OPENAI_TTS_VOICE` secret
- [ ] Set `OPENAI_AUDIO_FORMAT` secret
- [ ] Test function with curl
- [ ] Test in dev environment (`npm run dev`)
- [ ] Test text input
- [ ] Test voice input
- [ ] Test on mobile device
- [ ] Monitor logs for errors
- [ ] Check OpenAI API usage
- [ ] Deploy frontend to production

---

## 🎯 Quick Start for Manual Deployment

Since Supabase CLI isn't available, here's the fastest way:

1. **Copy the Edge Function code**
   - Open: `supabase/functions/chat-with-audio/index.ts`
   - Copy all the code

2. **Go to Supabase Dashboard**
   - https://supabase.com/dashboard
   - Select your project
   - Navigate to "Edge Functions"

3. **Create New Function**
   - Click "Create a new function"
   - Name: `chat-with-audio`
   - Paste the code
   - Click "Deploy"

4. **Set Secrets**
   - Click "Manage secrets"
   - Add your `OPENAI_API_KEY` and other secrets

5. **Test**
   - Use the test interface in the dashboard
   - Or test from your frontend

That's it! Your AI assistant should now be live! 🎉

---

## 📞 Need Help?

Check these resources:
- Edge Function logs in Supabase Dashboard
- OpenAI API status: https://status.openai.com
- Browser console for frontend errors
- Network tab to see API requests

**Remember**: Always test in development before deploying to production! 🛡️

