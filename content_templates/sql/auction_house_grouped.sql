-- Auction House - Grouped List Mode (Digital Access)
-- Template: Auction catalog with lots by category
-- 
-- INSTRUCTIONS:
-- 1. Replace 'YOUR_USER_ID_HERE' with actual user UUID
-- 2. Update image_url values with actual uploaded image URLs
-- 3. Run this SQL in Supabase SQL Editor or via psql

DO $body$
DECLARE
    v_user_id UUID := 'YOUR_USER_ID_HERE'::UUID;
    v_card_id UUID;
    v_cat_impressionist UUID;
    v_cat_contemporary UUID;
    v_cat_decorative UUID;
    v_cat_jewelry UUID;
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
        'Heritage Auctions - Spring Fine Art Sale',
        E'**Spring Fine Art Auction 2025**\n\nApril 15-16 | Live & Online Bidding\n\nBrowse 180+ lots of exceptional paintings, sculptures, and decorative arts.\n\n📞 Bidder Registration: +1 (555) 123-4567',
        'list',
        true,
        'expanded',
        'digital',
        true,
        'You are a knowledgeable art specialist at a prestigious auction house. Help potential bidders understand lots, provenance, condition, and market context. Be professional yet approachable. Explain auction terminology and bidding process to newcomers. Never give price predictions.',
        E'Heritage Auctions - Spring Fine Art Sale 2025\nDates: April 15-16, 2025\nLocation: Heritage Auction House, 500 Park Avenue\nPreview: April 12-14, 10am-6pm\n\nBidding options: In-person paddle, phone bid, online via LiveAuctioneer\nBuyer''s premium: 25% on hammer price\n\nPayment: Wire transfer, certified check, major credit cards\nShipping: In-house shipping department, international available\n\nCondition reports available upon request\nAll sales final, subject to Terms & Conditions',
        'Welcome to Heritage Auctions! I can explain any lot''s provenance, discuss condition reports, clarify bidding procedures, or help you find pieces in your collecting area. What interests you?',
        'You''re viewing Lot {name}! I can share provenance details, discuss the estimate, explain condition, or compare it to recent auction results. What would you like to know?',
        NULL,
        TRUE,
        replace(replace(encode(gen_random_bytes(9), 'base64'), '+', '-'), '/', '_')
    ) RETURNING id INTO v_card_id;

    -- Category 1: Impressionist & Modern Art
    INSERT INTO content_items (id, card_id, parent_id, name, content, ai_knowledge_base, sort_order)
    VALUES (gen_random_uuid(), v_card_id, NULL, 'Impressionist & Modern Art', '', 
        'Session 1: April 15, 10:00 AM. Lots 1-45: Works from 1860-1940. Highlight: Monet water lily study, Picasso ceramic. Estimates range $5,000 - $500,000.', 1)
    RETURNING id INTO v_cat_impressionist;

    INSERT INTO content_items (card_id, parent_id, name, content, image_url, ai_knowledge_base, sort_order) VALUES
    (v_card_id, v_cat_impressionist, 'Lot 12 - Monet Water Lily Study', E'**Claude Monet (French, 1840-1926)**\n\n*Nymphéas, étude* (Water Lilies, study)\nc. 1905\n\nOil on canvas\n18 × 24 inches (45.7 × 61 cm)\nSigned lower right: Claude Monet\n\n---\n\n**Provenance:**\n- Estate of the artist\n- Galerie Durand-Ruel, Paris (acquired 1927)\n- Private collection, Geneva (1952-2024)\n\n**Estimate:** $350,000 - $450,000\n\n🔨 **Session 1** | April 15, ~11:30 AM', NULL, 'One of numerous water lily studies Monet made at Giverny. This example shows the looser brushwork of his later period. Authenticated by Wildenstein Institute. Condition: Excellent, minor craquelure consistent with age. Provenance is impeccable - Durand-Ruel was Monet''s primary dealer. Similar works sold $400K-600K recently.', 1),
    
    (v_card_id, v_cat_impressionist, 'Lot 23 - Picasso Ceramic Owl', E'**Pablo Picasso (Spanish, 1881-1973)**\n\n*Hibou mat* (Matte Owl)\n1953\n\nTurned vase, white earthenware clay\nEdition of 500\nHeight: 13 inches (33 cm)\nStamped and numbered: Madoura Plein Feu / Edition Picasso\n\n---\n\n**Provenance:**\n- Madoura Pottery, Vallauris\n- Private collection, New York\n\n**Literature:**\n- Ramié, Alain, *Picasso Catalogue*, no. 253\n\n**Estimate:** $25,000 - $35,000\n\n🔨 **Session 1** | April 15, ~12:15 PM', NULL, 'From Picasso''s prolific ceramic period at Madoura pottery. Owl was favorite motif - symbolism of wisdom, night, Athena. Edition of 500 is relatively large for Picasso ceramics. Condition: Excellent, no chips or restoration. Madoura stamp authenticates. Market for Picasso ceramics strong, especially zoomorphic forms.', 2);

    -- Category 2: Contemporary Art
    INSERT INTO content_items (id, card_id, parent_id, name, content, ai_knowledge_base, sort_order)
    VALUES (gen_random_uuid(), v_card_id, NULL, 'Contemporary Art', '', 
        'Session 1: April 15, 2:00 PM. Lots 46-90: Works from 1945-present. Highlight: Warhol silk screen, Basquiat drawing. Estimates range $10,000 - $800,000.', 2)
    RETURNING id INTO v_cat_contemporary;

    INSERT INTO content_items (card_id, parent_id, name, content, image_url, ai_knowledge_base, sort_order) VALUES
    (v_card_id, v_cat_contemporary, 'Lot 52 - Warhol Campbell''s Soup', E'**Andy Warhol (American, 1928-1987)**\n\n*Campbell''s Soup Can (Tomato)*\n1968\n\nScreenprint on paper\n35 × 23 inches (88.9 × 58.4 cm)\nFrom the edition of 250\nSigned and numbered in pencil\n\n---\n\n**Provenance:**\n- Leo Castelli Gallery, New York\n- Private collection, Los Angeles\n\n**Exhibition:**\n- "Warhol: Icons", MOCA, 1995\n\n**Estimate:** $150,000 - $200,000\n\n🔨 **Session 1** | April 15, ~2:30 PM', NULL, 'Iconic Warhol image from 1968 portfolio of 10 soup can varieties. Tomato is most recognizable. This impression has strong colors, no fading. Pencil signature is period-appropriate (Warhol varied signature style). MOCA exhibition history adds provenance value. Market: Strong demand, prices up 15% over 5 years.', 1),
    
    (v_card_id, v_cat_contemporary, 'Lot 67 - Basquiat Untitled Drawing', E'**Jean-Michel Basquiat (American, 1960-1988)**\n\n*Untitled (Head)*\n1982\n\nOil stick and graphite on paper\n22 × 30 inches (55.9 × 76.2 cm)\nSigned and dated verso\n\n---\n\n**Provenance:**\n- Tony Shafrazi Gallery, New York (1983)\n- Private collection, Miami\n\n**Authentication:**\n- Authentication Committee of the Estate of Jean-Michel Basquiat\n\n**Estimate:** $600,000 - $800,000\n\n🔨 **Session 1** | April 15, ~3:15 PM', NULL, '1982 was breakthrough year for Basquiat - Documenta 7, first solo shows. Head/skull motif is central to his iconography. Authentication by Estate committee is essential - many forgeries exist. Condition: Some paper toning, oil stick stable. Tony Shafrazi was key early dealer. Current market extremely strong for works on paper.', 2);

    -- Category 3: Decorative Arts & Furniture
    INSERT INTO content_items (id, card_id, parent_id, name, content, ai_knowledge_base, sort_order)
    VALUES (gen_random_uuid(), v_card_id, NULL, 'Decorative Arts & Furniture', '', 
        'Session 2: April 16, 10:00 AM. Lots 91-130: European furniture, silver, porcelain. Highlight: Louis XV commode, Tiffany lamp. Estimates range $2,000 - $150,000.', 3)
    RETURNING id INTO v_cat_decorative;

    INSERT INTO content_items (card_id, parent_id, name, content, image_url, ai_knowledge_base, sort_order) VALUES
    (v_card_id, v_cat_decorative, 'Lot 98 - Louis XV Commode', E'**Louis XV Kingwood Commode**\n\nAttributed to Jean-François Oeben\nParis, c. 1755\n\nKingwood and tulipwood marquetry, gilt bronze mounts, Brèche d''Alep marble top\n34 × 50 × 24 inches (86 × 127 × 61 cm)\n\n---\n\n**Provenance:**\n- French noble collection (per tradition)\n- Sotheby''s Monaco, 1988\n- Private collection, London\n\n**Estimate:** $80,000 - $120,000\n\n🔨 **Session 2** | April 16, ~10:45 AM', NULL, 'Jean-François Oeben was master ébéniste, teacher of Riesener. Kingwood (bois de violette) prized for purple-brown tone. Marquetry pattern shows floral scrolls typical of period. Mounts appear period but may include 19th c. replacements (common). Marble top is later replacement. Condition report details restorations.', 1),
    
    (v_card_id, v_cat_decorative, 'Lot 115 - Tiffany Dragonfly Lamp', E'**Tiffany Studios Dragonfly Table Lamp**\n\nNew York, c. 1905\n\nLeaded glass shade, bronze base\nShade diameter: 16 inches (40.6 cm)\nOverall height: 22 inches (55.9 cm)\nShade stamped: TIFFANY STUDIOS NEW YORK\nBase stamped: TIFFANY STUDIOS NEW YORK 337\n\n---\n\n**Provenance:**\n- Private collection, Connecticut (acquired c. 1920)\n- By descent to present owner\n\n**Estimate:** $100,000 - $150,000\n\n🔨 **Session 2** | April 16, ~11:30 AM', NULL, 'Dragonfly is one of most desirable Tiffany lamp designs. This is 16-inch "cone" shade version (larger 20-inch more valuable). All glass appears original - no replaced segments. Bronze base #337 is correct period pairing. Provenance from 1920 suggests original purchase. Market for quality Tiffany very strong, especially insect designs (dragonfly, butterfly, spider).', 2);

    -- Category 4: Jewelry & Watches
    INSERT INTO content_items (id, card_id, parent_id, name, content, ai_knowledge_base, sort_order)
    VALUES (gen_random_uuid(), v_card_id, NULL, 'Jewelry & Watches', '', 
        'Session 2: April 16, 2:00 PM. Lots 131-180: Signed jewelry, vintage watches, diamonds. Highlight: Art Deco Cartier bracelet, Patek Philippe chronograph. Estimates range $5,000 - $250,000.', 4)
    RETURNING id INTO v_cat_jewelry;

    INSERT INTO content_items (card_id, parent_id, name, content, image_url, ai_knowledge_base, sort_order) VALUES
    (v_card_id, v_cat_jewelry, 'Lot 145 - Cartier Art Deco Bracelet', E'**Cartier Art Deco Diamond Bracelet**\n\nParis, c. 1925\n\nPlatinum, set with old European-cut diamonds\nTotal diamond weight: approximately 15.00 carats\nLength: 7 inches (17.8 cm)\nSigned: Cartier Paris, numbered\n\n---\n\n**Provenance:**\n- European private collection\n\n**Accompanied by:**\n- Cartier archive extract confirming manufacture\n\n**Estimate:** $180,000 - $250,000\n\n🔨 **Session 2** | April 16, ~2:45 PM', NULL, 'Geometric Art Deco design with calibré-cut diamonds. Paris-made Cartier of this period commands premium over London or New York. Old European cut diamonds show period-correct faceting. Cartier archive confirmation is gold standard for authentication. Platinum shows minimal wear. Art Deco jewelry market extremely strong, especially signed Cartier.', 1),
    
    (v_card_id, v_cat_jewelry, 'Lot 162 - Patek Philippe Ref. 5170', E'**Patek Philippe Reference 5170G-010**\n\nManual-winding chronograph\nGeneva, 2015\n\n18k white gold case, 39.4mm\nSilvered dial with applied Breguet numerals\nCaliber CH 29-535 PS\n\n---\n\n**Accompanied by:**\n- Original box and papers\n- Patek Philippe Certificate of Origin\n- Extract from the Archives\n\n**Estimate:** $60,000 - $80,000\n\n🔨 **Session 2** | April 16, ~3:30 PM', NULL, 'Reference 5170 introduced 2010, first in-house manual chronograph movement. Caliber CH 29-535 PS has column wheel, horizontal clutch. White gold with silver dial is classic configuration. Full set with box/papers commands 15-20% premium. Condition appears unworn. 5170 series discontinued, values appreciating. Extract from Archives confirms authenticity and original sale date.', 2);

    -- Insert into content_templates for template library management
    INSERT INTO content_templates (slug, card_id, venue_type, is_featured, is_active, sort_order)
    VALUES ('auction-house', v_card_id, 'cultural', true, true, 3);

    RAISE NOTICE 'Successfully created Auction House template with card ID: %', v_card_id;

END $body$;

