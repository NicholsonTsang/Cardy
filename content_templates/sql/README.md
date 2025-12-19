# SQL Insert Templates

This folder contains SQL scripts to insert template content directly into the database.

## Quick Start

Generate a combined SQL file with all templates:

```bash
./scripts/combine-templates.sh
```

This creates `content_templates/all_templates.sql` with all 13 templates combined.

## Usage

1. **Replace the user ID placeholder:**
   ```sql
   v_user_id UUID := 'YOUR_USER_ID_HERE'::UUID;
   ```
   Replace `'YOUR_USER_ID_HERE'` with your actual user UUID from the `auth.users` table.

2. **Update image URLs (optional):**
   All `image_url` fields are set to `NULL` by default. After running the script, you can update them with actual uploaded image URLs.

3. **Run the SQL:**
   - Open your Supabase Dashboard → SQL Editor
   - Paste the entire script content
   - Click "Run" to execute

## Available Templates

> **Note:** All templates use **Digital Access** mode (billing_type: 'digital')

| SQL File | Venue Type | Content Mode |
|----------|------------|--------------|
| `art_gallery_grid.sql` | Art Gallery | Grid Gallery |
| `history_museum_grouped.sql` | History Museum | Grouped List |
| `fine_dining_grouped.sql` | Fine Dining | Grouped List |
| `cocktail_bar_inline.sql` | Cocktail Bar | Full Cards |
| `zoo_grid.sql` | Zoo | Grid Gallery |
| `football_match_single.sql` | Sports Event | Single Page |
| `hotel_services_list.sql` | Hotel Services | Simple List |
| `conference_grouped.sql` | Conference | Grouped List |
| `shopping_mall_list.sql` | Shopping Mall | Simple List |
| `tourist_landmark_inline.sql` | Tourist Attraction | Full Cards |
| `auction_house_grouped.sql` | Auction House | Grouped List |
| `illustrator_portfolio_grid.sql` | Creative Portfolio | Grid Gallery |
| `fashion_show_grouped.sql` | Fashion Show | Grouped List |

## SQL Structure

Each script uses a `DO $body$ ... END $body$` block with:

1. **Variable declarations** for card ID and category IDs (for grouped mode)
2. **Card INSERT** with all card-level fields
3. **Category INSERTs** (grouped mode only) - creates parent items
4. **Content Item INSERTs** - creates individual content items

### For Grouped Mode Templates

The script creates categories first, captures their IDs, then creates child items referencing those IDs:

```sql
-- Create category, capture ID
INSERT INTO content_items (...) 
VALUES (...) RETURNING id INTO v_category_id;

-- Create items under that category
INSERT INTO content_items (card_id, parent_id, ...) 
VALUES (v_card_id, v_category_id, ...);
```

### For Non-Grouped Mode Templates

Items are inserted directly without parent references:

```sql
INSERT INTO content_items (card_id, name, content, ...) 
VALUES (v_card_id, 'Item Name', 'Item content...', ...);
```

## Notes

- All scripts use `gen_random_uuid()` for automatic UUID generation
- Single quotes in content are escaped as `''`
- Multi-line content uses `E'...'` syntax for escape sequences
- Scripts output the created card ID on success via `RAISE NOTICE`
- Uses `$body$` delimiter to avoid conflicts with `$` in content

## Finding Your User ID

Run this query to find your user ID:

```sql
SELECT id, email FROM auth.users WHERE email = 'your-email@example.com';
```

Or check the Supabase Dashboard → Authentication → Users
