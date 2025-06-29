-- Placeholder User ID (replace with an actual user_id from your auth.users table if needed)
DO $$
DECLARE
  v_user_id UUID;
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

  -- Create an auth user first (this will generate a valid user_id)
  INSERT INTO auth.users (
    id,
    aud,
    role,
    email,
    email_confirmed_at,
    raw_app_meta_data,
    raw_user_meta_data,
    created_at,
    updated_at
  ) VALUES (
    gen_random_uuid(),
    'authenticated',
    'authenticated',
    'demo@heritage-museums.org',
    NOW(),
    '{"provider": "email", "providers": ["email"]}',
    '{"role": "card_issuer"}',
    NOW(),
    NOW()
  )
  RETURNING id INTO v_user_id;

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
    'Cultural Heritage Director',
    'Passionate about creating immersive digital experiences that enhance visitor engagement with museums, cultural sites, and educational institutions.',
    'Heritage Museums & Cultural Sites Network',
    'Dr. Sarah Chen',
    'APPROVED',
    ARRAY['https://example.com/docs/identity.pdf', 'https://example.com/docs/business-license.pdf'],
    'All documents verified successfully. Excellent portfolio of cultural institutions!',
    NOW() - INTERVAL '5 days'
  );

  -- Card 1: Natural History Museum Experience (AI enabled)
  INSERT INTO public.cards (user_id, name, description, image_urls, conversation_ai_enabled, ai_prompt)
  VALUES (
    v_user_id, 
    'Natural History Museum Experience', 
    'Embark on an extraordinary journey through Earth''s natural history spanning 4.6 billion years. This interactive digital souvenir guides visitors through our world-class collection of dinosaur fossils, precious minerals, rare specimens, and immersive dioramas. Discover the stories behind our most treasured exhibits, from the towering T-Rex skeleton in our main hall to the delicate butterfly specimens in our biodiversity wing. Each exhibit comes alive through detailed explanations, scientific insights, and fascinating facts that connect our planet''s past to its present. Perfect for families, students, and anyone curious about the natural world, this digital companion enhances your museum visit with AI-powered conversations that can answer questions about geology, paleontology, ecology, and evolution. Take home the wonder of discovery and continue learning long after your visit ends.',
    ARRAY['https://images.unsplash.com/photo-1559827260-dc66d52bef19?w=400&h=600&fit=crop']::TEXT[],
    TRUE, 
    'You are an expert natural history museum guide and scientist with deep knowledge of paleontology, geology, biology, and Earth''s natural history. Help visitors understand exhibit specimens, explain scientific concepts, discuss evolution and extinction, and connect natural history to modern conservation efforts. Be enthusiastic, educational, and engaging while maintaining scientific accuracy.'
  )
  RETURNING id INTO v_card_id_1;

  -- Content Items for Card 1 - 5 parent items with 7+ children each
  
  -- Parent 1.1: Dinosaur Hall (8 children)
  INSERT INTO public.content_items (card_id, name, content, image_urls, sort_order)
  VALUES (v_card_id_1, 'Dinosaur Hall', 'Step into the age of giants and discover the fascinating world of dinosaurs that ruled Earth for over 160 million years.', ARRAY['https://picsum.photos/seed/dino-hall/600/400'], 0)
  RETURNING id INTO v_ci_parent_1_1;
  
  INSERT INTO public.content_items (card_id, parent_id, name, content, image_urls, sort_order)
  VALUES 
    (v_card_id_1, v_ci_parent_1_1, 'Tyrannosaurus Rex', 'Our crown jewel stands as one of the most complete T-Rex skeletons ever discovered, towering 12 feet tall and stretching 40 feet from nose to tail. This apex predator dominated the late Cretaceous period 68 million years ago, wielding bone-crushing jaws capable of exerting 12,800 pounds of pressure per square inch. Each of its 58 razor-sharp teeth could grow up to 8 inches long, perfectly designed for tearing flesh and crushing bone. Recent research suggests T-Rex was not just a scavenger but an active hunter, using its powerful legs to reach speeds of up to 25 mph. Our specimen, nicknamed "Regina," was discovered in Montana and represents a fully mature adult female. Interactive displays allow visitors to hear what scientists believe T-Rex sounded like and explore its incredible sensory capabilities, including exceptional vision and smell that made it the ultimate predator of its time.', ARRAY['https://picsum.photos/seed/trex/600/400'], 0),
    (v_card_id_1, v_ci_parent_1_1, 'Triceratops Family', 'Meet our beloved three-horned herbivores representing one of the most successful dinosaur families of the late Cretaceous period. Our display features a rare juvenile specimen alongside two adults, showcasing how these magnificent creatures grew from dog-sized hatchlings to house-sized adults weighing up to 12 tons. The iconic frill served multiple purposes: protection from predators, thermoregulation, and impressive displays during mating season. Each of the three horns could grow over three feet long and were used both defensively and in ritualized combat with rivals. Fossil evidence suggests Triceratops lived in herds, traveling across ancient floodplains in search of cycads, ferns, and other vegetation. Our juvenile specimen, discovered with preserved skin impressions, reveals that baby Triceratops had proportionally larger eyes and shorter frills, providing crucial insights into their development. Interactive touchscreens let visitors explore how these gentle giants used their powerful beaks to slice through tough plant material and how their complex social behaviors helped them survive in a world dominated by fearsome predators.', ARRAY['https://picsum.photos/seed/triceratops/600/400'], 1),
    (v_card_id_1, v_ci_parent_1_1, 'Velociraptor Pack', 'Discover the true nature of these intelligent predators, far removed from their Hollywood portrayal but infinitely more fascinating in reality. Our Velociraptor specimens, authentic fossils from Mongolia, reveal creatures about the size of large turkeys but possessing remarkable intelligence and sophisticated hunting strategies. Recent discoveries prove they were covered in feathers, likely for display and temperature regulation rather than flight. Each foot bore a sickle-shaped claw up to 3 inches long, used not for slashing as once thought, but for pinning down struggling prey while the pack worked together to overwhelm their victims. Fossil trackways suggest these raptors hunted in coordinated groups, using pack tactics similar to modern wolves. Their large brains relative to body size indicate problem-solving abilities that may have rivaled modern birds. Our interactive display demonstrates how their flexible wrists and grasping hands, remarkably similar to bird wings, were perfectly adapted for catching and manipulating prey. Visitors can test their own coordination against Velociraptor reflexes and learn how these feathered dinosaurs evolved into the birds we see today.', ARRAY['https://picsum.photos/seed/velociraptor/600/400'], 2),
    (v_card_id_1, v_ci_parent_1_1, 'Brachiosaurus Neck', 'Experience the engineering marvel of the longest neck in the animal kingdom by examining the massive vertebrae of this gentle giant that could reach treetops 40 feet above ground. Each vertebra was hollow and reinforced with internal struts, making them both incredibly strong and surprisingly lightweight - a crucial adaptation for supporting a neck that could extend over 30 feet. Our display reveals how Brachiosaurus used its height advantage to browse on prehistoric conifers, ginkgoes, and tree ferns that other dinosaurs couldn''t reach, essentially occupying the same ecological niche as modern giraffes. The elongated neck required a specialized cardiovascular system with an enormous heart weighing over 400 pounds to pump blood to the brain against gravity. Recent computer modeling suggests these giants could raise and lower their necks like massive construction cranes, allowing them to feed at various levels without moving their bodies. Visitors can manipulate our interactive neck model to understand the biomechanics involved and compare their own neck mobility to this prehistoric marvel. Fossilized stomach stones found with Brachiosaurus remains indicate they swallowed rocks to help grind tough plant material in their massive stomachs.', ARRAY['https://picsum.photos/seed/brachio/600/400'], 3),
    (v_card_id_1, v_ci_parent_1_1, 'Stegosaurus Plates', 'Examine the magnificent defensive armor and weapon system of this iconic herbivore, whose distinctive back plates and tail spikes have captivated scientists and visitors for over a century. The 17 bony plates arranged along Stegosaurus'' spine were not solid armor but complex structures filled with blood vessels, likely used for thermoregulation and species recognition rather than protection. These plates could flush with blood to create dramatic color displays, similar to how modern mammals blush. The real weapons were the four sharp spikes on the tail, each up to 3 feet long and capable of delivering devastating blows to attacking predators - paleontologists have even found Allosaurus bones bearing puncture wounds matching Stegosaurus tail spikes. Despite its fierce appearance, Stegosaurus had a brain no larger than a walnut, leading to the misconception that dinosaurs were unintelligent. However, modern research reveals that their small brains were perfectly adequate for their herbivorous lifestyle. Our hands-on displays let visitors feel the weight of replica plates and spikes while learning about the ongoing scientific debate over whether these magnificent creatures were warm-blooded or cold-blooded, and how their unique anatomy helped them thrive for millions of years.', ARRAY['https://picsum.photos/seed/stego/600/400'], 4),
    (v_card_id_1, v_ci_parent_1_1, 'Pteranodon Soaring', 'Look skyward at our magnificent flying reptile display showcasing creatures that achieved powered flight 85 million years ago, long before birds dominated the skies. With wingspans reaching an incredible 23 feet, Pteranodon was one of the largest flying animals ever to exist, soaring over ancient seas with the grace and efficiency of modern albatrosses. These were not dinosaurs but pterosaurs, reptiles that independently evolved the ability to fly using wings made of skin and muscle stretched between elongated finger bones. Our display reveals how Pteranodon''s lightweight, hollow bones and specialized air sacs made flight possible despite their enormous size. The distinctive bony crest served multiple purposes: aerodynamic stability during flight, species recognition, and sexual display. Males had much larger crests than females, suggesting elaborate mating rituals high above prehistoric oceans. Recent discoveries of fossilized flight muscles indicate these giants were capable of active, powered flight rather than just gliding. Interactive flight simulators let visitors experience the physics of pterosaur flight while learning about their fish-based diet and sophisticated diving techniques. Our fossil specimens include rare examples of pterosaur eggs and babies, providing insights into how these magnificent creatures reproduced and raised their young in clifftop colonies.', ARRAY['https://picsum.photos/seed/pteranodon/600/400'], 5),
    (v_card_id_1, v_ci_parent_1_1, 'Fossil Dig Site', 'Step into the boots of a real paleontologist at our hands-on excavation site where visitors can uncover replica fossils using authentic tools and techniques employed by professional fossil hunters worldwide. This immersive experience recreates the thrill of discovery that drives paleontologists to remote locations in search of prehistoric treasures. Our carefully constructed dig site contains exact replicas of significant fossil discoveries, including dinosaur bones, ancient plants, and marine reptiles, all buried in sediment layers that mirror real fossil formations. Visitors learn to use brushes, chisels, and dental picks with the same precision required at actual dig sites, understanding that a single careless moment could destroy millions of years of preserved history. Our expert guides explain how fossils form through the rare process of mineralization, why only a tiny fraction of ancient life becomes fossilized, and how scientists determine the age of specimens using relative dating and radiometric techniques. The experience includes proper documentation procedures, as visitors must record the exact position and condition of their discoveries just like real paleontologists. Educational displays reveal how modern technology like ground-penetrating radar and CT scanning has revolutionized fossil hunting, while preserving the traditional fieldwork skills that remain essential to paleontological discovery.', ARRAY['https://picsum.photos/seed/fossil-dig/600/400'], 6),
    (v_card_id_1, v_ci_parent_1_1, 'Extinction Event', 'Journey through one of the most dramatic chapters in Earth''s history as our multimedia presentation explores the catastrophic event that ended the Age of Dinosaurs 66 million years ago. The leading theory suggests that a massive asteroid, approximately 6 miles in diameter, struck the Yucatan Peninsula with the force of billions of nuclear bombs, instantly vaporizing rock and creating a crater over 110 miles wide. The impact hurled billions of tons of debris into the atmosphere, blocking sunlight for months and triggering a global winter that devastated plant life. Our immersive theater uses cutting-edge visualizations to recreate this apocalyptic event, showing how the impact triggered massive earthquakes, tsunamis hundreds of feet high, and worldwide wildfires that burned entire continents. The presentation explores how this single event eliminated non-avian dinosaurs while allowing small mammals, birds, and other creatures to survive and eventually diversify. Recent research suggests the timing was particularly unfortunate, as many dinosaur species were already under stress from climate change and volcanic activity. Interactive displays let visitors explore alternative extinction theories, including the role of massive volcanic eruptions in India and gradual climate shifts. The exhibit concludes by examining modern extinction threats and how human activities are creating the sixth mass extinction event in Earth''s history.', ARRAY['https://picsum.photos/seed/extinction/600/400'], 7);

  -- Parent 1.2: Mineral & Gems Gallery (7 children)
  INSERT INTO public.content_items (card_id, name, content, image_urls, sort_order)
  VALUES (v_card_id_1, 'Mineral & Gems Gallery', 'Journey into Earth''s treasure vault featuring spectacular crystals, precious gems, and rare minerals from around the globe.', ARRAY['https://picsum.photos/seed/minerals/600/400'], 1)
  RETURNING id INTO v_ci_parent_1_2;
  
  INSERT INTO public.content_items (card_id, parent_id, name, content, image_urls, sort_order)
  VALUES 
    (v_card_id_1, v_ci_parent_1_2, 'Hope Diamond Replica', 'Marvel at our stunning replica of the famous 45-carat blue diamond, learning about its mysterious curse and storied history through Indian royalty.', ARRAY['https://picsum.photos/seed/hope-diamond/600/400'], 0),
    (v_card_id_1, v_ci_parent_1_2, 'Amethyst Geode', 'Step inside our walk-through amethyst geode and discover how these purple crystals form deep within volcanic rock over millions of years.', ARRAY['https://picsum.photos/seed/amethyst/600/400'], 1),
    (v_card_id_1, v_ci_parent_1_2, 'Gold & Silver Specimens', 'Examine pure native gold nuggets and silver formations, learning about precious metal mining and their cultural significance across civilizations.', ARRAY['https://picsum.photos/seed/gold-silver/600/400'], 2),
    (v_card_id_1, v_ci_parent_1_2, 'Fluorite Rainbow', 'Experience our UV light showcase revealing the hidden fluorescent properties of minerals that glow in brilliant colors under special lighting.', ARRAY['https://picsum.photos/seed/fluorite/600/400'], 3),
    (v_card_id_1, v_ci_parent_1_2, 'Meteorite Collection', 'Touch actual pieces of Mars, the Moon, and asteroids in our meteorite collection, including the famous Murchison meteorite containing organic compounds.', ARRAY['https://picsum.photos/seed/meteorites/600/400'], 4),
    (v_card_id_1, v_ci_parent_1_2, 'Crystal Growth Lab', 'Watch live crystal formation in our laboratory setup and participate in hands-on activities to grow your own crystals at home.', ARRAY['https://picsum.photos/seed/crystal-lab/600/400'], 5),
    (v_card_id_1, v_ci_parent_1_2, 'Mining History Diorama', 'Explore the human story of mineral extraction through detailed dioramas showing mining techniques from ancient times to modern methods.', ARRAY['https://picsum.photos/seed/mining/600/400'], 6);

  -- Parent 1.3: Ocean Life Aquarium (7 children)
  INSERT INTO public.content_items (card_id, name, content, image_urls, sort_order)
  VALUES (v_card_id_1, 'Ocean Life Aquarium', 'Dive into the mysteries of marine ecosystems from shallow coral reefs to the deepest ocean trenches.', ARRAY['https://picsum.photos/seed/ocean/600/400'], 2)
  RETURNING id INTO v_ci_parent_1_3;
  
  INSERT INTO public.content_items (card_id, parent_id, name, content, image_urls, sort_order)
  VALUES 
    (v_card_id_1, v_ci_parent_1_3, 'Coral Reef Ecosystem', 'Immerse yourself in our living coral reef tank showcasing the biodiversity hotspot that supports 25% of all marine species.', ARRAY['https://picsum.photos/seed/coral-reef/600/400'], 0),
    (v_card_id_1, v_ci_parent_1_3, 'Giant Pacific Octopus', 'Meet our intelligent cephalopod resident and witness problem-solving abilities that rival those of mammals and birds.', ARRAY['https://picsum.photos/seed/octopus/600/400'], 1),
    (v_card_id_1, v_ci_parent_1_3, 'Shark Species Gallery', 'Learn about shark diversity from tiny lantern sharks to massive whale sharks, and discover their crucial role in ocean health.', ARRAY['https://picsum.photos/seed/sharks/600/400'], 2),
    (v_card_id_1, v_ci_parent_1_3, 'Deep Sea Creatures', 'Explore the alien world of the deep ocean featuring bioluminescent fish, giant tube worms, and other pressure-adapted organisms.', ARRAY['https://picsum.photos/seed/deep-sea/600/400'], 3),
    (v_card_id_1, v_ci_parent_1_3, 'Jellyfish Dreamscape', 'Float through our mesmerizing jellyfish gallery with ethereal lighting that highlights these ancient, pulsing marine animals.', ARRAY['https://picsum.photos/seed/jellyfish/600/400'], 4),
    (v_card_id_1, v_ci_parent_1_3, 'Touch Tank Experience', 'Get hands-on with sea stars, hermit crabs, and anemones in our supervised touch tank guided by marine biology experts.', ARRAY['https://picsum.photos/seed/touch-tank/600/400'], 5),
    (v_card_id_1, v_ci_parent_1_3, 'Marine Conservation Lab', 'Visit our working lab where scientists study ocean pollution, climate change impacts, and species preservation efforts.', ARRAY['https://picsum.photos/seed/conservation/600/400'], 6);

  -- Parent 1.4: Human Evolution Gallery (8 children)
  INSERT INTO public.content_items (card_id, name, content, image_urls, sort_order)
  VALUES (v_card_id_1, 'Human Evolution Gallery', 'Trace the remarkable 7-million-year journey of human evolution from our earliest ancestors to modern civilization.', ARRAY['https://picsum.photos/seed/evolution/600/400'], 3)
  RETURNING id INTO v_ci_parent_1_4;
  
  INSERT INTO public.content_items (card_id, parent_id, name, content, image_urls, sort_order)
  VALUES 
    (v_card_id_1, v_ci_parent_1_4, 'Lucy the Australopithecus', 'Meet our famous 3.2-million-year-old ancestor whose discovery revolutionized our understanding of early human bipedalism and brain development.', ARRAY['https://picsum.photos/seed/lucy/600/400'], 0),
    (v_card_id_1, v_ci_parent_1_4, 'Neanderthal Family', 'Discover our closest extinct relatives through detailed reconstructions showing their sophisticated tool use, art, and burial practices.', ARRAY['https://picsum.photos/seed/neanderthal/600/400'], 1),
    (v_card_id_1, v_ci_parent_1_4, 'Stone Tool Technology', 'Trace technological advancement from simple choppers to sophisticated spears through our hands-on stone tool demonstration area.', ARRAY['https://picsum.photos/seed/stone-tools/600/400'], 2),
    (v_card_id_1, v_ci_parent_1_4, 'Cave Art Gallery', 'Experience reproductions of Paleolithic cave paintings from Lascaux and Altamira showcasing humanity''s earliest artistic expressions.', ARRAY['https://picsum.photos/seed/cave-art/600/400'], 3),
    (v_card_id_1, v_ci_parent_1_4, 'Migration Out of Africa', 'Follow the epic journey of early humans as they spread across continents, adapting to diverse environments and climates.', ARRAY['https://picsum.photos/seed/migration/600/400'], 4),
    (v_card_id_1, v_ci_parent_1_4, 'Fossil Skull Collection', 'Examine precise casts of key hominin skulls showing the gradual increase in brain size and facial structure changes.', ARRAY['https://picsum.photos/seed/skulls/600/400'], 5),
    (v_card_id_1, v_ci_parent_1_4, 'DNA Analysis Lab', 'Learn about genetic archaeology and how scientists extract and analyze ancient DNA to trace human ancestry and migration.', ARRAY['https://picsum.photos/seed/dna-lab/600/400'], 6),
    (v_card_id_1, v_ci_parent_1_4, 'Modern Human Diversity', 'Celebrate human genetic and cultural diversity through our interactive displays on global populations and adaptations.', ARRAY['https://picsum.photos/seed/diversity/600/400'], 7);

  -- Parent 1.5: Earth Science & Climate (7 children)
  INSERT INTO public.content_items (card_id, name, content, image_urls, sort_order)
  VALUES (v_card_id_1, 'Earth Science & Climate', 'Understand our dynamic planet through geological processes, climate systems, and environmental changes over deep time.', ARRAY['https://picsum.photos/seed/earth-science/600/400'], 4)
  RETURNING id INTO v_ci_parent_1_5;
  
  INSERT INTO public.content_items (card_id, parent_id, name, content, image_urls, sort_order)
  VALUES 
    (v_card_id_1, v_ci_parent_1_5, 'Earthquake Simulator', 'Experience the power of tectonic forces in our earthquake simulator demonstrating plate boundaries and seismic wave propagation.', ARRAY['https://picsum.photos/seed/earthquake/600/400'], 0),
    (v_card_id_1, v_ci_parent_1_5, 'Volcano Cross-Section', 'Explore our massive volcano model showing magma chambers, eruption types, and the formation of igneous rocks and landforms.', ARRAY['https://picsum.photos/seed/volcano/600/400'], 1),
    (v_card_id_1, v_ci_parent_1_5, 'Ice Age Diorama', 'Journey through past ice ages and learn how glacial cycles shaped modern landscapes, sea levels, and species distribution.', ARRAY['https://picsum.photos/seed/ice-age/600/400'], 2),
    (v_card_id_1, v_ci_parent_1_5, 'Climate Change Timeline', 'Track Earth''s climate history from greenhouse worlds to ice houses, and examine human impacts on modern climate systems.', ARRAY['https://picsum.photos/seed/climate/600/400'], 3),
    (v_card_id_1, v_ci_parent_1_5, 'Rock Cycle Interactive', 'Follow rocks through their endless journey of formation, transformation, and recycling in our hands-on geological process display.', ARRAY['https://picsum.photos/seed/rock-cycle/600/400'], 4),
    (v_card_id_1, v_ci_parent_1_5, 'Fossil Fuel Formation', 'Discover how ancient life becomes today''s energy sources through our coal, oil, and natural gas formation timeline.', ARRAY['https://picsum.photos/seed/fossil-fuels/600/400'], 5),
    (v_card_id_1, v_ci_parent_1_5, 'Renewable Energy Lab', 'Explore sustainable alternatives through working models of solar, wind, geothermal, and hydroelectric power generation.', ARRAY['https://picsum.photos/seed/renewable/600/400'], 6);

  -- Standalone Content Items for Card 1
  INSERT INTO public.content_items (card_id, name, content, image_urls, sort_order)
  VALUES 
    (v_card_id_1, 'Museum Shop & Cafe', 'Visit our museum shop for educational books, fossil replicas, and unique gifts, plus enjoy locally-sourced refreshments in our cafe.', ARRAY['https://picsum.photos/seed/museum-shop/600/400'], 5),
    (v_card_id_1, 'Educational Programs', 'Join our guided tours, workshops, and lectures designed for all ages, from toddler discovery sessions to graduate-level seminars.', ARRAY['https://picsum.photos/seed/education/600/400'], 6),
    (v_card_id_1, 'Research Collections', 'Peek behind the scenes at our vast research collections containing millions of specimens available to scientists worldwide.', ARRAY['https://picsum.photos/seed/research/600/400'], 7);

  -- Card 2: Modern Art Gallery Collection (AI enabled)
  INSERT INTO public.cards (user_id, name, description, image_urls, conversation_ai_enabled, ai_prompt)
  VALUES (v_user_id, 'Modern Art Gallery Collection', 'Immerse yourself in the revolutionary movements that transformed art from the late 19th century to today. Our carefully curated collection showcases masterpieces from Impressionism through Contemporary Art, featuring works by renowned artists alongside emerging voices that challenge conventional boundaries. Each gallery space tells the story of artistic evolution, cultural movements, and the bold visionaries who redefined creative expression. From Van Gogh''s swirling brushstrokes to Pollock''s dynamic abstractions, from Picasso''s cubist innovations to contemporary digital installations, experience how art reflects and shapes our understanding of the human condition. This digital companion provides expert insights into artistic techniques, historical contexts, and the personal stories behind each masterpiece, making fine art accessible and engaging for visitors of all backgrounds and ages.', ARRAY['https://images.unsplash.com/photo-1541961017774-22349e4a1262?w=400&h=600&fit=crop']::TEXT[], true, 'You are a distinguished art historian and museum curator with expertise in modern and contemporary art movements, artistic techniques, and cultural contexts. Help visitors understand artistic styles, interpret symbolic meanings, discuss historical significance, and appreciate the evolution of creative expression. Be passionate about art while making complex concepts accessible to all audience levels.')
  RETURNING id INTO v_card_id_2;

  -- Content Items for Card 2 - 5 parent items with 7+ children each
  
  -- Parent 2.1: Impressionism Gallery (8 children)
  INSERT INTO public.content_items (card_id, name, content, image_urls, sort_order)
  VALUES (v_card_id_2, 'Impressionism Gallery', 'Experience the revolutionary movement that broke free from academic traditions, capturing fleeting moments of light and color in everyday life.', ARRAY['https://picsum.photos/seed/impressionism/600/400'], 0)
  RETURNING id INTO v_ci_parent_2_1;
  
  INSERT INTO public.content_items (card_id, parent_id, name, content, image_urls, sort_order)
  VALUES 
    (v_card_id_2, v_ci_parent_2_1, 'Monet Water Lilies', 'Claude Monet''s ethereal pond series represents the culmination of the Impressionist master''s lifelong obsession with capturing the ephemeral effects of light and atmosphere. Painted in his beloved garden at Giverny between 1896 and 1926, these monumental canvases transform his lily pond into a universe of shimmering color and reflection. Monet''s revolutionary technique eliminated traditional perspective, creating an almost abstract vision where water, sky, and vegetation merge in a symphony of blues, greens, and purples. The artist painted over 250 oil paintings of his water garden, working obsessively despite failing eyesight and cataracts that altered his color perception. These late works influenced generations of abstract artists who saw in Monet''s dissolved forms a pathway beyond representation. Standing before these massive paintings, visitors experience the meditative quality that Monet intended, as the eye loses itself in the endless play of light across water. The series represents not just a garden, but a spiritual sanctuary where the artist found solace during World War I and personal loss, transforming his private refuge into a universal symbol of peace and transcendence.', ARRAY['https://picsum.photos/seed/monet-lilies/600/400'], 0),
    (v_card_id_2, v_ci_parent_2_1, 'Renoir Luncheon', 'Auguste Renoir''s "Luncheon of the Boating Party" captures the joie de vivre of Belle Époque France, showcasing the artist''s mastery of light, color, and human warmth in a single, harmonious composition. Set on the balcony of the Maison Fournaise restaurant along the Seine, this masterpiece depicts Renoir''s friends enjoying a leisurely afternoon of food, wine, and conversation. Each figure is painted with individual character while contributing to the overall rhythm of the composition, demonstrating Renoir''s ability to balance portraiture with impressionistic technique. The dappled sunlight filtering through the awning creates a complex pattern of shadows and highlights that dance across faces, clothing, and still-life elements. Renoir spent months perfecting this work, making numerous preparatory sketches and studies to achieve the perfect balance between spontaneity and careful construction. The painting celebrates the emerging leisure culture of modern Paris, where middle-class citizens could escape urban life for recreational activities along the river. Notice how Renoir''s brushwork varies from precise detail in the faces to loose, energetic strokes in the background foliage, creating a sense of atmospheric depth that draws viewers into this convivial gathering of friends united by the simple pleasure of sharing a meal in beautiful surroundings.', ARRAY['https://picsum.photos/seed/renoir-luncheon/600/400'], 1),
    (v_card_id_2, v_ci_parent_2_1, 'Degas Ballet Dancers', 'Edgar Degas revolutionized ballet painting by taking viewers behind the scenes to witness the rigorous training, exhaustion, and determination that creates the illusion of effortless grace on stage. Unlike traditional academic painters who idealized their subjects, Degas showed dancers adjusting their slippers, stretching at the barre, and collapsing in exhaustion after rehearsals. His innovative compositions often cut figures at dramatic angles, influenced by Japanese woodblock prints and the new art of photography. Working primarily in pastels, Degas developed unique techniques for capturing the shimmer of tulle tutus and the gleam of sweat on tired bodies. His dancer series spans over 1,500 works created throughout his career, documenting the Paris Opera Ballet during its golden age. Many of his models were young working-class girls who endured grueling training for meager wages, and Degas captured both their vulnerability and strength with remarkable empathy. The artist''s failing eyesight in later years led him to work increasingly in sculpture, creating wax figures of dancers that he used as models for his paintings. These intimate glimpses into the world of professional dance reveal the physical and emotional demands of artistic perfection, making visible the hidden labor behind public beauty and transforming ballet from mere entertainment into a profound meditation on dedication, sacrifice, and the pursuit of artistic excellence.', ARRAY['https://picsum.photos/seed/degas-ballet/600/400'], 2),
    (v_card_id_2, v_ci_parent_2_1, 'Cézanne Mont Sainte-Victoire', 'Paul Cézanne''s obsessive study of Mont Sainte-Victoire represents one of art history''s most profound relationships between artist and subject, spanning over 30 paintings and countless sketches created from 1882 until his death in 1906. From his studio in Aix-en-Provence, Cézanne could see this limestone peak rising majestically from the Provençal landscape, and it became his laboratory for exploring how geometric forms could capture the essence of natural phenomena. Unlike the Impressionists who painted fleeting atmospheric effects, Cézanne sought to reveal the mountain''s underlying structure through carefully constructed planes of color that seem to vibrate with inner energy. His revolutionary technique of "constructive brushstrokes" built form through color relationships rather than traditional light and shadow, anticipating the abstract movements that would follow. Each painting of the mountain shows a different emotional and visual approach: some emphasize its monumental permanence, others capture its integration with the surrounding valley and sky. Cézanne''s methodical working process often required months to complete a single canvas, as he studied how colors interacted to create spatial depth without relying on Renaissance perspective systems. These works bridged 19th-century naturalism with 20th-century abstraction, inspiring artists from Picasso to Kandinsky who recognized in Cézanne''s geometric analysis of nature a new language for expressing the modern world''s complexity and fragmentation.', ARRAY['https://picsum.photos/seed/cezanne-mountain/600/400'], 3),
    (v_card_id_2, v_ci_parent_2_1, 'Manet Olympia Scandal', 'Édouard Manet''s "Olympia" created one of the greatest scandals in art history when it debuted at the Paris Salon of 1865, challenging every convention of acceptable female representation in academic painting. Inspired by Titian''s revered "Venus of Urbino," Manet transformed the classical goddess into a contemporary Parisian prostitute, stripping away romantic idealization to present stark reality with unflinching directness. The model, Victorine Meurent, stares boldly at viewers with defiant confidence rather than the modest downcast eyes expected of respectable women, while her black cat (replacing Titian''s sleeping dog symbolizing fidelity) represents sexuality and independence. Manet''s revolutionary painting technique eliminated traditional modeling and gradual tonal transitions, using flat areas of color and harsh contrasts that made the figure appear to emerge from the canvas with shocking immediacy. The black servant bringing flowers likely from a client emphasizes the commercial nature of the transaction, while Olympia''s bracelet, earrings, and the orchid Flowered in her hair signal her profession to contemporary viewers who understood these symbolic codes. Critics attacked both the subject matter and Manet''s "crude" technique, but progressive writers like Émile Zola defended the work as honest modern art that refused to disguise contemporary reality with classical mythology. The painting''s influence extended far beyond its initial controversy, inspiring generations of artists to abandon idealization in favor of authentic observation, establishing Manet as the father of modern art who liberated painting from academic constraints and opened new possibilities for artistic expression.', ARRAY['https://picsum.photos/seed/manet-olympia/600/400'], 4),
    (v_card_id_2, v_ci_parent_2_1, 'Cassatt Mother and Child', 'Mary Cassatt broke barriers as the only American and one of the few women accepted into the French Impressionist circle, bringing a uniquely feminine perspective to the male-dominated art world of 19th-century Paris. Her intimate portrayals of mothers and children reveal a deep understanding of domestic life that her male contemporaries rarely captured with such authenticity and emotional depth. Working primarily in pastels and oils, Cassatt developed a distinctive style that combined Impressionist color theory with the linear precision she learned from Japanese woodblock prints, creating compositions that feel both spontaneous and carefully structured. Her subjects were often drawn from her own social circle - wealthy American expatriates living in Paris - but she imbued these privileged domestic scenes with universal themes of maternal love, childhood innocence, and family bonds. Unlike many artists who idealized motherhood, Cassatt showed the reality of child-rearing: the fatigue, the tenderness, the everyday moments of bathing, dressing, and comforting. Her technique of using broken brushstrokes and unmixed colors created a luminous quality that made skin appear to glow with inner warmth. As a woman in a profession dominated by men, Cassatt faced significant challenges but earned respect through her artistic excellence and business acumen. Her work influenced American collectors to appreciate Impressionism and helped establish the movement in the United States, making her a crucial bridge between European and American art cultures.', ARRAY['https://picsum.photos/seed/cassatt-mother/600/400'], 5),
    (v_card_id_2, v_ci_parent_2_1, 'Pissarro Rural Scenes', 'Camille Pissarro, often called the "dean of Impressionist painters," captured the changing French countryside during the Industrial Revolution with remarkable sensitivity to both human dignity and natural beauty. As the oldest member of the Impressionist group and the only artist to participate in all eight of their exhibitions, Pissarro served as a mentor and peacemaker among the often contentious personalities of the movement. His rural scenes document the transformation of traditional agricultural life as railroads, factories, and modern commerce began reshaping the French landscape. Working en plein air in villages around Paris, Pissarro painted peasants at work in the fields, market scenes bustling with activity, and quiet village streets where old and new ways of life intersected. His technique evolved from the dark palette of his early Barbizon influence to the bright, broken brushwork that characterized mature Impressionism, always maintaining a sense of social consciousness that distinguished him from his peers. During the 1880s, Pissarro briefly adopted the pointillist technique of Neo-Impressionism, demonstrating his openness to artistic experimentation even in his later career. His political views as an anarchist influenced his choice of subjects, often highlighting the dignity of manual labor and the beauty of simple, unidealized rural life. These paintings serve as valuable historical documents of a disappearing way of life while celebrating the enduring connection between humans and the land they cultivate.', ARRAY['https://picsum.photos/seed/pissarro-rural/600/400'], 6),
    (v_card_id_2, v_ci_parent_2_1, 'Sisley River Thames', 'Alfred Sisley, the most purely Impressionist of all the movement''s founders, dedicated his entire career to landscape painting with an unwavering commitment to capturing the fleeting effects of light and atmosphere. Born in Paris to British parents, Sisley brought an outsider''s fresh perspective to French countryside painting, developing a distinctive style characterized by delicate color harmonies and sensitive observation of natural phenomena. His Thames series, painted during visits to England in the 1870s, demonstrates his mastery of depicting water in all its moods - from mirror-calm reflections to choppy surfaces broken by wind and boat traffic. These works show Sisley''s remarkable ability to suggest the weight and movement of water through carefully orchestrated brushstrokes that seem to flow with the river''s current. Unlike some of his contemporaries who painted the same subjects repeatedly, Sisley preferred to explore different locations, always seeking new challenges in light conditions and atmospheric effects. His palette remained consistently lighter and more optimistic than many Impressionists, favoring silvery blues, soft greens, and warm earth tones that created harmonious, peaceful compositions. Despite producing consistently beautiful work throughout his career, Sisley never achieved the commercial success of Monet or Renoir, remaining dedicated to his artistic vision even when facing financial hardship. His Thames paintings capture the industrial energy of Victorian London while maintaining the poetic sensibility that made him beloved among fellow artists and discerning collectors who appreciated his subtle, unforced approach to Impressionist principles.', ARRAY['https://picsum.photos/seed/sisley-thames/600/400'], 7),
    (v_card_id_2, v_ci_parent_2_2, 'Picasso Blue Period', 'Pablo Picasso''s Blue Period (1901-1904) emerged from profound personal loss and financial hardship, producing some of the most emotionally resonant works in modern art history. Following the suicide of his close friend Carlos Casagemas in 1901, the young artist fell into a deep depression that manifested in paintings dominated by various shades of blue - a color traditionally associated with melancholy, spirituality, and introspection. Working in poverty between Paris and Barcelona, Picasso created haunting images of beggars, street children, blind musicians, and other marginalized figures who reflected his own sense of isolation and despair. The monochromatic blue palette unified these works while creating an otherworldly atmosphere that elevated social realism into poetic meditation on human suffering. Paintings like "The Old Guitarist" and "La Vie" feature elongated, ethereal figures rendered with simplified forms that show the influence of El Greco and medieval art. The period''s most famous work, "The Blue Room," depicts Picasso''s modest studio with its sparse furnishings and reproductions of Toulouse-Lautrec posters on the walls. Despite their sorrowful subject matter, these paintings demonstrate remarkable technical mastery and emotional depth that established Picasso''s reputation as a serious artist rather than mere entertainer. The Blue Period ended as Picasso''s circumstances improved and his palette warmed into the more optimistic Rose Period, but these early works remain among his most beloved and psychologically penetrating creations, proving that great art often emerges from life''s darkest moments.', ARRAY['https://picsum.photos/seed/picasso-blue/600/400'], 3),
    (v_card_id_2, v_ci_parent_2_2, 'Synthetic Cubism Collages', 'Synthetic Cubism, developed by Picasso and Braque around 1912, revolutionized art by introducing real-world materials directly into paintings through collage and assemblage techniques that blurred the boundaries between high art and everyday life. Unlike Analytical Cubism''s deconstruction of objects into geometric fragments, Synthetic Cubism built up compositions from disparate elements - newspaper clippings, wallpaper, sheet music, rope, and other found materials - creating new realities rather than analyzing existing ones. This radical approach challenged traditional notions of artistic skill and authenticity while questioning what constitutes legitimate art materials. Braque''s pioneering use of papier collé (pasted paper) in works like "Fruit Dish and Glass" introduced actual newspaper into fine art, creating layers of meaning as the printed text interacted with painted elements. Picasso pushed these innovations further, incorporating sand, cloth, and even three-dimensional objects into his compositions, creating works that functioned as both paintings and sculptures. The technique allowed artists to reference contemporary life directly through newspaper headlines, advertisements, and popular culture imagery, making art more immediately relevant to modern urban experience. Synthetic Cubist works often employed brighter colors and more playful compositions than their analytical predecessors, reflecting the movement''s increasing confidence and acceptance by avant-garde circles. These innovative mixed-media techniques influenced countless subsequent art movements, from Dadaism and Surrealism to Pop Art and contemporary installation practices, establishing collage as a fundamental strategy for modern and contemporary artistic expression.', ARRAY['https://picsum.photos/seed/synthetic-cubism/600/400'], 4),
    (v_card_id_2, v_ci_parent_2_2, 'Juan Gris Precision', 'Juan Gris brought mathematical precision and classical harmony to Cubism, developing a more systematic and intellectually rigorous approach that earned him recognition as the movement''s most scholarly practitioner. Born José Victoriano González-Pérez in Madrid, Gris moved to Paris in 1906 and initially supported himself through commercial illustration before fully committing to fine art around 1911. His mature Cubist works demonstrate a methodical approach to geometric decomposition that contrasts sharply with Picasso''s intuitive experimentation and Braque''s painterly sensibilities. Gris developed a unique technique he called "architectural Cubism," using the golden ratio and other mathematical principles to create compositions of exceptional balance and clarity. His still lifes typically feature everyday objects - guitars, bottles, newspapers, books - arranged according to rigorous geometric principles that create sense of order within fragmentation. The artist''s sophisticated color harmonies, often employing complementary relationships and subtle gradations, add emotional warmth to his analytical approach. Works like "Portrait of Picasso" and "The Sunblind" demonstrate his ability to combine Cubist innovation with traditional concerns for beauty and craftsmanship. Gris''s theoretical writings on Cubism reveal his deep intellectual engagement with the movement''s philosophical implications, viewing art as a means of discovering universal truths through systematic investigation of visual phenomena. His influence extended beyond painting into stage design, book illustration, and design theory, establishing principles that would influence generations of artists seeking to balance innovation with classical values in their pursuit of modern artistic expression.', ARRAY['https://picsum.photos/seed/juan-gris/600/400'], 5);

  -- Parent 2.3: Abstract Expressionism (7 children)
  INSERT INTO public.content_items (card_id, name, content, image_urls, sort_order)
  VALUES (v_card_id_2, 'Abstract Expressionism', 'Experience the raw emotional power of post-war American art that established New York as the new center of the art world.', ARRAY['https://picsum.photos/seed/abstract-exp/600/400'], 2)
  RETURNING id INTO v_ci_parent_2_3;
  
  INSERT INTO public.content_items (card_id, parent_id, name, content, image_urls, sort_order)
  VALUES 
    (v_card_id_2, v_ci_parent_2_3, 'Pollock Action Painting', 'Jackson Pollock''s revolutionary drip technique creating dynamic compositions through rhythmic gestures and spontaneous energy.', ARRAY['https://picsum.photos/seed/pollock-drip/600/400'], 0),
    (v_card_id_2, v_ci_parent_2_3, 'Rothko Color Fields', 'Mark Rothko''s luminous color rectangles designed to evoke profound spiritual and emotional responses in contemplative viewers.', ARRAY['https://picsum.photos/seed/rothko-fields/600/400'], 1),
    (v_card_id_2, v_ci_parent_2_3, 'de Kooning Women', 'Willem de Kooning''s aggressive brushwork and distorted female figures expressing post-war anxiety and human condition.', ARRAY['https://picsum.photos/seed/dekooning-women/600/400'], 2),
    (v_card_id_2, v_ci_parent_2_3, 'Motherwell Elegies', 'Robert Motherwell''s black and white compositions mourning the Spanish Civil War with bold, simplified forms.', ARRAY['https://picsum.photos/seed/motherwell-elegies/600/400'], 3),
    (v_card_id_2, v_ci_parent_2_3, 'Kline Black Brushstrokes', 'Franz Kline''s monumental black and white paintings inspired by urban architecture and industrial landscapes.', ARRAY['https://picsum.photos/seed/kline-black/600/400'], 4),
    (v_card_id_2, v_ci_parent_2_3, 'Newman Zip Paintings', 'Barnett Newman''s vertical lines dividing color fields, creating sublime experiences of space and transcendence.', ARRAY['https://picsum.photos/seed/newman-zip/600/400'], 5),
    (v_card_id_2, v_ci_parent_2_3, 'Gottlieb Pictographs', 'Adolph Gottlieb''s primitive symbols and mythological references reflecting unconscious and archetypal themes.', ARRAY['https://picsum.photos/seed/gottlieb-pictographs/600/400'], 6);

  -- Parent 2.4: Pop Art Revolution (8 children)
  INSERT INTO public.content_items (card_id, name, content, image_urls, sort_order)
  VALUES (v_card_id_2, 'Pop Art Revolution', 'Celebrate the bold movement that brought commercial imagery and popular culture into the fine art world with vibrant colors and mass media aesthetics.', ARRAY['https://picsum.photos/seed/pop-art/600/400'], 3)
  RETURNING id INTO v_ci_parent_2_4;
  
  INSERT INTO public.content_items (card_id, parent_id, name, content, image_urls, sort_order)
  VALUES 
    (v_card_id_2, v_ci_parent_2_4, 'Warhol Campbell Soup', 'Andy Warhol''s iconic soup cans transforming everyday consumer products into high art through silkscreen repetition and commercial aesthetics.', ARRAY['https://picsum.photos/seed/warhol-soup/600/400'], 0),
    (v_card_id_2, v_ci_parent_2_4, 'Lichtenstein Comics', 'Roy Lichtenstein''s Ben-Day dot paintings elevating comic book imagery to fine art with precise mechanical reproduction techniques.', ARRAY['https://picsum.photos/seed/lichtenstein-comics/600/400'], 1),
    (v_card_id_2, v_ci_parent_2_4, 'Hockney Swimming Pools', 'David Hockney''s sun-drenched California landscapes celebrating leisure and affluence with bold colors and geometric forms.', ARRAY['https://picsum.photos/seed/hockney-pools/600/400'], 2),
    (v_card_id_2, v_ci_parent_2_4, 'Warhol Marilyn Monroe', 'Repeated portraits of the Hollywood icon exploring themes of celebrity, mortality, and mass media through silkscreen printing.', ARRAY['https://picsum.photos/seed/warhol-marilyn/600/400'], 3),
    (v_card_id_2, v_ci_parent_2_4, 'Oldenburg Soft Sculptures', 'Claes Oldenburg''s oversized everyday objects reimagined in unexpected materials, challenging perceptions of scale and material.', ARRAY['https://picsum.photos/seed/oldenburg-soft/600/400'], 4),
    (v_card_id_2, v_ci_parent_2_4, 'Rosenquist Collages', 'James Rosenquist''s fragmented advertising imagery creating surreal compositions from consumer culture elements.', ARRAY['https://picsum.photos/seed/rosenquist-collage/600/400'], 5),
    (v_card_id_2, v_ci_parent_2_4, 'Wesselman Great American Nude', 'Tom Wesselmann''s bold figure studies combining patriotic colors with commercial imagery and flat graphic design.', ARRAY['https://picsum.photos/seed/wesselmann-nude/600/400'], 6),
    (v_card_id_2, v_ci_parent_2_4, 'Indiana LOVE Sculpture', 'Robert Indiana''s iconic typography art transforming simple words into powerful visual statements about American culture.', ARRAY['https://picsum.photos/seed/indiana-love/600/400'], 7);

  -- Parent 2.5: Contemporary Art & Digital Media (7 children)
  INSERT INTO public.content_items (card_id, name, content, image_urls, sort_order)
  VALUES (v_card_id_2, 'Contemporary Art & Digital Media', 'Explore cutting-edge artistic expressions that challenge traditional boundaries through technology, installation, and conceptual innovation.', ARRAY['https://picsum.photos/seed/contemporary/600/400'], 4)
  RETURNING id INTO v_ci_parent_2_5;
  
  INSERT INTO public.content_items (card_id, parent_id, name, content, image_urls, sort_order)
  VALUES 
    (v_card_id_2, v_ci_parent_2_5, 'Interactive Digital Installations', 'Immersive art experiences that respond to viewer movement and participation through sensors, projection mapping, and real-time algorithms.', ARRAY['https://picsum.photos/seed/digital-interactive/600/400'], 0),
    (v_card_id_2, v_ci_parent_2_5, 'Banksy Street Art', 'Anonymous activist art that transforms urban landscapes with political commentary and social critique through stencil and guerrilla techniques.', ARRAY['https://picsum.photos/seed/banksy-street/600/400'], 1),
    (v_card_id_2, v_ci_parent_2_5, 'Kusama Infinity Rooms', 'Yayoi Kusama''s mesmerizing mirrored environments with polka dot obsessions creating infinite spaces and immersive experiences.', ARRAY['https://picsum.photos/seed/kusama-infinity/600/400'], 2),
    (v_card_id_2, v_ci_parent_2_5, 'Ai Weiwei Activism', 'Provocative political art challenging authority and human rights through traditional Chinese techniques and contemporary materials.', ARRAY['https://picsum.photos/seed/ai-weiwei/600/400'], 3),
    (v_card_id_2, v_ci_parent_2_5, 'Video Art Pioneers', 'Moving image artworks exploring time, narrative, and performance through single-channel videos and multi-screen installations.', ARRAY['https://picsum.photos/seed/video-art/600/400'], 4),
    (v_card_id_2, v_ci_parent_2_5, 'Virtual Reality Experiences', 'Cutting-edge VR artworks that transport viewers into entirely digital worlds and alternate realities for artistic exploration.', ARRAY['https://picsum.photos/seed/vr-art/600/400'], 5),
    (v_card_id_2, v_ci_parent_2_5, 'Bio-Art & Science', 'Artists working with living organisms, genetic engineering, and biotechnology to create thought-provoking works about life itself.', ARRAY['https://picsum.photos/seed/bio-art/600/400'], 6);

  -- Standalone Content Items for Card 2
  INSERT INTO public.content_items (card_id, name, content, image_urls, sort_order)
  VALUES 
    (v_card_id_2, 'Gallery Shop & Bookstore', 'Discover art books, prints, unique gifts, and exhibition catalogs in our carefully curated museum shop featuring works by featured artists.', ARRAY['https://picsum.photos/seed/art-shop/600/400'], 5),
    (v_card_id_2, 'Artist Talks & Workshops', 'Join renowned artists, curators, and art historians for intimate conversations, hands-on workshops, and behind-the-scenes gallery insights.', ARRAY['https://picsum.photos/seed/art-talks/600/400'], 6),
    (v_card_id_2, 'Private Collection Tours', 'Explore our exclusive collection storage areas and conservation labs where masterpieces are preserved for future generations.', ARRAY['https://picsum.photos/seed/private-tours/600/400'], 7);

  -- Card 3: Medieval Castle & Grounds Experience (AI enabled)
  INSERT INTO public.cards (user_id, name, description, image_urls, conversation_ai_enabled, ai_prompt)
  VALUES (v_user_id, 'Medieval Castle & Grounds Experience', 'Step back in time and explore eight centuries of royal history within our magnificently preserved medieval fortress. This interactive digital guide brings to life the stories of kings and queens, knights and nobles, servants and craftsmen who once called this castle home. Discover the architectural marvels of our great hall, the strategic brilliance of our defensive walls, and the daily rhythms of medieval court life. From the imposing battlements offering panoramic countryside views to the intimate chambers where history''s most dramatic events unfolded, every stone tells a story. Our extensive grounds feature period gardens, working blacksmith shops, and seasonal festivals that transport visitors to the age of chivalry. Perfect for families, history enthusiasts, and anyone fascinated by medieval culture, this digital companion enhances your visit with expert historical insights, architectural details, and engaging stories that make the past feel remarkably present and alive.', ARRAY['https://images.unsplash.com/photo-1510846801702-8d8a2e6c5cfe?w=400&h=600&fit=crop']::TEXT[], true, 'You are an expert medieval historian and castle guide with deep knowledge of royal history, medieval architecture, courtly life, and feudal society. Help visitors understand historical contexts, explain architectural features, share stories of royal intrigue, and connect medieval life to modern times. Be engaging and informative while bringing the past to life through vivid storytelling.')
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

  -- Card 4: Botanical Garden & Conservatory (AI enabled)
  INSERT INTO public.cards (user_id, name, description, image_urls, conversation_ai_enabled, ai_prompt)
  VALUES (v_user_id, 'Botanical Garden & Conservatory', 'Immerse yourself in a living museum of plant diversity showcasing over 10,000 species from around the world. Our award-winning botanical garden spans 150 acres of meticulously curated landscapes, from Mediterranean hillsides to tropical rainforest canopies. Discover rare orchids in our Victorian glasshouse, explore sustainable growing practices in our demonstration gardens, and learn about plant conservation efforts protecting endangered species. The conservatory houses climate-controlled environments replicating ecosystems from six continents, allowing visitors to journey from desert cacti to alpine wildflowers in a single afternoon. Interactive displays reveal the fascinating relationships between plants and their pollinators, while our research facilities showcase groundbreaking work in plant breeding and genetic preservation. Whether you''re a gardening enthusiast, nature lover, or simply seeking tranquil beauty, this digital guide enriches your experience with botanical expertise, conservation insights, and practical gardening advice to inspire your own green spaces.', ARRAY['https://images.unsplash.com/photo-1416879595882-3373a0480b5b?w=400&h=600&fit=crop']::TEXT[], true, 'You are a master botanist and horticulturist with expertise in plant taxonomy, conservation biology, garden design, and sustainable growing practices. Help visitors identify plants, understand ecological relationships, learn about plant conservation, and discover practical gardening techniques. Be enthusiastic about plant life while making botanical science accessible and inspiring.')
  RETURNING id INTO v_card_id_4;

  -- Content Items for Card 4 (Botanical Garden) - 3 parent items with 5+ children each
  
  -- Parent 4.1: Tropical Conservatory (6 children)
  INSERT INTO public.content_items (card_id, name, content, image_urls, sort_order)
  VALUES (v_card_id_4, 'Tropical Conservatory', 'Step into our climate-controlled tropical paradise featuring lush rainforest plants from around the equatorial belt.', ARRAY['https://picsum.photos/seed/tropical-conservatory/600/400'], 0)
  RETURNING id INTO v_ci_parent_4_1;
  
  INSERT INTO public.content_items (card_id, parent_id, name, content, image_urls, sort_order)
  VALUES 
    (v_card_id_4, v_ci_parent_4_1, 'Orchid Collection', 'Marvel at over 500 species of exotic orchids in our award-winning display featuring rare and endangered varieties from Madagascar to Malaysia.', ARRAY['https://picsum.photos/seed/orchids/600/400'], 0),
    (v_card_id_4, v_ci_parent_4_1, 'Carnivorous Plants', 'Discover nature''s predators including Venus flytraps, pitcher plants, and sundews that have evolved fascinating hunting strategies.', ARRAY['https://picsum.photos/seed/carnivorous/600/400'], 1),
    (v_card_id_4, v_ci_parent_4_1, 'Banana & Coffee Plants', 'Learn about economically important tropical crops and taste fresh samples from our working plantation exhibits.', ARRAY['https://picsum.photos/seed/banana-coffee/600/400'], 2),
    (v_card_id_4, v_ci_parent_4_1, 'Rainforest Canopy', 'Walk through our elevated treetop pathway and observe epiphytes, bromeliads, and the complex ecosystem layers.', ARRAY['https://picsum.photos/seed/canopy-walk/600/400'], 3),
    (v_card_id_4, v_ci_parent_4_1, 'Medicinal Plants', 'Explore traditional healing plants and modern pharmaceutical discoveries derived from rainforest biodiversity.', ARRAY['https://picsum.photos/seed/medicinal-plants/600/400'], 4),
    (v_card_id_4, v_ci_parent_4_1, 'Butterfly Garden', 'Experience our living butterfly exhibit where tropical species flutter freely among their native host plants.', ARRAY['https://picsum.photos/seed/butterflies/600/400'], 5);

  -- Parent 4.2: Desert & Succulent Gardens (5 children)
  INSERT INTO public.content_items (card_id, name, content, image_urls, sort_order)
  VALUES (v_card_id_4, 'Desert & Succulent Gardens', 'Explore the remarkable adaptations of plants that thrive in the world''s most challenging arid environments.', ARRAY['https://picsum.photos/seed/desert-garden/600/400'], 1)
  RETURNING id INTO v_ci_parent_4_2;
  
  INSERT INTO public.content_items (card_id, parent_id, name, content, image_urls, sort_order)
  VALUES 
    (v_card_id_4, v_ci_parent_4_2, 'Giant Cacti Collection', 'Stand beneath towering saguaro and barrel cacti while learning about their incredible water storage capabilities and longevity.', ARRAY['https://picsum.photos/seed/giant-cacti/600/400'], 0),
    (v_card_id_4, v_ci_parent_4_2, 'Succulent Varieties', 'Discover the diverse world of aloes, agaves, and echeveria with their stunning geometric forms and survival strategies.', ARRAY['https://picsum.photos/seed/succulents/600/400'], 1),
    (v_card_id_4, v_ci_parent_4_2, 'Desert Wildflower Display', 'Witness the spectacular seasonal bloom when desert plants burst into color after rare rainfall events.', ARRAY['https://picsum.photos/seed/desert-flowers/600/400'], 2),
    (v_card_id_4, v_ci_parent_4_2, 'Water-Wise Gardening', 'Learn practical techniques for creating beautiful, drought-resistant landscapes for your own home garden.', ARRAY['https://picsum.photos/seed/water-wise/600/400'], 3),
    (v_card_id_4, v_ci_parent_4_2, 'Desert Ecosystem', 'Understand the complex relationships between desert plants, pollinators, and the animals that depend on them.', ARRAY['https://picsum.photos/seed/desert-ecosystem/600/400'], 4);

  -- Parent 4.3: Heritage Rose Garden (5 children)
  INSERT INTO public.content_items (card_id, name, content, image_urls, sort_order)
  VALUES (v_card_id_4, 'Heritage Rose Garden', 'Stroll through our romantic collection of heirloom roses representing centuries of cultivation and breeding excellence.', ARRAY['https://picsum.photos/seed/rose-garden/600/400'], 2)
  RETURNING id INTO v_ci_parent_4_3;
  
  INSERT INTO public.content_items (card_id, parent_id, name, content, image_urls, sort_order)
  VALUES 
    (v_card_id_4, v_ci_parent_4_3, 'Ancient Rose Varieties', 'Discover roses grown in medieval monastery gardens and the varieties that inspired poets and artists throughout history.', ARRAY['https://picsum.photos/seed/ancient-roses/600/400'], 0),
    (v_card_id_4, v_ci_parent_4_3, 'Tea & Climbing Roses', 'Admire our spectacular climbing displays and learn about the development of repeat-flowering tea roses.', ARRAY['https://picsum.photos/seed/climbing-roses/600/400'], 1),
    (v_card_id_4, v_ci_parent_4_3, 'Fragrance Collection', 'Experience the intoxicating scents of damask, centifolia, and moss roses bred specifically for their perfume.', ARRAY['https://picsum.photos/seed/fragrant-roses/600/400'], 2),
    (v_card_id_4, v_ci_parent_4_3, 'Rose Breeding Lab', 'Visit our research facility where new disease-resistant varieties are developed using traditional and modern techniques.', ARRAY['https://picsum.photos/seed/rose-breeding/600/400'], 3),
    (v_card_id_4, v_ci_parent_4_3, 'Companion Planting', 'Learn about the herbs, perennials, and bulbs that create perfect partnerships with roses in garden design.', ARRAY['https://picsum.photos/seed/companion-planting/600/400'], 4);

  -- Standalone Content Items for Card 4
  INSERT INTO public.content_items (card_id, name, content, image_urls, sort_order)
  VALUES 
    (v_card_id_4, 'Garden Center & Plant Sales', 'Take home rare plants, seeds, and garden supplies from our extensive nursery featuring hard-to-find botanical specimens.', ARRAY['https://picsum.photos/seed/garden-center/600/400'], 3),
    (v_card_id_4, 'Seasonal Events & Classes', 'Join our expert-led workshops on propagation, garden design, and plant care throughout the growing season.', ARRAY['https://picsum.photos/seed/garden-classes/600/400'], 4);

  -- Card 5: Science & Technology Innovation Center (AI enabled)
  INSERT INTO public.cards (user_id, name, description, image_urls, conversation_ai_enabled, ai_prompt)
  VALUES (v_user_id, 'Science & Technology Innovation Center', 'Explore the cutting edge of human innovation where science fiction becomes scientific fact. Our interactive technology museum showcases breakthrough discoveries in artificial intelligence, robotics, space exploration, renewable energy, and biotechnology that are reshaping our world. Experience hands-on demonstrations of quantum computing, witness 3D printing creating complex structures, and interact with advanced AI systems that can compose music and create art. Our planetarium offers immersive journeys through the cosmos while our maker space encourages visitors to build and experiment with emerging technologies. From understanding climate change solutions to exploring the possibilities of genetic engineering, every exhibit connects scientific principles to real-world applications. Perfect for curious minds of all ages, tech enthusiasts, and future innovators, this digital companion provides in-depth explanations of complex concepts, career insights in STEM fields, and inspiration for the next generation of scientists and engineers who will solve tomorrow''s greatest challenges.', ARRAY['https://images.unsplash.com/photo-1518709268805-4e9042af2176?w=400&h=600&fit=crop']::TEXT[], true, 'You are a leading science communicator and technology expert with knowledge spanning physics, computer science, engineering, and emerging technologies. Help visitors understand complex scientific concepts, explore cutting-edge research, and discover career opportunities in STEM fields. Be inspiring and accessible while maintaining scientific accuracy and encouraging curiosity about the future.')
  RETURNING id INTO v_card_id_5;

  -- Content Items for Card 5 (Science & Technology) - 3 parent items with 5+ children each
  
  -- Parent 5.1: Artificial Intelligence & Robotics (6 children)
  INSERT INTO public.content_items (card_id, name, content, image_urls, sort_order)
  VALUES (v_card_id_5, 'Artificial Intelligence & Robotics', 'Interact with cutting-edge AI systems and advanced robots that are revolutionizing industries from healthcare to space exploration.', ARRAY['https://picsum.photos/seed/ai-robotics/600/400'], 0)
  RETURNING id INTO v_ci_parent_5_1;
  
  INSERT INTO public.content_items (card_id, parent_id, name, content, image_urls, sort_order)
  VALUES 
    (v_card_id_5, v_ci_parent_5_1, 'Conversational AI Demo', 'Experience advanced language models and chatbots that can engage in complex conversations, write code, and solve problems creatively.', ARRAY['https://picsum.photos/seed/ai-chat/600/400'], 0),
    (v_card_id_5, v_ci_parent_5_1, 'Humanoid Robot Gallery', 'Meet our collection of humanoid robots including social companions, service robots, and research platforms with human-like movements.', ARRAY['https://picsum.photos/seed/humanoid-robots/600/400'], 1),
    (v_card_id_5, v_ci_parent_5_1, 'Machine Learning Workshop', 'Train your own AI model and understand how machine learning algorithms recognize patterns, make predictions, and improve over time.', ARRAY['https://picsum.photos/seed/machine-learning/600/400'], 2),
    (v_card_id_5, v_ci_parent_5_1, 'Computer Vision Lab', 'Explore how machines see and interpret visual information through facial recognition, object detection, and autonomous vehicle systems.', ARRAY['https://picsum.photos/seed/computer-vision/600/400'], 3),
    (v_card_id_5, v_ci_parent_5_1, 'AI Ethics Discussion', 'Engage with the important questions surrounding artificial intelligence including bias, privacy, job displacement, and responsible development.', ARRAY['https://picsum.photos/seed/ai-ethics/600/400'], 4),
    (v_card_id_5, v_ci_parent_5_1, 'Future of Work', 'Discover how AI and automation are changing careers and learn about emerging job opportunities in the digital economy.', ARRAY['https://picsum.photos/seed/future-work/600/400'], 5);

  -- Parent 5.2: Space Exploration & Astronomy (5 children)
  INSERT INTO public.content_items (card_id, name, content, image_urls, sort_order)
  VALUES (v_card_id_5, 'Space Exploration & Astronomy', 'Journey through the cosmos in our state-of-the-art planetarium and explore humanity''s quest to understand the universe.', ARRAY['https://picsum.photos/seed/space-exploration/600/400'], 1)
  RETURNING id INTO v_ci_parent_5_2;
  
  INSERT INTO public.content_items (card_id, parent_id, name, content, image_urls, sort_order)
  VALUES 
    (v_card_id_5, v_ci_parent_5_2, 'Mars Mission Simulator', 'Experience a virtual journey to Mars and learn about the challenges of interplanetary travel, colonization, and life support systems.', ARRAY['https://picsum.photos/seed/mars-mission/600/400'], 0),
    (v_card_id_5, v_ci_parent_5_2, 'International Space Station', 'Tour a replica of the ISS and understand how astronauts live and work in zero gravity while conducting important research.', ARRAY['https://picsum.photos/seed/space-station/600/400'], 1),
    (v_card_id_5, v_ci_parent_5_2, 'Exoplanet Discovery', 'Use real astronomical data to hunt for planets beyond our solar system and evaluate their potential for supporting life.', ARRAY['https://picsum.photos/seed/exoplanets/600/400'], 2),
    (v_card_id_5, v_ci_parent_5_2, 'Rocket Science Workshop', 'Build and launch model rockets while learning about propulsion physics, orbital mechanics, and spacecraft design principles.', ARRAY['https://picsum.photos/seed/rocket-science/600/400'], 3),
    (v_card_id_5, v_ci_parent_5_2, 'Deep Space Telescope', 'Observe distant galaxies and nebulae through our research-grade telescope and learn how astronomers study the universe.', ARRAY['https://picsum.photos/seed/telescope/600/400'], 4);

  -- Parent 5.3: Renewable Energy & Climate Solutions (5 children)
  INSERT INTO public.content_items (card_id, name, content, image_urls, sort_order)
  VALUES (v_card_id_5, 'Renewable Energy & Climate Solutions', 'Discover innovative technologies that are helping humanity transition to sustainable energy and combat climate change.', ARRAY['https://picsum.photos/seed/renewable-energy/600/400'], 2)
  RETURNING id INTO v_ci_parent_5_3;
  
  INSERT INTO public.content_items (card_id, parent_id, name, content, image_urls, sort_order)
  VALUES 
    (v_card_id_5, v_ci_parent_5_3, 'Solar Power Laboratory', 'Experiment with photovoltaic cells, solar concentrators, and energy storage systems while tracking real-time power generation.', ARRAY['https://picsum.photos/seed/solar-power/600/400'], 0),
    (v_card_id_5, v_ci_parent_5_3, 'Wind Energy Models', 'Design and test wind turbine blades while learning about aerodynamics, materials science, and grid integration challenges.', ARRAY['https://picsum.photos/seed/wind-energy/600/400'], 1),
    (v_card_id_5, v_ci_parent_5_3, 'Electric Vehicle Technology', 'Explore battery chemistry, charging infrastructure, and the automotive revolution happening in transportation worldwide.', ARRAY['https://picsum.photos/seed/electric-vehicles/600/400'], 2),
    (v_card_id_5, v_ci_parent_5_3, 'Carbon Capture Innovation', 'Learn about direct air capture, carbon storage, and emerging technologies that remove greenhouse gases from the atmosphere.', ARRAY['https://picsum.photos/seed/carbon-capture/600/400'], 3),
    (v_card_id_5, v_ci_parent_5_3, 'Smart Grid Systems', 'Understand how modern electrical grids balance supply and demand using artificial intelligence and distributed energy resources.', ARRAY['https://picsum.photos/seed/smart-grid/600/400'], 4);

  -- Standalone Content Items for Card 5
  INSERT INTO public.content_items (card_id, name, content, image_urls, sort_order)
  VALUES 
    (v_card_id_5, 'Maker Space & 3D Printing', 'Create your own inventions using 3D printers, laser cutters, and electronics prototyping equipment in our hands-on workshop.', ARRAY['https://picsum.photos/seed/maker-space/600/400'], 3),
    (v_card_id_5, 'STEM Career Center', 'Explore career paths in science and technology through interactive displays, industry mentors, and skills assessment tools.', ARRAY['https://picsum.photos/seed/stem-careers/600/400'], 4);

END $$;
