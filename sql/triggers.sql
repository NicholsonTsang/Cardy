-- =================================================================
-- GENERIC TIMESTAMP UPDATE TRIGGER
-- =================================================================
-- Function for updating timestamps
-- MOVED TO sql/schemaStoreProc.sql

-- Triggers for 'updated_at' column
-- Cards
DROP TRIGGER IF EXISTS update_cards_updated_at ON public.cards;
CREATE TRIGGER update_cards_updated_at
    BEFORE UPDATE ON public.cards
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at();

-- Content items
DROP TRIGGER IF EXISTS update_content_items_updated_at ON public.content_items;
CREATE TRIGGER update_content_items_updated_at
    BEFORE UPDATE ON public.content_items
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at();

-- Card batches
DROP TRIGGER IF EXISTS update_card_batches_updated_at ON public.card_batches;
CREATE TRIGGER update_card_batches_updated_at
    BEFORE UPDATE ON public.card_batches
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at();

-- Issued cards
DROP TRIGGER IF EXISTS update_issue_cards_updated_at ON public.issue_cards;
CREATE TRIGGER update_issue_cards_updated_at
    BEFORE UPDATE ON public.issue_cards
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at();

-- Print requests
DROP TRIGGER IF EXISTS update_print_requests_updated_at ON public.print_requests;
CREATE TRIGGER update_print_requests_updated_at
    BEFORE UPDATE ON public.print_requests
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at();

-- =================================================================
-- AUTH RELATED TRIGGERS
-- =================================================================
-- Function to set default role for new users
-- MOVED TO sql/schemaStoreProc.sql

-- Trigger to call the function upon new user creation
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Grant execute permission on the function to Supabase internal roles
-- MOVED TO sql/schemaStoreProc.sql (with the function)

-- Note: For the trigger to work on auth.users, the database user that Supabase uses for its internal operations
-- (often `supabase_auth_admin` or a similar role) must have permissions to run the trigger function, 
-- and the function itself needs appropriate permissions (SECURITY DEFINER) if it modifies tables like auth.users.
-- The `SECURITY DEFINER` on `handle_new_user` and granting execute to `supabase_auth_admin` addresses this. 
-- (Function and its grant moved to sql/schemaStoreProc.sql)

-- =================================================================
-- TRANSLATION CONTENT HASH TRIGGERS
-- =================================================================
-- These triggers automatically calculate content_hash on INSERT and UPDATE
-- to enable translation freshness detection
-- =================================================================

-- Trigger function for cards table
CREATE OR REPLACE FUNCTION update_card_content_hash()
RETURNS TRIGGER AS $$
BEGIN
  -- On INSERT: Always calculate hash
  IF TG_OP = 'INSERT' THEN
    NEW.content_hash := md5(COALESCE(NEW.name, '') || '|' || COALESCE(NEW.description, ''));
    NEW.last_content_update := NOW();
  -- On UPDATE: Only recalculate if name or description changed
  ELSIF TG_OP = 'UPDATE' THEN
    IF (NEW.name IS DISTINCT FROM OLD.name) OR 
       (NEW.description IS DISTINCT FROM OLD.description) THEN
      NEW.content_hash := md5(COALESCE(NEW.name, '') || '|' || COALESCE(NEW.description, ''));
      NEW.last_content_update := NOW();
      -- Note: We don't clear translations here - they're marked as outdated via hash comparison
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Drop existing trigger if exists
DROP TRIGGER IF EXISTS trigger_update_card_content_hash ON cards;

-- Create trigger for cards (both INSERT and UPDATE)
CREATE TRIGGER trigger_update_card_content_hash
  BEFORE INSERT OR UPDATE ON cards
  FOR EACH ROW
  EXECUTE FUNCTION update_card_content_hash();

-- Trigger function for content_items table
CREATE OR REPLACE FUNCTION update_content_item_content_hash()
RETURNS TRIGGER AS $$
BEGIN
  -- On INSERT: Always calculate hash
  IF TG_OP = 'INSERT' THEN
    NEW.content_hash := md5(
      COALESCE(NEW.name, '') || '|' || 
      COALESCE(NEW.content, '') || '|' ||
      COALESCE(NEW.ai_knowledge_base, '')
    );
    NEW.last_content_update := NOW();
  -- On UPDATE: Only recalculate if any translatable field changed
  ELSIF TG_OP = 'UPDATE' THEN
    IF (NEW.name IS DISTINCT FROM OLD.name) OR 
       (NEW.content IS DISTINCT FROM OLD.content) OR
       (NEW.ai_knowledge_base IS DISTINCT FROM OLD.ai_knowledge_base) THEN
      NEW.content_hash := md5(
        COALESCE(NEW.name, '') || '|' || 
        COALESCE(NEW.content, '') || '|' ||
        COALESCE(NEW.ai_knowledge_base, '')
      );
      NEW.last_content_update := NOW();
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Drop existing trigger if exists
DROP TRIGGER IF EXISTS trigger_update_content_item_content_hash ON content_items;

-- Create trigger for content_items (both INSERT and UPDATE)
CREATE TRIGGER trigger_update_content_item_content_hash
  BEFORE INSERT OR UPDATE ON content_items
  FOR EACH ROW
  EXECUTE FUNCTION update_content_item_content_hash();