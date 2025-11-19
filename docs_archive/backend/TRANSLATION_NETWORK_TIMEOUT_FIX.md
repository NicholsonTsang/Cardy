# Translation Network Timeout Fix

**Date:** November 3, 2025  
**Status:** ✅ Fixed

## Problem

Translation requests were failing with network errors:

```
TypeError: fetch failed
SocketError: other side closed
code: 'UND_ERR_SOCKET'
```

The connection to OpenAI was established (bytesWritten: 10559) but closed by the server before receiving a response (bytesRead: 0).

## Root Causes

1. **No timeout configured** - Fetch requests had no timeout, leaving them vulnerable to hanging connections
2. **Large request size** - Translation requests with many content items can take time to process
3. **Poor error handling** - Generic network errors weren't being caught and explained properly

## Solution

### 1. Added Request Timeout with AbortController

```typescript
// Configure timeout (2 minutes for large translations)
const timeoutMs = parseInt(process.env.OPENAI_TRANSLATION_TIMEOUT_MS || '120000', 10);
const controller = new AbortController();
const timeoutId = setTimeout(() => controller.abort(), timeoutMs);

const response = await fetch('https://api.openai.com/v1/chat/completions', {
  method: 'POST',
  headers: { /* ... */ },
  body: JSON.stringify({
    model: 'gpt-4.1-nano-2025-04-14',
    max_completion_tokens: 32000,
    // ...
  }),
  signal: controller.signal,
});

clearTimeout(timeoutId);
```

### 2. Enhanced Error Handling

```typescript
catch (error: any) {
  clearTimeout(timeoutId);
  
  // Handle timeout
  if (error.name === 'AbortError') {
    throw new Error(`Translation request timed out after ${timeoutMs}ms`);
  }
  
  // Handle network errors
  if (error.code === 'ECONNRESET' || error.code === 'UND_ERR_SOCKET' || error.message.includes('fetch failed')) {
    throw new Error('Network error: Connection to OpenAI was closed. Try again or reduce content size.');
  }
  
  throw error;
}
```

## Configuration

Backend `.env` configuration (optional):

```bash
# Translation timeout in milliseconds (default: 120000 = 2 minutes)
OPENAI_TRANSLATION_TIMEOUT_MS=120000
```

### Recommended Timeout Values

| Content Size | Timeout | Use Case |
|-------------|---------|----------|
| Small (1-5 items) | 30000 (30s) | Quick translations |
| Medium (6-15 items) | 60000 (60s) | Standard cards |
| Large (16-30 items) | 120000 (120s) | **Default, recommended** |
| Very Large (30+ items) | 180000 (180s) | Maximum content |

## Benefits

1. ✅ **Prevents hanging requests** - Automatic timeout after configured duration
2. ✅ **Better error messages** - Clear explanations for network issues
3. ✅ **Retry-friendly** - Clean error handling works with retry logic
4. ✅ **Configurable** - Easy to adjust timeout via environment variable
5. ✅ **Resource cleanup** - Properly clears timeout and aborts fetch

## Error Types Now Handled

| Error Code | Description | User-Friendly Message |
|-----------|-------------|----------------------|
| `AbortError` | Request timed out | Request timed out after Xms. Try reducing content size or increasing timeout. |
| `ECONNRESET` | Connection reset by peer | Network error: Connection to OpenAI was closed. Try again or reduce content size. |
| `UND_ERR_SOCKET` | Socket error (connection closed) | Network error: Connection to OpenAI was closed. Try again or reduce content size. |
| `fetch failed` | Generic fetch failure | Network error: Connection to OpenAI was closed. Try again or reduce content size. |

## Retry Behavior

The translation system already has exponential backoff retry logic:
- **Max attempts:** 3
- **Base delay:** 1000ms
- **Exponential backoff:** 1s → 2s → 4s

Combined with the timeout fix, this provides robust error recovery.

## Files Modified

- `backend-server/src/routes/translation.routes.ts` (lines 406-521)

## Testing Recommendations

1. **Normal case:** Small translations complete quickly
2. **Large content:** Cards with 20+ items should complete within timeout
3. **Network issues:** Automatic retry on transient failures
4. **Timeout:** If content is too large, clear error message guides user

## Related Fixes

- **Translation UUID Matching Fix** (Nov 3, 2025) - Addresses GPT UUID errors
- **Reasoning Effort Update** (Nov 3, 2025) - Removes unsupported parameter for gpt-5-nano

