# Background Translation Jobs System

**Status:** In Progress (Backend Core Complete, Routes Need Cleanup, Frontend Pending)  
**Date:** November 8, 2025

## Overview

This document describes the implementation of a background translation job system that allows translations to continue processing even if the user closes their browser or navigates away from the page.

## Architecture Changes

### 1. Database Schema (`sql/schema.sql`)

Added new `translation_jobs` table:
```sql
CREATE TABLE translation_jobs (
    id UUID PRIMARY KEY,
    card_id UUID REFERENCES cards(id),
    user_id UUID REFERENCES auth.users(id),
    target_languages TEXT[],  -- Array of language codes
    status VARCHAR(20),  -- pending, processing, completed, failed, cancelled
    progress JSONB,  -- Per-language progress tracking
    retry_count INTEGER DEFAULT 0,
    max_retries INTEGER DEFAULT 3,
    credit_reserved DECIMAL(10,2),  -- Credits reserved upfront
    credit_consumed DECIMAL(10,2),  -- Credits actually used
    error_message TEXT,
    started_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    metadata JSONB
);
```

**Key Features:**
- Credits are reserved upfront when job is created
- Unused credits are refunded on completion/failure
- Per-language progress tracking in JSONB
- Automatic retry with configurable max attempts
- Comprehensive indexing for performance

### 2. Stored Procedures (`sql/storeproc/server-side/translation_jobs.sql`)

Created 11 new stored procedures:

1. **`create_translation_job`** - Creates job and reserves credits
2. **`get_translation_job`** - Retrieves job details by ID
3. **`get_user_translation_jobs`** - Lists user's jobs with filtering
4. **`get_pending_translation_jobs`** - Gets jobs for processing
5. **`update_translation_job_status`** - Updates job status
6. **`update_translation_job_progress`** - Updates per-language progress
7. **`increment_translation_job_retry`** - Increments retry counter
8. **`complete_translation_job`** - Completes job and handles credit accounting
9. **`cancel_translation_job`** - Cancels job and refunds credits
10. **`retry_failed_translation_languages`** - Creates new job for failed languages only

### 3. Background Job Processor (`backend-server/src/services/translation-job-processor.ts`)

**Core Service:** `TranslationJobProcessor` class

**Features:**
- Polls database every 5 seconds for pending jobs
- Processes up to 3 jobs concurrently
- Each job processes up to 3 languages concurrently
- Automatic retry on failure (up to 3 attempts)
- Continues processing even if client disconnects
- Emits Socket.IO events for real-time updates (when client is connected)

**Configuration:**
```typescript
{
  pollingInterval: 5000,      // 5 seconds
  maxConcurrentJobs: 3,       // Process 3 jobs simultaneously
  batchSize: 10,              // 10 content items per batch
  maxConcurrentLanguages: 3   // 3 languages per job simultaneously
}
```

**Lifecycle:**
1. Server starts → Job processor starts
2. Processor polls for pending jobs
3. For each job:
   - Fetch card and content data
   - Process languages in batches of 3
   - Each language processes content items in batches of 10
   - Update progress after each batch
   - Save translations to database
   - Handle credits (refund unused, record consumed)
4. On error: Retry up to max_retries times
5. On server shutdown → Stop processor gracefully

### 4. Backend Server Integration (`backend-server/src/index.ts`)

**Changes:**
- Import `translationJobProcessor`
- Start processor when server starts
- Stop processor on graceful shutdown (SIGTERM/SIGINT)

### 5. API Routes (Partial - Needs Completion)

**New Route Structure:**

#### Job Creation
```
POST /api/translations/translate-card
```
- Creates translation job instead of processing inline
- Reserves credits upfront
- Returns HTTP 202 (Accepted) with job_id
- Job is processed in background

#### Job Management
```
GET /api/translations/job/:jobId
GET /api/translations/jobs?status=pending&limit=50
POST /api/translations/job/:jobId/retry
POST /api/translations/job/:jobId/cancel
```

## Credit System

### Credit Flow

1. **Job Creation:**
   - Calculate credit cost: `1 credit × number_of_languages`
   - Check user balance
   - Deduct credits and mark as "reserved"
   - Create job with `credit_reserved` value

2. **Job Processing:**
   - Track which languages complete successfully
   - Track which languages fail

3. **Job Completion:**
   - Calculate actual credits used: `1 credit × successful_languages`
   - Refund difference: `credit_reserved - credit_consumed`
   - Record consumption in `credit_consumptions` table
   - Create entry in `translation_history`

### Example:
- User requests 5 languages
- 5 credits reserved upfront
- 3 languages succeed, 2 fail
- 3 credits consumed, 2 credits refunded
- User only pays for successful translations

## Real-Time Updates

### Socket.IO Events

Even though processing is in background, clients receive real-time updates if connected:

**Events Emitted:**
- `translation:started` - Job processing began
- `language:started` - Language processing started
- `batch:completed` - Batch finished
- `language:completed` - Language finished successfully
- `language:error` - Language failed
- `translation:completed` - All languages done
- `translation:failed` - Job failed
- `translation:retry` - Job retrying

