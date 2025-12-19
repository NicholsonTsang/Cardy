# Winery Tour - Cards Mode (Digital Access)

A wine tasting experience guide with featured wines, tour information, and tasting notes. Cards mode presents each wine prominently with full-width cards and beautiful imagery.

---

## Card Settings

```yaml
name: "Vineyard Estate Winery - Tasting Experience"
description: |
  **Welcome to Vineyard Estate**
  
  Family-owned since 1978 | Award-winning wines
  
  Explore our estate-grown wines and discover the art of 
  winemaking in the heart of wine country.
  
  📍 1200 Vineyard Road, Napa Valley
  ⏰ Tastings: 10 AM - 5 PM daily
  📞 (555) WINERY1

content_mode: cards
is_grouped: false
group_display: null
billing_type: digital
image_url: "[Upload: Winery exterior or vineyard view]"

# AI Configuration
conversation_ai_enabled: true
ai_instruction: |
  You are a knowledgeable sommelier and wine educator. Help guests 
  understand wine characteristics, food pairings, and winemaking 
  processes. Be approachable to beginners while engaging advanced 
  enthusiasts. Share stories about the estate and winemaker. Never 
  encourage overconsumption.

ai_knowledge_base: |
  Vineyard Estate Winery - Napa Valley
  Founded: 1978 by the Martinez family
  Estate: 85 acres, 60 planted to vines
  Elevation: 400-600 feet
  
  Varietals: Cabernet Sauvignon (signature), Chardonnay, 
  Merlot, Sauvignon Blanc, Pinot Noir
  
  Production: 15,000 cases annually
  Farming: Certified sustainable, transitioning to organic
  
  Tasting room: Historic 1920s stone barn
  Tours: 11 AM and 2 PM, reservations required
  
  Tasting fee: $35 (waived with purchase)
  Club members: Complimentary tastings
  
  Current winemaker: Elena Martinez (third generation)
  Awards: 90+ points on multiple wines from Wine Spectator

ai_welcome_general: "Welcome to Vineyard Estate! I can describe any wine's tasting notes, suggest food pairings, share our winemaking story, explain what makes a vintage special, or help you choose a bottle. What interests you?"
ai_welcome_item: "Our {name} is lovely! I can describe the flavor profile, suggest the perfect food pairing, share its story, or compare it to others in our portfolio. What would you like to know?"
```

---

## Content Items

### Hidden Category (Required for flat cards)
```yaml
name: "Wines"
content: ""
image_url: null
ai_knowledge_base: ""
sort_order: 1
parent_id: null
```

#### Estate Cabernet Sauvignon 2021
```yaml
name: "Estate Cabernet Sauvignon 2021"
content: |
  **Our Flagship Wine**
  
  ⭐ 94 Points - Wine Spectator
  
  Dark ruby with violet edges. Aromas of blackcurrant, cedar, 
  and dried herbs give way to a palate of ripe black cherry, 
  espresso, and fine-grained tannins.
  
  ---
  
  🍇 **Details**
  - 100% Estate Cabernet Sauvignon
  - 22 months in French oak (40% new)
  - Alcohol: 14.5%
  - Cases produced: 2,500
  
  🍽 **Pairs With**
  Grilled ribeye, braised short ribs, aged cheeses
  
  💰 **$85** per bottle
  
  *Cellar potential: 15-20 years*

image_url: "[Upload: cabernet_bottle.jpg]"
ai_knowledge_base: |
  Our best-selling wine and Elena's pride. 2021 was exceptional 
  vintage - warm days, cool nights, perfect ripeness. Grapes 
  from oldest vines (planted 1985). French oak from Tronçais 
  forest. Decant 1-2 hours or cellar 5+ years. Compare to Napa 
  cabs at twice the price. Club allocation sells out quickly.
sort_order: 1
parent_id: "[Reference: Wines]"
```

#### Reserve Chardonnay 2022
```yaml
name: "Reserve Chardonnay 2022"
content: |
  **Elegant & Complex**
  
  ⭐ 92 Points - Wine Enthusiast
  
  Golden straw color with brilliant clarity. Notes of ripe pear, 
  white flowers, and subtle oak spice. Creamy texture balanced 
  by bright acidity.
  
  ---
  
  🍇 **Details**
  - 100% Carneros Chardonnay
  - Barrel fermented, sur lie aged
  - Partial malolactic fermentation
  - Alcohol: 13.8%
  - Cases produced: 1,800
  
  🍽 **Pairs With**
  Lobster, roasted chicken, creamy pasta dishes
  
  💰 **$48** per bottle
  
  *Drink now through 2028*

image_url: "[Upload: chardonnay_bottle.jpg]"
ai_knowledge_base: |
  Sourced from cool Carneros region for bright acidity. Barrel 
  fermented in neutral French oak - no heavy oak flavors. 
  Partial malo gives creaminess without being buttery. Great 
  food wine. 2022 had ideal conditions for white wines. Elena's 
  go-to recommendation for Chardonnay skeptics.
sort_order: 2
parent_id: "[Reference: Wines]"
```

