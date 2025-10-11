# Quick Setup Steps - AI Assistant

## 🚨 Current Issue: Edge Function Not Deployed

The CORS error you're seeing means the `chat-with-audio` Edge Function hasn't been deployed to Supabase yet.

---

## 🔧 Option 1: Deploy via Supabase Dashboard (5 minutes)

### **Step 1: Open Edge Function Code**
Open this file: `supabase/functions/chat-with-audio/index.ts`

### **Step 2: Go to Supabase Dashboard**
1. Visit: https://supabase.com/dashboard
2. Select your project: `mzgusshseqxrdrkvamrg`
3. Click "Edge Functions" in the left sidebar

### **Step 3: Create New Function**
1. Click "Create a new function"
2. Function name: `chat-with-audio`
3. Copy ALL the code from `supabase/functions/chat-with-audio/index.ts`
4. Paste it into the editor
5. Click "Deploy function"

### **Step 4: Set Secrets**
1. In Edge Functions page, click "Manage secrets"
2. Add these secrets:
   ```
   OPENAI_API_KEY=sk-your_actual_key_here
   OPENAI_AUDIO_MODEL=gpt-4o-audio-preview
   OPENAI_TTS_VOICE=alloy
   OPENAI_AUDIO_FORMAT=wav
   ```
3. Save

### **Step 5: Test**
1. Refresh your browser (`http://localhost:5173`)
2. Navigate to a card
3. Click "Ask AI Assistant"
4. Try typing "hello"
5. Should work! ✅

---

## 🔧 Option 2: Install Supabase CLI (10 minutes)

### **macOS (Homebrew)**
```bash
brew install supabase/tap/supabase

# Verify installation
supabase --version

# Login
supabase login

# Link to your project
supabase link --project-ref mzgusshseqxrdrkvamrg

# Deploy function
supabase functions deploy chat-with-audio

# Set secrets
supabase secrets set OPENAI_API_KEY=sk-your_key_here
supabase secrets set OPENAI_AUDIO_MODEL=gpt-4o-audio-preview
supabase secrets set OPENAI_TTS_VOICE=alloy
supabase secrets set OPENAI_AUDIO_FORMAT=wav
```

### **Windows/Linux**
See: https://supabase.com/docs/guides/cli/getting-started

---

## 🔧 Option 3: Use Local Supabase (Testing Only)

If you just want to test the UI without deploying:

### **Install Supabase CLI first** (see Option 2)

Then:
```bash
# Start local Supabase
supabase start

# This will give you local URLs
# Update your .env to use local Supabase URL temporarily

# Deploy function locally
supabase functions serve chat-with-audio --env-file .env
```

---

## 🎯 Recommended: Option 1 (Dashboard)

**Why**: Fastest, no CLI installation needed, works immediately.

**Steps**:
1. Copy code from `supabase/functions/chat-with-audio/index.ts`
2. Paste in Supabase Dashboard → Edge Functions
3. Set your OpenAI API key in secrets
4. Test!

---

## 📋 Troubleshooting

### **Still getting CORS error after deployment?**

**Check 1**: Function deployed successfully?
- Go to Dashboard → Edge Functions
- Verify `chat-with-audio` is listed and status is "Active"

**Check 2**: Secrets set correctly?
- Go to Dashboard → Edge Functions → Manage secrets
- Verify `OPENAI_API_KEY` is set

**Check 3**: Test the function directly**
```bash
curl -X POST 'https://mzgusshseqxrdrkvamrg.supabase.co/functions/v1/chat-with-audio' \
  -H 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im16Z3Vzc2hzZXF4cmRya3ZhbXJnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDk4OTI0MTYsImV4cCI6MjA2NTQ2ODQxNn0.PktNuHIR0RjCoTsTkmJYx-Zn7iODyFUzfbg9A2X5wVo' \
  -H 'Content-Type: application/json' \
  -d '{
    "messages": [],
    "systemPrompt": "You are a test assistant.",
    "language": "en",
    "modalities": ["text"]
  }'
```

Expected: JSON response with success message
If you get: CORS error → Function not deployed
If you get: API key error → Set secrets

---

## ⚡ Quick Copy-Paste Checklist

**Before testing, you MUST:**
- [ ] Deploy `chat-with-audio` function to Supabase
- [ ] Set `OPENAI_API_KEY` secret
- [ ] Wait 10 seconds for deployment
- [ ] Refresh browser
- [ ] Test again

**The UI code is ready, but the backend function needs to be deployed first!**

---

## 💡 Why This Error?

The frontend is trying to call:
```
https://mzgusshseqxrdrkvamrg.supabase.co/functions/v1/chat-with-audio
```

But this endpoint doesn't exist yet because you haven't deployed the Edge Function.

**Solution**: Deploy the function (Option 1 is easiest!)

---

## 📞 Need Help?

1. **Check if function is deployed**: Dashboard → Edge Functions → Look for `chat-with-audio`
2. **Check function logs**: Click on the function → View logs
3. **Check your OpenAI API key**: https://platform.openai.com/api-keys
4. **Verify key has credits**: https://platform.openai.com/usage

**Once deployed, everything will work!** 🎉