**Frontend Handling:**
- If client is connected: Real-time updates via Socket.IO
- If client disconnects: Job continues processing
- When client reconnects: Poll for job status

## Retry Logic

### Automatic Retry
- Jobs automatically retry on failure
- Max 3 retries per job
- Retry counter increments on each attempt
- After max retries, job marked as "failed"

### Manual Retry
- Users can manually retry failed languages
- Creates new job with only failed languages
- New credits are reserved for retry
- Original job remains in history

### Retry Scenarios:
1. **Network timeout** → Retry
2. **OpenAI API error** → Retry
3. **Rate limit** → Retry with exponential backoff
4. **Invalid API key** → Don't retry (permanent failure)
5. **Insufficient credits** → Don't retry (user action needed)

## Status Flow

```
pending → processing → completed
                    → failed (after max retries)
                    → cancelled (user action)
```

## Implementation Status

### ✅ Completed
1. Database schema (`translation_jobs` table)
2. Stored procedures (all 11 functions)
3. Background job processor service
4. Server integration (start/stop processor)
5. Credit reservation and refund logic
6. Retry mechanism
7. Socket.IO event structure

### 🔄 In Progress
1. API routes cleanup (translation.routes.ts has dead code)
2. Frontend polling for job status
3. Frontend UI for job management

### ❌ Not Started
1. Frontend job status display
2. Frontend retry UI
3. Frontend job cancellation
4. Job history page
5. Admin dashboard for jobs
6. Job metrics and monitoring

## Next Steps

### Backend (Priority: High)
1. **Clean up `translation.routes.ts`:**
   - Remove all dead code between new routes and helper functions
   - Ensure clean separation between:
     - Job creation route (lines 48-200)
     - Job management routes (lines 202-401)
     - Helper functions (lines 405+)

### Frontend (Priority: High)
1. **Update Translation Store:**
   - Change `translateCard()` to create job instead of waiting for completion
   - Add `getTranslationJob(jobId)` method
   - Add `pollJobStatus(jobId)` method
   - Handle job status updates

2. **Update Translation Dialog:**
   - Show "Translation started in background" message
   - Add job status polling
   - Show progress from job status (not Socket.IO)
   - Allow closing dialog while translation runs
   - Show notification when translation completes (even if dialog closed)

3. **Add Job Management UI:**
   - Show ongoing translations in navbar/sidebar
   - Show failed translations with retry button
   - Allow cancelling pending jobs

### Testing (Priority: Medium)
1. Test with browser close during translation
2. Test with network disconnection
3. Test retry mechanism
4. Test credit refunds
5. Test concurrent job processing

### Documentation (Priority: Low)
1. API documentation
2. User guide
3. Admin guide
4. Troubleshooting guide

## Breaking Changes

### For Frontend
- `translateCard()` API response changed:
  - Old: Returns after all translations complete
  - New: Returns immediately with `job_id`
- Frontend must poll for job status
- Socket.IO events now include `jobId`

### For Database
- New `translation_jobs` table must be created
- New stored procedures must be deployed
- No changes to existing tables

### Migration Path
1. Deploy database changes (schema + stored procedures)
   - ✅ `schema.sql` includes `ALTER PUBLICATION supabase_realtime ADD TABLE translation_jobs;`
   - This automatically enables Supabase Realtime for instant job notifications
   - No manual dashboard configuration needed!
2. Deploy backend with new routes
3. Deploy frontend with polling logic
4. Old translations will still work (job system is backward compatible)

## Performance Considerations

### Database
- Indexed on `status`, `user_id`, `card_id`, `created_at`
- Jobs are cleaned up after 30 days (can add cron job)
- Progress JSONB is small (one entry per language)

### Backend
- Polling every 5 seconds is efficient
- Max 3 concurrent jobs prevents overload
- Each job uses existing translation logic (no changes to API calls)

### Frontend
- Poll every 5-10 seconds for job status
- Stop polling when job completes
- Use Socket.IO for real-time updates when connected
- Show toast notification on completion

## Monitoring

### Metrics to Track
1. Job completion rate
2. Average processing time per job
3. Retry rate
4. Failure rate by error type
5. Credits refunded vs consumed
6. Queue depth (pending jobs)

### Alerts
1. Job stuck in "processing" for > 10 minutes
2. High failure rate (> 20%)
3. Queue depth > 50 jobs
4. High retry rate (> 30%)

## Security

### Authorization
- All routes require authentication
- Users can only access their own jobs
- Job ownership verified before retry/cancel

### Rate Limiting
- Job creation rate limited (max 10 jobs per minute per user)
- Prevents abuse of credit system

### Data Privacy
- Job progress includes no sensitive data
- Error messages sanitized
- Job data auto-deleted after 30 days

## Conclusion

The background translation job system provides:
- **Reliability:** Translations continue even if browser closes
- **Transparency:** Real-time progress updates
- **Fairness:** Only pay for successful translations
- **Resilience:** Automatic retry on transient failures
- **Scalability:** Process multiple jobs concurrently

This is a significant improvement over the previous synchronous translation system and provides a better user experience for long-running translations.

