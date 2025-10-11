# i18n Complete Implementation Script
**Target: 100% Coverage (35/35 components)**

## ✅ Keys Added to en.json (Complete)

All translation keys have been added to `src/i18n/locales/en.json`:
- Admin print request management (+25 keys)
- Mobile/public components (+11 keys)  
- Landing page (+30 keys)
- Checkout (+13 keys)
- Print status (+10 keys)

**Total: ~700+ keys in English**

---

## ⏳ Traditional Chinese Keys - TO ADD

Copy this entire block to `src/i18n/locales/zh-Hant.json` after the import section (before the closing `}`):

```json
  "landing": {
    "hero_title": "創建互動式數碼紀念品",
    "hero_subtitle": "將您的展覽和景點轉化為引人入勝的數碼體驗",
    "get_started": "開始使用",
    "learn_more": "了解更多",
    "features": "功能特色",
    "how_it_works": "運作方式",
    "pricing": "價格",
    "testimonials": "用戶評價",
    "faq": "常見問題",
    "contact_us": "聯絡我們",
    "feature_1_title": "互動二維碼卡片",
    "feature_1_desc": "實體卡片配備二維碼，連結至豐富的數碼內容",
    "feature_2_title": "AI 智能助手",
    "feature_2_desc": "支援多種語言的語音AI導遊",
    "feature_3_title": "簡易管理",
    "feature_3_desc": "簡單的儀表板來創建和管理您的卡片",
    "feature_4_title": "專業印刷",
    "feature_4_desc": "高品質實體卡片，全球送貨",
    "step_1": "創建您的卡片",
    "step_1_desc": "使用照片和內容設計您的數碼紀念品",
    "step_2": "發行批次",
    "step_2_desc": "生成具有唯一二維碼的卡片批次",
    "step_3": "印刷與分發",
    "step_3_desc": "訂購實體卡片並分發給訪客",
    "price_per_card": "每張卡片 $2",
    "no_subscription": "無月費訂閱",
    "unlimited_scans": "無限次掃描",
    "for_museums": "完美適合博物館",
    "for_attractions": "適合旅遊景點",
    "for_exhibitions": "理想的展覽選擇"
  },

  "checkout": {
    "checkout": "結帳",
    "batch_checkout": "批次結帳",
    "payment_details": "付款詳情",
    "order_summary": "訂單摘要",
    "batch_quantity": "批次數量",
    "price_per_card": "每張卡片價格",
    "subtotal": "小計",
    "tax": "稅金",
    "total_amount": "總金額",
    "proceed_to_payment": "繼續付款",
    "processing_payment": "正在處理付款...",
    "payment_successful": "付款成功",
    "payment_failed": "付款失敗",
    "return_to_dashboard": "返回儀表板",
    "secure_payment": "透過 Stripe 安全付款"
  },

  "print": {
    "print_request": "列印請求",
    "request_print": "請求列印",
    "print_status": "列印狀態",
    "pending": "待處理",
    "in_production": "生產中",
    "shipped": "已發貨",
    "delivered": "已送達",
    "cancelled": "已取消",
    "request_submitted": "請求已提交",
    "request_cancelled": "請求已取消",
    "tracking_number": "追蹤編號",
    "estimated_delivery": "預計送達時間"
  }
```

---

## 🚀 Component Migration Checklist

### Phase 1: Admin Panel (7 components)

#### 1. ✅ BatchIssuance.vue - IN PROGRESS
**Status:** Title/description updated, template needs completion  
**Reference:** `BATCH_ISSUANCE_COMPLETION.md` (line-by-line guide)  
**Time:** 30 mins remaining

**Quick Steps:**
1. Complete template replacements (sections 1-10 in guide)
2. Add `import { useI18n } from 'vue-i18n'`
3. Add `const { t } = useI18n()` after const toast
4. Update toast messages to use `t()`

#### 2. PrintRequestManagement.vue
**Pattern:** Full migration  
**Time:** 2 hours

**Steps:**
1. Add useI18n import
2. Template strings:
   - Replace title="Print Request Management" → `:title="$t('admin.print_request_management')"`
   - Replace all labels with `:label="$t('admin.*')"`
