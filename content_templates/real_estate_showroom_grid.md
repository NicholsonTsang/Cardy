# Real Estate Showroom - Grid Mode (Digital Access)

A property development sales gallery showcasing available units, floor plans, and amenities. Grid mode presents properties visually for easy comparison.

---

## Card Settings

```yaml
name: "The Horizon Residences - Available Homes"
description: |
  **Luxury Living Elevated**
  
  A new standard in urban living. 42 stories of exceptional 
  residences with panoramic city and water views.
  
  📍 Sales Gallery: 100 Waterfront Drive
  ⏰ Open daily 10 AM - 6 PM
  📞 (555) HORIZON

content_mode: grid
is_grouped: false
group_display: null
billing_type: digital
image_url: "[Upload: Building rendering or skyline view]"

# AI Configuration
conversation_ai_enabled: true
ai_instruction: |
  You are a knowledgeable real estate advisor. Help prospective 
  buyers understand available units, building amenities, pricing, 
  and purchase process. Be informative without being pushy. 
  Acknowledge this is a major decision. Provide honest comparisons 
  between unit types. Refer detailed questions to sales team.

ai_knowledge_base: |
  The Horizon Residences - New luxury development
  Developer: Sterling Properties (25 years experience)
  Architect: Foster + Partners
  Location: 100 Waterfront Drive, Downtown
  
  Building: 42 stories, 180 residences
  Unit types: Studio, 1BR, 2BR, 3BR, Penthouse
  Price range: $650,000 - $4.5M
  Size range: 550 - 3,800 sq ft
  
  Construction: Completion Q4 2025
  Deposit: 10% at contract, 10% at 50% construction
  
  Amenities: Rooftop pool, fitness center, concierge, 
  valet parking, wine cellar, residents' lounge
  
  Tax abatement: 10-year 421-a program
  
  HOA estimate: $0.85-1.10 per sq ft
  
  Sales gallery open daily 10 AM - 6 PM
  Private appointments available

ai_welcome_general: "Welcome to The Horizon Residences! I can compare unit types, explain pricing and financing, describe amenities, share construction timeline, or help you find the right home for your needs. What matters most to you?"
ai_welcome_item: "The {name} is a great option! I can explain the layout, share pricing details, compare it to other units, or discuss availability and views. What would you like to know?"
```

---

## Content Items

### Hidden Category (Required for flat grid)
```yaml
name: "Available Units"
content: ""
image_url: null
ai_knowledge_base: ""
sort_order: 1
parent_id: null
```

#### Studio Residence
```yaml
name: "Studio Residence"
content: |
  **Efficient Luxury**
  
  💰 From $650,000
  
  📐 550 - 620 sq ft
  
  Thoughtfully designed open-concept living with premium 
  finishes. Floor-to-ceiling windows flood the space with 
  natural light.
  
  ---
  
  ✓ Open kitchen with island
  ✓ In-unit washer/dryer
  ✓ Walk-in closet
  ✓ City or courtyard views
  
  *8 units available on floors 5-18*

image_url: "[Upload: studio_rendering.jpg]"
ai_knowledge_base: |
  Best entry point for first-time buyers or investors. 
  Higher floors (12+) have better views, $50-75K premium. 
  West-facing units have sunset views. HOA approximately 
  $500/month. Strong rental potential - similar units rent 
  $2,800-3,200/month. Parking add-on: $75,000. Move-in ready 
  Q4 2025.
sort_order: 1
parent_id: "[Reference: Available Units]"
```

#### One-Bedroom Residence
```yaml
name: "One-Bedroom Residence"
content: |
  **Modern Comfort**
  
  💰 From $895,000
  
  📐 780 - 920 sq ft
  
  Spacious one-bedroom with separate living areas. 
  Chef's kitchen, spa-inspired bathroom, and private 
  balcony on select units.
  
  ---
  
  ✓ Separate bedroom with en-suite
  ✓ European appliances
  ✓ Balcony (floors 20+)
  ✓ Home office nook
  
  *15 units available on floors 8-32*

image_url: "[Upload: one_bedroom_rendering.jpg]"
ai_knowledge_base: |
  Most popular unit type - selling quickly. Two floor plans: 
  A (780sf, city view) and B (920sf, water view). B layouts 
  command $150K premium. Balconies start at floor 20 - highly 
  recommended. Corner units have two exposures. Great for 
  couples or work-from-home professionals. HOA approximately 
  $700-800/month.
sort_order: 2
parent_id: "[Reference: Available Units]"
```

