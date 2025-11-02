# Configurable Batch Minimum via Environment Variable

## Summary

Implemented configurable minimum batch size for card issuance using an environment variable. The validation is frontend-only as requested, with no backend validation required.

## Implementation Details

### 1. Environment Variable Configuration
**File**: `.env.example`

Added new environment variable:
```bash
# Batch Issuance Configuration
# Minimum number of cards per batch (default: 100)
VITE_BATCH_MIN_QUANTITY=100
```

**Purpose**: Allows easy configuration of minimum batch size without code changes.

### 2. Frontend Component Updates
**File**: `src/components/CardIssuanceCheckout.vue`

**Changes**:
1. **Dynamic Minimum Value**:
   - Reads `VITE_BATCH_MIN_QUANTITY` from environment (defaults to 100 if not set)
   - Applied to `InputNumber` component's `:min` attribute
   - Used as default value for `cardCount` field

2. **Helper Text**:
   - Added visual helper text below input field
   - Uses i18n key `batches.minimum_batch_size` with dynamic count parameter
   - Displayed as: "Minimum batch size: 100 cards" (or configured value)

3. **Form Reset**:
   - When form is reset after batch creation, uses `minBatchQuantity` instead of hardcoded 50

**Code Structure**:
```javascript
// Get minimum batch quantity from environment variable (default: 100)
const minBatchQuantity = Number(import.meta.env.VITE_BATCH_MIN_QUANTITY) || 100

// New batch form
const newBatch = ref({
  cardCount: minBatchQuantity
})
```

### 3. Internationalization
**Files**: 
- `src/i18n/locales/en.json`
- `src/i18n/locales/zh-Hant.json`

**Added Translation Keys**:
- `batches.enter_number_of_cards`: "Enter number of cards" / "輸入卡片數量"
- `batches.minimum_batch_size`: "Minimum batch size: {count} cards" / "最低批次數量：{count} 張卡片"

**Note**: Uses i18n parameter interpolation `{count}` for dynamic minimum value display.

### 4. Documentation Updates
**File**: `CLAUDE.md`

Updated two sections:
1. **Card Issuer Flow > Batch Issuance**: Added note about configurable minimum with env variable
2. **Landing Page > Environment Variables Used**: Added `VITE_BATCH_MIN_QUANTITY` to the list

## Configuration Guide

### Default Configuration (100 cards minimum)
No action needed - the default value of 100 is built into the code.

### Custom Configuration
To change the minimum batch size:

1. **Local Development**:
   ```bash
   # .env.local
   VITE_BATCH_MIN_QUANTITY=50  # Set to desired minimum
   ```

2. **Production**:
   - Add environment variable to your hosting platform
   - Variable name: `VITE_BATCH_MIN_QUANTITY`
   - Value: Desired minimum (e.g., 100, 200, etc.)

3. **Rebuild**:
   ```bash
   npm run build
   ```
   Environment variables are embedded at build time with Vite.

## Validation Behavior

### Frontend Validation Only (As Requested)
- **InputNumber Component**: Prevents user from entering values below minimum
- **Decrement Button**: Disabled when value reaches minimum
- **Manual Input**: Values below minimum are automatically adjusted to minimum
- **Form Reset**: Defaults to minimum value

### No Backend Validation
- As per requirements, backend stored procedure does NOT validate minimum
- Backend only validates maximum (1000 cards) and ensures positive values
- This is intentional - frontend acts as a guard/guide for users

## Testing Checklist

### Functionality Tests
- [ ] **Environment Variable Reading**:
  - [ ] Default value (100) works when env var not set
  - [ ] Custom value works when `VITE_BATCH_MIN_QUANTITY` is set
  - [ ] Non-numeric values fallback to default 100

- [ ] **UI Behavior**:
  - [ ] InputNumber shows correct minimum value
  - [ ] Default card count equals minimum on dialog open
  - [ ] Decrement button disabled at minimum
  - [ ] Manual input below minimum adjusts to minimum
  - [ ] Helper text displays correct minimum count

- [ ] **Form Reset**:
  - [ ] After successful batch creation, form resets to minimum
  - [ ] Form reset uses dynamic minimum (not hardcoded 50)

- [ ] **Internationalization**:
  - [ ] English helper text displays correctly
  - [ ] Chinese helper text displays correctly
  - [ ] Count parameter interpolates correctly in both languages

- [ ] **Backend Compatibility**:
  - [ ] Backend accepts values at configured minimum
  - [ ] Backend accepts values above minimum
  - [ ] No backend errors related to validation

