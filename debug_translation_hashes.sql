-- =====================================================
-- DIAGNOSTIC QUERIES FOR TRANSLATION OUTDATED ISSUE
-- =====================================================
-- Run these queries in Supabase SQL Editor to diagnose the issue
-- Replace 'YOUR_CARD_ID' with actual card ID having the problem

-- Query 1: Check Card Translation Hashes
-- This shows if stored hash matches current hash
SELECT 
  c.id,
  c.name as card_name,
  c.content_hash as current_card_hash,
  c.translations->'zh-Hans'->>'name' as chinese_name,
  c.translations->'zh-Hans'->>'content_hash' as stored_hash_in_translation,
  c.translations->'zh-Hans'->>'translated_at' as translation_date,
  c.last_content_update,
  CASE 
    WHEN c.translations->'zh-Hans'->>'content_hash' = c.content_hash 
    THEN '✅ MATCH (should show up_to_date)' 
    ELSE '❌ MISMATCH (will show outdated)'
  END as hash_status,
  CASE 
    WHEN c.translations->'zh-Hans'->>'content_hash' IS NULL 
    THEN '⚠️ HASH IS NULL!'
    WHEN c.content_hash IS NULL
    THEN '⚠️ CURRENT HASH IS NULL!'
    ELSE 'Hashes exist'
  END as hash_existence_check
FROM cards c
WHERE c.translations ? 'zh-Hans'  -- Has Chinese translation
ORDER BY c.updated_at DESC
LIMIT 10;

-- Query 2: Check Content Items Translation Hashes
-- This shows which content items have mismatched hashes
SELECT 
  ci.id as item_id,
  ci.card_id,
  ci.name as item_name,
  ci.content_hash as current_item_hash,
  ci.translations->'zh-Hans'->>'name' as chinese_name,
  ci.translations->'zh-Hans'->>'content_hash' as stored_hash,
  ci.translations->'zh-Hans'->>'translated_at' as translation_date,
  CASE 
    WHEN ci.translations->'zh-Hans'->>'content_hash' = ci.content_hash 
    THEN '✅ MATCH' 
    ELSE '❌ MISMATCH'
  END as hash_status,
  CASE 
    WHEN ci.translations->'zh-Hans'->>'content_hash' IS NULL 
    THEN '⚠️ STORED HASH IS NULL!'
    WHEN ci.content_hash IS NULL
    THEN '⚠️ CURRENT HASH IS NULL!'
    ELSE 'Hashes exist'
  END as hash_existence
FROM content_items ci
WHERE ci.translations ? 'zh-Hans'  -- Has Chinese translation
  AND ci.card_id IN (
    SELECT id FROM cards WHERE translations ? 'zh-Hans' LIMIT 5
  )
ORDER BY ci.card_id, ci.sort_order;

-- Query 3: Check What get_card_translation_status Returns
-- This is what the frontend sees
SELECT * FROM get_card_translation_status('YOUR_CARD_ID');
-- Replace 'YOUR_CARD_ID' with actual card ID

-- Query 4: Check if Content Hash Triggers are Working
-- Create a test: Update a card and see if hash changes
DO $$
DECLARE
  v_test_card_id UUID;
  v_hash_before TEXT;
  v_hash_after TEXT;
BEGIN
  -- Get a card with translations
  SELECT id INTO v_test_card_id 
  FROM cards 
  WHERE translations ? 'zh-Hans' 
  LIMIT 1;
  
  IF v_test_card_id IS NULL THEN
    RAISE NOTICE 'No card with translations found for testing';
    RETURN;
  END IF;
  
  -- Get hash before update
  SELECT content_hash INTO v_hash_before FROM cards WHERE id = v_test_card_id;
  
  -- Make a tiny change to description
  UPDATE cards 
  SET description = COALESCE(description, '') || ' [test]'
  WHERE id = v_test_card_id;
  
  -- Get hash after update
  SELECT content_hash INTO v_hash_after FROM cards WHERE id = v_test_card_id;
  
  -- Report results
  RAISE NOTICE 'Test Card ID: %', v_test_card_id;
  RAISE NOTICE 'Hash before: %', v_hash_before;
  RAISE NOTICE 'Hash after: %', v_hash_after;
  
  IF v_hash_before = v_hash_after THEN
    RAISE WARNING '❌ TRIGGER NOT WORKING: Hash did not change after content update!';
  ELSE
    RAISE NOTICE '✅ TRIGGER WORKING: Hash changed from % to %', v_hash_before, v_hash_after;
  END IF;
  
  -- Rollback the test change
  ROLLBACK;
END $$;

-- Query 5: Check Latest Translation History
-- See if translations are being saved
SELECT 
  th.id,
  th.card_id,
  c.name as card_name,
  th.target_languages,
  th.status,
  th.translated_by,
  th.created_at,
  th.metadata
FROM translation_history th
JOIN cards c ON c.id = th.card_id
ORDER BY th.created_at DESC
LIMIT 10;

-- Query 6: Raw JSONB Structure Check
-- See the actual structure of translations JSONB
SELECT 
  c.id,
  c.name,
  jsonb_pretty(c.translations->'zh-Hans') as chinese_translation_structure
FROM cards c
WHERE c.translations ? 'zh-Hans'
LIMIT 3;

