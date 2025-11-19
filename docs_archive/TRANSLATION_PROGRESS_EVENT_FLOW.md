# Translation Progress Event Flow

This document shows the exact sequence of events and progress bar updates during translation.

## Scenario: Translating 1 language with 25 content items

**Configuration:**
- Batch size: 10 items per batch
- Total batches: 3 (10 + 10 + 5)
- Language: Japanese (ja)

## Event Sequence

### 1. Translation Starts
```javascript
Event: translation:started
{
  type: 'translation:started',
  cardId: 'xxx',
  totalLanguages: 1,
  languages: ['ja'],
  timestamp: '...'
}
```
**Frontend State:**
- Translation dialog opens
- Shows "Starting translation for 1 language..."

---

### 2. Language Starts
```javascript
Event: language:started
{
  type: 'language:started',
  cardId: 'xxx',
  language: 'ja',
  languageIndex: 1,
  totalLanguages: 1,
  totalBatches: 3,  // ← Frontend now knows total batches!
  timestamp: '...'
}
```
**Frontend State:**
- Progress bar: **0%** (0/3 batches)
- Message: "Translating to Japanese (1/1)..."
- Japanese language card shows: 0% progress, "pending" status

---

### 3. First Batch Processing
**Backend:** Processing batch 1 (items 1-10)...  
**Frontend:** No update yet, still shows 0%

---

### 4. First Batch Completes
```javascript
Event: batch:progress
{
  type: 'batch:progress',
  cardId: 'xxx',
  language: 'ja',
  batchIndex: 1,        // ← Completed batch 1
  totalBatches: 3,
  itemsInBatch: 10,
  timestamp: '...'
}
```
**Frontend State:**
- Progress bar: **33%** (1/3 batches) ← Moved from 0%!
- Message: "Completed batch 1/3 for Japanese (10 items)"
- Japanese language card shows: 33% progress, "in_progress" status

---

### 5. Second Batch Processing
**Backend:** Processing batch 2 (items 11-20)...  
**Frontend:** Still shows 33%, no update yet

---

### 6. Second Batch Completes
```javascript
Event: batch:progress
{
  type: 'batch:progress',
  cardId: 'xxx',
  language: 'ja',
  batchIndex: 2,        // ← Completed batch 2
  totalBatches: 3,
  itemsInBatch: 10,
  timestamp: '...'
}
```
**Frontend State:**
- Progress bar: **67%** (2/3 batches) ← Moved from 33%!
- Message: "Completed batch 2/3 for Japanese (10 items)"
- Japanese language card shows: 67% progress, "in_progress" status

---

### 7. Third Batch Processing
**Backend:** Processing batch 3 (items 21-25)...  
**Frontend:** Still shows 67%, no update yet

---

### 8. Third Batch Completes
```javascript
Event: batch:progress
{
  type: 'batch:progress',
  cardId: 'xxx',
  language: 'ja',
  batchIndex: 3,        // ← Completed batch 3 (final batch)
  totalBatches: 3,
  itemsInBatch: 5,
  timestamp: '...'
}
```
**Frontend State:**
- Progress bar: **100%** (3/3 batches) ← Moved from 67%!
- Message: "Completed batch 3/3 for Japanese (5 items)"
- Japanese language card shows: 100% progress, "in_progress" status

---

### 9. Language Saves to Database
**Backend:** Saving translations to database...  
**Frontend:** Still shows 100%, waiting for confirmation

---

### 10. Language Completes
```javascript
Event: language:completed
{
  type: 'language:completed',
  cardId: 'xxx',
  language: 'ja',
  languageIndex: 1,
  totalLanguages: 1,
  timestamp: '...'
}
```
**Frontend State:**
- Progress bar: **100%** (3/3 batches)
- Message: "✅ Completed Japanese"
- Japanese language card shows: 100% progress, "completed" status ✓

---

### 11. Translation Completes
```javascript
Event: translation:completed
{
  type: 'translation:completed',
  cardId: 'xxx',
  completedLanguages: ['ja'],
  failedLanguages: [],
  duration: 45000,
  timestamp: '...'
}
```
**Frontend State:**
- Overall progress: 100%
- Message: "✅ All 1 language completed successfully!"
- Dialog moves to success screen

---

## Key Improvements

### Before Fix
- ❌ Progress bar might show updates before batches complete
- ❌ Frontend didn't know totalBatches until first batch completed
- ❌ Progress messages said "Processing batch X" (confusing)

### After Fix
- ✅ Progress bar **only** updates after batches complete
- ✅ Frontend knows totalBatches from `language:started` event
- ✅ Progress messages say "**Completed** batch X" (clear)
- ✅ Progress bar starts at 0% and smoothly moves: 0% → 33% → 67% → 100%

## Multiple Languages Example

For 3 languages (Japanese, Korean, Spanish) with 25 items each:

```
Language 1: Japanese
├─ language:started (0%)
├─ batch:progress (33%) ← After batch 1 completes
├─ batch:progress (67%) ← After batch 2 completes
├─ batch:progress (100%) ← After batch 3 completes
└─ language:completed

Language 2: Korean
├─ language:started (0%)
├─ batch:progress (33%) ← After batch 1 completes
├─ batch:progress (67%) ← After batch 2 completes
├─ batch:progress (100%) ← After batch 3 completes
└─ language:completed

Language 3: Spanish
├─ language:started (0%)
├─ batch:progress (33%) ← After batch 1 completes
├─ batch:progress (67%) ← After batch 2 completes
├─ batch:progress (100%) ← After batch 3 completes
└─ language:completed

translation:completed
```

Each language processes independently, one at a time, with clear progress updates after each batch completes.

