# Enable Gemini API for Your Service Account

## Error: "Request had insufficient authentication scopes"

This means your service account needs:
1. The Generative Language API enabled
2. Proper IAM permissions

## Quick Fix (Run These Commands)

### Step 1: Enable the API

```bash
gcloud services enable generativelanguage.googleapis.com --project=cardstudio-474313
```

### Step 2: Grant Permissions to Service Account

```bash
gcloud projects add-iam-policy-binding cardstudio-474313 \
    --member="serviceAccount:cardstudio-474313@appspot.gserviceaccount.com" \
    --role="roles/aiplatform.user"
```

### Or Use the Script

```bash
cd backend-server
./enable-gemini-api.sh
```

## Manual Setup (via Console)

### 1. Enable Generative Language API

1. Go to: https://console.cloud.google.com/apis/library/generativelanguage.googleapis.com?project=cardstudio-474313
2. Click **"ENABLE"**

### 2. Grant Permissions

1. Go to: https://console.cloud.google.com/iam-admin/iam?project=cardstudio-474313
2. Find: `cardstudio-474313@appspot.gserviceaccount.com`
3. Click **"Edit"** (pencil icon)
4. Click **"ADD ANOTHER ROLE"**
5. Select: **"AI Platform User"** or **"Vertex AI User"**
6. Click **"SAVE"**

## Verify Setup

After enabling the API and granting permissions:

```bash
# Restart backend
cd backend-server
npm run dev

# Try translation again - should work now!
```

## What Changed

**Before:**
- Service account had no API access
- No permissions to call Gemini API

**After:**
- ✅ Generative Language API enabled
- ✅ Service account has `roles/aiplatform.user` permission
- ✅ OAuth2 scopes include `generative-language`
- ✅ Translations will work!

## Troubleshooting

### Error persists after enabling API?
- Wait 1-2 minutes for changes to propagate
- Restart the backend
- Clear token cache by restarting

### "Permission denied" error?
- Make sure you have Owner/Editor role on the project
- Make sure you're logged in with correct Google account:
  ```bash
  gcloud auth list
  gcloud config set project cardstudio-474313
  ```

### Don't have gcloud installed?
- Install: https://cloud.google.com/sdk/docs/install
- Or use the manual console method above

