# Route Access Fix for /c/:activation_code

## Problem Identified
The route `/c/f9d1d41896bf5b14d333fcbca6bbad2c` was failing because:

1. **Route**: Only provides `activation_code`
2. **Stored Procedure**: `get_public_card_content(p_issue_card_id UUID, p_activation_code TEXT)` expects both parameters
3. **Missing Logic**: The procedure didn't properly resolve `issue_card_id` when it was `NULL`

## Root Cause
The stored procedure needs the **issue_card_id** to:
- Track which specific card was accessed (for analytics)
- Update the correct card's activation status
- Ensure proper security validation

## Solution Applied

### Updated Stored Procedure Logic
```sql
-- If issue_card_id is null, look it up by activation code
IF p_issue_card_id IS NULL THEN
    SELECT ic.id INTO v_resolved_issue_card_id
    FROM issue_cards ic
    WHERE ic.activation_code = p_activation_code;
    
    IF v_resolved_issue_card_id IS NULL THEN
        -- No card found with this activation code
        RETURN;
    END IF;
ELSE
    v_resolved_issue_card_id := p_issue_card_id;
END IF;
```

### Benefits
1. **Backward Compatible**: Old `/issuedcard/:id/:code` routes still work
2. **New Route Support**: `/c/:activation_code` routes now work
3. **Proper Tracking**: Still tracks individual card access
4. **Security Maintained**: Validation logic preserved

## Files Changed
- `sql/storeproc/07_public_access.sql` - Updated function logic
- `sql/migrations/006_fix_public_card_access.sql` - Migration file

## Testing
After applying the migration, test these URLs:
- ✅ `/c/f9d1d41896bf5b14d333fcbca6bbad2c` (new format)
- ✅ `/issuedcard/{id}/f9d1d41896bf5b14d333fcbca6bbad2c` (old format)

## Deployment
```bash
# Apply the migration
psql "$DATABASE_URL" -f sql/migrations/006_fix_public_card_access.sql
```

The `/c/:activation_code` route should now work correctly! 🎯