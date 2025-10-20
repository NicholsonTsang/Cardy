# CardStudio Deployment Checklist

> 📋 **Print this page and check off items as you deploy**
> 
> For detailed instructions, see `DEPLOYMENT_COMPLETE_GUIDE.md`

---

## 📦 Prerequisites

- [ ] Supabase project created (note Project ID: _______________)
- [ ] OpenAI API key obtained (sk-...)
- [ ] Stripe account created (test + live keys)
- [ ] Domain configured (if using custom domain)
- [ ] Git repository cloned locally
- [ ] Node.js 18+ installed
- [ ] Supabase CLI installed (`npm install -g supabase`)

---

## 🔧 Part 1: Environment Variables

- [ ] Copy `.env.example` to `.env`
- [ ] Set `VITE_SUPABASE_URL`
- [ ] Set `VITE_SUPABASE_ANON_KEY`
- [ ] Set `VITE_SUPABASE_USER_FILES_BUCKET=userfiles`
- [ ] Set `VITE_STRIPE_PUBLISHABLE_KEY`
- [ ] Set `VITE_OPENAI_REALTIME_MODEL`
- [ ] Set `VITE_BATCH_MIN_QUANTITY` (default: 100)
- [ ] Set `VITE_CONTACT_EMAIL`
- [ ] Set `VITE_CONTACT_WHATSAPP_URL`
- [ ] Set `VITE_CONTACT_PHONE`
- [ ] Set demo card variables (optional)
- [ ] **Verify**: All required variables set

---

## 🗄️ Part 2A: Database

Run `./scripts/combine-storeproc.sh` first, then execute in Supabase Dashboard > SQL Editor:

- [ ] Execute `sql/schema.sql`
- [ ] Execute `sql/all_stored_procedures.sql`
- [ ] Execute `sql/policy.sql`
- [ ] Execute `sql/triggers.sql`
- [ ] **Verify**: Run verification SQL queries
- [ ] **Verify**: Check tables created (~20+ tables)
- [ ] **Verify**: Check functions created (~40+ functions)

---

## 🗄️ Part 2B: Storage Bucket

Create in Supabase Dashboard > Storage:

- [ ] Create bucket: `userfiles` (public)
- [ ] **Verify**: Bucket visible in Storage dashboard
- [ ] **Verify**: Storage policies applied (check `sql/policy.sql`)
- [ ] **Note**: App creates folder structure automatically: `{user_id}/card-images/` and `{user_id}/content-images/`

---

## 🗄️ Part 2C: Authentication

Configure in Supabase Dashboard > Authentication > URL Configuration:

- [ ] Set Site URL: `https://your-domain.com`
- [ ] Add redirect URL: `https://your-domain.com/reset-password`
- [ ] Add redirect URL: `https://your-domain.com/cms/mycards`
- [ ] Customize email templates (optional)
- [ ] **Verify**: Test signup email
- [ ] **Verify**: Test password reset email

---

## 🔌 Part 3A: Edge Function Secrets

Choose **Option 1** OR **Option 2**:

### Option 1: Interactive Script
- [ ] Run `./scripts/setup-production-secrets.sh`
- [ ] Follow prompts to set all secrets

### Option 2: Manual Setup
- [ ] `npx supabase secrets set OPENAI_API_KEY=sk-...`
- [ ] `npx supabase secrets set STRIPE_SECRET_KEY=sk_live_...`
- [ ] `npx supabase secrets set OPENAI_REALTIME_MODEL=gpt-realtime-mini-2025-10-06`
- [ ] `npx supabase secrets set STRIPE_WEBHOOK_SECRET=whsec_...` (set after Part 3C)

**Verify**:
- [ ] Run `npx supabase secrets list`
- [ ] Confirm all required secrets present

---

## 🔌 Part 3B: Edge Functions Deployment

Choose **Option 1** OR **Option 2**:

### Option 1: Deploy All at Once
- [ ] Run `./scripts/deploy-edge-functions.sh`

### Option 2: Deploy Individually
- [ ] `npx supabase functions deploy chat-with-audio`
- [ ] `npx supabase functions deploy chat-with-audio-stream`
- [ ] `npx supabase functions deploy generate-tts-audio`
- [ ] `npx supabase functions deploy openai-realtime-token`
- [ ] `npx supabase functions deploy translate-card-content`
- [ ] `npx supabase functions deploy create-credit-checkout-session`
- [ ] `npx supabase functions deploy handle-credit-purchase-success`
- [ ] `npx supabase functions deploy stripe-credit-webhook`

**Verify**:
- [ ] Run `npx supabase functions list`
- [ ] Check logs for errors

---

## 🔌 Part 3C: Stripe Webhook

In Stripe Dashboard > Webhooks:

- [ ] Create webhook endpoint
- [ ] Set URL: `https://[project].supabase.co/functions/v1/stripe-credit-webhook`
- [ ] Select event: `checkout.session.completed`
- [ ] Select event: `checkout.session.async_payment_succeeded`
- [ ] Select event: `checkout.session.async_payment_failed`
- [ ] Select event: `charge.refunded`
- [ ] Copy webhook secret (whsec_...)
- [ ] Set secret: `npx supabase secrets set STRIPE_WEBHOOK_SECRET=whsec_...`
- [ ] Redeploy: `npx supabase functions deploy stripe-credit-webhook`
- [ ] **Verify**: Send test event in Stripe Dashboard
- [ ] **Verify**: Check function logs for successful processing

---

## 🌐 Part 4A: Frontend Build

- [ ] Run `npm run build:production`
- [ ] **Verify**: `dist/` folder created
- [ ] **Verify**: No build errors
- [ ] **Verify**: Run `npm run type-check` (passes)

