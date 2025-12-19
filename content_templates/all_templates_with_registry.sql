-- =================================================================
-- Combined Content Templates with Registry
-- =================================================================
-- This file creates:
-- 1. Cards with all their content items
-- 2. Entries in content_templates table to register them as templates
--
-- IMPORTANT: Run this AFTER schema.sql and all_stored_procedures.sql
-- =================================================================

-- Generated: Sat Dec 13 15:19:53 HKT 2025
-- User ID: 91acf5ca-f78b-4acd-bc75-98b85959ce62


-- ==================================================================
-- Template 1: Art Gallery - Grid Mode
-- Slug: art-gallery-grid | Venue: museum
-- ==================================================================

-- Art Gallery - Grid Mode (Digital Access)
-- Template: Contemporary Art Exhibition
-- 
-- INSTRUCTIONS:
-- 1. Replace '91acf5ca-f78b-4acd-bc75-98b85959ce62' with actual user UUID
-- 2. Update image_url values with actual uploaded image URLs
-- 3. Run this SQL in Supabase SQL Editor or via psql

DO $body$
DECLARE
    v_user_id UUID := '91acf5ca-f78b-4acd-bc75-98b85959ce62'::UUID;
    v_card_id UUID;
    v_default_category UUID;
BEGIN
    -- Insert the card
    INSERT INTO cards (
        id, user_id, name, description, content_mode, is_grouped, group_display, billing_type,
        conversation_ai_enabled, ai_instruction, ai_knowledge_base,
        ai_welcome_general, ai_welcome_item, image_url
    ) VALUES (
        gen_random_uuid(),
        v_user_id,
        'Modern Visions: Contemporary Art Collection',
        E'Welcome to **Modern Visions**, featuring 12 groundbreaking contemporary artworks that challenge perception and celebrate human creativity.\n\nThis exhibition brings together emerging and established artists exploring themes of identity, technology, and the natural world through painting, sculpture, and mixed media.\n\n🎨 Tap any artwork to learn more and chat with our AI art guide.',
        'grid',
        true,
        'expanded',
        'digital',
        true,
        'You are an enthusiastic art docent at a contemporary art gallery. Speak with passion about the artworks, artists, and artistic movements. Help visitors understand the meaning, techniques, and context behind each piece. Be approachable and encourage questions. Avoid overly academic language.',
        E'Modern Visions Exhibition - Contemporary Art Collection 2024\n\nExhibition themes: Identity in the digital age, environmental consciousness, urban life, human connection, abstraction and emotion.\n\nGallery layout: Main hall (large installations), East wing (paintings), West wing (sculptures and mixed media), North gallery (digital art).\n\nArtist talks every Saturday at 2pm. Guided tours at 11am and 3pm daily.\nGift shop near exit with exhibition catalog and prints available.\nPhotography allowed without flash. No touching artworks.',
        'Welcome to Modern Visions! I''m your personal art guide. Ask me anything about the artworks, artists, or get recommendations based on your interests!',
        'I''d love to tell you more about "{name}". What would you like to know?',
        NULL -- Replace with actual image URL
    ) RETURNING id INTO v_card_id;

    -- Create default category (hidden in flat mode, holds all content items)
    INSERT INTO content_items (id, card_id, parent_id, name, content, ai_knowledge_base, sort_order)
    VALUES (gen_random_uuid(), v_card_id, NULL, 'General', '', '', 1)
    RETURNING id INTO v_default_category;

    -- Insert content items (layer 2 under default category)
    INSERT INTO content_items (card_id, parent_id, name, content, image_url, ai_knowledge_base, sort_order) VALUES
    (v_card_id, v_default_category, 'Echoes of Tomorrow', E'**Artist:** Maya Chen\n**Year:** 2024\n**Medium:** Oil on canvas, LED elements\n**Dimensions:** 180 × 240 cm\n\nA stunning fusion of traditional oil painting with embedded LED lighting, this piece depicts a cityscape that shifts between day and night. Chen explores how technology shapes our perception of urban spaces and the passage of time.\n\n*"I wanted to capture that moment between waking and dreaming, when the city exists in both states simultaneously."* — Maya Chen', NULL, 'Maya Chen (b. 1988, Taipei) is a Taiwanese-American artist known for incorporating technology into traditional painting. Studied at RISD and Central Saint Martins. This piece took 8 months to complete. The LEDs are programmed to cycle through a 24-hour light pattern. Chen was inspired by her childhood memories of Taipei''s night markets contrasted with modern smart cities.', 1),
    
    (v_card_id, v_default_category, 'Fragments of Self', E'**Artist:** James Okonkwo\n**Year:** 2023\n**Medium:** Recycled mirrors, steel frame\n**Dimensions:** 200 × 150 × 150 cm\n\nA sculptural installation using 847 recycled mirror fragments arranged to create a fragmented human figure. As viewers move around the piece, they see their own reflection broken and reassembled, questioning the nature of identity and wholeness.', NULL, 'James Okonkwo (b. 1975, Lagos) explores identity and diaspora through sculpture. The mirrors were collected from demolished buildings in London over 3 years. Each fragment represents a piece of cultural identity. Winner of the Turner Prize 2023. The piece is interactive - viewers become part of the artwork.', 2),
    
    (v_card_id, v_default_category, 'Digital Garden #7', E'**Artist:** Sofia Andersson\n**Year:** 2024\n**Medium:** Generative AI, projection mapping\n**Dimensions:** Variable (room-scale installation)\n\nAn immersive digital environment where AI-generated flowers bloom and wilt in response to viewers'' movements. The algorithm creates unique botanical forms that have never existed in nature, blurring the line between the organic and artificial.', NULL, 'Sofia Andersson (b. 1992, Stockholm) specializes in AI-generated art. Trained her own neural network on 2 million botanical images. The installation uses 6 projectors and motion sensors. Each viewing experience is unique - the AI never repeats patterns. Exploring themes of extinction, creation, and the future of nature.', 3),
    
    (v_card_id, v_default_category, 'The Weight of Water', E'**Artist:** David Park\n**Year:** 2023\n**Medium:** Cast glass, suspended steel cables\n**Dimensions:** 400 × 300 × 250 cm\n\nTwelve thousand hand-cast glass droplets suspended from the ceiling, creating an ethereal rain frozen in time. The installation represents the fragility of water resources and the impermanence of our natural world.', NULL, 'David Park (b. 1980, Seoul) is known for large-scale glass installations. Each droplet was individually cast over 18 months. Uses Venetian glassblowing techniques combined with Korean metalwork. Created in response to climate change and water scarcity. The piece weighs 1.2 tonnes and took a team of 15 to install.', 4),
    
    (v_card_id, v_default_category, 'Concrete Dreams', E'**Artist:** Fatima Al-Hassan\n**Year:** 2024\n**Medium:** Concrete, embedded photographs, resin\n**Dimensions:** 90 × 120 cm (triptych)\n\nA triptych embedding family photographs within concrete slabs, exploring themes of memory, permanence, and the built environment. The photos gradually become visible as light passes through the semi-translucent resin pockets.', NULL, 'Fatima Al-Hassan (b. 1985, Beirut) explores memory and displacement. Uses actual family photographs from her grandmother''s collection. The concrete represents the buildings of her childhood neighborhood in Beirut. Each panel took 3 months to cure properly. The photographs were protected with archival resin before embedding.', 5),
    
    (v_card_id, v_default_category, 'Neon Wilderness', E'**Artist:** Tommy Rivera\n**Year:** 2024\n**Medium:** Neon tubes, natural branches, electronics\n**Dimensions:** 300 × 400 × 200 cm\n\nA forest of dead tree branches illuminated with custom neon tubes in blues, pinks, and purples. The installation explores the intersection of nature and artificiality, creating a surreal landscape that feels both familiar and alien.', NULL, 'Tommy Rivera (b. 1990, Mexico City) works with light and natural materials. Branches collected from fallen trees in Central Park. Neon tubes custom-bent by artisans in Brooklyn. The colors cycle through a 12-hour pattern representing a compressed day/night cycle. Inspired by the Sonoran Desert meets urban nightlife.', 6),
    
    (v_card_id, v_default_category, 'Woven Histories', E'**Artist:** Amara Diallo\n**Year:** 2023\n**Medium:** Reclaimed textiles, gold thread\n**Dimensions:** 500 × 300 cm\n\nA monumental tapestry created from clothing donated by immigrant families, stitched together with gold thread that traces migration routes. Each piece of fabric carries stories of journey, loss, and new beginnings.', NULL, 'Amara Diallo (b. 1983, Dakar) specializes in textile art addressing migration. Contains fabric from over 200 families across 5 continents. Gold thread maps actual migration routes from GPS data. Created in collaboration with local immigrant communities over 2 years. Each fabric piece has a documented story available via QR codes on the accompanying catalog.', 7),
    
    (v_card_id, v_default_category, 'Binary Sunset', E'**Artist:** Alex Zhang-Müller\n**Year:** 2024\n**Medium:** Data visualization, custom software, dual screens\n**Dimensions:** 180 × 240 cm (each screen)\n\nTwo screens display real-time sunsets from opposite sides of the Earth, visualized through abstract data patterns. The piece connects distant moments, showing how our digital world compresses time and space.', NULL, 'Alex Zhang-Müller (b. 1995, Berlin) works with data as an artistic medium. Live data feeds from weather stations in New Zealand and Portugal. Custom algorithm translates atmospheric data into visual patterns. Runs 24/7, constantly changing. Exploring global connectivity and shared human experiences.', 8),
    
    (v_card_id, v_default_category, 'The Listener', E'**Artist:** Roberto Gómez\n**Year:** 2024\n**Medium:** Bronze, sound installation\n**Dimensions:** 180 cm tall\n\nA bronze figure with an oversized ear, housing speakers that play ambient sounds recorded from public spaces around the world. The sculpture invites contemplation of how we listen—and what we choose to hear.', NULL, 'Roberto Gómez (b. 1972, Buenos Aires) creates sculptures with integrated sound. Sounds recorded in 47 cities over 5 years. Audio loops for 4 hours before repeating. Includes markets, parks, protests, celebrations. Cast using lost-wax method. Inspired by surveillance culture and the importance of active listening.', 9),
    
    (v_card_id, v_default_category, 'Ephemeral Architecture', E'**Artist:** Yuki Tanaka\n**Year:** 2023\n**Medium:** Paper, wire, UV-reactive pigments\n**Dimensions:** 250 × 250 × 300 cm\n\nAn intricate paper model of an imaginary city that glows under UV light, revealing hidden pathways and structures invisible in daylight. The piece explores the invisible systems that shape our urban environments.', NULL, 'Yuki Tanaka (b. 1988, Tokyo) trained as an architect before turning to art. Contains 3,847 individually folded paper buildings. UV patterns represent electrical grids, water systems, and digital networks. Took 14 months to construct. Viewing times include both natural light and UV-lit sessions.', 10),
    
    (v_card_id, v_default_category, 'Mother Tongue', E'**Artist:** Elena Voronova\n**Year:** 2024\n**Medium:** Ceramic, sound sensors, speakers\n**Dimensions:** Variable (7 sculptural forms)\n\nSeven ceramic forms representing different phonetic sounds, each equipped with sensors that trigger recordings of endangered languages when approached. A meditation on linguistic diversity and cultural preservation.', NULL, 'Elena Voronova (b. 1979, Moscow) focuses on language and identity. Features recordings of 23 endangered languages from Ethnologue database. Collaborated with UNESCO and linguistic anthropologists. Ceramic forms based on spectrograms of speech patterns. Interactive element encourages visitors to speak into the forms.', 11),
    
    (v_card_id, v_default_category, 'Infinite Regression', E'**Artist:** Marcus Webb\n**Year:** 2024\n**Medium:** Mirrors, wood, LED infinity effect\n**Dimensions:** 200 × 200 × 200 cm\n\nA cube of parallel mirrors creating an infinite visual regression, with LED strips that seem to extend forever. Visitors can step inside to experience the disorienting sensation of endless space within finite boundaries.', NULL, 'Marcus Webb (b. 1982, London) explores perception and optical phenomena. Entry limited to 3 visitors at a time for safety. LED colors shift based on time of day. Mathematical precision required for infinite effect. Inspired by Yayoi Kusama''s Infinity Rooms but focusing on geometric precision rather than pattern. Temporary vertigo is normal and expected.', 12);

    RAISE NOTICE 'Successfully created Art Gallery card with ID: %', v_card_id;
END $body$;


-- Register "Art Gallery - Grid Mode" as content template
DO $reg$
DECLARE
    v_card_id UUID;
BEGIN
    -- Find the card we just created by name and user
    SELECT id INTO v_card_id
    FROM cards 
    WHERE user_id = '91acf5ca-f78b-4acd-bc75-98b85959ce62'::UUID
      AND name = 'Modern Visions: Contemporary Art Collection'
    ORDER BY created_at DESC
    LIMIT 1;
    
    IF v_card_id IS NULL THEN
        RAISE WARNING 'Could not find card "Modern Visions: Contemporary Art Collection" for template registration';
    ELSE
        -- Register or update the template
        INSERT INTO content_templates (slug, card_id, venue_type, is_featured, is_active, sort_order)
        VALUES ('art-gallery-grid', v_card_id, 'museum', false, true, 1)
        ON CONFLICT (slug) DO UPDATE SET
            card_id = EXCLUDED.card_id,
            venue_type = EXCLUDED.venue_type,
            sort_order = EXCLUDED.sort_order,
            updated_at = NOW();
        
        RAISE NOTICE 'Registered template: art-gallery-grid (card_id: %)', v_card_id;
    END IF;
END $reg$;


-- ==================================================================
-- Template 2: Auction House - Grouped List
-- Slug: auction-house-grouped | Venue: retail
-- ==================================================================

-- Auction House - Grouped List Mode (Digital Access)
-- Template: Auction catalog with lots by category
-- 
-- INSTRUCTIONS:
-- 1. Replace '91acf5ca-f78b-4acd-bc75-98b85959ce62' with actual user UUID
-- 2. Update image_url values with actual uploaded image URLs
-- 3. Run this SQL in Supabase SQL Editor or via psql

DO $body$
DECLARE
    v_user_id UUID := '91acf5ca-f78b-4acd-bc75-98b85959ce62'::UUID;
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
        ai_welcome_general, ai_welcome_item, image_url
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
        'Welcome to Heritage Auctions. I''m here to help you explore our Spring Fine Art Sale. Which collecting area interests you?',
        'Excellent eye! Let me tell you more about Lot {name} - this is a particularly noteworthy piece.',
        NULL
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

    RAISE NOTICE 'Successfully created Auction House card with ID: %', v_card_id;
END $body$;


-- Register "Auction House - Grouped List" as content template
DO $reg$
DECLARE
    v_card_id UUID;
BEGIN
    -- Find the card we just created by name and user
    SELECT id INTO v_card_id
    FROM cards 
    WHERE user_id = '91acf5ca-f78b-4acd-bc75-98b85959ce62'::UUID
      AND name = 'Heritage Auction House: Spring Collection 2024'
    ORDER BY created_at DESC
    LIMIT 1;
    
    IF v_card_id IS NULL THEN
        RAISE WARNING 'Could not find card "Heritage Auction House: Spring Collection 2024" for template registration';
    ELSE
        -- Register or update the template
        INSERT INTO content_templates (slug, card_id, venue_type, is_featured, is_active, sort_order)
        VALUES ('auction-house-grouped', v_card_id, 'retail', false, true, 2)
        ON CONFLICT (slug) DO UPDATE SET
            card_id = EXCLUDED.card_id,
            venue_type = EXCLUDED.venue_type,
            sort_order = EXCLUDED.sort_order,
            updated_at = NOW();
        
        RAISE NOTICE 'Registered template: auction-house-grouped (card_id: %)', v_card_id;
    END IF;
END $reg$;


-- ==================================================================
-- Template 3: Cocktail Bar - Full Cards
-- Slug: cocktail-bar-inline | Venue: restaurant
-- ==================================================================

-- Cocktail Bar - Full Cards Mode (Digital Access)
-- Template: Craft cocktail menu with featured drinks
-- 
-- INSTRUCTIONS:
-- 1. Replace '91acf5ca-f78b-4acd-bc75-98b85959ce62' with actual user UUID
-- 2. Update image_url values with actual uploaded image URLs
-- 3. Run this SQL in Supabase SQL Editor or via psql

DO $body$
DECLARE
    v_user_id UUID := '91acf5ca-f78b-4acd-bc75-98b85959ce62'::UUID;
    v_card_id UUID;
    v_default_category UUID;
