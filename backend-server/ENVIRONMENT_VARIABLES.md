# Environment Variables Documentation

This document describes all environment variables used by the backend server.

## Required Variables

These variables **must** be set for the server to function:

### OpenAI Configuration
```bash
OPENAI_API_KEY=your_openai_api_key_here
```
Your OpenAI API key for accessing GPT models, TTS, Realtime API, and other OpenAI services (used for AI chat, TTS, etc. - NOT for translations).

### Google Gemini Configuration
```bash
GOOGLE_APPLICATION_CREDENTIALS=gemini-service-account.json
```
Path to Google service account JSON file for Gemini API authentication (used for translations).

### Supabase Configuration
```bash
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key_here
```
Supabase project URL and service role key (with admin privileges) for database operations.

### Stripe Configuration
```bash
STRIPE_SECRET_KEY=sk_test_your_stripe_secret_key_here
STRIPE_WEBHOOK_SECRET=whsec_your_webhook_secret_here
STRIPE_API_VERSION=2025-08-27.basil
STRIPE_PREMIUM_PRICE_ID=price_premium_id_here
STRIPE_STARTER_PRICE_ID=price_starter_id_here
```
Stripe API credentials for payment processing and webhook signature verification.

---

## Optional Variables with Defaults

### Server Configuration

#### PORT
```bash
PORT=8080  # Default: 8080
```
The port on which the Express server listens.

#### NODE_ENV
```bash
NODE_ENV=development  # Options: development, production
```
Sets the application environment. Affects logging verbosity and error reporting.

---

### CORS Configuration

#### ALLOWED_ORIGINS
```bash
ALLOWED_ORIGINS=*  # Default: * (all origins)
```
Comma-separated list of allowed origins for CORS.

**Examples:**
- Development (all origins): `ALLOWED_ORIGINS=*`
- Single origin: `ALLOWED_ORIGINS=https://your-app.com`
- Multiple origins: `ALLOWED_ORIGINS=https://app.com,https://admin.app.com`

**⚠️ Security Note:**
- Development: Use `*` for easy testing
- Production: **Always specify exact origins** for security

---

### Rate Limiting

#### RATE_LIMIT_WINDOW_MS
```bash
RATE_LIMIT_WINDOW_MS=900000  # Default: 900000 (15 minutes)
```
Time window in milliseconds for rate limiting.

#### RATE_LIMIT_MAX_REQUESTS
```bash
RATE_LIMIT_MAX_REQUESTS=100  # Default: 100
```
Maximum number of requests allowed per IP within the time window.

---

### Subscription & Pricing

These variables control the pricing and limits for the three tiers.

#### Starter Tier
```bash
STARTER_MONTHLY_FEE_USD=40
STARTER_EXPERIENCE_LIMIT=5
STARTER_MONTHLY_BUDGET_USD=40
STARTER_AI_ENABLED_SESSION_COST_USD=0.05
STARTER_AI_DISABLED_SESSION_COST_USD=0.025
```

#### Premium Tier
```bash
PREMIUM_MONTHLY_FEE_USD=280
PREMIUM_EXPERIENCE_LIMIT=35
PREMIUM_MONTHLY_BUDGET_USD=280
PREMIUM_AI_ENABLED_SESSION_COST_USD=0.045
PREMIUM_AI_DISABLED_SESSION_COST_USD=0.02
```

#### Free Tier
```bash
FREE_TIER_EXPERIENCE_LIMIT=3
FREE_TIER_MONTHLY_SESSION_LIMIT=50
```

#### Overage
```bash
OVERAGE_CREDITS_PER_BATCH=5
```

---

### OpenAI Configuration

#### OPENAI_TEXT_MODEL
```bash
OPENAI_TEXT_MODEL=gpt-4o-mini  # Default: gpt-4o-mini
```
OpenAI model for general text generation (AI chat).

#### OPENAI_MAX_TOKENS
```bash
OPENAI_MAX_TOKENS=3500  # Default: 3500
```
Maximum tokens for general OpenAI API calls.

#### OPENAI_TTS_MODEL
```bash
OPENAI_TTS_MODEL=tts-1  # Default: tts-1
```
OpenAI Text-to-Speech model.

#### OPENAI_TTS_VOICE
```bash
OPENAI_TTS_VOICE=alloy  # Default: alloy
# Options: alloy, echo, fable, onyx, nova, shimmer
```
Voice to use for TTS generation.

#### OPENAI_AUDIO_FORMAT
```bash
OPENAI_AUDIO_FORMAT=wav  # Default: wav
# Options: mp3, opus, aac, flac, wav, pcm
```
Audio format for TTS output.

#### OPENAI_REALTIME_MODEL
```bash
OPENAI_REALTIME_MODEL=gpt-realtime-mini-2025-10-06
```
Model for OpenAI Realtime API.

---

### Google Gemini Translation Configuration

These variables control the Gemini API for translation tasks.

#### GEMINI_TRANSLATION_MODEL
```bash
GEMINI_TRANSLATION_MODEL=gemini-2.5-flash-lite  # Default: gemini-2.5-flash-lite
```
Google Gemini model for translation tasks.

**Recommendation:** Use `gemini-2.5-flash-lite` for:
- Fast translation speed
- Excellent translation quality
- Native JSON output support
- Cost-effectiveness
- Better availability than OpenAI

