# i18n Migration - In Progress Status
**Last Updated:** October 7, 2025  
**Current Session Progress:** 15/35 components (43%)

## ✅ Completed in This Session

### UserManagement.vue - COMPLETE ✨
- Added `useI18n` import
- Converted all toast messages to use `t()`
- Made roleOptions and roleChangeOptions computed with translations
- Updated getRoleLabel function to use translations
- Added missing translation keys to both en.json and zh-Hant.json:
  - `admin.all_roles`
  - `admin.issued`
  - `admin.failed_to_load_users`
  - `admin.user_role_updated_successfully`
  - `admin.failed_to_update_user_role`

---

## 📋 Remaining Components (20 components)

### 🔴 HIGH PRIORITY - Admin Panel (9 remaining)

1. **BatchManagement.vue**
   - Estimated time: 1.5 hours
   - Keys needed: ~20-25 keys
   - Main features: Batch listing, filtering, status updates

2. **HistoryLogs.vue**
   - Estimated time: 1.5 hours
   - Keys needed: ~15-20 keys
   - Main features: Operations log, filtering, date range

3. **BatchIssuance.vue**
   - Estimated time: 1 hour
   - Keys needed: ~15 keys
   - Main features: Free batch creation dialog

4. **PrintRequestManagement.vue**
   - Estimated time: 2 hours
   - Keys needed: ~25-30 keys
   - Main features: Print request queue, status management

5. **AdminCardContent.vue**
   - Estimated time: 30 mins
   - Keys needed: ~10 keys
   - Main features: Read-only content viewer

6. **AdminCardGeneral.vue**
   - Estimated time: 30 mins
   - Keys needed: ~10 keys
   - Main features: Card details display

7. **AdminCardIssuance.vue**
   - Estimated time: 45 mins
   - Keys needed: ~12 keys
   - Main features: Batch issuance viewer

8. **AdminCardListPanel.vue**
   - Estimated time: 45 mins
   - Keys needed: ~12 keys
   - Main features: Admin card list

9. **AdminCardDetailPanel.vue**
   - Estimated time: 30 mins
   - Keys needed: ~8 keys
   - Main features: Card detail tabs

**Admin Panel Total:** ~8.5 hours, ~140 keys

---

### 🔴 HIGH PRIORITY - Public/Mobile (4 components)

1. **PublicCardView.vue**
   - Estimated time: 1 hour
   - Keys needed: ~15 keys
   - Main features: Mobile card viewer, loading/error states

2. **ContentDetail.vue**
   - Estimated time: 1 hour
   - Keys needed: ~18 keys
   - Main features: Content detail view, sub-items

3. **MobileHeader.vue**
   - Estimated time: 30 mins
   - Keys needed: ~5 keys
   - Main features: Mobile navigation header

4. **LandingPage.vue** ⚠️ LARGE
   - Estimated time: 4-6 hours
   - Keys needed: ~80-100 keys
   - Main features: Hero section, features, demo cards, CTAs
   - Note: Extensive marketing copy

**Public/Mobile Total:** ~6.5-8.5 hours, ~118-138 keys

---

### 🟢 LOW PRIORITY - Shared (3 components)

1. **CardIssuanceCheckout.vue**
   - Estimated time: 1 hour
   - Keys needed: ~15 keys
   - Main features: Stripe checkout modal

2. **PrintRequestStatusDisplay.vue**
   - Estimated time: 30 mins
   - Keys needed: ~8 keys
   - Main features: Status badge component

3. **CardExport.vue**
   - Estimated time: 1 hour
   - Keys needed: ~12 keys
   - Main features: Export dialog

**Shared Total:** ~2.5 hours, ~35 keys

---

### 🟡 MEDIUM PRIORITY - AI Components (4 components)

1. **MobileAIAssistant.vue**
   - Estimated time: 1.5 hours
   - Keys needed: ~20 keys
   - Main features: AI modal, mode switching

2. **MobileAIAssistantRefactored.vue**
   - Estimated time: 1 hour
   - Keys needed: ~15 keys
   - Main features: Refactored AI architecture

3. **ChatInterface.vue**
   - Estimated time: 1 hour
   - Keys needed: ~15 keys
   - Main features: Chat UI, messages

4. **LanguageSelector.vue**
   - Estimated time: 30 mins
   - Keys needed: ~8 keys
   - Main features: Language selection screen

