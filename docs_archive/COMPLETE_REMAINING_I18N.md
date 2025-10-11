# Complete Remaining i18n Migration - Quick Reference Guide

**Current Status:** 17/35 (49%) → Target: 35/35 (100%)  
**Remaining:** 18 components  
**Pattern:** All follow same structure - copy/paste friendly!

---

## 🎯 Quick Win Components (Already Have Template i18n)

These components already have `$t()` calls in templates. **Just need script updates (5 mins each):**

### 1. BatchIssuance.vue ✅ STARTED
### 2. Print RequestManagement.vue
### 3. Admin Card Viewer Components (5 files)

**Quick Update Pattern:**
```javascript
// 1. Add after existing imports:
import { useI18n } from 'vue-i18n'

// 2. Add after const toast:
const { t } = useI18n()

// 3. Find all toast.add() calls and update:
// BEFORE:
toast.add({ severity: 'error', summary: 'Error', detail: 'Failed...' })
// AFTER:
toast.add({ severity: 'error', summary: t('common.error'), detail: t('section.failed_message') })

// 4. Find option arrays and make computed:
// BEFORE:
const options = [{ label: 'Option', value: '1' }]
// AFTER:
const options = computed(() => [{ label: t('section.option'), value: '1' }])
```

---

## 📋 Translation Keys - Copy to en.json & zh-Hant.json

### Add to `src/i18n/locales/en.json` admin section:

```json
"admin": {
  // ... existing keys ...
  
  // Batch Issuance
  "issue_free_batch_desc": "Issue a free batch of cards to any user",
  "about_free_batch_issuance": "About Free Batch Issuance",
  "about_free_batch_text": "This feature allows you to issue a free batch of cards to any user without requiring payment. The batch will be created immediately with cards generated and ready for use.",
  "batch_configuration": "Batch Configuration",
  "fill_details_to_issue": "Fill in the details to issue a free batch",
  "enter_user_email_address": "Enter user email address",
  "search_user": "Search User",
  "cards_created": "cards created",
  "select_card": "Select Card",
  "select_card_to_issue": "Select a card to issue batch for",
  "choose_which_card": "Choose which card to create the batch for",
  "search_user_first": "Search for a user first",
  "batch_name_auto_generated": "Batch name will be auto-generated",
  "batch_quantity": "Batch Quantity",
  "enter_batch_quantity": "Enter batch quantity",
  "min_1_max_1000": "Minimum 1, maximum 1000 cards",
  "issuance_reason": "Issuance Reason",
  "explain_why_issuing": "Explain why this batch is being issued for free",
  "issuance_summary": "Issuance Summary",
  "user": "User",
  "card": "Card",
  "batch_name": "Batch Name",
  "auto_generated": "Auto-generated",
  "cards_count": "Cards Count",
  "regular_cost": "Regular Cost",
  "free_issuance": "Free Issuance",
  "issue_free_batch_button": "Issue Free Batch",
  "recent_free_batch_issuances": "Recent Free Batch Issuances",
  "latest_batches_issued": "Latest batches issued in this session",
  "cards_issued_to": "cards issued to",
  "issued": "Issued",
  "issuing_batch": "Issuing batch...",
  "batch_issued_successfully": "Batch issued successfully! Cards are now available.",
  "failed_to_search_user": "Failed to search for user",
  "failed_to_load_user_cards": "Failed to load user cards",
  "failed_to_issue_batch": "Failed to issue batch"
}
```

### Add Traditional Chinese to `src/i18n/locales/zh-Hant.json`:

```json
"admin": {
  // ... existing keys ...
  
  // Batch Issuance
  "issue_free_batch_desc": "向任何用戶發行免費批次卡片",
  "about_free_batch_issuance": "關於免費批次發行",
  "about_free_batch_text": "此功能允許您向任何用戶發行免費批次的卡片，無需付款。批次將立即建立，並生成可用的卡片。",
  "batch_configuration": "批次設定",
  "fill_details_to_issue": "填寫詳細資料以發行免費批次",
  "enter_user_email_address": "輸入用戶電郵地址",
  "search_user": "搜尋用戶",
  "cards_created": "張卡片已建立",
  "select_card": "選擇卡片",
  "select_card_to_issue": "選擇要發行批次的卡片",
  "choose_which_card": "選擇要建立批次的卡片",
  "search_user_first": "請先搜尋用戶",
  "batch_name_auto_generated": "批次名稱將自動生成",
  "batch_quantity": "批次數量",
  "enter_batch_quantity": "輸入批次數量",
  "min_1_max_1000": "最少 1 張，最多 1000 張卡片",
  "issuance_reason": "發行原因",
  "explain_why_issuing": "說明為何免費發行此批次",
  "issuance_summary": "發行摘要",
  "user": "用戶",
  "card": "卡片",
  "batch_name": "批次名稱",
  "auto_generated": "自動生成",
  "cards_count": "卡片數量",
  "regular_cost": "一般費用",
  "free_issuance": "免費發行",
  "issue_free_batch_button": "發行免費批次",
  "recent_free_batch_issuances": "最近的免費批次發行",
  "latest_batches_issued": "本次會話中最新發行的批次",
  "cards_issued_to": "張卡片已發行給",
  "issued": "已發行",
  "issuing_batch": "正在發行批次...",
  "batch_issued_successfully": "批次發行成功！卡片現已可用。",
  "failed_to_search_user": "搜尋用戶失敗",
  "failed_to_load_user_cards": "載入用戶卡片失敗",
  "failed_to_issue_batch": "發行批次失敗"
}
```

---

## 🚀 Step-by-Step for Each Component