BEGIN
    -- Insert the card
    INSERT INTO cards (
        id, user_id, name, description, content_mode, is_grouped, group_display, billing_type,
        conversation_ai_enabled, ai_instruction, ai_knowledge_base,
        ai_welcome_general, ai_welcome_item, daily_scan_limit
    ) VALUES (
        gen_random_uuid(),
        v_user_id,
        'The Velvet Room - Cocktail Menu',
        E'**Craft cocktails. Timeless classics. New discoveries.**\n\nOur bartenders blend artistry with tradition, creating drinks that honor the classics while pushing boundaries. Every cocktail tells a story.\n\n🥃 Ask your bartender for recommendations based on your mood.',
        'cards',
        true,
        'expanded',
        'digital',
        true,
        'You are a knowledgeable craft bartender with a warm, inviting personality. Help guests find their perfect drink based on flavor preferences (sweet, sour, bitter, spirit-forward), mood, or occasion. Share cocktail history and stories. Be enthusiastic but not pretentious—everyone is welcome regardless of cocktail knowledge.',
        E'The Velvet Room - Craft Cocktail Bar\nEst. 2018 · Named "Best Bar" by City Magazine 2023\n\nHead Bartender: James Monroe (15 years experience, trained in London & Tokyo)\n\nBar philosophy: Classic techniques, quality ingredients, personal touch\nIce program: All ice cut in-house from 300lb blocks\nSpirits: 400+ bottles, emphasis on small-batch and craft\n\nNon-alcoholic options: Full "Zero Proof" menu available\nFood: Light snacks and charcuterie available\n\nHappy hour: 5-7pm, $10 classic cocktails\nReservations: Recommended for groups of 4+\nDress code: Smart casual',
        'Welcome to The Velvet Room! I''m here to help you find your perfect cocktail. What flavors are you in the mood for tonight?',
        'The "{name}" is one of our favorites! Would you like to know more about its ingredients or the story behind it?',
        1000
    ) RETURNING id INTO v_card_id;

    -- Create default category (hidden in flat mode, holds all content items)
    INSERT INTO content_items (id, card_id, parent_id, name, content, ai_knowledge_base, sort_order)
    VALUES (gen_random_uuid(), v_card_id, NULL, 'General', '', '', 1)
    RETURNING id INTO v_default_category;

    -- Insert cocktails (layer 2 under default category)
    INSERT INTO content_items (card_id, parent_id, name, content, image_url, ai_knowledge_base, sort_order) VALUES
    (v_card_id, v_default_category, 'The Velvet Old Fashioned', E'**Our signature take on the timeless classic**\n\n*Woodford Reserve bourbon · demerara · house bitters · orange oil*\n\nWe start with a base of Woodford Reserve, add house-made demerara syrup and our proprietary blend of aromatic bitters, then express orange oil over a single hand-cut ice sphere.\n\nThe result is a drink that honors the original while showcasing what thoughtful ingredients can achieve.\n\n---\n\n🥃 **Spirit:** Bourbon\n📊 **Strength:** Strong\n🍬 **Profile:** Spirit-forward, subtly sweet, aromatic\n💰 **$16**', NULL, 'Our #1 selling cocktail. House bitters blend includes: Angostura, orange, and house-made walnut bitters (walnut steeped for 3 weeks). Demerara syrup is 2:1 ratio for richer texture. Ice sphere is 2.5 inches, cut from 300lb block. Can substitute rye (Rittenhouse) or Japanese whisky (Nikka Coffey Grain) for different profiles. 2oz pour.', 1),
    
    (v_card_id, v_default_category, 'Tokyo Sour', E'**East meets West in a glass**\n\n*Suntory Toki · yuzu · egg white · shiso · matcha dust*\n\nA Japanese-inspired whisky sour featuring Suntory Toki, fresh yuzu juice, silky egg white foam, and aromatic shiso leaf. Finished with a delicate dusting of ceremonial-grade matcha.\n\nBright, balanced, and utterly refreshing.\n\n---\n\n🥃 **Spirit:** Japanese Whisky\n📊 **Strength:** Medium\n🍬 **Profile:** Citrus-forward, creamy, aromatic\n💰 **$17**\n🌿 *Can be made vegan with aquafaba*', NULL, 'Created by head bartender James after his trip to Tokyo in 2019. Yuzu juice imported from Japan (10x price of lemon). Shiso adds herbaceous, slightly minty note. Dry shake first (no ice) for foam, then wet shake. Matcha is ceremonial grade from Uji, Kyoto. Aquafaba (chickpea water) is perfect vegan substitute for egg white.', 2),
    
    (v_card_id, v_default_category, 'Smoke & Mirrors', E'**A theatrical experience for mezcal lovers**\n\n*Del Maguey Vida mezcal · Aperol · lime · agave · chipotle*\n\nOur most dramatic cocktail: smoky mezcal meets bitter Aperol, brightened with lime and rounded with agave nectar. A whisper of chipotle tincture adds warmth without heat.\n\nServed under a glass cloche filled with applewood smoke—lifted tableside for full sensory impact.\n\n---\n\n🥃 **Spirit:** Mezcal\n📊 **Strength:** Medium-Strong\n🍬 **Profile:** Smoky, bitter-sweet, complex\n💰 **$18**', NULL, 'Del Maguey Vida is 100% espadín agave from Oaxaca. Chipotle tincture made in-house (dried chipotles in high-proof vodka for 2 weeks, then strained). Smoke is from applewood chips using a smoking gun. Cloche creates drama and captures aroma. Best consumed within 2 minutes of reveal for full smoke experience. Very Instagrammable.', 3),
    
    (v_card_id, v_default_category, 'Garden Party', E'**Summer in a glass, any time of year**\n\n*Hendrick''s gin · elderflower · cucumber · lemon · prosecco*\n\nA spritz-style cocktail that''s light, floral, and impossibly refreshing. Hendrick''s gin provides the cucumber-rose base, lifted with elderflower and a generous splash of prosecco.\n\nPerfect for starting the evening or sipping all night.\n\n---\n\n🥃 **Spirit:** Gin\n📊 **Strength:** Light\n🍬 **Profile:** Floral, refreshing, effervescent\n💰 **$15**', NULL, 'Hendrick''s chosen for its cucumber and rose notes that complement the other ingredients. St-Germain elderflower liqueur. Fresh cucumber ribbon as garnish. Prosecco added last to preserve bubbles. Very popular with gin lovers and cocktail newcomers alike. Can substitute Sipsmith for a more juniper-forward version.', 4),
    
    (v_card_id, v_default_category, 'Midnight Manhattan', E'**Dark, brooding, sophisticated**\n\n*Rittenhouse rye · Carpano Antica · Cynar · Luxardo cherry*\n\nOur twist on the Manhattan adds Cynar (artichoke liqueur) for earthy depth and complexity. Stirred until silky and served up with a Luxardo cherry that''s worth the price alone.\n\nFor those who like their drinks with a little mystery.\n\n---\n\n🥃 **Spirit:** Rye Whiskey\n📊 **Strength:** Strong\n🍬 **Profile:** Spirit-forward, complex, slightly bitter\n💰 **$17**', NULL, 'Rittenhouse 100 proof stands up to the vermouth and Cynar. Carpano Antica is the gold standard of sweet vermouth. Cynar adds subtle bitter-vegetal note that rounds out sweetness. Luxardo cherries imported from Italy ($25/jar vs $5 for maraschinos). Stirred exactly 50 rotations for proper dilution. James'' favorite.', 5),
    
    (v_card_id, v_default_category, 'Honey Bee', E'**Sweet sophistication with a botanical twist**\n\n*Beefeater gin · local honey · lavender · lemon*\n\nA Bee''s Knees with a lavender upgrade. Local wildflower honey brings floral sweetness, while house-made lavender tincture adds aromatic complexity without overwhelming.\n\nLight enough for summer, warming enough for winter.\n\n---\n\n🥃 **Spirit:** Gin\n📊 **Strength:** Medium\n🍬 **Profile:** Sweet, floral, balanced\n💰 **$15**', NULL, 'Honey from local apiary (changes seasonally - currently clover). Lavender tincture uses culinary lavender steeped for 1 week. The Bee''s Knees was invented during Prohibition to mask bathtub gin. We use Beefeater for its botanical balance. Garnished with dried lavender sprig. Popular with guests who find gin "too juniper-y."', 6),
    
    (v_card_id, v_default_category, 'Dark & Stormy', E'**The perfect storm of rum and ginger**\n\n*Gosling''s Black Seal rum · house ginger beer · lime*\n\nThe official drink of Bermuda, made with the only rum legally allowed in a Dark & Stormy: Gosling''s Black Seal. Our house-made ginger beer has serious heat—not for the faint-hearted.\n\nSimple. Bold. Unforgettable.\n\n---\n\n🥃 **Spirit:** Dark Rum\n📊 **Strength:** Medium\n🍬 **Profile:** Spicy, sweet, bold\n💰 **$14**', NULL, 'Gosling''s trademark protects the name "Dark & Stormy" - must use their rum. House ginger beer made fresh weekly with 2lbs fresh ginger per batch. Much spicier than commercial ginger beer. Layered, not stirred—rum floats on top for visual effect. Can reduce ginger heat on request.', 7),
    
    (v_card_id, v_default_category, 'Penicillin', E'**The modern classic that cures what ails you**\n\n*Monkey Shoulder blended scotch · lemon · honey-ginger · Laphroaig float*\n\nInvented in 2005, the Penicillin has already become a modern classic. Blended scotch base with honey-ginger syrup, fresh lemon, and a float of peaty Laphroaig that hits your nose before your lips.\n\nMedicinal in name only—this is pure pleasure.\n\n---\n\n🥃 **Spirit:** Scotch Whisky\n📊 **Strength:** Medium-Strong\n🍬 **Profile:** Sweet, smoky, warming\n💰 **$16**', NULL, 'Created by Sam Ross at Milk & Honey, NYC. Honey-ginger syrup made by cooking fresh ginger in honey (1:1). Monkey Shoulder is a blend of 3 Speyside malts—smooth, approachable. Laphroaig float (1/4 oz) adds dramatic peat smoke aroma. Often ordered by scotch skeptics who then discover they love it. Great cold remedy (though not medical advice!).', 8),
    
    (v_card_id, v_default_category, 'Paper Plane', E'**Equal parts everything—perfectly balanced**\n\n*Bourbon · Aperol · Amaro Nonino · lemon*\n\nThe Paper Plane proves that equal parts can create perfect harmony. Four ingredients, each playing their role: bourbon''s warmth, Aperol''s bitter orange, Amaro Nonino''s complexity, lemon''s brightness.\n\nA 2007 creation that''s already a legend.\n\n---\n\n🥃 **Spirit:** Bourbon\n📊 **Strength:** Medium\n🍬 **Profile:** Bittersweet, complex, balanced\n💰 **$16**', NULL, 'Created by Sam Ross (same as Penicillin) at Violet Hour, Chicago. Named after M.I.A. song. Equal parts (3/4 oz each) is the key—changing ratios throws off balance. Amaro Nonino has honey and herb notes. Shaken hard with ice, strained into coupe. No garnish needed—the drink speaks for itself. Popular with amaro lovers.', 9),
    
    (v_card_id, v_default_category, 'Zero Proof: Cucumber Collins', E'**All the complexity, none of the alcohol**\n\n*Seedlip Garden · cucumber · elderflower · soda · mint*\n\nOur non-alcoholic showpiece proves you don''t need spirits to have a craft cocktail experience. Seedlip Garden provides the botanical base, while cucumber, elderflower, and mint create a refreshing, sophisticated drink.\n\nPerfect for designated drivers, expectant mothers, or anyone taking a night off.\n\n---\n\n🌿 **Non-Alcoholic**\n📊 **Strength:** Zero Proof\n🍬 **Profile:** Fresh, botanical, effervescent\n💰 **$12**', NULL, 'Seedlip is the world''s first distilled non-alcoholic spirit. Garden 108 variety has pea, hay, and herb notes. Muddled cucumber adds freshness. St-Germain-style elderflower cordial (house-made, also non-alcoholic). Soda water for effervescence. Full "Zero Proof" menu available with 6 options. Same glassware and garnish care as alcoholic drinks—no one knows the difference.', 10);

    RAISE NOTICE 'Successfully created Cocktail Bar card with ID: %', v_card_id;
END $body$;


-- Register "Cocktail Bar - Full Cards" as content template
DO $reg$
DECLARE
    v_card_id UUID;
BEGIN
    -- Find the card we just created by name and user
    SELECT id INTO v_card_id
    FROM cards 
    WHERE user_id = '91acf5ca-f78b-4acd-bc75-98b85959ce62'::UUID
      AND name = 'The Velvet Room Cocktail Bar'
    ORDER BY created_at DESC
    LIMIT 1;
    
    IF v_card_id IS NULL THEN
        RAISE WARNING 'Could not find card "The Velvet Room Cocktail Bar" for template registration';
    ELSE
        -- Register or update the template
        INSERT INTO content_templates (slug, card_id, venue_type, is_featured, is_active, sort_order)
        VALUES ('cocktail-bar-inline', v_card_id, 'restaurant', false, true, 3)
        ON CONFLICT (slug) DO UPDATE SET
            card_id = EXCLUDED.card_id,
            venue_type = EXCLUDED.venue_type,
            sort_order = EXCLUDED.sort_order,
            updated_at = NOW();
        
        RAISE NOTICE 'Registered template: cocktail-bar-inline (card_id: %)', v_card_id;
    END IF;
END $reg$;


-- ==================================================================
-- Template 4: Conference - Grouped List
-- Slug: conference-grouped | Venue: event
-- ==================================================================

-- Conference - Grouped List Mode (Digital Access)
-- Template: Tech conference with sessions by day
-- 
-- INSTRUCTIONS:
-- 1. Replace '91acf5ca-f78b-4acd-bc75-98b85959ce62' with actual user UUID
-- 2. Update image_url values with actual uploaded image URLs
-- 3. Run this SQL in Supabase SQL Editor or via psql

DO $body$
DECLARE
    v_user_id UUID := '91acf5ca-f78b-4acd-bc75-98b85959ce62'::UUID;
    v_card_id UUID;
    v_day1 UUID;
    v_day2 UUID;
    v_day3 UUID;
BEGIN
    -- Insert the card
    INSERT INTO cards (
        id, user_id, name, description, content_mode, is_grouped, group_display, billing_type,
        conversation_ai_enabled, ai_instruction, ai_knowledge_base,
        ai_welcome_general, ai_welcome_item, image_url
    ) VALUES (
        gen_random_uuid(),
        v_user_id,
        'TechSummit 2025 - Conference Guide',
        E'Welcome to **TechSummit 2025**! 🚀\n\nDecember 10-12 | Convention Center\n\nBrowse sessions by day, track, and speaker. Build your personalized schedule with our AI assistant.',
        'list',
        true,
        'expanded',
        'digital',
        true,
        'You are a helpful conference assistant. Help attendees find relevant sessions based on their interests, navigate the venue, and answer questions about speakers and topics. Be enthusiastic about tech and help people discover talks they might not have considered.',
        E'TechSummit 2025 - Annual Technology Conference\nDates: December 10-12, 2025\nVenue: Downtown Convention Center\nAttendees: 5,000 expected\n\nVenue layout:\n- Main Hall: Keynotes (capacity 3,000)\n- Room A: AI & ML Track (500)\n- Room B: Web & Mobile Track (500)\n- Room C: Cloud & DevOps Track (500)\n- Room D: Workshops (100)\n- Expo Hall: Sponsor booths\n\nWiFi: TechSummit2025 / password: innovate2025\nApp: Download TechSummit app for live schedule updates\nMeals: Breakfast 8-9am, Lunch 12:30-2pm, Coffee breaks 10:30am & 3:30pm',
        'Welcome to TechSummit 2025! I''m here to help you navigate the conference. What topics are you most interested in?',
        'Great choice! "{name}" is one of our featured sessions. Would you like to know more about the speaker or related sessions?',
        NULL
    ) RETURNING id INTO v_card_id;

    -- Day 1
    INSERT INTO content_items (id, card_id, parent_id, name, content, ai_knowledge_base, sort_order)
    VALUES (gen_random_uuid(), v_card_id, NULL, 'Day 1 - December 10', '', 
        'Day 1 focus: Opening keynote and foundational sessions. Theme: "The Future of Technology". Special events: Welcome reception 6-8pm in Expo Hall. Early bird workshop: "Intro to AI" 7:30am (pre-registration required).', 1)
    RETURNING id INTO v_day1;

    INSERT INTO content_items (card_id, parent_id, name, content, image_url, ai_knowledge_base, sort_order) VALUES
    (v_card_id, v_day1, 'Opening Keynote: The Next Decade of Tech', E'**🎤 Sarah Chen, CEO of FutureTech**\n\n📍 Main Hall | ⏰ 9:00 AM - 10:15 AM\n\nJoin us as Sarah Chen shares her vision for the next decade of technology. From AI breakthroughs to sustainable computing, discover what''s coming and how to prepare.\n\nSarah has led FutureTech to a $50B valuation and was named "Most Influential Tech Leader" by Wired Magazine.\n\n---\n\n🏷️ **Track:** Keynote\n📊 **Level:** All Levels\n⭐ **Featured Speaker**', NULL, 'Sarah Chen founded FutureTech in 2015, grew to 10,000 employees. Previous roles: VP Engineering at Google, CTO at Stripe. Stanford CS PhD focused on distributed systems. Known for accurate predictions - called the smartphone revolution in 2005. Will discuss: AI regulation, quantum computing timeline, climate tech, and workforce evolution.', 1),
    
    (v_card_id, v_day1, 'Building Production ML Systems', E'**🎤 Dr. James Liu, ML Lead at DataScale**\n\n📍 Room A | ⏰ 10:45 AM - 11:30 AM\n\nLearn the architectural patterns and best practices for deploying machine learning models at scale. James shares lessons from running ML systems serving 100M+ predictions daily.\n\n---\n\n**Topics Covered:**\n- Feature stores and real-time inference\n- Model versioning and A/B testing\n- Monitoring and debugging ML in production\n- Cost optimization strategies\n\n🏷️ **Track:** AI & Machine Learning\n📊 **Level:** Intermediate\n💻 **Slides:** Available in app after session', NULL, 'James Liu has 12 years ML experience. PhD from MIT in predictive systems. DataScale processes 50TB data daily. Session includes live demo of their monitoring dashboard. Will share their open-source feature store framework. Good for engineers moving from prototype to production ML.', 2),
    
    (v_card_id, v_day1, 'Modern Web Performance in 2025', E'**🎤 Elena Rodriguez, Performance Engineer at Shopify**\n\n📍 Room B | ⏰ 10:45 AM - 11:30 AM\n\nWeb performance directly impacts user experience and business metrics. Discover the latest techniques for building blazing-fast web applications.\n\n---\n\n**Topics Covered:**\n- Core Web Vitals optimization\n- Image and font loading strategies\n- JavaScript bundling in 2025\n- Edge computing and CDN strategies\n\n🏷️ **Track:** Web & Mobile\n📊 **Level:** Intermediate\n🔗 **Resources:** github.com/elena/webperf-2025', NULL, 'Elena improved Shopify''s LCP by 40% last year. Previously at Google Chrome team working on performance metrics. Active contributor to web standards. Will demo real Shopify optimizations. Includes hands-on exercises if you bring laptop.', 3),
    
    (v_card_id, v_day1, 'Zero Trust Security Architecture', E'**🎤 Marcus Thompson, CISO at FinanceCloud**\n\n📍 Room C | ⏰ 10:45 AM - 11:30 AM\n\nTraditional perimeter security is dead. Learn how to implement zero trust architecture to protect your cloud infrastructure in an age of sophisticated threats.\n\n---\n\n**Topics Covered:**\n- Zero trust principles and frameworks\n- Identity-based access control\n- Micro-segmentation strategies\n- Real-world implementation case studies\n\n🏷️ **Track:** Cloud & DevOps\n📊 **Level:** Advanced\n📋 **Prerequisite:** Cloud security fundamentals', NULL, 'Marcus led security for $2T in transactions at FinanceCloud. 20+ years in cybersecurity, former NSA. Will discuss actual breach attempts and how zero trust prevented them. Covers AWS, Azure, and GCP implementations. Highly rated speaker from last year.', 4);

    -- Day 2
    INSERT INTO content_items (id, card_id, parent_id, name, content, ai_knowledge_base, sort_order)
    VALUES (gen_random_uuid(), v_card_id, NULL, 'Day 2 - December 11', '', 
        'Day 2 focus: Deep dive technical sessions and hands-on workshops. Theme: "Building for Scale". Special events: Speaker dinner (invite only), Birds of a Feather sessions 5-6pm. Evening: Hackathon kickoff 7pm (48-hour event).', 2)
    RETURNING id INTO v_day2;

    INSERT INTO content_items (card_id, parent_id, name, content, image_url, ai_knowledge_base, sort_order) VALUES
    (v_card_id, v_day2, 'Keynote: Responsible AI - Building Trust', E'**🎤 Dr. Aisha Patel, Chief Ethics Officer at TechGiant**\n\n📍 Main Hall | ⏰ 9:00 AM - 10:00 AM\n\nAs AI becomes ubiquitous, how do we ensure it serves humanity? Dr. Patel shares frameworks for ethical AI development and responsible deployment.\n\nNamed one of TIME''s 100 Most Influential People in AI.\n\n---\n\n🏷️ **Track:** Keynote\n📊 **Level:** All Levels\n⭐ **Featured Speaker**', NULL, 'Dr. Patel wrote the book "AI Ethics in Practice" (bestseller). Advises EU on AI regulation. TechGiant''s ethics board has veto power on products. Will discuss: bias in hiring algorithms, AI in healthcare decisions, deepfake detection, and open-source AI governance. Q&A session follows.', 1),
    
    (v_card_id, v_day2, 'Workshop: Building Your First LLM Application', E'**🎤 David Kim, Developer Advocate at OpenAI**\n\n📍 Room D | ⏰ 10:30 AM - 12:30 PM | **2 Hours**\n\n**⚠️ Pre-registration required - Limited to 100 attendees**\n\nHands-on workshop building a real application using GPT-4 API. You''ll leave with a working chatbot deployed to production.\n\n---\n\n**What You''ll Build:**\n- Custom chatbot with RAG (Retrieval Augmented Generation)\n- Semantic search over your documents\n- Streaming responses with proper error handling\n\n**Bring:** Laptop with Python 3.9+ installed\n\n🏷️ **Track:** Workshop\n📊 **Level:** Beginner-Intermediate\n💰 **Included:** $100 OpenAI API credits', NULL, 'David Kim created the popular "LLM in a Weekend" course (50K students). 5 years at OpenAI, worked on GPT-3 and GPT-4 launches. Workshop uses LangChain framework. Prerequisites: basic Python knowledge. Assistants will be available for troubleshooting. Complete code provided in GitHub repo.', 2),
    
    (v_card_id, v_day2, 'Panel: The Future of Work in the AI Era', E'**Moderated by Tech Reporter Maya Johnson**\n\n📍 Room A | ⏰ 2:00 PM - 3:00 PM\n\nHow will AI transform jobs over the next decade? Industry leaders debate automation, augmentation, and the skills that matter.\n\n---\n\n**Panelists:**\n- Sarah Chen, CEO, FutureTech\n- Dr. Robert Garcia, Labor Economist, Stanford\n- Lisa Wang, Chief People Officer, MegaCorp\n- Tom O''Brien, Union President, Tech Workers United\n\n🏷️ **Track:** AI & Machine Learning\n📊 **Level:** All Levels\n📱 **Live Q&A:** Submit questions via app', NULL, 'Controversial topic - expect heated debate. Garcia''s research shows 30% of jobs will be transformed by 2030. Wang believes AI creates more jobs than it eliminates. O''Brien advocates for retraining programs. Audience voting on predictions built into session.', 3);

    -- Day 3
    INSERT INTO content_items (id, card_id, parent_id, name, content, ai_knowledge_base, sort_order)
    VALUES (gen_random_uuid(), v_card_id, NULL, 'Day 3 - December 12', '', 
        'Day 3 focus: Advanced topics and closing ceremonies. Theme: "Looking Ahead". Special events: Hackathon judging 10am-12pm, Award ceremony 4pm. Early departure: Luggage storage available at registration desk.', 3)
    RETURNING id INTO v_day3;

    INSERT INTO content_items (card_id, parent_id, name, content, image_url, ai_knowledge_base, sort_order) VALUES
    (v_card_id, v_day3, 'Closing Keynote: What I Wish I Knew', E'**🎤 Michael Torres, Founder of five unicorn startups**\n\n📍 Main Hall | ⏰ 2:00 PM - 3:00 PM\n\nAfter building five billion-dollar companies, Michael shares the lessons that shaped his journey—and the mistakes he hopes you''ll avoid.\n\nAn honest, unfiltered conversation about entrepreneurship in tech.\n\n---\n\n🏷️ **Track:** Keynote\n📊 **Level:** All Levels\n⭐ **Featured Speaker**', NULL, 'Michael Torres founded StreamTech (acquired by Netflix), CloudBase (IPO), DataFlow (acquired by Salesforce), RoboInvest (current), and GreenEnergy (current). Forbes 400 list. Known for brutally honest talks. Will discuss: failed companies he doesn''t mention, mental health challenges, family sacrifices, and what success really means. Standing ovation expected.', 1),
    
    (v_card_id, v_day3, 'TechSummit Awards & Closing', E'**🏆 Celebrating Excellence in Tech**\n\n📍 Main Hall | ⏰ 4:00 PM - 5:00 PM\n\nJoin us as we recognize outstanding achievements and innovations from the past year.\n\n---\n\n**Award Categories:**\n- Startup of the Year\n- Best Open Source Project\n- Diversity & Inclusion Champion\n- Breakthrough Innovation\n- Community Impact Award\n\n**Hackathon Winners:** Announced during ceremony\n\n🏷️ **Track:** All Attendees\n🍾 **Reception follows**', NULL, 'Award finalists announced via app day before. Past winners include now-famous startups like DataBridge and AIAssist. Hackathon prizes total $50,000. Closing reception 5-7pm with open bar and networking. Photo booth with speakers available. Swag bag pickup at exit.', 2);

    RAISE NOTICE 'Successfully created Conference card with ID: %', v_card_id;
