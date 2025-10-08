# BatchIssuance.vue - Complete i18n Migration Template

## Status
- ✅ Keys added to en.json and zh-Hant.json
- ✅ Title and description updated
- ⏳ Template needs full migration
- ⏳ Script needs useI18n addition

---

## Template Replacements Needed

### Section 1: Form Headers & Labels
```vue
<!-- BEFORE -->
<h2 class="text-lg font-semibold text-slate-900">Batch Configuration</h2>
<p class="text-sm text-slate-600 mt-1">Fill in the details to issue a free batch</p>

<!-- AFTER -->
<h2 class="text-lg font-semibold text-slate-900">{{ $t('admin.batch_configuration') }}</h2>
<p class="text-sm text-slate-600 mt-1">{{ $t('admin.fill_details_to_issue') }}</p>
```

### Section 2: User Email Field
```vue
<!-- BEFORE -->
<label class="block text-sm font-medium text-slate-700">
  User Email <span class="text-red-500">*</span>
</label>
<InputText placeholder="Enter user email address" ... />
<Button label="Search User" ... />

<!-- AFTER -->
<label class="block text-sm font-medium text-slate-700">
  {{ $t('common.email') }} <span class="text-red-500">*</span>
</label>
<InputText :placeholder="$t('admin.enter_user_email_address')" ... />
<Button :label="$t('admin.search_user')" ... />
```

### Section 3: User Found Display
```vue
<!-- BEFORE -->
<p class="text-sm font-medium text-green-900">User Found</p>
<p class="text-xs text-green-600 mt-1">
  {{ selectedUser.cards_count || 0 }} cards created
</p>

<!-- AFTER -->
<p class="text-sm font-medium text-green-900">{{ $t('admin.user_found') }}</p>
<p class="text-xs text-green-600 mt-1">
  {{ selectedUser.cards_count || 0 }} {{ $t('admin.cards_created') }}
</p>
```

### Section 4: Card Selection
```vue
<!-- BEFORE -->
<label class="block text-sm font-medium text-slate-700">
  Select Card <span class="text-red-500">*</span>
</label>
<Select placeholder="Select a card to issue batch for" ... />
<small>
  {{ selectedUser ? 'Choose which card to create the batch for' : 'Search for a user first' }}
</small>

<!-- AFTER -->
<label class="block text-sm font-medium text-slate-700">
  {{ $t('admin.select_card') }} <span class="text-red-500">*</span>
</label>
<Select :placeholder="$t('admin.select_card_to_issue')" ... />
<small>
  {{ selectedUser ? $t('admin.choose_which_card') : $t('admin.search_user_first') }}
</small>
```

### Section 5: Batch Name Info
```vue
<!-- BEFORE -->
<label class="block text-sm font-medium text-slate-700">
  Batch Name
</label>
<p class="text-sm text-slate-600">
  Batch name will be auto-generated as ...
</p>

<!-- AFTER -->
<label class="block text-sm font-medium text-slate-700">
  {{ $t('admin.batch_name') }}
</label>
<p class="text-sm text-slate-600">
  {{ $t('admin.batch_name_auto_generated') }}
</p>
```

### Section 6: Cards Count
```vue
<!-- BEFORE -->
<label class="block text-sm font-medium text-slate-700">
  Number of Cards <span class="text-red-500">*</span>
</label>
<InputNumber placeholder="Enter number of cards" ... />
<small>
  Between 1 and 10,000 cards.
  <span v-if="form.cardsCount > 0">
    (Regular cost: ${{ (form.cardsCount * 2).toLocaleString() }})
  </span>
</small>

<!-- AFTER -->
<label class="block text-sm font-medium text-slate-700">
  {{ $t('admin.batch_quantity') }} <span class="text-red-500">*</span>
</label>
<InputNumber :placeholder="$t('admin.enter_batch_quantity')" ... />
<small>
  {{ $t('admin.min_1_max_1000') }}
  <span v-if="form.cardsCount > 0">
    ({{ $t('admin.regular_cost') }}: ${{ (form.cardsCount * 2).toLocaleString() }})
  </span>
</small>
```

### Section 7: Reason Field
```vue
<!-- BEFORE -->
<label class="block text-sm font-medium text-slate-700">
  Reason for Free Issuance <span class="text-red-500">*</span>
</label>
<small>Explain why this batch is being issued for free</small>

<!-- AFTER -->
<label class="block text-sm font-medium text-slate-700">
  {{ $t('admin.issuance_reason') }} <span class="text-red-500">*</span>
</label>
<small>{{ $t('admin.explain_why_issuing') }}</small>
```

