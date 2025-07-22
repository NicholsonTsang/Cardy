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
  
  -- Log new user registration in simplified audit table (self-registration)
  INSERT INTO admin_audit_log (
    admin_user_id,
    admin_email,
    target_user_id,
    target_user_email,
    action_type,
    description,
    details
  ) VALUES (
    NEW.id, -- Self-registration
    NEW.email, -- Admin email = user email for self-registration
    NEW.id,
    NEW.email, -- Target email = user email
    'USER_REGISTRATION',
    'New user account created: ' || NEW.email,
    jsonb_build_object(
      'email', NEW.email,
      'role', default_role,
      'registration_method', CASE 
        WHEN NEW.is_anonymous THEN 'anonymous'
        WHEN NEW.app_metadata->>'provider' = 'google' THEN 'google_oauth'
        WHEN NEW.app_metadata->>'provider' = 'github' THEN 'github_oauth'
        ELSE 'email_password'
      END,
      'email_domain', SPLIT_PART(NEW.email, '@', 2)
    )
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