#### Merlot 2021
```yaml
name: "Merlot 2021"
content: |
  **Approachable & Velvety**
  
  Deep garnet with ruby highlights. Plush aromas of plum, 
  chocolate, and violets. Soft, round tannins and a long, 
  smooth finish.
  
  ---
  
  🍇 **Details**
  - 92% Merlot, 8% Cabernet Franc
  - 18 months in French oak
  - Alcohol: 14.2%
  - Cases produced: 1,200
  
  🍽 **Pairs With**
  Roast duck, mushroom risotto, lamb chops
  
  💰 **$55** per bottle
  
  *Drink now through 2030*

image_url: "[Upload: merlot_bottle.jpg]"
ai_knowledge_base: |
  Don't let Merlot's reputation fool you - this is serious wine. 
  Touch of Cab Franc adds structure and floral notes. From 
  hillside vineyard block with excellent drainage. More 
  approachable young than our Cabernet. Great introduction to 
  our red wines. Popular with wine club members.
sort_order: 3
parent_id: "[Reference: Wines]"
```

#### Sauvignon Blanc 2023
```yaml
name: "Sauvignon Blanc 2023"
content: |
  **Crisp & Refreshing**
  
  Pale straw with green tints. Vibrant aromas of grapefruit, 
  lime zest, and fresh herbs. Bright acidity with a clean, 
  mineral finish.
  
  ---
  
  🍇 **Details**
  - 100% Estate Sauvignon Blanc
  - Stainless steel fermented
  - No oak contact
  - Alcohol: 13.2%
  - Cases produced: 800
  
  🍽 **Pairs With**
  Oysters, goat cheese salad, ceviche, grilled fish
  
  💰 **$32** per bottle
  
  *Best enjoyed within 2-3 years*

image_url: "[Upload: sauvignon_blanc_bottle.jpg]"
ai_knowledge_base: |
  Perfect summer sipper. Stainless steel preserves fruit purity. 
  Night-harvested to retain acidity. New Zealand style - grassy 
  and bright rather than oaky. Our most affordable wine. Great 
  aperitif or with light seafood. Serve well-chilled (45°F).
sort_order: 4
parent_id: "[Reference: Wines]"
```

#### Late Harvest Viognier 2022
```yaml
name: "Late Harvest Viognier 2022"
content: |
  **Dessert Wine**
  
  ⭐ Limited Release
  
  Brilliant amber gold. Intense aromas of apricot, honey, and 
  orange blossom. Lusciously sweet with balancing acidity.
  
  ---
  
  🍇 **Details**
  - 100% Viognier, late harvested
  - Residual sugar: 12%
  - 375ml half bottle
  - Alcohol: 11.5%
  - Cases produced: 200
  
  🍽 **Pairs With**
  Crème brûlée, blue cheese, foie gras, peach tart
  
  💰 **$38** per half bottle
  
  *Cellar potential: 10+ years*

image_url: "[Upload: viognier_bottle.jpg]"
ai_knowledge_base: |
  Made only in exceptional years when botrytis develops. Grapes 
  left on vine extra month for concentrated sweetness. Natural 
  acidity prevents cloying sweetness. Half bottles perfect for 
  two people with dessert. Elena's passion project - very 
  limited. Compare to French Sauternes at fraction of price.
sort_order: 5
parent_id: "[Reference: Wines]"
```

#### Winery Tour Experience
```yaml
name: "Winery Tour Experience"
content: |
  **Behind the Scenes**
  
  Join us for an intimate tour of our estate and discover the 
  art and science of winemaking.
  
  ---
  
  📍 **Includes**
  - Vineyard walk among the vines
  - Historic barrel cellar tour
  - Production facility overview
  - Library wine tasting
  
  ⏰ **Schedule**
  Daily at 11 AM and 2 PM
  Duration: 90 minutes
  
  👥 **Group Size**
  Maximum 12 guests
  
  💰 **$65** per person
  *(Includes 5-wine tasting)*
  
  **Reservations required**

image_url: "[Upload: barrel_cellar.jpg]"
ai_knowledge_base: |
  Tours book up weeks ahead on weekends - reserve early. 
  Morning tour great for photography (soft light in vineyard). 
  Afternoon tour often led by family member. Barrel cellar 
  dates to 1920s - original stone construction. Library tasting 
  includes wines not normally available. Wear comfortable shoes 
  for vineyard walk. Private tours available for groups of 6+.
sort_order: 6
parent_id: "[Reference: Wines]"
```

---

## Notes for Implementation

1. **Cards Mode** showcases each wine with full-width presentation
2. **Digital Access** ideal for tasting room tablets or guest guides
3. Include **tasting notes, details, and prices** consistently
4. AI knowledge should cover winemaking and food pairing advice
5. Update vintage information annually
6. Consider seasonal specials and limited releases
7. Include tour/experience as content item for complete offering


