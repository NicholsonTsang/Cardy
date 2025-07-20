DO $$
DECLARE
    target_user_id UUID := '91acf5ca-f78b-4acd-bc75-98b85959ce62';
    -- Card IDs
    card1_id UUID := gen_random_uuid();
    card2_id UUID := gen_random_uuid();
    -- Card 1: First-layer content items
    c1_item1_id UUID := gen_random_uuid();
    c1_item2_id UUID := gen_random_uuid();
    c1_item3_id UUID := gen_random_uuid();
    -- Card 1: Second-layer content items
    c1_item1_child1_id UUID := gen_random_uuid();
    c1_item1_child2_id UUID := gen_random_uuid();
    c1_item1_child3_id UUID := gen_random_uuid();
    c1_item2_child1_id UUID := gen_random_uuid();
    c1_item2_child2_id UUID := gen_random_uuid();
    c1_item2_child3_id UUID := gen_random_uuid();
    c1_item3_child1_id UUID := gen_random_uuid();
    c1_item3_child2_id UUID := gen_random_uuid();
    c1_item3_child3_id UUID := gen_random_uuid();
    -- Card 2: First-layer content items
    c2_item1_id UUID := gen_random_uuid();
    c2_item2_id UUID := gen_random_uuid();
    c2_item3_id UUID := gen_random_uuid();
    -- Card 2: Second-layer content items
    c2_item1_child1_id UUID := gen_random_uuid();
    c2_item1_child2_id UUID := gen_random_uuid();
    c2_item1_child3_id UUID := gen_random_uuid();
    c2_item2_child1_id UUID := gen_random_uuid();
    c2_item2_child2_id UUID := gen_random_uuid();
    c2_item2_child3_id UUID := gen_random_uuid();
    c2_item3_child1_id UUID := gen_random_uuid();
    c2_item3_child2_id UUID := gen_random_uuid();
    c2_item3_child3_id UUID := gen_random_uuid();
BEGIN
-- Card 1
INSERT INTO cards (id, user_id, name, description, content_render_mode, qr_code_position, image_url, conversation_ai_enabled, ai_prompt)
VALUES (
    card1_id,
    target_user_id,
    'Treasures of the Ancient World',
    'Explore the wonders of ancient civilizations through this exclusive digital souvenir card. Delve into the mysteries of the past as you journey across continents and centuries, discovering the stories behind legendary artifacts, lost cities, and the people who shaped history. This card offers a curated selection of the world''s most fascinating treasures, from the golden tombs of Egypt to the intricate pottery of the Han Dynasty. Each section provides immersive multimedia content, expert insights, and interactive AI-guided conversations to bring the ancient world to life. Whether you are a history enthusiast or a curious traveler, this card is your gateway to a deeper understanding of humanity''s shared heritage.',
    'SINGLE_SERIES_MULTI_ITEMS',
    'BR',
    'https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=600&q=80',
    true,
    'You are an expert museum curator specializing in ancient civilizations. Provide engaging, educational, and accurate explanations about historical artifacts, their cultural significance, and the stories they tell. Adapt your responses to the visitor''s curiosity and encourage deeper exploration.'
);
-- Card 1: First-layer content items
INSERT INTO content_items (id, card_id, parent_id, name, content, image_url, ai_metadata, sort_order) VALUES
(c1_item1_id, card1_id, NULL, 'Egyptian Mysteries',
 'Egypt, the land of pharaohs and pyramids, has captivated the imagination of explorers and scholars for centuries. This section unveils the secrets of ancient Egypt, from the construction of monumental tombs to the daily lives of its people. Discover the symbolism behind hieroglyphics, the rituals of mummification, and the treasures buried with kings and queens. Through interactive media and expert commentary, you will gain a deeper appreciation for the ingenuity and spirituality that defined this remarkable civilization.',
 'https://images.unsplash.com/photo-1464983953574-0892a716854b?auto=format&fit=crop&w=600&q=80',
 'egypt, pharaohs, pyramids, mummies, hieroglyphics', 1),
