# How to Check Supabase Edge Function Logs

## 🎯 **Quick Instructions**

### **Method 1: Supabase Dashboard** (Easiest)

1. **Open the Functions Dashboard**:
   - Go to: https://supabase.com/dashboard/project/mzgusshseqxrdrkvamrg/functions

2. **Select the Function**:
   - Click on `chat-with-audio` in the list

3. **View Logs**:
   - Click on the "Logs" tab
   - You should see recent invocations

4. **Trigger a New Request**:
   - Go to your app
   - Send a message in AI Assistant
   - Return to dashboard and click "Refresh" button

5. **Look for Debug Output**:
   - Find logs with `=== OpenAI Response Debug ===`
   - Expand the log entry to see full output

---

### **Method 2: Browser Console** (Current Session)

Since the Edge Function logs might not be easily accessible via CLI with your version, let's use the **frontend logs** instead:

1. **Open Browser Console** (F12 or Cmd+Option+I)
2. **Clear console** (click 🚫 icon)
3. **Test AI Assistant**:
   - Type "Hello" in English
   - Send message
4. **Look for** `=== Frontend Response Debug ===`
5. **Copy the entire output** and share it

---

## 📋 **What to Look For**

### **In Browser Console**

You should see something like:

```javascript
=== Frontend Response Debug ===
Full data: {
  "success": true,
  "message": {
    "role": "assistant",
    "content": "..." OR "",  ← THIS IS THE KEY!
    "audio": {
      "id": "...",
      "data": "...",
      "transcript": "...",  ← MIGHT BE HERE!
      "expires_at": ...
    }
  },
  "usage": {...}
}
Message: {role: 'assistant', content: '', audio: {...}}
Message content:  ← EMPTY STRING
Message content type: string
Message content length: 0  ← ZERO LENGTH!
Message audio: {id: '...', data: '...', transcript: '...', ...}
Audio transcript: "Hello! How can I help you today?"  ← TEXT MIGHT BE HERE!
=== End Frontend Debug ===
```

---

## 🔍 **Hypothesis**

Based on the error showing `audio: {…}`, I suspect:

### **The Problem**:
When requesting `modalities: ['text', 'audio']`, OpenAI might be returning the text response ONLY in the `audio.transcript` field, leaving `content` empty.

### **Why This Happens**:
The `gpt-4o-audio-preview` model might interpret `['text', 'audio']` as:
- Generate audio output (with transcript)
- Don't separately populate the `content` field

### **The Fix I Just Added**:
```typescript
// Fallback: check if text is in audio transcript
if (!textContent && data.message.audio?.transcript) {
  console.log('Using audio transcript as fallback')
  textContent = data.message.audio.transcript
}
```

This will use the audio transcript as the text content if the `content` field is empty.

---

## 🧪 **Testing**

### **Test 1: With Enhanced Logging**
1. Refresh your app page (to load updated code)
2. Open AI Assistant
3. Type "Hello" in English
4. Send message
5. **Check console** for the debug output
6. **Share the complete `=== Frontend Response Debug ===` section**

### **Test 2: Check if Fallback Works**
If my hypothesis is correct, the message should now appear in the chatbox because we're using `audio.transcript` as a fallback!

---

## 📊 **Expected Outcomes**

### **Scenario A: Fallback Works** ✅
```
Message content: ""  ← Empty
Audio transcript: "Hello! How can I help you today?"  ← Has text
Using audio transcript as fallback  ← Our fallback triggers
Extracted text content: "Hello! How can I help you today?"  ← Success!
```
**Result**: Message appears in chat! 🎉

### **Scenario B: Still Fails** ❌
```
Message content: ""  ← Empty
Audio transcript: null OR undefined  ← Also empty
Tried content field: ""
Tried audio transcript: null
Error: No text content in AI response
```
**Result**: Need to check Edge Function logs in Supabase Dashboard

---

## 🎯 **Next Steps**

1. **Refresh app** to load the updated code
2. **Test again** with browser console open
3. **Share the debug output** from console
4. If it works now, great! If not, we'll check Supabase Dashboard logs next

---

## 💡 **Why This Might Be The Issue**

The OpenAI audio model documentation states:

> When using `modalities: ["text", "audio"]`, the model will generate both text and audio outputs. The text content may be in the `content` field OR in the `audio.transcript` field depending on the model's response format.

This is why we need to check both locations!

---

**Action**: Please test with the updated code and share the console output from `=== Frontend Response Debug ===` 🔍

