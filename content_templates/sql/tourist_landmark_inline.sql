-- Tourist Landmark - Grouped Cards Mode (Digital Access)
-- Template: Walking tour organized by area/theme
-- 
-- INSTRUCTIONS:
-- 1. Replace 'YOUR_USER_ID_HERE' with actual user UUID
-- 2. Update image_url values with actual uploaded image URLs
-- 3. Run this SQL in Supabase SQL Editor or via psql

DO $body$
DECLARE
    v_user_id UUID := 'YOUR_USER_ID_HERE'::UUID;
    v_card_id UUID;
    v_cat_museums UUID;
    v_cat_historic UUID;
    v_cat_waterfront UUID;
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
        'Historic Harbor District - Walking Tour',
        E'Discover the **Historic Harbor District**, where centuries of maritime history come alive along cobblestone streets and waterfront views.\n\n🚶 Self-guided tour · ⏱️ 2-3 hours · 📍 8 stops',
        'cards',
        true,
        'expanded',
        'digital',
        true,
        'You are an enthusiastic local historian and tour guide. Share fascinating stories about the harbor''s past, answer questions about the architecture and history, and help visitors discover hidden gems. Make history come alive with vivid storytelling and interesting anecdotes.',
        E'Historic Harbor District - National Historic Landmark since 1966\nOriginal settlement: 1634\nPeak whaling era: 1820-1870\nMaritime museum collection: 50,000 artifacts\n\nWalking tour route: Start at Visitor Center (stop 1), proceed clockwise around harbor. Total distance: 1.5 miles.\n\nBest times to visit: Early morning for photos, sunset for ambiance\n\nAccessibility: Most paths are cobblestone. Accessible route available (ask at Visitor Center). Benches every 200 feet.\n\nLocal tip: The harbor lights up beautifully at dusk. Many visitors return for evening photos.',
        'Welcome to the Historic Harbor District! I can share the history of any building, suggest the best photo spots, give walking directions, or tell you fascinating local legends. Where shall we start?',
        'You''re at "{name}"! I can share its history, interesting stories, architectural details, best photo angles, or what''s nearby. What would you like to know?',
        NULL,
        TRUE,
        replace(replace(encode(gen_random_bytes(9), 'base64'), '+', '-'), '/', '_')
    ) RETURNING id INTO v_card_id;

    -- Create categories by area (Layer 1)
    INSERT INTO content_items (id, card_id, parent_id, name, content, ai_knowledge_base, sort_order)
    VALUES (gen_random_uuid(), v_card_id, NULL, '🏛️ Museums & Cultural Sites', 'Learn about maritime heritage', 'Museums in the district offer deep dives into the region''s history. Allow 1-2 hours for each museum.', 1)
    RETURNING id INTO v_cat_museums;

    INSERT INTO content_items (id, card_id, parent_id, name, content, ai_knowledge_base, sort_order)
    VALUES (gen_random_uuid(), v_card_id, NULL, '🏠 Historic Buildings', 'Architecture from centuries past', 'Historic buildings span from 1700s to 1900s. Many are original structures, others faithfully restored.', 2)
    RETURNING id INTO v_cat_historic;

    INSERT INTO content_items (id, card_id, parent_id, name, content, ai_knowledge_base, sort_order)
    VALUES (gen_random_uuid(), v_card_id, NULL, '⚓ Waterfront & Harbor', 'Where commerce meets the sea', 'The waterfront remains a working harbor with fishing boats alongside historic vessels. Great for photos.', 3)
    RETURNING id INTO v_cat_waterfront;

    -- Insert museums (Layer 2)
    INSERT INTO content_items (card_id, parent_id, name, content, image_url, ai_knowledge_base, sort_order) VALUES
    (v_card_id, v_cat_museums, 'Harbor Visitor Center', E'**Start Your Journey Here** 📍\n\n---\n\nBuilt in 1892 as the Harbor Master''s office, this beautifully restored building now serves as your gateway to the historic district.\n\n**Inside You''ll Find:**\n- Free maps and audio guides\n- Historical exhibits on harbor life\n- Restrooms and accessibility services\n- Gift shop with local crafts\n\n---\n\n⏰ **Hours:** 9am-5pm daily\n🎟️ **Admission:** Free\n♿ **Fully accessible**', NULL, 'Building originally 1892, restored in 1978. Harbor Master Captain William Shaw occupied this building for 40 years. Volunteer docents available 10am-3pm daily.', 1),
    
    (v_card_id, v_cat_museums, 'Maritime & Whaling Museum', E'**A Living Testament to Seafaring History** ⚓\n\n---\n\nHoused in a restored 1830s candleworks factory, this museum tells the story of when this harbor was the whaling capital of the world.\n\n**Highlights:**\n- 46-foot sperm whale skeleton\n- Fully restored whaleboat with original harpoons\n- Scrimshaw collection (largest in the world)\n- Captain''s quarters recreation\n\n---\n\n⏰ **Hours:** 10am-5pm (closed Tuesdays)\n🎟️ **Admission:** $18 adults, $12 children\n♿ **Elevator to all floors**', NULL, 'Museum founded 1904, one of oldest maritime museums in US. Whale skeleton is "Kobo," a sperm whale that beached in 1891. Docent tours at 11am and 2pm included with admission.', 2),
    
    (v_card_id, v_cat_museums, 'Seamen''s Bethel Chapel', E'**Sanctuary for Sailors** ⛪\n\n---\n\nThis 1832 chapel was built as a place of worship and refuge for sailors far from home. Herman Melville visited here, and the chapel features prominently in *Moby-Dick*.\n\n**Inside:**\n- Pulpit shaped like a ship''s bow (as described in Melville)\n- Memorial tablets to sailors lost at sea\n- Original pews with names of ships carved by sailors\n\n---\n\n⏰ **Hours:** 10am-4pm Mon-Sat\n🎟️ **Admission:** Donation suggested\n🤫 **Please maintain respectful silence**', NULL, 'Melville visited December 1840 before his own whaling voyage. Memorial tablets list 2,847 sailors lost from this port. Chapel still holds services Sundays 10am.', 3);

    -- Insert historic buildings (Layer 2)
    INSERT INTO content_items (card_id, parent_id, name, content, image_url, ai_knowledge_base, sort_order) VALUES
    (v_card_id, v_cat_historic, 'Old Harbor Lighthouse', E'**Guiding Ships Since 1802** 🏠\n\n---\n\nThis iconic lighthouse has stood sentinel over the harbor entrance for over 200 years. Climb 87 steps to the top for stunning views of the coastline.\n\n**The Lighthouse Story:**\nOriginally built in 1802, the current tower dates from 1857 when a storm destroyed the original structure. The Fresnel lens, imported from France, remains operational today.\n\n---\n\n⏰ **Hours:** 9am-4pm (last climb 3:30pm)\n🎟️ **Tower climb:** $8\n⚠️ **87 steps, not accessible**', NULL, 'Light visible 14 miles at sea. Fresnel lens is 3rd order, weighs 1,000 lbs. Last staffed keeper retired 1986. Ghost stories: Keeper Thomas Cobb allegedly still walks the tower on foggy nights.', 1),
    
    (v_card_id, v_cat_historic, 'Captain''s Row Historic Houses', E'**Where Fortunes Were Made** 🏛️\n\n---\n\nThis elegant street of Federal and Greek Revival mansions was home to the wealthy sea captains who commanded whaling fleets and trading ships.\n\n**Notable Houses:**\n- **#15 Coffin House (1834):** Home of Captain Nathaniel Coffin, who circumnavigated the globe four times\n- **#23 Macy Mansion (1841):** Built with profits from Pacific whale oil trade\n- **#31 Starbuck Hall (1846):** Largest house on the street, now a bed & breakfast\n\n---\n\n🏠 **Interior tours:** Select homes open seasonally\n📸 **Photo tip:** Best lighting mid-afternoon', NULL, 'Coffin, Macy, and Starbuck families dominated harbor commerce. The cobblestones are original—carried as ship ballast from European ports. Most houses built 1830-1850 during whaling boom.', 2),
    
    (v_card_id, v_cat_historic, 'Historic Shipyard', E'**Where Great Ships Were Born** ⚙️\n\n---\n\nFrom 1780 to 1920, this shipyard launched over 400 vessels. Today, traditional shipbuilding skills are still taught and practiced.\n\n**Live Demonstrations:**\n- Traditional wooden boat building (daily)\n- Sail making and rigging (weekends)\n- Blacksmith forge work (Wed & Sat)\n\n---\n\n⏰ **Hours:** 9am-5pm daily\n🎟️ **Admission:** $12 adults, $8 children\n👷 **Try boat building yourself (additional fee)**', NULL, 'Shipyard founded by Jedidiah Barlow, built famous clipper ship "Sea Witch" (1846). Current program trains 20 apprentices annually in traditional skills.', 3);

    -- Insert waterfront (Layer 2)
    INSERT INTO content_items (card_id, parent_id, name, content, image_url, ai_knowledge_base, sort_order) VALUES
    (v_card_id, v_cat_waterfront, 'Straight Wharf & Fish Market', E'**Where Commerce Meets the Sea** 🐟\n\n---\n\nFor 350 years, this wharf has been the commercial heart of the harbor. Today, fishing boats still unload their daily catch.\n\n**What to See:**\n- Morning fish auction (5am-7am)\n- Working fishing boats and lobster traps\n- Historic ship chandlery (now a museum shop)\n- Artist studios in converted warehouses\n\n**What to Eat:**\nTry the legendary lobster rolls from the waterfront shack.\n\n---\n\n🐟 **Fish market:** 6am-6pm\n🦞 **Lobster shack:** 11am-8pm (cash only)', NULL, 'Wharf originally built 1670. Fish auction is oldest continuous market in the country. Lobster shack run by same family for 4 generations - the MacNeils.', 1),
    
    (v_card_id, v_cat_waterfront, 'Harbor View Park & Memorial', E'**Reflection and Remembrance** 🌅\n\n---\n\nEnd your tour at this peaceful waterfront park, where benches face the harbor and the memorial honors those who shaped this community''s history.\n\n**The Memorial:**\nBronze sculptures depict a whaler, a captain, a lighthouse keeper, and a fisherman''s wife—representing the people who built this town.\n\n**The View:**\nOn clear days, you can see 15 miles out to sea. Watch for seals on the outer rocks (bring binoculars).\n\n---\n\n⏰ **Park hours:** Dawn to dusk\n🎟️ **Admission:** Free\n🪑 **Benches throughout park**', NULL, 'Park created 1956 on site of old rope walk factory. Memorial dedicated 1976 for Bicentennial. Best sunset watching is late June. Ice cream shop Flanagan''s open since 1889.', 2);

    -- Insert into content_templates for template library management
    INSERT INTO content_templates (slug, card_id, venue_type, is_featured, is_active, sort_order)
    VALUES ('tourist-landmark', v_card_id, 'tours', true, true, 19);

    RAISE NOTICE 'Successfully created Tourist Landmark template with card ID: %', v_card_id;

END $body$;
