-- Test JSONB merge behavior
SELECT 
  '{"zh-Hans": {"name": "旧名字", "content_hash": "old123"}}'::jsonb || 
  '{"zh-Hans": {"name": "新名字", "content_hash": "new456"}}'::jsonb 
  AS merged_result;

-- Expected: {"zh-Hans": {"name": "新名字", "content_hash": "new456"}}
-- The || operator does a shallow merge per key
