# URL Format Update Summary

## Problem
The system had mixed URL formats for accessing issued cards:
- **Old format**: `/issuedcard/{issue_card_id}/{activation_code}`
- **New format**: `/c/{activation_code}`

Some components were still using the old format, causing inconsistency.

## Files Updated

### ✅ 1. IssuedCards.vue
**File**: `/src/views/Dashboard/CardIssuer/IssuedCards.vue`
**Line**: 815-818
```javascript
// Before
const getActivationUrl = (card) => {
  const baseUrl = import.meta.env.VITE_APP_BASE_URL || 'https://app.cardy.com'
  return `${baseUrl}/issuedcard/${card.id}/${card.activation_code}`
}

// After
const getActivationUrl = (card) => {
  const baseUrl = import.meta.env.VITE_APP_BASE_URL || window.location.origin
  return `${baseUrl}/c/${card.activation_code}`
}
```

### ✅ 2. MobilePreview.vue
**File**: `/src/components/CardComponents/MobilePreview.vue`
**Line**: 142-146
```javascript
// Before
const previewUrl = computed(() => {
    if (!sampleCard.value) return null;
    const baseUrl = window.location.origin;
    return `${baseUrl}/issuedcard/${sampleCard.value.issue_card_id}/${sampleCard.value.activation_code}`;
});

// After
const previewUrl = computed(() => {
    if (!sampleCard.value) return null;
    const baseUrl = window.location.origin;
    return `${baseUrl}/c/${sampleCard.value.activation_code}`;
});
```

### ✅ 3. Already Correct Components
These components were already using the correct format:
- **CardIssuanceCheckout.vue**: `${window.location.origin}/c/${card.activation_code}`
- **CardAccessQR.vue**: `${window.location.origin}/c/${activationCode}`
- **LandingPage.vue**: `${window.location.origin}/c/demo-ancient-artifacts`

## Impact

### URL Generation
All components now generate consistent URLs:
```
Before: https://app.cardy.com/issuedcard/abc123/XYZ789
After:  https://app.cardy.com/c/XYZ789
```

### Affected Features
1. **Copy URL functionality** in IssuedCards view
2. **Mobile preview iframe** in Card Details
3. **QR code generation** (already correct)
4. **CSV exports** (already correct)
5. **Landing page demo** (already correct)

### Benefits
1. **Consistent URLs**: All activation URLs use same format
2. **Shorter URLs**: Easier to share and type
3. **Simplified Routing**: Single route handler in Vue Router
4. **Better UX**: Clean, memorable URLs for users

## Testing Checklist

- [ ] **IssuedCards view**: Copy URL button generates `/c/CODE` format
- [ ] **Mobile Preview**: Iframe loads cards using `/c/CODE` format  
- [ ] **QR Codes**: Generated QR codes point to `/c/CODE` format
- [ ] **CSV Export**: Downloaded URLs use `/c/CODE` format
- [ ] **Landing Page**: Demo button opens `/c/demo-ancient-artifacts`

## Deployment

No database changes needed - this is purely frontend URL generation.

All URL generation is now consistent with the simplified `/c/:activation_code` route! 🎯