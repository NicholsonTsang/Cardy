# Print Request Cards Count Display Fix

## Issue
In the print request status dialog, the card count number wasn't being rendered. The UI was trying to display `selectedPrintRequestData.cards_count`, but this field was missing from the data returned by the database.

## Root Cause
The `get_print_requests_for_batch()` stored procedure was only returning fields directly from the `print_requests` table, but not the `cards_count` field which exists in the related `card_batches` table.

## Solution
Updated the `get_print_requests_for_batch()` function to:
1. JOIN with the `card_batches` table
2. Include `cards_count` in the returned columns

## Files Modified

### Database Functions
1. **`sql/storeproc/client-side/06_print_requests.sql`**
   - Added `cards_count INTEGER` to the RETURNS TABLE definition (line 97)
   - Added JOIN with `card_batches` table (line 131)
   - Added `cb.cards_count` to the SELECT statement (line 127)

2. **`sql/all_stored_procedures.sql`**
   - Same changes as above to keep the combined file in sync (lines 1505, 1535, 1539)

### TypeScript Interface
3. **`src/stores/issuedCard.ts`**
   - Added `cards_count: number;` to the `PrintRequest` interface (line 59)

### Deployment Script
4. **`deploy-print-request-cards-count-fix.sql`**
   - Created standalone deployment script for applying this fix to the database

## Deployment Instructions

To deploy this fix to your database:

```bash
# Using Supabase CLI
supabase db push --file deploy-print-request-cards-count-fix.sql

# Or using psql directly
psql -h [your-db-host] -d [your-db-name] -U [your-user] -f deploy-print-request-cards-count-fix.sql
```

## Testing
After deployment:
1. Navigate to a card with an existing print request
2. Click on the print status button (truck icon)
3. Verify that the "Cards Count" field now displays the correct number (e.g., "50 cards")

## Impact
- **Breaking Changes**: None - this is an additive change
- **Backwards Compatibility**: Yes - existing code continues to work
- **Performance**: Minimal - adds one JOIN operation but on indexed foreign keys