3. Script:
   - Update toast messages
   - Make status options computed:
   ```javascript
   const statusOptions = computed(() => [
     { label: t('print.pending'), value: 'PENDING' },
     { label: t('print.in_production'), value: 'IN_PRODUCTION' },
     { label: t('print.shipped'), value: 'SHIPPED' },
     { label: t('print.delivered'), value: 'DELIVERED' },
     { label: t('print.cancelled'), value: 'CANCELLED' }
   ])
   ```

#### 3-7. Admin Card Viewer Components (Quick Wins - 30 mins each)
- AdminCardContent.vue
- AdminCardGeneral.vue
- AdminCardIssuance.vue
- AdminCardListPanel.vue
- AdminCardDetailPanel.vue

**Pattern for all 5:** Most likely already have template i18n
1. Add `import { useI18n } from 'vue-i18n'`
2. Add `const { t } = useI18n()`
3. Update toast messages only
4. Test with language switcher

---

### Phase 2: Public/Mobile (4 components)

#### 8. PublicCardView.vue
**Time:** 1 hour

**Template:**
```vue
<!-- Loading state -->
<div v-if="loading">
  <p>{{ $t('mobile.loading_card') }}</p>
</div>

<!-- Error state -->
<div v-if="error">
  <h2>{{ $t('mobile.card_not_found') }}</h2>
  <p>{{ $t('mobile.invalid_card') }}</p>
</div>
```

**Script:**
```javascript
import { useI18n } from 'vue-i18n'
const { t } = useI18n()

// Toast messages
toast.add({
  severity: 'error',
  summary: t('common.error'),
  detail: t('mobile.error_loading_card')
})
```

#### 9. ContentDetail.vue
**Time:** 1 hour

**Keys to use:**
- `mobile.content_details`
- `mobile.back_to_list`
- `mobile.no_sub_items`
- `mobile.view_details`

**Pattern:** Same as PublicCardView

#### 10. MobileHeader.vue
**Time:** 30 mins

**Simple component - just navigation labels**

#### 11. LandingPage.vue ⚠️ LARGE
**Time:** 4-6 hours

**All keys ready in `landing.*` section**

**Sections to migrate:**
1. Hero section (title, subtitle, CTA buttons)
2. Features section (4 feature cards)
3. How it works (3 steps)
4. Pricing section
5. Use cases section
6. CTA section

**Pattern:**
```vue
<h1>{{ $t('landing.hero_title') }}</h1>
<p>{{ $t('landing.hero_subtitle') }}</p>
<Button :label="$t('landing.get_started')" />
```

---

### Phase 3: Shared Components (3 components)

#### 12. CardIssuanceCheckout.vue
**Time:** 1 hour

**Use `checkout.*` keys:**
```vue
<h2>{{ $t('checkout.batch_checkout') }}</h2>
<div class="summary">
  <p>{{ $t('checkout.order_summary') }}</p>
  <div>
    <span>{{ $t('checkout.batch_quantity') }}:</span>
    <span>{{ quantity }}</span>
  </div>
  <div>
    <span>{{ $t('checkout.price_per_card') }}:</span>
    <span>${{ price }}</span>
  </div>
  <div>
    <span>{{ $t('checkout.total_amount') }}:</span>
    <span>${{ total }}</span>
  </div>
</div>
<Button :label="$t('checkout.proceed_to_payment')" />
```

#### 13. PrintRequestStatusDisplay.vue
**Time:** 30 mins

**Use `print.*` keys for status badges:**
```javascript
const getStatusLabel = (status) => {
  const statusMap = {
    'PENDING': t('print.pending'),
    'IN_PRODUCTION': t('print.in_production'),
    'SHIPPED': t('print.shipped'),
    'DELIVERED': t('print.delivered'),
    'CANCELLED': t('print.cancelled')
  }
  return statusMap[status] || status
}
```

#### 14. CardExport.vue
**Time:** 1 hour

**Keys already exist in `import.*` section - reuse them**

---

### Phase 4: AI Components (4 components)

#### 15-18. AI Components
- MobileAIAssistant.vue
- MobileAIAssistantRefactored.vue
- ChatInterface.vue
- LanguageSelector.vue (AI-specific)