(c1_item2_id, card1_id, NULL, 'Lost Cities of Mesopotamia',
 'Mesopotamia, often called the cradle of civilization, was home to some of the earliest cities and empires. In this section, explore the rise and fall of legendary cities like Babylon and Ur. Learn about the invention of writing, the development of law codes, and the architectural marvels that shaped the ancient Near East. Through vivid reconstructions and AI-guided storytelling, uncover the daily life, religious beliefs, and technological innovations that made Mesopotamia a beacon of human progress.',
 'https://images.unsplash.com/photo-1500534314209-a25ddb2bd429?auto=format&fit=crop&w=600&q=80',
 'mesopotamia, babylon, ur, cuneiform, ziggurat', 2),
(c1_item3_id, card1_id, NULL, 'Dynasties of the Far East',
 'Journey to ancient China and beyond, where powerful dynasties left a legacy of art, philosophy, and innovation. This section highlights the Han, Tang, and Ming dynasties, showcasing their achievements in pottery, calligraphy, and engineering. Discover the secrets of the Terracotta Army, the construction of the Great Wall, and the philosophies that shaped Eastern thought. Interactive exhibits and AI insights reveal how these dynasties influenced not only Asia but the entire world.',
 'https://images.unsplash.com/photo-1465101046530-73398c7f28ca?auto=format&fit=crop&w=600&q=80',
 'chinese dynasties, han, tang, ming, terracotta army, great wall', 3);
-- Card 1: Second-layer content items
INSERT INTO content_items (id, card_id, parent_id, name, content, image_url, ai_metadata, sort_order) VALUES
(c1_item1_child1_id, card1_id, c1_item1_id, 'The Great Pyramid of Giza',
 'The Great Pyramid of Giza stands as a testament to the architectural genius of ancient Egypt. Built over 4,500 years ago, it is the only surviving wonder of the original Seven Wonders of the Ancient World. This monumental structure was constructed as a tomb for Pharaoh Khufu and required the labor of thousands of skilled workers. Explore the mysteries of its construction, the alignment with celestial bodies, and the treasures that once filled its hidden chambers. The pyramid continues to inspire awe and curiosity, symbolizing the enduring legacy of Egyptian civilization.',
 'https://images.unsplash.com/photo-1502086223501-7ea6ecd79368?auto=format&fit=crop&w=600&q=80',
 'pyramid, giza, khufu, ancient engineering, tomb', 1),
(c1_item1_child2_id, card1_id, c1_item1_id, 'Mummification and the Afterlife',
 'Mummification was central to Egyptian beliefs about the afterlife. The process involved elaborate rituals to preserve the body, ensuring the soul''s safe journey to the next world. Priests performed ceremonies, and the deceased were buried with amulets, food, and treasures for use in the afterlife. This content explores the science behind mummification, the symbolism of funerary objects, and the spiritual significance of the journey through the underworld as depicted in the Book of the Dead.',
 'https://images.unsplash.com/photo-1519681393784-d120267933ba?auto=format&fit=crop&w=600&q=80',
 'mummification, afterlife, book of the dead, funerary, egyptian religion', 2),
(c1_item1_child3_id, card1_id, c1_item1_id, 'Hieroglyphics: The Language of the Gods',
 'Hieroglyphics were the sacred writing system of ancient Egypt, used for religious texts, monumental inscriptions, and official decrees. Each symbol carried deep meaning, representing sounds, objects, or concepts. The Rosetta Stone was key to deciphering this ancient script, unlocking the stories of pharaohs and daily life. This section delves into the art of hieroglyphic writing, its role in Egyptian culture, and the breakthroughs that allowed modern scholars to read the language of the gods.',
 'https://images.unsplash.com/photo-1465101178521-c1a9136a3fd8?auto=format&fit=crop&w=600&q=80',
 'hieroglyphics, writing, rosetta stone, egyptian language', 3),
