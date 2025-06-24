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

-- SELECT: Users can read their own cards, admins can read all, anon can read published
DROP POLICY IF EXISTS "Allow card reads" ON cards;
CREATE POLICY "Allow card reads"
ON cards FOR SELECT
USING (
    auth.uid() = user_id OR 
    auth.jwt()->>'role' = 'admin' OR
    (auth.role() = 'anon' AND published = TRUE)
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

-- SELECT: Users can read content for their cards, admins all, anon for published cards
DROP POLICY IF EXISTS "Allow content reads" ON content_items;
CREATE POLICY "Allow content reads"
ON content_items FOR SELECT
USING (
    auth.jwt()->>'role' = 'admin' OR
    EXISTS (SELECT 1 FROM cards c WHERE c.id = content_items.card_id AND 
        (c.user_id = auth.uid() OR (auth.role() = 'anon' AND c.published = TRUE)))
);

-- MODIFICATIONS: Admin only (forces stored procedure usage)
DROP POLICY IF EXISTS "Admin only modifications on content_items" ON content_items;
CREATE POLICY "Admin only modifications on content_items"
ON content_items FOR ALL
USING (auth.jwt()->>'role' = 'admin')
WITH CHECK (auth.jwt()->>'role' = 'admin');

-- =================================================================
-- CARD_BATCHES TABLE POLICIES
-- =================================================================
ALTER TABLE card_batches ENABLE ROW LEVEL SECURITY;

-- SELECT: Users can read batches for their cards, admins can read all
DROP POLICY IF EXISTS "Allow batch reads" ON card_batches;
CREATE POLICY "Allow batch reads"
ON card_batches FOR SELECT 
USING (
    auth.jwt()->>'role' = 'admin' OR
    EXISTS (SELECT 1 FROM cards c WHERE c.id = card_batches.card_id AND c.user_id = auth.uid())
);

-- MODIFICATIONS: Admin only (forces stored procedure usage)
DROP POLICY IF EXISTS "Admin only modifications on card_batches" ON card_batches;
CREATE POLICY "Admin only modifications on card_batches"
ON card_batches FOR ALL
USING (auth.jwt()->>'role' = 'admin')
WITH CHECK (auth.jwt()->>'role' = 'admin');

-- =================================================================
-- ISSUE_CARDS TABLE POLICIES
-- =================================================================
ALTER TABLE issue_cards ENABLE ROW LEVEL SECURITY;

-- SELECT: Users can read issued cards for their designs, admins all, anon for published cards
DROP POLICY IF EXISTS "Allow issued card reads" ON issue_cards;
CREATE POLICY "Allow issued card reads"
ON issue_cards FOR SELECT 
USING (
    auth.jwt()->>'role' = 'admin' OR
    EXISTS (SELECT 1 FROM cards c WHERE c.id = issue_cards.card_id AND 
        (c.user_id = auth.uid() OR (auth.role() = 'anon' AND c.published = TRUE)))
);

-- UPDATE: Allow anon activation only (specific stored procedure operation)
DROP POLICY IF EXISTS "Allow anon activation only" ON issue_cards;
CREATE POLICY "Allow anon activation only"
ON issue_cards FOR UPDATE 
TO anon
USING (
    EXISTS (SELECT 1 FROM cards c WHERE c.id = issue_cards.card_id AND c.published = TRUE)
    )
WITH CHECK (TRUE); -- Validation handled by stored procedure

-- MODIFICATIONS: Admin only for other operations (forces stored procedure usage)
DROP POLICY IF EXISTS "Admin only modifications on issue_cards" ON issue_cards;
CREATE POLICY "Admin only modifications on issue_cards"
ON issue_cards FOR ALL
USING (auth.jwt()->>'role' = 'admin')
WITH CHECK (auth.jwt()->>'role' = 'admin');

-- =================================================================
-- PRINT_REQUESTS TABLE POLICIES
-- =================================================================
ALTER TABLE print_requests ENABLE ROW LEVEL SECURITY;

-- SELECT: Users can read requests for their cards, admins can read all
DROP POLICY IF EXISTS "Allow print request reads" ON print_requests;
CREATE POLICY "Allow print request reads"
ON print_requests FOR SELECT
USING (
    auth.jwt()->>'role' = 'admin' OR
    user_id = auth.uid() OR
    EXISTS (SELECT 1 FROM card_batches cb JOIN cards c ON cb.card_id = c.id 
        WHERE cb.id = print_requests.batch_id AND c.user_id = auth.uid())
);

-- MODIFICATIONS: Admin only (forces stored procedure usage)
DROP POLICY IF EXISTS "Admin only modifications on print_requests" ON print_requests;
CREATE POLICY "Admin only modifications on print_requests"
ON print_requests FOR ALL
USING (auth.jwt()->>'role' = 'admin')
WITH CHECK (auth.jwt()->>'role' = 'admin');

-- =================================================================
-- USER_PROFILES TABLE POLICIES
-- =================================================================
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

-- SELECT: Users can read their own profile, admins can read all
DROP POLICY IF EXISTS "Allow profile reads" ON user_profiles;
CREATE POLICY "Allow profile reads"
ON user_profiles FOR SELECT
USING (auth.uid() = user_id OR auth.jwt()->>'role' = 'admin');

-- INSERT: Users can create their own profile only
DROP POLICY IF EXISTS "Allow profile creation" ON user_profiles;
CREATE POLICY "Allow profile creation"
ON user_profiles FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- UPDATE/DELETE: Admin only (forces stored procedure usage for verification management)
DROP POLICY IF EXISTS "Admin only profile modifications" ON user_profiles;
CREATE POLICY "Admin only profile updates"
ON user_profiles FOR UPDATE
USING (auth.jwt()->>'role' = 'admin')
WITH CHECK (auth.jwt()->>'role' = 'admin');

CREATE POLICY "Admin only profile deletions"
ON user_profiles FOR DELETE
USING (auth.jwt()->>'role' = 'admin');

-- =================================================================
-- SHIPPING_ADDRESSES TABLE POLICIES
-- =================================================================
ALTER TABLE shipping_addresses ENABLE ROW LEVEL SECURITY;

-- SELECT: Users can read their own addresses, admins can read all
DROP POLICY IF EXISTS "Allow shipping address reads" ON shipping_addresses;
CREATE POLICY "Allow shipping address reads"
ON shipping_addresses FOR SELECT
USING (auth.uid() = user_id OR auth.jwt()->>'role' = 'admin');

-- INSERT: Users can create their own addresses only
DROP POLICY IF EXISTS "Allow shipping address creation" ON shipping_addresses;
CREATE POLICY "Allow shipping address creation"
ON shipping_addresses FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- UPDATE: Users can update their own addresses, admins can update all
DROP POLICY IF EXISTS "Allow shipping address updates" ON shipping_addresses;
CREATE POLICY "Allow shipping address updates"
ON shipping_addresses FOR UPDATE
USING (auth.uid() = user_id OR auth.jwt()->>'role' = 'admin')
WITH CHECK (auth.uid() = user_id OR auth.jwt()->>'role' = 'admin');

-- DELETE: Users can delete their own addresses, admins can delete all
DROP POLICY IF EXISTS "Allow shipping address deletions" ON shipping_addresses;
CREATE POLICY "Allow shipping address deletions"
ON shipping_addresses FOR DELETE
USING (auth.uid() = user_id OR auth.jwt()->>'role' = 'admin');

-- =================================================================
-- CLEANUP OLD POLICIES
-- =================================================================
-- Remove any remaining old policies that might conflict
DROP POLICY IF EXISTS "Users can view their own cards" ON cards;
DROP POLICY IF EXISTS "Anonymous users can view published cards" ON cards;
DROP POLICY IF EXISTS "Allow full access to admins" ON cards;
DROP POLICY IF EXISTS "Users can view content items for their cards" ON content_items;
DROP POLICY IF EXISTS "Anonymous users can view content items of published cards" ON content_items;
DROP POLICY IF EXISTS "Allow full access to admins on content_items" ON content_items;
DROP POLICY IF EXISTS "Users can view their own card batches" ON card_batches;
DROP POLICY IF EXISTS "Allow full access to admins on card_batches" ON card_batches;
DROP POLICY IF EXISTS "Users can view their own issued cards" ON issue_cards;
DROP POLICY IF EXISTS "Anonymous users can view specific issued cards for activation" ON issue_cards;
DROP POLICY IF EXISTS "Anonymous users can activate issued cards" ON issue_cards;
DROP POLICY IF EXISTS "Users can delete their own issued cards" ON issue_cards;
DROP POLICY IF EXISTS "Allow full access to admins on issue_cards" ON issue_cards;
DROP POLICY IF EXISTS "Users can view print requests for their card batches" ON print_requests;
DROP POLICY IF EXISTS "Allow full access to admins on print_requests" ON print_requests;
DROP POLICY IF EXISTS "Users can view their own profile" ON user_profiles;
DROP POLICY IF EXISTS "Users can create their own profile" ON user_profiles;
DROP POLICY IF EXISTS "Users can update their own basic profile" ON user_profiles;
DROP POLICY IF EXISTS "Allow full access to admins on user_profiles" ON user_profiles;
