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
  
  -- Log new user registration in audit table (CRITICAL for security tracking)
  INSERT INTO admin_audit_log (
    admin_user_id,
    target_user_id,
    action_type,
    reason,
    old_values,
    new_values,
    action_details
  ) VALUES (
    NEW.id, -- Self-registration
    NEW.id,
    'USER_REGISTRATION',
    'New user account created',
    jsonb_build_object(
      'user_exists', false
    ),
    jsonb_build_object(
      'user_id', NEW.id,
      'email', NEW.email,
      'role', default_role,
      'email_confirmed_at', NEW.email_confirmed_at,
      'created_at', NEW.created_at,
      'is_anonymous', NEW.is_anonymous,
      'provider', COALESCE(NEW.app_metadata->>'provider', 'email')
    ),
    jsonb_build_object(
      'action', 'user_registered',
      'registration_method', CASE 
        WHEN NEW.is_anonymous THEN 'anonymous'
        WHEN NEW.app_metadata->>'provider' = 'google' THEN 'google_oauth'
        WHEN NEW.app_metadata->>'provider' = 'github' THEN 'github_oauth'
        ELSE 'email_password'
      END,
      'default_role_assigned', default_role,
      'email_domain', SPLIT_PART(NEW.email, '@', 2),
      'requires_email_confirmation', CASE 
        WHEN NEW.email_confirmed_at IS NULL THEN true
        ELSE false
      END,
      'security_impact', 'medium',
      'auto_assigned_role', true,
      'account_type', 'standard'
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