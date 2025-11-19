# Google Gemini API Authentication Setup

## Problem

The API key format `AQ.Ab8RN6KUo5-tYzvnwfBG6eQz-gGU3830cQll93eFKKedpQJs0g` is not a valid Google AI API key. This causes the error:

```
API keys are not supported by this API. Expected OAuth2 access token
```

## Solution: Get a Proper Google AI API Key

### Option 1: API Key (Recommended for Development)

1. **Go to Google AI Studio:**
   https://aistudio.google.com/app/apikey

2. **Click "Get API Key"**

3. **Create or Select a Google Cloud Project**

4. **Copy the API Key** (starts with `AIza...`)

5. **Add to `.env`:**
   ```bash
   GEMINI_API_KEY=AIzaSyD...your_actual_key_here
   ```

### Option 2: OAuth2 with Service Account (Production)

1. **Create Service Account:**
   ```bash
   gcloud iam service-accounts create gemini-translator \
       --display-name="Gemini Translation Service"
   ```

2. **Grant Permissions:**
   ```bash
   gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
       --member="serviceAccount:gemini-translator@YOUR_PROJECT_ID.iam.gserviceaccount.com" \
       --role="roles/aiplatform.user"
   ```

3. **Create Service Account Key:**
   ```bash
   gcloud iam service-accounts keys create gemini-sa-key.json \
       --iam-account=gemini-translator@YOUR_PROJECT_ID.iam.gserviceaccount.com
   ```

4. **Set Environment Variable:**
   ```bash
   # In .env
   GOOGLE_APPLICATION_CREDENTIALS=/path/to/gemini-sa-key.json
   ```

### Option 3: Application Default Credentials (Local Development)

```bash
# Authenticate with your Google account
gcloud auth application-default login

# Select the project
gcloud config set project YOUR_PROJECT_ID
```

## How the Code Works

The `GeminiClient` class automatically handles authentication:

1. **Tries API Key first** (simplest, fastest)
2. **Falls back to OAuth2** if API key fails
3. **Caches OAuth tokens** for 55 minutes
4. **Auto-refreshes** tokens when expired

```typescript
// Usage is the same regardless of auth method
const data = await geminiClient.generateContent(prompt);
```

## Verifying Your Setup

### Check API Key Format

✅ **Valid:** `AIzaSyDZZBpL4Y...` (starts with `AIza`)  
❌ **Invalid:** `AQ.Ab8RN6KUo5...` (wrong format)

### Test the API

```bash
curl "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-lite:generateContent?key=YOUR_API_KEY" \
  -H 'Content-Type: application/json' \
  -d '{"contents":[{"parts":[{"text":"Hello"}]}]}'
```

If successful, you'll see a JSON response with generated content.

## Quick Start

1. **Get API Key** from https://aistudio.google.com/app/apikey

2. **Update `.env`:**
   ```bash
   GEMINI_API_KEY=AIzaSyD...your_key_here
   ```

3. **Restart Backend:**
   ```bash
   cd backend-server
   npm run dev
   ```

4. **Test Translation** - Should work immediately!

## Troubleshooting

### Error: "API keys are not supported"
- Your key format is wrong
- Get a proper key from Google AI Studio

### Error: "Invalid API key"
- Key is expired or incorrect
- Generate a new key

### Error: "Quota exceeded"
- You've hit the free tier limit
- Upgrade to paid plan or wait for quota reset

### Error: "Permission denied"
- Service account lacks permissions
- Grant `roles/aiplatform.user` role

## Security Best Practices

✅ **Do:**
- Use environment variables for keys
- Use OAuth2 for production
- Rotate keys regularly
- Restrict API key to specific IPs

❌ **Don't:**
- Commit API keys to git
- Share keys publicly
- Use development keys in production
- Hardcode keys in source code

## Files Changed

1. `backend-server/src/services/gemini-client.ts` - New OAuth2 client
2. `backend-server/src/services/translation-job-processor.ts` - Uses new client
3. `backend-server/.env` - Update with proper API key
4. `backend-server/package.json` - Added googleapis dependencies

## Next Steps

1. Get a proper API key from Google AI Studio
2. Update `.env` with the new key
3. Restart the backend
4. Test translations - should work perfectly!

