-- =================================================================
-- MANUAL USER ROLE MANAGEMENT
-- =================================================================
-- Functions and queries to manually set user roles in Supabase

-- =================================================================
-- METHOD 1: Direct SQL Updates (Use with caution)
-- =================================================================

-- Update user role directly (replace email and role as needed)
UPDATE auth.users 
SET raw_user_meta_data = 
    COALESCE(raw_user_meta_data, '{}'::jsonb) || '{"role": "admin"}'::jsonb
WHERE email = 'user@example.com';

-- Update user role for specific user ID
UPDATE auth.users 
SET raw_user_meta_data = 
    COALESCE(raw_user_meta_data, '{}'::jsonb) || '{"role": "cardIssuer"}'::jsonb
WHERE id = '00000000-0000-0000-0000-000000000000';

-- =================================================================
-- METHOD 2: Stored Functions for Role Management
-- =================================================================

-- Function to set user role (admin only)
CREATE OR REPLACE FUNCTION set_user_role(
    p_user_email TEXT,
    p_new_role TEXT
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER -- Run with elevated privileges
AS $$
DECLARE
    target_user_id UUID;
    caller_role TEXT;
BEGIN
    -- Check if caller is admin
    SELECT raw_user_meta_data->>'role' INTO caller_role
    FROM auth.users
    WHERE id = auth.uid();
    
    IF caller_role != 'admin' THEN
        RAISE EXCEPTION 'Only admins can set user roles';
    END IF;
    
    -- Validate the new role
    IF p_new_role NOT IN ('user', 'cardIssuer', 'admin') THEN
        RAISE EXCEPTION 'Invalid role. Allowed roles: user, cardIssuer, admin';
    END IF;
    
    -- Find the target user
    SELECT id INTO target_user_id
    FROM auth.users
    WHERE email = p_user_email;
    
    IF target_user_id IS NULL THEN
        RAISE EXCEPTION 'User with email % not found', p_user_email;
    END IF;
    
    -- Update the user's role
    UPDATE auth.users
    SET raw_user_meta_data = 
        COALESCE(raw_user_meta_data, '{}'::jsonb) || 
        jsonb_build_object('role', p_new_role)
    WHERE id = target_user_id;
    
    RETURN FOUND;
END;
$$;

-- Grant execute permission to authenticated users (admin check is inside function)
GRANT EXECUTE ON FUNCTION set_user_role(TEXT, TEXT) TO authenticated;

-- Function to get user role by email
CREATE OR REPLACE FUNCTION get_user_role_by_email(p_user_email TEXT)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    user_role TEXT;
    caller_role TEXT;
BEGIN
    -- Check if caller is admin
    SELECT raw_user_meta_data->>'role' INTO caller_role
    FROM auth.users
    WHERE id = auth.uid();
    
    IF caller_role != 'admin' THEN
        RAISE EXCEPTION 'Only admins can view user roles';
    END IF;
    
    SELECT raw_user_meta_data->>'role' INTO user_role
    FROM auth.users
    WHERE email = p_user_email;
    
    RETURN COALESCE(user_role, 'user'); -- Default to 'user' if no role set
END;
$$;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION get_user_role_by_email(TEXT) TO authenticated;

-- Function to list all users with their roles (admin only)
CREATE OR REPLACE FUNCTION list_users_with_roles()
RETURNS TABLE (
    user_id UUID,
    email TEXT,
    role TEXT,
    created_at TIMESTAMPTZ,
    last_sign_in_at TIMESTAMPTZ,
    email_confirmed_at TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    caller_role TEXT;
BEGIN
    -- Check if caller is admin
    SELECT raw_user_meta_data->>'role' INTO caller_role
    FROM auth.users
    WHERE id = auth.uid();
    
    IF caller_role != 'admin' THEN
        RAISE EXCEPTION 'Only admins can list users';
    END IF;
    
    RETURN QUERY
    SELECT 
        u.id as user_id,
        u.email,
        COALESCE(u.raw_user_meta_data->>'role', 'user') as role,
        u.created_at,
        u.last_sign_in_at,
        u.email_confirmed_at
    FROM auth.users u
    ORDER BY u.created_at DESC;
END;
$$;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION list_users_with_roles() TO authenticated;

-- =================================================================
-- METHOD 3: Bulk Role Updates
-- =================================================================

-- Make all users without roles default to 'cardIssuer'
UPDATE auth.users 
SET raw_user_meta_data = 
    COALESCE(raw_user_meta_data, '{}'::jsonb) || '{"role": "cardIssuer"}'::jsonb
WHERE raw_user_meta_data->>'role' IS NULL 
   OR raw_user_meta_data->>'role' = '';

-- Make specific users admin (replace emails with actual admin emails)
UPDATE auth.users 
SET raw_user_meta_data = 
    COALESCE(raw_user_meta_data, '{}'::jsonb) || '{"role": "admin"}'::jsonb
WHERE email IN (
    'admin@yourcompany.com',
    'super.admin@yourcompany.com'
);

-- =================================================================
-- METHOD 4: Role Management Queries for Debugging
-- =================================================================

-- View all users and their current roles
SELECT 
    id,
    email,
    raw_user_meta_data->>'role' as current_role,
    created_at,
    email_confirmed_at
FROM auth.users
ORDER BY created_at DESC;

-- Count users by role
SELECT 
    COALESCE(raw_user_meta_data->>'role', 'no_role') as role,
    COUNT(*) as count
FROM auth.users
GROUP BY raw_user_meta_data->>'role'
ORDER BY count DESC;

-- Find users without roles
SELECT 
    id,
    email,
    created_at
FROM auth.users
WHERE raw_user_meta_data->>'role' IS NULL 
   OR raw_user_meta_data->>'role' = '';

-- =================================================================
-- USAGE EXAMPLES
-- =================================================================

-- Example 1: Set a user as admin
-- SELECT set_user_role('admin@example.com', 'admin');

-- Example 2: Set a user as cardIssuer
-- SELECT set_user_role('user@example.com', 'cardIssuer');

-- Example 3: Get a user's role
-- SELECT get_user_role_by_email('user@example.com');

-- Example 4: List all users with roles
-- SELECT * FROM list_users_with_roles();

-- =================================================================
-- SECURITY NOTES
-- =================================================================
-- 1. Only use direct SQL updates when you have database admin access
-- 2. Always backup before making bulk changes
-- 3. The stored functions include admin role checks for security
-- 4. Test role changes in development first
-- 5. Consider logging role changes for audit purposes 