# Remaining Admin Components - Quick Migration Guide

## Status
- ✅ BatchIssuance.vue - 100% Complete
- ✅ AdminCardGeneral.vue - 100% Complete  
- ⏳ 4 components remaining (quick migrations)

---

## Quick Migration Checklist

### 1. AdminCardContent.vue (15-20 mins)

**Script Updates:**
```javascript
// Add after imports
import { useI18n } from 'vue-i18n'
const { t } = useI18n()
```

**Template Updates:**
```vue
<!-- Line 11 -->
<h3>{{ $t('content.no_content_items') }}</h3>
<p>{{ $t('content.no_content_items_desc') }}</p>

<!-- Line 45 -->
<span>{{ $t('dashboard.ai_knowledge_base') }}</span>

<!-- Line 58 -->
<p>{{ $t('content.no_sub_items') }}</p>
```

**Toast Updates (if any):**
Check for toast.add() calls and update to use t()

---

### 2. AdminCardIssuance.vue (15-20 mins)

**Pattern:** Same as AdminCardContent
- Add useI18n import
- Update labels: "Total Batches", "Cards Issued", "QR Codes Generated"
- Update status labels
- Update toast messages (if any)

**Keys to use:**
- `batches.total_batches`
- `batches.cards_issued`  
- `batches.qr_codes_generated`
- `batches.no_batches`

---

### 3. AdminCardListPanel.vue (15-20 mins)

**Pattern:** List panel with search/filter
- Add useI18n import
- Update search placeholder
- Update filter labels
- Update empty state
- Update toast messages

**Keys to use:**
- `common.search`
- `common.filter`
- `dashboard.no_cards_found`

---

### 4. AdminCardDetailPanel.vue (15-20 mins)

**Pattern:** Detail panel with tabs
- Add useI18n import
- Update tab labels
- Update section headers
- Update toast messages

**Keys to use:**
- `dashboard.general`
- `dashboard.content`
- `dashboard.batches`
- `dashboard.qr_access`

---

## Standard Pattern for All Components

### Step 1: Add useI18n (2 mins)
```javascript
<script setup>
import { useI18n } from 'vue-i18n'
// ...other imports

const { t } = useI18n()
// ...rest of code
```

### Step 2: Update Template Strings (10 mins)
- Find all hardcoded text
- Replace with $t('key')
- Use existing keys from dashboard.*, content.*, batches.*, common.*

### Step 3: Update Toast Messages (3 mins)
```javascript
// Find all toast.add() calls
toast.add({
  severity: 'error',
  summary: t('common.error'),
  detail: t('section.error_message')
})
```

### Step 4: Test (5 mins)
- npm run dev
- Switch language
- Verify all text updates
- Check for missing key warnings

---

## Available Translation Keys

All these keys are already in en.json and zh-Hant.json:

### Common
- `common.search`, `common.filter`, `common.yes`, `common.no`
- `common.created_at`, `common.updated_at`, `common.description`
- `common.loading`, `common.error`, `common.success`

### Dashboard
- `dashboard.card_name`, `dashboard.card_image`, `dashboard.no_image`
- `dashboard.qr_position`, `dashboard.ai_enabled`
- `dashboard.ai_instruction`, `dashboard.ai_knowledge_base`
- `dashboard.no_description`, `dashboard.general`, `dashboard.content`

### Content
- `content.no_content_items`, `content.no_content_items_desc`
- `content.no_sub_items`, `content.content_item`, `content.sub_item`

### Batches
- `batches.total_batches`, `batches.cards_issued`
- `batches.qr_codes_generated`, `batches.no_batches`
- `batches.batch_name`, `batches.quantity`

---

## Estimated Time

| Component | Time | Status |
|-----------|------|--------|
| AdminCardGeneral | ✅ | Complete |
| AdminCardContent | 20m | Pending |
| AdminCardIssuance | 20m | Pending |
| AdminCardListPanel | 20m | Pending |
| AdminCardDetailPanel | 20m | Pending |
| **Total** | **1h 20m** | **4 remaining** |

---

## After Completion

Admin Panel will be:
- 10/12 components complete (83%)
- Only PrintRequestManagement left (2 hours)

Then move to:
- Public/Mobile (4 components)
- Shared (3 components)  
- AI (4 components)

---

## Quick Commands

```bash
# Start dev server
npm run dev

# Type check
npm run type-check

# Test in browser
# Switch language using LanguageSwitcher
# Verify all admin panel features
```

---

**These are straightforward migrations following the established pattern!**

