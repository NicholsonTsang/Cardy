-- Migration: Fix admin_update_print_request_status function to handle null reason
-- Description: Provide default reason when admin_notes is null to satisfy NOT NULL constraint

CREATE OR REPLACE FUNCTION admin_update_print_request_status(
    p_request_id UUID,
    p_new_status "PrintRequestStatus",
    p_admin_notes TEXT DEFAULT NULL
)
RETURNS BOOLEAN LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_request_record RECORD;
    caller_role TEXT;
BEGIN
    -- Check if the caller is an admin
    SELECT raw_user_meta_data->>'role' INTO caller_role
    FROM auth.users
    WHERE id = auth.uid();

    IF caller_role != 'admin' THEN
        RAISE EXCEPTION 'Only admins can update print request status.';
    END IF;

    -- Get current request details
    SELECT pr.*, c.name as card_name, cb.batch_name
    INTO v_request_record
    FROM print_requests pr
    JOIN card_batches cb ON pr.batch_id = cb.id
    JOIN cards c ON cb.card_id = c.id
    WHERE pr.id = p_request_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Print request not found.';
    END IF;

    -- Update the print request
    UPDATE print_requests
    SET 
        status = p_new_status,
        admin_notes = CASE 
            WHEN p_admin_notes IS NULL THEN admin_notes
            WHEN admin_notes IS NULL OR admin_notes = '' THEN p_admin_notes
            ELSE admin_notes || E'\n\n[' || NOW()::DATE || '] ' || p_admin_notes
        END,
        updated_at = NOW()
    WHERE id = p_request_id;

    -- Log the status change in audit table with default reason if notes are null
    INSERT INTO admin_audit_log (
        admin_user_id,
        target_user_id,
        action_type,
        reason,
        old_values,
        new_values,
        action_details
    ) VALUES (
        auth.uid(),
        v_request_record.user_id,
        'PRINT_REQUEST_STATUS_UPDATE',
        COALESCE(p_admin_notes, 'Print request status updated to ' || p_new_status),
        jsonb_build_object(
            'status', v_request_record.status
        ),
        jsonb_build_object(
            'status', p_new_status,
            'admin_notes', p_admin_notes
        ),
        jsonb_build_object(
            'request_id', p_request_id,
            'batch_id', v_request_record.batch_id,
            'card_name', v_request_record.card_name,
            'batch_name', v_request_record.batch_name
        )
    );
    
    RETURN FOUND;
END;
$$;