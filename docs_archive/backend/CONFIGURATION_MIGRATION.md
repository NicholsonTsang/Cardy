# Configuration Migration: Hardcoded Values → Environment Variables

**Date:** November 8, 2025  
**Status:** ✅ Complete

## Overview

All hardcoded configuration values in the backend server have been migrated to environment variables. This allows for flexible configuration across different environments (development, staging, production) without code changes.

---

## Changes Made

### 1. Updated `.env.example` ✅

Added comprehensive environment variable documentation with sensible defaults:

#### New Variables

**OpenAI Translation Configuration:**
```bash
OPENAI_TRANSLATION_MODEL=gpt-4.1-nano-2025-04-14
OPENAI_TRANSLATION_MAX_TOKENS=16000
OPENAI_TRANSLATION_TIMEOUT_MS=120000
OPENAI_TRANSLATION_TEMPERATURE=0.3
OPENAI_TRANSLATION_CONTEXT_WINDOW=128000
```

**Translation Job Processor Configuration:**
```bash
TRANSLATION_JOB_POLLING_INTERVAL_MS=5000
TRANSLATION_JOB_MAX_CONCURRENT_JOBS=3
TRANSLATION_JOB_MAX_CONCURRENT_LANGUAGES=3
TRANSLATION_JOB_BATCH_SIZE=10
```

### 2. Updated `translation-job-processor.ts` ✅

**Before:**
```typescript
const DEFAULT_CONFIG: JobProcessorConfig = {
  pollingInterval: 5000, // 5 seconds
  maxConcurrentJobs: 3,
  batchSize: 10,
  maxConcurrentLanguages: 3,
};
```

**After:**
```typescript
const DEFAULT_CONFIG: JobProcessorConfig = {
  pollingInterval: parseInt(process.env.TRANSLATION_JOB_POLLING_INTERVAL_MS || '5000', 10),
  maxConcurrentJobs: parseInt(process.env.TRANSLATION_JOB_MAX_CONCURRENT_JOBS || '3', 10),
  batchSize: parseInt(process.env.TRANSLATION_JOB_BATCH_SIZE || '10', 10),
  maxConcurrentLanguages: parseInt(process.env.TRANSLATION_JOB_MAX_CONCURRENT_LANGUAGES || '3', 10),
};
```

### 3. Updated `translation.routes.ts` ✅

**Before:**
```typescript
const MODEL_CONTEXT_WINDOW = 128000; // hardcoded
temperature: 0.3, // hardcoded
```

**After:**
```typescript
const MODEL_CONTEXT_WINDOW = parseInt(process.env.OPENAI_TRANSLATION_CONTEXT_WINDOW || '128000', 10);
temperature: parseFloat(process.env.OPENAI_TRANSLATION_TEMPERATURE || '0.3'),
```

**Already Using Environment Variables:**
- `OPENAI_TRANSLATION_MODEL`
- `OPENAI_TRANSLATION_MAX_TOKENS`
- `OPENAI_TRANSLATION_TIMEOUT_MS`

### 4. Created `ENVIRONMENT_VARIABLES.md` ✅

Comprehensive documentation covering:
- All environment variables with descriptions
- Default values and recommendations
- Environment-specific configurations
- Troubleshooting guide
- Monitoring recommendations
- Security best practices

---

## Benefits

### 1. **Flexibility** 🎛️
Different configurations for different environments without code changes:
```bash
# Development: Lower concurrency for stability
TRANSLATION_JOB_MAX_CONCURRENT_JOBS=2

# Production: Higher concurrency for throughput
TRANSLATION_JOB_MAX_CONCURRENT_JOBS=5
```

### 2. **Easy Tuning** ⚙️
Adjust performance parameters without redeploying code:
```bash
# Increase throughput during peak hours
TRANSLATION_JOB_POLLING_INTERVAL_MS=2000

# Reduce API load during off-peak
TRANSLATION_JOB_POLLING_INTERVAL_MS=10000
```

### 3. **Better Testing** 🧪
Test with different configurations easily:
```bash
# Test with conservative settings
TRANSLATION_JOB_MAX_CONCURRENT_LANGUAGES=1
TRANSLATION_JOB_BATCH_SIZE=5

# Test with aggressive settings
TRANSLATION_JOB_MAX_CONCURRENT_LANGUAGES=5
TRANSLATION_JOB_BATCH_SIZE=20
```

### 4. **Cloud Run Integration** ☁️
Google Cloud Run environment variables can be updated instantly:
```bash
gcloud run services update backend \
  --set-env-vars="TRANSLATION_JOB_MAX_CONCURRENT_JOBS=5"
```

### 5. **Cost Optimization** 💰
Adjust OpenAI API usage based on budget:
```bash
# Lower cost configuration
TRANSLATION_JOB_MAX_CONCURRENT_LANGUAGES=2
OPENAI_TRANSLATION_MAX_TOKENS=8000
```

---

## Migration Guide

### For Existing Deployments

1. **Update `.env` files:**
```bash
# Copy new variables from .env.example
cp .env.example .env.new
# Add your existing secrets to .env.new
# Rename when ready
mv .env.new .env
```

2. **Update Cloud Run environment variables:**
```bash
# Update via Google Cloud Console
# OR use gcloud CLI:
gcloud run services update backend \
  --set-env-vars="TRANSLATION_JOB_POLLING_INTERVAL_MS=5000,TRANSLATION_JOB_MAX_CONCURRENT_JOBS=3,TRANSLATION_JOB_MAX_CONCURRENT_LANGUAGES=3,TRANSLATION_JOB_BATCH_SIZE=10,OPENAI_TRANSLATION_TEMPERATURE=0.3,OPENAI_TRANSLATION_CONTEXT_WINDOW=128000"
```