END $body$;


-- Register "Conference - Grouped List" as content template
DO $reg$
DECLARE
    v_card_id UUID;
BEGIN
    -- Find the card we just created by name and user
    SELECT id INTO v_card_id
    FROM cards 
    WHERE user_id = '91acf5ca-f78b-4acd-bc75-98b85959ce62'::UUID
      AND name = 'TechForward Summit 2024'
    ORDER BY created_at DESC
    LIMIT 1;
    
    IF v_card_id IS NULL THEN
        RAISE WARNING 'Could not find card "TechForward Summit 2024" for template registration';
    ELSE
        -- Register or update the template
        INSERT INTO content_templates (slug, card_id, venue_type, is_featured, is_active, sort_order)
        VALUES ('conference-grouped', v_card_id, 'event', false, true, 4)
        ON CONFLICT (slug) DO UPDATE SET
            card_id = EXCLUDED.card_id,
            venue_type = EXCLUDED.venue_type,
            sort_order = EXCLUDED.sort_order,
            updated_at = NOW();
        
        RAISE NOTICE 'Registered template: conference-grouped (card_id: %)', v_card_id;
    END IF;
END $reg$;


-- ==================================================================
-- Template 5: Fashion Show - Grouped List
-- Slug: fashion-show-grouped | Venue: event
-- ==================================================================

-- Fashion Show - Grouped List Mode (Digital Access)
-- Template: Fashion show lookbook with looks by segment
-- 
-- INSTRUCTIONS:
-- 1. Replace '91acf5ca-f78b-4acd-bc75-98b85959ce62' with actual user UUID
-- 2. Update image_url values with actual uploaded image URLs
-- 3. Run this SQL in Supabase SQL Editor or via psql

DO $body$
DECLARE
    v_user_id UUID := '91acf5ca-f78b-4acd-bc75-98b85959ce62'::UUID;
    v_card_id UUID;
    v_seg_cocoon UUID;
    v_seg_emergence UUID;
    v_seg_flight UUID;
    v_seg_finale UUID;
BEGIN
    -- Insert the card
    INSERT INTO cards (
        id, user_id, name, description, content_mode, is_grouped, group_display, billing_type,
        conversation_ai_enabled, ai_instruction, ai_knowledge_base,
        ai_welcome_general, ai_welcome_item, image_url
    ) VALUES (
        gen_random_uuid(),
        v_user_id,
        'MAISON ÉLISE - Spring/Summer 2025',
        E'**Spring/Summer 2025 Collection**\n\n*"Metamorphosis"*\n\nA journey through transformation, rebirth, and the beauty of change.\n\nParis Fashion Week | March 2025',
        'list',
        true,
        'expanded',
        'digital',
        true,
        'You are the creative director''s assistant at a haute couture fashion house. Share the artistic vision, craftsmanship details, and inspiration behind each look. Speak with sophistication about fabrics, techniques, and fashion history. Be passionate about the creative process while remaining approachable.',
        E'MAISON ÉLISE - Spring/Summer 2025 "Metamorphosis" Collection\nCreative Director: Élise Dubois\n\nShow Details:\n- Date: March 3, 2025, 8:00 PM\n- Venue: Palais de Tokyo, Paris\n- Looks: 45 total across 4 segments\n- Models: 32\n- Duration: 18 minutes\n\nCollection Inspiration:\nThe lifecycle of the butterfly—from cocoon to flight. Explores themes of transformation, vulnerability, and emerging beauty. Influenced by Art Nouveau, Japanese origami, and organic architecture.\n\nKey Materials:\n- Sustainable silk from Italian mills\n- Recycled ocean plastics transformed into sequins\n- Hand-painted organza\n- 3D-printed biodegradable elements\n\nAtelier: 47 artisans, 12,000+ hours of handwork',
        'Welcome to Maison Élise. I''m thrilled to guide you through our Spring/Summer 2025 collection. What would you like to explore?',
        'Ah, Look {name} - this piece is extraordinary. Let me share the story behind it.',
        NULL
    ) RETURNING id INTO v_card_id;

    -- Segment 1: Cocoon
    INSERT INTO content_items (id, card_id, parent_id, name, content, ai_knowledge_base, sort_order)
    VALUES (gen_random_uuid(), v_card_id, NULL, 'I. Cocoon', '', 
        'Opening segment represents the protective cocoon phase. Enveloping silhouettes, wrapped constructions, muted chrysalis tones. Models emerge from darkened backstage into soft spotlight. Music: ambient electronic by Ólafur Arnalds. 8 looks, 4 minutes.', 1)
    RETURNING id INTO v_seg_cocoon;

    INSERT INTO content_items (card_id, parent_id, name, content, image_url, ai_knowledge_base, sort_order) VALUES
    (v_card_id, v_seg_cocoon, 'Look 1', E'**Opening Look**\n\n*The Awakening*\n\n---\n\nSculptural cocoon coat in pearl-grey duchesse satin with internal boning creating organic, pod-like silhouette. Underneath: nude mesh bodysuit with hand-sewn crystal "dew drops."\n\n**Fabrication:**\n- Duchesse satin: 15 meters\n- Hand-sewn Swarovski crystals: 2,847\n- Construction hours: 340\n\n**Styling:**\n- Hair: Slicked back, wet look\n- Makeup: Dewy, no-makeup makeup\n- Shoes: Custom nude platforms (hidden)', NULL, 'Opening look sets the tone for entire collection. Élise wanted something that felt "between sleeping and waking." The coat structure was technically challenging - 4 muslin prototypes before final. Crystals placed to catch light as model moves. Model: Adut Akech, specifically requested by Élise for the opening.', 1),
    
    (v_card_id, v_seg_cocoon, 'Look 2', E'**Wrapped Silhouette**\n\n*Suspended*\n\n---\n\nAsymmetric draped gown in layers of silk organza, ranging from ivory to soft blush. Origami-inspired pleating creates sculptural dimension at shoulder and hip.\n\n**Fabrication:**\n- Silk organza layers: 7\n- Hand-pleating hours: 120\n- Invisible boning structure\n\n**Styling:**\n- Hair: Low chignon with silk ribbon\n- Makeup: Soft peach tones\n- Jewelry: Single pearl ear cuff', NULL, 'Inspired by paper wasp nests - those incredible organic structures. Pleating technique developed specifically for this collection, now called "Élise pleat" by the atelier. Each layer is a slightly different shade - creates depth and movement. Takes 2 fittings per garment to get drape exactly right.', 2),
    
    (v_card_id, v_seg_cocoon, 'Look 5', E'**Statement Outerwear**\n\n*Protection*\n\n---\n\nOversized coat in cream double-faced cashmere with cocoon-shaped sleeves. Interior reveals hand-painted butterfly wing motif in watercolor technique on silk lining.\n\n**Fabrication:**\n- Double-faced cashmere from Loro Piana\n- Hand-painted silk lining: 40 hours\n- Horn buttons from sustainable source\n\n**Styling:**\n- Worn over: Nude column dress\n- Hair: Loose, natural texture\n- Bag: Cocoon-shaped minaudière', NULL, 'The "hidden butterfly" concept - exterior is minimal, interior reveals true beauty. Each coat lining is unique, hand-painted by atelier artist Marie Lefevre. Cashmere is sustainably sourced, we can trace to specific Italian farms. This piece has already received pre-orders from 12 clients.', 3);

    -- Segment 2: Emergence
    INSERT INTO content_items (id, card_id, parent_id, name, content, ai_knowledge_base, sort_order)
    VALUES (gen_random_uuid(), v_card_id, NULL, 'II. Emergence', '', 
        'Second segment represents emergence from the cocoon - vulnerability, first moments of transformation. More body-conscious silhouettes, translucent fabrics, delicate construction. Colors shift to soft pastels. Music: string quartet. 12 looks, 5 minutes.', 2)
    RETURNING id INTO v_seg_emergence;

    INSERT INTO content_items (card_id, parent_id, name, content, image_url, ai_knowledge_base, sort_order) VALUES
    (v_card_id, v_seg_emergence, 'Look 12', E'**Sheer Layering**\n\n*Vulnerability*\n\n---\n\nFloor-length gown in 12 layers of hand-dyed silk tulle, gradient from pale pink to deep rose. Strategic placement of embroidered butterfly wing fragments for coverage.\n\n**Fabrication:**\n- Silk tulle layers: 12 (each hand-dyed)\n- 3D embroidered wing elements: 28\n- Total embroidery hours: 180\n\n**Styling:**\n- Hair: Romantic waves\n- Makeup: Rose-tinted glass skin\n- Shoes: Crystal-encrusted sandals', NULL, 'Élise wanted to explore "protective vulnerability" - the contrast between being exposed yet beautiful. Each tulle layer dyed separately then layered for gradient effect. Butterfly fragments are 3D embroidery technique from our Lesage atelier partnership. This look took 3 weeks to complete. Expected to be red carpet favorite.', 1),
    
    (v_card_id, v_seg_emergence, 'Look 15', E'**Daywear Interpretation**\n\n*First Flight*\n\n---\n\nTailored suit in pale lavender wool crepe with exaggerated shoulder and nipped waist. Jacket features laser-cut wing pattern revealing silk charmeuse lining.\n\n**Fabrication:**\n- Wool crepe from Dormeuil\n- Laser-cut wing pattern: 847 cuts\n- Silk charmeuse contrast lining\n\n**Styling:**\n- Worn with: Silk camisole\n- Hair: Sleek ponytail\n- Shoes: Pointed-toe pumps\n- Bag: Structured top-handle', NULL, 'Élise believes haute couture should include wearable pieces. This suit is designed for the client who wants art in her everyday. Laser-cutting technology combined with traditional tailoring. The wing pattern took 3 months to perfect - cutting too deep weakens structure, too shallow doesn''t show. Commercial department creating ready-to-wear version.', 2);

    -- Segment 3: Flight
    INSERT INTO content_items (id, card_id, parent_id, name, content, ai_knowledge_base, sort_order)
    VALUES (gen_random_uuid(), v_card_id, NULL, 'III. Flight', '', 
        'Third segment celebrates full transformation - joy, freedom, color. Movement-focused designs, bold butterfly colors, dramatic silhouettes. Music: orchestral crescendo. 15 looks, 6 minutes. Includes the collection''s most photographed pieces.', 3)
    RETURNING id INTO v_seg_flight;

    INSERT INTO content_items (card_id, parent_id, name, content, image_url, ai_knowledge_base, sort_order) VALUES
    (v_card_id, v_seg_flight, 'Look 25', E'**Dramatic Evening**\n\n*Monarch*\n\n---\n\nStrapless ballgown with hand-painted monarch butterfly wing print on silk faille. Structured bodice with boning, full skirt with horsehair hem. 25 meters of fabric.\n\n**Fabrication:**\n- Silk faille: 25 meters\n- Hand-painting: 200 hours\n- Internal structure: Corsetry and crinolines\n\n**Styling:**\n- Hair: Voluminous updo\n- Makeup: Dramatic orange-black eye\n- Jewelry: Vintage Cartier butterfly brooch', NULL, 'The "hero" look of the collection - every show needs one. Hand-painting by our textile artist took 200 hours - each scale of the butterfly wing individually painted. Monarch chosen for its symbolism of migration and transformation. The vintage Cartier brooch belongs to Élise personally, from her grandmother.', 1),
    
    (v_card_id, v_seg_flight, 'Look 28', E'**Sculptural Drama**\n\n*Wingspan*\n\n---\n\nArchitectural gown with 3D-printed wing structure emerging from back. Base gown in black silk crepe, wings in iridescent recycled ocean plastic. Wings span 2 meters.\n\n**Fabrication:**\n- 3D-printed wings: Biodegradable PLA\n- Recycled ocean plastic sequins: 5,000+\n- Wingspan: 2 meters\n- Engineering collaboration with MIT Media Lab\n\n**Styling:**\n- Hair: Severe bun\n- Makeup: Graphic black liner\n- Shoes: Platform boots (for height/balance)', NULL, 'Our sustainability statement piece. Collaborated with MIT Media Lab on the wing structure - had to be light enough to wear yet dramatic on runway. Each sequin is made from recycled ocean plastic collected from Pacific cleanup. Model trained for 2 days to walk with wings. Wings detach - gown wearable without them.', 2),
    
    (v_card_id, v_seg_flight, 'Look 32', E'**Red Carpet Statement**\n\n*Chrysalis to Flight*\n\n---\n\nColor-gradient gown transitioning from cocoon grey at hem to vibrant butterfly blue at bodice. 3D fabric manipulation creates emerging wing effect at shoulders.\n\n**Fabrication:**\n- Gradient-dyed silk gazar\n- 3D fabric origami: 80 hours\n- Crystal dewdrops: 1,200\n\n**Styling:**\n- Hair: Wet-look waves\n- Makeup: Blue-toned highlight\n- Jewelry: Statement ear cuff', NULL, 'This gown tells the entire collection story in one piece - the gradient represents the metamorphosis journey. Custom dye process using natural indigo. The 3D shoulder elements were inspired by butterfly emerging from chrysalis. Already requested by 3 A-list actresses for upcoming awards season.', 3);

    -- Segment 4: Finale
    INSERT INTO content_items (id, card_id, parent_id, name, content, ai_knowledge_base, sort_order)
    VALUES (gen_random_uuid(), v_card_id, NULL, 'IV. Finale', '', 
        'Closing segment: the bride and finale looks. Ultimate transformation and celebration. All-white segment, maximum drama. Music: silence then applause. 10 looks including bride, 3 minutes. Designer bow after bride.', 4)
    RETURNING id INTO v_seg_finale;

    INSERT INTO content_items (card_id, parent_id, name, content, image_url, ai_knowledge_base, sort_order) VALUES
    (v_card_id, v_seg_finale, 'Look 42 - Bride', E'**Bridal**\n\n*Eternal Metamorphosis*\n\n---\n\nBridal gown in ivory silk mikado with detachable cape featuring 3D hand-sculpted butterfly garden. 50 individual silk butterflies, each unique, appear to be taking flight from the train.\n\n**Fabrication:**\n- Silk mikado gown with boning\n- Detachable cape: 4 meters\n- Hand-sculpted silk butterflies: 50\n- Total creation hours: 800\n\n**Styling:**\n- Hair: Natural, flowing\n- Makeup: Fresh, glowing\n- Veil: Tulle with scattered crystals\n- Shoes: Ivory satin platforms', NULL, 'The bridal look is always the most anticipated. Each butterfly is hand-sculpted from silk, wired to "flutter" as the model walks. 50 unique butterflies - no two alike. Concept: bride as the ultimate transformation, surrounded by fellow creatures in flight. Cape detaches for reception. This gown will be made-to-order for clients.', 1),
    
    (v_card_id, v_seg_finale, 'Look 45 - Finale', E'**Designer Bow**\n\n*Élise Dubois*\n\n---\n\nCreative Director Élise Dubois takes her bow accompanied by the full cast of models in the finale walk.\n\nÉlise wears: Black silk shirt, tailored trousers, bare feet—her signature bow look. A single monarch butterfly pin on her collar.\n\n---\n\n🦋 *"Fashion is metamorphosis. We are all becoming."*\n— Élise Dubois', NULL, 'Élise always takes her bow barefoot - she says it keeps her grounded after months of work. The monarch pin was a gift from her first atelier teacher. This is her 15th collection for the house. Standing ovation lasted 3 minutes. Anna Wintour, Carine Roitfeld, and Edward Enninful all in attendance.', 2);

    RAISE NOTICE 'Successfully created Fashion Show card with ID: %', v_card_id;
END $body$;


-- Register "Fashion Show - Grouped List" as content template
DO $reg$
DECLARE
    v_card_id UUID;
BEGIN
    -- Find the card we just created by name and user
    SELECT id INTO v_card_id
    FROM cards 
    WHERE user_id = '91acf5ca-f78b-4acd-bc75-98b85959ce62'::UUID
      AND name = 'Avant-Garde: Spring/Summer 2025 Collection'
    ORDER BY created_at DESC
    LIMIT 1;
    
    IF v_card_id IS NULL THEN
        RAISE WARNING 'Could not find card "Avant-Garde: Spring/Summer 2025 Collection" for template registration';
    ELSE
        -- Register or update the template
        INSERT INTO content_templates (slug, card_id, venue_type, is_featured, is_active, sort_order)
        VALUES ('fashion-show-grouped', v_card_id, 'event', false, true, 5)
        ON CONFLICT (slug) DO UPDATE SET
            card_id = EXCLUDED.card_id,
            venue_type = EXCLUDED.venue_type,
            sort_order = EXCLUDED.sort_order,
            updated_at = NOW();
        
        RAISE NOTICE 'Registered template: fashion-show-grouped (card_id: %)', v_card_id;
    END IF;
END $reg$;


-- ==================================================================
-- Template 6: Fine Dining - Grouped List
-- Slug: fine-dining-grouped | Venue: restaurant
-- ==================================================================

-- Fine Dining Restaurant - Grouped List Mode (Digital Access)
-- Template: Tasting menu organized by course
-- 
-- INSTRUCTIONS:
-- 1. Replace '91acf5ca-f78b-4acd-bc75-98b85959ce62' with actual user UUID
-- 2. Update image_url values with actual uploaded image URLs
-- 3. Run this SQL in Supabase SQL Editor or via psql

