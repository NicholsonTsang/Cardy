# Translation Jobs System - Testing Guide

**Date:** November 8, 2025  
**Purpose:** Comprehensive testing of the production-ready background translation jobs system  
**Priority:** CRITICAL - Must complete before production deployment

---

## 🎯 Testing Overview

This guide covers all critical test scenarios for the background translation jobs system, including:
1. ✅ Basic translation flow
2. ✅ Browser close during translation
3. ✅ Network disconnection and recovery
4. ✅ Retry mechanism for failed jobs
5. ✅ Credit refunds and accounting
6. ✅ Concurrent jobs handling
7. ✅ Realtime connection stability

---

## 🔧 Test Environment Setup

### Prerequisites

1. **Backend Running:**
   ```bash
   cd backend-server
   npm run dev
   ```
   
   **Verify logs show:**
   ```
   ✅ Realtime subscription active
   🚀 Translation job processor started
      - Max concurrent jobs: 3
      - Max concurrent languages: 3
      - Mode: Realtime with polling fallback
   ```

2. **Frontend Running:**
   ```bash
   npm run dev
   ```

3. **Database Schema Applied:**
   - `schema.sql` with `translation_jobs` table
   - All stored procedures deployed
   - `triggers.sql` applied
   - Realtime enabled (`ALTER PUBLICATION supabase_realtime ADD TABLE translation_jobs;`)

4. **Test Account:**
   - User account with at least 20 credits
   - Test card with name, description, and 3+ content items

---

## ✅ Test 1: Basic Translation Flow

### **Objective:** Verify end-to-end translation works correctly

### Steps:

1. **Navigate to card:**
   - Go to "My Cards"
   - Open a test card

2. **Start translation:**
   - Scroll to "Multi-Language Support" section
   - Click "Manage Translations"
   - Select 2 languages (e.g., 简体中文, 日本語)
   - Click "Translate 2 Languages"
   - Confirm in credit confirmation dialog

3. **Observe Translation Jobs Panel:**
   - **Should appear below translation section**
   - **Job should show:**
     - Status: "Processing"
     - Progress bar showing % complete
     - 2 language tags (one for each selected language)
     - Credits reserved: 2
     - Credits consumed: (updating as languages complete)

4. **Watch progress:**
   - Progress should update every 5 seconds
   - Language tags should change from "Pending" → "Processing" → "Completed"
   - Progress bar should increase: 0% → 50% → 100%

5. **Verify completion:**
   - Job status changes to "Completed"
   - Green success banner appears
   - Translation section shows new languages
   - Credits consumed = 2
   - Credits refunded = 0

### Expected Results:

✅ Job created successfully  
✅ Job appears in Translation Jobs Panel  
✅ Progress updates in real-time  
✅ Translation completes within 1-2 minutes  
✅ Credits deducted correctly  
✅ Translations visible in language tags  

### Backend Logs to Watch:

```
📬 Realtime: New job created [job-id]
📥 Found 1 pending job(s)
🔄 Processing job: [job-id]
   - Card: [card-name]
   - Languages: zh-Hans, ja
✅ Language zh-Hans completed
✅ Language ja completed
✅ Job completed: [job-id]
```

---

## ✅ Test 2: Browser Close During Translation

### **Objective:** Verify translations continue when browser is closed

### Steps:

1. **Start translation:**
   - Select 3 languages (e.g., 简体中文, 日本語, 한국어)
   - Start translation
   - Wait for progress to reach ~30% (1 language completed)

2. **Close browser completely:**
   - Close the browser tab
   - Or close entire browser window
   - **Wait 2-3 minutes**

3. **Reopen browser:**
   - Navigate back to the card
   - Scroll to Translation Jobs Panel

4. **Check job status:**
   - Job should show "Completed" or still "Processing"
   - If processing: wait for completion
   - Translation should complete successfully

5. **Verify results:**
   - All 3 languages should be translated
   - Translation section shows all languages
   - Credits correctly deducted

### Expected Results:

