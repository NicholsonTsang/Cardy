# Fine Dining Restaurant - Grouped Mode (Digital Access)

An elegant multi-course tasting menu organized by course type. Perfect for upscale restaurants wanting to showcase their seasonal menus with detailed dish descriptions and wine pairings.

---

## Card Settings

```yaml
name: "AURUM - Seasonal Tasting Menu"
description: |
  Welcome to **AURUM**, where culinary artistry meets seasonal excellence.
  
  Our 8-course tasting menu celebrates the finest ingredients of the season, 
  crafted by Executive Chef Isabella Chen and her team.
  
  🍷 Wine pairing available · 🌿 Dietary modifications upon request

content_mode: list
is_grouped: true
group_display: expanded
billing_type: digital
image_url: null  # Digital access - no card image needed

# Optional for digital: daily_scan_limit
daily_scan_limit: 500  # Limit scans per day

# AI Configuration
conversation_ai_enabled: true
ai_instruction: |
  You are a refined sommelier and maitre d' at an upscale restaurant. 
  Speak elegantly but warmly about dishes, ingredients, and wine pairings. 
  Be helpful with dietary restrictions and allergies. Recommend dishes 
  based on guest preferences. Never be pretentious—guests should feel 
  welcomed, not judged.

ai_knowledge_base: |
  AURUM Restaurant - 2 Michelin Stars
  Executive Chef: Isabella Chen (trained at Noma, Eleven Madison Park)
  Cuisine: Modern European with Asian influences
  
  Dietary accommodations: Vegetarian tasting menu available, gluten-free 
  modifications possible for most courses, please inform staff of allergies.
  
  Wine program: 800+ labels, emphasis on biodynamic and natural wines.
  Sommelier: Marcus Thompson, Master Sommelier
  
  Dress code: Smart casual (jackets not required)
  Reservations: Required, 2-3 weeks in advance recommended
  
  All produce sourced within 100 miles. Sustainable seafood certified.
  Kitchen uses only pasture-raised meats and heritage breeds.

ai_welcome_general: "Welcome to AURUM! I can explain any dish on the menu, suggest wine pairings, accommodate dietary needs, or share the story behind Chef Chen's creations. How may I assist your dining experience?"
ai_welcome_item: "Our \"{name}\" is beautifully crafted! I can describe the ingredients, explain the technique, suggest the ideal wine pairing, or note any allergens. What would you like to know?"
```

---

## Content Items

### Category 1: Amuse-Bouche
```yaml
name: "Amuse-Bouche"
content: ""
image_url: null
ai_knowledge_base: |
  The amuse-bouche ("mouth amuser") is a complimentary bite to awaken 
  the palate. Changes daily based on chef's inspiration. Not listed on 
  printed menus to maintain element of surprise.
sort_order: 1
parent_id: null
```

#### Item 1.1: Chef's Welcome
```yaml
name: "Chef's Daily Inspiration"
content: |
  **A gift from the kitchen**
  
  Today's amuse-bouche features a single bite that encapsulates our 
  culinary philosophy: precision, seasonality, and surprise.
  
  *Changes daily—ask your server about today's creation*
  
  ---
  
  🌿 Always includes a vegetarian option  
  ⚠️ Please inform us of any allergies

image_url: "[Upload: elegant_amuse_bouche.jpg]"
ai_knowledge_base: |
  Current rotation includes: black truffle gougère, hamachi tartare on 
  rice cracker, beet meringue with goat cheese. Served on custom ceramic 
  spoons by local artist Mia Santos. Designed to be consumed in one bite. 
  Sets the tone for the entire meal.
sort_order: 1
parent_id: "[Reference: Amuse-Bouche category ID]"
```

---

### Category 2: First Course
```yaml
name: "First Course"
content: ""
image_url: null
ai_knowledge_base: |
  First courses are designed to be light and awakening, featuring 
  delicate flavors and often raw or lightly cooked preparations. 
  Portion size: 3-4 bites.
sort_order: 2
parent_id: null
```

