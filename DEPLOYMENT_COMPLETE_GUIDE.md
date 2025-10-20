# CardStudio Complete Deployment Guide

This guide provides a step-by-step deployment menu for setting up CardStudio from scratch. Follow these steps in order to ensure a complete and functional deployment.

## Prerequisites Checklist

- [ ] Supabase project created (note Project ID and URL)
- [ ] OpenAI API account with API key
- [ ] Stripe account with API keys (Test & Live)
- [ ] Domain configured (if using custom domain)
- [ ] Git repository cloned locally
- [ ] Node.js 18+ installed
- [ ] Supabase CLI installed (`npm install -g supabase`)

---

## 🔧 Part 1: Environment Variables Configuration

### 1.1 Frontend Environment Variables

**Location**: `.env` (production) and `.env.local` (local development)

**Copy from template**:
```bash
cp .env.example .env
```

**Required Variables**:

```bash
# ===== SUPABASE CONFIGURATION =====
VITE_SUPABASE_URL=https://your-project.supabase.co
VITE_SUPABASE_ANON_KEY=your-anon-key-here
VITE_SUPABASE_USER_FILES_BUCKET=userfiles

# ===== STRIPE CONFIGURATION =====
VITE_STRIPE_PUBLISHABLE_KEY=pk_live_...  # Use pk_test_... for testing

# ===== AI CONFIGURATION =====
VITE_OPENAI_REALTIME_MODEL=gpt-realtime-mini-2025-10-06
# Optional: For regions where OpenAI is blocked
# VITE_OPENAI_RELAY_URL=https://your-relay-server.com

# ===== BUSINESS CONFIGURATION =====
VITE_BATCH_MIN_QUANTITY=100  # Minimum cards per batch (default: 100)

# ===== CONTACT INFORMATION (for landing page) =====
VITE_CONTACT_EMAIL=contact@cardstudio.com
VITE_CONTACT_WHATSAPP_URL=https://wa.me/85212345678
VITE_CONTACT_PHONE=+852 1234 5678

# ===== DEMO CARD CONFIGURATION =====
VITE_SAMPLE_QR_URL=https://cardstudio.com/card/demo-card-id
VITE_DEMO_CARD_TITLE=Demo Museum Card
VITE_DEMO_CARD_SUBTITLE=Experience CardStudio
VITE_DEFAULT_CARD_IMAGE_URL=https://your-supabase-project.supabase.co/storage/v1/object/public/userfiles/demo-card.jpg

# ===== OPTIONAL CONFIGURATION (has defaults) =====
VITE_STRIPE_SUCCESS_URL=http://localhost:5173/cms/credits
VITE_DEFAULT_CURRENCY=USD
VITE_CARD_ASPECT_RATIO_WIDTH=2
VITE_CARD_ASPECT_RATIO_HEIGHT=3
VITE_CONTENT_ASPECT_RATIO_WIDTH=4
VITE_CONTENT_ASPECT_RATIO_HEIGHT=3
VITE_DEFAULT_AI_INSTRUCTION="You are a knowledgeable and friendly AI assistant for museum and exhibition visitors. Provide accurate, engaging, and educational explanations about exhibits and artifacts. Keep responses conversational and easy to understand. If you don't know something, politely say so rather than making up information."
```

**Verification**:
- [ ] All required variables are set
- [ ] SUPABASE_URL matches your project
- [ ] ANON_KEY is correct (check Supabase Dashboard > Settings > API)
- [ ] Stripe keys match environment (test vs live)

---

## 🗄️ Part 2: Supabase Configuration

### 2.1 Database Setup

**Execute SQL files in Supabase Dashboard > SQL Editor in this exact order**:

#### Step 1: Create Schema
```bash
# File: sql/schema.sql
```
- [ ] Execute `sql/schema.sql`
- [ ] Verify tables created: `cards`, `content_items`, `issued_cards`, `batches`, `user_credits`, `credit_transactions`, etc.

