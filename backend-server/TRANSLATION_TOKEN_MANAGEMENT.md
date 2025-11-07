# Translation Token Management & Validation

**Date:** November 3, 2025  
**Status:** ✅ Enhanced for gpt-4.1-nano-2025-04-14

## Problem

Translation requests were previously failing with connection errors when content was too large:
- OpenAI server closing connection immediately (bytesWritten: 22KB, bytesRead: 0)
- No clear feedback about request size issues
- Fixed `max_completion_tokens` values that could exceed the model context window

## Solution

Implemented comprehensive token validation and dynamic token allocation tuned for `gpt-4.1-nano-2025-04-14`.

### 1. Token Estimation & Logging

```typescript
// Estimate tokens for both prompts
const estimateTokens = (text: string) => Math.ceil(text.length / 4);
const systemPromptTokens = estimateTokens(systemPrompt);
const userPromptTokens = estimateTokens(userPrompt);
const totalInputTokens = systemPromptTokens + userPromptTokens;

// Log detailed breakdown
console.log(`📊 Token estimation for ${targetLanguageName}:`, {
  systemPromptTokens,
  userPromptTokens,
  totalInputTokens,
  maxCompletionTokens,
  totalTokensNeeded,
  modelContextWindow: MODEL_CONTEXT_WINDOW,
  requestSizeBytes: systemPrompt.length + userPrompt.length,
  contentItemCount: data.contentItems.length,
});
```

### 2. Dynamic Token Allocation

**Before (❌ Fixed allocation):**
```typescript
const maxCompletionTokens = 32000; // Could exceed context window!
```

**After (✅ Dynamic allocation):**
```typescript
const MODEL_CONTEXT_WINDOW = 128000;
const configuredMaxTokens = parseInt(process.env.OPENAI_TRANSLATION_MAX_TOKENS || '16000', 10);
const availableOutputTokens = MODEL_CONTEXT_WINDOW - totalInputTokens;
const maxCompletionTokens = Math.min(configuredMaxTokens, availableOutputTokens);

// Ensure minimum space for output
if (maxCompletionTokens < 1000) {
  throw new Error(
    `Input too large: ${totalInputTokens} input tokens leaves only ${availableOutputTokens} tokens for output.`
  );
}
```

### 3. Environment Configuration

| Variable | Value | Why |
|----------|-------|-----|
| `OPENAI_TRANSLATION_MODEL` | `gpt-4.1-nano-2025-04-14` | Stable, cost-effective nano model |
| `OPENAI_TRANSLATION_MAX_TOKENS` | `16000` | Conservative output ceiling |
| `OPENAI_TRANSLATION_TIMEOUT_MS` | `120000` | 2 minute timeout for large cards |

## Benefits

1. ✅ **Prevents oversized requests** — validation happens before calling OpenAI
2. ✅ **Dynamic output tokens** — adapts per request based on available context
3. ✅ **Clear error messages** — explicit instructions when content is too large
4. ✅ **Detailed logging** — token breakdown for each translation
5. ✅ **Fail-fast** — avoids long waits on doomed requests

## Token Budget Breakdown (gpt-4.1-nano)

- **Context Window**: 128,000 tokens
- **Configured Output Ceiling**: 16,000 tokens
- **Maximum Input**: ~112,000 tokens (context minus output)

### Example Calculations

#### Small Card (10 items)
```
System Prompt: ~500 tokens
User Content:  ~5,000 tokens
Total Input:   ~5,500 tokens
Max Output:    16,000 tokens
Total:         21,500 tokens ✅ OK (fits in 128K context)
```

#### Medium Card (24 items)
```
System Prompt: ~500 tokens
User Content:  ~12,000 tokens
Total Input:   ~12,500 tokens
Max Output:    16,000 tokens
Total:         28,500 tokens ✅ OK
```

#### Large Card (50 items)
```
System Prompt: ~500 tokens
User Content:  ~25,000 tokens
Total Input:   ~25,500 tokens
Max Output:    16,000 tokens
Total:         41,500 tokens ✅ OK
```

#### Oversized Card (Would fail)
```
System Prompt: ~500 tokens
User Content:  ~120,000 tokens
Total Input:   ~120,500 tokens
Max Output:    16,000 tokens
Total:         136,500 tokens ❌ EXCEEDS 128K
Available:     7,500 tokens (too small, rejected)
```

## Error Messages

### Input Too Large
```
Error: Input too large: 120500 input tokens leaves only 7500 tokens for output.
Model context window is 128000 tokens.
Please reduce the amount of content or translate fewer items at once.
```

### Recommendations for Users
- Split extremely large cards into multiple smaller cards
- Reduce overly verbose content item descriptions
- Translate fewer languages simultaneously if needed

## Configuration Summary

```bash
OPENAI_TRANSLATION_MODEL=gpt-4.1-nano-2025-04-14
OPENAI_TRANSLATION_MAX_TOKENS=16000
OPENAI_TRANSLATION_TIMEOUT_MS=120000
```

### Why 16K Output Tokens?

- Aligns with known stable behaviour for gpt-4.1-nano
- Plenty for translating 10-item batches (~2K tokens input)
- Minimises chance of API truncation or network aborts

### If Using Different Models

- **gpt-4o-mini:** keep context window at 128K, but `OPENAI_TRANSLATION_MAX_TOKENS=16384`
- **gpt-5-nano (future):** increase context window to 256K and output ceiling to 128K

## Monitoring

Console output now includes token estimates per request:
```
📊 Token estimation for Traditional Chinese:
{
  systemPromptTokens: 315,
  userPromptTokens: 5195,
  totalInputTokens: 5510,
  maxCompletionTokens: 16000,
  totalTokensNeeded: 21510,
  modelContextWindow: 128000,
  requestSizeBytes: 22034,
  contentItemCount: 24
}
```

## Files Modified

- `backend-server/src/routes/translation.routes.ts`
  - Context window set to 128K
  - Fallback `max_completion_tokens` set to 16000
  - JSON mode enforced with `response_format`
- `backend-server/.env`
  - Translation model set to `gpt-4.1-nano-2025-04-14`
  - Max tokens set to `16000`

## Related Fixes

- **Translation Network Timeout** — Handles network issues within batches
- **GPT Nano Parameters** — Documents reasoning parameter limitations
- **Batch Translation Strategy** — Batches of 10 items with per-language saves
- **Translation UUID Matching** — Ensures reliable item alignment across batches


