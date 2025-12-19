-- Hotel Services - Grouped List Mode (Digital Access)
-- Template: Hotel guest services directory with categories
-- 
-- INSTRUCTIONS:
-- 1. Replace 'YOUR_USER_ID_HERE' with actual user UUID
-- 2. Update image_url values with actual uploaded image URLs
-- 3. Run this SQL in Supabase SQL Editor or via psql

DO $body$
DECLARE
    v_user_id UUID := 'YOUR_USER_ID_HERE'::UUID;
    v_card_id UUID;
    v_cat_dining UUID;
    v_cat_wellness UUID;
    v_cat_services UUID;
    v_cat_business UUID;
    v_cat_information UUID;
BEGIN
    -- Insert the card
    INSERT INTO cards (
        id, user_id, name, description, content_mode, is_grouped, group_display, billing_type,
        conversation_ai_enabled, ai_instruction, ai_knowledge_base,
        ai_welcome_general, ai_welcome_item, daily_scan_limit,
        is_access_enabled, access_token
    ) VALUES (
        gen_random_uuid(),
        v_user_id,
        'Grand Plaza Hotel - Guest Services',
        E'Welcome to **Grand Plaza Hotel** ⭐⭐⭐⭐⭐\n\nYour complete guide to hotel services and amenities.\n\n📞 Front Desk: Dial 0 · 🛎️ Concierge: Dial 1',
        'list',
        true,
        'expanded',
        'digital',
        true,
        'You are a helpful hotel concierge. Assist guests with any questions about hotel services, local recommendations, or general inquiries. Be warm, professional, and anticipate guest needs. For urgent matters, always direct guests to call the front desk.',
        E'Grand Plaza Hotel - 5-star luxury hotel\nAddress: 100 Plaza Avenue, Downtown\nBuilt: 1925, renovated 2022\nRooms: 450 rooms and suites across 25 floors\n\nCheck-in: 3:00 PM · Check-out: 11:00 AM\nLate checkout available (fee may apply)\n\nConcierge desk: 24 hours, can arrange anything\nValet parking: $45/night, self-park $30/night\n\nPet policy: Dogs under 25 lbs welcome, $75 fee per stay\nSmoking: Non-smoking property, designated outdoor areas',
        'Welcome to Grand Plaza Hotel! I can help with room service, restaurant reservations, spa bookings, local recommendations, or any hotel amenity. What do you need?',
        'For {name}, I can share hours, pricing, how to book, what''s included, or answer specific questions. How can I help?',
        2000,
        TRUE,
        replace(replace(encode(gen_random_bytes(9), 'base64'), '+', '-'), '/', '_')
    ) RETURNING id INTO v_card_id;

    -- Create categories (Layer 1)
    INSERT INTO content_items (id, card_id, parent_id, name, content, ai_knowledge_base, sort_order)
    VALUES (gen_random_uuid(), v_card_id, NULL, '🍽️ Dining', 'Restaurant and in-room dining options', 'Dining services include 24-hour room service and our award-winning restaurant.', 1)
    RETURNING id INTO v_cat_dining;

    INSERT INTO content_items (id, card_id, parent_id, name, content, ai_knowledge_base, sort_order)
    VALUES (gen_random_uuid(), v_card_id, NULL, '💆 Wellness', 'Spa, fitness, and relaxation facilities', 'Our wellness facilities are complimentary for all hotel guests.', 2)
    RETURNING id INTO v_cat_wellness;

    INSERT INTO content_items (id, card_id, parent_id, name, content, ai_knowledge_base, sort_order)
    VALUES (gen_random_uuid(), v_card_id, NULL, '🛎️ Guest Services', 'Concierge, housekeeping, and more', 'Our team is available 24/7 to assist with any request.', 3)
    RETURNING id INTO v_cat_services;

    INSERT INTO content_items (id, card_id, parent_id, name, content, ai_knowledge_base, sort_order)
    VALUES (gen_random_uuid(), v_card_id, NULL, '💼 Business', 'Business center and meeting facilities', 'Full business services available for corporate travelers.', 4)
    RETURNING id INTO v_cat_business;

    INSERT INTO content_items (id, card_id, parent_id, name, content, ai_knowledge_base, sort_order)
    VALUES (gen_random_uuid(), v_card_id, NULL, 'ℹ️ Information', 'Local attractions and emergency info', 'Everything you need to explore and stay safe.', 5)
    RETURNING id INTO v_cat_information;

    -- Insert dining items (Layer 2)
    INSERT INTO content_items (card_id, parent_id, name, content, image_url, ai_knowledge_base, sort_order) VALUES
    (v_card_id, v_cat_dining, 'Room Service', E'**24-Hour In-Room Dining**\n\n📞 **Dial 4** from your room phone\n\nEnjoy breakfast, lunch, dinner, or late-night snacks delivered directly to your room.\n\n**Hours:** 24 hours (limited menu midnight-6am)\n\n**Delivery Time:** 30-45 minutes\n\n**Tray Pickup:** Place tray outside door or call for pickup\n\n---\n\n**Popular Items:**\n- Continental Breakfast: $28\n- Club Sandwich: $24\n- Caesar Salad: $18\n- Wagyu Burger: $42\n- Kids Menu: $15\n\n*Full menu in your room''s tablet or call for paper menu*', NULL, 'Room service uses restaurant kitchens. Executive Chef Marco prepares all items fresh. 20% service charge automatically added. Special dietary requests accommodated with advance notice. Champagne and wine available. Birthday cakes can be ordered with 24hr notice.', 1),
    
    (v_card_id, v_cat_dining, 'The Grand Restaurant', E'**Fine Dining Experience**\n\n📍 **Location:** Lobby Level\n\n**Hours:**\n- Breakfast: 6:30 AM - 10:30 AM\n- Lunch: 12:00 PM - 2:30 PM\n- Dinner: 6:00 PM - 10:30 PM\n\n**Dress Code:** Smart casual (no shorts/flip-flops at dinner)\n\n**Reservations:** Dial 2 or speak to concierge\n\n---\n\n**The Plaza Bar**\n\n📍 Adjacent to restaurant\n\n**Hours:** 4:00 PM - 1:00 AM\n\nLive jazz Thursday-Saturday, 8-11 PM', NULL, 'Executive Chef Marco Bellini - 2 Michelin stars. Restaurant seats 120. Private dining room available for up to 20 guests. Vegetarian and vegan tasting menus available. Wine list curated by sommelier Anna Chen - 800 labels. Happy hour 4-7pm with $15 cocktails. Hotel guests receive 10% discount.', 2);

    -- Insert wellness items (Layer 2)
    INSERT INTO content_items (card_id, parent_id, name, content, image_url, ai_knowledge_base, sort_order) VALUES
    (v_card_id, v_cat_wellness, 'Spa & Wellness Center', E'**Relax and Rejuvenate**\n\n📍 **Location:** 4th Floor\n\n📞 **Reservations:** Dial 5\n\n**Hours:** 7:00 AM - 9:00 PM daily\n\n---\n\n**Services:**\n- Swedish Massage (60 min): $180\n- Deep Tissue Massage (60 min): $200\n- Aromatherapy Facial (75 min): $165\n- Body Scrub & Wrap (90 min): $220\n- Couples Massage (60 min): $350\n\n**Facilities (complimentary for hotel guests):**\n- Heated indoor pool\n- Jacuzzi and steam room\n- Sauna (dry and wet)\n- Relaxation lounge\n\n*Advance booking recommended, especially weekends*', NULL, 'Spa has 8 treatment rooms including couples suite. Pool is 25m lap pool, heated to 82°F. Steam room infused with eucalyptus. Spa director is certified aromatherapist. Hotel guests can use facilities free; day passes available for non-guests ($50). Robes and slippers provided. Gratuity not included in prices.', 1),
    
    (v_card_id, v_cat_wellness, 'Fitness Center', E'**24-Hour Gym Access**\n\n📍 **Location:** 4th Floor (adjacent to Spa)\n\n**Hours:** Open 24/7\n\n**Access:** Use your room key card\n\n---\n\n**Equipment:**\n- Cardio machines (treadmills, bikes, ellipticals)\n- Free weights (up to 100 lbs)\n- Weight machines\n- Yoga mats and props\n- Stretching area\n\n**Complimentary:**\n- Towels and water\n- Fitness classes (schedule at concierge)\n- Personal trainer consultation\n\n*Gym wear and athletic shoes required*', NULL, 'Gym equipped with Technogym equipment. Morning yoga classes 7am weekdays (free for guests). Personal training $100/hour, book 24hr in advance. Running maps of local routes available at front desk. Lockers available, bring your own lock or purchase at front desk ($10).', 2);

    -- Insert services items (Layer 2)
    INSERT INTO content_items (card_id, parent_id, name, content, image_url, ai_knowledge_base, sort_order) VALUES
    (v_card_id, v_cat_services, 'Concierge Services', E'**Your Personal Assistant**\n\n📍 **Location:** Lobby\n\n📞 **Dial 1** or visit in person\n\n**Hours:** 24 hours\n\n---\n\n**We can arrange:**\n- Restaurant reservations\n- Theater and event tickets\n- Airport transfers\n- Car rentals\n- Tours and activities\n- Flowers and gifts\n- Babysitting services\n- Dry cleaning and laundry\n- Business services\n\n**Local Expertise:**\nOur concierge team knows the city inside out. Let us create a personalized itinerary for your stay.\n\n*No request is too big or too small*', NULL, 'Head Concierge: Michelle Torres, Les Clefs d''Or member (golden keys - elite concierge organization). Team of 6 multilingual concierges. Can get reservations at fully-booked restaurants. Theater tickets usually available same-day. Airport transfer in Mercedes sedan $85, SUV $120. 24hr turnaround on dry cleaning.', 1),
    
    (v_card_id, v_cat_services, 'Housekeeping', E'**Keeping Your Room Perfect**\n\n📞 **Dial 8** for any housekeeping needs\n\n**Daily Service:** 9:00 AM - 4:00 PM\n\n---\n\n**Request:**\n- Extra towels or pillows\n- Additional toiletries\n- Iron and ironing board\n- Crib or rollaway bed\n- Room refresh\n\n**Green Program:**\nHang your towels to reuse them. Place the green card on your bed if you don''t need sheets changed.\n\n*Help us reduce our environmental impact*\n\n**Do Not Disturb:**\nUse the sign or press the button by your door', NULL, 'Housekeeping manager: Rosa Martinez. Team of 50 housekeepers. Turndown service available 6-9pm on request. Hypoallergenic pillows and bedding available. Baby amenities (crib, bottle warmer, baby bath) free of charge. Lost items held for 90 days. Laundry returned same day if submitted by 9am.', 2),
    
    (v_card_id, v_cat_services, 'WiFi & Technology', E'**Stay Connected**\n\n**WiFi Network:** GrandPlaza_Guest\n\n**Password:** Your room number + last name\n*(Example: 1234Smith)*\n\n---\n\n**In-Room Technology:**\n- Smart TV with streaming apps\n- USB charging ports (bedside and desk)\n- Bluetooth speaker (ask housekeeping)\n- Universal power adapters (at front desk)\n\n**Troubleshooting:**\n📞 **Dial 0** for technical support (24 hours)\n\n**Tip:** For fastest speeds, connect to the 5GHz network (GrandPlaza_Guest_5G)', NULL, 'WiFi speed: 100 Mbps throughout property. Premium WiFi available for high-bandwidth needs ($15/day, 500 Mbps). Smart TV has Netflix, Prime, Disney+ - sign in with your accounts. Chromecast in all rooms for screen mirroring. IT support can assist with video conferencing setup.', 3),
    
    (v_card_id, v_cat_services, 'Transportation', E'**Getting Around**\n\n📞 **Valet:** Dial 9\n\n---\n\n**Parking:**\n- Valet: $45/night (in and out privileges)\n- Self-park: $30/night (garage level P2)\n- Electric charging: 4 stations available\n\n**Airport Transfers:**\n- Sedan: $85 one-way\n- SUV: $120 one-way\n- Book through concierge (Dial 1)\n\n**Car Rental:**\nHertz desk in lobby, 7am-7pm daily\n\n**Rideshare:**\nPickup zone at East entrance\n\n**Public Transit:**\nMetro station 2 blocks north (Plaza Station)', NULL, 'Valet uses secure underground garage. Airport is 25 minutes in normal traffic, allow 45 minutes during rush hour. Hertz offers hotel guest discount (code: GRANDPLAZA). Bike rentals available through concierge - city bike share station across street. Private driver available for hourly hire ($75/hour, 4hr minimum).', 4);

    -- Insert business items (Layer 2)
    INSERT INTO content_items (card_id, parent_id, name, content, image_url, ai_knowledge_base, sort_order) VALUES
    (v_card_id, v_cat_business, 'Business Center', E'**Work Away From Home**\n\n📍 **Location:** Mezzanine Level\n\n📞 **Dial 6** for assistance\n\n**Hours:** 6:00 AM - 10:00 PM (after hours access with room key)\n\n---\n\n**Complimentary Services:**\n- High-speed WiFi\n- Computer workstations (Mac & PC)\n- Printing (first 20 pages free)\n- Scanning and faxing\n- Phone charging stations\n\n**Paid Services:**\n- Printing over 20 pages: $0.25/page\n- Binding and laminating\n- Courier services\n- Notary (by appointment)\n\n**Meeting Rooms:**\nAvailable for rent - see Meetings & Events', NULL, 'Business center has 6 private workstations with dividers. Complimentary coffee and tea. Secretarial services available $50/hour. International calling cards at front desk. Printer is color laser, accepts USB drives. WiFi password is room number + last name (case sensitive).', 1),
    
    (v_card_id, v_cat_business, 'Meetings & Events', E'**Professional Event Spaces**\n\n📞 **Events Team:** Dial 7\n\n📧 **events@grandplaza.com**\n\n---\n\n**Venues:**\n\n| Room | Capacity | Size |\n|------|----------|------|\n| Grand Ballroom | 500 | 8,000 sq ft |\n| Plaza Room | 150 | 2,500 sq ft |\n| Boardroom A | 20 | 600 sq ft |\n| Boardroom B | 12 | 400 sq ft |\n| Executive Suite | 8 | 300 sq ft |\n\n**Services:**\n- A/V equipment and technician\n- Catering and bar service\n- Event planning assistance\n- Breakout rooms\n\n*Request a proposal for your next event*', NULL, 'Events Director: Sarah Chen. Grand Ballroom perfect for weddings (up to 250 seated dinner). Corporate rate: 20% off for 10+ room nights. Packages include AV, WiFi, coffee breaks. Popular for conferences and product launches. Rooftop terrace available for cocktail events (weather permitting, max 100 guests).', 2);

    -- Insert information items (Layer 2)
    INSERT INTO content_items (card_id, parent_id, name, content, image_url, ai_knowledge_base, sort_order) VALUES
    (v_card_id, v_cat_information, 'Local Attractions', E'**Explore the City**\n\n*Ask our concierge to book tours or tickets*\n\n---\n\n**Walking Distance (< 15 min):**\n- City Museum - 5 min\n- Central Park - 8 min\n- Theater District - 10 min\n- Shopping Mall - 12 min\n\n**Worth the Trip:**\n- Art Gallery - 20 min by taxi\n- Historic District - 25 min by metro\n- Beach - 40 min by car\n- Wine Country - 1 hour by car\n\n**Hotel Tours:**\n- City Walking Tour: Daily 10am ($35)\n- Food Tour: Sat/Sun 2pm ($75)\n- Wine Tasting: Fri 4pm ($95)\n\n*Book through concierge*', NULL, 'Top restaurant recommendations: La Maison (French, $$$), Sake House (Japanese, $$), Taco Loco (Mexican, $). Best brunch: Sunny Side Café (15 min walk). Museum free on Thursdays after 5pm. Central Park has free summer concerts. Hotel has partnership with Broadway - can often get last-minute tickets.', 1),
    
    (v_card_id, v_cat_information, 'Emergency Information', E'**Safety First**\n\n🚨 **Emergency:** Dial 911\n\n🏥 **Hotel Security:** Dial 0 (24 hours)\n\n---\n\n**Fire Safety:**\n- Fire exits marked on back of room door\n- Do not use elevators during fire\n- Meet at designated assembly point (front of hotel)\n\n**Medical:**\n- First aid available at front desk\n- Nearest hospital: City General (10 min by car)\n- 24-hour pharmacy: CVS, 2 blocks east\n\n**Lost & Found:**\n- Items found in hotel: Front desk\n- Items left after checkout: Call (555) 123-4567\n\n**Safe Deposit:**\nIn-room safe included. Front desk safe for valuables.', NULL, 'Hotel has full sprinkler system and smoke detectors in all rooms. AED machines on every floor. Security team includes former police officers. Doctor on call 24 hours (house call $150). Wheelchair accessible throughout. Service animals welcome. In-room safes hold standard laptop size.', 2);

    -- Insert into content_templates for template library management
    INSERT INTO content_templates (slug, card_id, venue_type, is_featured, is_active, sort_order)
    VALUES ('hotel-services', v_card_id, 'hospitality', true, true, 14);

    RAISE NOTICE 'Successfully created Hotel Services template with card ID: %', v_card_id;

END $body$;
