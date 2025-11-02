-- Drop all user-defined functions in the public schema
-- This will remove ALL custom functions before recreating them

DO $$
DECLARE
    func_record RECORD;
    drop_statement TEXT;
BEGIN
    -- Loop through all functions in public schema
    FOR func_record IN 
        SELECT 
            n.nspname as schema_name,
            p.proname as function_name,
            pg_get_function_identity_arguments(p.oid) as arguments
        FROM pg_proc p
        JOIN pg_namespace n ON p.pronamespace = n.oid
        WHERE n.nspname = 'public'  -- Only public schema
        AND p.prokind = 'f'          -- Only functions (not procedures)
        AND p.proname NOT LIKE 'pg_%'  -- Exclude PostgreSQL system functions
        AND p.proname NOT LIKE 'dblink%'  -- Exclude dblink functions
        AND p.proname NOT IN (         -- Exclude other system functions
            'armor', 'crypt', 'dearmor', 'decrypt', 'decrypt_iv',
            'digest', 'encrypt', 'encrypt_iv', 'gen_random_bytes',
            'gen_random_uuid', 'gen_salt', 'hmac', 'pgp_armor_headers',
            'pgp_key_id', 'pgp_pub_decrypt', 'pgp_pub_decrypt_bytea',
            'pgp_pub_encrypt', 'pgp_pub_encrypt_bytea', 'pgp_sym_decrypt',
            'pgp_sym_decrypt_bytea', 'pgp_sym_encrypt', 'pgp_sym_encrypt_bytea'
        )
    LOOP
        -- Build DROP statement
        drop_statement := format('DROP FUNCTION IF EXISTS %I.%I(%s) CASCADE',
            func_record.schema_name,
            func_record.function_name,
            func_record.arguments
        );
        
        -- Execute DROP statement
        EXECUTE drop_statement;
        
        -- Optional: Print what was dropped
        RAISE NOTICE 'Dropped function: %.%(%)', 
            func_record.schema_name, 
            func_record.function_name, 
            func_record.arguments;
    END LOOP;
    
    RAISE NOTICE 'All user-defined functions dropped successfully';
END $$;