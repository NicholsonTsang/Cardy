-- Winery Tour - Cards Mode (Digital Access)
-- Template: Wine tasting experience with featured wines
-- 
-- INSTRUCTIONS:
-- 1. Replace 'YOUR_USER_ID_HERE' with actual user UUID
-- 2. Update image_url values with actual uploaded image URLs
-- 3. Run this SQL in Supabase SQL Editor or via psql

DO $body$
DECLARE
    v_user_id UUID := 'YOUR_USER_ID_HERE'::UUID;
    v_card_id UUID;
    v_cat_wines UUID;
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
        'Vineyard Estate Winery - Tasting Experience',
        E'**Welcome to Vineyard Estate**\n\nFamily-owned since 1978 | Award-winning wines\n\nExplore our estate-grown wines and discover the art of winemaking in the heart of wine country.\n\n📍 1200 Vineyard Road, Napa Valley\n⏰ Tastings: 10 AM - 5 PM daily\n📞 (555) WINERY1',
        'cards',
        false,
        NULL,
        'digital',
        true,
        'You are a knowledgeable sommelier and wine educator. Help guests understand wine characteristics, food pairings, and winemaking processes. Be approachable to beginners while engaging advanced enthusiasts. Share stories about the estate and winemaker. Never encourage overconsumption.',
        E'Vineyard Estate Winery - Napa Valley\nFounded: 1978 by the Martinez family\nEstate: 85 acres, 60 planted to vines\nElevation: 400-600 feet\n\nVarietals: Cabernet Sauvignon (signature), Chardonnay, Merlot, Sauvignon Blanc, Pinot Noir\n\nProduction: 15,000 cases annually\nFarming: Certified sustainable, transitioning to organic\n\nTasting room: Historic 1920s stone barn\nTours: 11 AM and 2 PM, reservations required\n\nTasting fee: $35 (waived with purchase)\nClub members: Complimentary tastings\n\nCurrent winemaker: Elena Martinez (third generation)\nAwards: 90+ points on multiple wines from Wine Spectator',
        'Welcome to Vineyard Estate! I can describe any wine''s tasting notes, suggest food pairings, share our winemaking story, explain what makes a vintage special, or help you choose a bottle. What interests you?',
        'Our {name} is lovely! I can describe the flavor profile, suggest the perfect food pairing, share its story, or compare it to others in our portfolio. What would you like to know?',
        NULL,
        TRUE,
        replace(replace(encode(gen_random_bytes(9), 'base64'), '+', '-'), '/', '_')
    ) RETURNING id INTO v_card_id;

    -- Hidden Category for flat cards
    INSERT INTO content_items (id, card_id, parent_id, name, content, ai_knowledge_base, sort_order)
    VALUES (gen_random_uuid(), v_card_id, NULL, 'Wines', '', '', 1)
    RETURNING id INTO v_cat_wines;

    -- Content Items
    INSERT INTO content_items (card_id, parent_id, name, content, image_url, ai_knowledge_base, sort_order) VALUES
    (v_card_id, v_cat_wines, 'Estate Cabernet Sauvignon 2021', E'**Our Flagship Wine**\n\n⭐ 94 Points - Wine Spectator\n\nDark ruby with violet edges. Aromas of blackcurrant, cedar, and dried herbs give way to a palate of ripe black cherry, espresso, and fine-grained tannins.\n\n---\n\n🍇 **Details**\n- 100% Estate Cabernet Sauvignon\n- 22 months in French oak (40% new)\n- Alcohol: 14.5%\n- Cases produced: 2,500\n\n🍽 **Pairs With**\nGrilled ribeye, braised short ribs, aged cheeses\n\n💰 **$85** per bottle\n\n*Cellar potential: 15-20 years*', NULL, 'Our best-selling wine and Elena''s pride. 2021 was exceptional vintage - warm days, cool nights, perfect ripeness. Grapes from oldest vines (planted 1985). French oak from Tronçais forest. Decant 1-2 hours or cellar 5+ years. Compare to Napa cabs at twice the price. Club allocation sells out quickly.', 1),
    
    (v_card_id, v_cat_wines, 'Reserve Chardonnay 2022', E'**Elegant & Complex**\n\n⭐ 92 Points - Wine Enthusiast\n\nGolden straw color with brilliant clarity. Notes of ripe pear, white flowers, and subtle oak spice. Creamy texture balanced by bright acidity.\n\n---\n\n🍇 **Details**\n- 100% Carneros Chardonnay\n- Barrel fermented, sur lie aged\n- Partial malolactic fermentation\n- Alcohol: 13.8%\n- Cases produced: 1,800\n\n🍽 **Pairs With**\nLobster, roasted chicken, creamy pasta dishes\n\n💰 **$48** per bottle\n\n*Drink now through 2028*', NULL, 'Sourced from cool Carneros region for bright acidity. Barrel fermented in neutral French oak - no heavy oak flavors. Partial malo gives creaminess without being buttery. Great food wine. 2022 had ideal conditions for white wines. Elena''s go-to recommendation for Chardonnay skeptics.', 2),
    
    (v_card_id, v_cat_wines, 'Merlot 2021', E'**Approachable & Velvety**\n\nDeep garnet with ruby highlights. Plush aromas of plum, chocolate, and violets. Soft, round tannins and a long, smooth finish.\n\n---\n\n🍇 **Details**\n- 92% Merlot, 8% Cabernet Franc\n- 18 months in French oak\n- Alcohol: 14.2%\n- Cases produced: 1,200\n\n🍽 **Pairs With**\nRoast duck, mushroom risotto, lamb chops\n\n💰 **$55** per bottle\n\n*Drink now through 2030*', NULL, 'Don''t let Merlot''s reputation fool you - this is serious wine. Touch of Cab Franc adds structure and floral notes. From hillside vineyard block with excellent drainage. More approachable young than our Cabernet. Great introduction to our red wines. Popular with wine club members.', 3),
    
    (v_card_id, v_cat_wines, 'Sauvignon Blanc 2023', E'**Crisp & Refreshing**\n\nPale straw with green tints. Vibrant aromas of grapefruit, lime zest, and fresh herbs. Bright acidity with a clean, mineral finish.\n\n---\n\n🍇 **Details**\n- 100% Estate Sauvignon Blanc\n- Stainless steel fermented\n- No oak contact\n- Alcohol: 13.2%\n- Cases produced: 800\n\n🍽 **Pairs With**\nOysters, goat cheese salad, ceviche, grilled fish\n\n💰 **$32** per bottle\n\n*Best enjoyed within 2-3 years*', NULL, 'Perfect summer sipper. Stainless steel preserves fruit purity. Night-harvested to retain acidity. New Zealand style - grassy and bright rather than oaky. Our most affordable wine. Great aperitif or with light seafood. Serve well-chilled (45°F).', 4),
    
    (v_card_id, v_cat_wines, 'Late Harvest Viognier 2022', E'**Dessert Wine**\n\n⭐ Limited Release\n\nBrilliant amber gold. Intense aromas of apricot, honey, and orange blossom. Lusciously sweet with balancing acidity.\n\n---\n\n🍇 **Details**\n- 100% Viognier, late harvested\n- Residual sugar: 12%\n- 375ml half bottle\n- Alcohol: 11.5%\n- Cases produced: 200\n\n🍽 **Pairs With**\nCrème brûlée, blue cheese, foie gras, peach tart\n\n💰 **$38** per half bottle\n\n*Cellar potential: 10+ years*', NULL, 'Made only in exceptional years when botrytis develops. Grapes left on vine extra month for concentrated sweetness. Natural acidity prevents cloying sweetness. Half bottles perfect for two people with dessert. Elena''s passion project - very limited. Compare to French Sauternes at fraction of price.', 5),
    
    (v_card_id, v_cat_wines, 'Winery Tour Experience', E'**Behind the Scenes**\n\nJoin us for an intimate tour of our estate and discover the art and science of winemaking.\n\n---\n\n📍 **Includes**\n- Vineyard walk among the vines\n- Historic barrel cellar tour\n- Production facility overview\n- Library wine tasting\n\n⏰ **Schedule**\nDaily at 11 AM and 2 PM\nDuration: 90 minutes\n\n👥 **Group Size**\nMaximum 12 guests\n\n💰 **$65** per person\n*(Includes 5-wine tasting)*\n\n**Reservations required**', NULL, 'Tours book up weeks ahead on weekends - reserve early. Morning tour great for photography (soft light in vineyard). Afternoon tour often led by family member. Barrel cellar dates to 1920s - original stone construction. Library tasting includes wines not normally available. Wear comfortable shoes for vineyard walk. Private tours available for groups of 6+.', 6);

    -- Insert into content_templates for template library management
    INSERT INTO content_templates (slug, card_id, scenario_category, is_featured, is_active, sort_order)
    VALUES ('winery-tour', v_card_id, 'food', true, true, 8);

    RAISE NOTICE 'Successfully created Winery Tour template with card ID: %', v_card_id;

END $body$;