✅ Translation continues after browser closes  
✅ Job completes successfully  
✅ All languages translated  
✅ Credits deducted correctly  
✅ No data loss  

### How It Works:

```
User starts translation → Job created in database
↓
User closes browser → Frontend disconnects
↓
Backend keeps processing → Polls database every 5s
↓
Job completes → Saves to database
↓
User reopens browser → Sees completed job
```

---

## ✅ Test 3: Network Disconnection and Recovery

### **Objective:** Verify system handles network issues gracefully

### Steps:

1. **Start translation:**
   - Select 2 languages
   - Start translation
   - Wait for progress to reach ~25%

2. **Simulate network disconnect:**
   - **Option A:** Open DevTools → Network tab → Set "Offline"
   - **Option B:** Disable WiFi/Ethernet
   - **Wait 30 seconds**

3. **Observe behavior:**
   - Backend continues processing (check logs)
   - Frontend polling fails (check browser console)
   - No error messages shown to user
   - Job panel shows last known state

4. **Reconnect network:**
   - Re-enable network connection
   - **Wait 10 seconds**

5. **Verify recovery:**
   - Frontend resumes polling automatically
   - Job status updates to current state
   - Progress catches up (may jump several %)
   - Translation completes successfully

### Expected Results:

✅ Backend continues processing during disconnect  
✅ Frontend reconnects automatically  
✅ Job completes successfully  
✅ No data corruption  
✅ User sees accurate final state  

### Backend Behavior:

- Realtime connection may drop
- System automatically falls back to internal polling
- Job processor continues running
- No jobs lost or duplicated

---

## ✅ Test 4: Retry Mechanism for Failed Jobs

### **Objective:** Test automatic retry and manual retry

### Setup:

**To simulate failure, temporarily break OpenAI API:**
```bash
# In backend .env file, set invalid API key:
OPENAI_API_KEY=sk-invalid-key-for-testing

# Restart backend
```

### Test 4A: Automatic Retry

1. **Start translation:**
   - Select 1 language
   - Start translation

