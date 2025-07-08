-- =================================================================
-- PAYMENT MANAGEMENT FUNCTIONS (CLIENT-SIDE)
-- Functions called by Vue.js frontend application
-- =================================================================

-- Get batch payment information (Used by frontend)
CREATE OR REPLACE FUNCTION get_batch_payment_info(p_batch_id UUID)
RETURNS TABLE (
    payment_id UUID,
    stripe_checkout_session_id TEXT,
    stripe_payment_intent_id TEXT,
    amount_cents INTEGER,
    currency TEXT,
    payment_status TEXT,
    payment_method TEXT,
    failure_reason TEXT,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ
) LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_batch_owner_id UUID;
BEGIN
    -- Check batch ownership
    SELECT created_by INTO v_batch_owner_id
    FROM card_batches 
    WHERE id = p_batch_id;
    
    IF v_batch_owner_id IS NULL THEN
        RAISE EXCEPTION 'Batch not found.';
    END IF;
    
    IF v_batch_owner_id != auth.uid() THEN
        RAISE EXCEPTION 'Not authorized to view payment info for this batch.';
    END IF;
    
    RETURN QUERY
    SELECT 
        bp.id as payment_id,
        bp.stripe_checkout_session_id,
        bp.stripe_payment_intent_id,
        bp.amount_cents,
        bp.currency,
        bp.payment_status,
        bp.payment_method,
        bp.failure_reason,
        bp.created_at,
        bp.updated_at
    FROM batch_payments bp
    WHERE bp.batch_id = p_batch_id;
END;
$$;