#### Step 2: Create Stored Procedures
```bash
# First, generate the combined file locally
./scripts/combine-storeproc.sh
```
- [ ] Run combine script
- [ ] Verify `sql/all_stored_procedures.sql` is generated
- [ ] Execute `sql/all_stored_procedures.sql` in Supabase SQL Editor
- [ ] Verify functions created (check Database > Functions in Supabase Dashboard)

#### Step 3: Apply RLS Policies
```bash
# File: sql/policy.sql
```
- [ ] Execute `sql/policy.sql`
- [ ] Verify policies applied (check Authentication > Policies)

#### Step 4: Create Triggers
```bash
# File: sql/triggers.sql
```
- [ ] Execute `sql/triggers.sql`
- [ ] Verify triggers created (check Database > Triggers)

**Verification Queries**:
```sql
-- Check tables
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' 
ORDER BY table_name;

-- Check functions
SELECT proname, pronargs FROM pg_proc 
WHERE pronamespace = 'public'::regnamespace 
ORDER BY proname;

-- Check policies
SELECT schemaname, tablename, policyname 
FROM pg_policies 
WHERE schemaname = 'public';

-- Check triggers
SELECT trigger_name, event_object_table 
FROM information_schema.triggers 
WHERE trigger_schema = 'public';
```

### 2.2 Storage Buckets Setup

**Create bucket in Supabase Dashboard > Storage**:

#### Bucket: `userfiles`
- [ ] Create bucket `userfiles`
- [ ] Set to **Public** bucket
- [ ] Configure CORS (if needed)

**Folder Structure** (created automatically by the app):
```
userfiles/
  └── {user_id}/
      ├── card-images/
      │   ├── {uuid}_original.{ext}  (uncropped card images)
      │   └── {uuid}_cropped.{ext}   (cropped 2:3 card images)
      └── content-images/
          ├── {uuid}_original.{ext}  (uncropped content images)
          └── {uuid}_cropped.{ext}   (cropped content images)
```

**Storage Policies**:

The storage policies are included in `sql/policy.sql`. Verify they are applied:

```sql
-- Check storage policies
SELECT * FROM storage.policies WHERE bucket_id = 'userfiles';
```

**Expected policies**:
- Allow authenticated users to upload to their own user folder
- Allow public read access to all files in the bucket
- Allow authenticated users to update/delete their own files only

**Optional: Enhanced Storage Security**

For additional security, you can execute `sql/storage_policies.sql`:
- [ ] Execute `sql/storage_policies.sql` in Supabase SQL Editor
- This adds RLS policies on `storage.objects` table
- Validates folder structure on upload (`card-images`, `content-images`, `verification-documents`)
- Enforces user-specific folder access

**Note**: This step is optional. The bucket works without these policies if set to public and the app handles security at the application level.

### 2.3 Authentication Configuration

#### Email Templates
**Location**: Supabase Dashboard > Authentication > Email Templates

- [ ] Customize **Confirm signup** template
- [ ] Customize **Reset password** template
- [ ] Customize **Magic Link** template (if using)

#### URL Configuration
**Location**: Supabase Dashboard > Authentication > URL Configuration

**Site URL**:
```
Production: https://your-domain.com
Development: http://localhost:5173
```

**Redirect URLs** (whitelist these):
```
# Production
https://your-domain.com/reset-password
https://your-domain.com/cms/mycards

# Development
http://localhost:5173/reset-password
http://localhost:5173/cms/mycards
```

- [ ] Set Site URL
- [ ] Add all redirect URLs to whitelist
- [ ] **CRITICAL**: Password reset requires `/reset-password` in whitelist

**Verification**:
- [ ] Test signup email received
- [ ] Test password reset email (should redirect to `/reset-password`)
- [ ] Test email confirmation link

---

## 🔌 Part 3: Edge Functions Setup

### 3.1 Edge Function Secrets (Production)

**Set these secrets BEFORE deploying functions**:

#### Method 1: Interactive Setup Script (Recommended)
```bash
./scripts/setup-production-secrets.sh
```

#### Method 2: Manual Setup

**Required Secrets** (must set these):
```bash
npx supabase secrets set OPENAI_API_KEY=sk-...
npx supabase secrets set STRIPE_SECRET_KEY=sk_live_...  # Use sk_test_... for testing
npx supabase secrets set STRIPE_WEBHOOK_SECRET=whsec_...  # Get from Stripe Dashboard after creating webhook
```

