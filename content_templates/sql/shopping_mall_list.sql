-- Shopping Mall - Grouped List Mode (Digital Access)
-- Template: Mall store directory organized by category
-- 
-- INSTRUCTIONS:
-- 1. Replace 'YOUR_USER_ID_HERE' with actual user UUID
-- 2. Update image_url values with actual uploaded image URLs
-- 3. Run this SQL in Supabase SQL Editor or via psql

DO $body$
DECLARE
    v_user_id UUID := 'YOUR_USER_ID_HERE'::UUID;
    v_card_id UUID;
    v_cat_fashion UUID;
    v_cat_electronics UUID;
    v_cat_dining UUID;
    v_cat_services UUID;
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
        'Central Plaza Mall - Store Directory',
        E'🛍️ Welcome to **Central Plaza Mall**\n\n200+ stores across 4 floors. Find your favorite brands below.\n\n📍 Guest Services: Level 1 near Main Entrance',
        'list',
        true,
        'expanded',
        'digital',
        true,
        'You are a friendly mall concierge. Help shoppers find stores, restaurants, and services. Give directions, share current promotions, and suggest alternatives if a store doesn''t have what they need. Be helpful and enthusiastic about shopping!',
        E'Central Plaza Mall - Premier Shopping Destination\nAddress: 500 Central Avenue\nHours: Mon-Sat 10am-9pm, Sun 11am-7pm\nStores: 200+ retail locations\nFloors: 4 levels + parking garage\n\nLayout:\n- Level 1: Fashion, accessories, main entrances\n- Level 2: Electronics, home goods, food court\n- Level 3: Entertainment, kids, services\n- Level 4: Department stores, specialty retail\n\nParking: 3 hours free with validation, $3/hour after\nWiFi: CentralPlaza_Guest (free)\n\nGuest Services: Wheelchair rental, stroller rental, gift cards, package holding, lost & found',
        'Welcome to Central Plaza Mall! I can help you find specific stores, give directions, share current sales and promotions, suggest restaurants, or locate services like ATMs. What are you looking for?',
        'For {name}, I can give you directions, share their hours, tell you about current promotions, or suggest similar stores nearby. What do you need?',
        NULL,
        TRUE,
        replace(replace(encode(gen_random_bytes(9), 'base64'), '+', '-'), '/', '_')
    ) RETURNING id INTO v_card_id;

    -- Create categories by store type (Layer 1)
    INSERT INTO content_items (id, card_id, parent_id, name, content, ai_knowledge_base, sort_order)
    VALUES (gen_random_uuid(), v_card_id, NULL, '👗 Fashion & Apparel', 'Clothing, shoes, and accessories', 'Fashion stores are primarily on Level 1 and Level 4. Most accept mall gift cards.', 1)
    RETURNING id INTO v_cat_fashion;

    INSERT INTO content_items (id, card_id, parent_id, name, content, ai_knowledge_base, sort_order)
    VALUES (gen_random_uuid(), v_card_id, NULL, '📱 Electronics & Tech', 'Phones, computers, and gadgets', 'Electronics stores are on Level 2. Most offer price matching and tech support.', 2)
    RETURNING id INTO v_cat_electronics;

    INSERT INTO content_items (id, card_id, parent_id, name, content, ai_knowledge_base, sort_order)
    VALUES (gen_random_uuid(), v_card_id, NULL, '🍽️ Dining', 'Restaurants and food court', 'Dining options range from quick bites in the food court to sit-down restaurants on Level 2.', 3)
    RETURNING id INTO v_cat_dining;

    INSERT INTO content_items (id, card_id, parent_id, name, content, ai_knowledge_base, sort_order)
    VALUES (gen_random_uuid(), v_card_id, NULL, 'ℹ️ Services & Facilities', 'Guest services and amenities', 'Services are spread throughout the mall. Guest Services desk is on Level 1.', 4)
    RETURNING id INTO v_cat_services;

    -- Insert fashion stores (Layer 2)
    INSERT INTO content_items (card_id, parent_id, name, content, image_url, ai_knowledge_base, sort_order) VALUES
    (v_card_id, v_cat_fashion, 'Zara', E'**Fast Fashion & Trendy Styles**\n\n📍 Level 1, Store #112\n⏰ Mall Hours\n\nLatest runway-inspired fashion at accessible prices. New arrivals twice weekly.\n\n---\n\n🏷️ Women''s, Men''s, Kids\n💳 Mall gift cards accepted', NULL, 'Zara is one of mall''s largest stores (8,000 sq ft). Located near central entrance. New inventory Tuesdays and Fridays. Return policy: 30 days with receipt.', 1),
    
    (v_card_id, v_cat_fashion, 'H&M', E'**Affordable Fashion for Everyone**\n\n📍 Level 1, Store #108\n⏰ Mall Hours\n\nTrendy, sustainable fashion at great prices. Features Conscious Collection made from recycled materials.\n\n---\n\n🏷️ Women''s, Men''s, Kids, Home\n💳 Student discount 15% (with ID)', NULL, 'H&M has 10,000 sq ft on Level 1. Garment recycling program - bring old clothes for 15% off coupon. Member rewards program offers free shipping online.', 2),
    
    (v_card_id, v_cat_fashion, 'Nordstrom', E'**Premium Department Store**\n\n📍 Level 4, Anchor Store\n⏰ 10am-9pm Mon-Sat, 11am-7pm Sun\n\nDesigner brands, exceptional service, and free alterations. Personal stylists available by appointment.\n\n---\n\n🏷️ Full Department Store\n💳 Nordstrom Card earns 3x points\n🛋️ Café & Espresso Bar inside', NULL, 'Nordstrom is anchor store with 3 floors. Best shoe selection in mall. Alterations free on full-price items. Anniversary Sale in July - biggest discounts of year.', 3),
    
    (v_card_id, v_cat_fashion, 'J.Crew', E'**Classic American Style**\n\n📍 Level 1, Store #124\n⏰ Mall Hours\n\nTimeless preppy fashion with modern updates. Known for quality basics and excellent suiting.\n\n---\n\n🏷️ Men''s, Women''s\n💳 J.Crew Rewards: 15% off first order', NULL, 'J.Crew men''s section is comprehensive. Ludlow suit is bestseller for weddings and interviews. Free hemming on full-price pants.', 4);

    -- Insert electronics stores (Layer 2)
    INSERT INTO content_items (card_id, parent_id, name, content, image_url, ai_knowledge_base, sort_order) VALUES
    (v_card_id, v_cat_electronics, 'Apple Store', E'**Official Apple Retail Location**\n\n📍 Level 2, Store #215\n⏰ Mall Hours\n\nLatest iPhones, Macs, iPads, and accessories. Genius Bar support and Today at Apple workshops.\n\n---\n\n🏷️ Electronics\n🔧 Genius Bar: Book online\n📱 Trade-in available', NULL, 'Apple Store is always busy - book Genius Bar online before visiting. Today at Apple workshops are free. Education discount for students.', 1),
    
    (v_card_id, v_cat_electronics, 'Best Buy', E'**Electronics Superstore**\n\n📍 Level 2, Store #201\n⏰ Mall Hours\n\nTVs, computers, appliances, and smart home tech. Expert advice and installation services.\n\n---\n\n🏷️ Electronics, Appliances\n🛠️ Geek Squad support\n💳 Best Buy Credit: 18 months 0% APR', NULL, 'Best Buy is 25,000 sq ft, mall''s largest electronics store. Price match policy - they''ll match Amazon. Open-box deals in dedicated section near entrance.', 2);

    -- Insert dining options (Layer 2)
    INSERT INTO content_items (card_id, parent_id, name, content, image_url, ai_knowledge_base, sort_order) VALUES
    (v_card_id, v_cat_dining, 'Food Court', E'**Quick Bites & Global Flavors**\n\n📍 Level 2, Center Court\n⏰ 10am-9pm daily\n\n**12 Restaurants:**\n- Panda Express (Chinese)\n- Chick-fil-A (Chicken)\n- Sbarro (Pizza)\n- Chipotle (Mexican)\n- Subway (Sandwiches)\n- Auntie Anne''s (Pretzels)\n- + 6 more\n\n---\n\n🪑 Seating: 500+ seats\n👶 High chairs available', NULL, 'Food court busiest 12-2pm, try going at 11:30 or after 2pm. Chick-fil-A closed Sundays. Halal option: Gyro Palace. Vegetarian-friendly: Chipotle, Indian Kitchen.', 1),
    
    (v_card_id, v_cat_dining, 'The Cheesecake Factory', E'**Full-Service Restaurant**\n\n📍 Level 2, Store #250\n⏰ 11am-11pm Mon-Thu, 11am-12am Fri-Sat, 10am-10pm Sun\n\n250+ menu items and legendary cheesecakes. Reservations recommended for dinner.\n\n---\n\n🏷️ American, Full Bar\n📱 Waitlist: Yelp app\n🎂 30+ cheesecake varieties', NULL, 'Cheesecake Factory has huge portions - shareable. Average wait Friday/Saturday dinner is 45-60 minutes. Get on Yelp waitlist remotely. SkinnyLicious menu for lighter options.', 2);

    -- Insert services (Layer 2)
    INSERT INTO content_items (card_id, parent_id, name, content, image_url, ai_knowledge_base, sort_order) VALUES
    (v_card_id, v_cat_services, 'Guest Services', E'**We''re Here to Help**\n\n📍 Level 1, Near Main Entrance\n⏰ Mall Hours\n\n**Services:**\n- Wheelchair & stroller rental\n- Gift cards (accepted at all stores)\n- Package holding\n- Lost & found\n- Information & directions\n\n---\n\n📞 Call: (555) 123-MALL\n💳 Mall gift cards: $10-$500', NULL, 'Guest Services staffed with multilingual associates (Spanish, Mandarin). Strollers $5/day, wheelchairs free with ID. Will hold packages while you shop (free, up to 4 hours).', 1),
    
    (v_card_id, v_cat_services, 'Parking & Transportation', E'**Getting Here & Getting Around**\n\n🚗 **Parking Garage:**\n- 3 hours free with store validation\n- $3/hour after (max $15/day)\n- Electric charging stations Level P1\n\n🚌 **Public Transit:**\n- Bus routes 12, 15, 22 stop at mall\n- Metro Red Line: Central Plaza station (2 blocks)\n\n🚕 **Rideshare:**\n- Pickup zone at East Entrance\n- Designated Uber/Lyft area', NULL, 'Parking garage has 3,500 spaces across 4 levels. Busiest on weekends - try Level P3 for faster spots. Electric charging is ChargePoint network. Valet parking available $20 at Main Entrance.', 2);

    -- Insert into content_templates for template library management
    INSERT INTO content_templates (slug, card_id, scenario_category, is_featured, is_active, sort_order)
    VALUES ('shopping-mall', v_card_id, 'retail', true, true, 16);

    RAISE NOTICE 'Successfully created Shopping Mall template with card ID: %', v_card_id;

END $body$;
