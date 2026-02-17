-- =================================================================
-- SIMPLIFIED RLS POLICIES FOR STORED PROCEDURE-DRIVEN ARCHITECTURE
-- =================================================================
-- Since all business operations use SECURITY DEFINER stored procedures,
-- these policies focus on preventing direct table access while allowing
-- necessary reads and admin overrides.

-- =================================================================
-- CARDS TABLE POLICIES
-- =================================================================
ALTER TABLE cards ENABLE ROW LEVEL SECURITY;

-- SELECT: Users can read their own cards, admins can read all, anon can read all cards
DROP POLICY IF EXISTS "Allow card reads" ON cards;
CREATE POLICY "Allow card reads"
ON cards FOR SELECT
USING (
    auth.uid() = user_id OR 
    auth.jwt()->>'role' = 'admin' OR
    auth.role() = 'anon'
);

-- MODIFICATIONS: Only admins can directly modify (forces stored procedure usage)
DROP POLICY IF EXISTS "Admin only modifications on cards" ON cards;
CREATE POLICY "Admin only modifications on cards"
ON cards FOR ALL
USING (auth.jwt()->>'role' = 'admin')
WITH CHECK (auth.jwt()->>'role' = 'admin');

-- =================================================================
-- CONTENT_ITEMS TABLE POLICIES  
-- =================================================================
ALTER TABLE content_items ENABLE ROW LEVEL SECURITY;

-- SELECT: Users can read content for their cards, admins all, anon for all cards
DROP POLICY IF EXISTS "Allow content reads" ON content_items;
CREATE POLICY "Allow content reads"
ON content_items FOR SELECT
USING (
    auth.jwt()->>'role' = 'admin' OR
    EXISTS (SELECT 1 FROM cards c WHERE c.id = content_items.card_id AND 
        (c.user_id = auth.uid() OR auth.role() = 'anon'))
);

-- MODIFICATIONS: Admin only (forces stored procedure usage)
DROP POLICY IF EXISTS "Admin only modifications on content_items" ON content_items;
CREATE POLICY "Admin only modifications on content_items"
ON content_items FOR ALL
USING (auth.jwt()->>'role' = 'admin')
WITH CHECK (auth.jwt()->>'role' = 'admin');

-- =================================================================
-- CLEANUP OLD POLICIES (removed tables: card_batches, issue_cards, print_requests, user_profiles)
-- =================================================================
-- These DROP statements clean up policies from removed tables
-- Safe to run even if tables/policies don't exist (IF EXISTS)

-- =================================================================
-- CREDIT SYSTEM TABLE POLICIES
-- =================================================================

-- USER_CREDITS TABLE
ALTER TABLE user_credits ENABLE ROW LEVEL SECURITY;

-- SELECT: Users can read their own credits, admins can read all
DROP POLICY IF EXISTS "Users read own credits" ON user_credits;
CREATE POLICY "Users read own credits"
ON user_credits FOR SELECT
USING (
    auth.uid() = user_id OR 
    auth.jwt()->>'role' = 'admin'
);

-- MODIFICATIONS: Only through stored procedures (admin override)
DROP POLICY IF EXISTS "Admin only modifications on user_credits" ON user_credits;
CREATE POLICY "Admin only modifications on user_credits"
ON user_credits FOR ALL
USING (auth.jwt()->>'role' = 'admin')
WITH CHECK (auth.jwt()->>'role' = 'admin');

-- CREDIT_TRANSACTIONS TABLE
ALTER TABLE credit_transactions ENABLE ROW LEVEL SECURITY;

-- SELECT: Users can read their own transactions, admins can read all
DROP POLICY IF EXISTS "Users read own transactions" ON credit_transactions;
CREATE POLICY "Users read own transactions"
ON credit_transactions FOR SELECT
USING (
    auth.uid() = user_id OR 
    auth.jwt()->>'role' = 'admin'
);

-- MODIFICATIONS: Only through stored procedures (admin override)
DROP POLICY IF EXISTS "Admin only modifications on credit_transactions" ON credit_transactions;
CREATE POLICY "Admin only modifications on credit_transactions"
ON credit_transactions FOR ALL
USING (auth.jwt()->>'role' = 'admin')
WITH CHECK (auth.jwt()->>'role' = 'admin');

-- CREDIT_PURCHASES TABLE
ALTER TABLE credit_purchases ENABLE ROW LEVEL SECURITY;

-- SELECT: Users can read their own purchases, admins can read all
DROP POLICY IF EXISTS "Users read own purchases" ON credit_purchases;
CREATE POLICY "Users read own purchases"
ON credit_purchases FOR SELECT
USING (
    auth.uid() = user_id OR 
    auth.jwt()->>'role' = 'admin'
);

-- MODIFICATIONS: Only through stored procedures (admin override)
DROP POLICY IF EXISTS "Admin only modifications on credit_purchases" ON credit_purchases;
CREATE POLICY "Admin only modifications on credit_purchases"
ON credit_purchases FOR ALL
USING (auth.jwt()->>'role' = 'admin')
WITH CHECK (auth.jwt()->>'role' = 'admin');

-- CREDIT_CONSUMPTIONS TABLE
ALTER TABLE credit_consumptions ENABLE ROW LEVEL SECURITY;

-- SELECT: Users can read their own consumptions, admins can read all
DROP POLICY IF EXISTS "Users read own consumptions" ON credit_consumptions;
CREATE POLICY "Users read own consumptions"
ON credit_consumptions FOR SELECT
USING (
    auth.uid() = user_id OR 
    auth.jwt()->>'role' = 'admin'
);

-- MODIFICATIONS: Only through stored procedures (admin override)
DROP POLICY IF EXISTS "Admin only modifications on credit_consumptions" ON credit_consumptions;
CREATE POLICY "Admin only modifications on credit_consumptions"
ON credit_consumptions FOR ALL
USING (auth.jwt()->>'role' = 'admin')
WITH CHECK (auth.jwt()->>'role' = 'admin');