#### Item 2.1: Hokkaido Scallop
```yaml
name: "Hokkaido Scallop"
content: |
  **Diver scallop · yuzu kosho · apple · fennel**
  
  Hand-harvested Hokkaido scallop served raw, dressed with house-made 
  yuzu kosho and accompanied by paper-thin Granny Smith apple and 
  shaved baby fennel.
  
  The natural sweetness of the scallop plays against the citrus heat 
  of the yuzu kosho, while the apple adds brightness and crunch.
  
  ---
  
  🍷 **Wine Pairing:** Domaine Leflaive Puligny-Montrachet 2020  
  🌿 Gluten-free

image_url: "[Upload: hokkaido_scallop.jpg]"
ai_knowledge_base: |
  Scallops flown in twice weekly from Hokkaido, Japan. Only the adductor 
  muscle used—coral reserved for staff meal. Yuzu kosho made in-house 
  with fresh yuzu from California. Apple sliced to order to prevent 
  oxidation. Can substitute with hamachi for scallop allergy.
sort_order: 1
parent_id: "[Reference: First Course category ID]"
```

#### Item 2.2: Heirloom Tomato
```yaml
name: "Heirloom Tomato"
content: |
  **Cherokee purple · burrata · basil · aged balsamic**
  
  The peak of summer captured in a dish. Cherokee Purple heirloom 
  tomatoes from Oak Hill Farm paired with creamy burrata, purple basil, 
  and 25-year aged balsamic vinegar.
  
  A celebration of simplicity—when ingredients are this perfect, 
  restraint becomes the highest technique.
  
  ---
  
  🍷 **Wine Pairing:** Domaine Tempier Bandol Rosé 2022  
  🌿 Vegetarian · Gluten-free

image_url: "[Upload: heirloom_tomato.jpg]"
ai_knowledge_base: |
  Cherokee Purple tomatoes only available July-September. Burrata made 
  fresh daily by local creamery. Balsamic from single producer in Modena, 
  Italy—we buy their entire annual allocation. Purple basil grown in 
  restaurant's rooftop garden. Can omit burrata for vegan version.
sort_order: 2
parent_id: "[Reference: First Course category ID]"
```

---

### Category 3: Second Course
```yaml
name: "Second Course"
content: ""
image_url: null
ai_knowledge_base: |
  Second courses introduce more complexity and often feature our 
  signature techniques. Typically includes a sauce or reduction. 
  Portion size: 4-5 bites.
sort_order: 3
parent_id: null
```

#### Item 3.1: Duck Liver Parfait
```yaml
name: "Duck Liver Parfait"
content: |
  **Foie gras · Sauternes gelée · toasted brioche · smoked salt**
  
  Silky duck liver parfait with a delicate Sauternes gelée, served with 
  house-made brioche toast. The parfait is torchon-style, wrapped and 
  poached for 48 hours to achieve its impossibly smooth texture.
  
  ---
  
  🍷 **Wine Pairing:** Château d'Yquem 2015 (1oz pour)  
  ⚠️ Contains: Dairy, Gluten, Eggs

image_url: "[Upload: duck_liver_parfait.jpg]"
ai_knowledge_base: |
  Foie gras from Hudson Valley Foie Gras, only producer using humane 
  gavage-free methods. Sauternes gelée uses same wine as pairing. 
  Brioche recipe from Chef Isabella's grandmother. Smoked salt made 
  in-house using applewood. Can substitute with chicken liver for cost-conscious guests.
sort_order: 1
parent_id: "[Reference: Second Course category ID]"
```

#### Item 3.2: Roasted Cauliflower
```yaml
name: "Roasted Cauliflower"
content: |
  **Whole-roasted · almond · golden raisin · brown butter**
  
  A whole baby cauliflower roasted until deeply caramelized, served 
  with marcona almond cream, golden raisins plumped in verjus, and 
  nutty brown butter.
  
  Our vegetarian guests' favorite—proof that vegetables can be the 
  star of any table.
  
  ---
  
  🍷 **Wine Pairing:** Kistler Chardonnay 2021  
  🌿 Vegetarian · Can be made vegan

image_url: "[Upload: roasted_cauliflower.jpg]"
ai_knowledge_base: |
  Cauliflower roasted at 500°F for 45 minutes until charred exterior 
  and creamy interior. Almond cream uses marcona almonds from Spain. 
  Vegan version substitutes olive oil for brown butter. One of most 
  Instagrammed dishes. Staff favorite for family meal.
sort_order: 2
parent_id: "[Reference: Second Course category ID]"
```

---

### Category 4: Fish Course
```yaml
name: "Fish Course"
content: ""
image_url: null
ai_knowledge_base: |
  Our fish course showcases sustainable seafood prepared with precision. 
  All seafood is Monterey Bay Aquarium Seafood Watch approved. 
  Fish changes based on daily catch and sustainability.
sort_order: 4
parent_id: null
```

