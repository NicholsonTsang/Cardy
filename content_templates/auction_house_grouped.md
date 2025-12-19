# Auction House - Grouped List (Digital Access)

An auction catalog with lots organized by category. Grouped List mode allows bidders to browse by category and view individual lots with estimates and provenance.

---

## Card Settings

```yaml
name: "Heritage Auctions - Spring Fine Art Sale"
description: |
  **Spring Fine Art Auction 2025**
  
  April 15-16 | Live & Online Bidding
  
  Browse 180+ lots of exceptional paintings, sculptures, and decorative arts.
  
  📞 Bidder Registration: +1 (555) 123-4567

content_mode: list
is_grouped: true
group_display: expanded
billing_type: digital
image_url: "[Upload: Auction house logo or highlight lot]"

# AI Configuration
conversation_ai_enabled: true
ai_instruction: |
  You are a knowledgeable art specialist at a prestigious auction house. 
  Help potential bidders understand lots, provenance, condition, and market 
  context. Be professional yet approachable. Explain auction terminology 
  and bidding process to newcomers. Never give price predictions.

ai_knowledge_base: |
  Heritage Auctions - Spring Fine Art Sale 2025
  Dates: April 15-16, 2025
  Location: Heritage Auction House, 500 Park Avenue
  Preview: April 12-14, 10am-6pm
  
  Bidding options: In-person paddle, phone bid, online via LiveAuctioneer
  Buyer's premium: 25% on hammer price
  
  Payment: Wire transfer, certified check, major credit cards
  Shipping: In-house shipping department, international available
  
  Condition reports available upon request
  All sales final, subject to Terms & Conditions

ai_welcome_general: "Welcome to Heritage Auctions! I can explain any lot's provenance, discuss condition reports, clarify bidding procedures, or help you find pieces in your collecting area. What interests you?"
ai_welcome_item: "You're viewing Lot {name}! I can share provenance details, discuss the estimate, explain condition, or compare it to recent auction results. What would you like to know?"
```

---

## Content Items

### Category 1: Impressionist & Modern Art
```yaml
name: "Impressionist & Modern Art"
content: ""
image_url: null
ai_knowledge_base: |
  Session 1: April 15, 10:00 AM
  Lots 1-45: Works from 1860-1940
  Highlight: Monet water lily study, Picasso ceramic
  Estimates range $5,000 - $500,000
sort_order: 1
parent_id: null
```

#### Lot 12: Monet Water Lily Study
```yaml
name: "Lot 12 - Monet Water Lily Study"
content: |
  **Claude Monet (French, 1840-1926)**
  
  *Nymphéas, étude* (Water Lilies, study)  
  c. 1905
  
  Oil on canvas  
  18 × 24 inches (45.7 × 61 cm)  
  Signed lower right: Claude Monet
  
  ---
  
  **Provenance:**
  - Estate of the artist
  - Galerie Durand-Ruel, Paris (acquired 1927)
  - Private collection, Geneva (1952-2024)
  
  **Estimate:** $350,000 - $450,000
  
  🔨 **Session 1** | April 15, ~11:30 AM

image_url: "[Upload: monet_water_lily.jpg]"
ai_knowledge_base: |
  One of numerous water lily studies Monet made at Giverny. This example 
  shows the looser brushwork of his later period. Authenticated by 
  Wildenstein Institute. Condition: Excellent, minor craquelure 
  consistent with age. Provenance is impeccable - Durand-Ruel was 
  Monet's primary dealer. Similar works sold $400K-600K recently.
sort_order: 1
parent_id: "[Reference: Impressionist & Modern Art]"
```

#### Lot 23: Picasso Ceramic Owl
```yaml
name: "Lot 23 - Picasso Ceramic Owl"
content: |
  **Pablo Picasso (Spanish, 1881-1973)**
  
  *Hibou mat* (Matte Owl)  
  1953
  
  Turned vase, white earthenware clay  
  Edition of 500  
  Height: 13 inches (33 cm)  
  Stamped and numbered: Madoura Plein Feu / Edition Picasso
  
  ---
  
  **Provenance:**
  - Madoura Pottery, Vallauris
  - Private collection, New York
  
  **Literature:**
  - Ramié, Alain, *Picasso Catalogue*, no. 253
  
  **Estimate:** $25,000 - $35,000
  
  🔨 **Session 1** | April 15, ~12:15 PM

image_url: "[Upload: picasso_owl.jpg]"
ai_knowledge_base: |
  From Picasso's prolific ceramic period at Madoura pottery. Owl was 
  favorite motif - symbolism of wisdom, night, Athena. Edition of 500 
  is relatively large for Picasso ceramics. Condition: Excellent, 
  no chips or restoration. Madoura stamp authenticates. Market for 
  Picasso ceramics strong, especially zoomorphic forms.
sort_order: 2
parent_id: "[Reference: Impressionist & Modern Art]"
```