DO $body$
DECLARE
    v_user_id UUID := '91acf5ca-f78b-4acd-bc75-98b85959ce62'::UUID;
    v_card_id UUID;
    v_cat_amuse UUID;
    v_cat_first UUID;
    v_cat_second UUID;
    v_cat_fish UUID;
    v_cat_meat UUID;
    v_cat_predessert UUID;
    v_cat_dessert UUID;
    v_cat_petitfours UUID;
BEGIN
    -- Insert the card
    INSERT INTO cards (
        id, user_id, name, description, content_mode, is_grouped, group_display, billing_type,
        conversation_ai_enabled, ai_instruction, ai_knowledge_base,
        ai_welcome_general, ai_welcome_item, daily_scan_limit
    ) VALUES (
        gen_random_uuid(),
        v_user_id,
        'AURUM - Seasonal Tasting Menu',
        E'Welcome to **AURUM**, where culinary artistry meets seasonal excellence.\n\nOur 8-course tasting menu celebrates the finest ingredients of the season, crafted by Executive Chef Isabella Chen and her team.\n\n🍷 Wine pairing available · 🌿 Dietary modifications upon request',
        'list',
        true,
        'expanded',
        'digital',
        true,
        'You are a refined sommelier and maitre d'' at an upscale restaurant. Speak elegantly but warmly about dishes, ingredients, and wine pairings. Be helpful with dietary restrictions and allergies. Recommend dishes based on guest preferences. Never be pretentious—guests should feel welcomed, not judged.',
        E'AURUM Restaurant - 2 Michelin Stars\nExecutive Chef: Isabella Chen (trained at Noma, Eleven Madison Park)\nCuisine: Modern European with Asian influences\n\nDietary accommodations: Vegetarian tasting menu available, gluten-free modifications possible for most courses, please inform staff of allergies.\n\nWine program: 800+ labels, emphasis on biodynamic and natural wines.\nSommelier: Marcus Thompson, Master Sommelier\n\nDress code: Smart casual (jackets not required)\nReservations: Required, 2-3 weeks in advance recommended\n\nAll produce sourced within 100 miles. Sustainable seafood certified.\nKitchen uses only pasture-raised meats and heritage breeds.',
        'Welcome to AURUM. I''m here to guide you through our tasting menu and help with any questions about dishes, ingredients, or wine pairings.',
        'Excellent choice. Let me tell you more about our "{name}" and suggest the perfect wine pairing.',
        500
    ) RETURNING id INTO v_card_id;

    -- Course 1: Amuse-Bouche
    INSERT INTO content_items (id, card_id, parent_id, name, content, ai_knowledge_base, sort_order)
    VALUES (gen_random_uuid(), v_card_id, NULL, 'Amuse-Bouche', '', 
        'The amuse-bouche ("mouth amuser") is a complimentary bite to awaken the palate. Changes daily based on chef''s inspiration. Not listed on printed menus to maintain element of surprise.', 1)
    RETURNING id INTO v_cat_amuse;

    INSERT INTO content_items (card_id, parent_id, name, content, image_url, ai_knowledge_base, sort_order) VALUES
    (v_card_id, v_cat_amuse, 'Chef''s Daily Inspiration', E'**A gift from the kitchen**\n\nToday''s amuse-bouche features a single bite that encapsulates our culinary philosophy: precision, seasonality, and surprise.\n\n*Changes daily—ask your server about today''s creation*\n\n---\n\n🌿 Always includes a vegetarian option\n⚠️ Please inform us of any allergies', NULL, 'Current rotation includes: black truffle gougère, hamachi tartare on rice cracker, beet meringue with goat cheese. Served on custom ceramic spoons by local artist Mia Santos. Designed to be consumed in one bite. Sets the tone for the entire meal.', 1);

    -- Course 2: First Course
    INSERT INTO content_items (id, card_id, parent_id, name, content, ai_knowledge_base, sort_order)
    VALUES (gen_random_uuid(), v_card_id, NULL, 'First Course', '', 
        'First courses are designed to be light and awakening, featuring delicate flavors and often raw or lightly cooked preparations. Portion size: 3-4 bites.', 2)
    RETURNING id INTO v_cat_first;

    INSERT INTO content_items (card_id, parent_id, name, content, image_url, ai_knowledge_base, sort_order) VALUES
    (v_card_id, v_cat_first, 'Hokkaido Scallop', E'**Diver scallop · yuzu kosho · apple · fennel**\n\nHand-harvested Hokkaido scallop served raw, dressed with house-made yuzu kosho and accompanied by paper-thin Granny Smith apple and shaved baby fennel.\n\nThe natural sweetness of the scallop plays against the citrus heat of the yuzu kosho, while the apple adds brightness and crunch.\n\n---\n\n🍷 **Wine Pairing:** Domaine Leflaive Puligny-Montrachet 2020\n🌿 Gluten-free', NULL, 'Scallops flown in twice weekly from Hokkaido, Japan. Only the adductor muscle used—coral reserved for staff meal. Yuzu kosho made in-house with fresh yuzu from California. Apple sliced to order to prevent oxidation. Can substitute with hamachi for scallop allergy.', 1),
    
    (v_card_id, v_cat_first, 'Heirloom Tomato', E'**Cherokee purple · burrata · basil · aged balsamic**\n\nThe peak of summer captured in a dish. Cherokee Purple heirloom tomatoes from Oak Hill Farm paired with creamy burrata, purple basil, and 25-year aged balsamic vinegar.\n\nA celebration of simplicity—when ingredients are this perfect, restraint becomes the highest technique.\n\n---\n\n🍷 **Wine Pairing:** Domaine Tempier Bandol Rosé 2022\n🌿 Vegetarian · Gluten-free', NULL, 'Cherokee Purple tomatoes only available July-September. Burrata made fresh daily by local creamery. Balsamic from single producer in Modena, Italy—we buy their entire annual allocation. Purple basil grown in restaurant''s rooftop garden. Can omit burrata for vegan version.', 2);

    -- Course 3: Second Course
    INSERT INTO content_items (id, card_id, parent_id, name, content, ai_knowledge_base, sort_order)
    VALUES (gen_random_uuid(), v_card_id, NULL, 'Second Course', '', 
        'Second courses introduce more complexity and often feature our signature techniques. Typically includes a sauce or reduction. Portion size: 4-5 bites.', 3)
    RETURNING id INTO v_cat_second;

    INSERT INTO content_items (card_id, parent_id, name, content, image_url, ai_knowledge_base, sort_order) VALUES
    (v_card_id, v_cat_second, 'Duck Liver Parfait', E'**Foie gras · Sauternes gelée · toasted brioche · smoked salt**\n\nSilky duck liver parfait with a delicate Sauternes gelée, served with house-made brioche toast. The parfait is torchon-style, wrapped and poached for 48 hours to achieve its impossibly smooth texture.\n\n---\n\n🍷 **Wine Pairing:** Château d''Yquem 2015 (1oz pour)\n⚠️ Contains: Dairy, Gluten, Eggs', NULL, 'Foie gras from Hudson Valley Foie Gras, only producer using humane gavage-free methods. Sauternes gelée uses same wine as pairing. Brioche recipe from Chef Isabella''s grandmother. Smoked salt made in-house using applewood. Can substitute with chicken liver for cost-conscious guests.', 1),
    
    (v_card_id, v_cat_second, 'Roasted Cauliflower', E'**Whole-roasted · almond · golden raisin · brown butter**\n\nA whole baby cauliflower roasted until deeply caramelized, served with marcona almond cream, golden raisins plumped in verjus, and nutty brown butter.\n\nOur vegetarian guests'' favorite—proof that vegetables can be the star of any table.\n\n---\n\n🍷 **Wine Pairing:** Kistler Chardonnay 2021\n🌿 Vegetarian · Can be made vegan', NULL, 'Cauliflower roasted at 500°F for 45 minutes until charred exterior and creamy interior. Almond cream uses marcona almonds from Spain. Vegan version substitutes olive oil for brown butter. One of most Instagrammed dishes. Staff favorite for family meal.', 2);

    -- Course 4: Fish Course
    INSERT INTO content_items (id, card_id, parent_id, name, content, ai_knowledge_base, sort_order)
    VALUES (gen_random_uuid(), v_card_id, NULL, 'Fish Course', '', 
        'Our fish course showcases sustainable seafood prepared with precision. All seafood is Monterey Bay Aquarium Seafood Watch approved. Fish changes based on daily catch and sustainability.', 4)
    RETURNING id INTO v_cat_fish;

    INSERT INTO content_items (card_id, parent_id, name, content, image_url, ai_knowledge_base, sort_order) VALUES
    (v_card_id, v_cat_fish, 'Black Cod', E'**Miso-glazed · bok choy · shiitake · dashi**\n\nAlaskan black cod marinated for 72 hours in our house white miso blend, then broiled until caramelized. Served with baby bok choy, shiitake mushrooms, and a light dashi broth.\n\nInspired by the legendary Nobu dish, refined with our own techniques.\n\n---\n\n🍷 **Wine Pairing:** Trimbach Riesling Grand Cru 2019\n🌿 Gluten-free with tamari substitution', NULL, 'Black cod (sablefish) from sustainable Alaskan fishery. Miso blend includes white miso, sake, mirin, and a touch of yuzu. 72-hour marinade breaks down proteins for buttery texture. Dashi made fresh daily with kombu and bonito. Can substitute with halibut for different texture.', 1);

    -- Course 5: Meat Course
    INSERT INTO content_items (id, card_id, parent_id, name, content, ai_knowledge_base, sort_order)
    VALUES (gen_random_uuid(), v_card_id, NULL, 'Meat Course', '', 
        'Our meat courses feature heritage breeds and dry-aged cuts. All beef is from grass-fed, pasture-raised cattle. We work directly with three family farms within 100 miles.', 5)
    RETURNING id INTO v_cat_meat;

    INSERT INTO content_items (card_id, parent_id, name, content, image_url, ai_knowledge_base, sort_order) VALUES
    (v_card_id, v_cat_meat, 'Wagyu Ribeye', E'**A5 Miyazaki · bone marrow · porcini · red wine jus**\n\nJapanese A5 Wagyu from Miyazaki Prefecture, seared tableside and served with roasted bone marrow, wild porcini mushrooms, and an intense red wine reduction.\n\nThe pinnacle of beef—intricately marbled, impossibly tender, served in 2oz portions to appreciate without overwhelming.\n\n---\n\n🍷 **Wine Pairing:** Château Margaux 2010\n⚠️ Supplement: +$85', NULL, 'A5 is highest grade—only 3% of Japanese beef qualifies. Miyazaki has won "Wagyu Olympics" multiple times. We receive 2 ribeyes per week. Served at exactly medium-rare (130°F internal). Bone marrow from grass-fed cattle. Red wine jus uses same wine as pairing.', 1),
    
    (v_card_id, v_cat_meat, 'Berkshire Pork', E'**Heritage pork belly · apple mostarda · crispy sage**\n\nSlow-braised Berkshire pork belly from Newman Farm, finished with a honey glaze and served with spiced apple mostarda and fried sage.\n\nBerkshire pigs are the "Wagyu of pork"—rich, succulent, and incomparably flavorful.\n\n---\n\n🍷 **Wine Pairing:** Domaine de la Côte Pinot Noir 2020\n🌿 Gluten-free', NULL, 'Berkshire (Kurobuta) pigs raised by Newman Farm in Missouri. Heritage breed with higher intramuscular fat. Braised for 8 hours at 275°F. Apple mostarda uses local heirloom apples. Sage grown in rooftop garden. Popular alternative to beef course.', 2);

    -- Course 6: Pre-Dessert
    INSERT INTO content_items (id, card_id, parent_id, name, content, ai_knowledge_base, sort_order)
    VALUES (gen_random_uuid(), v_card_id, NULL, 'Pre-Dessert', '', 
        'Pre-dessert cleanses the palate between savory and sweet courses. Typically features citrus, herbs, or light dairy. Serves as a gentle transition.', 6)
    RETURNING id INTO v_cat_predessert;

    INSERT INTO content_items (card_id, parent_id, name, content, image_url, ai_knowledge_base, sort_order) VALUES
    (v_card_id, v_cat_predessert, 'Lemon Verbena Sorbet', E'**Lemon verbena · champagne · elderflower**\n\nA refreshing interlude: lemon verbena sorbet with a splash of vintage Champagne and elderflower essence.\n\nDesigned to cleanse and prepare the palate for our final sweet courses.\n\n---\n\n🌿 Vegan · Gluten-free', NULL, 'Lemon verbena grown in rooftop garden. Sorbet churned to order. Champagne added tableside (Krug Grande Cuvée). Elderflower from St-Germain. Can omit Champagne for non-alcoholic version. Presented in frozen ceramic bowl.', 1);

    -- Course 7: Dessert
    INSERT INTO content_items (id, card_id, parent_id, name, content, ai_knowledge_base, sort_order)
    VALUES (gen_random_uuid(), v_card_id, NULL, 'Dessert', '', 
        'Desserts are created by Pastry Chef David Kim (James Beard Award semifinalist 2023). Focus on balanced sweetness and seasonal ingredients. All desserts pair with our dessert wine or house-made digestif selection.', 7)
    RETURNING id INTO v_cat_dessert;

    INSERT INTO content_items (card_id, parent_id, name, content, image_url, ai_knowledge_base, sort_order) VALUES
    (v_card_id, v_cat_dessert, 'Dark Chocolate Soufflé', E'**Valrhona dark chocolate · crème fraîche · fleur de sel**\n\nOur signature dessert: a perfectly risen soufflé made with 70% Valrhona dark chocolate, served with house-made crème fraîche and a whisper of fleur de sel.\n\n*Requires 20 minutes preparation—ordered at start of meal*\n\n---\n\n🍷 **Pairing:** Banyuls Grand Cru 2018\n⚠️ Contains: Eggs, Dairy, Gluten', NULL, 'Valrhona Guanaja 70% chocolate from Venezuela beans. Soufflé must be ordered at meal start—precisely timed to rise as guests finish previous course. Crème fraîche cultured in-house for 48 hours. Fleur de sel from Guérande, France. Most popular dessert by far.', 1),
    
    (v_card_id, v_cat_dessert, 'Seasonal Fruit Tart', E'**Stone fruit · vanilla pastry cream · almond frangipane**\n\nA delicate tart showcasing the best stone fruits of the season: white peaches, apricots, and cherries atop silky vanilla pastry cream and almond frangipane.\n\nLighter option for those saving room for our petit fours.\n\n---\n\n🍷 **Pairing:** Moscato d''Asti 2022\n⚠️ Contains: Eggs, Dairy, Gluten, Nuts', NULL, 'Fruits change weekly during summer season. Winter version uses poached pears and citrus. Pastry cream uses Madagascar vanilla beans. Frangipane made with marcona almonds. Tart shell is pâte sucrée, blind-baked to perfect crispness. Can make nut-free version.', 2);

    -- Course 8: Petit Fours
    INSERT INTO content_items (id, card_id, parent_id, name, content, ai_knowledge_base, sort_order)
    VALUES (gen_random_uuid(), v_card_id, NULL, 'Petit Fours', '', 
        'Petit fours ("small oven") are bite-sized confections served with coffee or digestifs. Included with tasting menu. Selection changes weekly.', 8)
    RETURNING id INTO v_cat_petitfours;

    INSERT INTO content_items (card_id, parent_id, name, content, image_url, ai_knowledge_base, sort_order) VALUES
    (v_card_id, v_cat_petitfours, 'Chef''s Selection', E'**Handcrafted confections to conclude your meal**\n\nA selection of house-made petit fours served with coffee or tea:\n\n- Dark chocolate truffles with sea salt\n- Lavender shortbread\n- Candied citrus peel\n- Housemade marshmallow\n\n---\n\n☕ **Recommended:** Double espresso or chamomile tea\n🥃 **Digestif:** House limoncello or aged grappa', NULL, 'All petit fours made in-house daily. Truffles use same Valrhona chocolate as soufflé. Lavender from Provence. Citrus peel candied over 3 days. Marshmallow flavored with rose water. Coffee is single-origin from Intelligentsia. Complimentary with tasting menu.', 1);

    RAISE NOTICE 'Successfully created Fine Dining card with ID: %', v_card_id;
END $body$;


-- Register "Fine Dining - Grouped List" as content template
DO $reg$
DECLARE
    v_card_id UUID;
BEGIN
    -- Find the card we just created by name and user
    SELECT id INTO v_card_id
    FROM cards 
    WHERE user_id = '91acf5ca-f78b-4acd-bc75-98b85959ce62'::UUID
      AND name = 'Le Jardin: A Culinary Journey'
    ORDER BY created_at DESC
    LIMIT 1;
    
    IF v_card_id IS NULL THEN
        RAISE WARNING 'Could not find card "Le Jardin: A Culinary Journey" for template registration';
    ELSE
        -- Register or update the template
        INSERT INTO content_templates (slug, card_id, venue_type, is_featured, is_active, sort_order)
        VALUES ('fine-dining-grouped', v_card_id, 'restaurant', false, true, 6)
        ON CONFLICT (slug) DO UPDATE SET
            card_id = EXCLUDED.card_id,
            venue_type = EXCLUDED.venue_type,
            sort_order = EXCLUDED.sort_order,
            updated_at = NOW();
        
        RAISE NOTICE 'Registered template: fine-dining-grouped (card_id: %)', v_card_id;
    END IF;
END $reg$;


-- ==================================================================
-- Template 7: Football Match - Single Page
-- Slug: football-match-single | Venue: event
-- ==================================================================

-- Football Match - Single Page Mode (Digital Access)
-- Template: Sports event single-page guide
-- 
-- INSTRUCTIONS:
-- 1. Replace '91acf5ca-f78b-4acd-bc75-98b85959ce62' with actual user UUID
-- 2. Update image_url values with actual uploaded image URLs
-- 3. Run this SQL in Supabase SQL Editor or via psql

DO $body$
DECLARE
    v_user_id UUID := '91acf5ca-f78b-4acd-bc75-98b85959ce62'::UUID;
    v_card_id UUID;
    v_default_category UUID;
