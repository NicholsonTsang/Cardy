# GPT Model Selection for Translations

**Date:** November 3, 2025  
**Status:** ✅ Using gpt-4.1-nano-2025-04-14 (stable & cost-effective)

## Background

We previously experimented with several models:
- `gpt-5-nano-2025-08-07` → Connection closed immediately (model unavailable)
- `gpt-4o-mini` → Reliable, but higher cost than nano tier

## Current Solution: gpt-4.1-nano-2025-04-14

Chosen because it is:
- ✅ **Available & stable** with our API key
- ✅ **Cost-effective** (nano pricing tier)
- ✅ **JSON mode compatible** using `response_format`
- ✅ **128K context window** — sufficient for our batched requests
- ✅ **Low latency** for translation workflows

## Configuration

```bash
# backend-server/.env
OPENAI_TRANSLATION_MODEL=gpt-4.1-nano-2025-04-14
OPENAI_TRANSLATION_MAX_TOKENS=16000
```

```typescript
// Translation API Request
{
  model: 'gpt-4.1-nano-2025-04-14',
  messages: [...],
  max_completion_tokens: 16000,
  response_format: { type: 'json_object' },
  temperature: 0.3,
}
```

## Model Comparison Snapshot

| Feature | gpt-4.1-nano (Current) | gpt-4o-mini | gpt-5-nano |
|---------|------------------------|-------------|------------|
| Availability | ✅ Stable | ✅ Stable | ❌ Unavailable |
| Context Window | 128K | 128K | 256K |
| Output Ceiling | 16K | 16K | 128K |
| Cost | 💰 Low | 💰 Medium | ❓ Unknown |
| JSON Mode | ✅ | ✅ | ✅ |
| Recommendation | ✅ Use now | Optional | Wait until available |

## Monitoring Metrics

Example log with current configuration:
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

## What if We Need More Capacity?

- Increase batch size? ➜ Prefer smaller batches (10 items) for reliability
- Need larger outputs? ➜ Evaluate `gpt-4o` or revisit `gpt-5-nano` when available
- Encounter availability issues? ➜ Fallback to `gpt-4o-mini`

## Files Updated

- `backend-server/.env`
- `backend-server/src/routes/translation.routes.ts`
- Documentation (`CLAUDE.md`, `REASONING_EFFORT_UPDATE.md`, `TRANSLATION_TOKEN_MANAGEMENT.md`)

