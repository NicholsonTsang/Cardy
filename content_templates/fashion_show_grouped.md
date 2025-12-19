# Fashion Show - Grouped List (Digital Access)

A fashion show lookbook with looks organized by collection/segment. Grouped List mode allows attendees to browse by collection and view individual looks with designer notes.

---

## Card Settings

```yaml
name: "MAISON ÉLISE - Spring/Summer 2025"
description: |
  **Spring/Summer 2025 Collection**
  
  *"Metamorphosis"*
  
  A journey through transformation, rebirth, and the beauty of change.
  
  Paris Fashion Week | March 2025

content_mode: list
is_grouped: true
group_display: expanded
billing_type: digital
image_url: "[Upload: Show invitation or key look]"

# AI Configuration
conversation_ai_enabled: true
ai_instruction: |
  You are the creative director's assistant at a haute couture fashion house. 
  Share the artistic vision, craftsmanship details, and inspiration behind 
  each look. Speak with sophistication about fabrics, techniques, and fashion 
  history. Be passionate about the creative process while remaining 
  approachable.

ai_knowledge_base: |
  MAISON ÉLISE - Spring/Summer 2025 "Metamorphosis" Collection
  Creative Director: Élise Dubois
  
  Show Details:
  - Date: March 3, 2025, 8:00 PM
  - Venue: Palais de Tokyo, Paris
  - Looks: 45 total across 4 segments
  - Models: 32
  - Duration: 18 minutes
  
  Collection Inspiration:
  The lifecycle of the butterfly—from cocoon to flight. Explores themes of 
  transformation, vulnerability, and emerging beauty. Influenced by Art 
  Nouveau, Japanese origami, and organic architecture.
  
  Key Materials:
  - Sustainable silk from Italian mills
  - Recycled ocean plastics transformed into sequins
  - Hand-painted organza
  - 3D-printed biodegradable elements
  
  Atelier: 47 artisans, 12,000+ hours of handwork

ai_welcome_general: "Welcome to Maison Élise's Spring/Summer 2025 show! I can explain the creative inspiration, describe fabrics and techniques, share details about any look, or give you behind-the-scenes stories. What captivates you?"
ai_welcome_item: "Look {name} is stunning! I can describe the fabrics used, explain the construction technique, share the designer's inspiration, or tell you how it connects to the collection's theme. What interests you?"
```

---

## Content Items

### Segment 1: Cocoon (Opening)
```yaml
name: "I. Cocoon"
content: ""
image_url: null
ai_knowledge_base: |
  Opening segment represents the protective cocoon phase. Enveloping 
  silhouettes, wrapped constructions, muted chrysalis tones. Models 
  emerge from darkened backstage into soft spotlight. Music: ambient 
  electronic by Ólafur Arnalds. 8 looks, 4 minutes.
sort_order: 1
parent_id: null
```

#### Look 1
```yaml
name: "Look 1"
content: |
  **Opening Look**
  
  *The Awakening*
  
  ---
  
  Sculptural cocoon coat in pearl-grey duchesse satin with internal 
  boning creating organic, pod-like silhouette. Underneath: nude 
  mesh bodysuit with hand-sewn crystal "dew drops."
  
  **Fabrication:**
  - Duchesse satin: 15 meters
  - Hand-sewn Swarovski crystals: 2,847
  - Construction hours: 340
  
  **Styling:**
  - Hair: Slicked back, wet look
  - Makeup: Dewy, no-makeup makeup
  - Shoes: Custom nude platforms (hidden)

image_url: "[Upload: look_01.jpg]"
ai_knowledge_base: |
  Opening look sets the tone for entire collection. Élise wanted 
  something that felt "between sleeping and waking." The coat structure 
  was technically challenging - 4 muslin prototypes before final. 
  Crystals placed to catch light as model moves. Model: Adut Akech, 
  specifically requested by Élise for the opening.
sort_order: 1
parent_id: "[Reference: I. Cocoon]"
```