(c1_item2_child1_id, card1_id, c1_item2_id, 'Babylon and the Hanging Gardens',
 'Babylon was one of the most influential cities of the ancient world, renowned for its grandeur and innovation. The legendary Hanging Gardens, considered one of the Seven Wonders, were said to be an engineering marvel of terraced greenery. This section explores the myths and realities of Babylon, its towering ziggurats, and the cultural achievements that made it a center of art, science, and governance in Mesopotamia.',
 'https://images.unsplash.com/photo-1465101046530-73398c7f28ca?auto=format&fit=crop&w=600&q=80',
 'babylon, hanging gardens, ziggurat, mesopotamia, wonders', 1),
(c1_item2_child2_id, card1_id, c1_item2_id, 'The Invention of Writing: Cuneiform',
 'Cuneiform, developed by the Sumerians, is one of the earliest known writing systems. Using wedge-shaped marks on clay tablets, it enabled the recording of laws, trade, literature, and history. This innovation transformed communication and administration in ancient Mesopotamia. Discover how cuneiform tablets were made, the stories they tell, and their impact on the development of civilization.',
 'https://images.unsplash.com/photo-1500534314209-a25ddb2bd429?auto=format&fit=crop&w=600&q=80',
 'cuneiform, sumerians, writing, tablets, ancient records', 2),
(c1_item2_child3_id, card1_id, c1_item2_id, 'Law and Order: The Code of Hammurabi',
 'The Code of Hammurabi is one of the oldest and most comprehensive legal codes in history. Inscribed on a basalt stele, it established rules for justice, trade, and daily life in Babylon. This section examines the significance of Hammurabi''s laws, their influence on later legal systems, and what they reveal about the values and challenges of ancient Mesopotamian society.',
 'https://images.unsplash.com/photo-1464983953574-0892a716854b?auto=format&fit=crop&w=600&q=80',
 'hammurabi, law code, babylon, justice, ancient law', 3),
(c1_item3_child1_id, card1_id, c1_item3_id, 'The Terracotta Army of Xi''an',
 'Discovered in 1974, the Terracotta Army is a vast collection of life-sized clay soldiers buried with China''s first emperor, Qin Shi Huang. Each figure is unique, reflecting the artistry and military organization of the Qin Dynasty. This section explores the purpose of the army, the techniques used in its creation, and the ongoing archaeological discoveries that continue to shed light on ancient China''s imperial ambitions.',
 'https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=600&q=80',
 'terracotta army, qin dynasty, xi''an, archaeology, china', 1),
(c1_item3_child2_id, card1_id, c1_item3_id, 'The Great Wall: Engineering Marvel',
 'The Great Wall of China stretches over 13,000 miles, a monumental feat of engineering and perseverance. Built over centuries by various dynasties, it served as both a defensive barrier and a symbol of unity. This section delves into the construction methods, the lives of the workers, and the strategic importance of the wall in protecting China from invasions.',
 'https://images.unsplash.com/photo-1519681393784-d120267933ba?auto=format&fit=crop&w=600&q=80',
 'great wall, china, engineering, defense, ming dynasty', 2),
(c1_item3_child3_id, card1_id, c1_item3_id, 'Art and Innovation in the Han Dynasty',
 'The Han Dynasty is celebrated for its artistic achievements and technological advancements. From delicate silk production to the invention of paper, the Han era shaped Chinese culture for centuries. This section highlights masterpieces of Han art, the development of the Silk Road, and the innovations that connected China to the wider world.',
 'https://images.unsplash.com/photo-1502086223501-7ea6ecd79368?auto=format&fit=crop&w=600&q=80',
 'han dynasty, silk road, paper, chinese art, innovation', 3);
