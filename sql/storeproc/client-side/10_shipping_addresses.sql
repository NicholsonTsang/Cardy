-- =================================================================
-- SHIPPING ADDRESS FUNCTIONS
-- Functions for managing user shipping addresses
-- =================================================================

-- Get all shipping addresses for the current user
CREATE OR REPLACE FUNCTION get_user_shipping_addresses()
RETURNS TABLE (
    id UUID,
    label TEXT,
    recipient_name TEXT,
    address_line_1 TEXT,
    address_line_2 TEXT,
    city TEXT,
    state_province TEXT,
    postal_code TEXT,
    country TEXT,
    phone TEXT,
    is_default BOOLEAN,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ
) LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
    RETURN QUERY
    SELECT 
        sa.id,
        sa.label,
        sa.recipient_name,
        sa.address_line_1,
        sa.address_line_2,
        sa.city,
        sa.state_province,
        sa.postal_code,
        sa.country,
        sa.phone,
        sa.is_default,
        sa.created_at,
        sa.updated_at
    FROM shipping_addresses sa
    WHERE sa.user_id = auth.uid()
    ORDER BY sa.is_default DESC, sa.created_at DESC;
END;
$$;

-- Create a new shipping address
CREATE OR REPLACE FUNCTION create_shipping_address(
    p_label TEXT,
    p_recipient_name TEXT,
    p_address_line_1 TEXT,
    p_city TEXT,
    p_postal_code TEXT,
    p_country TEXT,
    p_address_line_2 TEXT DEFAULT NULL,
    p_state_province TEXT DEFAULT NULL,
    p_phone TEXT DEFAULT NULL,
    p_is_default BOOLEAN DEFAULT FALSE
) RETURNS UUID LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_address_id UUID;
BEGIN
    -- If this is being set as default, unset all other defaults first
    IF p_is_default THEN
        UPDATE shipping_addresses 
        SET is_default = FALSE, updated_at = NOW()
        WHERE user_id = auth.uid();
    END IF;
    
    INSERT INTO shipping_addresses (
        user_id,
        label,
        recipient_name,
        address_line_1,
        address_line_2,
        city,
        state_province,
        postal_code,
        country,
        phone,
        is_default
    ) VALUES (
        auth.uid(),
        p_label,
        p_recipient_name,
        p_address_line_1,
        p_address_line_2,
        p_city,
        p_state_province,
        p_postal_code,
        p_country,
        p_phone,
        p_is_default
    )
    RETURNING id INTO v_address_id;
    
    RETURN v_address_id;
END;
$$;

-- Update a shipping address
CREATE OR REPLACE FUNCTION update_shipping_address(
    p_address_id UUID,
    p_label TEXT,
    p_recipient_name TEXT,
    p_address_line_1 TEXT,
    p_city TEXT,
    p_postal_code TEXT,
    p_country TEXT,
    p_address_line_2 TEXT DEFAULT NULL,
    p_state_province TEXT DEFAULT NULL,
    p_phone TEXT DEFAULT NULL,
    p_is_default BOOLEAN DEFAULT FALSE
) RETURNS BOOLEAN LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_user_id UUID;
BEGIN
    -- Check if the user owns this address
    SELECT user_id INTO v_user_id FROM shipping_addresses WHERE id = p_address_id;
    
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Shipping address not found';
    END IF;
    
    IF v_user_id != auth.uid() THEN
        RAISE EXCEPTION 'Not authorized to update this shipping address';
    END IF;
    
    -- If this is being set as default, unset all other defaults first
    IF p_is_default THEN
        UPDATE shipping_addresses 
        SET is_default = FALSE, updated_at = NOW()
        WHERE user_id = auth.uid() AND id != p_address_id;
    END IF;
    
    UPDATE shipping_addresses
    SET 
        label = p_label,
        recipient_name = p_recipient_name,
        address_line_1 = p_address_line_1,
        address_line_2 = p_address_line_2,
        city = p_city,
        state_province = p_state_province,
        postal_code = p_postal_code,
        country = p_country,
        phone = p_phone,
        is_default = p_is_default,
        updated_at = NOW()
    WHERE id = p_address_id;
    
    RETURN FOUND;