#### Two-Bedroom Residence
```yaml
name: "Two-Bedroom Residence"
content: |
  **Family-Ready Living**
  
  💰 From $1,450,000
  
  📐 1,200 - 1,580 sq ft
  
  Generous two-bedroom layouts with dual primary suites 
  or traditional primary + secondary configuration. 
  Expansive great room perfect for entertaining.
  
  ---
  
  ✓ Two full bathrooms
  ✓ Chef's kitchen with island
  ✓ Private balcony
  ✓ Custom closet systems
  
  *12 units available on floors 15-38*

image_url: "[Upload: two_bedroom_rendering.jpg]"
ai_knowledge_base: |
  Three floor plans: Standard (1,200sf), Corner (1,380sf), 
  Premium (1,580sf with den). Corner units best value - two 
  exposures, more light. Premium on floors 30+ have water 
  views from both bedrooms. Popular with growing families 
  and downsizers from larger homes. Second bedroom works as 
  guest room, office, or nursery. HOA approximately $1,100-1,400.
sort_order: 3
parent_id: "[Reference: Available Units]"
```

#### Three-Bedroom Residence
```yaml
name: "Three-Bedroom Residence"
content: |
  **Expansive Living**
  
  💰 From $2,450,000
  
  📐 1,950 - 2,400 sq ft
  
  Rare three-bedroom homes offering true family living 
  with separate living and entertaining spaces. 
  Primary suite with walk-in closet and spa bath.
  
  ---
  
  ✓ Three bedrooms, 2.5 baths
  ✓ Separate dining room
  ✓ Large private terrace
  ✓ Powder room
  
  *Only 6 units available on floors 28-40*

image_url: "[Upload: three_bedroom_rendering.jpg]"
ai_knowledge_base: |
  Limited inventory - only 6 in the building. Half corners 
  (2 exposures), half full-floor units. Full-floor units 
  ($3.2M+) have private elevator landing. Terraces range 
  from 150-400sf. Popular with families with children - 
  excellent nearby schools. Also attracts empty nesters 
  wanting downtown location with space. HOA approximately 
  $1,800-2,200.
sort_order: 4
parent_id: "[Reference: Available Units]"
```

#### Penthouse Collection
```yaml
name: "Penthouse Collection"
content: |
  **The Pinnacle**
  
  💰 From $3,500,000
  
  📐 2,800 - 3,800 sq ft
  
  Exclusive penthouse residences on floors 40-42 with 
  unobstructed panoramic views. Custom finishes, 
  private outdoor spaces, and white-glove service.
  
  ---
  
  ✓ 3-4 bedrooms
  ✓ Private terraces up to 800 sf
  ✓ Custom kitchen design
  ✓ Dedicated concierge
  
  *3 penthouses remaining*

image_url: "[Upload: penthouse_rendering.jpg]"
ai_knowledge_base: |
  Three distinct penthouses: PH1 (2,800sf, 3BR), PH2 (3,200sf, 
  3BR+den), PH3 (3,800sf, 4BR). PH3 is building crown jewel at 
  $4.5M - 360-degree views. All include 2 parking spaces, 
  private storage unit, custom finish consultation with 
  designer. 11-foot ceilings versus 10-foot in lower floors. 
  HOA approximately $2,800-3,500. By appointment only.
sort_order: 5
parent_id: "[Reference: Available Units]"
```

#### Building Amenities
```yaml
name: "Building Amenities"
content: |
  **Exceptional Living**
  
  Resort-caliber amenities for residents and guests.
  
  ---
  
  🏊 **Wellness**
  - Rooftop infinity pool
  - State-of-the-art fitness center
  - Yoga/meditation studio
  - Spa treatment room
  
  🎉 **Social**
  - Residents' lounge with kitchen
  - Private dining room
  - Rooftop terrace with grill
  - Wine cellar with lockers
  
  🚗 **Services**
  - 24/7 concierge
  - Valet parking
  - Package room
  - Pet spa

image_url: "[Upload: amenities_collage.jpg]"
ai_knowledge_base: |
  $15M amenity package - among best in the city. Pool open 
  May-October, heated. Fitness center 24/7 access with Pelotons. 
  Wine cellar lockers $500/year - climate controlled. Pet spa 
  includes grooming station and dog wash. Residents' lounge 
  bookable for private events. Valet parking $500/month 
  additional. Guest suite available for out-of-town visitors.
sort_order: 6
parent_id: "[Reference: Available Units]"
```

---

## Notes for Implementation

1. **Grid Mode** showcases properties visually side-by-side
2. **Digital Access** works for sales gallery tablets and broker previews
3. Include **pricing, sizes, availability** consistently
4. AI knowledge should cover honest comparisons and value insights
5. Update inventory status as units sell
6. Include professional renderings/photography
7. Consider adding neighborhood guide as separate section