#### GEMINI_TRANSLATION_MAX_TOKENS
```bash
GEMINI_TRANSLATION_MAX_TOKENS=30000  # Default: 30000
```
Maximum output tokens for translation responses.

**Guidelines:**
- Small cards (< 10 items): 8000 tokens
- Medium cards (10-30 items): 16000 tokens
- Large cards (30-100 items): 30000 tokens
- Very large cards (> 100 items): May need to be split into multiple requests

#### GEMINI_TRANSLATION_TEMPERATURE
```bash
GEMINI_TRANSLATION_TEMPERATURE=0.3  # Default: 0.3
```
Temperature setting for translation API calls (0.0 - 2.0).

**Guidelines:**
- Lower (0.1 - 0.3): More consistent, deterministic translations (recommended)
- Medium (0.4 - 0.7): More creative translations
- Higher (0.8 - 2.0): Very creative but potentially inconsistent (not recommended)

---

## Translation System Architecture

The translation system uses **synchronous processing with Socket.IO** for real-time progress updates:

1. **Client** sends translation request via API
2. **Backend** processes translations immediately
3. **Socket.IO** sends real-time progress updates to client
4. **Languages** are processed concurrently (max 3 at once)
5. **Content batches** are processed sequentially (10 items per batch)
6. **Credits** are consumed after each successful language translation

This approach provides:
- ✅ Real-time progress feedback (<100ms updates)
- ✅ Instant completion (no job queue delays)
- ✅ Partial success handling (failed languages don't affect successful ones)
- ✅ Per-language credit accounting
- ✅ Simpler architecture (no background workers)

---

## Environment-Specific Recommendations

### Development
```bash
NODE_ENV=development
ALLOWED_ORIGINS=*
GEMINI_TRANSLATION_TEMPERATURE=0.3
GEMINI_TRANSLATION_MAX_TOKENS=30000
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=100
```

### Staging
```bash
NODE_ENV=production
ALLOWED_ORIGINS=https://staging.your-app.com
GEMINI_TRANSLATION_TEMPERATURE=0.3
GEMINI_TRANSLATION_MAX_TOKENS=30000
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=100
```

### Production
```bash
NODE_ENV=production
ALLOWED_ORIGINS=https://your-app.com,https://admin.your-app.com
GEMINI_TRANSLATION_TEMPERATURE=0.3
GEMINI_TRANSLATION_MAX_TOKENS=30000
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=200
```

---

## Deployment Checklist

Before deploying, ensure:

- [ ] All required variables are set
- [ ] `ALLOWED_ORIGINS` is set to specific domains (not `*`) in production
- [ ] `NODE_ENV=production` in production
- [ ] OpenAI API key has sufficient credits/quota
- [ ] Google service account JSON file is accessible
- [ ] Gemini API is enabled in Google Cloud project
- [ ] Stripe keys match the environment (test vs. live)
- [ ] Rate limiting is configured appropriately

---

## Monitoring Recommendations

### Key Metrics to Track

1. **Translation Operations:**
   - Average translation completion time per language
   - Translation success rate
   - Translation failure rate
   - Credits consumed per translation

2. **Gemini API:**
   - API call count per minute
   - Token usage per request
   - API response time
   - Error rate

3. **System Resources:**
   - Memory usage during concurrent translations
   - CPU usage
   - Socket.IO connection count
   - API response times

### Adjustment Triggers

**If translations are slow:**
- Check Gemini API response times
- Verify network latency to Google APIs
- Consider increasing max concurrent languages (currently 3)

**If Gemini rate limit errors occur:**
- Reduce concurrent language processing
- Add retry logic with exponential backoff
- Contact Google to increase quota

**If Socket.IO issues occur:**
- Check connection stability
- Monitor WebSocket connection count
- Verify CORS configuration

---

## Troubleshooting

### Common Issues

#### Gemini API authentication errors
- Verify `GOOGLE_APPLICATION_CREDENTIALS` path is correct
- Ensure service account JSON file exists and is readable
- Check service account has Gemini API permissions

#### Translation timeouts
- Check Gemini API status
- Verify network connectivity to Google APIs
- Consider reducing batch size if translating very large cards

#### Socket.IO connection issues
- Verify CORS configuration includes all client origins
- Check WebSocket support in deployment environment
- Ensure ports are properly configured

#### High memory usage
- Monitor concurrent translation requests
- Check for memory leaks in Socket.IO connections
- Adjust rate limiting if needed

---

## Security Best Practices

1. **Never commit `.env` files** to version control
2. **Use `.env.example`** for documentation only
3. **Rotate API keys** regularly
4. **Use different keys** for development, staging, and production
5. **Restrict CORS origins** in production
6. **Monitor API usage** for anomalies
7. **Set up alerts** for unusual activity
8. **Secure service account JSON** files with proper permissions
9. **Use secrets management** in cloud deployments

---

## Related Documentation

- [Gemini Translation Migration](../GEMINI_TRANSLATION_MIGRATION.md)
- [Job Queue Removal](../JOB_QUEUE_REMOVAL_COMPLETE.md)
- [Translation Credit Consumption](../TRANSLATION_CREDIT_CONSUMPTION.md)
- [Main README](../README.md)