#### Look 2
```yaml
name: "Look 2"
content: |
  **Wrapped Silhouette**
  
  *Suspended*
  
  ---
  
  Asymmetric draped gown in layers of silk organza, ranging from 
  ivory to soft blush. Origami-inspired pleating creates sculptural 
  dimension at shoulder and hip.
  
  **Fabrication:**
  - Silk organza layers: 7
  - Hand-pleating hours: 120
  - Invisible boning structure
  
  **Styling:**
  - Hair: Low chignon with silk ribbon
  - Makeup: Soft peach tones
  - Jewelry: Single pearl ear cuff

image_url: "[Upload: look_02.jpg]"
ai_knowledge_base: |
  Inspired by paper wasp nests - those incredible organic structures. 
  Pleating technique developed specifically for this collection, now 
  called "Élise pleat" by the atelier. Each layer is a slightly 
  different shade - creates depth and movement. Takes 2 fittings per 
  garment to get drape exactly right.
sort_order: 2
parent_id: "[Reference: I. Cocoon]"
```

#### Look 5
```yaml
name: "Look 5"
content: |
  **Statement Outerwear**
  
  *Protection*
  
  ---
  
  Oversized coat in cream double-faced cashmere with cocoon-shaped 
  sleeves. Interior reveals hand-painted butterfly wing motif in 
  watercolor technique on silk lining.
  
  **Fabrication:**
  - Double-faced cashmere from Loro Piana
  - Hand-painted silk lining: 40 hours
  - Horn buttons from sustainable source
  
  **Styling:**
  - Worn over: Nude column dress
  - Hair: Loose, natural texture
  - Bag: Cocoon-shaped minaudière

image_url: "[Upload: look_05.jpg]"
ai_knowledge_base: |
  The "hidden butterfly" concept - exterior is minimal, interior 
  reveals true beauty. Each coat lining is unique, hand-painted 
  by atelier artist Marie Lefevre. Cashmere is sustainably sourced, 
  we can trace to specific Italian farms. This piece has already 
  received pre-orders from 12 clients.
sort_order: 3
parent_id: "[Reference: I. Cocoon]"
```

---

### Segment 2: Emergence
```yaml
name: "II. Emergence"
content: ""
image_url: null
ai_knowledge_base: |
  Second segment represents emergence from the cocoon - vulnerability, 
  first moments of transformation. More body-conscious silhouettes, 
  translucent fabrics, delicate construction. Colors shift to soft 
  pastels. Music: string quartet. 12 looks, 5 minutes.
sort_order: 2
parent_id: null
```

#### Look 12
```yaml
name: "Look 12"
content: |
  **Sheer Layering**
  
  *Vulnerability*
  
  ---
  
  Floor-length gown in 12 layers of hand-dyed silk tulle, gradient 
  from pale pink to deep rose. Strategic placement of embroidered 
  butterfly wing fragments for coverage.
  
  **Fabrication:**
  - Silk tulle layers: 12 (each hand-dyed)
  - 3D embroidered wing elements: 28
  - Total embroidery hours: 180
  
  **Styling:**
  - Hair: Romantic waves
  - Makeup: Rose-tinted glass skin
  - Shoes: Crystal-encrusted sandals

image_url: "[Upload: look_12.jpg]"
ai_knowledge_base: |
  Élise wanted to explore "protective vulnerability" - the contrast 
  between being exposed yet beautiful. Each tulle layer dyed separately 
  then layered for gradient effect. Butterfly fragments are 3D 
  embroidery technique from our Lesage atelier partnership. This look 
  took 3 weeks to complete. Expected to be red carpet favorite.
sort_order: 1
parent_id: "[Reference: II. Emergence]"
```