**Optional Overrides** (use defaults if not set):
```bash
# AI Model Configuration (defaults are production-ready)
npx supabase secrets set OPENAI_REALTIME_MODEL=gpt-realtime-mini-2025-10-06  # Default: gpt-realtime-mini-2025-10-06
npx supabase secrets set OPENAI_TEXT_MODEL=gpt-4o-mini  # Default: gpt-4o-mini
npx supabase secrets set OPENAI_AUDIO_MODEL=gpt-4o-mini-audio-preview  # Default: gpt-4o-mini-audio-preview
npx supabase secrets set OPENAI_WHISPER_MODEL=whisper-1  # Default: whisper-1
npx supabase secrets set OPENAI_TTS_MODEL=tts-1  # Default: tts-1

# Voice & Audio Configuration
npx supabase secrets set OPENAI_TTS_VOICE=alloy  # Default: alloy (options: alloy, echo, fable, onyx, nova, shimmer)
npx supabase secrets set OPENAI_AUDIO_FORMAT=wav  # Default: wav (options: wav, mp3, opus)

# Generation Parameters
npx supabase secrets set OPENAI_MAX_TOKENS=3500  # Default: 3500
npx supabase secrets set OPENAI_STT_MODE=audio-model  # Default: audio-model
```

**Verify secrets**:
```bash
npx supabase secrets list
```

**Checklist** (Required Secrets Only):
- [ ] `OPENAI_API_KEY` set
- [ ] `STRIPE_SECRET_KEY` set (use test key for testing)
- [ ] `STRIPE_WEBHOOK_SECRET` set (after setting up webhook in Part 3.3)

**Note**: `SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY` are automatically provided by Supabase and don't need to be manually set.

### 3.2 Edge Functions Deployment

#### Deploy All Functions at Once (Recommended)
```bash
./scripts/deploy-edge-functions.sh
```

#### Deploy Individual Functions
```bash
# AI Assistant functions
npx supabase functions deploy chat-with-audio
npx supabase functions deploy chat-with-audio-stream
npx supabase functions deploy generate-tts-audio
npx supabase functions deploy openai-realtime-token

# Translation function
npx supabase functions deploy translate-card-content

# Credit purchase functions
npx supabase functions deploy create-credit-checkout-session
npx supabase functions deploy handle-credit-purchase-success
npx supabase functions deploy stripe-credit-webhook
```

**Verify deployment**:
```bash
# Check function status
npx supabase functions list

# Test function (example)
curl -i --location --request POST \
  'https://your-project.supabase.co/functions/v1/chat-with-audio' \
  --header 'Authorization: Bearer YOUR_ANON_KEY' \
  --header 'Content-Type: application/json' \
  --data '{"test": true}'
```

**Checklist**:
- [ ] All functions deployed successfully
- [ ] No deployment errors in logs
- [ ] Functions appear in Supabase Dashboard > Edge Functions

### 3.3 Stripe Webhook Configuration

#### Create Webhook Endpoint in Stripe Dashboard

**Production Webhook URL**:
```
https://your-project.supabase.co/functions/v1/stripe-credit-webhook
```

**Events to Listen**:
- [x] `checkout.session.completed`
- [x] `checkout.session.async_payment_succeeded`
- [x] `checkout.session.async_payment_failed`
- [x] `charge.refunded`

**Get Webhook Secret**:
1. After creating webhook, copy the webhook signing secret (`whsec_...`)
2. Set it as Edge Function secret:
```bash
npx supabase secrets set STRIPE_WEBHOOK_SECRET=whsec_...
```

**Redeploy webhook function after setting secret**:
```bash
npx supabase functions deploy stripe-credit-webhook
```

**Checklist**:
- [ ] Webhook endpoint created in Stripe
- [ ] All required events selected
- [ ] Webhook secret copied
- [ ] Secret set in Supabase
- [ ] Webhook function redeployed

