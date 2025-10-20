-- =================================================================
-- TRANSLATION SYSTEM VERIFICATION SCRIPT
-- =================================================================
-- Run these queries to verify your translation system is set up correctly
-- Execute in: Supabase Dashboard → SQL Editor
-- =================================================================

-- 1. Check if content hash update triggers exist
SELECT 
    tgname AS trigger_name,
    tgenabled AS enabled,
    tgrelid::regclass AS table_name
FROM pg_trigger 
WHERE tgname LIKE '%content_hash%'
ORDER BY tgname;

-- Expected result: 2 triggers (both enabled = 'O')
-- trigger_update_card_content_hash on cards
-- trigger_update_content_item_content_hash on content_items

-- =================================================================

-- 2. Check if translation management functions exist
SELECT 
    proname AS function_name,
    pg_get_function_arguments(oid) AS arguments
FROM pg_proc
WHERE proname IN (
    'get_card_translation_status',
    'store_card_translations',
    'recalculate_all_translation_hashes',
    'recalculate_card_translation_hashes',
    'recalculate_content_item_translation_hashes'
)
ORDER BY proname;

-- Expected result: 5 functions

-- =================================================================

-- 3. Test content hash trigger (replace YOUR_CARD_ID with actual card ID)
-- First, check current state:
SELECT 
    id,
    name,
    content_hash,
    last_content_update,
    updated_at
FROM cards 
WHERE id = 'YOUR_CARD_ID'; -- Replace with your card ID

-- Update the card (adds a space to name):
UPDATE cards 
SET name = TRIM(name) || ' '
WHERE id = 'YOUR_CARD_ID'; -- Replace with your card ID

-- Check if hash changed:
SELECT 
    id,
    name,
    content_hash,
    last_content_update,
    updated_at
FROM cards 
WHERE id = 'YOUR_CARD_ID'; -- Replace with your card ID

-- Expected: content_hash should be different, last_content_update should be NOW()

-- =================================================================

-- 4. Check translation status for a card (replace YOUR_CARD_ID)
SELECT * FROM get_card_translation_status('YOUR_CARD_ID'); -- Replace with your card ID

-- Expected columns:
-- language, language_name, status, translated_at, needs_update, content_fields_count

-- Status should be:
-- 'original' for original language
-- 'up_to_date' for translations matching current hash
-- 'outdated' for translations with old hash
-- 'not_translated' for languages without translations

-- =================================================================

-- 5. Check if a card has outdated translations
SELECT 
    c.id,
    c.name,
    c.content_hash as current_hash,
    c.translations as translations_json,
    jsonb_object_keys(c.translations) as translated_languages
FROM cards c
WHERE c.id = 'YOUR_CARD_ID' -- Replace with your card ID
  AND c.translations IS NOT NULL
  AND c.translations != '{}'::jsonb;

-- For each language in translations, check if hash matches:
SELECT 
    c.id,
    c.name,
    c.content_hash as current_hash,
    lang_key as language,
    c.translations->lang_key->>'content_hash' as translation_hash,
    CASE 
        WHEN c.translations->lang_key->>'content_hash' = c.content_hash 
        THEN 'up_to_date' 
        ELSE 'outdated' 
    END as status
FROM cards c,
     jsonb_object_keys(c.translations) as lang_key
WHERE c.id = 'YOUR_CARD_ID'; -- Replace with your card ID

-- =================================================================

-- 6. Check credit balance for a user (replace YOUR_USER_ID)
SELECT 
    user_id,
    balance,
    total_purchased,
    total_consumed,
    last_purchase_at,
    updated_at
FROM user_credits
WHERE user_id = 'YOUR_USER_ID'; -- Replace with your user ID

-- Or check for all users:
SELECT 
    uc.user_id,
    u.email,
    uc.balance,
    uc.total_purchased,
    uc.total_consumed
FROM user_credits uc
JOIN auth.users u ON u.id = uc.user_id
ORDER BY uc.balance DESC;

-- =================================================================

-- TROUBLESHOOTING CHECKLIST:
-- 
-- ✅ If no triggers found (query 1):
--    → Deploy sql/triggers.sql
--
-- ✅ If functions missing (query 2):
--    → Deploy sql/all_stored_procedures.sql
--
-- ✅ If content_hash doesn't change after update (query 3):
--    → Triggers not working, redeploy sql/triggers.sql
--
-- ✅ If translations show 'up_to_date' but hashes don't match (query 5):
--    → Frontend not refreshing, hard refresh browser (Cmd+Shift+R)
--
-- ✅ If credit balance is 0 or negative (query 6):
--    → User needs to purchase credits
--
-- =================================================================


