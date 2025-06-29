-- Placeholder User ID (replace with an actual user_id from your auth.users table if needed)
DO $$
DECLARE
  v_user_id UUID := '10cd527e-9c09-42e8-be43-e1cf2cc28f3a'; -- Example static UUID
  v_card_id_1 UUID;
  v_card_id_2 UUID;
  v_card_id_3 UUID;
  v_card_id_4 UUID;
  v_card_id_5 UUID;
  v_ci_parent_1_1 UUID;
  v_ci_parent_1_2 UUID;
  v_ci_parent_1_3 UUID;
  v_ci_parent_1_4 UUID;
  v_ci_parent_1_5 UUID;
  v_ci_parent_2_1 UUID;
  v_ci_parent_2_2 UUID;
  v_ci_parent_2_3 UUID;
  v_ci_parent_2_4 UUID;
  v_ci_parent_2_5 UUID;
  v_ci_parent_3_1 UUID;
  v_ci_parent_3_2 UUID;
  v_ci_parent_3_3 UUID;
  v_ci_parent_3_4 UUID;
  v_ci_parent_3_5 UUID;
  v_ci_parent_4_1 UUID;
  v_ci_parent_4_2 UUID;
  v_ci_parent_4_3 UUID;
  v_ci_parent_4_4 UUID;
  v_ci_parent_4_5 UUID;
  v_ci_parent_5_1 UUID;
  v_ci_parent_5_2 UUID;
  v_ci_parent_5_3 UUID;
  v_ci_parent_5_4 UUID;
  v_ci_parent_5_5 UUID;
  -- Variables for issued cards functionality
  v_batch_id_1_1 UUID;
  v_batch_id_1_2 UUID;
  v_batch_id_2_1 UUID;
  v_batch_id_2_2 UUID;
  v_batch_id_3_1 UUID;
  v_issued_card_id UUID;
  v_print_request_id UUID;