---

## 🌐 Part 4B: Frontend Deployment

Choose your hosting provider:

### Vercel
- [ ] Run `vercel --prod`
- [ ] Set environment variables in Vercel Dashboard

### Netlify
- [ ] Run `netlify deploy --prod`
- [ ] Set environment variables in Netlify Dashboard

### Firebase
- [ ] Run `firebase deploy --only hosting`
- [ ] Configure environment in Firebase Console

**Verify**:
- [ ] Site accessible at deployment URL
- [ ] SSL certificate active
- [ ] No console errors

---

## 🌐 Part 4C: Domain Configuration (Optional)

- [ ] Configure DNS A record
- [ ] Configure DNS CNAME record (www)
- [ ] Point domain to hosting provider
- [ ] Enable SSL certificate
- [ ] Configure www redirect (optional)
- [ ] **Verify**: Domain accessible via HTTPS
- [ ] **Verify**: www redirect works (if configured)

---

## ✅ Part 5: Post-Deployment Verification

### 5.1 Database Verification
- [ ] Run verification SQL queries
- [ ] Confirm ~20+ tables exist
- [ ] Confirm ~40+ functions exist
- [ ] Confirm RLS enabled on critical tables
- [ ] Confirm `userfiles` storage bucket exists (public)

### 5.2 Authentication Flow
- [ ] Test: User signup → Receive email → Confirm account
- [ ] Test: User login → Access dashboard
- [ ] Test: Password reset → Receive email → Reset successful
- [ ] Test: Admin role assignment → User role updates
- [ ] Test: Session refresh after role change

### 5.3 Credit System
- [ ] Navigate to `/cms/credits`
- [ ] Click "Purchase Credits"
- [ ] Complete test payment (Stripe test card: 4242 4242 4242 4242)
- [ ] Credits appear in dashboard
- [ ] Transaction logged in history

### 5.4 Card Creation
- [ ] Create new card with image upload
- [ ] Image crops to 2:3 ratio
- [ ] Select original language
- [ ] Enable AI assistant
- [ ] Add content items
- [ ] Save successfully

### 5.5 Translation
- [ ] Open card → General tab
- [ ] Click "Manage Translations"
- [ ] Select target language
- [ ] Confirm credit usage
- [ ] Translation completes
- [ ] Status shows "Up to Date"
- [ ] Preview translation works

### 5.6 Batch Issuance
- [ ] Navigate to card → Issue Batch tab
- [ ] Enter batch name and quantity (≥ 100)
- [ ] Confirm credit usage
- [ ] Batch created instantly
- [ ] Navigate to QR & Access tab
- [ ] Download QR codes as ZIP
- [ ] Download CSV with URLs
- [ ] Files download correctly

### 5.7 Mobile Client
- [ ] Scan QR code with mobile device
- [ ] Card loads correctly
- [ ] Select language
- [ ] Content displays in selected language
- [ ] AI Assistant opens
- [ ] Test text chat
- [ ] Test voice recording
- [ ] Test Realtime voice mode

### 5.8 Edge Functions
- [ ] Test `chat-with-audio` (returns 200)
- [ ] Test `generate-tts-audio` (returns audio)
- [ ] Test `openai-realtime-token` (returns token)
- [ ] Test `translate-card-content` (translates)
- [ ] No CORS errors
- [ ] Check logs for errors

### 5.9 Admin Functions
- [ ] Login as admin
- [ ] Access `/cms/admin/dashboard`
- [ ] View statistics
- [ ] Navigate to User Management
- [ ] Verify user
- [ ] Navigate to Batch Management
- [ ] Navigate to Credit Management
- [ ] Test credit adjustment
- [ ] View audit logs

---

## 🔍 Part 6: Monitoring & Maintenance

### 6.1 Monitoring Setup
- [ ] Check Supabase Database > Monitor
- [ ] Check Edge Functions > Invocations
- [ ] Check Authentication > MAU
- [ ] Check Storage > Usage
- [ ] Check Stripe > Payments
- [ ] Check Stripe > Webhooks delivery
- [ ] Configure error tracking (optional)

### 6.2 Backup Strategy
- [ ] Verify Supabase daily backups enabled
- [ ] Document backup restore process
- [ ] Set up Storage bucket backups (optional)

### 6.3 Documentation
- [ ] Document admin credentials (secure location)
- [ ] Document API keys (secure location)
- [ ] Document deployment process
- [ ] Create troubleshooting guide
- [ ] Train team on platform

---

## 🎉 Final Pre-Launch Checklist

- [ ] All environment variables configured
- [ ] Database fully deployed
- [ ] Storage buckets configured
- [ ] Authentication working
- [ ] Edge Functions deployed
- [ ] Stripe webhook configured
- [ ] Frontend deployed
- [ ] Domain configured (if applicable)
- [ ] All tests passing
- [ ] Monitoring active
- [ ] Backups configured
- [ ] Team trained
- [ ] Documentation complete

---

## 🚀 LAUNCH!

- [ ] Announce launch to stakeholders
- [ ] Monitor logs closely for first 48 hours
- [ ] Gather user feedback
- [ ] Document any issues
- [ ] Iterate based on feedback

---

**Deployment Date**: _______________

**Deployed By**: _______________

**Production URL**: _______________

**Notes**: 
________________________________________________________________
________________________________________________________________
________________________________________________________________
________________________________________________________________

---

**Reference Documents**:
- Full Guide: `DEPLOYMENT_COMPLETE_GUIDE.md`
- Flow Diagram: `DEPLOYMENT_FLOW_DIAGRAM.md`
- Summary: `DEPLOYMENT_GUIDE_SUMMARY.md`