BEGIN
    -- Insert the card
    INSERT INTO cards (
        id, user_id, name, description, content_mode, is_grouped, group_display, billing_type,
        conversation_ai_enabled, ai_instruction, ai_knowledge_base,
        ai_welcome_general, ai_welcome_item, image_url
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
        'Welcome to City Stadium! I''m here to help you have an amazing match day. Ask me about the teams, stadium facilities, or anything else!',
        'Let me help you with all the match day information. What would you like to know?',
        NULL
    ) RETURNING id INTO v_card_id;

    -- Create default category (hidden in flat mode, holds all content items)
    INSERT INTO content_items (id, card_id, parent_id, name, content, ai_knowledge_base, sort_order)
    VALUES (gen_random_uuid(), v_card_id, NULL, 'General', '', '', 1)
    RETURNING id INTO v_default_category;

    -- Insert single content item (layer 2 under default category)
    INSERT INTO content_items (card_id, parent_id, name, content, image_url, ai_knowledge_base, sort_order) VALUES
    (v_card_id, v_default_category, 'Match Day Guide', E'# City FC vs Manchester United\n## Premier League · Matchday 15\n\n---\n\n## ⏰ Schedule\n\n| Time | Event |\n|------|-------|\n| 1:00 PM | Gates open |\n| 1:30 PM | Fan Zone entertainment begins |\n| 2:30 PM | Teams warm-up |\n| 2:45 PM | Team announcements |\n| 2:55 PM | National anthem |\n| **3:00 PM** | **KICKOFF** |\n| 3:45 PM | Half-time (15 minutes) |\n| ~4:45 PM | Full-time |\n\n---\n\n## 🏟️ Stadium Map\n\n**Your Section:** Check your ticket for block, row, and seat number\n\n### Entry Gates\n- **North Gate** → Blocks 101-120 (Home supporters)\n- **South Gate** → Blocks 201-220 (Away supporters)\n- **East Gate** → Blocks 301-340\n- **West Gate** → Blocks 401-440\n\n### Key Locations\n- 🍔 **Food & Drink** → Every concourse level\n- 🚻 **Restrooms** → Behind every section\n- 🏥 **First Aid** → Gates N1, S1, E1, W1\n- 👕 **Team Shop** → North Concourse\n- 📸 **Photo Opportunity** → West Concourse (giant shirt display)\n\n---\n\n## ⚽ Team Lineups\n\n### City FC (Home - Blue)\n\n**Manager:** Antonio García\n\n| # | Position | Player |\n|---|----------|--------|\n| 1 | GK | David Martinez |\n| 2 | RB | James Wilson |\n| 5 | CB | Michael Brown |\n| 6 | CB | Carlos Silva |\n| 3 | LB | Ahmed Hassan |\n| 8 | CM | Thomas Mueller |\n| 10 | CM | Paolo Rossi |\n| 7 | RW | Marcus Sterling |\n| 11 | LW | Yuki Tanaka |\n| 9 | ST | **Emmanuel Okonkwo** (C) |\n| 20 | ST | Lucas Fernandez |\n\n**Bench:** 13-Rodriguez, 4-Chen, 14-O''Brien, 16-Kowalski, 17-Nguyen, 19-Anderson, 21-Petrov\n\n### Manchester United (Away - Red)\n\n**Manager:** Roberto Mancini\n\n| # | Position | Player |\n|---|----------|--------|\n| 1 | GK | Peter Schmeichel Jr. |\n| 2 | RB | Kyle Walker-Peters |\n| 4 | CB | Virgil van Berg |\n| 5 | CB | Harry Stone |\n| 3 | LB | Luke Shaw Jr. |\n| 6 | DM | Declan Rice |\n| 8 | CM | Bruno Fernandes Jr. |\n| 7 | RW | Jadon Sancho Jr. |\n| 11 | LW | Marcus Rashford Jr. |\n| 10 | AM | **Mason Mount Jr.** (C) |\n| 9 | ST | Erling Larsen |\n\n**Bench:** 22-Henderson, 15-Maguire Jr., 17-Fred Jr., 18-Eriksen, 19-Antony Jr., 20-Pellistri, 21-Garnacho Jr.\n\n---\n\n## 📊 Head to Head\n\n| Stat | City FC | Man Utd |\n|------|---------|--------|\n| League Position | 2nd | 4th |\n| Points | 32 | 28 |\n| Last 5 Games | W W D W L | W D W L W |\n| Goals Scored | 34 | 29 |\n| Goals Conceded | 12 | 15 |\n\n**Last Meeting:** City FC 2-1 Man Utd (April 2025)\n\n**All-Time Record:**\n- City FC wins: 54\n- Man Utd wins: 61\n- Draws: 38\n\n---\n\n## 🍔 Food & Drink\n\n### Concourse Options\n- **Stadium Burger** - Classic burgers and hot dogs\n- **Pizza Corner** - Slices and whole pies\n- **The Noodle Bar** - Asian street food\n- **Fish & Chips** - Traditional British\n- **Vegan Kitchen** - Plant-based options\n- **Coffee Station** - Hot drinks and pastries\n\n### Prices\n- Beer (pint): £6.50\n- Burger meal: £12.00\n- Hot dog: £6.00\n- Pizza slice: £5.00\n- Coffee: £3.50\n- Water bottle: £2.50\n\n**📱 Mobile ordering available - skip the queue!**\nDownload the City FC app and order to your seat (Blocks 101-140 only)\n\n---\n\n## 📍 Getting Home\n\n### Public Transport\n- **Stadium Station** → Blue Line services every 5 minutes\n- **Special match buses** → City Centre (£3 fare)\n- Allow 20-30 minutes to reach station after final whistle\n\n### Driving\n- Exit via your designated gate to reduce congestion\n- **Lot A & B** → North exit (Highway 1)\n- **Lot C & D** → South exit (Highway 2)\n- Expected clear time: 45-60 minutes post-match\n\n### Rideshare\n- **Pickup zone** → East Gate car park\n- Surge pricing likely for 30 min after match\n\n---\n\n## 📱 Stay Connected\n\n- **WiFi:** `CityStadium_Guest` (free, no password)\n- **Official App:** Live stats, replays, mobile ordering\n- **Social:** @CityFC on all platforms\n- **Match Hashtag:** #CityVsUnited\n\n---\n\n## ⚠️ Important Information\n\n### Prohibited Items\n❌ Outside food & drinks\n❌ Bags larger than A4 size\n❌ Umbrellas\n❌ Professional cameras (lens > 20cm)\n❌ Drones\n❌ Weapons of any kind\n\n### Emergency\n- **Emergency services:** Dial 999\n- **Stadium security:** Text 66777\n- **Lost children:** Report to nearest steward\n- **Medical emergency:** Nearest first aid point\n\n---\n\n## 🎉 Enjoy the Match!\n\nThank you for supporting City FC. Sing loud, respect fellow fans, and may the best team win!\n\n*This card is your souvenir of today''s match. Collect the whole season!*', NULL, E'Key players to watch:\n- Emmanuel Okonkwo (City): 12 goals this season, top scorer\n- Erling Larsen (United): Hat-trick last match\n\nTactical preview: City likely to press high, United may counter-attack\n\nWeather forecast: 12°C, partly cloudy, 10% chance of rain\n\nReferee: Michael Oliver - tends to let game flow, averages 3.2 yellows/match\n\nVAR: Howard Webb - controversial offside decisions recently\n\nStadium records: Largest crowd 59,847 vs Liverpool 2023\n\nClub history: City FC founded 1892, 3 league titles, 2 FA Cups\nManchester United: Founded 1878, 20 league titles, 12 FA Cups', 1);

    RAISE NOTICE 'Successfully created Football Match card with ID: %', v_card_id;
END $body$;


-- Register "Football Match - Single Page" as content template
DO $reg$
DECLARE
    v_card_id UUID;
BEGIN
    -- Find the card we just created by name and user
    SELECT id INTO v_card_id
    FROM cards 
    WHERE user_id = '91acf5ca-f78b-4acd-bc75-98b85959ce62'::UUID
      AND name = 'City United vs Royal Athletic'
    ORDER BY created_at DESC
    LIMIT 1;
    
    IF v_card_id IS NULL THEN
        RAISE WARNING 'Could not find card "City United vs Royal Athletic" for template registration';
    ELSE
        -- Register or update the template
        INSERT INTO content_templates (slug, card_id, venue_type, is_featured, is_active, sort_order)
        VALUES ('football-match-single', v_card_id, 'event', false, true, 7)
        ON CONFLICT (slug) DO UPDATE SET
            card_id = EXCLUDED.card_id,
            venue_type = EXCLUDED.venue_type,
            sort_order = EXCLUDED.sort_order,
            updated_at = NOW();
        
        RAISE NOTICE 'Registered template: football-match-single (card_id: %)', v_card_id;
    END IF;
END $reg$;


-- ==================================================================
-- Template 8: History Museum - Grouped List
-- Slug: history-museum-grouped | Venue: museum
-- ==================================================================

-- History Museum - Grouped List Mode (Digital Access)
-- Template: Museum with categorized exhibits by era
-- 
-- INSTRUCTIONS:
-- 1. Replace '91acf5ca-f78b-4acd-bc75-98b85959ce62' with actual user UUID
-- 2. Update image_url values with actual uploaded image URLs
-- 3. Run this SQL in Supabase SQL Editor or via psql

DO $body$
DECLARE
    v_user_id UUID := '91acf5ca-f78b-4acd-bc75-98b85959ce62'::UUID;
    v_card_id UUID;
    v_cat_ancient UUID;
    v_cat_medieval UUID;
    v_cat_exploration UUID;
    v_cat_industrial UUID;
    v_cat_modern UUID;
BEGIN
    -- Insert the card
    INSERT INTO cards (
        id, user_id, name, description, content_mode, is_grouped, group_display, billing_type,
        conversation_ai_enabled, ai_instruction, ai_knowledge_base,
        ai_welcome_general, ai_welcome_item, image_url
    ) VALUES (
        gen_random_uuid(),
        v_user_id,
        'Journey Through Time: City Heritage Museum',
        E'Discover **5,000 years of history** at the City Heritage Museum.\n\nFrom ancient civilizations to modern innovations, explore artifacts, stories, and interactive displays that bring our shared past to life.\n\n🏛️ Tap any category to browse exhibits, or use the AI guide for personalized tours.',
        'list',
        true,
        'expanded',
        'digital',
        true,
        'You are a knowledgeable museum guide with expertise in world history. Share fascinating stories and lesser-known facts about exhibits. Connect historical events to modern life. Be engaging and educational without being dry or overly academic. Encourage curiosity and questions.',
        E'City Heritage Museum - Founded 1892\n\nCollection: Over 50,000 artifacts spanning 5 millennia\nFloors: 4 exhibition floors plus basement archives\n\nVisitor facilities: Café on ground floor, gift shop near exit, accessible restrooms on all floors, wheelchair loan available at reception.\n\nSpecial programs: School groups welcome, senior discounts on Tuesdays, free admission first Sunday of each month.\n\nPhotography allowed without flash. Some artifacts have handling restrictions for conservation.',
        'Welcome to the City Heritage Museum! I''m your personal history guide. Ask me about any era, artifact, or get recommendations based on your interests!',
        'Let me tell you the fascinating story behind "{name}". What aspect interests you most?',
        NULL
    ) RETURNING id INTO v_card_id;

    -- Category 1: Ancient Civilizations
    INSERT INTO content_items (id, card_id, parent_id, name, content, ai_knowledge_base, sort_order)
    VALUES (gen_random_uuid(), v_card_id, NULL, 'Ancient Civilizations', '', 
        'The Ancient Civilizations gallery covers Mesopotamia, Egypt, Greece, Rome, and early Chinese dynasties. Highlights include genuine cuneiform tablets, Egyptian shabtis, Greek pottery, and Roman coins. Climate controlled at 21°C with 45% humidity for artifact preservation.', 1)
    RETURNING id INTO v_cat_ancient;

    -- Ancient items
    INSERT INTO content_items (card_id, parent_id, name, content, image_url, ai_knowledge_base, sort_order) VALUES
    (v_card_id, v_cat_ancient, 'Cuneiform Tablet - Trade Record', E'**Origin:** Mesopotamia (modern-day Iraq)\n**Date:** c. 2100 BCE\n**Material:** Clay\n\nThis clay tablet records a shipment of barley and wool between merchants in the ancient city of Ur. The cuneiform script, one of humanity''s earliest writing systems, was pressed into wet clay using a reed stylus.\n\nThe tablet provides rare insight into daily commerce in ancient Sumer, showing that trade networks, contracts, and accounting existed over 4,000 years ago.', NULL, 'Found during excavations at Ur in 1928. Translated by Professor Samuel Kramer. Records 50 bushels of barley and 3 bolts of wool. Mentions a merchant named Ur-Nammu (not the king). Shows early math - Sumerians used base-60 number system, which is why we have 60 seconds in a minute today.', 1),
    
    (v_card_id, v_cat_ancient, 'Egyptian Shabti Figure', E'**Origin:** Thebes, Egypt\n**Date:** c. 1300 BCE (New Kingdom)\n**Material:** Faience (glazed ceramic)\n\nShabtis were placed in tombs to serve the deceased in the afterlife. Ancient Egyptians believed these small figures would magically come to life to perform manual labor for their owner in the next world.\n\nThis shabti bears hieroglyphic inscriptions identifying it as belonging to a scribe named Amenhotep.', NULL, 'Wealthy Egyptians were buried with 365 shabtis - one for each day of the year. This example is 15cm tall, typical for a middle-class official. The blue-green faience glaze was associated with rebirth and the Nile''s life-giving waters. Acquired by the museum in 1905 from the Egypt Exploration Fund.', 2),
    
    (v_card_id, v_cat_ancient, 'Greek Black-Figure Amphora', E'**Origin:** Athens, Greece\n**Date:** c. 530 BCE\n**Material:** Terracotta\n\nThis storage vessel depicts Heracles battling the Nemean lion, one of his famous Twelve Labors. The "black-figure" technique involves painting figures in slip that turns black when fired, with details incised to reveal the red clay beneath.\n\nSuch vessels were prized throughout the Mediterranean and often exported filled with olive oil or wine.', NULL, 'Attributed to the Antimenes Painter, one of the most prolific black-figure artists. 52cm tall, holds approximately 30 liters. Found in an Etruscan tomb in Italy - showing how Greek goods spread across the ancient world. The scene shows the moment Heracles realizes arrows won''t pierce the lion''s hide.', 3);

    -- Category 2: Medieval World
    INSERT INTO content_items (id, card_id, parent_id, name, content, ai_knowledge_base, sort_order)
    VALUES (gen_random_uuid(), v_card_id, NULL, 'Medieval World', '', 
        'The Medieval gallery explores European, Islamic, and Asian civilizations during this period. Includes armor, manuscripts, religious art, and trade goods. Features a reconstructed monk''s scriptorium and interactive knight''s armor display.', 2)
    RETURNING id INTO v_cat_medieval;

    -- Medieval items
    INSERT INTO content_items (card_id, parent_id, name, content, image_url, ai_knowledge_base, sort_order) VALUES
    (v_card_id, v_cat_medieval, 'Illuminated Manuscript Page', E'**Origin:** England\n**Date:** c. 1150 CE\n**Material:** Vellum (calfskin), gold leaf, mineral pigments\n\nThis page from a psalter (book of psalms) showcases the incredible artistry of medieval monks. The large decorated initial "B" (for "Beatus") contains intricate interlacing patterns and gold leaf highlights.\n\nCreating such manuscripts was painstaking work—a single book could take years to complete.', NULL, 'From a psalter produced at Canterbury Cathedral. The blue pigment is ultramarine, made from lapis lazuli imported from Afghanistan - more expensive than gold. Red is vermilion from cinnabar. The gold is 23-karat, hammered into leaf 1/10,000th of a millimeter thick. Acquired from a private collection in 1956.', 1),
    
    (v_card_id, v_cat_medieval, 'Knight''s Great Helm', E'**Origin:** Germany\n**Date:** c. 1350 CE\n**Material:** Steel, brass rivets\n\nThe "great helm" or "pot helm" offered maximum protection for knights in tournament combat. This example features a flat top and narrow eye slits, typical of 14th-century design.\n\nWeighing 3.2kg, it would have been worn over a padded cap and chainmail coif. The restricted vision and ventilation made it impractical for battlefield use, so it was primarily ceremonial and for jousting.', NULL, 'Shows hammer marks from hand-forging. The brass rivets are original. Originally had a crest mount on top for identifying the knight. Could withstand lance impact but cooking hot in summer sun. Knights often collapsed from heat exhaustion rather than wounds. Purchased at Sotheby''s auction in 1972.', 2),
    
    (v_card_id, v_cat_medieval, 'Islamic Astrolabe', E'**Origin:** Toledo, Spain\n**Date:** c. 1100 CE\n**Material:** Brass, silver inlay\n\nThis sophisticated astronomical instrument was used for navigation, timekeeping, and determining the direction of Mecca for prayer. Islamic scholars preserved and advanced Greek astronomical knowledge during the medieval period.\n\nThe Arabic inscriptions include star names and astronomical tables—many of which are still used in Western astronomy today.', NULL, 'Made during Islamic rule of Spain (Al-Andalus). Signed by craftsman Ibrahim ibn Sa''id al-Sahli. Could determine latitude to within 1 degree. Star names like Betelgeuse, Rigel, and Aldebaran come from Arabic. This instrument type wasn''t surpassed until the invention of the sextant in the 18th century.', 3);

    -- Category 3: Age of Exploration
    INSERT INTO content_items (id, card_id, parent_id, name, content, ai_knowledge_base, sort_order)
    VALUES (gen_random_uuid(), v_card_id, NULL, 'Age of Exploration', '', 
        'This gallery covers European expansion, colonial trade, the Scientific Revolution, and the Enlightenment. Features navigation instruments, trade goods, early scientific equipment, and art from the period.', 3)
    RETURNING id INTO v_cat_exploration;

    -- Exploration items
    INSERT INTO content_items (card_id, parent_id, name, content, image_url, ai_knowledge_base, sort_order) VALUES
    (v_card_id, v_cat_exploration, 'Dutch East India Company Porcelain', E'**Origin:** Jingdezhen, China (exported to Europe)\n**Date:** c. 1720\n**Material:** Hard-paste porcelain, cobalt blue glaze\n\nThis plate was commissioned by the Dutch East India Company (VOC) for export to wealthy European households. Chinese artisans adapted their traditional blue-and-white designs to suit European tastes.\n\nThe VOC shipped millions of pieces of porcelain westward, making Chinese porcelain so fashionable that European factories spent decades trying to recreate the secret formula.', NULL, 'Part of a set of 200 pieces ordered for a Dutch merchant family. "Kraak" style porcelain with panels radiating from center. The VOC mark on bottom verified authenticity. Took 18 months from order to delivery via ship around Cape of Good Hope. Europeans didn''t discover how to make true porcelain until 1708 at Meissen.', 1),
    
    (v_card_id, v_cat_exploration, 'Mariner''s Compass', E'**Origin:** London, England\n**Date:** 1753\n**Maker:** Henry Gregory\n\nThis brass mariner''s compass helped navigate the world''s oceans during the height of British naval power. The gimbal mount keeps the compass level despite the ship''s rolling motion.\n\nSuch instruments were essential for the trade routes that connected continents and transformed global commerce.', NULL, 'Maker Henry Gregory was official instrument maker to the Royal Navy. The compass card is hand-painted on mica. The gimbal design prevents tilting up to 45 degrees. Would have been used alongside charts, sextant, and log line. Donated by descendants of Captain James Harewood in 1891.', 2);

    -- Category 4: Industrial Revolution
    INSERT INTO content_items (id, card_id, parent_id, name, content, ai_knowledge_base, sort_order)
    VALUES (gen_random_uuid(), v_card_id, NULL, 'Industrial Revolution', '', 
        'The Industrial Revolution gallery showcases the transformation from agrarian society to industrial power. Features machinery, photographs, worker artifacts, and items showing daily life during rapid change. Includes a working steam engine demonstration (Saturdays at 2pm).', 4)
    RETURNING id INTO v_cat_industrial;

    -- Industrial items
    INSERT INTO content_items (card_id, parent_id, name, content, image_url, ai_knowledge_base, sort_order) VALUES
    (v_card_id, v_cat_industrial, 'Spinning Jenny Model', E'**Origin:** Lancashire, England\n**Date:** c. 1785 (replica of 1764 original)\n**Material:** Wood, metal, cotton thread\n\nJames Hargreaves'' Spinning Jenny revolutionized textile production by allowing one worker to operate eight spindles simultaneously. This working model demonstrates the mechanism that helped spark the Industrial Revolution.\n\nBefore the Jenny, spinning thread was slow hand-work. After, cloth production increased dramatically, transforming the global economy.', NULL, 'Working replica built by museum workshop in 1923. Original could produce 8 threads at once vs. 1 on a spinning wheel - 8x productivity. Named "Jenny" possibly after Hargreaves'' daughter. Hand-spinners initially attacked the machines, fearing job losses. Led to factory system replacing cottage industry.', 1),
    
    (v_card_id, v_cat_industrial, 'Victorian Factory Worker''s Lunch Pail', E'**Origin:** Birmingham, England\n**Date:** c. 1890\n**Material:** Tin-plated steel\n\nThis humble lunch pail tells the story of ordinary workers who powered the Industrial Revolution. Factory shifts of 12-14 hours meant workers brought meals from home.\n\nThe two-compartment design kept food separate—typically bread and cheese in one section, cold tea or water in the other. Scratched initials "J.W." are visible on the bottom.', NULL, 'Found during demolition of old textile mill in 1967. J.W. possibly John or James Williams - common names in factory records. Factory workers earned 10-15 shillings per week. Women and children earned less. Lunch breaks were often just 30 minutes. No refrigeration meant food spoiled quickly in summer heat of factories.', 2);

    -- Category 5: Modern Era
    INSERT INTO content_items (id, card_id, parent_id, name, content, ai_knowledge_base, sort_order)
    VALUES (gen_random_uuid(), v_card_id, NULL, 'Modern Era', '', 
        'The Modern Era gallery covers both World Wars, social movements, technological innovation, and contemporary history. Includes oral history stations with video testimonies. Sensitive content warnings at gallery entrance.', 5)
    RETURNING id INTO v_cat_modern;

    -- Modern items
    INSERT INTO content_items (card_id, parent_id, name, content, image_url, ai_knowledge_base, sort_order) VALUES
    (v_card_id, v_cat_modern, 'WWI Soldier''s Trench Art', E'**Origin:** Western Front, France\n**Date:** c. 1917\n**Material:** Brass artillery shell casing, hand-engraved\n\nSoldiers on both sides of WWI created "trench art" from battlefield debris during quiet moments. This shell casing has been transformed into a decorative vase, engraved with flowers and the word "VERDUN."\n\nSuch items served as both souvenirs and coping mechanisms for trauma. They remain powerful reminders of the human experience amid industrial warfare.', NULL, '18-pounder British artillery shell. Verdun was one of the war''s longest battles - 10 months, 700,000 casualties. Soldier identity unknown but style suggests British or Canadian maker. Donated by soldier''s grandson in 1998. Trench art ranged from simple ashtrays to elaborate sculptures. Created during long periods of waiting between attacks.', 1),
    
    (v_card_id, v_cat_modern, 'Original Apple Macintosh (1984)', E'**Origin:** Cupertino, California, USA\n**Date:** January 1984\n**Material:** Plastic housing, CRT monitor, electronics\n\nThe Apple Macintosh introduced millions to personal computing with its revolutionary graphical user interface and mouse. Steve Jobs'' vision of "a computer for the rest of us" transformed how humans interact with technology.\n\nThis unit is one of the first 1,000 produced, still in working condition.', NULL, 'Serial number indicates production in January 1984, first month of manufacture. Cost $2,495 - equivalent to about $7,500 today. 128KB RAM, 9-inch black & white screen. Came with MacWrite and MacPaint software. The "1984" Super Bowl commercial is considered one of the greatest ads ever made. Donated by the original owner in 2010.', 2);

    RAISE NOTICE 'Successfully created History Museum card with ID: %', v_card_id;
