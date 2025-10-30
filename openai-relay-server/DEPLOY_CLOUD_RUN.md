# Deploy OpenAI Relay Server to Google Cloud Run

**Prerequisites:** ✅ You have `gcloud` CLI installed and authenticated

---

## 🚀 Quick Deploy (5 Steps)

### Step 1: Set Your Project Variables

```bash
# Navigate to relay server directory
cd openai-relay-server

# Set your project ID (replace with your actual project ID)
export PROJECT_ID="your-project-id"
export REGION="us-central1"  # or your preferred region
export SERVICE_NAME="openai-relay"

# Verify your current project
gcloud config get-value project

# If needed, set the project
gcloud config set project $PROJECT_ID
```

### Step 2: Enable Required APIs

```bash
# Enable Cloud Run API
gcloud services enable run.googleapis.com

# Enable Container Registry API
gcloud services enable containerregistry.googleapis.com

# Enable Artifact Registry API (recommended over Container Registry)
gcloud services enable artifactregistry.googleapis.com
```

### Step 3: Build and Push Container Image

**Option A: Using Cloud Build (Recommended)**

```bash
# Build and push image using Cloud Build (serverless, no Docker needed locally)
gcloud builds submit --tag gcr.io/$PROJECT_ID/$SERVICE_NAME

# This will:
# 1. Upload your code to Google Cloud
# 2. Build the Docker image in the cloud
# 3. Push to Container Registry
# 4. Show you the build logs
```

**Option B: Using Local Docker**

```bash
# Build locally
docker build -t gcr.io/$PROJECT_ID/$SERVICE_NAME .

# Configure Docker to use gcloud as credential helper
gcloud auth configure-docker

# Push to Container Registry
docker push gcr.io/$PROJECT_ID/$SERVICE_NAME
```

### Step 4: Deploy to Cloud Run

```bash
# Deploy the service
gcloud run deploy $SERVICE_NAME \
  --image gcr.io/$PROJECT_ID/$SERVICE_NAME \
  --platform managed \
  --region $REGION \
  --allow-unauthenticated \
  --port 8080 \
  --memory 512Mi \
  --cpu 1 \
  --max-instances 10 \
  --set-env-vars "NODE_ENV=production" \
  --set-env-vars "ALLOWED_ORIGINS=https://cardstudio.org,https://www.cardstudio.org"

# You'll be prompted to enter your OPENAI_API_KEY
# Or set it with the command:
gcloud run services update $SERVICE_NAME \
  --region $REGION \
  --update-secrets OPENAI_API_KEY=openai-api-key:latest
```

**Alternative: Set Environment Variables Directly**

```bash
# Deploy with all environment variables in one command
gcloud run deploy $SERVICE_NAME \
  --image gcr.io/$PROJECT_ID/$SERVICE_NAME \
  --platform managed \
  --region $REGION \
  --allow-unauthenticated \
  --port 8080 \
  --memory 512Mi \
  --cpu 1 \
  --max-instances 10 \
  --set-env-vars "NODE_ENV=production,ALLOWED_ORIGINS=https://cardstudio.org,https://www.cardstudio.org,OPENAI_API_KEY=sk-your-key-here"
```

### Step 5: Get Your Service URL

```bash
# Get the deployed URL
SERVICE_URL=$(gcloud run services describe $SERVICE_NAME \
  --region $REGION \
  --format 'value(status.url)')

echo "Service deployed at: $SERVICE_URL"

# Test the health endpoint
curl $SERVICE_URL/health

# Should return: {"status":"healthy",...}
```

**Example Output:**
```
Service deployed at: https://openai-relay-abc123-uc.a.run.app
```

---

## 🔒 Secure Configuration with Secret Manager

### Option 1: Using Secret Manager (Recommended for Production)

