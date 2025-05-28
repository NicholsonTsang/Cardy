-- Enable Row Level Security for cards
ALTER TABLE cards ENABLE ROW LEVEL SECURITY;

-- Card policies
DROP POLICY IF EXISTS "Users can view their own cards" ON cards;
CREATE POLICY "Users can view their own cards" 
ON cards FOR SELECT 
USING (user_id = auth.uid());

DROP POLICY IF EXISTS "Users can insert their own cards" ON cards;
CREATE POLICY "Users can insert their own cards" 
ON cards FOR INSERT 
WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "Users can update their own cards" ON cards;
CREATE POLICY "Users can update their own cards" 
ON cards FOR UPDATE 
USING (user_id = auth.uid());

DROP POLICY IF EXISTS "Users can delete their own cards" ON cards;
CREATE POLICY "Users can delete their own cards" 
ON cards FOR DELETE 
USING (user_id = auth.uid());

-- Enable Row Level Security for content_items
ALTER TABLE content_items ENABLE ROW LEVEL SECURITY;

-- Content items policies
DROP POLICY IF EXISTS "Users can view content items of their cards" ON content_items;
CREATE POLICY "Users can view content items of their cards" 
ON content_items FOR SELECT 
USING (
    EXISTS (
        SELECT 1 FROM cards 
        WHERE cards.id = content_items.card_id 
        AND cards.user_id = auth.uid()
    )
);

DROP POLICY IF EXISTS "Users can insert content items to their cards" ON content_items;
CREATE POLICY "Users can insert content items to their cards" 
ON content_items FOR INSERT 
WITH CHECK (
    EXISTS (
        SELECT 1 FROM cards 
        WHERE cards.id = content_items.card_id 
        AND cards.user_id = auth.uid()
    )
);

DROP POLICY IF EXISTS "Users can update content items of their cards" ON content_items;
CREATE POLICY "Users can update content items of their cards" 
ON content_items FOR UPDATE 
USING (
    EXISTS (
        SELECT 1 FROM cards 
        WHERE cards.id = content_items.card_id 
        AND cards.user_id = auth.uid()
    )
);

DROP POLICY IF EXISTS "Users can delete content items of their cards" ON content_items;
CREATE POLICY "Users can delete content items of their cards" 
ON content_items FOR DELETE 
USING (
    EXISTS (
        SELECT 1 FROM cards 
        WHERE cards.id = content_items.card_id 
        AND cards.user_id = auth.uid()
    )
);

-- Enable Row Level Security for card_batches
ALTER TABLE card_batches ENABLE ROW LEVEL SECURITY;

-- Card batches policies
DROP POLICY IF EXISTS "Users can view their own card batches" ON card_batches;
CREATE POLICY "Users can view their own card batches" 
ON card_batches FOR SELECT 
USING (
    EXISTS (
        SELECT 1 FROM cards 
        WHERE cards.id = card_batches.card_id 
        AND cards.user_id = auth.uid()
    )
);

DROP POLICY IF EXISTS "Users can insert their own card batches" ON card_batches;
CREATE POLICY "Users can insert their own card batches" 
ON card_batches FOR INSERT 
WITH CHECK (
    EXISTS (
        SELECT 1 FROM cards 
        WHERE cards.id = card_batches.card_id 
        AND cards.user_id = auth.uid()
    )
);

DROP POLICY IF EXISTS "Users can update their own card batches" ON card_batches;
CREATE POLICY "Users can update their own card batches" 
ON card_batches FOR UPDATE 
USING (
    EXISTS (
        SELECT 1 FROM cards 
        WHERE cards.id = card_batches.card_id 
        AND cards.user_id = auth.uid()
    )
);

DROP POLICY IF EXISTS "Users can delete their own card batches" ON card_batches;
CREATE POLICY "Users can delete their own card batches" 
ON card_batches FOR DELETE 
USING (
    EXISTS (
        SELECT 1 FROM cards 
        WHERE cards.id = card_batches.card_id 
        AND cards.user_id = auth.uid()
    )
);

-- Enable Row Level Security for issue_cards
ALTER TABLE issue_cards ENABLE ROW LEVEL SECURITY;

-- Issue cards policies
DROP POLICY IF EXISTS "Users can view their own issued cards" ON issue_cards;
CREATE POLICY "Users can view their own issued cards" 
ON issue_cards FOR SELECT 
USING (
    EXISTS (
        SELECT 1 FROM cards 
        WHERE cards.id = issue_cards.card_id 
        AND cards.user_id = auth.uid()
    )
);

DROP POLICY IF EXISTS "Users can insert their own issued cards" ON issue_cards;
CREATE POLICY "Users can insert their own issued cards" 
ON issue_cards FOR INSERT 
WITH CHECK (
    EXISTS (
        SELECT 1 FROM cards 
        WHERE cards.id = issue_cards.card_id 
        AND cards.user_id = auth.uid()
    )
);

DROP POLICY IF EXISTS "Users can update their own issued cards" ON issue_cards;
CREATE POLICY "Users can update their own issued cards" 
ON issue_cards FOR UPDATE 
USING (
    EXISTS (
        SELECT 1 FROM cards 
        WHERE cards.id = issue_cards.card_id 
        AND cards.user_id = auth.uid()
    )
);

DROP POLICY IF EXISTS "Users can delete their own issued cards" ON issue_cards;
CREATE POLICY "Users can delete their own issued cards" 
ON issue_cards FOR DELETE 
USING (
    EXISTS (
        SELECT 1 FROM cards 
        WHERE cards.id = issue_cards.card_id 
        AND cards.user_id = auth.uid()
    )
);

-- Enable Row Level Security for print_requests
ALTER TABLE print_requests ENABLE ROW LEVEL SECURITY;

-- Print requests policies
DROP POLICY IF EXISTS "Users can view print requests for their card batches" ON print_requests;
CREATE POLICY "Users can view print requests for their card batches"
ON print_requests FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM card_batches cb
        JOIN cards c ON cb.card_id = c.id
        WHERE cb.id = print_requests.batch_id
        AND c.user_id = auth.uid()
    )
);

DROP POLICY IF EXISTS "Users can insert print requests for their card batches" ON print_requests;
CREATE POLICY "Users can insert print requests for their card batches"
ON print_requests FOR INSERT
WITH CHECK (
    print_requests.user_id = auth.uid() AND
    EXISTS (
        SELECT 1 FROM card_batches cb
        JOIN cards c ON cb.card_id = c.id
        WHERE cb.id = print_requests.batch_id
        AND c.user_id = auth.uid()
    )
);

DROP POLICY IF EXISTS "Users can update their own print requests" ON print_requests;
CREATE POLICY "Users can update their own print requests"
ON print_requests FOR UPDATE
USING (
    print_requests.user_id = auth.uid() AND
    EXISTS (
        SELECT 1 FROM card_batches cb
        JOIN cards c ON cb.card_id = c.id
        WHERE cb.id = print_requests.batch_id
        AND c.user_id = auth.uid()
    )
)
WITH CHECK (
    print_requests.user_id = auth.uid() -- Ensure user_id cannot be changed to someone else
    -- Further specific field/status update checks can be handled by RPCs if needed
);

-- Note: No direct DELETE policy for users on print_requests. 
-- Cancellation should be a status update. Deletion would be an admin task.