#### Look 15
```yaml
name: "Look 15"
content: |
  **Daywear Interpretation**
  
  *First Flight*
  
  ---
  
  Tailored suit in pale lavender wool crepe with exaggerated 
  shoulder and nipped waist. Jacket features laser-cut wing 
  pattern revealing silk charmeuse lining.
  
  **Fabrication:**
  - Wool crepe from Dormeuil
  - Laser-cut wing pattern: 847 cuts
  - Silk charmeuse contrast lining
  
  **Styling:**
  - Worn with: Silk camisole
  - Hair: Sleek ponytail
  - Shoes: Pointed-toe pumps
  - Bag: Structured top-handle

image_url: "[Upload: look_15.jpg]"
ai_knowledge_base: |
  Élise believes haute couture should include wearable pieces. 
  This suit is designed for the client who wants art in her everyday. 
  Laser-cutting technology combined with traditional tailoring. 
  The wing pattern took 3 months to perfect - cutting too deep 
  weakens structure, too shallow doesn't show. Commercial department 
  creating ready-to-wear version.
sort_order: 2
parent_id: "[Reference: II. Emergence]"
```

---

### Segment 3: Flight
```yaml
name: "III. Flight"
content: ""
image_url: null
ai_knowledge_base: |
  Third segment celebrates full transformation - joy, freedom, color. 
  Movement-focused designs, bold butterfly colors, dramatic silhouettes. 
  Music: orchestral crescendo. 15 looks, 6 minutes. Includes the 
  collection's most photographed pieces.
sort_order: 3
parent_id: null
```

#### Look 25
```yaml
name: "Look 25"
content: |
  **Dramatic Evening**
  
  *Monarch*
  
  ---
  
  Strapless ballgown with hand-painted monarch butterfly wing print 
  on silk faille. Structured bodice with boning, full skirt with 
  horsehair hem. 25 meters of fabric.
  
  **Fabrication:**
  - Silk faille: 25 meters
  - Hand-painting: 200 hours
  - Internal structure: Corsetry and crinolines
  
  **Styling:**
  - Hair: Voluminous updo
  - Makeup: Dramatic orange-black eye
  - Jewelry: Vintage Cartier butterfly brooch

image_url: "[Upload: look_25.jpg]"
ai_knowledge_base: |
  The "hero" look of the collection - every show needs one. Hand-painting 
  by our textile artist took 200 hours - each scale of the butterfly 
  wing individually painted. Monarch chosen for its symbolism of 
  migration and transformation. The vintage Cartier brooch belongs 
  to Élise personally, from her grandmother.
sort_order: 1
parent_id: "[Reference: III. Flight]"
```

#### Look 28
```yaml
name: "Look 28"
content: |
  **Sculptural Drama**
  
  *Wingspan*
  
  ---
  
  Architectural gown with 3D-printed wing structure emerging from 
  back. Base gown in black silk crepe, wings in iridescent recycled 
  ocean plastic. Wings span 2 meters.
  
  **Fabrication:**
  - 3D-printed wings: Biodegradable PLA
  - Recycled ocean plastic sequins: 5,000+
  - Wingspan: 2 meters
  - Engineering collaboration with MIT Media Lab
  
  **Styling:**
  - Hair: Severe bun
  - Makeup: Graphic black liner
  - Shoes: Platform boots (for height/balance)

image_url: "[Upload: look_28.jpg]"
ai_knowledge_base: |
  Our sustainability statement piece. Collaborated with MIT Media Lab 
  on the wing structure - had to be light enough to wear yet dramatic 
  on runway. Each sequin is made from recycled ocean plastic collected 
  from Pacific cleanup. Model trained for 2 days to walk with wings. 
  Wings detach - gown wearable without them.
sort_order: 2
parent_id: "[Reference: III. Flight]"
```