```bash
# Create a secret for your OpenAI API key
echo -n "sk-your-actual-key-here" | \
  gcloud secrets create openai-api-key \
  --data-file=- \
  --replication-policy="automatic"

# Grant Cloud Run access to the secret
gcloud secrets add-iam-policy-binding openai-api-key \
  --member="serviceAccount:${PROJECT_ID}@appspot.gserviceaccount.com" \
  --role="roles/secretmanager.secretAccessor"

# Deploy with secret reference
gcloud run deploy $SERVICE_NAME \
  --image gcr.io/$PROJECT_ID/$SERVICE_NAME \
  --platform managed \
  --region $REGION \
  --allow-unauthenticated \
  --port 8080 \
  --memory 512Mi \
  --cpu 1 \
  --update-secrets OPENAI_API_KEY=openai-api-key:latest \
  --set-env-vars "NODE_ENV=production,ALLOWED_ORIGINS=https://cardstudio.org"
```

### Option 2: Using Environment Variables Directly

```bash
# Set environment variables (less secure but simpler)
gcloud run services update $SERVICE_NAME \
  --region $REGION \
  --set-env-vars "OPENAI_API_KEY=sk-your-key-here,ALLOWED_ORIGINS=https://cardstudio.org"
```

---

## 🌐 Custom Domain Setup

### Map Custom Domain to Cloud Run

```bash
# Map your domain (e.g., relay.cardstudio.org)
gcloud run domain-mappings create \
  --service $SERVICE_NAME \
  --domain relay.cardstudio.org \
  --region $REGION

# This will output DNS records to add to your domain:
# CNAME: relay.cardstudio.org → ghs.googlehosted.com
```

### Add DNS Records

1. Go to your DNS provider (Cloudflare, etc.)
2. Add the CNAME record shown by the command above
3. Wait 5-10 minutes for DNS propagation

### Verify Custom Domain

```bash
# Check domain mapping status
gcloud run domain-mappings describe \
  --domain relay.cardstudio.org \
  --region $REGION

# Test with custom domain
curl https://relay.cardstudio.org/health
```

---

## 📊 Configuration Options

### Memory and CPU Options

```bash
# Minimum (saves cost)
--memory 256Mi --cpu 1

# Recommended (good performance)
--memory 512Mi --cpu 1

# High traffic (better performance)
--memory 1Gi --cpu 2
```

### Scaling Options

```bash
# Auto-scaling settings
--min-instances 0 \          # Scale to zero when idle (saves cost)
--max-instances 10 \         # Max 10 instances
--concurrency 80 \           # Max 80 concurrent requests per instance
--cpu-throttling \           # Throttle CPU when idle (saves cost)
--timeout 300                # 5 minute timeout
```

### Full Deployment Command (Production-Ready)

```bash
gcloud run deploy $SERVICE_NAME \
  --image gcr.io/$PROJECT_ID/$SERVICE_NAME \
  --platform managed \
  --region $REGION \
  --allow-unauthenticated \
  --port 8080 \
  --memory 512Mi \
  --cpu 1 \
  --min-instances 0 \
  --max-instances 10 \
  --concurrency 80 \
  --cpu-throttling \
  --timeout 300 \
  --update-secrets OPENAI_API_KEY=openai-api-key:latest \
  --set-env-vars "NODE_ENV=production,ALLOWED_ORIGINS=https://cardstudio.org,https://www.cardstudio.org"
```

---

## 🔄 Update Deployment

### Update Code

```bash
# After making code changes
cd openai-relay-server

# Rebuild and redeploy
gcloud builds submit --tag gcr.io/$PROJECT_ID/$SERVICE_NAME

gcloud run deploy $SERVICE_NAME \
  --image gcr.io/$PROJECT_ID/$SERVICE_NAME \
  --region $REGION

# Or one command:
gcloud builds submit --tag gcr.io/$PROJECT_ID/$SERVICE_NAME && \
  gcloud run deploy $SERVICE_NAME \
    --image gcr.io/$PROJECT_ID/$SERVICE_NAME \
    --region $REGION
```

### Update Environment Variables

```bash
# Update CORS origins
gcloud run services update $SERVICE_NAME \
  --region $REGION \
  --set-env-vars "ALLOWED_ORIGINS=https://cardstudio.org,https://admin.cardstudio.org"

# Update API key
gcloud run services update $SERVICE_NAME \
  --region $REGION \
  --update-secrets OPENAI_API_KEY=openai-api-key:latest
```

---

## 📈 Monitoring & Logs

### View Logs

