# Translation API Parameters - gpt-4.1-nano-2025-04-14
**Date:** November 2, 2025  
**Status:** ✅ Verified in production

---

## 🎯 Current Implementation

### API Endpoint
```
POST https://api.openai.com/v1/chat/completions
```
✅ **Status:** Standard Chat Completions API

### Parameters Used

| Parameter | Value | Notes |
|-----------|-------|-------|
| `model` | `gpt-4.1-nano-2025-04-14` | Set via `OPENAI_TRANSLATION_MODEL` |
| `messages` | System + user prompts | Standard chat format |
| `max_completion_tokens` | Dynamic (≤ 16000) | Calculated per request, capped by env |
| `response_format` | `{ type: 'json_object' }` | Forces valid JSON output |
| `temperature` | `0.3` | Low variance for consistent translations |
| `timeout` | 120,000ms | Controlled via AbortController |

### Environment Variables

```bash
OPENAI_TRANSLATION_MODEL=gpt-4.1-nano-2025-04-14
OPENAI_TRANSLATION_MAX_TOKENS=16000
OPENAI_TRANSLATION_TIMEOUT_MS=120000
# OPENAI_TRANSLATION_REASONING_EFFORT - NOT USED (nano models don't support it)
```

---

## 📊 Parameter Details

### 1. Model Selection
```typescript
model: process.env.OPENAI_TRANSLATION_MODEL || 'gpt-4.1-nano-2025-04-14'
```
- **Reason:** Nano tier balances cost & performance
- **Fallback:** Uses explicit version for reproducibility

### 2. Messages Payload
```typescript
messages: [
  { role: 'system', content: systemPrompt },
  { role: 'user', content: userPrompt }
]
```
- **System Prompt:** Translation guidelines (tone, formatting, JSON requirement)
- **User Prompt:** Card metadata + batched content items
- **Batching:** Only first batch includes card metadata (name/description)

### 3. Temperature
```typescript
temperature: 0.3
```
- **Purpose:** Keeps translations consistent & professional
- **Allowed Range:** 0.0 – 2.0 for chat completions

### 4. Max Completion Tokens
```typescript
const configuredMaxTokens = parseInt(process.env.OPENAI_TRANSLATION_MAX_TOKENS || '16000', 10);
const availableOutputTokens = MODEL_CONTEXT_WINDOW - totalInputTokens;
const max_completion_tokens = Math.min(configuredMaxTokens, availableOutputTokens);
```
- **Context Window:** 128,000 tokens for gpt-4.1-nano
- **Output Ceiling:** 16,000 tokens (configurable)
- **Safety:** Throws error if output budget would drop below 1,000 tokens

### 5. Response Format (JSON Mode)
```typescript
response_format: { type: 'json_object' }
```
- **Why:** Guarantees machine-readable JSON for downstream storage
- **Fallback:** Additional cleanup in parser strips stray markdown fences

### 6. Reasoning Parameters
- ❌ **Not used** — nano models reject `reasoning` / `reasoning_effort`
- ✅ Guidance is embedded in system prompt instead

---

## 🔄 Request Body Example
```json
{
  "model": "gpt-4.1-nano-2025-04-14",
  "messages": [
    { "role": "system", "content": "You are a professional translator ..." },
    { "role": "user", "content": "Translate the following content ..." }
  ],
  "max_completion_tokens": 16000,
  "response_format": { "type": "json_object" },
  "temperature": 0.3
}
```

---

## ✅ Verification Checklist
- [x] `/v1/chat/completions` endpoint
- [x] `model: gpt-4.1-nano-2025-04-14`
- [x] `messages` array in chat format
- [x] Dynamic `max_completion_tokens` with validation
- [x] `response_format` enforces JSON output
- [x] `temperature` explicitly set
- [x] Reasoning parameters removed
- [x] Request guarded by timeout + retries

---

## 📖 References
- [OpenAI API Reference – Chat Completions](https://platform.openai.com/docs/api-reference/chat)
- [OpenAI Model Overview](https://platform.openai.com/docs/models)

**Last Updated:** November 3, 2025  
**Verified By:** AI Assistant  
**Status:** ✅ Parameters validated against live API behaviour