BEGIN

  -- Create user profile for demonstration
  INSERT INTO public.user_profiles (
    user_id, 
    public_name, 
    bio, 
    company_name, 
    full_name, 
    verification_status, 
    supporting_documents, 
    admin_feedback, 
    verified_at
  ) VALUES (
    v_user_id,
    'Adventure Creator',
    'Passionate about creating immersive card experiences that inspire exploration and learning.',
    'ExploreMore Inc.',
    'Alex Johnson',
    'APPROVED',
    ARRAY['https://example.com/docs/identity.pdf', 'https://example.com/docs/business-license.pdf'],
    'All documents verified successfully. Great profile!',
    NOW() - INTERVAL '5 days'
  );

  -- Card 1: Adventure Travel Guide (AI enabled)
  INSERT INTO public.cards (user_id, name, description, image_urls, conversation_ai_enabled, ai_prompt)
  VALUES (
    v_user_id, 
    'Adventure Series', 
    'Explore breathtaking destinations and outdoor adventures around the world.',
    ARRAY['https://images.unsplash.com/photo-1464822759844-d150ad6d1dff?w=400&h=300&fit=crop']::TEXT[],
    TRUE, 
    'You are an adventure travel expert who helps people discover amazing outdoor experiences. Answer questions about destinations, activities, gear, and travel tips with enthusiasm and practical knowledge.'
  )
  RETURNING id INTO v_card_id_1;

  -- Content Items for Card 1 - 5 parent items with 7+ children each
  
  -- Parent 1.1: Mountain Expeditions (8 children)
  INSERT INTO public.content_items (card_id, name, content, image_urls, sort_order)
  VALUES (v_card_id_1, 'Mountain Expeditions', 'Conquer the world''s most challenging peaks with expert mountaineering guidance.', ARRAY['https://picsum.photos/seed/c1p1/600/400'], 0)
  RETURNING id INTO v_ci_parent_1_1;
  
  INSERT INTO public.content_items (card_id, parent_id, name, content, image_urls, sort_order)
  VALUES 
    (v_card_id_1, v_ci_parent_1_1, 'Everest Base Camp', 'Trek to the base of the world''s highest mountain through stunning Himalayan landscapes.', ARRAY['https://picsum.photos/seed/c1p1c1/600/400'], 0),
    (v_card_id_1, v_ci_parent_1_1, 'K2 Summit Attempt', 'The ultimate mountaineering challenge on the world''s second-highest and most technical peak.', ARRAY['https://picsum.photos/seed/c1p1c2/600/400'], 1),
    (v_card_id_1, v_ci_parent_1_1, 'Alpine Climbing Course', 'Master technical rock and ice climbing skills in the European Alps.', ARRAY['https://picsum.photos/seed/c1p1c3/600/400'], 2),
    (v_card_id_1, v_ci_parent_1_1, 'Denali Expedition', 'North America''s highest peak demands extreme cold weather mountaineering expertise.', ARRAY['https://picsum.photos/seed/c1p1c4/600/400'], 3),
    (v_card_id_1, v_ci_parent_1_1, 'Aconcagua Ascent', 'South America''s tallest mountain offers high-altitude acclimatization training.', ARRAY['https://picsum.photos/seed/c1p1c5/600/400'], 4),
    (v_card_id_1, v_ci_parent_1_1, 'Mont Blanc Circuit', 'Classic European trek combining stunning scenery with moderate technical challenges.', ARRAY['https://picsum.photos/seed/c1p1c6/600/400'], 5),
    (v_card_id_1, v_ci_parent_1_1, 'Kilimanjaro Routes', 'Multiple pathway options to Africa''s highest summit through diverse ecosystems.', ARRAY['https://picsum.photos/seed/c1p1c7/600/400'], 6),
    (v_card_id_1, v_ci_parent_1_1, 'Rescue Techniques', 'Essential mountain rescue skills including rope work and emergency medical care.', ARRAY['https://picsum.photos/seed/c1p1c8/600/400'], 7);

  -- Parent 1.2: Ocean Adventures (7 children)
  INSERT INTO public.content_items (card_id, name, content, image_urls, sort_order)
  VALUES (v_card_id_1, 'Ocean Adventures', 'Dive into the depths and explore marine ecosystems around the globe.', ARRAY['https://picsum.photos/seed/c1p2/600/400'], 1)
  RETURNING id INTO v_ci_parent_1_2;
  
  INSERT INTO public.content_items (card_id, parent_id, name, content, image_urls, sort_order)
  VALUES 
    (v_card_id_1, v_ci_parent_1_2, 'Scuba Certification', 'Professional diving certification from beginner to advanced technical diving levels.', ARRAY['https://picsum.photos/seed/c1p2c1/600/400'], 0),
    (v_card_id_1, v_ci_parent_1_2, 'Coral Reef Exploration', 'Discover vibrant underwater ecosystems teeming with tropical marine life.', ARRAY['https://picsum.photos/seed/c1p2c2/600/400'], 1),
    (v_card_id_1, v_ci_parent_1_2, 'Wreck Diving', 'Explore sunken ships and underwater archaeological sites with historical significance.', ARRAY['https://picsum.photos/seed/c1p2c3/600/400'], 2),
    (v_card_id_1, v_ci_parent_1_2, 'Night Diving', 'Experience the ocean''s nocturnal transformation with specialized night diving techniques.', ARRAY['https://picsum.photos/seed/c1p2c4/600/400'], 3),
    (v_card_id_1, v_ci_parent_1_2, 'Deep Water Diving', 'Advanced technical diving to depths exceeding 40 meters with proper safety protocols.', ARRAY['https://picsum.photos/seed/c1p2c5/600/400'], 4),
    (v_card_id_1, v_ci_parent_1_2, 'Underwater Photography', 'Capture stunning marine life and underwater landscapes with professional techniques.', ARRAY['https://picsum.photos/seed/c1p2c6/600/400'], 5),
    (v_card_id_1, v_ci_parent_1_2, 'Marine Conservation', 'Learn about ocean protection efforts and participate in reef restoration projects.', ARRAY['https://picsum.photos/seed/c1p2c7/600/400'], 6);

  -- Parent 1.3: Jungle Safari (7 children)
  INSERT INTO public.content_items (card_id, name, content, image_urls, sort_order)
  VALUES (v_card_id_1, 'Jungle Safari', 'An expedition into the wild rainforest ecosystem.', ARRAY['https://picsum.photos/seed/c1p3/600/400'], 2)
  RETURNING id INTO v_ci_parent_1_3;
  
  INSERT INTO public.content_items (card_id, parent_id, name, content, image_urls, sort_order)
  VALUES 
    (v_card_id_1, v_ci_parent_1_3, 'Wildlife Tracking', 'Learn to identify animal tracks, scat, and feeding signs in dense vegetation.', ARRAY['https://picsum.photos/seed/c1p3c1/600/400'], 0),
    (v_card_id_1, v_ci_parent_1_3, 'Canopy Exploration', 'Tree-top adventures using zip lines and suspension bridges 30m above ground.', ARRAY['https://picsum.photos/seed/c1p3c2/600/400'], 1),
    (v_card_id_1, v_ci_parent_1_3, 'River Expeditions', 'Navigate jungle waterways by kayak to spot caimans and exotic birds.', ARRAY['https://picsum.photos/seed/c1p3c3/600/400'], 2),
    (v_card_id_1, v_ci_parent_1_3, 'Indigenous Culture', 'Experience traditional hunting techniques and medicinal plant knowledge.', ARRAY['https://picsum.photos/seed/c1p3c4/600/400'], 3),
    (v_card_id_1, v_ci_parent_1_3, 'Survival Skills', 'Essential jungle survival including shelter building and water purification.', ARRAY['https://picsum.photos/seed/c1p3c5/600/400'], 4),
    (v_card_id_1, v_ci_parent_1_3, 'Night Sounds Safari', 'Identify nocturnal jungle animals by their distinctive calls and movements.', ARRAY['https://picsum.photos/seed/c1p3c6/600/400'], 5),
    (v_card_id_1, v_ci_parent_1_3, 'Conservation Projects', 'Participate in rainforest preservation and wildlife protection initiatives.', ARRAY['https://picsum.photos/seed/c1p3c7/600/400'], 6);

  -- Parent 1.4: Desert Expedition (8 children)
  INSERT INTO public.content_items (card_id, name, content, image_urls, sort_order)
  VALUES (v_card_id_1, 'Desert Expedition', 'Navigate vast desert landscapes and learn survival techniques in extreme conditions.', ARRAY['https://picsum.photos/seed/c1p4/600/400'], 3)
  RETURNING id INTO v_ci_parent_1_4;
  
  INSERT INTO public.content_items (card_id, parent_id, name, content, image_urls, sort_order)
  VALUES 
    (v_card_id_1, v_ci_parent_1_4, 'Water Conservation', 'Advanced techniques for finding, purifying, and conserving water in arid zones.', ARRAY['https://picsum.photos/seed/c1p4c1/600/400'], 0),
    (v_card_id_1, v_ci_parent_1_4, 'Navigation Methods', 'Use of stars, sun position, and landmark recognition without GPS technology.', ARRAY['https://picsum.photos/seed/c1p4c2/600/400'], 1),
    (v_card_id_1, v_ci_parent_1_4, 'Extreme Heat Management', 'Thermoregulation strategies and heat illness prevention in 50°C+ temperatures.', ARRAY['https://picsum.photos/seed/c1p4c3/600/400'], 2),
    (v_card_id_1, v_ci_parent_1_4, 'Desert Wildlife Encounters', 'Safe interaction with venomous snakes, scorpions, and desert predators.', ARRAY['https://picsum.photos/seed/c1p4c4/600/400'], 3),
    (v_card_id_1, v_ci_parent_1_4, 'Sand Dune Traversal', 'Efficient movement techniques across shifting sand terrain and steep slopes.', ARRAY['https://picsum.photos/seed/c1p4c5/600/400'], 4),
    (v_card_id_1, v_ci_parent_1_4, 'Emergency Shelter', 'Construction of life-saving shade structures using minimal available materials.', ARRAY['https://picsum.photos/seed/c1p4c6/600/400'], 5),
    (v_card_id_1, v_ci_parent_1_4, 'Sandstorm Survival', 'Protection protocols during extreme weather events with zero visibility.', ARRAY['https://picsum.photos/seed/c1p4c7/600/400'], 6),
    (v_card_id_1, v_ci_parent_1_4, 'Oasis Discovery', 'Identify natural water sources and understand desert ecosystem patterns.', ARRAY['https://picsum.photos/seed/c1p4c8/600/400'], 7);

  -- Parent 1.5: Arctic Exploration (7 children)
  INSERT INTO public.content_items (card_id, name, content, image_urls, sort_order)
  VALUES (v_card_id_1, 'Arctic Exploration', 'Experience the pristine wilderness of polar regions and their unique ecosystems.', ARRAY['https://picsum.photos/seed/c1p5/600/400'], 4)
  RETURNING id INTO v_ci_parent_1_5;
  
  INSERT INTO public.content_items (card_id, parent_id, name, content, image_urls, sort_order)
  VALUES 
    (v_card_id_1, v_ci_parent_1_5, 'Cold Weather Gear', 'Layer systems and specialized equipment for -40°C survival conditions.', ARRAY['https://picsum.photos/seed/c1p5c1/600/400'], 0),
    (v_card_id_1, v_ci_parent_1_5, 'Ice Fishing Techniques', 'Traditional Inuit methods for catching fish through frozen lake surfaces.', ARRAY['https://picsum.photos/seed/c1p5c2/600/400'], 1),
    (v_card_id_1, v_ci_parent_1_5, 'Aurora Borealis Viewing', 'Optimal timing and locations for witnessing the spectacular northern lights.', ARRAY['https://picsum.photos/seed/c1p5c3/600/400'], 2),
    (v_card_id_1, v_ci_parent_1_5, 'Polar Bear Safety', 'Awareness protocols and deterrent strategies in polar bear territory.', ARRAY['https://picsum.photos/seed/c1p5c4/600/400'], 3),
    (v_card_id_1, v_ci_parent_1_5, 'Dog Sledding Adventure', 'Traditional transportation methods using husky teams across tundra.', ARRAY['https://picsum.photos/seed/c1p5c5/600/400'], 4),
    (v_card_id_1, v_ci_parent_1_5, 'Igloo Construction', 'Snow shelter building techniques for emergency survival situations.', ARRAY['https://picsum.photos/seed/c1p5c6/600/400'], 5),
    (v_card_id_1, v_ci_parent_1_5, 'Hypothermia Prevention', 'Recognition and treatment of cold-related injuries and illnesses.', ARRAY['https://picsum.photos/seed/c1p5c7/600/400'], 6);

  -- Standalone Content Items for Card 1
  INSERT INTO public.content_items (card_id, name, content, image_urls, sort_order)
  VALUES 
    (v_card_id_1, 'Urban Exploration', 'Discovering hidden city gems and architectural wonders.', ARRAY['https://picsum.photos/seed/c1s1/600/400'], 5),
    (v_card_id_1, 'Extreme Sports', 'Adrenaline-pumping activities for thrill seekers.', ARRAY['https://picsum.photos/seed/c1s2/600/400'], 6),
    (v_card_id_1, 'Photography Tips', 'Capture stunning adventure moments with professional techniques.', ARRAY['https://picsum.photos/seed/c1s3/600/400'], 7);

  -- Card 2: Culinary Masterclass (AI enabled)
  INSERT INTO public.cards (user_id, name, description, image_urls, conversation_ai_enabled, ai_prompt)
  VALUES (v_user_id, 'Culinary Masterclass', 'Master the art of international cuisine with professional techniques, authentic recipes, and cultural insights from renowned chefs around the globe.', ARRAY['https://picsum.photos/seed/card2/600/400']::TEXT[], true, true, 'You are a world-class chef and culinary instructor with expertise in international cuisines, cooking techniques, and food culture. Help visitors learn cooking skills, understand ingredients, and explore culinary traditions from around the world. Be passionate and detailed in your culinary guidance.')
  RETURNING id INTO v_card_id_2;

  -- Content Items for Card 2 - 5 parent items with 7+ children each
  
  -- Parent 2.1: European Cuisine (8 children)
  INSERT INTO public.content_items (card_id, name, content, image_urls, sort_order)
  VALUES (v_card_id_2, 'European Cuisine', 'Master classic European cooking techniques and traditional recipes.', ARRAY['https://picsum.photos/seed/c2p1/600/400'], 0)
  RETURNING id INTO v_ci_parent_2_1;
  
  INSERT INTO public.content_items (card_id, parent_id, name, content, image_urls, sort_order)
  VALUES 
    (v_card_id_2, v_ci_parent_2_1, 'Fresh Pasta Making', 'Hand-rolled pasta techniques using traditional Italian methods and equipment.', ARRAY['https://picsum.photos/seed/c2p1c1/600/400'], 0),
    (v_card_id_2, v_ci_parent_2_1, 'Sauce Perfection', 'Classic marinara, carbonara, and pesto preparation with authentic ingredients.', ARRAY['https://picsum.photos/seed/c2p1c2/600/400'], 1),
    (v_card_id_2, v_ci_parent_2_1, 'Risotto Techniques', 'Creamy risotto mastery with proper rice selection and stirring methods.', ARRAY['https://picsum.photos/seed/c2p1c3/600/400'], 2),
    (v_card_id_2, v_ci_parent_2_1, 'Pizza Napoletana', 'Authentic Neapolitan pizza with proper dough fermentation and wood-fired ovens.', ARRAY['https://picsum.photos/seed/c2p1c4/600/400'], 3),
    (v_card_id_2, v_ci_parent_2_1, 'Gelato Crafting', 'Traditional Italian gelato preparation with natural ingredients and techniques.', ARRAY['https://picsum.photos/seed/c2p1c5/600/400'], 4),
    (v_card_id_2, v_ci_parent_2_1, 'Wine Pairing', 'Regional Italian wine selection and pairing principles for different courses.', ARRAY['https://picsum.photos/seed/c2p1c6/600/400'], 5),
    (v_card_id_2, v_ci_parent_2_1, 'Antipasti Artistry', 'Creative appetizer combinations featuring cured meats, cheeses, and preserves.', ARRAY['https://picsum.photos/seed/c2p1c7/600/400'], 6),
    (v_card_id_2, v_ci_parent_2_1, 'Tiramisu Mastery', 'Classic dessert preparation with proper layering and flavor balance.', ARRAY['https://picsum.photos/seed/c2p1c8/600/400'], 7);

  -- Parent 2.2: Japanese Culinary Arts (8 children)
  INSERT INTO public.content_items (card_id, name, content, image_urls, sort_order)
  VALUES (v_card_id_2, 'Japanese Culinary Arts', 'Explore the precision and artistry of Japanese cuisine traditions.', ARRAY['https://picsum.photos/seed/c2p2/600/400'], 1)
  RETURNING id INTO v_ci_parent_2_2;
  
  INSERT INTO public.content_items (card_id, parent_id, name, content, image_urls, sort_order)
  VALUES 
    (v_card_id_2, v_ci_parent_2_2, 'Sushi Craftsmanship', 'Master the art of sushi preparation with knife skills and rice techniques.', ARRAY['https://picsum.photos/seed/c2p2c1/600/400'], 0),
    (v_card_id_2, v_ci_parent_2_2, 'Ramen Perfection', 'Complex broth preparation and noodle making for authentic ramen bowls.', ARRAY['https://picsum.photos/seed/c2p2c2/600/400'], 1),
    (v_card_id_2, v_ci_parent_2_2, 'Tempura Technique', 'Light, crispy tempura batter secrets and proper frying temperatures.', ARRAY['https://picsum.photos/seed/c2p2c3/600/400'], 2),
    (v_card_id_2, v_ci_parent_2_2, 'Kaiseki Presentation', 'Multi-course Japanese formal dining with seasonal ingredients and aesthetics.', ARRAY['https://picsum.photos/seed/c2p2c4/600/400'], 3),
    (v_card_id_2, v_ci_parent_2_2, 'Miso Soup Mastery', 'Traditional dashi preparation and miso variety selection for perfect flavor.', ARRAY['https://picsum.photos/seed/c2p2c5/600/400'], 4),
    (v_card_id_2, v_ci_parent_2_2, 'Sake Appreciation', 'Understanding sake types, serving temperatures, and food pairing traditions.', ARRAY['https://picsum.photos/seed/c2p2c6/600/400'], 5),
    (v_card_id_2, v_ci_parent_2_2, 'Knife Skills', 'Japanese knife techniques for precise cuts and proper maintenance methods.', ARRAY['https://picsum.photos/seed/c2p2c7/600/400'], 6),
    (v_card_id_2, v_ci_parent_2_2, 'Wagyu Preparation', 'Handling and cooking premium Japanese beef with proper temperature control.', ARRAY['https://picsum.photos/seed/c2p2c8/600/400'], 7);

  -- Parent 2.3: French Pastry Excellence (7 children)
  INSERT INTO public.content_items (card_id, name, content, image_urls, sort_order)
  VALUES (v_card_id_2, 'French Pastry Excellence', 'Master the sophisticated techniques of French patisserie.', ARRAY['https://picsum.photos/seed/c2p3/600/400'], 2)
  RETURNING id INTO v_ci_parent_2_3;
  
  INSERT INTO public.content_items (card_id, parent_id, name, content, image_urls, sort_order)
  VALUES 
    (v_card_id_2, v_ci_parent_2_3, 'Croissant Perfection', 'Laminated dough techniques for flaky, buttery croissants with proper proofing.', ARRAY['https://picsum.photos/seed/c2p3c1/600/400'], 0),
    (v_card_id_2, v_ci_parent_2_3, 'Macaron Artistry', 'Delicate almond flour cookies with perfect feet and smooth tops.', ARRAY['https://picsum.photos/seed/c2p3c2/600/400'], 1),
    (v_card_id_2, v_ci_parent_2_3, 'Chocolate Tempering', 'Professional chocolate working techniques for ganaches and decorations.', ARRAY['https://picsum.photos/seed/c2p3c3/600/400'], 2),
    (v_card_id_2, v_ci_parent_2_3, 'Puff Pastry Mastery', 'Creating hundreds of layers for vol-au-vents and napoleons.', ARRAY['https://picsum.photos/seed/c2p3c4/600/400'], 3),
    (v_card_id_2, v_ci_parent_2_3, 'Crème Brûlée', 'Silky custard preparation with perfect caramelized sugar topping.', ARRAY['https://picsum.photos/seed/c2p3c5/600/400'], 4),
    (v_card_id_2, v_ci_parent_2_3, 'Soufflé Technique', 'Light, airy soufflés both sweet and savory with timing precision.', ARRAY['https://picsum.photos/seed/c2p3c6/600/400'], 5),
    (v_card_id_2, v_ci_parent_2_3, 'Sugar Artistry', 'Advanced sugar pulling, spinning, and molding for decorative elements.', ARRAY['https://picsum.photos/seed/c2p3c7/600/400'], 6);

  -- Parent 2.4: Mexican Authentic Cuisine (8 children)
  INSERT INTO public.content_items (card_id, name, content, image_urls, sort_order)
  VALUES (v_card_id_2, 'Mexican Authentic Cuisine', 'Explore the rich flavors and traditions of regional Mexican cooking.', ARRAY['https://picsum.photos/seed/c2p4/600/400'], 3)
  RETURNING id INTO v_ci_parent_2_4;
  
  INSERT INTO public.content_items (card_id, parent_id, name, content, image_urls, sort_order)
  VALUES 
    (v_card_id_2, v_ci_parent_2_4, 'Mole Preparation', 'Complex sauce making with 20+ ingredients including chocolate and chilies.', ARRAY['https://picsum.photos/seed/c2p4c1/600/400'], 0),
    (v_card_id_2, v_ci_parent_2_4, 'Tortilla Crafting', 'Traditional corn and flour tortilla making from scratch with proper technique.', ARRAY['https://picsum.photos/seed/c2p4c2/600/400'], 1),
    (v_card_id_2, v_ci_parent_2_4, 'Chili Mastery', 'Understanding heat levels and flavor profiles of Mexican chili varieties.', ARRAY['https://picsum.photos/seed/c2p4c3/600/400'], 2),
    (v_card_id_2, v_ci_parent_2_4, 'Taco Artistry', 'Authentic street taco preparation with various meat and vegetarian fillings.', ARRAY['https://picsum.photos/seed/c2p4c4/600/400'], 3),
    (v_card_id_2, v_ci_parent_2_4, 'Pozole Traditions', 'Hominy soup preparation with traditional garnishes and regional variations.', ARRAY['https://picsum.photos/seed/c2p4c5/600/400'], 4),
    (v_card_id_2, v_ci_parent_2_4, 'Mezcal Appreciation', 'Understanding agave spirits and their role in Mexican culinary culture.', ARRAY['https://picsum.photos/seed/c2p4c6/600/400'], 5),
    (v_card_id_2, v_ci_parent_2_4, 'Tamale Workshop', 'Masa preparation and filling techniques for perfect steamed tamales.', ARRAY['https://picsum.photos/seed/c2p4c7/600/400'], 6),
    (v_card_id_2, v_ci_parent_2_4, 'Ceviche Perfection', 'Fresh seafood "cooking" with citrus acids and complementary seasonings.', ARRAY['https://picsum.photos/seed/c2p4c8/600/400'], 7);

  -- Parent 2.5: Asian Fusion Techniques (7 children)
  INSERT INTO public.content_items (card_id, name, content, image_urls, sort_order)
  VALUES (v_card_id_2, 'Asian Fusion Techniques', 'Modern interpretations of traditional Asian cooking methods.', ARRAY['https://picsum.photos/seed/c2p5/600/400'], 4)
  RETURNING id INTO v_ci_parent_2_5;
  
  INSERT INTO public.content_items (card_id, parent_id, name, content, image_urls, sort_order)
  VALUES 
    (v_card_id_2, v_ci_parent_2_5, 'Wok Mastery', 'High-heat stir-frying techniques with proper wok seasoning and maintenance.', ARRAY['https://picsum.photos/seed/c2p5c1/600/400'], 0),
    (v_card_id_2, v_ci_parent_2_5, 'Dim Sum Artistry', 'Delicate dumpling folding and steaming techniques for perfect texture.', ARRAY['https://picsum.photos/seed/c2p5c2/600/400'], 1),
    (v_card_id_2, v_ci_parent_2_5, 'Thai Curry Balance', 'Balancing sweet, sour, salty, and spicy flavors in traditional curry pastes.', ARRAY['https://picsum.photos/seed/c2p5c3/600/400'], 2),
    (v_card_id_2, v_ci_parent_2_5, 'Korean BBQ Techniques', 'Marinating and grilling methods for bulgogi and galbi preparations.', ARRAY['https://picsum.photos/seed/c2p5c4/600/400'], 3),
    (v_card_id_2, v_ci_parent_2_5, 'Vietnamese Pho', 'Long-simmered bone broth preparation with aromatic spice combinations.', ARRAY['https://picsum.photos/seed/c2p5c5/600/400'], 4),
    (v_card_id_2, v_ci_parent_2_5, 'Indian Spice Blending', 'Creating custom spice mixtures and understanding regional spice preferences.', ARRAY['https://picsum.photos/seed/c2p5c6/600/400'], 5),
    (v_card_id_2, v_ci_parent_2_5, 'Chinese Tea Ceremony', 'Traditional tea preparation methods and food pairing principles.', ARRAY['https://picsum.photos/seed/c2p5c7/600/400'], 6);

  -- Standalone Content Items for Card 2
  INSERT INTO public.content_items (card_id, name, content, image_urls, sort_order)
  VALUES 
    (v_card_id_2, 'Molecular Gastronomy', 'Modern cooking techniques using science and technology.', ARRAY['https://picsum.photos/seed/c2s1/600/400'], 5),
    (v_card_id_2, 'Food Photography', 'Professional techniques for capturing culinary creations.', ARRAY['https://picsum.photos/seed/c2s2/600/400'], 6),
    (v_card_id_2, 'Culinary Nutrition', 'Understanding the health benefits of different cooking methods.', ARRAY['https://picsum.photos/seed/c2s3/600/400'], 7);

  -- Card 3: Historical Chronicles (AI enabled)
  INSERT INTO public.cards (user_id, name, description, image_urls, conversation_ai_enabled, ai_prompt)
  VALUES (v_user_id, 'Historical Chronicles', 'Journey through pivotal moments in human history, exploring ancient civilizations, major conflicts, and cultural transformations that shaped our modern world.', ARRAY['https://picsum.photos/seed/card3/600/400']::TEXT[], true, true, 'You are a distinguished historian with deep knowledge of world history, ancient civilizations, and historical events. Help visitors understand historical contexts, analyze historical significance, and connect past events to modern times. Be scholarly yet engaging in your historical explanations.')
  RETURNING id INTO v_card_id_3;
  
  -- Content Items for Card 3 - 5 parent items with 7+ children each
  
  -- Parent 3.1: Ancient Civilizations (8 children)
  INSERT INTO public.content_items (card_id, name, content, image_urls, sort_order)
  VALUES (v_card_id_3, 'Ancient Civilizations', 'Explore the foundations of human civilization and early empires.', ARRAY['https://picsum.photos/seed/c3p1/600/400'], 0)
  RETURNING id INTO v_ci_parent_3_1;
  
  INSERT INTO public.content_items (card_id, parent_id, name, content, image_urls, sort_order)
  VALUES 
    (v_card_id_3, v_ci_parent_3_1, 'Egyptian Dynasties', 'Pharaohs, pyramids, and the mysteries of ancient Egypt spanning 3,000 years.', ARRAY['https://picsum.photos/seed/c3p1c1/600/400'], 0),
    (v_card_id_3, v_ci_parent_3_1, 'Roman Empire', 'The rise and fall of Rome from republic to empire across three continents.', ARRAY['https://picsum.photos/seed/c3p1c2/600/400'], 1),
    (v_card_id_3, v_ci_parent_3_1, 'Greek City-States', 'Democracy, philosophy, and warfare in Athens, Sparta, and beyond.', ARRAY['https://picsum.photos/seed/c3p1c3/600/400'], 2),
    (v_card_id_3, v_ci_parent_3_1, 'Mesopotamian Kingdoms', 'Cradle of civilization with Sumerians, Babylonians, and Assyrians.', ARRAY['https://picsum.photos/seed/c3p1c4/600/400'], 3),
    (v_card_id_3, v_ci_parent_3_1, 'Chinese Dynasties', 'Imperial China from Qin to Ming dynasties and the Great Wall.', ARRAY['https://picsum.photos/seed/c3p1c5/600/400'], 4),
    (v_card_id_3, v_ci_parent_3_1, 'Indus Valley', 'Sophisticated urban planning and trade networks in ancient India.', ARRAY['https://picsum.photos/seed/c3p1c6/600/400'], 5),
    (v_card_id_3, v_ci_parent_3_1, 'Maya Civilization', 'Advanced astronomy, mathematics, and hieroglyphic writing systems.', ARRAY['https://picsum.photos/seed/c3p1c7/600/400'], 6),
    (v_card_id_3, v_ci_parent_3_1, 'Persian Empire', 'Vast empire stretching from India to Greece under Cyrus and Darius.', ARRAY['https://picsum.photos/seed/c3p1c8/600/400'], 7);

  -- Parent 3.2: Medieval Times (8 children)
  INSERT INTO public.content_items (card_id, name, content, image_urls, sort_order)
  VALUES (v_card_id_3, 'Medieval Times', 'The age of knights, castles, and feudalism in medieval Europe.', ARRAY['https://picsum.photos/seed/c3p2/600/400'], 1)
  RETURNING id INTO v_ci_parent_3_2;
  
  INSERT INTO public.content_items (card_id, parent_id, name, content, image_urls, sort_order)
  VALUES 
    (v_card_id_3, v_ci_parent_3_2, 'Knights and Chivalry', 'Code of honor, tournaments, and the warrior culture of medieval nobility.', ARRAY['https://picsum.photos/seed/c3p2c1/600/400'], 0),
    (v_card_id_3, v_ci_parent_3_2, 'Castle Architecture', 'Defensive structures, siege warfare, and medieval engineering marvels.', ARRAY['https://picsum.photos/seed/c3p2c2/600/400'], 1),
    (v_card_id_3, v_ci_parent_3_2, 'The Crusades', 'Religious wars between Christianity and Islam for control of the Holy Land.', ARRAY['https://picsum.photos/seed/c3p2c3/600/400'], 2),
    (v_card_id_3, v_ci_parent_3_2, 'Viking Expeditions', 'Norse exploration, raids, and settlements from Greenland to Constantinople.', ARRAY['https://picsum.photos/seed/c3p2c4/600/400'], 3),
    (v_card_id_3, v_ci_parent_3_2, 'Feudal System', 'Land ownership, vassalage, and the complex social hierarchy of medieval Europe.', ARRAY['https://picsum.photos/seed/c3p2c5/600/400'], 4),
    (v_card_id_3, v_ci_parent_3_2, 'Gothic Cathedrals', 'Soaring architecture as expressions of faith and medieval craftsmanship.', ARRAY['https://picsum.photos/seed/c3p2c6/600/400'], 5),
    (v_card_id_3, v_ci_parent_3_2, 'Plague and Pestilence', 'The Black Death and its devastating impact on medieval European society.', ARRAY['https://picsum.photos/seed/c3p2c7/600/400'], 6),
    (v_card_id_3, v_ci_parent_3_2, 'Medieval Trade Routes', 'Merchant guilds, silk roads, and the economic foundations of medieval commerce.', ARRAY['https://picsum.photos/seed/c3p2c8/600/400'], 7);

  -- Parent 3.3: Renaissance Era (7 children)
  INSERT INTO public.content_items (card_id, name, content, image_urls, sort_order)
  VALUES (v_card_id_3, 'Renaissance Era', 'The rebirth of art, science, and humanism in 14th-17th century Europe.', ARRAY['https://picsum.photos/seed/c3p3/600/400'], 2)
  RETURNING id INTO v_ci_parent_3_3;
  
  INSERT INTO public.content_items (card_id, parent_id, name, content, image_urls, sort_order)
  VALUES 
    (v_card_id_3, v_ci_parent_3_3, 'Leonardo da Vinci', 'The ultimate Renaissance man: artist, inventor, scientist, and philosopher.', ARRAY['https://picsum.photos/seed/c3p3c1/600/400'], 0),
    (v_card_id_3, v_ci_parent_3_3, 'Michelangelo''s Masterpieces', 'Sistine Chapel, David, and revolutionary sculpture and painting techniques.', ARRAY['https://picsum.photos/seed/c3p3c2/600/400'], 1),
    (v_card_id_3, v_ci_parent_3_3, 'Scientific Revolution', 'Galileo, Copernicus, and the shift from medieval to modern scientific thinking.', ARRAY['https://picsum.photos/seed/c3p3c3/600/400'], 2),
    (v_card_id_3, v_ci_parent_3_3, 'Printing Press Impact', 'Gutenberg''s invention revolutionizing knowledge distribution and literacy.', ARRAY['https://picsum.photos/seed/c3p3c4/600/400'], 3),
    (v_card_id_3, v_ci_parent_3_3, 'Medici Banking', 'Florence''s powerful banking family patronizing arts and influencing European politics.', ARRAY['https://picsum.photos/seed/c3p3c5/600/400'], 4),
    (v_card_id_3, v_ci_parent_3_3, 'Maritime Exploration', 'Columbus, Magellan, and the Age of Discovery opening new trade routes.', ARRAY['https://picsum.photos/seed/c3p3c6/600/400'], 5),
    (v_card_id_3, v_ci_parent_3_3, 'Humanist Philosophy', 'Shift toward individual dignity and human potential in art and literature.', ARRAY['https://picsum.photos/seed/c3p3c7/600/400'], 6);

  -- Parent 3.4: Industrial Revolution (8 children)
  INSERT INTO public.content_items (card_id, name, content, image_urls, sort_order)
  VALUES (v_card_id_3, 'Industrial Revolution', 'The transformation from agrarian to industrial society in the 18th-19th centuries.', ARRAY['https://picsum.photos/seed/c3p4/600/400'], 3)
  RETURNING id INTO v_ci_parent_3_4;
  
  INSERT INTO public.content_items (card_id, parent_id, name, content, image_urls, sort_order)
  VALUES 
    (v_card_id_3, v_ci_parent_3_4, 'Steam Engine Innovation', 'James Watt''s improvements powering factories, trains, and ships worldwide.', ARRAY['https://picsum.photos/seed/c3p4c1/600/400'], 0),
    (v_card_id_3, v_ci_parent_3_4, 'Factory System', 'Mass production methods transforming manufacturing and worker relationships.', ARRAY['https://picsum.photos/seed/c3p4c2/600/400'], 1),
    (v_card_id_3, v_ci_parent_3_4, 'Railroad Expansion', 'Connecting continents with steam locomotives and transforming commerce.', ARRAY['https://picsum.photos/seed/c3p4c3/600/400'], 2),
    (v_card_id_3, v_ci_parent_3_4, 'Urban Growth', 'Rapid city expansion, population shifts, and new social challenges.', ARRAY['https://picsum.photos/seed/c3p4c4/600/400'], 3),
    (v_card_id_3, v_ci_parent_3_4, 'Labor Movements', 'Workers organizing for better conditions, hours, and wages in dangerous factories.', ARRAY['https://picsum.photos/seed/c3p4c5/600/400'], 4),
    (v_card_id_3, v_ci_parent_3_4, 'Textile Revolution', 'Mechanized weaving and spinning transforming clothing production and trade.', ARRAY['https://picsum.photos/seed/c3p4c6/600/400'], 5),
    (v_card_id_3, v_ci_parent_3_4, 'Child Labor Issues', 'Exploitation of young workers and eventual reform movements for protection.', ARRAY['https://picsum.photos/seed/c3p4c7/600/400'], 6),
    (v_card_id_3, v_ci_parent_3_4, 'Capitalist Economy', 'New economic systems, banking, and the rise of industrial entrepreneurs.', ARRAY['https://picsum.photos/seed/c3p4c8/600/400'], 7);

  -- Parent 3.5: Modern Conflicts (7 children)
  INSERT INTO public.content_items (card_id, name, content, image_urls, sort_order)
  VALUES (v_card_id_3, 'Modern Conflicts', 'Major wars and conflicts that shaped the 20th and 21st centuries.', ARRAY['https://picsum.photos/seed/c3p5/600/400'], 4)
  RETURNING id INTO v_ci_parent_3_5;
  
  INSERT INTO public.content_items (card_id, parent_id, name, content, image_urls, sort_order)
  VALUES 
    (v_card_id_3, v_ci_parent_3_5, 'World War I', 'The Great War that ended empires and reshaped global political boundaries.', ARRAY['https://picsum.photos/seed/c3p5c1/600/400'], 0),
    (v_card_id_3, v_ci_parent_3_5, 'World War II', 'Global conflict against fascism with unprecedented scale and consequences.', ARRAY['https://picsum.photos/seed/c3p5c2/600/400'], 1),
    (v_card_id_3, v_ci_parent_3_5, 'Cold War Era', 'Decades of tension between capitalist and communist superpowers.', ARRAY['https://picsum.photos/seed/c3p5c3/600/400'], 2),
    (v_card_id_3, v_ci_parent_3_5, 'Decolonization', 'Independence movements across Africa, Asia, and the Americas.', ARRAY['https://picsum.photos/seed/c3p5c4/600/400'], 3),
    (v_card_id_3, v_ci_parent_3_5, 'Civil Rights Movement', 'Struggle for equality and justice in America and around the world.', ARRAY['https://picsum.photos/seed/c3p5c5/600/400'], 4),
    (v_card_id_3, v_ci_parent_3_5, 'Space Race', 'Competition between superpowers to explore and conquer outer space.', ARRAY['https://picsum.photos/seed/c3p5c6/600/400'], 5),
    (v_card_id_3, v_ci_parent_3_5, 'Digital Revolution', 'Technology transforming communication, work, and daily life globally.', ARRAY['https://picsum.photos/seed/c3p5c7/600/400'], 6);

  -- Standalone Content Items for Card 3
  INSERT INTO public.content_items (card_id, name, content, image_urls, sort_order)
  VALUES 
    (v_card_id_3, 'Archaeological Discoveries', 'Uncovering the past through modern archaeological techniques and tools.', ARRAY['https://picsum.photos/seed/c3s1/600/400'], 5),
    (v_card_id_3, 'Historical Mysteries', 'Unsolved puzzles and debates that continue to intrigue historians.', ARRAY['https://picsum.photos/seed/c3s2/600/400'], 6),
    (v_card_id_3, 'Timeline Navigation', 'Interactive chronological exploration of major historical events.', ARRAY['https://picsum.photos/seed/c3s3/600/400'], 7);

  -- ===============================
  -- CARD BATCHES AND ISSUED CARDS
  -- ===============================

  -- Batches for Card 1 (Adventure Series)
  INSERT INTO public.card_batches (card_id, batch_name, batch_number, cards_count, is_disabled, created_by, created_at)
  VALUES (v_card_id_1, 'batch-1', 1, 50, false, v_user_id, NOW() - INTERVAL '10 days')
  RETURNING id INTO v_batch_id_1_1;

  INSERT INTO public.card_batches (card_id, batch_name, batch_number, cards_count, is_disabled, created_by, created_at)
  VALUES (v_card_id_1, 'batch-2', 2, 25, false, v_user_id, NOW() - INTERVAL '5 days')
  RETURNING id INTO v_batch_id_1_2;

  -- Batches for Card 2 (Culinary Delights)
  INSERT INTO public.card_batches (card_id, batch_name, batch_number, cards_count, is_disabled, created_by, created_at)
  VALUES (v_card_id_2, 'batch-1', 1, 100, false, v_user_id, NOW() - INTERVAL '15 days')
  RETURNING id INTO v_batch_id_2_1;

  INSERT INTO public.card_batches (card_id, batch_name, batch_number, cards_count, is_disabled, created_by, created_at)
  VALUES (v_card_id_2, 'batch-2', 2, 30, true, v_user_id, NOW() - INTERVAL '3 days')
  RETURNING id INTO v_batch_id_2_2;

  -- Batches for Card 3 (Historical Journeys) - smaller test batch
  INSERT INTO public.card_batches (card_id, batch_name, batch_number, cards_count, is_disabled, created_by, created_at)
  VALUES (v_card_id_3, 'batch-1', 1, 10, false, v_user_id, NOW() - INTERVAL '2 days')
  RETURNING id INTO v_batch_id_3_1;

  -- Generate issued cards for each batch with varied activation status
  
  -- Batch 1-1: 50 cards, 80% activated (40 active, 10 pending)
  FOR i IN 1..40 LOOP
    INSERT INTO public.issue_cards (card_id, batch_id, active, issue_at, active_at, activated_by)
    VALUES (
      v_card_id_1, 
      v_batch_id_1_1, 
      true, 
      NOW() - INTERVAL '10 days' + (i || ' hours')::INTERVAL,
      NOW() - INTERVAL '8 days' + (i || ' hours')::INTERVAL,
      NULL
    );
  END LOOP;

  FOR i IN 41..50 LOOP
    INSERT INTO public.issue_cards (card_id, batch_id, active, issue_at)
    VALUES (
      v_card_id_1, 
      v_batch_id_1_1, 
      false, 
      NOW() - INTERVAL '10 days' + (i || ' hours')::INTERVAL
    );
  END LOOP;

  -- Batch 1-2: 25 cards, 60% activated (15 active, 10 pending)
  FOR i IN 1..15 LOOP
    INSERT INTO public.issue_cards (card_id, batch_id, active, issue_at, active_at)
    VALUES (
      v_card_id_1, 
      v_batch_id_1_2, 
      true, 
      NOW() - INTERVAL '5 days' + (i || ' hours')::INTERVAL,
      NOW() - INTERVAL '3 days' + (i || ' hours')::INTERVAL
    );
  END LOOP;

  FOR i IN 16..25 LOOP
    INSERT INTO public.issue_cards (card_id, batch_id, active, issue_at)
    VALUES (
      v_card_id_1, 
      v_batch_id_1_2, 
      false, 
      NOW() - INTERVAL '5 days' + (i || ' hours')::INTERVAL
    );
  END LOOP;

  -- Batch 2-1: 100 cards, 90% activated (90 active, 10 pending)
  FOR i IN 1..90 LOOP
    INSERT INTO public.issue_cards (card_id, batch_id, active, issue_at, active_at)
    VALUES (
      v_card_id_2, 
      v_batch_id_2_1, 
      true, 
      NOW() - INTERVAL '15 days' + (i || ' minutes')::INTERVAL,
      NOW() - INTERVAL '12 days' + (i || ' minutes')::INTERVAL
    );
  END LOOP;

  FOR i IN 91..100 LOOP
    INSERT INTO public.issue_cards (card_id, batch_id, active, issue_at)
    VALUES (
      v_card_id_2, 
      v_batch_id_2_1, 
      false, 
      NOW() - INTERVAL '15 days' + (i || ' minutes')::INTERVAL
    );
  END LOOP;

  -- Batch 2-2: 30 cards, 0% activated (all pending, batch is disabled)
  FOR i IN 1..30 LOOP
    INSERT INTO public.issue_cards (card_id, batch_id, active, issue_at)
    VALUES (
      v_card_id_2, 
      v_batch_id_2_2, 
      false, 
      NOW() - INTERVAL '3 days' + (i || ' minutes')::INTERVAL
    );
  END LOOP;

  -- Batch 3-1: 10 cards, 30% activated (3 active, 7 pending)
  FOR i IN 1..3 LOOP
    INSERT INTO public.issue_cards (card_id, batch_id, active, issue_at, active_at)
    VALUES (
      v_card_id_3, 
      v_batch_id_3_1, 
      true, 
      NOW() - INTERVAL '2 days' + (i || ' hours')::INTERVAL,
      NOW() - INTERVAL '1 day' + (i || ' hours')::INTERVAL
    );
  END LOOP;

  FOR i IN 4..10 LOOP
    INSERT INTO public.issue_cards (card_id, batch_id, active, issue_at)
    VALUES (
      v_card_id_3, 
      v_batch_id_3_1, 
      false, 
      NOW() - INTERVAL '2 days' + (i || ' hours')::INTERVAL
    );
  END LOOP;

  -- ===============================
  -- PRINT REQUESTS
  -- ===============================

  -- Print request for Adventure Series batch-1 (completed)
  INSERT INTO public.print_requests (
    batch_id, 
    user_id, 
    status, 
    shipping_address, 
    admin_notes, 
    requested_at, 
    updated_at
  ) VALUES (
    v_batch_id_1_1,
    v_user_id,
    'COMPLETED',
    '123 Adventure Street, Mountain View, CA 94041, USA',
    'Print quality excellent. Shipped via FedEx Express. Tracking: 1234567890123',
    NOW() - INTERVAL '8 days',
    NOW() - INTERVAL '2 days'
  );

  -- Print request for Culinary Delights batch-1 (processing)
  INSERT INTO public.print_requests (
    batch_id, 
    user_id, 
    status, 
    shipping_address, 
    admin_notes, 
    requested_at, 
    updated_at
  ) VALUES (
    v_batch_id_2_1,
    v_user_id,
    'PROCESSING',
    '456 Culinary Avenue, New York, NY 10001, USA',
    'Large order in production. Expected completion in 2-3 business days.',
    NOW() - INTERVAL '4 days',
    NOW() - INTERVAL '1 day'
  );

  -- Print request for Adventure Series batch-2 (submitted)
  INSERT INTO public.print_requests (
    batch_id, 
    user_id, 
    status, 
    shipping_address, 
    admin_notes, 
    requested_at
  ) VALUES (
    v_batch_id_1_2,
    v_user_id,
    'SUBMITTED',
    '789 Explorer Road, Denver, CO 80202, USA',
    NULL,
    NOW() - INTERVAL '1 day'
  );

  -- Print request for Historical Journeys batch-1 (shipped)
  INSERT INTO public.print_requests (
    batch_id, 
    user_id, 
    status, 
    shipping_address, 
    admin_notes, 
    requested_at, 
    updated_at
  ) VALUES (
    v_batch_id_3_1,
    v_user_id,
    'SHIPPED',
    '321 History Lane, Boston, MA 02101, USA',
    'Shipped via UPS Ground. Tracking: 9876543210987',
    NOW() - INTERVAL '6 hours',
    NOW() - INTERVAL '2 hours'
  );

  -- Insert sample shipping addresses
  INSERT INTO shipping_addresses (user_id, label, recipient_name, address_line1, address_line2, city, state_province, postal_code, country, phone, is_default) VALUES
  (v_user_id, 'Home', 'John Doe', '123 Main Street', 'Apt 4B', 'New York', 'NY', '10001', 'US', '+1-555-0123', true),
  (v_user_id, 'Office', 'John Doe', '456 Business Ave', 'Suite 200', 'New York', 'NY', '10002', 'US', '+1-555-0124', false);

  -- Print success message

END $$;
