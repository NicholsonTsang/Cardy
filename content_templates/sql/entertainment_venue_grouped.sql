-- Entertainment Venue - Grouped List Mode (Digital Access)
-- Template: Theatre/performing arts center with shows by category
-- 
-- INSTRUCTIONS:
-- 1. Replace 'YOUR_USER_ID_HERE' with actual user UUID
-- 2. Update image_url values with actual uploaded image URLs
-- 3. Run this SQL in Supabase SQL Editor or via psql

DO $body$
DECLARE
    v_user_id UUID := 'YOUR_USER_ID_HERE'::UUID;
    v_card_id UUID;
    v_cat_now_playing UUID;
    v_cat_coming_soon UUID;
    v_cat_venue_guide UUID;
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
        'Majestic Theatre - Season Guide',
        E'**2025 Season**\n\nExperience world-class performances in our historic venue.\n\n📍 250 Broadway, Downtown\n🎭 Box Office: Open 10 AM - 8 PM\n📞 (555) THEATRE',
        'list',
        true,
        'expanded',
        'digital',
        true,
        'You are a friendly theatre concierge. Help guests learn about shows, find the best seats, understand venue amenities, and plan their visit. Be enthusiastic about performances without spoiling plots. Help with accessibility needs and dining recommendations nearby.',
        E'Majestic Theatre - Opened 1927, 1,800 seats\nHistoric landmark with Art Deco interior\n\nSeating: Orchestra, Mezzanine, Balcony\nPremium seats: Center Orchestra rows D-M\nAccessible seating: Orchestra, aisle access\n\nAmenities: Two bars, coat check, gift shop\nPre-show dining: Partner restaurants with prix fixe\n\nBox Office: 250 Broadway, open daily 10 AM - 8 PM\nSame-day rush tickets available 2 hours before showtime\nStudent/Senior discounts on select performances\n\nParking: City Garage adjacent ($25 event rate)\nSubway: Blue Line, Theatre District station',
        'Welcome to the Majestic Theatre! I can tell you about current shows, recommend the best seats for your budget, explain dining options nearby, or share our venue''s history. What would you like to know?',
        'You''re interested in {name}! I can share the show synopsis (no spoilers!), suggest best seats, tell you the run time, or help with accessibility needs. What would help?',
        NULL,
        TRUE,
        replace(replace(encode(gen_random_bytes(9), 'base64'), '+', '-'), '/', '_')
    ) RETURNING id INTO v_card_id;

    -- Category 1: Now Playing
    INSERT INTO content_items (id, card_id, parent_id, name, content, ai_knowledge_base, sort_order)
    VALUES (gen_random_uuid(), v_card_id, NULL, 'Now Playing', '', 
        'Current shows running through Spring 2025. All performances Tuesday-Sunday. Best availability: Tuesday, Wednesday, Thursday evenings.', 1)
    RETURNING id INTO v_cat_now_playing;

    INSERT INTO content_items (card_id, parent_id, name, content, image_url, ai_knowledge_base, sort_order) VALUES
    (v_card_id, v_cat_now_playing, 'The Phantom Legacy', E'**A New Musical Thriller**\n\n⭐ Critics'' Choice - "Breathtaking!" - NY Times\n\nParis, 1920. The Opera Populaire reopens after decades of darkness. But someone remembers the music of the night...\n\n---\n\n🎭 **Now through May 2025**\n\n📅 Tue-Sat 8 PM | Wed & Sat 2 PM | Sun 3 PM\n\n⏱ 2 hours 30 minutes (one intermission)\n\n💰 $79 - $175\n\n*Recommended ages 12+*', NULL, 'Flagship production, running since October 2024. Original score by Broadway veterans. Cast of 32, full orchestra. Features famous chandelier effect in Act 2 (center orchestra best view). Most popular: Saturday evening. Best availability: Wednesday matinee. VIP package includes backstage tour. Standing ovations every night. Not affiliated with other "Phantom" productions.', 1),
    
    (v_card_id, v_cat_now_playing, 'Comedy Tonight!', E'**Stand-Up Showcase**\n\nThe city''s best comedians take the stage for an unforgettable night of laughter. Rotating headliners weekly.\n\n---\n\n🎭 **Fridays & Saturdays**\n\n📅 10:30 PM (late show)\n\n⏱ 90 minutes (no intermission)\n\n💰 $45 - $65\n\n🍸 Two-drink minimum\n\n*Ages 18+ only*', NULL, 'Late-night show in Cabaret space (200 seats). Different headliner each weekend. Bar seating and table seating available. Full bar service during show. Famous comedians have performed here as surprise guests. Great date night option. Book early - sells out.', 2);

    -- Category 2: Coming Soon
    INSERT INTO content_items (id, card_id, parent_id, name, content, ai_knowledge_base, sort_order)
    VALUES (gen_random_uuid(), v_card_id, NULL, 'Coming Soon', '', 
        'Upcoming productions. Premium subscriber presale one week before public. Sign up for email alerts for on-sale announcements.', 2)
    RETURNING id INTO v_cat_coming_soon;

    INSERT INTO content_items (card_id, parent_id, name, content, image_url, ai_knowledge_base, sort_order) VALUES
    (v_card_id, v_cat_coming_soon, 'Shakespeare in Summer', E'**A Midsummer Night''s Dream**\n\nAn enchanting outdoor production in our rooftop garden. Bring blankets and picnics for this magical evening under the stars.\n\n---\n\n🎭 **June 15 - August 31, 2025**\n\n📅 Wed-Sun 7:30 PM\n\n⏱ 2 hours (one intermission)\n\n💰 $55 - $95 | Lawn seating $35\n\n🍷 Picnic packages available\n\n*Family friendly*\n\n**ON SALE MARCH 1**', NULL, 'Rooftop venue holds 500. Modern dress production with live musicians. Bring blankets for lawn section. Chairs provided in premium sections. Rain policy: show goes on unless severe weather; covered seating available. Sunset start time means show ends under stars. Picnic basket from partner deli available for pre-order.', 1),
    
    (v_card_id, v_cat_coming_soon, 'Holiday Spectacular', E'**A Majestic Christmas**\n\nOur beloved annual tradition returns! Featuring the Rockettes-style dance troupe, live orchestra, and Santa''s grand arrival.\n\n---\n\n🎭 **November 20 - December 30, 2025**\n\n📅 Daily performances\n\n⏱ 90 minutes (no intermission)\n\n💰 $59 - $149\n\n🎁 Photo packages with Santa available\n\n*All ages welcome*\n\n**PRESALE STARTS OCTOBER 1**', NULL, '35-year tradition. Cast of 50+ dancers. Real snow effect in finale. Santa meet-and-greet after matinees (book ahead). School groups welcome - special rates for 20+. Most popular performances: Thanksgiving weekend, week before Christmas. Best availability: November weekdays.', 2);

    -- Category 3: Venue Guide
    INSERT INTO content_items (id, card_id, parent_id, name, content, ai_knowledge_base, sort_order)
    VALUES (gen_random_uuid(), v_card_id, NULL, 'Venue Guide', '', 
        'Practical information for visitors. Staff available in lobby 30 minutes before showtime for assistance.', 3)
    RETURNING id INTO v_cat_venue_guide;

    INSERT INTO content_items (card_id, parent_id, name, content, image_url, ai_knowledge_base, sort_order) VALUES
    (v_card_id, v_cat_venue_guide, 'Seating Guide', E'**Find Your Perfect Seat**\n\n**Orchestra** - Main floor, closest to stage\n- Premium: Rows D-M center\n- Value: Rear orchestra, partial view\n\n**Mezzanine** - Elevated, great sightlines\n- Front row has excellent leg room\n- Bar service during intermission\n\n**Balcony** - Upper level, full stage view\n- Most affordable option\n- Best for spectacle shows\n\n---\n\n♿ **Accessible Seating**\n- Wheelchair: Orchestra, aisle\n- Transfer seats available\n- Hearing loop: All sections\n- Audio description: Select shows', NULL, 'Orchestra center rows D-M considered best - not too close, centered. Row A very close, neck strain possible. Mezzanine front row is hidden gem - great view, private feel. Balcony side seats have partial obstruction. For musicals, center is key. For plays, slight angle fine. Children need booster seats in orchestra. Accessible seating book through box office.', 1),
    
    (v_card_id, v_cat_venue_guide, 'Before the Show', E'**Plan Your Visit**\n\n📍 **Location**\n250 Broadway, Downtown\n\n🚇 **Getting Here**\n- Subway: Blue Line, Theatre District\n- Parking: City Garage ($25 event rate)\n- Drop-off: Front entrance on Broadway\n\n🍽 **Dining Partners**\nShow your ticket for prix fixe specials:\n- Bistro Laurent (French) - $55\n- Trattoria Bella (Italian) - $45\n- The Grill Room (American) - $65\n\n⏰ **Arrival**\n- Doors open 45 minutes before\n- Latecomers seated at suitable break\n- Coat check available ($3)', NULL, 'Arrive 30 minutes early for best experience. Pre-show drinks at lobby bars. Partner restaurants 5-10 minute walk - make reservations. Garage fills up on weekends - arrive early or use subway. No re-entry once show starts. Photos in lobby allowed, not in auditorium. Gift shop has show merchandise.', 2);

    -- Insert into content_templates for template library management
    INSERT INTO content_templates (slug, card_id, scenario_category, is_featured, is_active, sort_order)
    VALUES ('entertainment-venue', v_card_id, 'events', true, true, 12);

    RAISE NOTICE 'Successfully created Entertainment Venue template with card ID: %', v_card_id;

END $body$;

