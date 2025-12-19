-- Zoo - Grouped Grid Gallery Mode (Digital Access)
-- Template: Zoo visitor guide with animal exhibits organized by habitat zone
-- 
-- INSTRUCTIONS:
-- 1. Replace 'YOUR_USER_ID_HERE' with actual user UUID
-- 2. Update image_url values with actual uploaded image URLs
-- 3. Run this SQL in Supabase SQL Editor or via psql

DO $body$
DECLARE
    v_user_id UUID := 'YOUR_USER_ID_HERE'::UUID;
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
        ai_welcome_general, ai_welcome_item, image_url,
        is_access_enabled, access_token
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
        'Welcome to City Zoo! I can share fun facts about any animal, tell you feeding times, suggest the best route to see everything, or help you find specific animals. What would you like to explore?',
        'Our {name} is amazing! I can share fun facts, conservation status, their individual story, feeding times, or tips for the best viewing spot. What interests you?',
        NULL,
        TRUE,
        replace(replace(encode(gen_random_bytes(9), 'base64'), '+', '-'), '/', '_')
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

    -- Insert into content_templates for template library management
    INSERT INTO content_templates (slug, card_id, venue_type, is_featured, is_active, sort_order)
    VALUES ('zoo', v_card_id, 'cultural', true, true, 5);

    RAISE NOTICE 'Successfully created Zoo template with card ID: %', v_card_id;

END $body$;