-- Card 2
INSERT INTO cards (id, user_id, name, description, content_render_mode, qr_code_position, image_url, conversation_ai_enabled, ai_prompt)
VALUES (
    card2_id,
    target_user_id,
    'Wonders of the Natural World',
    'Embark on a breathtaking journey through the planet''s most extraordinary natural wonders. This digital souvenir card invites you to explore the awe-inspiring beauty and diversity of Earth, from towering mountains and lush rainforests to the mysterious depths of the oceans. Each section offers immersive multimedia experiences, scientific insights, and interactive AI-guided conversations that reveal the secrets of our natural world. Whether you are a nature lover, an adventurer, or a curious learner, this card provides a window into the forces that have shaped our environment and the remarkable life it sustains.',
    'SINGLE_SERIES_MULTI_ITEMS',
    'BR',
    'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=600&q=80',
    true,
    'You are a passionate naturalist and science communicator. Provide engaging, accurate, and accessible explanations about natural phenomena, ecosystems, and the importance of conservation. Inspire visitors to appreciate and protect the wonders of the natural world.'
);
-- Card 2: First-layer content items
INSERT INTO content_items (id, card_id, parent_id, name, content, image_url, ai_metadata, sort_order) VALUES
(c2_item1_id, card2_id, NULL, 'Majestic Mountains',
 'From the snow-capped peaks of the Himalayas to the rugged ranges of the Andes, mountains are among the most dramatic features of our planet. This section explores the geological forces that create mountains, the unique ecosystems they support, and the cultural significance they hold for people around the world. Discover the challenges faced by climbers, the adaptations of mountain wildlife, and the role of mountains in shaping weather and climate.',
 'https://images.unsplash.com/photo-1469474968028-56623f02e42e?auto=format&fit=crop&w=600&q=80',
 'mountains, himalayas, andes, geology, ecosystems, climate', 1),
(c2_item2_id, card2_id, NULL, 'Rainforests: Lungs of the Earth',
 'Rainforests are vibrant, life-sustaining ecosystems that cover only a small fraction of the Earth''s surface but harbor more than half of its plant and animal species. This section delves into the structure of rainforests, the incredible biodiversity they support, and their crucial role in regulating the planet''s climate. Learn about the threats facing these vital habitats and the efforts being made to conserve them for future generations.',
 'https://images.unsplash.com/photo-1501785888041-af3ef285b470?auto=format&fit=crop&w=600&q=80',
 'rainforest, biodiversity, conservation, climate, amazon, habitat', 2),
(c2_item3_id, card2_id, NULL, 'Oceans: The Blue Frontier',
 'Oceans cover more than 70% of the Earth''s surface and are home to an astonishing variety of life. This section invites you to dive into the mysteries of the deep, from coral reefs teeming with color to the dark, unexplored abyss. Discover the interconnectedness of marine ecosystems, the importance of oceans in regulating climate, and the urgent need to protect these fragile environments from pollution and overfishing.',
 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=600&q=80',
 'ocean, marine life, coral reef, climate, conservation, deep sea', 3);
-- Card 2: Second-layer content items
INSERT INTO content_items (id, card_id, parent_id, name, content, image_url, ai_metadata, sort_order) VALUES
(c2_item1_child1_id, card2_id, c2_item1_id, 'Mount Everest: Roof of the World',
 'Mount Everest, rising 8,848 meters above sea level, is the highest point on Earth. Its formidable slopes have challenged climbers for generations, symbolizing the ultimate test of human endurance and ambition. This section explores the geology of the Himalayas, the history of Everest expeditions, and the unique adaptations of plants and animals that survive in this extreme environment.',
 'https://images.unsplash.com/photo-1500534314209-a25ddb2bd429?auto=format&fit=crop&w=600&q=80',
 'everest, himalayas, climbing, altitude, geology', 1),
(c2_item1_child2_id, card2_id, c2_item1_id, 'The Andes: Spine of South America',
 'The Andes stretch over 7,000 kilometers along the western edge of South America, forming the longest continental mountain range in the world. This section highlights the diverse climates and cultures found along the Andes, from snow-capped volcanoes to lush valleys. Learn about the ancient civilizations that thrived here, the unique wildlife, and the geological forces that continue to shape the landscape.',
 'https://images.unsplash.com/photo-1469474968028-56623f02e42e?auto=format&fit=crop&w=600&q=80',
 'andes, south america, volcano, inca, wildlife', 2),