2. **Observe failure:**
   - Job status: "Processing"
   - After ~30 seconds: Job status changes to "Processing" (retry #1)
   - System automatically retries up to 3 times

3. **After 3 failures:**
   - Job status changes to "Failed"
   - Error message displayed in job card
   - Language tag shows "Failed" with red color

4. **Restore API key:**
   ```bash
   # In .env, restore correct API key
   OPENAI_API_KEY=sk-correct-key

   # Restart backend
   ```

### Test 4B: Manual Retry

1. **With failed job visible:**
   - Click "Retry" button on failed job
   - Confirm retry action

2. **Observe retry:**
   - New job created with same languages
   - Original job remains as "Failed" (for history)
   - New job processes successfully
   - Credits reserved for new attempt

3. **Verify completion:**
   - New job completes
   - Translation visible
   - Credits: only charged for successful attempt

### Expected Results:

✅ Automatic retry (up to 3 attempts)  
✅ Job marked as "Failed" after 3 failures  
✅ Error message shown to user  
✅ Manual retry creates new job  
✅ Successful retry completes translation  
✅ Credits only charged for success  

---

## ✅ Test 5: Credit Refunds and Accounting

### **Objective:** Verify fair credit system

### Test 5A: Partial Success

1. **Start translation:**
   - Select 5 languages
   - Expected: 5 credits reserved

2. **Simulate 2 failures:**
   - Temporarily break API (see Test 4)
   - Let 3 languages succeed
   - Let 2 languages fail after 3 retries

3. **Check credit accounting:**
   ```
   Reserved: 5 credits
   Consumed: 3 credits (successful languages)
   Refunded: 2 credits (failed languages)
   ```

4. **Verify user balance:**
   - Check credit balance before translation
   - Balance should decrease by 3 (not 5)
   - Failed language credits returned

### Test 5B: Cancelled Job

1. **Start translation:**
   - Select 3 languages
   - Credits reserved: 3

2. **Cancel job immediately:**
   - Click "Cancel" button
   - Confirm cancellation

3. **Verify refund:**
   - Job status: "Cancelled"
   - Credits consumed: 0
   - Credits refunded: 3 (full refund)
   - User balance restored

### Expected Results:

✅ Credits reserved upfront  
✅ Partial success → partial refund  
✅ Cancelled job → full refund  
✅ Only pay for successful translations  
✅ Accurate credit balance  

### SQL Verification:

```sql
-- Check job credit accounting
SELECT 
  id,
  target_languages,
  status,
  credit_reserved,
  credit_consumed,
  (credit_reserved - credit_consumed) as refunded
FROM translation_jobs
WHERE card_id = 'your-card-id'
ORDER BY created_at DESC
LIMIT 5;

-- Check user credit balance
SELECT 
  balance,
  (SELECT SUM(amount) FROM credit_transactions WHERE user_id = 'your-user-id') as total_transactions
FROM user_credits
WHERE user_id = 'your-user-id';
```

---

## ✅ Test 6: Concurrent Jobs

### **Objective:** Verify system handles multiple jobs

### Steps:

1. **Create 5 cards** (or use existing cards)

2. **Start translations simultaneously:**
   - Open Card 1 → Start translation (2 languages)
   - Open Card 2 → Start translation (2 languages)
   - Open Card 3 → Start translation (2 languages)
   - Open Card 4 → Start translation (2 languages)
   - Open Card 5 → Start translation (2 languages)
   - **Do this quickly within 30 seconds**

3. **Observe job processing:**
   - Check backend logs
   - Should see: "Found 5 pending job(s)"
   - Max 3 jobs process concurrently
   - Others wait in queue

4. **Verify completion:**
   - All 5 jobs complete successfully
   - No jobs lost or duplicated
   - All translations successful

### Expected Results:

✅ Queue handles 5 jobs  
✅ Max 3 process concurrently  
✅ Remaining 2 wait patiently  
✅ All complete successfully  
✅ No race conditions  
✅ No duplicate processing  

### Backend Logs:

```
📥 Found 5 pending job(s)
🔄 Processing job: [job-1]
🔄 Processing job: [job-2]
🔄 Processing job: [job-3]
✅ Job completed: [job-1]
🔄 Processing job: [job-4]  ← Picks up next job
✅ Job completed: [job-2]
🔄 Processing job: [job-5]
...all complete
```

---

## ✅ Test 7: Realtime Connection Stability

### **Objective:** Verify Realtime connection is robust

### Test 7A: Normal Operation

1. **Start backend with Realtime enabled**

2. **Verify connection:**
   - Check logs: `✅ Realtime subscription active`
   - Create translation job
   - Should see: `📬 Realtime: New job created [id]`
   - Job picked up within 100ms

### Test 7B: Realtime Disconnection

1. **Simulate Realtime failure:**
   - In Supabase Dashboard, temporarily disable Realtime
   - Or kill Supabase connection

2. **Observe behavior:**
   - Backend logs: `⚠️ Realtime subscription closed`
   - Backend logs: `🔄 Attempting Realtime reconnection...`
   - Backend logs: `📊 Switching to polling mode`

3. **Create translation job:**
   - Job still created successfully
   - Backend picks up via polling (within 5 seconds)
   - Translation completes normally

4. **Re-enable Realtime:**
   - Restore Realtime in Supabase
   - Backend should reconnect automatically
   - See: `✅ Realtime subscription active`

### Test 7C: Health Check

1. **Let system run for 10 minutes:**
   - No translation jobs created
   - Just idle

2. **Create translation job:**
   - Should be picked up instantly (<100ms)
   - Health check should detect the job

3. **Verify logs:**
   ```
   ✅ Realtime connection healthy
   📬 Realtime: New job created [id]
   📥 Found 1 pending job(s)
   ```

### Expected Results:

✅ Realtime picks up jobs instantly (<100ms)  
✅ Automatic reconnection on failure  
✅ Seamless fallback to polling  
✅ Health monitoring detects stale connections  
✅ Zero job loss under any scenario  

---

## 🎯 Test Results Checklist

Mark each test as you complete it:

- [ ] **Test 1:** Basic translation flow
- [ ] **Test 2:** Browser close during translation
- [ ] **Test 3:** Network disconnection and recovery
- [ ] **Test 4A:** Automatic retry mechanism
- [ ] **Test 4B:** Manual retry button
- [ ] **Test 5A:** Credit refunds for partial success
- [ ] **Test 5B:** Credit refunds for cancelled job
- [ ] **Test 6:** Concurrent jobs handling
- [ ] **Test 7A:** Realtime normal operation
- [ ] **Test 7B:** Realtime disconnection and fallback
- [ ] **Test 7C:** Health check monitoring

---

## 🐛 Common Issues & Solutions

### Issue: Jobs stuck in "Pending"

**Symptoms:**
- Job created but never starts processing
- No progress updates

**Check:**
1. Is backend running? (`npm run dev`)
2. Is job processor started? (check logs for `🚀 Translation job processor started`)
3. Is Realtime connected? (check for `✅ Realtime subscription active`)

**Solution:**
- Restart backend
- Check database for pending jobs:
  ```sql
  SELECT * FROM translation_jobs WHERE status = 'pending';
  ```

---

### Issue: Frontend not showing job updates

**Symptoms:**
- Job panel doesn't update
- Progress stuck at 0%

**Check:**
1. Browser console for errors
2. Network tab for failed API calls
3. Check if polling is active

**Solution:**
- Refresh page
- Clear browser cache
- Check backend is accessible

---

### Issue: Credits not refunding

**Symptoms:**
- Job failed but credits not returned

**Check:**
```sql
SELECT * FROM translation_jobs 
WHERE id = 'job-id';
-- Check credit_reserved vs credit_consumed

SELECT * FROM user_credits 
WHERE user_id = 'user-id';
-- Check balance
```

**Solution:**
- Run stored procedure manually:
  ```sql
  SELECT complete_translation_job('job-id', 'failed', NULL);
  ```

---

### Issue: Realtime not connecting

**Symptoms:**
- Backend logs: `❌ Realtime subscription error`
- Fallback to polling mode

**Check:**
1. Is Realtime enabled in Supabase?
2. Is `translation_jobs` in publication?
   ```sql
   SELECT * FROM pg_publication_tables 
   WHERE pubname = 'supabase_realtime' 
   AND tablename = 'translation_jobs';
   ```

**Solution:**
```sql
ALTER PUBLICATION supabase_realtime ADD TABLE translation_jobs;
```
Restart backend.

---

## 📊 Performance Benchmarks

### Expected Performance:

| Metric | Target | Acceptable Range |
|--------|--------|------------------|
| **Job Pickup (Realtime)** | <100ms | 50-200ms |
| **Job Pickup (Polling)** | <5s | 5-10s |
| **Translation (1 lang)** | 20-40s | 15-60s |
| **Translation (3 langs)** | 40-80s | 30-120s |
| **Credit Refund** | Instant | <1s |
| **Realtime Reconnect** | <10s | 5-60s |

### Database Query Performance:

```sql
-- Should be fast (<50ms)
EXPLAIN ANALYZE
SELECT * FROM translation_jobs
WHERE status = 'pending'
ORDER BY created_at ASC
LIMIT 10
FOR UPDATE SKIP LOCKED;
```

---

## ✅ Final Verification

Before marking testing as complete:

1. **All 11 tests passed** ✓
2. **No unresolved issues** ✓
3. **Performance meets benchmarks** ✓
4. **Credits accounting accurate** ✓
5. **Realtime connection stable** ✓
6. **Documentation updated** ✓

---

## 🚀 Ready for Production

Once all tests pass:

1. **Update `IMPLEMENTATION_STATUS.md`:**
   ```markdown
   ### 🧪 Testing: 100% Complete
   - All scenarios tested
   - All tests passed
   - Production ready
   ```

2. **Deploy to staging first**
3. **Run smoke tests on staging**
4. **Deploy to production**
5. **Monitor initial usage**

---

**Good luck with testing! 🎉**

Remember: **Thorough testing now prevents production issues later!**