#### Look 32
```yaml
name: "Look 32"
content: |
  **Red Carpet Statement**
  
  *Chrysalis to Flight*
  
  ---
  
  Color-gradient gown transitioning from cocoon grey at hem to 
  vibrant butterfly blue at bodice. 3D fabric manipulation creates 
  emerging wing effect at shoulders.
  
  **Fabrication:**
  - Gradient-dyed silk gazar
  - 3D fabric origami: 80 hours
  - Crystal dewdrops: 1,200
  
  **Styling:**
  - Hair: Wet-look waves
  - Makeup: Blue-toned highlight
  - Jewelry: Statement ear cuff

image_url: "[Upload: look_32.jpg]"
ai_knowledge_base: |
  This gown tells the entire collection story in one piece - the 
  gradient represents the metamorphosis journey. Custom dye process 
  using natural indigo. The 3D shoulder elements were inspired by 
  butterfly emerging from chrysalis. Already requested by 3 A-list 
  actresses for upcoming awards season.
sort_order: 3
parent_id: "[Reference: III. Flight]"
```

---

### Segment 4: Finale
```yaml
name: "IV. Finale"
content: ""
image_url: null
ai_knowledge_base: |
  Closing segment: the bride and finale looks. Ultimate transformation 
  and celebration. All-white segment, maximum drama. Music: silence 
  then applause. 10 looks including bride, 3 minutes. Designer bow 
  after bride.
sort_order: 4
parent_id: null
```

#### Look 42: Bride
```yaml
name: "Look 42 - Bride"
content: |
  **Bridal**
  
  *Eternal Metamorphosis*
  
  ---
  
  Bridal gown in ivory silk mikado with detachable cape featuring 
  3D hand-sculpted butterfly garden. 50 individual silk butterflies, 
  each unique, appear to be taking flight from the train.
  
  **Fabrication:**
  - Silk mikado gown with boning
  - Detachable cape: 4 meters
  - Hand-sculpted silk butterflies: 50
  - Total creation hours: 800
  
  **Styling:**
  - Hair: Natural, flowing
  - Makeup: Fresh, glowing
  - Veil: Tulle with scattered crystals
  - Shoes: Ivory satin platforms

image_url: "[Upload: look_42_bride.jpg]"
ai_knowledge_base: |
  The bridal look is always the most anticipated. Each butterfly is 
  hand-sculpted from silk, wired to "flutter" as the model walks. 
  50 unique butterflies - no two alike. Concept: bride as the ultimate 
  transformation, surrounded by fellow creatures in flight. Cape 
  detaches for reception. This gown will be made-to-order for clients.
sort_order: 1
parent_id: "[Reference: IV. Finale]"
```

#### Look 45: Designer Bow
```yaml
name: "Look 45 - Finale"
content: |
  **Designer Bow**
  
  *Élise Dubois*
  
  ---
  
  Creative Director Élise Dubois takes her bow accompanied by the 
  full cast of models in the finale walk.
  
  Élise wears: Black silk shirt, tailored trousers, bare feet—her 
  signature bow look. A single monarch butterfly pin on her collar.
  
  ---
  
  🦋 *"Fashion is metamorphosis. We are all becoming."*  
  — Élise Dubois

image_url: "[Upload: designer_bow.jpg]"
ai_knowledge_base: |
  Élise always takes her bow barefoot - she says it keeps her grounded 
  after months of work. The monarch pin was a gift from her first 
  atelier teacher. This is her 15th collection for the house. Standing 
  ovation lasted 3 minutes. Anna Wintour, Carine Roitfeld, and Edward 
  Enninful all in attendance.
sort_order: 2
parent_id: "[Reference: IV. Finale]"
```

---

## Notes for Implementation

1. **Grouped List** organizes looks by show segment/collection chapter
2. **Digital Access** serves as fashion show program and lookbook souvenir
3. Include **fabrication details** for fashion industry attendees
4. Professional photos of each look are essential
5. **AI knowledge** shares behind-the-scenes creative process
6. Consider adding backstage, atelier, or inspiration images
7. Update for each season's new collection
8. Can adapt for trunk shows, press previews, or client presentations