**AI Components Total:** ~4 hours, ~58 keys

---

## 📊 Total Remaining Effort

| Priority | Components | Hours | Keys |
|----------|-----------|-------|------|
| High (Admin) | 9 | 8.5 | ~140 |
| High (Public) | 4 | 6.5-8.5 | ~118-138 |
| Low (Shared) | 3 | 2.5 | ~35 |
| Medium (AI) | 4 | 4 | ~58 |
| **TOTAL** | **20** | **21.5-23.5** | **~351-371** |

---

## 🎯 Recommended Next Steps

### Option A: Continue High-Priority Components (Recommended)
Focus on admin panel and public-facing components for maximum business impact:
1. Complete remaining 9 admin panel components
2. Complete 4 public/mobile components
3. Defer AI and shared components

**Time:** ~15-17 hours  
**Impact:** Complete admin panel + public experience

### Option B: Strategic Completion
Complete all components systematically:
1. Admin panel (9 components)
2. Public/Mobile (4 components)
3. Shared (3 components)
4. AI (4 components)

**Time:** ~21.5-23.5 hours  
**Impact:** Full i18n coverage

### Option C: Defer AI Components
Complete everything except AI:
1. Admin panel (9 components)
2. Public/Mobile (4 components)
3. Shared (3 components)

**Time:** ~17.5-19.5 hours  
**Impact:** 95% coverage (AI can be experimental)

---

## 📝 Migration Pattern (for remaining components)

### Standard Steps:
1. Import `useI18n` from 'vue-i18n'
2. Initialize `const { t } = useI18n()`
3. Replace template strings: `label="Text"` → `:label="$t('key')"`
4. Replace script strings: `'Text'` → `t('key')`
5. Make options computed if they contain labels
6. Update toast messages
7. Add keys to en.json
8. Add Traditional Chinese to zh-Hant.json
9. Lint and verify

### Common Patterns:
```javascript
// Before
const options = [
  { label: 'Option 1', value: 'opt1' },
  { label: 'Option 2', value: 'opt2' }
]

// After
const options = computed(() => [
  { label: t('section.option_1'), value: 'opt1' },
  { label: t('section.option_2'), value: 'opt2' }
])
```

```javascript
// Before
toast.add({
  severity: 'error',
  summary: 'Error',
  detail: 'Failed to load data'
})

// After
toast.add({
  severity: 'error',
  summary: t('common.error'),
  detail: t('section.failed_to_load_data')
})
```

---

## 🔧 Tools & Resources

### Key Files:
- **Translation Files:**
  - `src/i18n/locales/en.json` (~620+ keys)
  - `src/i18n/locales/zh-Hant.json` (~620+ keys)
  
### Helper Commands:
```bash
# Check for hardcoded strings in a component
grep -E "(label=\"[A-Z]|placeholder=\"[A-Z]|>[A-Z][a-z]+ )" file.vue

# Count $t() calls in template
grep -c '\$t(' file.vue

# Count t() calls in script
grep -c " t('" file.vue

# Verify useI18n import
grep -c 'useI18n' file.vue
```

---

## 💡 Efficiency Tips

1. **Batch add keys:** Add all keys for a component to both en.json and zh-Hant.json before starting edits
2. **Template first:** Update template strings before script strings
3. **Use search-replace:** Leverage editor's find-replace for common patterns
4. **Test incrementally:** Verify each component works after migration
5. **Commit frequently:** Save progress after each component

---

## 📈 Progress Tracking

- [x] Auth & Core (5 components) - 100%
- [x] Card Issuer Dashboard (7 components) - 100%
- [x] Admin Dashboard (3 components) - 23%
  - [x] AdminDashboard.vue
  - [x] UserCardsView.vue
  - [x] UserManagement.vue ✨ NEW
  - [ ] BatchManagement.vue
  - [ ] HistoryLogs.vue
  - [ ] BatchIssuance.vue
  - [ ] PrintRequestManagement.vue
  - [ ] Admin card viewer components (5)
- [ ] Public/Mobile (4 components) - 0%
- [ ] Shared (3 components) - 0%
- [ ] AI Components (4 components) - 0%

**Overall:** 15/35 (43%)

---

**Next Action:** Continue with BatchManagement.vue or request user decision on prioritization.

