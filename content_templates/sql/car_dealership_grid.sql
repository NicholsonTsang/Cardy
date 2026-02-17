-- Car Dealership - Grid Mode (Digital Access)
-- Template: Automotive showroom with vehicle inventory
-- 
-- INSTRUCTIONS:
-- 1. Replace 'YOUR_USER_ID_HERE' with actual user UUID
-- 2. Update image_url values with actual uploaded image URLs
-- 3. Run this SQL in Supabase SQL Editor or via psql

DO $body$
DECLARE
    v_user_id UUID := 'YOUR_USER_ID_HERE'::UUID;
    v_card_id UUID;
    v_cat_vehicles UUID;
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
        'Premier Motors - Vehicle Showcase',
        E'**Drive Excellence**\n\nYour authorized luxury automotive destination.\nNew, certified pre-owned, and service.\n\n📍 500 Auto Drive, Motor Mile\n⏰ Mon-Sat 9 AM - 8 PM | Sun 11 AM - 5 PM\n📞 (555) PREMIER',
        'grid',
        false,
        NULL,
        'digital',
        true,
        'You are a knowledgeable automotive advisor. Help customers understand vehicle features, compare models, and explore financing options. Be helpful without being pushy. Provide honest assessments of vehicle capabilities. Acknowledge that test drives are the best way to decide. Direct complex questions to sales consultants.',
        E'Premier Motors - Authorized luxury dealership\nBrands: Full luxury lineup\nEstablished: 1985, family-owned\n\nInventory: 150+ new, 75+ certified pre-owned\n\nServices offered:\n- New vehicle sales\n- Certified pre-owned\n- Trade-in appraisals\n- Financing & leasing\n- Factory service center\n- Parts department\n\nBusiness hours:\n- Sales: Mon-Sat 9 AM - 8 PM, Sun 11 AM - 5 PM\n- Service: Mon-Fri 7 AM - 6 PM, Sat 8 AM - 3 PM\n\nFinancing partners: Major banks, manufacturer financing\nSpecial programs: First-time buyer, loyalty, conquest\n\nTest drives: Walk-in welcome, appointments preferred\nHome delivery available',
        'Welcome to Premier Motors! I can compare models, explain features and specs, discuss financing options, share trade-in info, or help you find a vehicle that fits your needs. What are you looking for?',
        'The {name} is excellent! I can detail the specs, compare it to competitors, explain pricing and packages, or discuss test drive options. What would you like to know?',
        NULL,
        TRUE,
        replace(replace(encode(gen_random_bytes(9), 'base64'), '+', '-'), '/', '_')
    ) RETURNING id INTO v_card_id;

    -- Hidden Category for flat grid
    INSERT INTO content_items (id, card_id, parent_id, name, content, ai_knowledge_base, sort_order)
    VALUES (gen_random_uuid(), v_card_id, NULL, 'Vehicles', '', '', 1)
    RETURNING id INTO v_cat_vehicles;

    -- Content Items
    INSERT INTO content_items (card_id, parent_id, name, content, image_url, ai_knowledge_base, sort_order) VALUES
    (v_card_id, v_cat_vehicles, '2025 Executive Sedan', E'**Refined Performance**\n\n💰 Starting at $52,900\n\nThe benchmark in luxury sedans. Effortless power, advanced technology, and handcrafted comfort for every journey.\n\n---\n\n🔧 **Specifications**\n- 2.0L Turbo | 255 HP\n- 8-speed automatic\n- AWD available\n- 28 city / 36 highway MPG\n\n⭐ **Highlights**\n- 12.3" digital cockpit\n- Panoramic moonroof\n- Heated leather seats\n- Driver assistance suite\n\n*5 in stock | 12 colors available*', NULL, 'Best-selling model for professionals. Competitor to BMW 3, Mercedes C-Class. Available in base, Premium, and Sport trims. Premium ($58K) adds 360 camera, premium audio. Sport ($62K) adds adaptive suspension, sport exhaust. AWD adds $2,500. Popular lease: $599/month, 36 months, $4,000 due at signing. Test drive tip: try highway merge.', 1),
    
    (v_card_id, v_cat_vehicles, '2025 Sport SUV', E'**Versatile Adventure**\n\n💰 Starting at $48,500\n\nCompact luxury SUV with bold styling and agile handling. Premium comfort meets everyday practicality.\n\n---\n\n🔧 **Specifications**\n- 2.0L Turbo | 248 HP\n- AWD standard\n- 25 city / 32 highway MPG\n- Towing: 3,500 lbs\n\n⭐ **Highlights**\n- Hands-free liftgate\n- Wireless CarPlay/Android\n- Adaptive cruise control\n- 40/20/40 rear seats\n\n*8 in stock | Test drives available*', NULL, 'Fastest growing segment. Competes with BMW X1, Audi Q3, Lexus NX. Standard AWD is differentiator vs competitors. Popular with young professionals and small families. Cargo: 25 cu ft behind rear seats, 54 cu ft seats folded. Available tow package ($750) for light trailers. Most popular color: white, followed by black. Best value in lineup.', 2),
    
    (v_card_id, v_cat_vehicles, '2025 Grand Touring SUV', E'**Commanding Presence**\n\n💰 Starting at $72,900\n\nFull-size luxury SUV with three-row seating and uncompromising capability. First-class comfort for the entire family.\n\n---\n\n🔧 **Specifications**\n- 3.0L Twin-Turbo V6 | 375 HP\n- AWD standard\n- 19 city / 25 highway MPG\n- Towing: 7,500 lbs\n\n⭐ **Highlights**\n- Seating for 7\n- Air suspension\n- Executive rear seats\n- Premium 19-speaker audio\n\n*3 in stock | Factory orders welcome*', NULL, 'Flagship SUV. Competes with BMW X7, Mercedes GLS, Range Rover. Third row actually usable for adults. Executive rear seats ($3,500) add captain''s chairs with massage. Air suspension adjusts ride height - raises for off-road, lowers for entry. Tow package standard. Popular with families, executives. Factory orders 8-10 weeks. Residual value strong - 58% at 36 months.', 3),
    
    (v_card_id, v_cat_vehicles, '2025 Performance Coupe', E'**Pure Driving Thrill**\n\n💰 Starting at $67,500\n\nTwo-door sports car engineered for driving enthusiasts. Race-inspired performance meets everyday usability.\n\n---\n\n🔧 **Specifications**\n- 3.0L Twin-Turbo | 385 HP\n- 0-60: 4.2 seconds\n- RWD (AWD available)\n- Sport exhaust standard\n\n⭐ **Highlights**\n- Adaptive sport suspension\n- Launch control\n- Carbon fiber trim\n- Sport bucket seats\n\n*2 in stock | Limited availability*', NULL, 'For driving enthusiasts. RWD is purer driving experience, AWD adds $3,000 and better launch times (3.9s 0-60). Available track package ($5,500) adds ceramic brakes, limited-slip diff. Surprisingly practical - usable back seat for short trips. Popular as second car. Manual transmission no longer available. Exhaust has active valves - quiet in comfort mode, loud in sport.', 4),
    
    (v_card_id, v_cat_vehicles, '2025 Electric SUV', E'**Zero Emissions Luxury**\n\n💰 Starting at $79,900\n\nAll-electric performance SUV with instant torque and cutting-edge technology. The future of driving, today.\n\n---\n\n🔧 **Specifications**\n- Dual motor AWD | 516 HP\n- 0-60: 3.8 seconds\n- Range: 320 miles (EPA)\n- DC fast charging: 10-80% in 25 min\n\n⭐ **Highlights**\n- Glass panoramic roof\n- Over-the-air updates\n- Augmented reality nav\n- Intelligent regeneration\n\n*Available for order | $2,500 deposit*', NULL, 'First full EV in lineup. Eligible for $7,500 federal tax credit (verify eligibility). Home charging: Level 2 adds ~30 miles/hour. DC fast charging at 800+ locations nationally. Range in winter drops ~15-20%. Maintenance costs 40% lower than gas - no oil changes. Performance mode unlocks full 516 HP. Over-the-air updates add features over time. Most advanced tech in our lineup.', 5),
    
    (v_card_id, v_cat_vehicles, 'Certified Pre-Owned', E'**Premium Value**\n\n💰 Starting at $32,900\n\nFactory-certified vehicles with extended warranty and confidence. Every CPO vehicle passes 200+ point inspection.\n\n---\n\n✓ **CPO Benefits**\n- 2-year unlimited mile warranty\n- 24/7 roadside assistance\n- Vehicle history report\n- Exchange privilege (7 days)\n- Special financing rates\n\n📊 **Current Inventory**\n- Sedans: 22 available\n- SUVs: 35 available\n- Coupes: 8 available\n\n*New arrivals weekly*', NULL, 'Best value proposition. CPO cars typically 3-4 years old, under 50,000 miles. Warranty better than most new car warranties. Financing rates typically 0.5-1% higher than new. Popular models sell fast - check inventory often. Exchange privilege lets you return within 7 days if not satisfied. Recent lease returns in excellent condition. Ask about specific models - can search regional inventory.', 6),
    
    (v_card_id, v_cat_vehicles, 'Service Center', E'**Factory-Trained Care**\n\nOur technicians know your vehicle inside and out. Genuine parts, advanced diagnostics, and transparent pricing.\n\n---\n\n🔧 **Services**\n- Maintenance (oil, tires, brakes)\n- Warranty repairs\n- Recall service\n- Performance upgrades\n- Collision repair\n\n⏰ **Hours**\nMon-Fri 7 AM - 6 PM\nSaturday 8 AM - 3 PM\n\n🚗 **Amenities**\n- Complimentary loaner cars\n- Wi-Fi lounge\n- Shuttle service\n- Express service lane\n\n📞 **Schedule: (555) SERVICE**', NULL, 'Factory-trained technicians only. Loaner cars for service over 2 hours - same brand vehicles. Express lane for oil changes and simple maintenance (no appointment, under 1 hour). Price match guarantee on tires. First maintenance visit complimentary for new car purchases. Shuttle runs to downtown and mall. Customer lounge has coffee, snacks, work stations.', 7);

    -- Insert into content_templates for template library management
    INSERT INTO content_templates (slug, card_id, scenario_category, is_featured, is_active, sort_order)
    VALUES ('car-dealership', v_card_id, 'retail', true, true, 17);

    RAISE NOTICE 'Successfully created Car Dealership template with card ID: %', v_card_id;

END $body$;

