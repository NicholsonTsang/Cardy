-- =================================================================
-- AUTH FUNCTIONS
-- Functions for user authentication, role management, and triggers
-- =================================================================

-- Function to set default role for new users (from triggers.sql)
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER -- Required to modify auth.users table
SET search_path = public
AS $$
DECLARE
    default_role TEXT := 'card_issuer';
BEGIN
  -- Update new user with default role
  UPDATE auth.users
  SET raw_user_meta_data = raw_user_meta_data || jsonb_build_object('role', default_role)
  WHERE id = NEW.id;
  
  -- Log new user registration
  INSERT INTO operations_log (user_id, user_role, operation)
  VALUES (
    NEW.id,
    default_role::"UserRole",
    'New user registered: ' || NEW.email
  );
  
  RETURN NEW;
END;
$$;

-- Grant execute permission for handle_new_user (from triggers.sql)
GRANT EXECUTE ON FUNCTION public.handle_new_user() TO supabase_auth_admin;

-- Function to get user role (from auth_triggers.sql)
CREATE OR REPLACE FUNCTION public.get_user_role(user_id UUID)
RETURNS TEXT
LANGUAGE plpgsql
AS $$
DECLARE
  role TEXT;
BEGIN
  SELECT raw_user_meta_data->>'role' INTO role FROM auth.users WHERE id = user_id;
  RETURN role;
END;
$$;

-- Grant execute permission for get_user_role (from auth_triggers.sql)
GRANT EXECUTE ON FUNCTION public.get_user_role(UUID) TO postgres, anon, authenticated, service_role; 