3. **Deploy updated code:**
```bash
bash scripts/deploy-cloud-run.sh
```

### For New Deployments

1. **Copy `.env.example` to `.env`:**
```bash
cd backend-server
cp .env.example .env
```

2. **Fill in required values:**
```bash
# Edit .env and set:
# - OPENAI_API_KEY
# - SUPABASE_URL
# - SUPABASE_SERVICE_ROLE_KEY
# - STRIPE_SECRET_KEY
# - STRIPE_WEBHOOK_SECRET
```

3. **Adjust optional values as needed** (see `ENVIRONMENT_VARIABLES.md`)

4. **Deploy:**
```bash
bash scripts/deploy-cloud-run.sh
```

---

## Configuration Profiles

### Profile: Conservative (Low API Load)
```bash
TRANSLATION_JOB_MAX_CONCURRENT_JOBS=2
TRANSLATION_JOB_MAX_CONCURRENT_LANGUAGES=2
TRANSLATION_JOB_BATCH_SIZE=5
OPENAI_TRANSLATION_MAX_TOKENS=8000
```

**Use case:** Development, testing, budget constraints

### Profile: Balanced (Recommended)
```bash
TRANSLATION_JOB_MAX_CONCURRENT_JOBS=3
TRANSLATION_JOB_MAX_CONCURRENT_LANGUAGES=3
TRANSLATION_JOB_BATCH_SIZE=10
OPENAI_TRANSLATION_MAX_TOKENS=16000
```

**Use case:** Production, most deployments

### Profile: Aggressive (High Throughput)
```bash
TRANSLATION_JOB_MAX_CONCURRENT_JOBS=5
TRANSLATION_JOB_MAX_CONCURRENT_LANGUAGES=5
TRANSLATION_JOB_BATCH_SIZE=15
OPENAI_TRANSLATION_MAX_TOKENS=16000
TRANSLATION_JOB_POLLING_INTERVAL_MS=2000
```

**Use case:** High-traffic production, ample resources

---

## Backwards Compatibility

✅ **Fully backwards compatible**

All environment variables have sensible defaults matching the previous hardcoded values:

```typescript
// If not set, uses previous hardcoded value
parseInt(process.env.TRANSLATION_JOB_POLLING_INTERVAL_MS || '5000', 10)
```

**Result:** Existing deployments continue working without `.env` changes.

---

## Testing

### Verify Configuration Loading

Add this to your startup logs (already implemented):

```typescript
console.log('🚀 Translation job processor started');
console.log(`   - Polling interval: ${this.config.pollingInterval}ms`);
console.log(`   - Max concurrent jobs: ${this.config.maxConcurrentJobs}`);
console.log(`   - Max concurrent languages: ${this.config.maxConcurrentLanguages}`);
```

### Test Different Configurations

```bash
# Test 1: Conservative
export TRANSLATION_JOB_MAX_CONCURRENT_JOBS=1
npm start

# Test 2: Balanced (default)
unset TRANSLATION_JOB_MAX_CONCURRENT_JOBS
npm start

# Test 3: Aggressive
export TRANSLATION_JOB_MAX_CONCURRENT_JOBS=10
npm start
```

Check logs to confirm configuration is loaded correctly.

---

## Monitoring Recommendations

### Key Configuration Metrics

Track these metrics to optimize configuration:

1. **Job Processing Time**
   - Avg time per job
   - Correlation with concurrency settings

2. **API Usage**
   - OpenAI API calls per minute
   - Token usage per request
   - Error/timeout frequency

3. **System Resources**
   - Memory usage vs. concurrent jobs
   - CPU usage patterns

### Adjustment Triggers

**If jobs are queuing up:**
```bash
# Increase throughput
TRANSLATION_JOB_MAX_CONCURRENT_JOBS=5
TRANSLATION_JOB_POLLING_INTERVAL_MS=2000
```

**If seeing rate limit errors:**
```bash
# Decrease API load
TRANSLATION_JOB_MAX_CONCURRENT_LANGUAGES=2
TRANSLATION_JOB_MAX_CONCURRENT_JOBS=2
```

**If seeing timeouts:**
```bash
# Increase timeout and reduce batch size
OPENAI_TRANSLATION_TIMEOUT_MS=180000
TRANSLATION_JOB_BATCH_SIZE=5
```

---

## Files Modified

1. ✅ `backend-server/.env.example` - Added new environment variables
2. ✅ `backend-server/src/services/translation-job-processor.ts` - Read config from env
3. ✅ `backend-server/src/routes/translation.routes.ts` - Read temperature and context window from env
4. ✅ `backend-server/ENVIRONMENT_VARIABLES.md` - Comprehensive documentation
5. ✅ `backend-server/CONFIGURATION_MIGRATION.md` - This file

---

## Next Steps

- [ ] Update your `.env` file with new variables (optional, has defaults)
- [ ] Review `ENVIRONMENT_VARIABLES.md` for recommended settings
- [ ] Update Cloud Run environment variables if needed
- [ ] Deploy updated backend
- [ ] Monitor logs to verify configuration is loaded correctly
- [ ] Adjust settings based on production metrics

---

## Support

For detailed information about each environment variable, see:
- [`ENVIRONMENT_VARIABLES.md`](./ENVIRONMENT_VARIABLES.md) - Complete reference
- [`.env.example`](./.env.example) - Template with all variables

For questions about optimal configuration for your use case, refer to the "Environment-Specific Recommendations" section in `ENVIRONMENT_VARIABLES.md`.