#### Item 4.1: Black Cod
```yaml
name: "Black Cod"
content: |
  **Miso-glazed · bok choy · shiitake · dashi**
  
  Alaskan black cod marinated for 72 hours in our house white miso 
  blend, then broiled until caramelized. Served with baby bok choy, 
  shiitake mushrooms, and a light dashi broth.
  
  Inspired by the legendary Nobu dish, refined with our own techniques.
  
  ---
  
  🍷 **Wine Pairing:** Trimbach Riesling Grand Cru 2019  
  🌿 Gluten-free with tamari substitution

image_url: "[Upload: black_cod.jpg]"
ai_knowledge_base: |
  Black cod (sablefish) from sustainable Alaskan fishery. Miso blend 
  includes white miso, sake, mirin, and a touch of yuzu. 72-hour 
  marinade breaks down proteins for buttery texture. Dashi made fresh 
  daily with kombu and bonito. Can substitute with halibut for different texture.
sort_order: 1
parent_id: "[Reference: Fish Course category ID]"
```

---

### Category 5: Meat Course
```yaml
name: "Meat Course"
content: ""
image_url: null
ai_knowledge_base: |
  Our meat courses feature heritage breeds and dry-aged cuts. All beef 
  is from grass-fed, pasture-raised cattle. We work directly with three 
  family farms within 100 miles.
sort_order: 5
parent_id: null
```

#### Item 5.1: Wagyu Ribeye
```yaml
name: "Wagyu Ribeye"
content: |
  **A5 Miyazaki · bone marrow · porcini · red wine jus**
  
  Japanese A5 Wagyu from Miyazaki Prefecture, seared tableside and 
  served with roasted bone marrow, wild porcini mushrooms, and an 
  intense red wine reduction.
  
  The pinnacle of beef—intricately marbled, impossibly tender, 
  served in 2oz portions to appreciate without overwhelming.
  
  ---
  
  🍷 **Wine Pairing:** Château Margaux 2010  
  ⚠️ Supplement: +$85

image_url: "[Upload: wagyu_ribeye.jpg]"
ai_knowledge_base: |
  A5 is highest grade—only 3% of Japanese beef qualifies. Miyazaki has 
  won "Wagyu Olympics" multiple times. We receive 2 ribeyes per week. 
  Served at exactly medium-rare (130°F internal). Bone marrow from 
  grass-fed cattle. Red wine jus uses same wine as pairing.
sort_order: 1
parent_id: "[Reference: Meat Course category ID]"
```

#### Item 5.2: Berkshire Pork
```yaml
name: "Berkshire Pork"
content: |
  **Heritage pork belly · apple mostarda · crispy sage**
  
  Slow-braised Berkshire pork belly from Newman Farm, finished with 
  a honey glaze and served with spiced apple mostarda and fried sage.
  
  Berkshire pigs are the "Wagyu of pork"—rich, succulent, and 
  incomparably flavorful.
  
  ---
  
  🍷 **Wine Pairing:** Domaine de la Côte Pinot Noir 2020  
  🌿 Gluten-free

image_url: "[Upload: berkshire_pork.jpg]"
ai_knowledge_base: |
  Berkshire (Kurobuta) pigs raised by Newman Farm in Missouri. 
  Heritage breed with higher intramuscular fat. Braised for 8 hours at 
  275°F. Apple mostarda uses local heirloom apples. Sage grown in 
  rooftop garden. Popular alternative to beef course.
sort_order: 2
parent_id: "[Reference: Meat Course category ID]"
```

---

### Category 6: Pre-Dessert
```yaml
name: "Pre-Dessert"
content: ""
image_url: null
ai_knowledge_base: |
  Pre-dessert cleanses the palate between savory and sweet courses. 
  Typically features citrus, herbs, or light dairy. Serves as a 
  gentle transition.
sort_order: 6
parent_id: null
```

#### Item 6.1: Lemon Verbena Sorbet
```yaml
name: "Lemon Verbena Sorbet"
content: |
  **Lemon verbena · champagne · elderflower**
  
  A refreshing interlude: lemon verbena sorbet with a splash of 
  vintage Champagne and elderflower essence.
  
  Designed to cleanse and prepare the palate for our final sweet courses.
  
  ---
  
  🌿 Vegan · Gluten-free

image_url: "[Upload: lemon_verbena_sorbet.jpg]"
ai_knowledge_base: |
  Lemon verbena grown in rooftop garden. Sorbet churned to order. 
  Champagne added tableside (Krug Grande Cuvée). Elderflower from 
  St-Germain. Can omit Champagne for non-alcoholic version. 
  Presented in frozen ceramic bowl.
sort_order: 1
parent_id: "[Reference: Pre-Dessert category ID]"
```