(c2_item1_child3_id, card2_id, c2_item1_id, 'Mountain Ecosystems and Climate',
 'Mountains create unique ecosystems that vary dramatically with altitude. This section examines how temperature, precipitation, and sunlight change from base to summit, influencing the distribution of plants and animals. Discover the importance of mountains as water sources, their role in weather patterns, and the challenges posed by climate change to these fragile environments.',
 'https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=600&q=80',
 'mountain ecosystem, climate, altitude, biodiversity, water', 3),
(c2_item2_child1_id, card2_id, c2_item2_id, 'Amazon Rainforest: Biodiversity Hotspot',
 'The Amazon Rainforest is the largest tropical forest on Earth, home to millions of species of plants, animals, and insects. This section explores the complex web of life in the Amazon, the importance of its rivers, and the threats posed by deforestation. Learn about the indigenous peoples who have lived in harmony with the forest for thousands of years.',
 'https://images.unsplash.com/photo-1501785888041-af3ef285b470?auto=format&fit=crop&w=600&q=80',
 'amazon, rainforest, biodiversity, indigenous, deforestation', 1),
(c2_item2_child2_id, card2_id, c2_item2_id, 'Rainforest Layers and Adaptations',
 'Rainforests are structured in layers, from the dark forest floor to the sunlit canopy. Each layer supports different forms of life, adapted to unique conditions. This section examines the strategies plants and animals use to survive, from climbing vines to camouflage and symbiotic relationships.',
 'https://images.unsplash.com/photo-1465101178521-c1a9136a3fd8?auto=format&fit=crop&w=600&q=80',
 'rainforest, canopy, adaptation, symbiosis, ecology', 2),
(c2_item2_child3_id, card2_id, c2_item2_id, 'Conservation and the Future of Rainforests',
 'Rainforests are under threat from logging, agriculture, and climate change. This section highlights global efforts to protect these vital ecosystems, from sustainable development to reforestation projects. Discover how individuals and communities can contribute to rainforest conservation and why it matters for the health of the planet.',
 'https://images.unsplash.com/photo-1519681393784-d120267933ba?auto=format&fit=crop&w=600&q=80',
 'conservation, rainforest, reforestation, climate change, sustainability', 3),
(c2_item3_child1_id, card2_id, c2_item3_id, 'Coral Reefs: Rainforests of the Sea',
 'Coral reefs are among the most diverse and productive ecosystems on Earth, supporting thousands of marine species. This section explores the structure of coral reefs, their role in coastal protection, and the threats they face from warming oceans and pollution. Learn about the symbiotic relationships that sustain reef life and the importance of conservation.',
 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=600&q=80',
 'coral reef, marine life, biodiversity, conservation, ocean', 1),
(c2_item3_child2_id, card2_id, c2_item3_id, 'Deep Sea Exploration',
 'The deep sea is one of the least explored regions on the planet, home to extraordinary creatures adapted to darkness and high pressure. This section delves into the technology used to explore the ocean depths, the discoveries of new species, and the mysteries that remain hidden beneath the waves.',
 'https://images.unsplash.com/photo-1464983953574-0892a716854b?auto=format&fit=crop&w=600&q=80',
 'deep sea, exploration, marine biology, technology, discovery', 2),
(c2_item3_child3_id, card2_id, c2_item3_id, 'Oceans and Climate Regulation',
 'Oceans play a crucial role in regulating the Earth''s climate by absorbing heat and carbon dioxide. This section examines the science of ocean currents, the impact of climate change on marine environments, and the importance of protecting the oceans for future generations.',
 'https://images.unsplash.com/photo-1465101046530-73398c7f28ca?auto=format&fit=crop&w=600&q=80',
 'ocean, climate, currents, carbon cycle, environment', 3);
-- Update image for 'Oceans: The Blue Frontier' (Card 2, first-layer content item)
UPDATE content_items
SET image_url = 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=600&q=80'
WHERE name = 'Oceans: The Blue Frontier';
END $$;