**Test Webhook** (Stripe Dashboard > Webhooks > Test):
- [ ] Send test `checkout.session.completed` event
- [ ] Verify in Supabase Dashboard > Edge Functions > stripe-credit-webhook > Logs
- [ ] Check for successful processing

---

## 🌐 Part 4: Frontend Deployment

### 4.1 Build Frontend

**For Production**:
```bash
npm run build:production
```

**For Preview/Staging**:
```bash
npm run build
```

**Verify build**:
- [ ] `dist/` folder created
- [ ] No build errors
- [ ] No TypeScript errors (`npm run type-check`)

### 4.2 Deploy to Hosting Provider

#### Option 1: Vercel
```bash
# Install Vercel CLI
npm install -g vercel

# Deploy
vercel --prod

# Set environment variables in Vercel Dashboard
# Project Settings > Environment Variables
```

#### Option 2: Netlify
```bash
# Install Netlify CLI
npm install -g netlify-cli

# Deploy
netlify deploy --prod

# Set environment variables in Netlify Dashboard
# Site Settings > Environment Variables
```

#### Option 3: Firebase Hosting
```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login and initialize
firebase login
firebase init hosting

# Deploy
firebase deploy --only hosting
```

**Checklist**:
- [ ] Build completed successfully
- [ ] Deployed to hosting provider
- [ ] Environment variables configured in hosting dashboard
- [ ] Custom domain configured (if applicable)
- [ ] SSL certificate active

### 4.3 Domain Configuration

**DNS Records** (if using custom domain):
```
Type    Name    Value
A       @       <hosting-provider-ip>
CNAME   www     <hosting-provider-domain>
```

**Checklist**:
- [ ] Domain DNS configured
- [ ] SSL certificate issued
- [ ] HTTPS working
- [ ] www redirect configured (if needed)

---

## ✅ Part 5: Post-Deployment Verification

### 5.1 Database Verification

```sql
-- Check tables exist
SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';
-- Expected: ~20+ tables

-- Check functions exist
SELECT COUNT(*) FROM pg_proc WHERE pronamespace = 'public'::regnamespace;
-- Expected: ~40+ functions

-- Check RLS enabled on critical tables
SELECT tablename, rowsecurity FROM pg_tables 
WHERE schemaname = 'public' AND tablename IN ('cards', 'content_items', 'user_credits');
-- Expected: All should have rowsecurity = true

-- Check storage buckets
SELECT * FROM storage.buckets;
-- Expected: userfiles (public bucket)
```

### 5.2 Authentication Flow Test

- [ ] **Signup**: Create new account → Receive confirmation email → Confirm email
- [ ] **Login**: Sign in with verified account → Redirect to dashboard
- [ ] **Password Reset**: Click "Forgot Password" → Receive reset email → Click link → Redirects to `/reset-password` → Reset password successfully
- [ ] **Role Assignment**: Admin approves user → User role becomes `cardIssuer`
- [ ] **Session Refresh**: After role change, user refreshes session → Role updated in UI

### 5.3 Credit System Test

- [ ] Navigate to `/cms/credits`
- [ ] Click "Purchase Credits"
- [ ] Enter amount (e.g., 100 credits)
- [ ] Redirects to Stripe Checkout
- [ ] Complete test payment (use Stripe test card: `4242 4242 4242 4242`)
- [ ] Returns to success page
- [ ] Credits appear in dashboard
- [ ] Transaction logged in history

### 5.4 Card Creation Test

- [ ] Create new card with image upload
- [ ] Image crops to 2:3 ratio
- [ ] Select original language (en or zh-Hant)
- [ ] Enable AI assistant
- [ ] Add content items
- [ ] Save successfully

### 5.5 Translation Test

- [ ] Open card → General tab → Multi-Language Support section
- [ ] Click "Manage Translations"
- [ ] Select target language (e.g., zh-Hant)
- [ ] Confirm credit usage (1 credit)
- [ ] Translation completes successfully
- [ ] Status shows "Up to Date"
- [ ] Preview translation in language dropdown

### 5.6 Batch Issuance Test

