-- Simple version: Drop all Cardy CMS functions
-- Add this at the beginning of your deployment to ensure clean state

DO $$
DECLARE
    r RECORD;
BEGIN
    -- Drop all functions that are likely from Cardy CMS
    FOR r IN 
        SELECT format('DROP FUNCTION IF EXISTS %I(%s) CASCADE', 
                     p.proname, 
                     pg_get_function_identity_arguments(p.oid)) as drop_cmd
        FROM pg_proc p
        JOIN pg_namespace n ON p.pronamespace = n.oid
        WHERE n.nspname = 'public'
        AND p.prokind = 'f'
        AND p.proname IN (
            -- Card management functions
            'create_card', 'update_card', 'delete_card', 'get_card_by_id',
            'get_user_cards', 'duplicate_card',
            
            -- Content management functions
            'create_content_item', 'update_content_item', 'delete_content_item',
            'get_content_items', 'reorder_content_items', 'update_content_item_parent',
            
            -- User management functions
            'get_or_create_user_profile', 'update_user_profile', 'get_user_profile_status',
            'submit_user_verification', 'upload_verification_document',
            
            -- Batch management functions
            'get_next_batch_number', 'issue_card_batch', 'get_card_batches',
            'get_issued_cards_with_batch', 'toggle_card_batch_disabled_status',
            'activate_issued_card', 'get_card_issuance_stats', 'delete_issued_card',
            'generate_batch_cards',
            
            -- Payment management functions
            'create_batch_payment', 'update_batch_payment_status', 'get_batch_payment_info',
            'confirm_batch_payment', 'process_stripe_payment',
            
            -- Print request functions
            'request_card_printing', 'get_print_requests_for_batch', 'withdraw_print_request',
            'get_user_print_requests',
            
            -- Public access functions
            'get_public_card_content', 'get_sample_issued_card_for_preview',
            'get_card_preview_access',
            
            -- Admin functions
            'admin_confirm_batch_payment', 'admin_waive_batch_payment',
            'get_user_all_issued_cards', 'get_user_issuance_stats',
            'get_user_all_card_batches', 'get_user_recent_activity',
            'admin_update_user_role', 'admin_update_verification_status',
            'admin_get_user_verification_details', 'admin_reset_user_verification',
            'admin_get_platform_stats', 'admin_get_pending_verifications',
            'admin_get_all_users', 'admin_update_print_request_status',
            'admin_get_all_print_requests', 'admin_add_print_notes',
            'admin_get_batch_details', 'admin_get_all_batches',
            'admin_disable_batch', 'admin_generate_cards_for_batch'
        )
    LOOP
        EXECUTE r.drop_cmd;
    END LOOP;
    
    RAISE NOTICE 'All Cardy CMS functions dropped';
END $$;