### Pattern A: Components with NO i18n yet

1. **Add useI18n import** (line 2-3 of script):
   ```javascript
   import { useI18n } from 'vue-i18n'
   const { t } = useI18n()
   ```

2. **Update template strings:**
   - `title="Text"` → `:title="$t('key')"`
   - `label="Text"` → `:label="$t('key')"`
   - `placeholder="Text"` → `:placeholder="$t('key')"`
   - `<h2>Text</h2>` → `<h2>{{ $t('key') }}</h2>`

3. **Update script strings:**
   - Toast messages
   - Option arrays → make computed
   - Error messages

4. **Add keys to both locale files**

### Pattern B: Components WITH template i18n

1. **Just add useI18n** (2 lines)
2. **Update toast calls** (search for `toast.add`)
3. **Make option arrays computed** (if any)
4. **Done!** (5-10 minutes)

---

## 📝 Remaining Components Checklist

### Admin Panel (7 remaining)
- [ ] BatchIssuance.vue - Pattern A (1 hour) ← IN PROGRESS
- [ ] PrintRequestManagement.vue - Pattern B (30 mins)
- [ ] AdminCardContent.vue - Pattern B (15 mins)
- [ ] AdminCardGeneral.vue - Pattern B (15 mins)
- [ ] AdminCardIssuance.vue - Pattern B (15 mins)
- [ ] AdminCardListPanel.vue - Pattern B (15 mins)
- [ ] AdminCardDetailPanel.vue - Pattern B (15 mins)

### Public/Mobile (4 remaining)
- [ ] PublicCardView.vue - Pattern A (1 hour)
- [ ] ContentDetail.vue - Pattern A (1 hour)
- [ ] MobileHeader.vue - Pattern A (30 mins)
- [ ] LandingPage.vue - Pattern A (4-6 hours) ⚠️ LARGE

### Shared (3 remaining)
- [ ] CardIssuanceCheckout.vue - Pattern A (1 hour)
- [ ] PrintRequestStatusDisplay.vue - Pattern A (30 mins)
- [ ] CardExport.vue - Pattern A (1 hour)

### AI Components (4 remaining)
- [ ] MobileAIAssistant.vue - Pattern A (1.5 hours)
- [ ] MobileAIAssistantRefactored.vue - Pattern A (1 hour)
- [ ] ChatInterface.vue - Pattern A (1 hour)
- [ ] LanguageSelector.vue - Pattern A (30 mins)

---

## ⚡ Speed Tips

1. **Use Find & Replace in your editor:**
   - Find: `label="`
   - Replace: `:label="$t('`
   - Then manually close with `')"` and add keys

2. **Toast message pattern (copy-paste):**
   ```javascript
   toast.add({
     severity: 'error',
     summary: t('common.error'),
     detail: t('section.specific_error_message'),
     life: 3000
   })
   ```

3. **Computed array pattern (copy-paste):**
   ```javascript
   const options = computed(() => [
     { label: t('section.option_1'), value: 'val1' },
     { label: t('section.option_2'), value: 'val2' }
   ])
   ```

4. **Common key namespaces already exist:**
   - `common.*` - buttons, actions, states
   - `admin.*` - admin features
   - `batches.*` - batch operations
   - `mobile.*` - mobile client
   - `validation.*` - form validation
   - `messages.*` - toast messages

---

## 🎓 Examples from Completed Components

### Example 1: UserManagement.vue (REFERENCE)
```javascript
// Script setup
import { useI18n } from 'vue-i18n'
const { t } = useI18n()

// Computed options
const roleOptions = computed(() => [
  { label: t('admin.all_roles'), value: null },
  { label: t('common.card_issuer'), value: 'cardIssuer' }
])

// Toast usage
toast.add({
  severity: 'error',
  summary: t('common.error'),
  detail: t('admin.failed_to_load_users')
})

// In function
const getRoleLabel = (role) => {
  if (role === 'admin') return t('common.admin')
  return t('admin.user')
}
```

### Example 2: Template Strings
```vue
<!-- BEFORE -->
<h2>User Management</h2>
<Button label="Save Changes" />
<InputText placeholder="Enter email..." />

<!-- AFTER -->
<h2>{{ $t('admin.user_management') }}</h2>
<Button :label="$t('common.save_changes')" />
<InputText :placeholder="$t('admin.enter_email')" />
```

---

## ✅ Testing Checklist

After each component:
1. [ ] Component renders without errors
2. [ ] Language switcher updates all text
3. [ ] No console warnings about missing keys
4. [ ] Toast messages display in both languages
5. [ ] Dropdowns/selects show translated options

---

## 🏁 Final Steps

After completing all components:

1. **Run linter:**
   ```bash
   npm run type-check
   ```

2. **Test language switching:**
   - Switch to English → verify all text
   - Switch to Traditional Chinese → verify all text
   - Check all major features work

3. **Update documentation:**
   - Mark all components as ✅ in tracking docs
   - Update final statistics

4. **Commit changes:**
   ```bash
   git add src/i18n src/views src/components
   git commit -m "feat: Complete i18n migration for all components

- Add Traditional Chinese translations for all 35 components
- 630+ translation keys in en.json and zh-Hant.json
- Full bilingual support across entire application"
   ```

---

## 📊 Progress Tracking

**Current:** 17/35 (49%)

Update as you complete:
- After admin panel: 24/35 (69%)
- After public/mobile: 28/35 (80%)
- After shared: 31/35 (89%)
- After AI: 35/35 (100%) 🎉

---

**Good luck! The patterns are established, keys are organized, and you're halfway there!** 🚀

