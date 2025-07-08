-- =================================================================
-- USER-LEVEL ANALYTICS FUNCTIONS
-- Functions for user analytics and statistics across all cards
-- =================================================================

-- Get all issued cards for the current user across all their card designs
CREATE OR REPLACE FUNCTION get_user_all_issued_cards()
RETURNS TABLE (
    id UUID,
    card_id UUID,
    card_name TEXT,
    card_image_urls TEXT[],
    active BOOLEAN,
    issue_at TIMESTAMPTZ,
    active_at TIMESTAMPTZ,
    activated_by UUID,
    batch_id UUID,
    batch_name TEXT,
    batch_number INTEGER,
    batch_is_disabled BOOLEAN
) LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
    RETURN QUERY
    SELECT 
        ic.id,
        c.id as card_id,
        c.name as card_name,
        c.image_urls as card_image_urls,
        ic.active,
        ic.issue_at,
        ic.active_at,
        ic.activated_by,
        cb.id as batch_id,
        cb.batch_name,
        cb.batch_number,
        cb.is_disabled as batch_is_disabled
    FROM issue_cards ic
    JOIN card_batches cb ON ic.batch_id = cb.id
    JOIN cards c ON ic.card_id = c.id
    WHERE c.user_id = auth.uid()
    ORDER BY ic.issue_at DESC;
END;
$$;

-- Get aggregated statistics for all cards of the current user
CREATE OR REPLACE FUNCTION get_user_issuance_stats()
RETURNS TABLE (
    total_issued BIGINT,
    total_activated BIGINT,
    activation_rate NUMERIC,
    total_batches BIGINT,
    total_cards BIGINT,
    pending_cards BIGINT,
    disabled_batches BIGINT,
    active_print_requests BIGINT
) LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(ic.id) as total_issued,
        COUNT(ic.id) FILTER (WHERE ic.active = true) as total_activated,
        CASE 
            WHEN COUNT(ic.id) > 0 THEN 
                ROUND((COUNT(ic.id) FILTER (WHERE ic.active = true) * 100.0 / COUNT(ic.id)), 2)
            ELSE 0 
        END as activation_rate,
        COUNT(DISTINCT cb.id) as total_batches,
        COUNT(DISTINCT c.id) as total_cards,
        COUNT(ic.id) FILTER (WHERE ic.active = false) as pending_cards,
        COUNT(DISTINCT cb.id) FILTER (WHERE cb.is_disabled = true) as disabled_batches,
        COUNT(DISTINCT pr.id) FILTER (WHERE pr.status NOT IN ('COMPLETED', 'CANCELLED')) as active_print_requests
    FROM cards c
    LEFT JOIN card_batches cb ON c.id = cb.card_id
    LEFT JOIN issue_cards ic ON cb.id = ic.batch_id
    LEFT JOIN print_requests pr ON cb.id = pr.batch_id
    WHERE c.user_id = auth.uid();
END;
$$;

-- Get all card batches for the current user across all their card designs
CREATE OR REPLACE FUNCTION get_user_all_card_batches()
RETURNS TABLE (
    id UUID,
    card_id UUID,
    card_name TEXT,
    batch_name TEXT,
    batch_number INTEGER,
    cards_count INTEGER,
    active_cards_count BIGINT,
    is_disabled BOOLEAN,
    payment_required BOOLEAN,
    payment_completed BOOLEAN,
    payment_amount_cents INTEGER,
    payment_completed_at TIMESTAMPTZ,
    payment_waived BOOLEAN,
    payment_waived_by UUID,
    payment_waived_at TIMESTAMPTZ,
    payment_waiver_reason TEXT,
    cards_generated BOOLEAN,
    cards_generated_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ
) LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
    RETURN QUERY
    SELECT 
        cb.id,
        cb.card_id,
        c.name as card_name,
        cb.batch_name,
        cb.batch_number,
        cb.cards_count,
        COUNT(ic.id) FILTER (WHERE ic.active = true) as active_cards_count,
        cb.is_disabled,
        cb.payment_required,
        cb.payment_completed,
        cb.payment_amount_cents,
        cb.payment_completed_at,
        cb.payment_waived,
        cb.payment_waived_by,
        cb.payment_waived_at,
        cb.payment_waiver_reason,
        cb.cards_generated,
        cb.cards_generated_at,
        cb.created_at,
        cb.updated_at
    FROM card_batches cb
    LEFT JOIN issue_cards ic ON cb.id = ic.batch_id
    JOIN cards c ON cb.card_id = c.id
    WHERE c.user_id = auth.uid()
    GROUP BY cb.id, cb.card_id, c.name, cb.batch_name, cb.batch_number, cb.cards_count, cb.is_disabled, 
             cb.payment_required, cb.payment_completed, cb.payment_amount_cents, cb.payment_completed_at,
             cb.payment_waived, cb.payment_waived_by, cb.payment_waived_at, cb.payment_waiver_reason,
             cb.cards_generated, cb.cards_generated_at, cb.created_at, cb.updated_at
    ORDER BY cb.created_at DESC;
END;
$$;

-- Get recent issuance activity across all cards
CREATE OR REPLACE FUNCTION get_user_recent_activity(p_limit INTEGER DEFAULT 50)
RETURNS TABLE (
    activity_type TEXT,
    activity_date TIMESTAMPTZ,
    card_name TEXT,
    batch_name TEXT,
    description TEXT,
    count INTEGER
) LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
    RETURN QUERY
    (
        -- Recent batch creations
        SELECT 
            'batch_created'::TEXT as activity_type,
            cb.created_at as activity_date,
            c.name as card_name,
            cb.batch_name,
            'Batch created with ' || cb.cards_count || ' cards' as description,
            cb.cards_count as count
        FROM card_batches cb
        JOIN cards c ON cb.card_id = c.id
        WHERE c.user_id = auth.uid()
        
        UNION ALL
        
        -- Recent card activations
        SELECT 
            'card_activated'::TEXT as activity_type,
            ic.active_at as activity_date,
            c.name as card_name,
            cb.batch_name,
            'Card activated' as description,
            1 as count
        FROM issue_cards ic
        JOIN card_batches cb ON ic.batch_id = cb.id
        JOIN cards c ON ic.card_id = c.id
        WHERE c.user_id = auth.uid() AND ic.active_at IS NOT NULL
        
        UNION ALL
        
        -- Recent print requests
        SELECT 
            'print_requested'::TEXT as activity_type,
            pr.requested_at as activity_date,
            c.name as card_name,
            cb.batch_name,
            'Print request submitted' as description,
            cb.cards_count as count
        FROM print_requests pr
        JOIN card_batches cb ON pr.batch_id = cb.id
        JOIN cards c ON cb.card_id = c.id
        WHERE c.user_id = auth.uid()
    )
    ORDER BY activity_date DESC
    LIMIT p_limit;
END;
$$; 