- [ ] Navigate to card → Issue Batch tab
- [ ] Enter batch name and quantity (≥ 100)
- [ ] System checks credit balance (2 credits/card)
- [ ] Confirm credit usage
- [ ] Batch created instantly
- [ ] Navigate to QR & Access tab
- [ ] Download QR codes as ZIP
- [ ] Download CSV with card URLs
- [ ] Verify files downloaded correctly

### 5.7 Mobile Client Test

- [ ] Scan QR code with mobile device
- [ ] Card loads correctly
- [ ] Select language from dropdown
- [ ] Content displays in selected language
- [ ] AI Assistant button appears (if enabled)
- [ ] Click AI Assistant → Modal opens
- [ ] Test text chat mode
- [ ] Test voice recording mode
- [ ] Test Realtime voice mode (if configured)

### 5.8 Edge Functions Test

**Test each function**:

```bash
# Get your session token
SESSION_TOKEN="your-jwt-token-here"

# Test chat-with-audio
curl -i --location --request POST \
  'https://your-project.supabase.co/functions/v1/chat-with-audio' \
  --header "Authorization: Bearer $SESSION_TOKEN" \
  --header 'Content-Type: application/json' \
  --data '{"message": "Hello", "cardId": "test-card-id"}'

# Test generate-tts-audio
curl -i --location --request POST \
  'https://your-project.supabase.co/functions/v1/generate-tts-audio' \
  --header "Authorization: Bearer $SESSION_TOKEN" \
  --header 'Content-Type: application/json' \
  --data '{"text": "Hello world", "language": "en"}'

# Test openai-realtime-token
curl -i --location --request POST \
  'https://your-project.supabase.co/functions/v1/openai-realtime-token' \
  --header "Authorization: Bearer $SESSION_TOKEN"
```

**Checklist**:
- [ ] All functions return 200 status
- [ ] No CORS errors
- [ ] Proper error handling for invalid inputs
- [ ] Check logs in Supabase Dashboard

### 5.9 Admin Functions Test

- [ ] Login as admin user
- [ ] Access `/cms/admin/dashboard`
- [ ] View statistics (cards, batches, users, credits)
- [ ] Navigate to User Management → Verify user
- [ ] Navigate to Batch Management → View all batches
- [ ] Navigate to Credit Management → View transactions
- [ ] Test credit adjustment for user
- [ ] View audit logs

---

## 🔍 Part 6: Monitoring & Maintenance

### 6.1 Set Up Monitoring

**Supabase Dashboard Checks**:
- [ ] Database > Monitor → Check query performance
- [ ] Edge Functions → Monitor invocations and errors
- [ ] Authentication → Check MAU (Monthly Active Users)
- [ ] Storage → Check storage usage

**Stripe Dashboard Checks**:
- [ ] Payments → Monitor successful charges
- [ ] Webhooks → Check webhook delivery success rate
- [ ] Disputes → Monitor for any disputes

**Error Tracking** (Optional):
```bash
# Install Sentry (or similar)
npm install @sentry/vue @sentry/vite-plugin

# Configure in main.ts
# Follow Sentry setup guide
```

### 6.2 Backup Strategy

**Database Backups**:
- Supabase automatically backs up daily
- Verify in Supabase Dashboard > Database > Backups
- [ ] Test restore from backup (staging environment)

**Storage Backups**:
- [ ] Set up periodic backup of Storage buckets
- [ ] Consider S3 sync or similar solution

### 6.3 Update Checklist

**When updating stored procedures**:
1. Edit files in `sql/storeproc/client-side/` or `sql/storeproc/server-side/`
2. Run `./scripts/combine-storeproc.sh`
3. Execute `sql/all_stored_procedures.sql` in Supabase SQL Editor
4. Test thoroughly in staging environment
5. Deploy to production

**When updating Edge Functions**:
1. Make changes to function code
2. Test locally: `npx supabase functions serve <function-name>`
3. Deploy: `npx supabase functions deploy <function-name>`
4. Monitor logs for errors

**When updating frontend**:
1. Make changes to Vue components
2. Test locally: `npm run dev:local`
3. Build: `npm run build:production`
4. Deploy to hosting provider
5. Clear CDN cache (if applicable)

