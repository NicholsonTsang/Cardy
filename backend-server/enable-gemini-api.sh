#!/bin/bash

echo "Enabling Generative Language API for FunTell project (cardstudio-474313)..."

# Enable the Generative Language API
gcloud services enable generativelanguage.googleapis.com --project=cardstudio-474313

# Grant the service account necessary permissions
echo "Granting permissions to service account..."
gcloud projects add-iam-policy-binding cardstudio-474313 \
    --member="serviceAccount:cardstudio-474313@appspot.gserviceaccount.com" \
    --role="roles/aiplatform.user"

echo "Done! Service account now has access to Gemini API."