---

### Category 2: Contemporary Art
```yaml
name: "Contemporary Art"
content: ""
image_url: null
ai_knowledge_base: |
  Session 1: April 15, 2:00 PM
  Lots 46-90: Works from 1945-present
  Highlight: Warhol silk screen, Basquiat drawing
  Estimates range $10,000 - $800,000
sort_order: 2
parent_id: null
```

#### Lot 52: Warhol Campbell's Soup
```yaml
name: "Lot 52 - Warhol Campbell's Soup"
content: |
  **Andy Warhol (American, 1928-1987)**
  
  *Campbell's Soup Can (Tomato)*  
  1968
  
  Screenprint on paper  
  35 × 23 inches (88.9 × 58.4 cm)  
  From the edition of 250  
  Signed and numbered in pencil
  
  ---
  
  **Provenance:**
  - Leo Castelli Gallery, New York
  - Private collection, Los Angeles
  
  **Exhibition:**
  - "Warhol: Icons", MOCA, 1995
  
  **Estimate:** $150,000 - $200,000
  
  🔨 **Session 1** | April 15, ~2:30 PM

image_url: "[Upload: warhol_soup.jpg]"
ai_knowledge_base: |
  Iconic Warhol image from 1968 portfolio of 10 soup can varieties. 
  Tomato is most recognizable. This impression has strong colors, 
  no fading. Pencil signature is period-appropriate (Warhol varied 
  signature style). MOCA exhibition history adds provenance value. 
  Market: Strong demand, prices up 15% over 5 years.
sort_order: 1
parent_id: "[Reference: Contemporary Art]"
```

#### Lot 67: Basquiat Untitled Drawing
```yaml
name: "Lot 67 - Basquiat Untitled Drawing"
content: |
  **Jean-Michel Basquiat (American, 1960-1988)**
  
  *Untitled (Head)*  
  1982
  
  Oil stick and graphite on paper  
  22 × 30 inches (55.9 × 76.2 cm)  
  Signed and dated verso
  
  ---
  
  **Provenance:**
  - Tony Shafrazi Gallery, New York (1983)
  - Private collection, Miami
  
  **Authentication:**
  - Authentication Committee of the Estate of Jean-Michel Basquiat
  
  **Estimate:** $600,000 - $800,000
  
  🔨 **Session 1** | April 15, ~3:15 PM

image_url: "[Upload: basquiat_head.jpg]"
ai_knowledge_base: |
  1982 was breakthrough year for Basquiat - Documenta 7, first solo shows. 
  Head/skull motif is central to his iconography. Authentication by 
  Estate committee is essential - many forgeries exist. Condition: 
  Some paper toning, oil stick stable. Tony Shafrazi was key early 
  dealer. Current market extremely strong for works on paper.
sort_order: 2
parent_id: "[Reference: Contemporary Art]"
```

---

### Category 3: Decorative Arts & Furniture
```yaml
name: "Decorative Arts & Furniture"
content: ""
image_url: null
ai_knowledge_base: |
  Session 2: April 16, 10:00 AM
  Lots 91-130: European furniture, silver, porcelain
  Highlight: Louis XV commode, Tiffany lamp
  Estimates range $2,000 - $150,000
sort_order: 3
parent_id: null
```

#### Lot 98: Louis XV Commode
```yaml
name: "Lot 98 - Louis XV Commode"
content: |
  **Louis XV Kingwood Commode**
  
  Attributed to Jean-François Oeben  
  Paris, c. 1755
  
  Kingwood and tulipwood marquetry, gilt bronze mounts, 
  Brèche d'Alep marble top  
  34 × 50 × 24 inches (86 × 127 × 61 cm)
  
  ---
  
  **Provenance:**
  - French noble collection (per tradition)
  - Sotheby's Monaco, 1988
  - Private collection, London
  
  **Estimate:** $80,000 - $120,000
  
  🔨 **Session 2** | April 16, ~10:45 AM

image_url: "[Upload: louis_xv_commode.jpg]"
ai_knowledge_base: |
  Jean-François Oeben was master ébéniste, teacher of Riesener. 
  Kingwood (bois de violette) prized for purple-brown tone. 
  Marquetry pattern shows floral scrolls typical of period. 
  Mounts appear period but may include 19th c. replacements 
  (common). Marble top is later replacement. Condition report 
  details restorations.
sort_order: 1
parent_id: "[Reference: Decorative Arts & Furniture]"
```

