-- Spa & Wellness Center - List Mode (Digital Access)
-- Template: Spa menu with treatments and services
-- 
-- INSTRUCTIONS:
-- 1. Replace 'YOUR_USER_ID_HERE' with actual user UUID
-- 2. Update image_url values with actual uploaded image URLs
-- 3. Run this SQL in Supabase SQL Editor or via psql

DO $body$
DECLARE
    v_user_id UUID := 'YOUR_USER_ID_HERE'::UUID;
    v_card_id UUID;
    v_cat_services UUID;
BEGIN
    -- Insert the card
    INSERT INTO cards (
        id, user_id, name, description, content_mode, is_grouped, group_display, billing_type,
        conversation_ai_enabled, ai_instruction, ai_knowledge_base,
        ai_welcome_general, ai_welcome_item, image_url,
        is_access_enabled, access_token
    ) VALUES (
        gen_random_uuid(),
        v_user_id,
        'Serenity Spa & Wellness',
        E'**Your Sanctuary of Calm**\n\nExperience transformative treatments designed to restore balance and vitality.\n\n📍 Grand Hotel, Level B1\n⏰ Daily 9:00 AM - 9:00 PM\n📞 Reservations: ext. 8888',
        'list',
        false,
        NULL,
        'digital',
        true,
        'You are a knowledgeable spa concierge. Help guests choose treatments based on their needs - relaxation, rejuvenation, pain relief, or skincare. Be warm and reassuring. Explain treatment benefits without medical claims. Suggest combinations and packages when appropriate.',
        E'Serenity Spa at Grand Hotel\nHours: 9:00 AM - 9:00 PM daily\n\nFacilities: 8 treatment rooms, couples suite, hydrotherapy pool, steam room, sauna, relaxation lounge\n\nProducts: Organic skincare line, essential oils, hot stones\n\nBooking: 24-hour advance recommended, same-day subject to availability\nCancellation: 4-hour notice required\n\nGratuity: 18-20% customary, not included in prices\nHealth forms required for first visit\nArrive 30 minutes early to enjoy facilities',
        'Welcome to Serenity Spa! I can recommend treatments for relaxation, pain relief, or skincare goals, explain what to expect during any service, suggest combinations, or help with booking. What brings you in today?',
        'Our {name} is wonderful! I can explain what happens during the treatment, suggest who it''s best for, discuss duration and pricing, or recommend add-ons. What would you like to know?',
        NULL,
        TRUE,
        replace(replace(encode(gen_random_bytes(9), 'base64'), '+', '-'), '/', '_')
    ) RETURNING id INTO v_card_id;

    -- Hidden Category for flat list
    INSERT INTO content_items (id, card_id, parent_id, name, content, ai_knowledge_base, sort_order)
    VALUES (gen_random_uuid(), v_card_id, NULL, 'Services', '', '', 1)
    RETURNING id INTO v_cat_services;

    -- Content Items
    INSERT INTO content_items (card_id, parent_id, name, content, image_url, ai_knowledge_base, sort_order) VALUES
    (v_card_id, v_cat_services, 'Signature Hot Stone Massage', E'**90 minutes | $195**\n\nWarm basalt stones melt away tension while skilled hands work deep into tired muscles. Our signature treatment combines Swedish and deep tissue techniques with heated stones placed along energy meridians.\n\n---\n\n✓ Full body treatment\n✓ Includes scalp massage\n✓ Aromatherapy oils\n\n*Best for: Deep relaxation, muscle tension, stress relief*', NULL, 'Most popular treatment. Stones heated to 130°F. Therapist uses combination of stones and hands. Good for those who like heat and medium-deep pressure. Not recommended if pregnant or have circulation issues. Pairs well with body scrub beforehand.', 1),
    
    (v_card_id, v_cat_services, 'Rejuvenating Facial', E'**60 minutes | $145**\n\nCustomized to your skin type, this results-driven facial includes deep cleansing, exfoliation, extractions, mask, and hydrating finish. Your therapist will analyze your skin and select the perfect products.\n\n---\n\n✓ Skin analysis included\n✓ All skin types\n✓ LED light therapy add-on available (+$35)\n\n*Best for: Dull skin, congestion, anti-aging*', NULL, 'Uses organic product line. Therapist customizes products based on skin analysis. Extractions are gentle - redness typically fades within 2 hours. LED add-on uses red light for collagen stimulation. No downtime. Avoid sun exposure for 24 hours after.', 2),
    
    (v_card_id, v_cat_services, 'Deep Tissue Massage', E'**60 minutes | $155 | 90 minutes | $215**\n\nFocused, therapeutic massage targeting chronic muscle tension and knots. Our therapists use sustained pressure and slow strokes to reach deeper layers of muscle and fascia.\n\n---\n\n✓ Pressure customized to tolerance\n✓ Focus areas available\n✓ Arnica gel finish\n\n*Best for: Athletes, chronic pain, injury recovery*', NULL, 'Firm to very firm pressure. Communicate with therapist about pressure - should feel "good hurt" not sharp pain. May cause soreness next day. Drink extra water after. 90-minute version recommended for full body; 60 minutes better for focus areas.', 3),
    
    (v_card_id, v_cat_services, 'Couples Retreat Package', E'**2.5 hours | $450 per couple**\n\nShare a romantic escape in our private couples suite. Begin with champagne and chocolate, followed by side-by-side massages. Conclude with time in the private jacuzzi.\n\n---\n\n✓ Private suite with jacuzzi\n✓ Champagne & artisan chocolates\n✓ 60-minute couples massage\n✓ Exclusive suite access (90 min)\n\n*Best for: Anniversaries, honeymoons, date nights*', NULL, 'Most romantic offering. Suite has two massage tables, private jacuzzi, fireplace, rain shower. Can upgrade to 90-minute massage. Book 48 hours ahead for suite. Peak times: Friday evening, weekends. Non-alcoholic option available. Can add rose petals and candles for special occasions (+$50).', 4),
    
    (v_card_id, v_cat_services, 'Express Refresh', E'**30 minutes | $85**\n\nShort on time? Our express treatments target key areas for maximum impact. Choose from:\n\n- **Back & Shoulders** - Release tension\n- **Scalp & Neck** - Relieve headaches\n- **Feet & Legs** - Restore tired legs\n\n---\n\n✓ No changing required\n✓ Same-day booking welcome\n✓ Combine two for 50-minute treatment\n\n*Best for: Busy schedules, lunch breaks, travel recovery*', NULL, 'Popular with business travelers and hotel guests. Can stay clothed for back/shoulders option. Scalp massage great for jet lag and headaches. Foot treatment uses reflexology points. Easy to fit between meetings. Often available same-day.', 5),
    
    (v_card_id, v_cat_services, 'Detox Body Wrap', E'**75 minutes | $175**\n\nPurify and tone with our signature body wrap. Begins with full-body exfoliation, followed by warm mineral mud application. Wrapped in thermal blankets, you''ll deeply relax while toxins are drawn out.\n\n---\n\n✓ Full-body exfoliation\n✓ Mineral-rich mud mask\n✓ Scalp massage during wrap\n✓ Moisturizing finish\n\n*Best for: Detoxification, skin smoothing, water retention*', NULL, 'Uses Dead Sea mud and seaweed extracts. Helps with skin texture and temporary inch loss (water weight). Exfoliation removes dead skin cells. Will feel warm during wrap portion. Great prep before vacation or event. Avoid if claustrophobic.', 6);

    -- Insert into content_templates for template library management
    INSERT INTO content_templates (slug, card_id, scenario_category, is_featured, is_active, sort_order)
    VALUES ('spa-wellness', v_card_id, 'hospitality', true, true, 15);

    RAISE NOTICE 'Successfully created Spa & Wellness template with card ID: %', v_card_id;

END $body$;