---

## 🚨 Troubleshooting

### Common Issues

#### Issue: "Permission denied for function"
**Solution**: Check GRANT statements in stored procedures
```sql
-- Verify grants
SELECT p.proname, array_agg(pr.rolname) as granted_to
FROM pg_proc p
LEFT JOIN pg_proc_acl_explode(p.proacl) acl ON true
LEFT JOIN pg_roles pr ON acl.grantee = pr.oid
WHERE p.proname = 'your_function_name'
GROUP BY p.proname;
```

#### Issue: Password reset not working
**Solution**: Check redirect URL whitelist
- Supabase Dashboard > Authentication > URL Configuration
- Add `https://your-domain.com/reset-password` to whitelist

#### Issue: Edge Function 401 Unauthorized
**Solution**: Check JWT token in Authorization header
```typescript
// Get token from session
const { data: { session } } = await supabase.auth.getSession()
const token = session?.access_token

// Use in fetch
fetch(edgeFunctionUrl, {
  headers: { 'Authorization': `Bearer ${token}` }
})
```

#### Issue: Realtime Voice CORS Error
**Solution**: Check VITE_OPENAI_REALTIME_MODEL is set
```bash
# In .env
VITE_OPENAI_REALTIME_MODEL=gpt-realtime-mini-2025-10-06

# In Supabase secrets
npx supabase secrets set OPENAI_REALTIME_MODEL=gpt-realtime-mini-2025-10-06
```

#### Issue: Translations show "Outdated" after creation
**Solution**: Deploy hash calculation fix
```bash
# Execute DEPLOY_HASH_REFACTOR.sql in Supabase SQL Editor
# Or manually recalculate hashes:
SELECT recalculate_card_translation_hashes();
SELECT recalculate_content_item_translation_hashes();
```

#### Issue: Stripe webhook not receiving events
**Solution**: 
1. Check webhook URL is correct in Stripe Dashboard
2. Verify STRIPE_WEBHOOK_SECRET is set in Supabase
3. Check Edge Function logs for errors
4. Test webhook with Stripe CLI:
```bash
stripe listen --forward-to https://your-project.supabase.co/functions/v1/stripe-credit-webhook
```

---

## 📋 Final Deployment Checklist

### Pre-Launch
- [ ] All environment variables configured
- [ ] Database schema deployed
- [ ] Stored procedures deployed
- [ ] RLS policies applied
- [ ] Triggers created
- [ ] Storage buckets configured
- [ ] Edge Function secrets set
- [ ] Edge Functions deployed
- [ ] Stripe webhook configured
- [ ] Frontend built and deployed
- [ ] Domain and SSL configured

### Testing
- [ ] User signup/login works
- [ ] Password reset works
- [ ] Credit purchase works
- [ ] Card creation works
- [ ] Translation works
- [ ] Batch issuance works
- [ ] QR download works
- [ ] Mobile client works
- [ ] AI Assistant works (text + voice)
- [ ] Admin functions work

### Monitoring
- [ ] Database monitoring set up
- [ ] Edge Function logs reviewed
- [ ] Error tracking configured
- [ ] Backup strategy in place
- [ ] Performance baseline established

### Documentation
- [ ] Admin credentials documented (secure location)
- [ ] API keys documented (secure location)
- [ ] Deployment process documented
- [ ] Troubleshooting guide available
- [ ] Team training completed

---

## 🎉 Launch!

Once all checklist items are complete:

1. **Announce Launch**: Notify stakeholders
2. **Monitor Closely**: Watch logs and metrics for first 48 hours
3. **Gather Feedback**: Collect user feedback and issues
4. **Iterate**: Make improvements based on real-world usage

---

## 📞 Support Resources

- **Supabase Docs**: https://supabase.com/docs
- **Stripe Docs**: https://stripe.com/docs
- **OpenAI Docs**: https://platform.openai.com/docs
- **Project GitHub**: [Your Repository URL]
- **Issue Tracker**: [Your Issue Tracker URL]

---

**Last Updated**: 2025-10-15
**Version**: 1.0.0

