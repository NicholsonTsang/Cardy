-- History Museum - Grouped List Mode (Digital Access)
-- Template: Museum with categorized exhibits by era
-- 
-- INSTRUCTIONS:
-- 1. Replace 'YOUR_USER_ID_HERE' with actual user UUID
-- 2. Update image_url values with actual uploaded image URLs
-- 3. Run this SQL in Supabase SQL Editor or via psql

DO $body$
DECLARE
    v_user_id UUID := 'YOUR_USER_ID_HERE'::UUID;
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
        ai_welcome_general, ai_welcome_item, image_url,
        is_access_enabled, access_token
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
        'Welcome to the City Heritage Museum! I can share fascinating stories about any artifact, explain historical context, suggest must-see highlights, or help plan your route. Which era interests you most?',
        'You''re looking at "{name}" - I can tell you how it was made, who used it, why it matters historically, or share surprising stories about it. What would you like to know?',
        NULL,
        TRUE,
        replace(replace(encode(gen_random_bytes(9), 'base64'), '+', '-'), '/', '_')
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

    -- Insert into content_templates for template library management
    INSERT INTO content_templates (slug, card_id, scenario_category, is_featured, is_active, sort_order)
    VALUES ('history-museum', v_card_id, 'cultural', true, true, 2);

    RAISE NOTICE 'Successfully created History Museum template with card ID: %', v_card_id;

END $body$;

