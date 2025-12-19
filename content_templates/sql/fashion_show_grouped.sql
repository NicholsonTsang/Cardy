-- Fashion Show - Grouped List Mode (Digital Access)
-- Template: Fashion show lookbook with looks by segment
-- 
-- INSTRUCTIONS:
-- 1. Replace 'YOUR_USER_ID_HERE' with actual user UUID
-- 2. Update image_url values with actual uploaded image URLs
-- 3. Run this SQL in Supabase SQL Editor or via psql

DO $body$
DECLARE
    v_user_id UUID := 'YOUR_USER_ID_HERE'::UUID;
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
        ai_welcome_general, ai_welcome_item, image_url,
        is_access_enabled, access_token
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
        'Welcome to Maison Élise''s Spring/Summer 2025 show! I can explain the creative inspiration, describe fabrics and techniques, share details about any look, or give you behind-the-scenes stories. What captivates you?',
        'Look {name} is stunning! I can describe the fabrics used, explain the construction technique, share the designer''s inspiration, or tell you how it connects to the collection''s theme. What interests you?',
        NULL,
        TRUE,
        replace(replace(encode(gen_random_bytes(9), 'base64'), '+', '-'), '/', '_')
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

    -- Insert into content_templates for template library management
    INSERT INTO content_templates (slug, card_id, venue_type, is_featured, is_active, sort_order)
    VALUES ('fashion-show', v_card_id, 'events', true, true, 11);

    RAISE NOTICE 'Successfully created Fashion Show template with card ID: %', v_card_id;

END $body$;

