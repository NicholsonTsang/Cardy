-- Real Estate Showroom - Grid Mode (Digital Access)
-- Template: Property development sales gallery with available units
-- 
-- INSTRUCTIONS:
-- 1. Replace 'YOUR_USER_ID_HERE' with actual user UUID
-- 2. Update image_url values with actual uploaded image URLs
-- 3. Run this SQL in Supabase SQL Editor or via psql

DO $body$
DECLARE
    v_user_id UUID := 'YOUR_USER_ID_HERE'::UUID;
    v_card_id UUID;
    v_cat_units UUID;
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
        'The Horizon Residences - Available Homes',
        E'**Luxury Living Elevated**\n\nA new standard in urban living. 42 stories of exceptional residences with panoramic city and water views.\n\n📍 Sales Gallery: 100 Waterfront Drive\n⏰ Open daily 10 AM - 6 PM\n📞 (555) HORIZON',
        'grid',
        false,
        NULL,
        'digital',
        true,
        'You are a knowledgeable real estate advisor. Help prospective buyers understand available units, building amenities, pricing, and purchase process. Be informative without being pushy. Acknowledge this is a major decision. Provide honest comparisons between unit types. Refer detailed questions to sales team.',
        E'The Horizon Residences - New luxury development\nDeveloper: Sterling Properties (25 years experience)\nArchitect: Foster + Partners\nLocation: 100 Waterfront Drive, Downtown\n\nBuilding: 42 stories, 180 residences\nUnit types: Studio, 1BR, 2BR, 3BR, Penthouse\nPrice range: $650,000 - $4.5M\nSize range: 550 - 3,800 sq ft\n\nConstruction: Completion Q4 2025\nDeposit: 10% at contract, 10% at 50% construction\n\nAmenities: Rooftop pool, fitness center, concierge, valet parking, wine cellar, residents'' lounge\n\nTax abatement: 10-year 421-a program\n\nHOA estimate: $0.85-1.10 per sq ft\n\nSales gallery open daily 10 AM - 6 PM\nPrivate appointments available',
        'Welcome to The Horizon Residences! I can compare unit types, explain pricing and financing, describe amenities, share construction timeline, or help you find the right home for your needs. What matters most to you?',
        'The {name} is a great option! I can explain the layout, share pricing details, compare it to other units, or discuss availability and views. What would you like to know?',
        NULL,
        TRUE,
        replace(replace(encode(gen_random_bytes(9), 'base64'), '+', '-'), '/', '_')
    ) RETURNING id INTO v_card_id;

    -- Hidden Category for flat grid
    INSERT INTO content_items (id, card_id, parent_id, name, content, ai_knowledge_base, sort_order)
    VALUES (gen_random_uuid(), v_card_id, NULL, 'Available Units', '', '', 1)
    RETURNING id INTO v_cat_units;

    -- Content Items
    INSERT INTO content_items (card_id, parent_id, name, content, image_url, ai_knowledge_base, sort_order) VALUES
    (v_card_id, v_cat_units, 'Studio Residence', E'**Efficient Luxury**\n\n💰 From $650,000\n\n📐 550 - 620 sq ft\n\nThoughtfully designed open-concept living with premium finishes. Floor-to-ceiling windows flood the space with natural light.\n\n---\n\n✓ Open kitchen with island\n✓ In-unit washer/dryer\n✓ Walk-in closet\n✓ City or courtyard views\n\n*8 units available on floors 5-18*', NULL, 'Best entry point for first-time buyers or investors. Higher floors (12+) have better views, $50-75K premium. West-facing units have sunset views. HOA approximately $500/month. Strong rental potential - similar units rent $2,800-3,200/month. Parking add-on: $75,000. Move-in ready Q4 2025.', 1),
    
    (v_card_id, v_cat_units, 'One-Bedroom Residence', E'**Modern Comfort**\n\n💰 From $895,000\n\n📐 780 - 920 sq ft\n\nSpacious one-bedroom with separate living areas. Chef''s kitchen, spa-inspired bathroom, and private balcony on select units.\n\n---\n\n✓ Separate bedroom with en-suite\n✓ European appliances\n✓ Balcony (floors 20+)\n✓ Home office nook\n\n*15 units available on floors 8-32*', NULL, 'Most popular unit type - selling quickly. Two floor plans: A (780sf, city view) and B (920sf, water view). B layouts command $150K premium. Balconies start at floor 20 - highly recommended. Corner units have two exposures. Great for couples or work-from-home professionals. HOA approximately $700-800/month.', 2),
    
    (v_card_id, v_cat_units, 'Two-Bedroom Residence', E'**Family-Ready Living**\n\n💰 From $1,450,000\n\n📐 1,200 - 1,580 sq ft\n\nGenerous two-bedroom layouts with dual primary suites or traditional primary + secondary configuration. Expansive great room perfect for entertaining.\n\n---\n\n✓ Two full bathrooms\n✓ Chef''s kitchen with island\n✓ Private balcony\n✓ Custom closet systems\n\n*12 units available on floors 15-38*', NULL, 'Three floor plans: Standard (1,200sf), Corner (1,380sf), Premium (1,580sf with den). Corner units best value - two exposures, more light. Premium on floors 30+ have water views from both bedrooms. Popular with growing families and downsizers from larger homes. Second bedroom works as guest room, office, or nursery. HOA approximately $1,100-1,400.', 3),
    
    (v_card_id, v_cat_units, 'Three-Bedroom Residence', E'**Expansive Living**\n\n💰 From $2,450,000\n\n📐 1,950 - 2,400 sq ft\n\nRare three-bedroom homes offering true family living with separate living and entertaining spaces. Primary suite with walk-in closet and spa bath.\n\n---\n\n✓ Three bedrooms, 2.5 baths\n✓ Separate dining room\n✓ Large private terrace\n✓ Powder room\n\n*Only 6 units available on floors 28-40*', NULL, 'Limited inventory - only 6 in the building. Half corners (2 exposures), half full-floor units. Full-floor units ($3.2M+) have private elevator landing. Terraces range from 150-400sf. Popular with families with children - excellent nearby schools. Also attracts empty nesters wanting downtown location with space. HOA approximately $1,800-2,200.', 4),
    
    (v_card_id, v_cat_units, 'Penthouse Collection', E'**The Pinnacle**\n\n💰 From $3,500,000\n\n📐 2,800 - 3,800 sq ft\n\nExclusive penthouse residences on floors 40-42 with unobstructed panoramic views. Custom finishes, private outdoor spaces, and white-glove service.\n\n---\n\n✓ 3-4 bedrooms\n✓ Private terraces up to 800 sf\n✓ Custom kitchen design\n✓ Dedicated concierge\n\n*3 penthouses remaining*', NULL, 'Three distinct penthouses: PH1 (2,800sf, 3BR), PH2 (3,200sf, 3BR+den), PH3 (3,800sf, 4BR). PH3 is building crown jewel at $4.5M - 360-degree views. All include 2 parking spaces, private storage unit, custom finish consultation with designer. 11-foot ceilings versus 10-foot in lower floors. HOA approximately $2,800-3,500. By appointment only.', 5),
    
    (v_card_id, v_cat_units, 'Building Amenities', E'**Exceptional Living**\n\nResort-caliber amenities for residents and guests.\n\n---\n\n🏊 **Wellness**\n- Rooftop infinity pool\n- State-of-the-art fitness center\n- Yoga/meditation studio\n- Spa treatment room\n\n🎉 **Social**\n- Residents'' lounge with kitchen\n- Private dining room\n- Rooftop terrace with grill\n- Wine cellar with lockers\n\n🚗 **Services**\n- 24/7 concierge\n- Valet parking\n- Package room\n- Pet spa', NULL, '$15M amenity package - among best in the city. Pool open May-October, heated. Fitness center 24/7 access with Pelotons. Wine cellar lockers $500/year - climate controlled. Pet spa includes grooming station and dog wash. Residents'' lounge bookable for private events. Valet parking $500/month additional. Guest suite available for out-of-town visitors.', 6);

    -- Insert into content_templates for template library management
    INSERT INTO content_templates (slug, card_id, venue_type, is_featured, is_active, sort_order)
    VALUES ('real-estate-showroom', v_card_id, 'retail', true, true, 18);

    RAISE NOTICE 'Successfully created Real Estate Showroom template with card ID: %', v_card_id;

END $body$;

