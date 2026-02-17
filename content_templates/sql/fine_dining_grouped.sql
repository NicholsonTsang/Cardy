-- Fine Dining Restaurant - Grouped List Mode (Digital Access)
-- Template: Tasting menu organized by course
-- 
-- INSTRUCTIONS:
-- 1. Replace 'YOUR_USER_ID_HERE' with actual user UUID
-- 2. Update image_url values with actual uploaded image URLs
-- 3. Run this SQL in Supabase SQL Editor or via psql

DO $body$
DECLARE
    v_user_id UUID := 'YOUR_USER_ID_HERE'::UUID;
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
        ai_welcome_general, ai_welcome_item, daily_scan_limit,
        is_access_enabled, access_token
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
        'Welcome to AURUM! I can explain any dish on the menu, suggest wine pairings, accommodate dietary needs, or share the story behind Chef Chen''s creations. How may I assist your dining experience?',
        'Our "{name}" is beautifully crafted! I can describe the ingredients, explain the technique, suggest the ideal wine pairing, or note any allergens. What would you like to know?',
        500,
        TRUE,
        replace(replace(encode(gen_random_bytes(9), 'base64'), '+', '-'), '/', '_')
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

    -- Insert into content_templates for template library management
    INSERT INTO content_templates (slug, card_id, scenario_category, is_featured, is_active, sort_order)
    VALUES ('fine-dining', v_card_id, 'food', true, true, 6);

    RAISE NOTICE 'Successfully created Fine Dining template with card ID: %', v_card_id;

END $body$;