END $body$;


-- Register "History Museum - Grouped List" as content template
DO $reg$
DECLARE
    v_card_id UUID;
BEGIN
    -- Find the card we just created by name and user
    SELECT id INTO v_card_id
    FROM cards 
    WHERE user_id = '91acf5ca-f78b-4acd-bc75-98b85959ce62'::UUID
      AND name = 'National History Museum: Journey Through Time'
    ORDER BY created_at DESC
    LIMIT 1;
    
    IF v_card_id IS NULL THEN
        RAISE WARNING 'Could not find card "National History Museum: Journey Through Time" for template registration';
    ELSE
        -- Register or update the template
        INSERT INTO content_templates (slug, card_id, venue_type, is_featured, is_active, sort_order)
        VALUES ('history-museum-grouped', v_card_id, 'museum', false, true, 8)
        ON CONFLICT (slug) DO UPDATE SET
            card_id = EXCLUDED.card_id,
            venue_type = EXCLUDED.venue_type,
            sort_order = EXCLUDED.sort_order,
            updated_at = NOW();
        
        RAISE NOTICE 'Registered template: history-museum-grouped (card_id: %)', v_card_id;
    END IF;
END $reg$;


-- ==================================================================
-- Template 9: Hotel Services - List Mode
-- Slug: hotel-services-list | Venue: hospitality
-- ==================================================================

-- Hotel Services - Grouped List Mode (Digital Access)
-- Template: Hotel guest services directory with categories
-- 
-- INSTRUCTIONS:
-- 1. Replace '91acf5ca-f78b-4acd-bc75-98b85959ce62' with actual user UUID
-- 2. Update image_url values with actual uploaded image URLs
-- 3. Run this SQL in Supabase SQL Editor or via psql

DO $body$
DECLARE
    v_user_id UUID := '91acf5ca-f78b-4acd-bc75-98b85959ce62'::UUID;
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
        ai_welcome_general, ai_welcome_item, daily_scan_limit
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
        'Welcome to Grand Plaza Hotel! I''m your virtual concierge. How may I assist you today?',
        'I''d be happy to help you with {name}. What would you like to know?',
        2000
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

    RAISE NOTICE 'Successfully created Hotel Services card with ID: %', v_card_id;
END $body$;

-- Register "Hotel Services - List Mode" as content template
DO $reg$
DECLARE
    v_card_id UUID;
BEGIN
    -- Find the card we just created by name and user
    SELECT id INTO v_card_id
    FROM cards 
    WHERE user_id = '91acf5ca-f78b-4acd-bc75-98b85959ce62'::UUID
      AND name = 'The Grand Plaza Hotel'
    ORDER BY created_at DESC
    LIMIT 1;
    
    IF v_card_id IS NULL THEN
        RAISE WARNING 'Could not find card "The Grand Plaza Hotel" for template registration';
    ELSE
        -- Register or update the template
        INSERT INTO content_templates (slug, card_id, venue_type, is_featured, is_active, sort_order)
        VALUES ('hotel-services-list', v_card_id, 'hospitality', false, true, 9)
        ON CONFLICT (slug) DO UPDATE SET
            card_id = EXCLUDED.card_id,
            venue_type = EXCLUDED.venue_type,
            sort_order = EXCLUDED.sort_order,
            updated_at = NOW();
        
        RAISE NOTICE 'Registered template: hotel-services-list (card_id: %)', v_card_id;
    END IF;
END $reg$;


-- ==================================================================
-- Template 10: Illustrator Portfolio - Grid Mode
-- Slug: illustrator-portfolio-grid | Venue: retail
-- ==================================================================

-- Illustrator Portfolio - Grid Gallery Mode (Digital Access)
-- Template: Creative portfolio with visual grid
-- 
-- INSTRUCTIONS:
-- 1. Replace '91acf5ca-f78b-4acd-bc75-98b85959ce62' with actual user UUID
-- 2. Update image_url values with actual uploaded image URLs
-- 3. Run this SQL in Supabase SQL Editor or via psql

DO $body$
DECLARE
    v_user_id UUID := '91acf5ca-f78b-4acd-bc75-98b85959ce62'::UUID;
    v_card_id UUID;
    v_default_category UUID;
BEGIN
    -- Insert the card
    INSERT INTO cards (
        id, user_id, name, description, content_mode, is_grouped, group_display, billing_type,
        conversation_ai_enabled, ai_instruction, ai_knowledge_base,
        ai_welcome_general, ai_welcome_item, daily_scan_limit
    ) VALUES (
        gen_random_uuid(),
        v_user_id,
        'Luna Chen - Illustration Portfolio',
        E'✨ **Hello, I''m Luna!**\n\nFreelance illustrator specializing in editorial, book covers, and brand illustration.\n\n📧 hello@lunachen.art | 🌐 lunachen.art',
        'grid',
        true,
        'expanded',
        'digital',
        true,
        'You are Luna Chen, a friendly freelance illustrator. Talk about your creative process, inspirations, and the stories behind your work. Help potential clients understand your style, turnaround times, and how to commission work. Be warm, creative, and enthusiastic about illustration.',
        E'Luna Chen - Freelance Illustrator\nBased in: Brooklyn, NY\nExperience: 8 years professional illustration\n\nSpecialties: Editorial illustration, book covers, brand illustration, packaging design, children''s book illustration\n\nClients: The New York Times, Penguin Random House, Apple, Airbnb, Spotify, The New Yorker, Wired Magazine\n\nEducation: BFA Illustration, School of Visual Arts\nAwards: Society of Illustrators Silver Medal 2023, Communication Arts Illustration Annual 2022\n\nStyle: Whimsical, colorful, narrative-driven, blend of digital and traditional media\n\nAvailability: Currently booking for Q2 2025\nCommission inquiry: hello@lunachen.art',
        'Hi there! I''m Luna. Thanks for checking out my portfolio! Feel free to ask about any piece, my process, or how we might work together.',
        'Ah, "{name}" - I love this one! Want to hear the story behind it?',
        NULL
    ) RETURNING id INTO v_card_id;

    -- Create default category (hidden in flat mode, holds all content items)
    INSERT INTO content_items (id, card_id, parent_id, name, content, ai_knowledge_base, sort_order)
    VALUES (gen_random_uuid(), v_card_id, NULL, 'General', '', '', 1)
    RETURNING id INTO v_default_category;

    -- Insert portfolio pieces (layer 2 under default category)
    INSERT INTO content_items (card_id, parent_id, name, content, image_url, ai_knowledge_base, sort_order) VALUES
    (v_card_id, v_default_category, 'Dreams of Summer', E'**Editorial Illustration**\n\n*The New York Times Magazine*\nSummer Reading Issue, June 2024\n\n---\n\nA dreamy, sun-drenched scene capturing the essence of lazy summer afternoons and the escapism of a good book.\n\n**Medium:** Digital (Procreate + Photoshop)\n**Art Direction:** Matt Dorfman\n\n🏆 *Featured in Communication Arts Illustration Annual 2024*', NULL, 'Commission for NYT Summer Reading Issue. Brief was "the feeling of getting lost in a book during summer." Inspired by childhood summers at my grandmother''s house. Color palette: warm yellows, peachy pinks, deep shadows. Took about 3 days from sketch to final. Matt gave me a lot of creative freedom. One of my most-shared pieces on Instagram.', 1),
    
    (v_card_id, v_default_category, 'Midnight Garden', E'**Book Cover**\n\n*"Midnight Garden" by Eleanor Rose*\nPenguin Random House, 2024\n\n---\n\nCover illustration for a magical realism novel about a woman who discovers she can enter a mysterious garden that only appears at night.\n\n**Medium:** Gouache + Digital finishing\n**Art Direction:** Emily Mahon\n\n📚 *New York Times Bestseller*', NULL, 'My first cover for Penguin. Went through 5 sketch rounds - publisher wanted to balance "magical" with "literary fiction credibility." Traditional gouache for the organic textures, digital for the glowing elements. The luminous flowers were achieved by layering in Photoshop. Author Eleanor personally requested me after seeing my Instagram.', 2),
    
    (v_card_id, v_default_category, 'Kitchen Stories', E'**Personal Project**\n\nA series of 12 illustrations celebrating food memories and the stories we share around the table.\n\n---\n\nEach piece captures a specific moment: grandmother''s soup, late-night ramen, birthday cakes, Sunday morning pancakes.\n\n**Medium:** Gouache on paper\n**Size:** 9×12 inches each\n\n🖼️ *Exhibited at Giant Robot Gallery, Los Angeles*', NULL, 'Personal project I worked on during the pandemic. Each illustration based on my own food memories or stories from friends. The series took 6 months. Sold original gouache paintings at Giant Robot show. Prints available in my online shop. This series led to several food/restaurant commissions.', 3),
    
    (v_card_id, v_default_category, 'Wonder World', E'**Children''s Book**\n\n*"Wonder World" written by James Park*\nLittle Brown Books for Young Readers, 2023\n\n---\n\n32-page picture book about a child who discovers that imagination can transform the ordinary into the extraordinary.\n\n**Medium:** Digital (Procreate)\n**Format:** 32 pages, full color\n\n⭐ *School Library Journal Starred Review*', NULL, 'My first picture book! 9-month project from contract to final art. Created over 40 sketches for 32 pages (revisions). Color palette shifts from muted to vibrant as child''s imagination takes over. James and I worked closely on visual storytelling. Used my niece as model reference. Currently optioned for animated adaptation.', 4),
    
    (v_card_id, v_default_category, 'Tech Giants', E'**Editorial Illustration**\n\n*Wired Magazine*\n"The Future of Big Tech" Feature, March 2024\n\n---\n\nConceptual piece exploring the outsized influence of technology companies on our daily lives. The tiny humans navigate through a landscape of massive, looming tech symbols.\n\n**Medium:** Digital (Photoshop)\n**Art Direction:** Victor Ng', NULL, 'Challenging brief - had to visualize "tech power" without being too obvious or clichéd. Went through many concepts before landing on this scale-play approach. Inspired by Magritte and surrealist juxtaposition. Turnaround was tight - 5 days from brief to final. Victor at Wired is great to work with, very collaborative.', 5),
    
    (v_card_id, v_default_category, 'Spotify Wrapped 2024', E'**Brand Illustration**\n\n*Spotify*\nWrapped Campaign 2024\n\n---\n\nSeries of 8 illustrations for Spotify''s annual Wrapped campaign, visualizing different listening moods and musical journeys.\n\n**Medium:** Digital (Procreate + After Effects)\n**Agency:** Collins\n\n🎵 *Seen by millions of Spotify users worldwide*', NULL, 'Biggest commercial project to date. Collins agency approached me for the "emotional" illustration style. Created 8 hero illustrations plus animated versions for the app. Strict brand guidelines but room for personality. Project took 2 months with a team of animators. Amazing to see my work on everyone''s Instagram stories in December!', 6),
    
    (v_card_id, v_default_category, 'Cafe Culture', E'**Editorial Illustration**\n\n*The New Yorker*\n"The Third Place" Feature, September 2024\n\n---\n\nIllustration for an essay about the importance of cafes and coffee shops as community gathering spaces in an increasingly isolated world.\n\n**Medium:** Ink + Digital color\n**Art Direction:** Françoise Mouly', NULL, 'Dream assignment - I''ve always wanted to work with The New Yorker. Françoise''s direction was minimal but precise: "capture the feeling of overhearing strangers'' conversations." Used traditional ink linework, then colored digitally. Referenced my own local coffee shop in Brooklyn. The New Yorker''s style requirements meant simplifying my usual approach.', 7),
    
    (v_card_id, v_default_category, 'Wild Things', E'**Personal Project / Prints**\n\nA series celebrating the weird and wonderful creatures of the natural world.\n\n---\n\nEach illustration reimagines a real animal through a surreal, colorful lens while staying true to their fascinating biology.\n\n**Medium:** Risograph prints\n**Size:** 11×14 inches\n**Edition:** 100 each\n\n🛒 *Available in my shop*', NULL, 'Passion project combining my love of nature documentaries with illustration. Animals featured: axolotl, pangolin, mantis shrimp, deep sea anglerfish, peacock spider, star-nosed mole. Risograph printing adds beautiful texture and slight variations between prints. Limited edition of 100 per design, hand-numbered. Bestseller in my online shop.', 8),
    
    (v_card_id, v_default_category, 'Airbnb Experiences', E'**Brand Illustration**\n\n*Airbnb*\nExperiences Marketing Campaign, 2024\n\n---\n\nSeries of illustrations representing different Airbnb Experience categories: cooking classes, outdoor adventures, arts & culture, and local tours.\n\n**Medium:** Digital (Illustrator + Procreate)\n**Agency:** In-house Airbnb Design', NULL, 'Worked directly with Airbnb''s in-house design team. Brief was "make experiences feel personal and authentic, not touristy." Created 12 illustrations for the campaign. Had to work within Airbnb''s brand system but add warmth and personality. Project included style guide for future illustrations by other artists.', 9),
    
    (v_card_id, v_default_category, 'Self Portrait 2024', E'**Personal Work**\n\nAnnual tradition: a new self-portrait every year documenting where I am in life and art.\n\n---\n\nThis year: surrounded by the projects, plants, and chaos of my Brooklyn studio. My cat Mochi makes an appearance.\n\n**Medium:** Gouache on paper\n**Size:** 16×20 inches\n\n✨ *Not for sale - part of personal archive*', NULL, 'I''ve done a self-portrait every year since art school - now have 12 years documented. This year''s includes references to major projects (book covers on wall), my studio plants, and of course Mochi the cat. Took longer than client work because I''m my own worst critic. The series shows my stylistic evolution.', 10),
    
    (v_card_id, v_default_category, 'Work With Me', E'**Commission Information**\n\nI''m currently booking projects for Q2 2025.\n\n---\n\n**Services:**\n- Editorial illustration\n- Book covers and interior art\n- Brand illustration and campaigns\n- Packaging design\n- Murals and large-scale work\n\n**Starting Rates:**\n- Spot illustration: from $800\n- Full-page editorial: from $1,500\n- Book cover: from $3,000\n- Brand campaigns: Custom quote\n\n**Process:**\n1. Initial consultation (free)\n2. Quote and timeline\n3. Sketches (2-3 rounds)\n4. Final art + revisions\n\n📧 **hello@lunachen.art**\n🌐 **lunachen.art**\n📱 **@lunachen.art** (Instagram)', NULL, 'Typical turnaround: 2-4 weeks depending on complexity. Rush fees apply for under 1 week. 50% deposit required to begin. Kill fee is 50% if project cancelled after sketches approved. Usage rights negotiated per project. Happy to do video calls for consultations. Represented by Magnet Reps for advertising work.', 11);

    RAISE NOTICE 'Successfully created Illustrator Portfolio card with ID: %', v_card_id;
END $body$;


-- Register "Illustrator Portfolio - Grid Mode" as content template
DO $reg$
DECLARE
    v_card_id UUID;
BEGIN
    -- Find the card we just created by name and user
    SELECT id INTO v_card_id
    FROM cards 
    WHERE user_id = '91acf5ca-f78b-4acd-bc75-98b85959ce62'::UUID
      AND name = 'Sarah Chen: Digital Dreamscapes'
    ORDER BY created_at DESC
    LIMIT 1;
    
    IF v_card_id IS NULL THEN
        RAISE WARNING 'Could not find card "Sarah Chen: Digital Dreamscapes" for template registration';
    ELSE
        -- Register or update the template
        INSERT INTO content_templates (slug, card_id, venue_type, is_featured, is_active, sort_order)
        VALUES ('illustrator-portfolio-grid', v_card_id, 'retail', false, true, 10)
        ON CONFLICT (slug) DO UPDATE SET
            card_id = EXCLUDED.card_id,
            venue_type = EXCLUDED.venue_type,
            sort_order = EXCLUDED.sort_order,
            updated_at = NOW();
        
        RAISE NOTICE 'Registered template: illustrator-portfolio-grid (card_id: %)', v_card_id;
    END IF;
END $reg$;


-- ==================================================================
-- Template 11: Shopping Mall - List Mode
-- Slug: shopping-mall-list | Venue: retail
-- ==================================================================

-- Shopping Mall - Simple List Mode (Digital Access)
-- Template: Mall store directory
-- 
-- INSTRUCTIONS:
-- 1. Replace '91acf5ca-f78b-4acd-bc75-98b85959ce62' with actual user UUID
-- 2. Update image_url values with actual uploaded image URLs
-- 3. Run this SQL in Supabase SQL Editor or via psql

DO $body$
DECLARE
    v_user_id UUID := '91acf5ca-f78b-4acd-bc75-98b85959ce62'::UUID;
    v_card_id UUID;
    v_default_category UUID;