```bash
# Stream logs in real-time
gcloud run services logs tail $SERVICE_NAME --region $REGION

# View recent logs
gcloud run services logs read $SERVICE_NAME \
  --region $REGION \
  --limit 50

# Filter logs
gcloud run services logs read $SERVICE_NAME \
  --region $REGION \
  --filter="severity>=ERROR"
```

### Cloud Console Monitoring

Visit: https://console.cloud.google.com/run

You can see:
- Request count
- Request latency
- Error rate
- Memory usage
- CPU usage
- Container instance count

### Set Up Alerts

```bash
# Create uptime check
gcloud monitoring uptime create \
  openai-relay-uptime \
  --resource-type=uptime-url \
  --check-interval=5m \
  --timeout=10s \
  --display-name="OpenAI Relay Health Check" \
  --http-check="https://relay.cardstudio.org/health"
```

---

## 💰 Cost Optimization

### Cloud Run Pricing

**Free Tier (per month):**
- 2 million requests
- 360,000 GB-seconds
- 180,000 vCPU-seconds
- 1 GB network egress

**After free tier:**
- Requests: $0.40 per million
- Memory: $0.0000025 per GB-second
- CPU: $0.00001 per vCPU-second

### Optimization Tips

```bash
# 1. Scale to zero when idle
--min-instances 0

# 2. Enable CPU throttling
--cpu-throttling

# 3. Right-size resources
--memory 256Mi --cpu 1  # Start small, scale up if needed

# 4. Set reasonable timeout
--timeout 60  # Don't need 5 minutes for relay

# 5. Limit max instances
--max-instances 5  # Prevent runaway costs
```

---

## 🧪 Testing

### Local Test Before Deploy

```bash
# Test locally with Docker
docker build -t openai-relay-test .

docker run -p 8080:8080 \
  -e OPENAI_API_KEY="sk-your-key" \
  -e ALLOWED_ORIGINS="*" \
  openai-relay-test

# Test
curl http://localhost:8080/health
```

### Production Test

```bash
# Get service URL
SERVICE_URL=$(gcloud run services describe $SERVICE_NAME \
  --region $REGION \
  --format 'value(status.url)')

# Test health
curl $SERVICE_URL/health

# Test from frontend
# Update .env.production:
# VITE_OPENAI_RELAY_URL=https://openai-relay-abc123-uc.a.run.app
```

---

## 🚨 Troubleshooting

### Issue: Build Fails

```bash
# Check build logs
gcloud builds list --limit 5

# Get detailed build log
gcloud builds log <BUILD_ID>
```

### Issue: Service Won't Start

```bash
# Check service status
gcloud run services describe $SERVICE_NAME --region $REGION

# View logs
gcloud run services logs read $SERVICE_NAME --region $REGION --limit 50
```

### Issue: CORS Errors

```bash
# Update CORS origins
gcloud run services update $SERVICE_NAME \
  --region $REGION \
  --set-env-vars "ALLOWED_ORIGINS=https://cardstudio.org"

# Verify environment variables
gcloud run services describe $SERVICE_NAME \
  --region $REGION \
  --format="value(spec.template.spec.containers[0].env)"
```

### Issue: High Latency

```bash
# Check if scaled to zero (cold starts)
# Solution: Set min-instances
gcloud run services update $SERVICE_NAME \
  --region $REGION \
  --min-instances 1

# Check region
# Solution: Deploy closer to users
--region us-west1  # West Coast US
--region asia-northeast1  # Tokyo
--region europe-west1  # Belgium
```

---

## 🔐 Security Best Practices

### 1. Use Secret Manager

```bash
# Never put API keys in environment variables directly
# Always use Secret Manager
--update-secrets OPENAI_API_KEY=openai-api-key:latest
```

### 2. Restrict CORS

```bash
# Never use * in production
# Bad:  ALLOWED_ORIGINS=*
# Good: ALLOWED_ORIGINS=https://cardstudio.org
```

### 3. Use Custom Domain with SSL

```bash
# Cloud Run provides automatic SSL for custom domains
gcloud run domain-mappings create \
  --service $SERVICE_NAME \
  --domain relay.cardstudio.org
```

### 4. Set Up IAM

