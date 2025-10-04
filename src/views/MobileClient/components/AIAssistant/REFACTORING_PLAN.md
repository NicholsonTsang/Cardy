# MobileAIAssistant Refactoring Plan

**Current State**: 2,975 lines in single file  
**Goal**: Break down into smaller, manageable components  
**Status**: 🚧 IN PROGRESS

---

## 📊 Current File Breakdown

| Section | Lines | Complexity |
|---------|-------|------------|
| Template | ~310 | High |
| Script (Logic) | ~1,450 | Very High |
| Styles | ~1,215 | Medium |
| **TOTAL** | **~2,975** | **Very High** |

---

## 🎯 Refactoring Strategy

### Phase 1: Extract Composables (Business Logic) ✅ STARTED
- [x] `useRealtimeConnection.ts` - Realtime WebSocket logic (~400 lines)
- [ ] `useChatCompletion.ts` - Chat completion logic (~300 lines)
- [ ] `useVoiceRecording.ts` - Voice recording logic (~200 lines)
- [ ] `useCostSafeguards.ts` - Inactivity timers, visibility handlers (~150 lines)
- [ ] `useInactivityTimer.ts` - Timer management (~100 lines)

### Phase 2: Extract UI Components
- [ ] `LanguageSelector.vue` - Language selection screen (~150 lines)
- [ ] `ChatInterface.vue` - Chat completion UI (~400 lines)
- [ ] `RealtimeInterface.vue` - Real-time call UI (~300 lines)
- [ ] `MessageBubble.vue` - Individual message component (~100 lines)
- [ ] `VoiceInputButton.vue` - Voice recording button (~150 lines)
- [ ] `AIAssistantModal.vue` - Modal wrapper (~200 lines)

### Phase 3: Refactor Main Component
- [ ] Integrate all composables
- [ ] Use new sub-components
- [ ] Clean up prop drilling
- [ ] Add proper TypeScript types

---

## 📁 Proposed File Structure

```
src/views/MobileClient/components/AIAssistant/
├── MobileAIAssistant.vue (Main component - ~300 lines)
├── composables/
│   ├── useRealtimeConnection.ts ✅
│   ├── useChatCompletion.ts
│   ├── useVoiceRecording.ts
│   ├── useCostSafeguards.ts
│   └── useInactivityTimer.ts
├── components/
│   ├── LanguageSelector.vue
│   ├── ChatInterface.vue
│   ├── RealtimeInterface.vue
│   ├── MessageBubble.vue
│   ├── VoiceInputButton.vue
│   └── AIAssistantModal.vue
├── types/
│   └── index.ts (Shared TypeScript types)
└── utils/
    └── audioProcessing.ts (Audio conversion utilities)
```

---

## ⏱️ Estimated Timeline

| Phase | Time | Priority |
|-------|------|----------|
| Phase 1 | 4-6 hours | 🔴 High |
| Phase 2 | 6-8 hours | 🟡 Medium |
| Phase 3 | 2-3 hours | 🟢 Low |
| **Total** | **12-17 hours** | - |

---

## 🚨 Risks & Considerations

### High Risk
1. **Breaking functionality** - Complex state management
2. **Type errors** - Many interconnected refs
3. **Event handling** - WebSocket, audio, timers
4. **CSS specificity** - Scoped styles might break

### Mitigation
1. ✅ Keep original file as backup
2. ✅ Test each phase incrementally
3. ✅ Use TypeScript for type safety
4. ✅ Comprehensive console logging

---

## 🎯 Immediate Recommendation

Given the complexity and time required, I recommend:

### Option A: **Incremental Refactoring** (Recommended)
- Keep current file working
- Extract one composable at a time
- Test after each extraction
- Merge when stable

**Pros**: Safe, testable, reversible  
**Cons**: Takes longer

### Option B: **Complete Rewrite**
- Build entire new structure from scratch
- Migrate piece by piece
- Switch when complete

**Pros**: Clean slate, best practices  
**Cons**: Risky, time-consuming, might miss edge cases

### Option C: **Defer Refactoring**
- Keep current file as-is
- Focus on new features/bugs
- Refactor when blocking new work

**Pros**: No risk, focus on features  
**Cons**: Technical debt grows

---

## 📝 What I've Done So Far

✅ **Created**:
- `AIAssistant/composables/useRealtimeConnection.ts`
  - Extracted all realtime WebSocket logic
  - ~400 lines of business logic
  - Properly typed with TypeScript
  - Includes all safety mechanisms (duplicate audio fix, cost safeguards)

---

## 🤔 Next Steps - Your Decision

**Question**: How would you like to proceed?

1. **Continue full refactoring** (12-17 hours of work)
   - I'll systematically break down the entire component
   - Test at each step
   - Complete when done

2. **Extract just a few key pieces** (2-3 hours)
   - Extract 1-2 more composables
   - Extract 1-2 UI components
   - Leave rest as-is for now

3. **Stop here and test what we have** (0 hours)
   - Keep current `MobileAIAssistant.vue` as-is
   - Use the new `useRealtimeConnection` composable if needed later
   - Focus on other priorities

**My Recommendation**: **Option 2** - Extract just the most critical pieces (ChatCompletion logic and LanguageSelector component), which will reduce the file to ~2000 lines and make it more manageable, while not requiring a massive time investment.

---

## 💡 Alternative: Keep As-Is With Better Organization

If refactoring is too time-consuming, we could instead:
- ✅ Add comprehensive comments to current file
- ✅ Group related functions with markers
- ✅ Add a table of contents at top of file
- ✅ Improve variable naming

**Time**: ~30 minutes  
**Benefit**: Easier to navigate without restructuring

---

**Status**: Waiting for your decision on how to proceed.

