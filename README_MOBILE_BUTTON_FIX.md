# Mobile Demo Button Fix

## Problem
The mobile "Open Demo Card" button was not routing to the same URL as the QR code because:
1. The QR code pointed to an external URL format (`https://cardy.example.com/demo/ancient-artifacts`)
2. The mobile button tried to extract an activation code and route to `/c/{code}`
3. There was no route handler for `/c/:activation_code` format
4. The stored procedure required both `issue_card_id` and `activation_code` parameters

## Solution

### 1. Simplified routing architecture
**File: `src/router/index.ts`**
```javascript
// Primary route: Clean, short format
{
  path: '/c/:activation_code',
  name: 'publiccardview',
  component: () => import('@/views/MobileClient/PublicCardView.vue')
},
// Legacy redirect: Maintains backward compatibility
{
  path: '/issuedcard/:issue_card_id/:activation_code',
  redirect: to => `/c/${to.params.activation_code}`
}
```

### 2. Updated stored procedure to handle activation code only
**File: `sql/storeproc/07_public_access.sql`**
- Modified `get_public_card_content()` to accept `null` for `p_issue_card_id`
- Added logic to find issued cards by activation code only
- Updated activation logic to work with both route formats

### 3. Simplified mobile client component
**File: `src/views/MobileClient/PublicCardView.vue`**
- Simplified to only handle `/c/:activation_code` format
- Legacy routes automatically redirect to new format
- Cleaner code with single parameter handling

### 4. Fixed sample QR URL
**File: `src/views/Public/LandingPage.vue`**
- Changed default sample URL to use current domain: `${window.location.origin}/c/demo-ancient-artifacts`
- Updated mobile button to navigate to exact same URL as QR code

### 5. Created migration
**File: `sql/migrations/005_update_public_access_function.sql`**
- Deploys the updated stored procedure

## URL Format Comparison

### Before:
- **QR Code**: `https://cardy.example.com/demo/ancient-artifacts` (external)
- **Mobile Button**: `/c/ancient-artifacts` (extracted incorrectly)
- **Result**: Different destinations, button didn't work

### After:
- **QR Code**: `https://yoursite.com/c/demo-ancient-artifacts`
- **Mobile Button**: `https://yoursite.com/c/demo-ancient-artifacts`
- **Result**: Both point to exact same URL

## Benefits

1. **Consistent Experience**: QR code and mobile button now lead to identical URLs
2. **Shorter URLs**: `/c/CODE` format is cleaner than `/issuedcard/ID/CODE`
3. **Better UX**: Mobile users can easily access demo without QR scanning
4. **Backward Compatibility**: Old `/issuedcard/ID/CODE` format still works

## Deployment

```bash
# Deploy the updated stored procedure
psql "$DATABASE_URL" -f sql/migrations/005_update_public_access_function.sql
```

## Testing

1. **QR Code**: Scan the QR code on landing page → should open demo card
2. **Mobile Button**: Click "Open Demo Card" on mobile → should open same demo card
3. **URL formats**: Both `/c/demo-ancient-artifacts` and `/issuedcard/ID/demo-ancient-artifacts` should work