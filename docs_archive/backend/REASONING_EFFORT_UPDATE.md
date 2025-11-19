# OpenAI Nano Models Configuration

**Date:** November 3, 2025  
**Status:** ✅ Configured for gpt-4.1-nano-2025-04-14

## Important Discovery

The `reasoning` parameter is **NOT supported** by OpenAI's nano family models (`gpt-4.1-nano-2025-04-14`, `gpt-5-nano-*`, etc.). Attempting to pass `reasoning` or `reasoning_effort` results in:

```
Unknown parameter: 'reasoning'
invalid_request_error
```

## Solution: Remove Reasoning Parameter

**Current Implementation (✅ Correct):**
```typescript
{
  model: 'gpt-4.1-nano-2025-04-14',
  messages: [...],
  max_completion_tokens: 16000,
  response_format: { type: 'json_object' }, // Ensure valid JSON output
  temperature: 0.3,
  // Note: nano models do not support reasoning parameters
}
```

## Model-Specific Behavior

### gpt-4.1-nano-2025-04-14 (Current Model)
- ✅ **Optimized for speed & cost**
- ✅ 128K context window
- ✅ 16K+ realistic output capacity (configurable via env)
- ✅ Supports JSON mode via `response_format`
- ✅ Stable for translation workloads

### When to Consider Other Models
- **gpt-4o-mini**: Slightly higher accuracy, comparable context window, higher cost
- **gpt-5-nano** *(future)*: Larger 256K context window & 128K output, but currently unavailable for this project

## Conclusion

**No action required** — running with `gpt-4.1-nano-2025-04-14` provides reliable, cost-effective translations. Keep reasoning parameters disabled.

## Environment Variables

```bash
# OpenAI Translation Configuration
OPENAI_TRANSLATION_MODEL=gpt-4.1-nano-2025-04-14
OPENAI_TRANSLATION_MAX_TOKENS=16000   # Dynamic ceiling; actual output limited by context
OPENAI_TRANSLATION_TIMEOUT_MS=120000  # 2 minute timeout
# OPENAI_TRANSLATION_REASONING_EFFORT - NOT USED (nano models don't support it)
```

## Files Updated

- `backend-server/src/routes/translation.routes.ts`
  - Context window set to 128K
  - Default `max_completion_tokens` fallback set to 16000
  - `response_format` retained for JSON guarantees
- `backend-server/.env`
  - Translation model set to `gpt-4.1-nano-2025-04-14`
  - Max tokens set to `16000`

## Benefits of gpt-4.1-nano

1. **Fast by default** — low latency, low cost
2. **Consistent outputs** with `temperature: 0.3`
3. **JSON mode support** keeps downstream parsing simple
4. **Large enough context** (128K) for 100+ content items when batching
5. **No extra parameters** to maintain — simpler integration

## Comparison Snapshot

| Feature | gpt-4.1-nano (Current) | gpt-4o-mini | gpt-5-nano (Future) |
|---------|------------------------|-------------|----------------------|
| Context Window | 128K | 128K | 256K |
| Practical Output Ceiling | 16K | 16K | 128K |
| JSON Mode | ✅ | ✅ | ✅ |
| Availability | ✅ Stable | ✅ Stable | ⚠️ Unavailable |
| Cost | 💰 Low | 💰 Medium | ❓ Unknown |

## Testing & Compatibility

- ✅ `gpt-4.1-nano-2025-04-14`
- ✅ `gpt-4.1-nano` (alias)
- ⚠️ `gpt-5-nano-*` (currently unavailable for this project)
- ✅ OpenAI Chat Completions API (`https://api.openai.com/v1/chat/completions`)

