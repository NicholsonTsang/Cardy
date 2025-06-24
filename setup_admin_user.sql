-- Quick setup: Make yourself an admin
-- Replace 'your-email@example.com' with your actual email

UPDATE auth.users 
SET raw_user_meta_data = 
    COALESCE(raw_user_meta_data, '{}'::jsonb) || '{"role": "admin"}'::jsonb
WHERE email = 'your-email@example.com';

-- Verify the change
SELECT 
    email,
    raw_user_meta_data->>'role' as role
FROM auth.users 
WHERE email = 'your-email@example.com'; 