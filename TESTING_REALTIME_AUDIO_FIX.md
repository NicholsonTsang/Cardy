# Testing Guide: Realtime Audio Restart Fix

## Overview

Fixed the issue where AI voice stops and re-speaks from the beginning during mobile realtime conversations.

## What Was Fixed

**Problem**: On mobile, the AI would start speaking, suddenly stop, then start speaking again from the beginning.

**Root Cause**: The WebRTC `ontrack` event handler was creating a new `Audio()` element every time it fired. On mobile networks, `ontrack` fires multiple times due to ICE reconnections (when switching between WiFi and cellular, or during cell tower handoffs).

**Solution**: Track the audio element and prevent creating duplicates when `ontrack` fires multiple times.

---

## Testing Instructions

### ⚠️ Critical: Must Test on Mobile

**This issue ONLY occurs on mobile devices**, particularly on cellular networks. Desktop testing will NOT reproduce the issue.

### Test 1: Network Switch (Most Important)

This is the main scenario that triggers the bug:

1. **Start on WiFi**
   - Open the mobile client app
   - Start a realtime voice call
   - Let the AI start speaking (ask a question that requires a long answer)

2. **Switch to Cellular**
   - While AI is speaking, turn OFF WiFi on your phone
   - Phone will automatically switch to cellular (4G/5G)
   - Wait 2-3 seconds for reconnection

3. **Expected Behavior**
   - ✅ **BEFORE FIX**: AI audio would stop and restart from the beginning
   - ✅ **AFTER FIX**: Brief pause (1-2 seconds), then audio continues smoothly
   - ✅ Console shows: `⚠️ Audio track already connected, skipping duplicate ontrack event`

### Test 2: Movement Test (Cellular)

This simulates real-world mobile usage:

1. Start realtime call on cellular network
2. Walk around while AI is speaking
3. Move far enough to trigger cell tower handoff

**Expected**: Audio continues smoothly, no restarts

### Test 3: Background/Foreground

Test app switching behavior:

1. Start realtime call
2. AI starts speaking
3. Switch to another app (put browser in background)
4. Wait 3-5 seconds
5. Switch back to the app

**Expected**: Audio resumes or continues, no restart from beginning

### Test 4: Stable Connection (Baseline)

Verify normal operation still works:

1. Start realtime call on stable WiFi
2. Stay in one place, don't switch networks
3. Have a conversation with AI

**Expected**: Smooth, continuous audio (should work as before)

---

## Debug Console Logs

Open the browser console (on mobile: use Remote Debugging) to see these logs:

### Normal Flow (No Issues)
```
🎵 Received audio track
✅ Creating new audio element for stream
[AI speaking...]
```

### ICE Reconnection Detected (Fix Working)
```
🎵 Received audio track
✅ Creating new audio element for stream
[AI speaking...]
🎵 Received audio track  ← ontrack fired again!
⚠️ Audio track already connected, skipping duplicate ontrack event  ← FIX IS WORKING!
[AI continues speaking without restart]
```

### Cleanup on Disconnect
```
🔌 Disconnecting...
🧹 Cleaning up audio element
🧹 Cleaning up audio analyser
```

---

## Remote Debugging Setup

To see console logs on mobile:

### iPhone (Safari)
1. On iPhone: Settings → Safari → Advanced → Web Inspector (ON)
2. Connect iPhone to Mac via USB
3. On Mac: Safari → Develop → [Your iPhone] → [Your page]

### Android (Chrome)
1. On Android: Settings → Developer Options → USB Debugging (ON)
2. Connect Android to computer via USB
3. On computer: Chrome → chrome://inspect → Your device

---

## Success Criteria

✅ **Fix is working if**:
- Audio continues smoothly during network switches
- Console shows "skipping duplicate ontrack event" when network changes
- No audio restarts from the beginning
- Clean disconnection with cleanup logs

❌ **Fix is NOT working if**:
- Audio still restarts from beginning during network changes
- No "skipping duplicate ontrack event" log appears
- Multiple "Creating new audio element" logs for same conversation

---

## Rollback Plan

If the fix causes issues:

```bash
# Revert the useWebRTCConnection.ts changes
git checkout HEAD^ src/views/MobileClient/components/AIAssistant/composables/useWebRTCConnection.ts
```

---

## Additional Notes

1. **Why mobile only?**: Desktop WiFi connections are very stable and rarely trigger ICE reconnections

2. **Why cellular testing is important?**: Cellular networks constantly switch towers, change signal strength, and have more variable quality - all triggers for ICE reconnection

3. **Brief pauses are normal**: A 1-2 second pause during network switch is expected WebRTC behavior and is acceptable

4. **Audio restarting is NOT normal**: The stream starting over from the beginning is the bug we fixed

---

## Files Modified

- `src/views/MobileClient/components/AIAssistant/composables/useWebRTCConnection.ts` (~35 lines)
  - Added `audioElement` and `audioAnalyser` ref variables
  - Updated `ontrack` handler with duplicate check and cleanup
  - Updated `cleanup()` function to dispose audio resources

## Documentation

- `docs_archive/REALTIME_AUDIO_RESTART_FIX_NOV_2025.md` - Complete technical analysis
- `CLAUDE.md` - Updated with fix summary

---

**Last Updated**: November 17, 2025

