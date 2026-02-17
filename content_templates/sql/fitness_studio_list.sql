-- Fitness Studio - List Mode (Digital Access)
-- Template: Boutique fitness studio with classes and services
-- 
-- INSTRUCTIONS:
-- 1. Replace 'YOUR_USER_ID_HERE' with actual user UUID
-- 2. Update image_url values with actual uploaded image URLs
-- 3. Run this SQL in Supabase SQL Editor or via psql

DO $body$
DECLARE
    v_user_id UUID := 'YOUR_USER_ID_HERE'::UUID;
    v_card_id UUID;
    v_cat_classes UUID;
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
        'Pulse Fitness Studio - Class Guide',
        E'**Move. Sweat. Transform.**\n\nBoutique fitness experiences designed to challenge and inspire.\n\n📍 456 Health Street, Suite 200\n⏰ Mon-Fri 6 AM - 9 PM | Weekends 7 AM - 6 PM\n📞 (555) GETPULSE',
        'list',
        false,
        NULL,
        'digital',
        true,
        'You are an encouraging fitness advisor. Help clients choose classes based on their goals, fitness level, and schedule. Be motivating without being intimidating. Explain modifications for beginners. Emphasize that all levels are welcome. Never give specific medical advice.',
        E'Pulse Fitness Studio - Boutique fitness\nOpened: 2019\nLocation: Downtown, near Metro station\n\nClass types: HIIT, spin, yoga, barre, strength, boxing\nClass size: 15-20 per class\nEquipment: Peloton bikes, TRX, free weights, boxing bags\n\nInstructors: 12 certified trainers, various specialties\n\nPricing:\n- Drop-in: $35/class\n- 10-pack: $280 ($28/class)\n- Monthly unlimited: $199\n- Annual: $149/month\n\nNew client special: First class free\nCancellation: 12 hours notice required\n\nAmenities: Showers, lockers (day use), towels, water station, retail boutique\n\nApp: Book classes, track progress, view schedule',
        'Hey! Welcome to Pulse Fitness! I can recommend classes based on your goals or fitness level, explain what to expect as a beginner, share the schedule, or help you choose between different workout styles. What are you looking for?',
        'Our {name} class is great! I can explain the workout format, suggest what to bring, describe the intensity level, or let you know if it''s good for beginners. What would help?',
        NULL,
        TRUE,
        replace(replace(encode(gen_random_bytes(9), 'base64'), '+', '-'), '/', '_')
    ) RETURNING id INTO v_card_id;

    -- Hidden Category for flat list
    INSERT INTO content_items (id, card_id, parent_id, name, content, ai_knowledge_base, sort_order)
    VALUES (gen_random_uuid(), v_card_id, NULL, 'Classes', '', '', 1)
    RETURNING id INTO v_cat_classes;

    -- Content Items
    INSERT INTO content_items (card_id, parent_id, name, content, image_url, ai_knowledge_base, sort_order) VALUES
    (v_card_id, v_cat_classes, 'HIIT Burn', E'**High-Intensity Interval Training**\n\n⚡ 45 minutes | 500-700 calories\n\nFast-paced circuits alternating intense bursts with active recovery. Full-body workout using bodyweight, dumbbells, and cardio equipment.\n\n---\n\n🎯 **Benefits**\n- Maximum calorie burn\n- Improved cardio endurance\n- Build lean muscle\n- Afterburn effect (EPOC)\n\n👤 **Intensity:** ●●●●○\n\n📅 *Mon/Wed/Fri 6:30 AM, 12 PM, 6 PM*\n\n*All fitness levels welcome - modifications provided*', NULL, 'Most popular class. Format: 45 seconds work, 15 seconds rest. Three circuits, different exercises each. Instructors always show low-impact modifications. Bring water - you''ll sweat! Heart rate monitors available for rent. Great for beginners who want to push themselves with built-in rest periods.', 1),
    
    (v_card_id, v_cat_classes, 'Power Spin', E'**Indoor Cycling**\n\n🚴 45 minutes | 400-600 calories\n\nRhythm-based cycling to high-energy playlists. Hills, sprints, and intervals set to the beat in a candlelit studio.\n\n---\n\n🎯 **Benefits**\n- Low-impact cardio\n- Leg strength & endurance\n- Mental stress relief\n- Community energy\n\n👤 **Intensity:** ●●●○○ to ●●●●●\n\n📅 *Daily 7 AM, 9 AM, 5:30 PM, 7 PM*\n\n*First-timers: Arrive 10 min early for bike setup*', NULL, 'Peloton bikes with screens showing metrics. Resistance is yours to control - go at your own pace. Candlelit for vibe, not pitch dark. Clip-in shoes available (free) or wear sneakers. Water and towel essential. 7 PM classes most popular - book 2+ days ahead. Gentle on joints, great for runners recovering from injury.', 2),
    
    (v_card_id, v_cat_classes, 'Vinyasa Flow', E'**Yoga**\n\n🧘 60 minutes | Mind-body connection\n\nBreath-linked movement through dynamic sequences. Build strength, flexibility, and mindfulness in our heated studio.\n\n---\n\n🎯 **Benefits**\n- Improved flexibility\n- Core strength\n- Stress reduction\n- Better posture\n\n👤 **Intensity:** ●●○○○ to ●●●○○\n\n🌡 *Heated to 80°F*\n\n📅 *Daily 8 AM, 12 PM, 7:30 PM*\n\n*Mats and props provided*', NULL, 'Not hot yoga (80°F, not 105°F) - warm enough to loosen muscles without extreme heat. All levels in same class - instructor offers variations. Beginners start in front to see better. Props encouraged, not a crutch. Sunday 8 AM is especially peaceful. Great complement to high-intensity classes.', 3),
    
    (v_card_id, v_cat_classes, 'Boxing Bootcamp', E'**Boxing + Strength**\n\n🥊 50 minutes | 600-800 calories\n\nLearn boxing fundamentals while getting a killer workout. Heavy bag rounds combined with strength circuits.\n\n---\n\n🎯 **Benefits**\n- Full-body strength\n- Stress release\n- Coordination\n- Self-defense basics\n\n👤 **Intensity:** ●●●●○\n\n📅 *Tue/Thu 6 AM, 5:30 PM | Sat 10 AM*\n\n*Gloves provided - wraps available for purchase*', NULL, 'No boxing experience needed - all combos taught from basics. Format: warm-up, technique drill, 6 rounds of bag work with strength exercises between. Huge stress reliever - clients love it after tough work days. Wraps ($15) keep gloves hygienic and wrists protected. Saturday class is most social.', 4),
    
    (v_card_id, v_cat_classes, 'Barre Sculpt', E'**Ballet-Inspired Toning**\n\n💃 55 minutes | Lean muscle definition\n\nLow-impact, high-rep movements at the ballet barre. Sculpt long, lean muscles using small, controlled movements.\n\n---\n\n🎯 **Benefits**\n- Muscle definition\n- Improved posture\n- Core stability\n- Flexibility\n\n👤 **Intensity:** ●●○○○\n\n📅 *Mon/Wed/Fri 9:30 AM | Tue/Thu 7 PM*\n\n*Sticky socks required (available for purchase $12)*', NULL, 'No dance experience needed. Small isometric movements = muscle fatigue = results. "The shake" is normal and means it''s working. Lower impact on joints than jumping exercises. Great for rehab from injury. Sticky socks grip the floor - required for safety. Complements other workouts by targeting smaller stabilizer muscles.', 5),
    
    (v_card_id, v_cat_classes, 'Strength Lab', E'**Weight Training**\n\n🏋️ 50 minutes | Build strength\n\nStructured strength training with barbells, dumbbells, and kettlebells. Learn proper form while building functional strength.\n\n---\n\n🎯 **Benefits**\n- Build muscle\n- Boost metabolism\n- Bone density\n- Functional movement\n\n👤 **Intensity:** ●●●○○ to ●●●●●\n\n📅 *Mon/Wed/Fri 5:30 PM | Sat/Sun 8 AM*\n\n*Small groups (max 12) for personalized coaching*', NULL, 'Structured like personal training but in group setting. Coach demonstrates every lift, corrects form individually. Progressive program - weights increase over time. Beginners start with lighter weights, focus on form. Great for women intimidated by weight rooms - supportive environment. Track your lifts in our app.', 6),
    
    (v_card_id, v_cat_classes, 'Recovery & Stretch', E'**Active Recovery**\n\n🧘‍♀️ 45 minutes | Restore & recover\n\nGentle stretching, foam rolling, and mobility work. Essential for preventing injury and improving performance.\n\n---\n\n🎯 **Benefits**\n- Muscle recovery\n- Injury prevention\n- Improved mobility\n- Relaxation\n\n👤 **Intensity:** ●○○○○\n\n📅 *Sun 11 AM, 4 PM | Wed 8 PM*\n\n*Foam rollers and massage balls provided*', NULL, 'Often overlooked but crucial class. Targets fascia and tight muscles from intense workouts. Foam rolling can be uncomfortable on tight spots - that''s normal. Great after leg day or long run. Wednesday night slot perfect for mid-week reset. Therapist designed the sequences. Free for unlimited members.', 7);

    -- Insert into content_templates for template library management
    INSERT INTO content_templates (slug, card_id, scenario_category, is_featured, is_active, sort_order)
    VALUES ('fitness-studio', v_card_id, 'events', true, true, 13);

    RAISE NOTICE 'Successfully created Fitness Studio template with card ID: %', v_card_id;

END $body$;