```bash
# If you want to restrict access (not needed for public relay)
gcloud run services add-iam-policy-binding $SERVICE_NAME \
  --region $REGION \
  --member="allUsers" \
  --role="roles/run.invoker"
```

---

## 📝 Complete Deployment Script

Save this as `deploy-to-cloud-run.sh`:

```bash
#!/bin/bash

# Configuration
PROJECT_ID="your-project-id"
REGION="us-central1"
SERVICE_NAME="openai-relay"
OPENAI_API_KEY="sk-your-key-here"
ALLOWED_ORIGINS="https://cardstudio.org,https://www.cardstudio.org"

# Set project
gcloud config set project $PROJECT_ID

# Enable APIs
echo "Enabling required APIs..."
gcloud services enable run.googleapis.com
gcloud services enable containerregistry.googleapis.com

# Build and push image
echo "Building container image..."
gcloud builds submit --tag gcr.io/$PROJECT_ID/$SERVICE_NAME

# Deploy to Cloud Run
echo "Deploying to Cloud Run..."
gcloud run deploy $SERVICE_NAME \
  --image gcr.io/$PROJECT_ID/$SERVICE_NAME \
  --platform managed \
  --region $REGION \
  --allow-unauthenticated \
  --port 8080 \
  --memory 512Mi \
  --cpu 1 \
  --min-instances 0 \
  --max-instances 10 \
  --set-env-vars "NODE_ENV=production,ALLOWED_ORIGINS=$ALLOWED_ORIGINS,OPENAI_API_KEY=$OPENAI_API_KEY"

# Get service URL
SERVICE_URL=$(gcloud run services describe $SERVICE_NAME \
  --region $REGION \
  --format 'value(status.url)')

echo ""
echo "✅ Deployment complete!"
echo ""
echo "Service URL: $SERVICE_URL"
echo ""
echo "Test it:"
echo "curl $SERVICE_URL/health"
echo ""
echo "Update your frontend .env.production:"
echo "VITE_OPENAI_RELAY_URL=$SERVICE_URL"
```

**Run it:**
```bash
chmod +x deploy-to-cloud-run.sh
./deploy-to-cloud-run.sh
```

---

## 🎯 Quick Reference Commands

```bash
# Deploy
gcloud run deploy $SERVICE_NAME --image gcr.io/$PROJECT_ID/$SERVICE_NAME --region $REGION

# Update
gcloud builds submit --tag gcr.io/$PROJECT_ID/$SERVICE_NAME && \
  gcloud run deploy $SERVICE_NAME --image gcr.io/$PROJECT_ID/$SERVICE_NAME --region $REGION

# Logs
gcloud run services logs tail $SERVICE_NAME --region $REGION

# Describe
gcloud run services describe $SERVICE_NAME --region $REGION

# Delete
gcloud run services delete $SERVICE_NAME --region $REGION

# List services
gcloud run services list
```

---

## ✅ Deployment Checklist

- [ ] gcloud CLI installed and authenticated
- [ ] Project ID set correctly
- [ ] Required APIs enabled
- [ ] OPENAI_API_KEY ready
- [ ] ALLOWED_ORIGINS configured for your domain
- [ ] Code built and pushed to Container Registry
- [ ] Service deployed to Cloud Run
- [ ] Health endpoint responding (curl /health)
- [ ] Custom domain mapped (optional)
- [ ] Frontend updated with new VITE_OPENAI_RELAY_URL
- [ ] Tested end-to-end with frontend
- [ ] Monitoring/alerts set up

---

## 🆘 Need Help?

- **Cloud Run Docs**: https://cloud.google.com/run/docs
- **gcloud CLI Reference**: https://cloud.google.com/sdk/gcloud/reference/run
- **Troubleshooting**: Check logs with `gcloud run services logs`

---

**Your relay server will be:**
- ✅ Fully managed (no servers to maintain)
- ✅ Auto-scaling (0 to millions of requests)
- ✅ HTTPS by default
- ✅ Global CDN
- ✅ Pay only for what you use

**Estimated cost:** ~$0-5/month for typical usage (within free tier)

---

*Ready to deploy? Run the commands above!* 🚀