**All keys already exist in `mobile.*` section!**

**Quick pattern:**
1. Add useI18n import
2. Replace hardcoded strings with existing keys:
   - `mobile.ai_assistant`
   - `mobile.language_selection`
   - `mobile.select_language`
   - `mobile.type_message`
   - `mobile.hold_to_record`
   - `mobile.tap_to_hear`
   - `mobile.chat_mode`
   - `mobile.realtime_mode`
   - `mobile.connecting`
   - `mobile.connected`

**Time:** 30 mins each = 2 hours total

---

## ⚡ Speed Tips

### 1. Use Find & Replace (VS Code)
```
Find: placeholder="
Replace: :placeholder="$t('
```
Then manually add closing `)"`

### 2. Toast Pattern (Copy-Paste)
```javascript
toast.add({
  severity: 'error',
  summary: t('common.error'),
  detail: t('section.error_message')
})
```

### 3. Computed Options Pattern
```javascript
const options = computed(() => [
  { label: t('section.option1'), value: 'val1' },
  { label: t('section.option2'), value: 'val2' }
])
```

### 4. Test After Each Component
```bash
# Start dev server
npm run dev

# Switch languages and verify
# - All text updates
# - No console warnings
# - Toast messages work
```

---

## ✅ Final Checklist

After completing all components:

- [ ] All 35 components migrated
- [ ] No missing key warnings in console
- [ ] Language switcher works everywhere
- [ ] Toast messages in both languages
- [ ] Dropdowns show translated options
- [ ] Form validation messages translated
- [ ] Run `npm run type-check` (no errors)
- [ ] Test all major user flows
- [ ] Mobile responsive verified

---

## 📊 Progress Tracker

Update as you complete:

| Phase | Component | Status | Time |
|-------|-----------|--------|------|
| Admin | BatchIssuance | 🟡 In Progress | 30m |
| Admin | PrintRequestManagement | ⏳ | 2h |
| Admin | AdminCardContent | ⏳ | 30m |
| Admin | AdminCardGeneral | ⏳ | 30m |
| Admin | AdminCardIssuance | ⏳ | 30m |
| Admin | AdminCardListPanel | ⏳ | 30m |
| Admin | AdminCardDetailPanel | ⏳ | 30m |
| Public | PublicCardView | ⏳ | 1h |
| Public | ContentDetail | ⏳ | 1h |
| Public | MobileHeader | ⏳ | 30m |
| Public | LandingPage | ⏳ | 4-6h |
| Shared | CardIssuanceCheckout | ⏳ | 1h |
| Shared | PrintRequestStatusDisplay | ⏳ | 30m |
| Shared | CardExport | ⏳ | 1h |
| AI | MobileAIAssistant | ⏳ | 30m |
| AI | MobileAIAssistantRefactored | ⏳ | 30m |
| AI | ChatInterface | ⏳ | 30m |
| AI | LanguageSelector | ⏳ | 30m |

**Total Estimated Time:** 12-16 hours

---

## 🎯 Recommended Order

1. **Admin quick wins** (3 hours) → 69% complete
   - Complete BatchIssuance
   - All 5 admin card viewer components
   
2. **Public/Mobile core** (3 hours) → 80% complete
   - PublicCardView, ContentDetail, MobileHeader
   - Skip LandingPage initially

3. **Shared** (2.5 hours) → 89% complete
   - All 3 shared components

4. **AI** (2 hours) → 100% core complete
   - All 4 AI components

5. **LandingPage** (4-6 hours) → 100% complete
   - Marketing content (can be done independently)

---

## 🎉 Success!

After completion:
- **35/35 components** fully bilingual
- **700+ translation keys** in English & Traditional Chinese
- **Complete application** internationalized
- **8 additional languages** ready for translation

**Commit message:**
```bash
git add .
git commit -m "feat: Complete i18n implementation for all 35 components

- Full English and Traditional Chinese support
- 700+ translation keys across 11 namespaces
- All user-facing text internationalized
- Language switcher functional throughout app"
```

---

**You've got this! Follow the patterns, test as you go, and celebrate at 100%! 🚀🌐**