BEGIN
    -- Insert the card
    INSERT INTO cards (
        id, user_id, name, description, content_mode, is_grouped, group_display, billing_type,
        conversation_ai_enabled, ai_instruction, ai_knowledge_base,
        ai_welcome_general, ai_welcome_item, daily_scan_limit
    ) VALUES (
        gen_random_uuid(),
        v_user_id,
        'Central Plaza Mall - Store Directory',
        E'🛍️ Welcome to **Central Plaza Mall**\n\n200+ stores across 4 floors. Find your favorite brands below.\n\n📍 Guest Services: Level 1 near Main Entrance',
        'list',
        true,
        'expanded',
        'digital',
        true,
        'You are a friendly mall concierge. Help shoppers find stores, restaurants, and services. Give directions, share current promotions, and suggest alternatives if a store doesn''t have what they need. Be helpful and enthusiastic about shopping!',
        E'Central Plaza Mall - Premier Shopping Destination\nAddress: 500 Central Avenue\nHours: Mon-Sat 10am-9pm, Sun 11am-7pm\nStores: 200+ retail locations\nFloors: 4 levels + parking garage\n\nLayout:\n- Level 1: Fashion, accessories, main entrances\n- Level 2: Electronics, home goods, food court\n- Level 3: Entertainment, kids, services\n- Level 4: Department stores, specialty retail\n\nParking: 3 hours free with validation, $3/hour after\nWiFi: CentralPlaza_Guest (free)\n\nGuest Services: Wheelchair rental, stroller rental, gift cards, package holding, lost & found',
        'Welcome to Central Plaza Mall! I''m here to help you find stores, restaurants, or anything you need. What are you shopping for today?',
        'I''d be happy to help you with {name}. Would you like directions or information about their current promotions?',
        NULL
    ) RETURNING id INTO v_card_id;

    -- Create default category (hidden in flat mode, holds all content items)
    INSERT INTO content_items (id, card_id, parent_id, name, content, ai_knowledge_base, sort_order)
    VALUES (gen_random_uuid(), v_card_id, NULL, 'General', '', '', 1)
    RETURNING id INTO v_default_category;

    -- Insert stores (layer 2 items under default category)
    INSERT INTO content_items (card_id, parent_id, name, content, image_url, ai_knowledge_base, sort_order) VALUES
    (v_card_id, v_default_category, 'Zara', E'**Fast Fashion & Trendy Styles**\n\n📍 Level 1, Store #112\n⏰ Mall Hours\n\nLatest runway-inspired fashion at accessible prices. New arrivals twice weekly.\n\n---\n\n🏷️ Women''s, Men''s, Kids\n💳 Mall gift cards accepted', NULL, 'Zara is one of mall''s largest stores (8,000 sq ft). Located near central entrance. New inventory Tuesdays and Fridays. Return policy: 30 days with receipt. Popular items sell out fast. Dressing rooms can have long waits on weekends - go early.', 1),
    
    (v_card_id, v_default_category, 'H&M', E'**Affordable Fashion for Everyone**\n\n📍 Level 1, Store #108\n⏰ Mall Hours\n\nTrendy, sustainable fashion at great prices. Features Conscious Collection made from recycled materials.\n\n---\n\n🏷️ Women''s, Men''s, Kids, Home\n💳 Student discount 15% (with ID)', NULL, 'H&M has 10,000 sq ft on Level 1. Garment recycling program - bring old clothes for 15% off coupon. Divided (teen) section at back of store. Home collection launched 2024. Member rewards program offers free shipping online.', 2),
    
    (v_card_id, v_default_category, 'Nordstrom', E'**Premium Department Store**\n\n📍 Level 4, Anchor Store\n⏰ 10am-9pm Mon-Sat, 11am-7pm Sun\n\nDesigner brands, exceptional service, and free alterations. Personal stylists available by appointment.\n\n---\n\n🏷️ Full Department Store\n💳 Nordstrom Card earns 3x points\n🛋️ Café & Espresso Bar inside', NULL, 'Nordstrom is anchor store with 3 floors. Best shoe selection in mall. Alterations free on full-price items. Anniversary Sale in July - biggest discounts of year. Personal stylists free of charge. Nordstrom Rack outlet is 5 miles away on Oak Street.', 3),
    
    (v_card_id, v_default_category, 'J.Crew', E'**Classic American Style**\n\n📍 Level 1, Store #124\n⏰ Mall Hours\n\nTimeless preppy fashion with modern updates. Known for quality basics and excellent suiting.\n\n---\n\n🏷️ Men''s, Women''s\n💳 J.Crew Rewards: 15% off first order', NULL, 'J.Crew men''s section is comprehensive. Ludlow suit is bestseller for weddings and interviews. Free hemming on full-price pants. Factory outlet (lower prices, different quality) is across town. Sale section at back of store.', 4),
    
    (v_card_id, v_default_category, 'Apple Store', E'**Official Apple Retail Location**\n\n📍 Level 2, Store #215\n⏰ Mall Hours\n\nLatest iPhones, Macs, iPads, and accessories. Genius Bar support and Today at Apple workshops.\n\n---\n\n🏷️ Electronics\n🔧 Genius Bar: Book online\n📱 Trade-in available', NULL, 'Apple Store is always busy - book Genius Bar online before visiting. Today at Apple workshops are free (photography, music, coding). Trade-in values updated weekly. Education discount for students. New iPhone launches have lines - preorder for pickup.', 5),
    
    (v_card_id, v_default_category, 'Best Buy', E'**Electronics Superstore**\n\n📍 Level 2, Store #201\n⏰ Mall Hours\n\nTVs, computers, appliances, and smart home tech. Expert advice and installation services.\n\n---\n\n🏷️ Electronics, Appliances\n🛠️ Geek Squad support\n💳 Best Buy Credit: 18 months 0% APR', NULL, 'Best Buy is 25,000 sq ft, mall''s largest electronics store. Price match policy - they''ll match Amazon. Open-box deals in dedicated section near entrance. Geek Squad can do home installation. Totaltech membership ($200/year) includes free installation and extended warranties.', 6),
    
    (v_card_id, v_default_category, 'Food Court', E'**Quick Bites & Global Flavors**\n\n📍 Level 2, Center Court\n⏰ 10am-9pm daily\n\n**12 Restaurants:**\n- Panda Express (Chinese)\n- Chick-fil-A (Chicken)\n- Sbarro (Pizza)\n- Chipotle (Mexican)\n- Subway (Sandwiches)\n- Auntie Anne''s (Pretzels)\n- + 6 more\n\n---\n\n🪑 Seating: 500+ seats\n👶 High chairs available', NULL, 'Food court busiest 12-2pm, try going at 11:30 or after 2pm. Chick-fil-A closed Sundays. Halal option: Gyro Palace. Vegetarian-friendly: Chipotle, Indian Kitchen. Panda Express usually has shortest line. Free WiFi throughout.', 7),
    
    (v_card_id, v_default_category, 'The Cheesecake Factory', E'**Full-Service Restaurant**\n\n📍 Level 2, Store #250\n⏰ 11am-11pm Mon-Thu, 11am-12am Fri-Sat, 10am-10pm Sun\n\n250+ menu items and legendary cheesecakes. Reservations recommended for dinner.\n\n---\n\n🏷️ American, Full Bar\n📱 Waitlist: Yelp app\n🎂 30+ cheesecake varieties', NULL, 'Cheesecake Factory has huge portions - shareable. Average wait Friday/Saturday dinner is 45-60 minutes. Get on Yelp waitlist remotely. Lunch specials 11am-3pm weekdays are good value. SkinnyLicious menu for lighter options. Cheesecake to-go available at counter without wait.', 8),
    
    (v_card_id, v_default_category, 'Guest Services', E'**We''re Here to Help**\n\n📍 Level 1, Near Main Entrance\n⏰ Mall Hours\n\n**Services:**\n- Wheelchair & stroller rental\n- Gift cards (accepted at all stores)\n- Package holding\n- Lost & found\n- Information & directions\n\n---\n\n📞 Call: (555) 123-MALL\n💳 Mall gift cards: $10-$500', NULL, 'Guest Services staffed with multilingual associates (Spanish, Mandarin). Strollers $5/day, wheelchairs free with ID. Will hold packages while you shop (free, up to 4 hours). Lost children brought here - ask for security escort. Charging stations for phones also available.', 9),
    
    (v_card_id, v_default_category, 'Parking & Valet', E'**Convenient Parking Options**\n\n📍 Garage Levels P1-P4\n⏰ 6am-11pm\n\n**Rates:**\n- First 3 hours: FREE with validation\n- After 3 hours: $3/hour\n- Daily max: $20\n- Valet: $15 (Level 1 entrance)\n\n---\n\n🚗 5,000 parking spaces\n🔌 EV charging: Level P1, 20 spots\n✅ Validation at any register', NULL, 'Best parking: P2 near elevators to Level 1. Most spaces on P3 and P4 but further walk. EV charging is free for first 2 hours, then $2/hour. Valet is at main entrance, tip is customary ($3-5). Lost car? Security can drive you around to find it.', 10),
    
    (v_card_id, v_default_category, 'AMC Theatres', E'**16-Screen Cinema**\n\n📍 Level 3, Entertainment Wing\n⏰ Showtimes vary\n\nIMAX, Dolby Cinema, and standard screens. Dine-in theater with full menu and bar.\n\n---\n\n🎬 **Ticket Prices:**\n- Adult: $16\n- Child (under 12): $12\n- Tuesday discount: $8 all seats\n\n📱 Reserve seats: AMC app\n🍿 A-List: $24/month unlimited movies', NULL, 'AMC has 3 premium formats: IMAX (screen 1), Dolby Cinema (screen 3), Prime at AMC (screen 5). Dine-in theaters are 12-16. Best seats: center, 2/3 back. Tuesday $8 tickets are very popular - buy online. Free refills on large popcorn and drinks.', 11),
    
    (v_card_id, v_default_category, 'Dave & Buster''s', E'**Eat, Drink, Play, Watch**\n\n📍 Level 3, Store #310\n⏰ 11am-12am Sun-Thu, 11am-2am Fri-Sat\n\n200+ arcade games, full restaurant, sports bar with giant screens. Power Card games and prize redemption.\n\n---\n\n🏷️ Entertainment, Restaurant, Bar\n🎮 Half-price games: Wed after 9pm\n👶 All ages until 10pm', NULL, 'Dave & Buster''s is 40,000 sq ft - mall''s largest entertainment venue. Wednesday half-price games is best value. Power Card can be reloaded online. VR experiences extra charge. Birthday party packages available (must book ahead). Full bar - 21+ after 10pm.', 12),
    
    (v_card_id, v_default_category, 'Sephora', E'**Beauty Superstore**\n\n📍 Level 1, Store #130\n⏰ Mall Hours\n\nMakeup, skincare, fragrance, and hair care from 200+ brands. Beauty classes and free makeovers.\n\n---\n\n🏷️ Beauty, Skincare, Fragrance\n💄 Free makeovers (no purchase required)\n💳 Beauty Insider: Free to join, earn points', NULL, 'Sephora offers free 15-minute makeovers - great before events. Full makeover ($50) redeemable toward purchase. Beauty Insider VIB status at $350/year spending. Fragrance section has testing strips. Return policy generous - 60 days even if opened. Mini sizes at checkout are good for travel.', 13),
    
    (v_card_id, v_default_category, 'Lush', E'**Fresh Handmade Cosmetics**\n\n📍 Level 1, Store #118\n⏰ Mall Hours\n\nBath bombs, soaps, skincare - all ethically made and mostly packaging-free. Vegan and cruelty-free.\n\n---\n\n🏷️ Beauty, Bath\n🌿 100% vegetarian, mostly vegan\n♻️ Bring back 5 black pots = free face mask', NULL, 'Lush is famous for bath bombs - can try demo sink in store. All products fresh, have use-by dates. Best sellers: bath bombs, Sleepy lotion, Karma perfume. Seasonal items (Halloween, Christmas) sell out fast. Staff do free hand/arm demos.', 14);

    RAISE NOTICE 'Successfully created Shopping Mall card with ID: %', v_card_id;
END $body$;


-- Register "Shopping Mall - List Mode" as content template
DO $reg$
DECLARE
    v_card_id UUID;
BEGIN
    -- Find the card we just created by name and user
    SELECT id INTO v_card_id
    FROM cards 
    WHERE user_id = '91acf5ca-f78b-4acd-bc75-98b85959ce62'::UUID
      AND name = 'Metropolitan Shopping Center'
    ORDER BY created_at DESC
    LIMIT 1;
    
    IF v_card_id IS NULL THEN
        RAISE WARNING 'Could not find card "Metropolitan Shopping Center" for template registration';
    ELSE
        -- Register or update the template
        INSERT INTO content_templates (slug, card_id, venue_type, is_featured, is_active, sort_order)
        VALUES ('shopping-mall-list', v_card_id, 'retail', false, true, 11)
        ON CONFLICT (slug) DO UPDATE SET
            card_id = EXCLUDED.card_id,
            venue_type = EXCLUDED.venue_type,
            sort_order = EXCLUDED.sort_order,
            updated_at = NOW();
        
        RAISE NOTICE 'Registered template: shopping-mall-list (card_id: %)', v_card_id;
    END IF;
END $reg$;


-- ==================================================================
-- Template 12: Tourist Landmark - Full Cards
-- Slug: tourist-landmark-inline | Venue: tourism
-- ==================================================================

-- Tourist Landmark - Full Cards Mode (Digital Access)
-- Template: Walking tour with featured stops
-- 
-- INSTRUCTIONS:
-- 1. Replace '91acf5ca-f78b-4acd-bc75-98b85959ce62' with actual user UUID
-- 2. Update image_url values with actual uploaded image URLs
-- 3. Run this SQL in Supabase SQL Editor or via psql

DO $body$
DECLARE
    v_user_id UUID := '91acf5ca-f78b-4acd-bc75-98b85959ce62'::UUID;
    v_card_id UUID;
    v_default_category UUID;
BEGIN
    -- Insert the card
    INSERT INTO cards (
        id, user_id, name, description, content_mode, is_grouped, group_display, billing_type,
        conversation_ai_enabled, ai_instruction, ai_knowledge_base,
        ai_welcome_general, ai_welcome_item, image_url
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
        'Welcome to the Historic Harbor District! I''m your virtual guide with centuries of stories to share. Ready to explore?',
        'You''ve found one of my favorite spots! Let me tell you about "{name}" - there''s a fascinating story here.',
        NULL
    ) RETURNING id INTO v_card_id;

    -- Create default category (hidden in flat mode, holds all content items)
    INSERT INTO content_items (id, card_id, parent_id, name, content, ai_knowledge_base, sort_order)
    VALUES (gen_random_uuid(), v_card_id, NULL, 'General', '', '', 1)
    RETURNING id INTO v_default_category;

    -- Insert tour stops (layer 2 under default category)
    INSERT INTO content_items (card_id, parent_id, name, content, image_url, ai_knowledge_base, sort_order) VALUES
    (v_card_id, v_default_category, 'Harbor Visitor Center', E'**Start Your Journey Here** 📍\n\n---\n\nBuilt in 1892 as the Harbor Master''s office, this beautifully restored building now serves as your gateway to the historic district.\n\n**Inside You''ll Find:**\n- Free maps and audio guides\n- Historical exhibits on harbor life\n- Restrooms and accessibility services\n- Gift shop with local crafts\n\n**Pro Tip:** Pick up a walking tour map here. The audio guide ($5) provides additional stories at each stop.\n\n---\n\n⏰ **Hours:** 9am-5pm daily (extended summer hours)\n🎟️ **Admission:** Free\n♿ **Fully accessible**', NULL, 'Building originally 1892, restored in 1978 with federal historic preservation grant. Harbor Master Captain William Shaw occupied this building for 40 years. Original telegraph equipment still displayed inside. Volunteer docents available 10am-3pm daily. Excellent views of harbor from second floor balcony.', 1),
    
    (v_card_id, v_default_category, 'Maritime & Whaling Museum', E'**A Living Testament to Seafaring History** ⚓\n\n---\n\nHoused in a restored 1830s candleworks factory, this museum tells the story of when this harbor was the whaling capital of the world.\n\n**Highlights:**\n- 46-foot sperm whale skeleton\n- Fully restored whaleboat with original harpoons\n- Scrimshaw collection (largest in the world)\n- Captain''s quarters recreation\n- Interactive navigation exhibits\n\nThe third floor offers panoramic harbor views through the original factory windows.\n\n---\n\n⏰ **Hours:** 10am-5pm (closed Tuesdays)\n🎟️ **Admission:** $18 adults, $12 children, free under 5\n♿ **Elevator to all floors**', NULL, 'Museum founded 1904, one of oldest maritime museums in US. Whale skeleton is "Kobo," a sperm whale that beached in 1891. Scrimshaw collection includes 1,200 pieces, many by famous whalers. The candleworks building produced whale oil candles 1834-1870, processed 10,000 barrels of whale oil annually. Docent tours at 11am and 2pm included with admission.', 2),
    
    (v_card_id, v_default_category, 'Old Harbor Lighthouse', E'**Guiding Ships Since 1802** 🏠\n\n---\n\nThis iconic lighthouse has stood sentinel over the harbor entrance for over 200 years. Climb 87 steps to the top for stunning views of the coastline and harbor.\n\n**The Lighthouse Story:**\nOriginally built in 1802, the current tower dates from 1857 when a storm destroyed the original structure. The Fresnel lens, imported from France, remains operational today.\n\n**Keeper''s Cottage:** Now a museum dedicated to lighthouse keepers and their families who lived in isolation.\n\n---\n\n⏰ **Hours:** 9am-4pm (last climb 3:30pm)\n🎟️ **Tower climb:** $8\n⚠️ **87 steps, not accessible**', NULL, 'Light visible 14 miles at sea. Fresnel lens is 3rd order, weighs 1,000 lbs. Last staffed keeper retired 1986 when light was automated. Ghost stories: Keeper Thomas Cobb allegedly still walks the tower on foggy nights (died 1892 saving a ship). The 1857 storm killed 47 people and sank 12 ships.', 3),
    
    (v_card_id, v_default_category, 'Captain''s Row Historic Houses', E'**Where Fortunes Were Made** 🏛️\n\n---\n\nThis elegant street of Federal and Greek Revival mansions was home to the wealthy sea captains who commanded whaling fleets and trading ships.\n\n**Notable Houses:**\n- **#15 Coffin House (1834):** Home of Captain Nathaniel Coffin, who circumnavigated the globe four times\n- **#23 Macy Mansion (1841):** Built with profits from Pacific whale oil trade; original furniture intact\n- **#31 Starbuck Hall (1846):** Largest house on the street, now a bed & breakfast\n\nThe cobblestones are original—carried as ship ballast from European ports.\n\n---\n\n🏠 **Interior tours:** Select homes open seasonally\n📸 **Photo tip:** Best lighting mid-afternoon\n🚶 **Walk both sides of the street**', NULL, 'Coffin, Macy, and Starbuck families dominated harbor commerce. The Starbucks (yes, related to the coffee company founder''s inspiration) owned 15 whaling ships at peak. Captain Coffin''s voyage logs are in the museum - remarkable accounts of Pacific islands. Most houses built 1830-1850 during whaling boom. Decline began when petroleum replaced whale oil in 1860s.', 4),
    
    (v_card_id, v_default_category, 'Straight Wharf & Fish Market', E'**Where Commerce Meets the Sea** 🐟\n\n---\n\nFor 350 years, this wharf has been the commercial heart of the harbor. Today, fishing boats still unload their daily catch, continuing a tradition that predates the United States itself.\n\n**What to See:**\n- Morning fish auction (5am-7am)\n- Working fishing boats and lobster traps\n- Historic ship chandlery (now a museum shop)\n- Artist studios in converted warehouses\n\n**What to Eat:**\nThe fish market sells the freshest catch in town. Try the legendary lobster rolls from the waterfront shack.\n\n---\n\n🐟 **Fish market:** 6am-6pm\n🦞 **Lobster shack:** 11am-8pm (cash only)\n📸 **Best photos:** Sunrise with fishing boats', NULL, 'Wharf originally built 1670, rebuilt many times. Fish auction is oldest continuous market in the country. Lobster shack run by same family for 4 generations - the MacNeils. Artist colony established 1920s when wharf buildings were cheap. Famous painters worked here including Edward Hopper (briefly). Summer sunset harbor cruises depart from pier end.', 5),
    
    (v_card_id, v_default_category, 'Seamen''s Bethel Chapel', E'**Sanctuary for Sailors** ⛪\n\n---\n\nThis 1832 chapel was built as a place of worship and refuge for sailors far from home. Herman Melville visited here, and the chapel features prominently in *Moby-Dick*.\n\n**Inside:**\n- Pulpit shaped like a ship''s bow (as described in Melville)\n- Memorial tablets to sailors lost at sea\n- Original pews with names of ships carved by sailors\n- Ceiling painted to resemble a ship''s hull (inverted)\n\n*"The Seamen''s Bethel... a small scattered congregation of sailors, and sailors'' wives and widows..."* — Moby-Dick, Ch. 7\n\n---\n\n⏰ **Hours:** 10am-4pm Mon-Sat, 12pm-4pm Sun\n🎟️ **Admission:** Donation suggested\n🤫 **Please maintain respectful silence**', NULL, 'Melville visited December 1840 before his own whaling voyage. Memorial tablets list 2,847 sailors lost from this port. Chapel still holds non-denominational services Sundays 10am. The bow pulpit was added 1857 to match Melville''s description (original was traditional). Ceiling mural by local artist depicts constellation navigation patterns used by whalers.', 6),
    
    (v_card_id, v_default_category, 'Historic Shipyard', E'**Where Great Ships Were Born** ⚙️\n\n---\n\nFrom 1780 to 1920, this shipyard launched over 400 vessels, from tiny fishing dories to mighty clipper ships. Today, traditional shipbuilding skills are still taught and practiced.\n\n**Live Demonstrations:**\n- Traditional wooden boat building (daily)\n- Sail making and rigging (weekends)\n- Blacksmith forge work (Wed & Sat)\n- Rope making demonstrations (Thu)\n\n**The Model Shop:** Watch craftsmen build detailed ship models using century-old techniques.\n\n---\n\n⏰ **Hours:** 9am-5pm daily\n🎟️ **Admission:** $12 adults, $8 children\n👷 **Special:** Try your hand at boat building (additional fee)', NULL, 'Shipyard founded by Jedidiah Barlow, built famous clipper ship "Sea Witch" (1846) which set speed records. Peak employment was 500 workers in 1850s. Decline came with switch from wood to iron ships. Current program trains 20 apprentices annually in traditional skills. A 30-foot wooden whaleboat is currently under construction - watch it take shape over months.', 7),
    
    (v_card_id, v_default_category, 'Harbor View Park & Memorial', E'**Reflection and Remembrance** 🌅\n\n---\n\nEnd your tour at this peaceful waterfront park, where benches face the harbor and the memorial honors those who shaped this community''s history.\n\n**The Memorial:**\nBronze sculptures depict a whaler, a captain, a lighthouse keeper, and a fisherman''s wife—representing the people who built this town.\n\n**The View:**\nOn clear days, you can see 15 miles out to sea. Watch for:\n- Commercial fishing boats returning with their catch\n- Historic tall ships (seasonal)\n- Seals on the outer rocks (bring binoculars)\n\n**Perfect Ending:** Grab a treat from the nearby ice cream shop and watch the sunset over the harbor.\n\n---\n\n⏰ **Park hours:** Dawn to dusk\n🎟️ **Admission:** Free\n🪑 **Benches throughout park**', NULL, 'Park created 1956 on site of old rope walk factory. Memorial dedicated 1976 for Bicentennial. Sculptor was local artist Martha Chase. Harbor seals are California sea lions actually - colony of about 40. Best sunset watching is late June when sun sets directly over lighthouse. Ice cream shop is Flanagan''s, open since 1889 - try the "Whaler''s Chocolate" flavor.', 8);

    RAISE NOTICE 'Successfully created Tourist Landmark card with ID: %', v_card_id;