### Section 8: Summary Card
```vue
<!-- BEFORE -->
<h4 class="text-sm font-semibold text-slate-900 mb-3">Issuance Summary</h4>
<div class="space-y-2 text-sm">
  <div class="flex justify-between">
    <span class="text-slate-600">User:</span>
    ...
  </div>
  <div class="flex justify-between">
    <span class="text-slate-600">Card:</span>
    ...
  </div>
  <div class="flex justify-between">
    <span class="text-slate-600">Batch Name:</span>
    <span class="font-mono text-sm text-slate-900">Auto-generated</span>
  </div>
  <div class="flex justify-between">
    <span class="text-slate-600">Cards Count:</span>
    ...
  </div>
  <div class="flex justify-between pt-2 border-t border-slate-300">
    <span class="text-slate-600">Regular Cost:</span>
    ...
  </div>
  <div class="flex justify-between">
    <span class="text-green-600 font-medium">Free Issuance:</span>
    <span class="font-semibold text-green-600">$0.00</span>
  </div>
</div>

<!-- AFTER -->
<h4 class="text-sm font-semibold text-slate-900 mb-3">{{ $t('admin.issuance_summary') }}</h4>
<div class="space-y-2 text-sm">
  <div class="flex justify-between">
    <span class="text-slate-600">{{ $t('admin.user') }}:</span>
    ...
  </div>
  <div class="flex justify-between">
    <span class="text-slate-600">{{ $t('admin.card') }}:</span>
    ...
  </div>
  <div class="flex justify-between">
    <span class="text-slate-600">{{ $t('admin.batch_name') }}:</span>
    <span class="font-mono text-sm text-slate-900">{{ $t('admin.auto_generated') }}</span>
  </div>
  <div class="flex justify-between">
    <span class="text-slate-600">{{ $t('admin.cards_count') }}:</span>
    ...
  </div>
  <div class="flex justify-between pt-2 border-t border-slate-300">
    <span class="text-slate-600">{{ $t('admin.regular_cost') }}:</span>
    ...
  </div>
  <div class="flex justify-between">
    <span class="text-green-600 font-medium">{{ $t('admin.free_issuance') }}:</span>
    <span class="font-semibold text-green-600">$0.00</span>
  </div>
</div>
```

### Section 9: Action Buttons
```vue
<!-- BEFORE -->
<Button label="Cancel" ... />
<Button label="Issue Free Batch" ... />

<!-- AFTER -->
<Button :label="$t('common.cancel')" ... />
<Button :label="$t('admin.issue_free_batch_button')" ... />
```

### Section 10: Recent Issuances
```vue
<!-- BEFORE -->
<h2 class="text-lg font-semibold text-slate-900">Recent Free Batch Issuances</h2>
<p class="text-sm text-slate-600 mt-1">Latest batches issued in this session</p>
<p class="text-xs text-slate-600">
  {{ issuance.cardsCount }} cards issued to {{ issuance.userEmail }}
</p>
<Tag value="Issued" severity="success" />

<!-- AFTER -->
<h2 class="text-lg font-semibold text-slate-900">{{ $t('admin.recent_free_batch_issuances') }}</h2>
<p class="text-sm text-slate-600 mt-1">{{ $t('admin.latest_batches_issued') }}</p>
<p class="text-xs text-slate-600">
  {{ issuance.cardsCount }} {{ $t('admin.cards_issued_to') }} {{ issuance.userEmail }}
</p>
<Tag :value="$t('admin.issued')" severity="success" />
```

---

## Script Section Updates

### Add imports (after line 240):
```javascript
import { useI18n } from 'vue-i18n'
```

### Add after const toast (after line 254):
```javascript
const { t } = useI18n()
```

### Update toast messages in searchUser() function:
```javascript
// BEFORE
toast.add({ 
  severity: 'error', 
  summary: 'Error', 
  detail: 'Failed to search for user' 
})

// AFTER
toast.add({ 
  severity: 'error', 
  summary: t('common.error'), 
  detail: t('admin.failed_to_search_user') 
})
```

### Update toast messages in handleSubmit() function:
```javascript
// BEFORE
toast.add({
  severity: 'success',
  summary: 'Success',
  detail: 'Batch issued successfully! Cards are now available.',
  life: 5000
})

toast.add({
  severity: 'error',
  summary: 'Error',
  detail: 'Failed to issue batch'
})

// AFTER
toast.add({
  severity: 'success',
  summary: t('common.success'),
  detail: t('admin.batch_issued_successfully'),
  life: 5000
})

toast.add({
  severity: 'error',
  summary: t('common.error'),
  detail: t('admin.failed_to_issue_batch')
})
```

### Update toast for loadUserCards():
```javascript
// BEFORE
toast.add({
  severity: 'error',
  summary: 'Error',
  detail: 'Failed to load user cards'
})

// AFTER
toast.add({
  severity: 'error',
  summary: t('common.error'),
  detail: t('admin.failed_to_load_user_cards')
})
```

---

## Complete Implementation Checklist

- [ ] Replace all template strings with $t() calls (sections 1-10 above)
- [ ] Add useI18n import to script
- [ ] Add const { t } = useI18n() after const toast
- [ ] Update all toast messages to use t()
- [ ] Test with language switcher
- [ ] Verify no console warnings for missing keys
- [ ] Test form submission in both languages
- [ ] Verify validation messages display correctly

---

## Estimated Time: 30-45 minutes

