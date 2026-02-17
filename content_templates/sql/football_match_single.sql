-- Football Match - Single Page Mode (Digital Access)
-- Template: Sports event single-page guide
-- 
-- INSTRUCTIONS:
-- 1. Replace 'YOUR_USER_ID_HERE' with actual user UUID
-- 2. Update image_url values with actual uploaded image URLs
-- 3. Run this SQL in Supabase SQL Editor or via psql

DO $body$
DECLARE
    v_user_id UUID := 'YOUR_USER_ID_HERE'::UUID;
    v_card_id UUID;
    v_default_category UUID;
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
        'Match Day Guide - City FC vs United',
        E'🏟️ **Welcome to City Stadium!**\n\nYour complete guide for today''s Premier League clash.\n\nTap below for kickoff time, team lineups, stadium map, and more.',
        'single',
        false,
        'expanded',
        'digital',
        true,
        'You are an enthusiastic football fan and stadium guide. Help visitors with directions, match information, and general stadium questions. Be excited about the match but remain neutral - fans of both teams are attending! Know the rules of football and can explain them simply.',
        E'City FC vs Manchester United - Premier League Matchday 15\nDate: December 7, 2025 · Kickoff: 3:00 PM\nVenue: City Stadium, 60,000 capacity\n\nStadium opened 2012, sustainable design with solar panels\n4 entry gates: North (home), South (away), East & West (general)\n\nFood options: Main concourse has 12 vendors\nAlcohol: Beer available in concourse areas only, not at seats\n\nParking: Lots A-D around stadium, £15 per vehicle\nPublic transport: Stadium Station on Blue Line (5 min walk)\n\nFan zone opens 2 hours before kickoff with entertainment',
        'Welcome to City Stadium! I can help with directions to your seat, food options, kickoff time, team lineups, stadium rules, or nearby parking. What do you need?',
        'Here''s your complete match day guide! Ask me about kickoff time, team lineups, where to eat, parking, or how to get to your seat. What do you need help with?',
        NULL,
        TRUE,
        replace(replace(encode(gen_random_bytes(9), 'base64'), '+', '-'), '/', '_')
    ) RETURNING id INTO v_card_id;

    -- Create default category (hidden in flat mode, holds all content items)
    INSERT INTO content_items (id, card_id, parent_id, name, content, ai_knowledge_base, sort_order)
    VALUES (gen_random_uuid(), v_card_id, NULL, 'General', '', '', 1)
    RETURNING id INTO v_default_category;

    -- Insert single content item (layer 2 under default category)
    INSERT INTO content_items (card_id, parent_id, name, content, image_url, ai_knowledge_base, sort_order) VALUES
    (v_card_id, v_default_category, 'Match Day Guide', E'# City FC vs Manchester United\n## Premier League · Matchday 15\n\n---\n\n## ⏰ Schedule\n\n| Time | Event |\n|------|-------|\n| 1:00 PM | Gates open |\n| 1:30 PM | Fan Zone entertainment begins |\n| 2:30 PM | Teams warm-up |\n| 2:45 PM | Team announcements |\n| 2:55 PM | National anthem |\n| **3:00 PM** | **KICKOFF** |\n| 3:45 PM | Half-time (15 minutes) |\n| ~4:45 PM | Full-time |\n\n---\n\n## 🏟️ Stadium Map\n\n**Your Section:** Check your ticket for block, row, and seat number\n\n### Entry Gates\n- **North Gate** → Blocks 101-120 (Home supporters)\n- **South Gate** → Blocks 201-220 (Away supporters)\n- **East Gate** → Blocks 301-340\n- **West Gate** → Blocks 401-440\n\n### Key Locations\n- 🍔 **Food & Drink** → Every concourse level\n- 🚻 **Restrooms** → Behind every section\n- 🏥 **First Aid** → Gates N1, S1, E1, W1\n- 👕 **Team Shop** → North Concourse\n- 📸 **Photo Opportunity** → West Concourse (giant shirt display)\n\n---\n\n## ⚽ Team Lineups\n\n### City FC (Home - Blue)\n\n**Manager:** Antonio García\n\n| # | Position | Player |\n|---|----------|--------|\n| 1 | GK | David Martinez |\n| 2 | RB | James Wilson |\n| 5 | CB | Michael Brown |\n| 6 | CB | Carlos Silva |\n| 3 | LB | Ahmed Hassan |\n| 8 | CM | Thomas Mueller |\n| 10 | CM | Paolo Rossi |\n| 7 | RW | Marcus Sterling |\n| 11 | LW | Yuki Tanaka |\n| 9 | ST | **Emmanuel Okonkwo** (C) |\n| 20 | ST | Lucas Fernandez |\n\n**Bench:** 13-Rodriguez, 4-Chen, 14-O''Brien, 16-Kowalski, 17-Nguyen, 19-Anderson, 21-Petrov\n\n### Manchester United (Away - Red)\n\n**Manager:** Roberto Mancini\n\n| # | Position | Player |\n|---|----------|--------|\n| 1 | GK | Peter Schmeichel Jr. |\n| 2 | RB | Kyle Walker-Peters |\n| 4 | CB | Virgil van Berg |\n| 5 | CB | Harry Stone |\n| 3 | LB | Luke Shaw Jr. |\n| 6 | DM | Declan Rice |\n| 8 | CM | Bruno Fernandes Jr. |\n| 7 | RW | Jadon Sancho Jr. |\n| 11 | LW | Marcus Rashford Jr. |\n| 10 | AM | **Mason Mount Jr.** (C) |\n| 9 | ST | Erling Larsen |\n\n**Bench:** 22-Henderson, 15-Maguire Jr., 17-Fred Jr., 18-Eriksen, 19-Antony Jr., 20-Pellistri, 21-Garnacho Jr.\n\n---\n\n## 📊 Head to Head\n\n| Stat | City FC | Man Utd |\n|------|---------|--------|\n| League Position | 2nd | 4th |\n| Points | 32 | 28 |\n| Last 5 Games | W W D W L | W D W L W |\n| Goals Scored | 34 | 29 |\n| Goals Conceded | 12 | 15 |\n\n**Last Meeting:** City FC 2-1 Man Utd (April 2025)\n\n**All-Time Record:**\n- City FC wins: 54\n- Man Utd wins: 61\n- Draws: 38\n\n---\n\n## 🍔 Food & Drink\n\n### Concourse Options\n- **Stadium Burger** - Classic burgers and hot dogs\n- **Pizza Corner** - Slices and whole pies\n- **The Noodle Bar** - Asian street food\n- **Fish & Chips** - Traditional British\n- **Vegan Kitchen** - Plant-based options\n- **Coffee Station** - Hot drinks and pastries\n\n### Prices\n- Beer (pint): £6.50\n- Burger meal: £12.00\n- Hot dog: £6.00\n- Pizza slice: £5.00\n- Coffee: £3.50\n- Water bottle: £2.50\n\n**📱 Mobile ordering available - skip the queue!**\nDownload the City FC app and order to your seat (Blocks 101-140 only)\n\n---\n\n## 📍 Getting Home\n\n### Public Transport\n- **Stadium Station** → Blue Line services every 5 minutes\n- **Special match buses** → City Centre (£3 fare)\n- Allow 20-30 minutes to reach station after final whistle\n\n### Driving\n- Exit via your designated gate to reduce congestion\n- **Lot A & B** → North exit (Highway 1)\n- **Lot C & D** → South exit (Highway 2)\n- Expected clear time: 45-60 minutes post-match\n\n### Rideshare\n- **Pickup zone** → East Gate car park\n- Surge pricing likely for 30 min after match\n\n---\n\n## 📱 Stay Connected\n\n- **WiFi:** `CityStadium_Guest` (free, no password)\n- **Official App:** Live stats, replays, mobile ordering\n- **Social:** @CityFC on all platforms\n- **Match Hashtag:** #CityVsUnited\n\n---\n\n## ⚠️ Important Information\n\n### Prohibited Items\n❌ Outside food & drinks\n❌ Bags larger than A4 size\n❌ Umbrellas\n❌ Professional cameras (lens > 20cm)\n❌ Drones\n❌ Weapons of any kind\n\n### Emergency\n- **Emergency services:** Dial 999\n- **Stadium security:** Text 66777\n- **Lost children:** Report to nearest steward\n- **Medical emergency:** Nearest first aid point\n\n---\n\n## 🎉 Enjoy the Match!\n\nThank you for supporting City FC. Sing loud, respect fellow fans, and may the best team win!\n\n*This card is your souvenir of today''s match. Collect the whole season!*', NULL, E'Key players to watch:\n- Emmanuel Okonkwo (City): 12 goals this season, top scorer\n- Erling Larsen (United): Hat-trick last match\n\nTactical preview: City likely to press high, United may counter-attack\n\nWeather forecast: 12°C, partly cloudy, 10% chance of rain\n\nReferee: Michael Oliver - tends to let game flow, averages 3.2 yellows/match\n\nVAR: Howard Webb - controversial offside decisions recently\n\nStadium records: Largest crowd 59,847 vs Liverpool 2023\n\nClub history: City FC founded 1892, 3 league titles, 2 FA Cups\nManchester United: Founded 1878, 20 league titles, 12 FA Cups', 1);

    -- Insert into content_templates for template library management
    INSERT INTO content_templates (slug, card_id, scenario_category, is_featured, is_active, sort_order)
    VALUES ('football-match', v_card_id, 'events', true, true, 10);

    RAISE NOTICE 'Successfully created Football Match template with card ID: %', v_card_id;

END $body$;