---

### Category 7: Dessert
```yaml
name: "Dessert"
content: ""
image_url: null
ai_knowledge_base: |
  Desserts are created by Pastry Chef David Kim (James Beard Award 
  semifinalist 2023). Focus on balanced sweetness and seasonal ingredients. 
  All desserts pair with our dessert wine or house-made digestif selection.
sort_order: 7
parent_id: null
```

#### Item 7.1: Dark Chocolate Soufflé
```yaml
name: "Dark Chocolate Soufflé"
content: |
  **Valrhona dark chocolate · crème fraîche · fleur de sel**
  
  Our signature dessert: a perfectly risen soufflé made with 70% 
  Valrhona dark chocolate, served with house-made crème fraîche 
  and a whisper of fleur de sel.
  
  *Requires 20 minutes preparation—ordered at start of meal*
  
  ---
  
  🍷 **Pairing:** Banyuls Grand Cru 2018  
  ⚠️ Contains: Eggs, Dairy, Gluten

image_url: "[Upload: chocolate_souffle.jpg]"
ai_knowledge_base: |
  Valrhona Guanaja 70% chocolate from Venezuela beans. Soufflé must 
  be ordered at meal start—precisely timed to rise as guests finish 
  previous course. Crème fraîche cultured in-house for 48 hours. 
  Fleur de sel from Guérande, France. Most popular dessert by far.
sort_order: 1
parent_id: "[Reference: Dessert category ID]"
```

#### Item 7.2: Seasonal Fruit Tart
```yaml
name: "Seasonal Fruit Tart"
content: |
  **Stone fruit · vanilla pastry cream · almond frangipane**
  
  A delicate tart showcasing the best stone fruits of the season: 
  white peaches, apricots, and cherries atop silky vanilla pastry 
  cream and almond frangipane.
  
  Lighter option for those saving room for our petit fours.
  
  ---
  
  🍷 **Pairing:** Moscato d'Asti 2022  
  ⚠️ Contains: Eggs, Dairy, Gluten, Nuts

image_url: "[Upload: fruit_tart.jpg]"
ai_knowledge_base: |
  Fruits change weekly during summer season. Winter version uses 
  poached pears and citrus. Pastry cream uses Madagascar vanilla beans. 
  Frangipane made with marcona almonds. Tart shell is pâte sucrée, 
  blind-baked to perfect crispness. Can make nut-free version.
sort_order: 2
parent_id: "[Reference: Dessert category ID]"
```

---

### Category 8: Petit Fours
```yaml
name: "Petit Fours"
content: ""
image_url: null
ai_knowledge_base: |
  Petit fours ("small oven") are bite-sized confections served with 
  coffee or digestifs. Included with tasting menu. Selection changes weekly.
sort_order: 8
parent_id: null
```

#### Item 8.1: Chef's Selection
```yaml
name: "Chef's Selection"
content: |
  **Handcrafted confections to conclude your meal**
  
  A selection of house-made petit fours served with coffee or tea:
  
  - Dark chocolate truffles with sea salt
  - Lavender shortbread
  - Candied citrus peel
  - Housemade marshmallow
  
  ---
  
  ☕ **Recommended:** Double espresso or chamomile tea  
  🥃 **Digestif:** House limoncello or aged grappa

image_url: "[Upload: petit_fours.jpg]"
ai_knowledge_base: |
  All petit fours made in-house daily. Truffles use same Valrhona 
  chocolate as soufflé. Lavender from Provence. Citrus peel candied 
  over 3 days. Marshmallow flavored with rose water. Coffee is 
  single-origin from Intelligentsia. Complimentary with tasting menu.
sort_order: 1
parent_id: "[Reference: Petit Fours category ID]"
```

---

## Notes for Implementation

1. **Digital Access** is ideal for restaurants—no physical cards needed, just table QR codes
2. **Grouped mode** organizes courses naturally for a tasting menu
3. Categories (courses) don't need images; items (dishes) should have beautiful photos
4. **AI knowledge base** per item enables detailed ingredient/preparation discussions
5. Consider adding wine pairing details to each dish's AI knowledge
6. **Daily scan limit** prevents unexpected costs during busy service
7. Update menu items seasonally to reflect changing offerings

