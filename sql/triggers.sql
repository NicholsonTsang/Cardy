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