### Edge Cases
- [ ] Minimum = 1: Should work (no minimum enforcement)
- [ ] Minimum = 1000: Should work (equals maximum)
- [ ] Minimum = 5000: Should work but max validation at 1000 kicks in
- [ ] Missing env var: Falls back to 100
- [ ] Invalid env var (text): Falls back to 100

## Business Rationale

### Why Configurable Minimum?

1. **Flexibility**: Different clients may have different economical batch sizes
2. **Testing**: Lower minimums useful for development/testing environments
3. **Market Adaptation**: Can adjust minimum based on production costs or market conditions
4. **No Code Deployment**: Change minimum without rebuilding (just env var + restart)

### Why Frontend-Only Validation?

1. **User Experience**: Prevents users from wasting time entering invalid values
2. **Guidance**: Acts as a helpful constraint, not a security boundary
3. **Flexibility**: Backend remains agnostic to business rules that may change
4. **Deployment**: Easy to adjust without database migrations or stored procedure updates

### Current Default (100 Cards)

Reasoning for 100 cards minimum:
- **Economical Production**: Printing/shipping costs optimized at scale
- **Professional Use Cases**: Museums, exhibitions typically need 100+ cards
- **Sustainable Model**: Ensures viable transactions (100 cards × $2 = $200 minimum)
- **Quality Service**: Better pricing with printing partners

## Related Files

### Modified Files
- `.env.example` - Added `VITE_BATCH_MIN_QUANTITY`
- `src/components/CardIssuanceCheckout.vue` - Implemented dynamic minimum
- `src/i18n/locales/en.json` - Added translation keys
- `src/i18n/locales/zh-Hant.json` - Added translation keys
- `CLAUDE.md` - Updated documentation

### No Changes Required
- Backend stored procedures (intentionally no validation)
- Database schema
- Edge Functions
- Other components

## Migration Notes

### For Existing Deployments

**Before Deployment**:
1. No database changes needed
2. No stored procedure updates needed
3. Existing batches unaffected

**After Deployment**:
1. New batches will respect configured minimum
2. Old batches remain unchanged
3. Users see new minimum in UI immediately

**Environment Variable**:
- Add `VITE_BATCH_MIN_QUANTITY=100` to production environment
- Rebuild frontend with updated env vars
- Deploy as normal

### Rollback Plan

If needed, revert to previous behavior:
1. Set `VITE_BATCH_MIN_QUANTITY=1` in environment
2. Rebuild and deploy
3. Or revert code changes entirely

## Future Enhancements

### Potential Improvements

1. **Admin Configuration**: Allow admins to set minimum via dashboard
2. **Per-User Minimums**: Different minimums for different user tiers
3. **Dynamic Minimums**: Adjust based on card type or features
4. **Tiered Pricing**: Lower per-card cost for larger batches
5. **Backend Validation**: Add optional server-side validation for consistency

### Not Planned

- Backend validation (intentionally omitted per requirements)
- Database constraints (frontend guard sufficient)
- Per-card minimum configuration (batch level is appropriate)

## Questions & Answers

**Q: Why default to 100 instead of keeping 50?**
A: Based on business model requirements for economical production and sustainable pricing.

**Q: Can users bypass the frontend validation?**
A: Technically yes (API calls), but backend has reasonable upper limits. This is a UX guide, not a security measure.

**Q: What if I want no minimum?**
A: Set `VITE_BATCH_MIN_QUANTITY=1` in environment variables.

**Q: Does this affect existing batches?**
A: No, only new batch creation is affected.

**Q: Can different environments have different minimums?**
A: Yes! Set different values in `.env.local` (dev) vs production environment.

**Q: Why not read from database or admin settings?**
A: Environment variables provide simpler deployment and configuration without database dependencies.

## Deployment Checklist

### Pre-Deployment
- [x] Code changes completed
- [x] i18n translations added for en and zh-Hant
- [x] Documentation updated (CLAUDE.md)
- [x] Environment variable documented in .env.example

### Deployment Steps
1. [ ] Add `VITE_BATCH_MIN_QUANTITY=100` to production environment variables
2. [ ] Build frontend: `npm run build:production`
3. [ ] Deploy frontend build to hosting platform
4. [ ] Verify environment variable is correctly set

### Post-Deployment Testing
- [ ] Open batch creation dialog
- [ ] Verify minimum shows as 100 cards
- [ ] Try to enter value below 100 (should auto-adjust)
- [ ] Verify helper text displays correctly
- [ ] Test batch creation with 100 cards
- [ ] Verify English and Chinese translations
- [ ] Check browser console for any errors

## Summary

This implementation provides flexible, configurable minimum batch size through environment variables with frontend-only validation as requested. No backend changes are needed, making deployment simple and risk-free. The default of 100 cards aligns with business requirements for economical production while remaining easily configurable for different environments or business needs.