END;
$$;

-- Delete a shipping address
CREATE OR REPLACE FUNCTION delete_shipping_address(p_address_id UUID)
RETURNS BOOLEAN LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_user_id UUID;
    v_is_default BOOLEAN;
    v_remaining_count INTEGER;
BEGIN
    -- Check if the user owns this address and get its default status
    SELECT user_id, is_default INTO v_user_id, v_is_default 
    FROM shipping_addresses 
    WHERE id = p_address_id;
    
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Shipping address not found';
    END IF;
    
    IF v_user_id != auth.uid() THEN
        RAISE EXCEPTION 'Not authorized to delete this shipping address';
    END IF;
    
    -- Delete the address
    DELETE FROM shipping_addresses WHERE id = p_address_id;
    
    -- If we deleted the default address, set another one as default
    IF v_is_default THEN
        -- Count remaining addresses
        SELECT COUNT(*) INTO v_remaining_count
        FROM shipping_addresses
        WHERE user_id = auth.uid();
        
        -- If there are remaining addresses, set the most recent one as default
        IF v_remaining_count > 0 THEN
            UPDATE shipping_addresses
            SET is_default = TRUE, updated_at = NOW()
            WHERE user_id = auth.uid()
            AND id = (
                SELECT id FROM shipping_addresses 
                WHERE user_id = auth.uid() 
                ORDER BY created_at DESC 
                LIMIT 1
            );
        END IF;
    END IF;
    
    RETURN FOUND;
END;
$$;

-- Set a shipping address as default
CREATE OR REPLACE FUNCTION set_default_shipping_address(p_address_id UUID)
RETURNS BOOLEAN LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_user_id UUID;
BEGIN
    -- Check if the user owns this address
    SELECT user_id INTO v_user_id FROM shipping_addresses WHERE id = p_address_id;
    
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Shipping address not found';
    END IF;
    
    IF v_user_id != auth.uid() THEN
        RAISE EXCEPTION 'Not authorized to modify this shipping address';
    END IF;
    
    -- Unset all other defaults first
    UPDATE shipping_addresses 
    SET is_default = FALSE, updated_at = NOW()
    WHERE user_id = auth.uid();
    
    -- Set this address as default
    UPDATE shipping_addresses
    SET is_default = TRUE, updated_at = NOW()
    WHERE id = p_address_id;
    
    RETURN FOUND;
END;
$$;

-- Format shipping address for display/printing
CREATE OR REPLACE FUNCTION format_shipping_address(p_address_id UUID)
RETURNS TEXT LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_address RECORD;
    v_formatted_address TEXT;
BEGIN
    -- Get the address details
    SELECT * INTO v_address
    FROM shipping_addresses
    WHERE id = p_address_id;
    
    IF NOT FOUND THEN
        RETURN NULL;
    END IF;
    
    -- Format the address
    v_formatted_address := v_address.recipient_name || E'\n' ||
                          v_address.address_line_1;
    
    -- Add second address line if present
    IF v_address.address_line_2 IS NOT NULL AND v_address.address_line_2 != '' THEN
        v_formatted_address := v_formatted_address || E'\n' || v_address.address_line_2;
    END IF;
    
    -- Add city, state/province, postal code
    v_formatted_address := v_formatted_address || E'\n' || v_address.city;
    
    IF v_address.state_province IS NOT NULL AND v_address.state_province != '' THEN
        v_formatted_address := v_formatted_address || ', ' || v_address.state_province;
    END IF;
    
    v_formatted_address := v_formatted_address || ' ' || v_address.postal_code;
    
    -- Add country
    v_formatted_address := v_formatted_address || E'\n' || v_address.country;
    
    -- Add phone if present
    IF v_address.phone IS NOT NULL AND v_address.phone != '' THEN
        v_formatted_address := v_formatted_address || E'\nPhone: ' || v_address.phone;
    END IF;
    
    RETURN v_formatted_address;
END;
$$; 