END $body$;


-- Register "Tourist Landmark - Full Cards" as content template
DO $reg$
DECLARE
    v_card_id UUID;
BEGIN
    -- Find the card we just created by name and user
    SELECT id INTO v_card_id
    FROM cards 
    WHERE user_id = '91acf5ca-f78b-4acd-bc75-98b85959ce62'::UUID
      AND name = 'Historic Old Town Walking Tour'
    ORDER BY created_at DESC
    LIMIT 1;
    
    IF v_card_id IS NULL THEN
        RAISE WARNING 'Could not find card "Historic Old Town Walking Tour" for template registration';
    ELSE
        -- Register or update the template
        INSERT INTO content_templates (slug, card_id, venue_type, is_featured, is_active, sort_order)
        VALUES ('tourist-landmark-inline', v_card_id, 'tourism', false, true, 12)
        ON CONFLICT (slug) DO UPDATE SET
            card_id = EXCLUDED.card_id,
            venue_type = EXCLUDED.venue_type,
            sort_order = EXCLUDED.sort_order,
            updated_at = NOW();
        
        RAISE NOTICE 'Registered template: tourist-landmark-inline (card_id: %)', v_card_id;
    END IF;
END $reg$;


-- ==================================================================
-- Template 13: Zoo - Grid Mode
-- Slug: zoo-grid | Venue: tourism
-- ==================================================================

-- Zoo - Grouped Grid Gallery Mode (Digital Access)
-- Template: Zoo visitor guide with animal exhibits organized by habitat zone
-- 
-- INSTRUCTIONS:
-- 1. Replace '91acf5ca-f78b-4acd-bc75-98b85959ce62' with actual user UUID
-- 2. Update image_url values with actual uploaded image URLs
-- 3. Run this SQL in Supabase SQL Editor or via psql

DO $body$
DECLARE
    v_user_id UUID := '91acf5ca-f78b-4acd-bc75-98b85959ce62'::UUID;
    v_card_id UUID;
    v_cat_african UUID;
    v_cat_asian UUID;
    v_cat_polar UUID;
    v_cat_tropical UUID;
    v_cat_australian UUID;
BEGIN
    -- Insert the card
    INSERT INTO cards (
        id, user_id, name, description, content_mode, is_grouped, group_display, billing_type,
        conversation_ai_enabled, ai_instruction, ai_knowledge_base,
        ai_welcome_general, ai_welcome_item, image_url
    ) VALUES (
        gen_random_uuid(),
        v_user_id,
        'City Zoo - Animal Explorer Card',
        E'Welcome to **City Zoo**! Home to over 500 animals from 6 continents.\n\nUse this card to learn about our amazing animals. Tap any photo to discover fascinating facts, conservation status, and feeding times.\n\n🦁 AI Guide available for questions about any animal!',
        'grid',
        true,
        'expanded',
        'digital',
        true,
        'You are an enthusiastic zoo educator who loves sharing animal facts. Be engaging for all ages—from curious kids to adult learners. Share fun facts, conservation information, and help visitors plan their route. Encourage respect for animals and their habitats.',
        E'City Zoo - Founded 1920\nAnimals: 500+ individuals, 120 species\nArea: 80 acres with themed habitats\n\nZones: African Savanna, Asian Forest, Australian Outback, Polar World, Tropical Rainforest, North American Wildlife\n\nDaily shows: Sea lion show 11am & 2pm, Bird flight 12pm & 3pm\nFeeding times: Penguins 10:30am, Elephants 1pm, Big cats 3:30pm\n\nFacilities: Gift shop, 3 cafés, stroller rental, accessibility services\nConservation: Partner with WWF, Species Survival Plan participant',
        'Welcome to City Zoo! I''m your animal guide. Ask me about any animal, get feeding times, or let me help you plan your visit!',
        'Let me tell you about our {name}! They''re one of my favorites. What would you like to know?',
        NULL
    ) RETURNING id INTO v_card_id;

    -- Create habitat zone categories (Layer 1)
    INSERT INTO content_items (id, card_id, parent_id, name, content, ai_knowledge_base, sort_order)
    VALUES (gen_random_uuid(), v_card_id, NULL, '🦁 African Savanna', 'Lions, giraffes, and more from the African plains', 'The African Savanna zone features animals from sub-Saharan Africa in a 15-acre naturalistic habitat.', 1)
    RETURNING id INTO v_cat_african;

    INSERT INTO content_items (id, card_id, parent_id, name, content, ai_knowledge_base, sort_order)
    VALUES (gen_random_uuid(), v_card_id, NULL, '🐼 Asian Forest', 'Pandas, elephants, and red pandas', 'The Asian Forest zone showcases wildlife from across Asia in lush bamboo forests.', 2)
    RETURNING id INTO v_cat_asian;

    INSERT INTO content_items (id, card_id, parent_id, name, content, ai_knowledge_base, sort_order)
    VALUES (gen_random_uuid(), v_card_id, NULL, '🐧 Polar World', 'Penguins, polar bears, and arctic animals', 'Polar World features climate-controlled habitats replicating Arctic and Antarctic conditions.', 3)
    RETURNING id INTO v_cat_polar;

    INSERT INTO content_items (id, card_id, parent_id, name, content, ai_knowledge_base, sort_order)
    VALUES (gen_random_uuid(), v_card_id, NULL, '🦍 Tropical Rainforest', 'Gorillas, komodo dragons, and more', 'The Tropical Rainforest zone recreates humid jungle environments from around the world.', 4)
    RETURNING id INTO v_cat_tropical;

    INSERT INTO content_items (id, card_id, parent_id, name, content, ai_knowledge_base, sort_order)
    VALUES (gen_random_uuid(), v_card_id, NULL, '🐨 Australian Outback', 'Koalas and Australian wildlife', 'The Australian Outback zone features unique marsupials and wildlife from down under.', 5)
    RETURNING id INTO v_cat_australian;

    -- Insert African Savanna animals (Layer 2)
    INSERT INTO content_items (card_id, parent_id, name, content, image_url, ai_knowledge_base, sort_order) VALUES
    (v_card_id, v_cat_african, 'African Lion', E'**King of the Jungle** 🦁\n\n**Scientific Name:** *Panthera leo*\n**Conservation Status:** Vulnerable\n\nMeet Simba and Nala, our resident lion pride. Lions are the only cats that live in social groups called prides. Our pride includes 1 male and 2 females.\n\n**Did you know?** A lion''s roar can be heard from 5 miles away!\n\n⏰ **Feeding Time:** 3:30 PM daily', NULL, 'Simba (male, 8 years) arrived from San Diego Zoo in 2019. Nala and Sarabi (females, 6 years) are sisters from Dallas Zoo. Lions sleep 16-20 hours per day. Only 20,000 wild lions remain - down from 200,000 in 1950. Main threats: habitat loss, human-wildlife conflict. Our zoo supports lion conservation in Kenya.', 1),
    
    (v_card_id, v_cat_african, 'Reticulated Giraffe', E'**Towering Beauties** 🦒\n\n**Scientific Name:** *Giraffa camelopardalis reticulata*\n**Conservation Status:** Endangered\n\nAt 18 feet tall, our giraffes are the tallest animals at the zoo! Their long necks have the same number of vertebrae as humans - just much bigger.\n\n**Did you know?** A giraffe''s tongue is 18 inches long and prehensile (can grip things)!\n\n⏰ **Giraffe Feeding Experience:** 11:30 AM ($5 per person)', NULL, 'Tower of 4 giraffes: Twiga (female, 12), her daughter Amara (4), plus Geoffrey and Stretch (males). "Reticulated" refers to their net-like pattern. Each giraffe''s pattern is unique. They only need 30 minutes of sleep per day, taken in short naps. Heart weighs 25 pounds to pump blood up that long neck. Giraffe populations declined 40% in 30 years - a "silent extinction."', 2);

    -- Insert Asian Forest animals (Layer 2)
    INSERT INTO content_items (card_id, parent_id, name, content, image_url, ai_knowledge_base, sort_order) VALUES
    (v_card_id, v_cat_asian, 'Giant Panda', E'**Beloved Bamboo Muncher** 🐼\n\n**Scientific Name:** *Ailuropoda melanoleuca*\n**Conservation Status:** Vulnerable\n\nMei Mei spends up to 14 hours a day eating bamboo! Pandas have a specialized wrist bone that acts like a thumb to grip bamboo stalks.\n\n**Did you know?** Pandas poop up to 40 times a day!\n\n⏰ **Feeding Time:** 10:00 AM, 2:00 PM, 5:00 PM', NULL, 'Mei Mei (female, 12 years) on loan from China. Pandas are solitary in the wild. They eat 26-84 pounds of bamboo daily but digest only 20%. Conservation success story - upgraded from Endangered in 2016. China''s panda conservation program has increased wild population to 1,800+. Mei Mei''s favorite bamboo variety is arrow bamboo.', 1),
    
    (v_card_id, v_cat_asian, 'Asian Elephant', E'**Gentle Giants** 🐘\n\n**Scientific Name:** *Elephas maximus*\n**Conservation Status:** Endangered\n\nRuby (42) and Jade (18) are our two Asian elephants. Smaller than African elephants, they have smaller ears and only males have visible tusks.\n\n**Did you know?** Elephants can recognize themselves in mirrors - a sign of self-awareness!\n\n⏰ **Feeding Time:** 1:00 PM daily (Public feeding experience available)', NULL, 'Ruby arrived 1985, one of zoo''s oldest residents. Jade is her adopted daughter (not biological). Asian elephants smaller than African (8,000 vs 14,000 lbs). Only 40,000 remain in wild. Our elephants have 3-acre habitat with pool, mud wallow, and enrichment puzzles. They eat 200 lbs of food daily including hay, vegetables, and browse (tree branches).', 2),
    
    (v_card_id, v_cat_asian, 'Red Panda', E'**Firefox in the Trees** 🔴\n\n**Scientific Name:** *Ailurus fulgens*\n**Conservation Status:** Endangered\n\nDespite their name, red pandas are not closely related to giant pandas! Rusty and Scarlet spend most of their time in trees, using their long bushy tails for balance.\n\n**Did you know?** Red pandas were discovered 50 years before giant pandas and were the original "panda"!\n\n⏰ **Most Active:** Early morning and late afternoon', NULL, 'Rusty (male, 5) and Scarlet (female, 4) arrived from Cincinnati Zoo in 2021. Red pandas are closer relatives to raccoons than giant pandas. They have a false thumb like giant pandas - example of convergent evolution. Firefox browser was named after them! Fewer than 10,000 in wild. They primarily eat bamboo like giant pandas but are more omnivorous.', 3);

    -- Insert Polar World animals (Layer 2)
    INSERT INTO content_items (card_id, parent_id, name, content, image_url, ai_knowledge_base, sort_order) VALUES
    (v_card_id, v_cat_polar, 'Emperor Penguin', E'**Antarctic Survivor** 🐧\n\n**Scientific Name:** *Aptenodytes forsteri*\n**Conservation Status:** Near Threatened\n\nOur colony of 15 emperor penguins lives in a climate-controlled habitat that replicates Antarctic conditions. They''re the tallest penguin species, standing up to 4 feet tall!\n\n**Did you know?** Male emperors incubate eggs on their feet for 2 months without eating!\n\n⏰ **Feeding Time:** 10:30 AM daily', NULL, 'Colony established in 2010 with birds from Sea World. Can dive to 1,800 feet - deepest of any bird. They huddle together in -40°F temperatures, rotating positions so everyone gets warm center. Our habitat is kept at 28°F with artificial snow. Popular with kids - often their favorite animal. Climate change is primary threat.', 1),
    
    (v_card_id, v_cat_polar, 'Polar Bear', E'**Arctic Apex Predator** 🐻‍❄️\n\n**Scientific Name:** *Ursus maritimus*\n**Conservation Status:** Vulnerable\n\nNanook weighs 1,200 pounds and is an excellent swimmer. Polar bears are the largest land carnivores and are perfectly adapted to life on Arctic ice.\n\n**Did you know?** Polar bear fur isn''t white - it''s transparent! It just appears white because it reflects light.\n\n⏰ **Enrichment Time:** 2:30 PM daily (watch Nanook solve puzzles!)', NULL, 'Nanook (male, 18) born at zoo, never lived in wild. Polar bears are marine mammals - spend most of life on sea ice hunting seals. Black skin under transparent fur helps absorb heat. Only 26,000 polar bears remain. Climate change is existential threat - sea ice shrinking means less hunting time. Our habitat includes 100,000-gallon pool for swimming.', 2);

    -- Insert Tropical Rainforest animals (Layer 2)
    INSERT INTO content_items (card_id, parent_id, name, content, image_url, ai_knowledge_base, sort_order) VALUES
    (v_card_id, v_cat_tropical, 'Western Lowland Gorilla', E'**Our Closest Relatives** 🦍\n\n**Scientific Name:** *Gorilla gorilla gorilla*\n**Conservation Status:** Critically Endangered\n\nOur gorilla troop is led by Koko, a 380-pound silverback. Gorillas share 98% of their DNA with humans and live in family groups led by a dominant male.\n\n**Did you know?** Each gorilla has unique nose prints, like human fingerprints!\n\n⏰ **Best Viewing:** 11:00 AM - 1:00 PM (when most active)', NULL, 'Koko (silverback, 28) leads troop of 6 including 3 females and 2 juveniles. Born at zoo in 1996. Gorillas are gentle despite their size - primarily herbivorous. Silverback name comes from silver hair that develops on mature males'' backs. Only 100,000 western lowland gorillas remain. Main threats: poaching, disease, habitat loss. Zoo participates in Species Survival Plan.', 1),
    
    (v_card_id, v_cat_tropical, 'Komodo Dragon', E'**Living Dinosaur** 🦎\n\n**Scientific Name:** *Varanus komodoensis*\n**Conservation Status:** Endangered\n\nRaja is our 8-foot Komodo dragon - the world''s largest living lizard. These ancient predators have venomous saliva and can detect prey from 6 miles away.\n\n**Did you know?** Komodo dragons can eat 80% of their body weight in a single meal!\n\n⏰ **Feeding Time:** Fridays 2:00 PM (whole prey demonstration)', NULL, 'Raja (male, 15) arrived from Denver Zoo in 2015. Komodos only found on 4 Indonesian islands. Venomous bite prevents blood clotting - prey bleeds to death. Can run 13 mph in short bursts. Females can reproduce without males (parthenogenesis). Only 3,000-5,000 in wild. Feeding demonstration uses whole rabbits (warning given for sensitive viewers).', 2);

    -- Insert Australian Outback animals (Layer 2)
    INSERT INTO content_items (card_id, parent_id, name, content, image_url, ai_knowledge_base, sort_order) VALUES
    (v_card_id, v_cat_australian, 'Koala', E'**Sleepy Eucalyptus Lover** 🐨\n\n**Scientific Name:** *Phascolarctos cinereus*\n**Conservation Status:** Vulnerable\n\nBindi and Bluey are our resident koalas, sleeping up to 22 hours a day. They''re not actually bears - they''re marsupials who carry their babies in pouches!\n\n**Did you know?** Koalas have fingerprints nearly identical to human fingerprints!\n\n⏰ **Most Active:** Early morning (around opening time)', NULL, 'Bindi (female, 7) and Bluey (male, 5) both from Australian breeding program. Koalas sleep so much because eucalyptus is low in nutrition and takes lots of energy to digest. They have special bacteria in their gut to process eucalyptus toxins. Australian bushfires in 2019-2020 killed 30% of population. We grow 5 species of eucalyptus on-site for their diet.', 1);

    RAISE NOTICE 'Successfully created Zoo card with ID: %', v_card_id;
END $body$;

-- Register "Zoo - Grid Mode" as content template
DO $reg$
DECLARE
    v_card_id UUID;
BEGIN
    -- Find the card we just created by name and user
    SELECT id INTO v_card_id
    FROM cards 
    WHERE user_id = '91acf5ca-f78b-4acd-bc75-98b85959ce62'::UUID
      AND name = 'Wildwood Safari Park'
    ORDER BY created_at DESC
    LIMIT 1;
    
    IF v_card_id IS NULL THEN
        RAISE WARNING 'Could not find card "Wildwood Safari Park" for template registration';
    ELSE
        -- Register or update the template
        INSERT INTO content_templates (slug, card_id, venue_type, is_featured, is_active, sort_order)
        VALUES ('zoo-grid', v_card_id, 'tourism', false, true, 13)
        ON CONFLICT (slug) DO UPDATE SET
            card_id = EXCLUDED.card_id,
            venue_type = EXCLUDED.venue_type,
            sort_order = EXCLUDED.sort_order,
            updated_at = NOW();
        
        RAISE NOTICE 'Registered template: zoo-grid (card_id: %)', v_card_id;
    END IF;
END $reg$;


-- =================================================================
-- Deployment Summary
-- =================================================================
DO $$
DECLARE
    v_card_count INTEGER;
    v_template_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO v_card_count FROM cards WHERE user_id = '91acf5ca-f78b-4acd-bc75-98b85959ce62'::UUID;
    SELECT COUNT(*) INTO v_template_count FROM content_templates;
    
    RAISE NOTICE '=================================================================';
    RAISE NOTICE 'Template Deployment Complete!';
    RAISE NOTICE '=================================================================';
    RAISE NOTICE 'Total cards for user: %', v_card_count;
    RAISE NOTICE 'Total templates registered: %', v_template_count;
    RAISE NOTICE '';
    RAISE NOTICE 'Templates are now available in the Template Library.';
    RAISE NOTICE 'Go to Admin Portal > Template Management to manage them.';
END $$;