#### Lot 115: Tiffany Dragonfly Lamp
```yaml
name: "Lot 115 - Tiffany Dragonfly Lamp"
content: |
  **Tiffany Studios Dragonfly Table Lamp**
  
  New York, c. 1905
  
  Leaded glass shade, bronze base  
  Shade diameter: 16 inches (40.6 cm)  
  Overall height: 22 inches (55.9 cm)  
  Shade stamped: TIFFANY STUDIOS NEW YORK  
  Base stamped: TIFFANY STUDIOS NEW YORK 337
  
  ---
  
  **Provenance:**
  - Private collection, Connecticut (acquired c. 1920)
  - By descent to present owner
  
  **Estimate:** $100,000 - $150,000
  
  🔨 **Session 2** | April 16, ~11:30 AM

image_url: "[Upload: tiffany_lamp.jpg]"
ai_knowledge_base: |
  Dragonfly is one of most desirable Tiffany lamp designs. This is 
  16-inch "cone" shade version (larger 20-inch more valuable). 
  All glass appears original - no replaced segments. Bronze base 
  #337 is correct period pairing. Provenance from 1920 suggests 
  original purchase. Market for quality Tiffany very strong, 
  especially insect designs (dragonfly, butterfly, spider).
sort_order: 2
parent_id: "[Reference: Decorative Arts & Furniture]"
```

---

### Category 4: Jewelry & Watches
```yaml
name: "Jewelry & Watches"
content: ""
image_url: null
ai_knowledge_base: |
  Session 2: April 16, 2:00 PM
  Lots 131-180: Signed jewelry, vintage watches, diamonds
  Highlight: Art Deco Cartier bracelet, Patek Philippe chronograph
  Estimates range $5,000 - $250,000
sort_order: 4
parent_id: null
```

#### Lot 145: Cartier Art Deco Bracelet
```yaml
name: "Lot 145 - Cartier Art Deco Bracelet"
content: |
  **Cartier Art Deco Diamond Bracelet**
  
  Paris, c. 1925
  
  Platinum, set with old European-cut diamonds  
  Total diamond weight: approximately 15.00 carats  
  Length: 7 inches (17.8 cm)  
  Signed: Cartier Paris, numbered
  
  ---
  
  **Provenance:**
  - European private collection
  
  **Accompanied by:**
  - Cartier archive extract confirming manufacture
  
  **Estimate:** $180,000 - $250,000
  
  🔨 **Session 2** | April 16, ~2:45 PM

image_url: "[Upload: cartier_bracelet.jpg]"
ai_knowledge_base: |
  Geometric Art Deco design with calibré-cut diamonds. Paris-made 
  Cartier of this period commands premium over London or New York. 
  Old European cut diamonds show period-correct faceting. Cartier 
  archive confirmation is gold standard for authentication. 
  Platinum shows minimal wear. Art Deco jewelry market extremely 
  strong, especially signed Cartier.
sort_order: 1
parent_id: "[Reference: Jewelry & Watches]"
```

#### Lot 162: Patek Philippe Chronograph
```yaml
name: "Lot 162 - Patek Philippe Ref. 5170"
content: |
  **Patek Philippe Reference 5170G-010**
  
  Manual-winding chronograph  
  Geneva, 2015
  
  18k white gold case, 39.4mm  
  Silvered dial with applied Breguet numerals  
  Caliber CH 29-535 PS  
  
  ---
  
  **Accompanied by:**
  - Original box and papers
  - Patek Philippe Certificate of Origin
  - Extract from the Archives
  
  **Estimate:** $60,000 - $80,000
  
  🔨 **Session 2** | April 16, ~3:30 PM

image_url: "[Upload: patek_5170.jpg]"
ai_knowledge_base: |
  Reference 5170 introduced 2010, first in-house manual chronograph 
  movement. Caliber CH 29-535 PS has column wheel, horizontal clutch. 
  White gold with silver dial is classic configuration. Full set with 
  box/papers commands 15-20% premium. Condition appears unworn. 
  5170 series discontinued, values appreciating. Extract from 
  Archives confirms authenticity and original sale date.
sort_order: 2
parent_id: "[Reference: Jewelry & Watches]"
```

---

## Notes for Implementation

1. **Grouped List** organizes lots by collecting category
2. **Digital Access** serves as auction catalog souvenir
3. Include **estimates** and **session times** for bidding
4. **Provenance** is crucial - include in every lot description
5. AI knowledge should cover authentication, condition, market context
6. Update for each auction sale with new lots
7. Consider adding a "How to Bid" section as additional category

