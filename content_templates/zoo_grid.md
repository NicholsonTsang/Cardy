# Zoo - Grid Mode (Digital Access)

A zoo visitor guide with animal exhibits displayed in a visual 2-column grid. Perfect for zoos, aquariums, and wildlife parks where visitors want to browse animals visually.

---

## Card Settings

```yaml
name: "City Zoo - Animal Explorer Card"
description: |
  Welcome to **City Zoo**! Home to over 500 animals from 6 continents.
  
  Use this card to learn about our amazing animals. Tap any photo to 
  discover fascinating facts, conservation status, and feeding times.
  
  🦁 AI Guide available for questions about any animal!

content_mode: grid
is_grouped: true
group_display: expanded
billing_type: digital
image_url: "[Upload: Zoo entrance or signature animal photo]"

# AI Configuration
conversation_ai_enabled: true
ai_instruction: |
  You are an enthusiastic zoo educator who loves sharing animal facts. 
  Be engaging for all ages—from curious kids to adult learners. Share 
  fun facts, conservation information, and help visitors plan their route. 
  Encourage respect for animals and their habitats.

ai_knowledge_base: |
  City Zoo - Founded 1920
  Animals: 500+ individuals, 120 species
  Area: 80 acres with themed habitats
  
  Zones: African Savanna, Asian Forest, Australian Outback, 
  Polar World, Tropical Rainforest, North American Wildlife
  
  Daily shows: Sea lion show 11am & 2pm, Bird flight 12pm & 3pm
  Feeding times: Penguins 10:30am, Elephants 1pm, Big cats 3:30pm
  
  Facilities: Gift shop, 3 cafés, stroller rental, accessibility services
  Conservation: Partner with WWF, Species Survival Plan participant

ai_welcome_general: "Welcome to City Zoo! I can share fun facts about any animal, tell you feeding times, suggest the best route to see everything, or help you find specific animals. What would you like to explore?"
ai_welcome_item: "Our {name} is amazing! I can share fun facts, conservation status, their individual story, feeding times, or tips for the best viewing spot. What interests you?"
```

---

## Content Items (Animals)

### Item 1: African Lion
```yaml
name: "African Lion"
content: |
  **King of the Jungle** 🦁
  
  **Scientific Name:** *Panthera leo*  
  **Habitat:** African Savanna Zone  
  **Conservation Status:** Vulnerable
  
  Meet Simba and Nala, our resident lion pride. Lions are the only 
  cats that live in social groups called prides. Our pride includes 
  1 male and 2 females.
  
  **Did you know?** A lion's roar can be heard from 5 miles away!
  
  ⏰ **Feeding Time:** 3:30 PM daily

image_url: "[Upload: african_lion.jpg]"
ai_knowledge_base: |
  Simba (male, 8 years) arrived from San Diego Zoo in 2019. Nala and 
  Sarabi (females, 6 years) are sisters from Dallas Zoo. Lions sleep 
  16-20 hours per day. Only 20,000 wild lions remain - down from 200,000 
  in 1950. Main threats: habitat loss, human-wildlife conflict. 
  Our zoo supports lion conservation in Kenya.
sort_order: 1
```

### Item 2: Giant Panda
```yaml
name: "Giant Panda"
content: |
  **Beloved Bamboo Muncher** 🐼
  
  **Scientific Name:** *Ailuropoda melanoleuca*  
  **Habitat:** Asian Forest Zone  
  **Conservation Status:** Vulnerable
  
  Mei Mei spends up to 14 hours a day eating bamboo! Pandas have a 
  specialized wrist bone that acts like a thumb to grip bamboo stalks.
  
  **Did you know?** Pandas poop up to 40 times a day!
  
  ⏰ **Feeding Time:** 10:00 AM, 2:00 PM, 5:00 PM

image_url: "[Upload: giant_panda.jpg]"
ai_knowledge_base: |
  Mei Mei (female, 12 years) on loan from China. Pandas are solitary 
  in the wild. They eat 26-84 pounds of bamboo daily but digest only 
  20%. Conservation success story - upgraded from Endangered in 2016. 
  China's panda conservation program has increased wild population to 
  1,800+. Mei Mei's favorite bamboo variety is arrow bamboo.
sort_order: 2
```

### Item 3: Emperor Penguin
```yaml
name: "Emperor Penguin"
content: |
  **Antarctic Survivor** 🐧
  
  **Scientific Name:** *Aptenodytes forsteri*  
  **Habitat:** Polar World Zone  
  **Conservation Status:** Near Threatened
  
  Our colony of 15 emperor penguins lives in a climate-controlled 
  habitat that replicates Antarctic conditions. They're the tallest 
  penguin species, standing up to 4 feet tall!
  
  **Did you know?** Male emperors incubate eggs on their feet for 
  2 months without eating!
  
  ⏰ **Feeding Time:** 10:30 AM daily

image_url: "[Upload: emperor_penguin.jpg]"
ai_knowledge_base: |
  Colony established in 2010 with birds from Sea World. Can dive to 
  1,800 feet - deepest of any bird. They huddle together in -40°F 
  temperatures, rotating positions so everyone gets warm center. 
  Our habitat is kept at 28°F with artificial snow. Popular with 
  kids - often their favorite animal. Climate change is primary threat.
sort_order: 3
```

### Item 4: Asian Elephant
```yaml
name: "Asian Elephant"
content: |
  **Gentle Giants** 🐘
  
  **Scientific Name:** *Elephas maximus*  
  **Habitat:** Asian Forest Zone  
  **Conservation Status:** Endangered
  
  Ruby (42) and Jade (18) are our two Asian elephants. Smaller than 
  African elephants, they have smaller ears and only males have 
  visible tusks.
  
  **Did you know?** Elephants can recognize themselves in mirrors - 
  a sign of self-awareness!
  
  ⏰ **Feeding Time:** 1:00 PM daily (Public feeding experience available)

image_url: "[Upload: asian_elephant.jpg]"
ai_knowledge_base: |
  Ruby arrived 1985, one of zoo's oldest residents. Jade is her 
  adopted daughter (not biological). Asian elephants smaller than 
  African (8,000 vs 14,000 lbs). Only 40,000 remain in wild. 
  Our elephants have 3-acre habitat with pool, mud wallow, and 
  enrichment puzzles. They eat 200 lbs of food daily including 
  hay, vegetables, and browse (tree branches).
sort_order: 4
```

### Item 5: Red Panda
```yaml
name: "Red Panda"
content: |
  **Firefox in the Trees** 🔴
  
  **Scientific Name:** *Ailurus fulgens*  
  **Habitat:** Asian Forest Zone  
  **Conservation Status:** Endangered
  
  Despite their name, red pandas are not closely related to giant 
  pandas! Rusty and Scarlet spend most of their time in trees, 
  using their long bushy tails for balance.
  
  **Did you know?** Red pandas were discovered 50 years before 
  giant pandas and were the original "panda"!
  
  ⏰ **Most Active:** Early morning and late afternoon

image_url: "[Upload: red_panda.jpg]"
ai_knowledge_base: |
  Rusty (male, 5) and Scarlet (female, 4) arrived from Cincinnati 
  Zoo in 2021. Red pandas are closer relatives to raccoons than 
  giant pandas. They have a false thumb like giant pandas - example 
  of convergent evolution. Firefox browser was named after them! 
  Fewer than 10,000 in wild. They primarily eat bamboo like giant 
  pandas but are more omnivorous.
sort_order: 5
```

### Item 6: Gorilla
```yaml
name: "Western Lowland Gorilla"
content: |
  **Our Closest Relatives** 🦍
  
  **Scientific Name:** *Gorilla gorilla gorilla*  
  **Habitat:** Tropical Rainforest Zone  
  **Conservation Status:** Critically Endangered
  
  Our gorilla troop is led by Koko, a 380-pound silverback. 
  Gorillas share 98% of their DNA with humans and live in 
  family groups led by a dominant male.
  
  **Did you know?** Each gorilla has unique nose prints, like 
  human fingerprints!
  
  ⏰ **Best Viewing:** 11:00 AM - 1:00 PM (when most active)

image_url: "[Upload: gorilla.jpg]"
ai_knowledge_base: |
  Koko (silverback, 28) leads troop of 6 including 3 females and 
  2 juveniles. Born at zoo in 1996. Gorillas are gentle despite 
  their size - primarily herbivorous. Silverback name comes from 
  silver hair that develops on mature males' backs. Only 100,000 
  western lowland gorillas remain. Main threats: poaching, disease, 
  habitat loss. Zoo participates in Species Survival Plan.
sort_order: 6
```

### Item 7: Giraffe
```yaml
name: "Reticulated Giraffe"
content: |
  **Towering Beauties** 🦒
  
  **Scientific Name:** *Giraffa camelopardalis reticulata*  
  **Habitat:** African Savanna Zone  
  **Conservation Status:** Endangered
  
  At 18 feet tall, our giraffes are the tallest animals at the zoo! 
  Their long necks have the same number of vertebrae as humans - 
  just much bigger.
  
  **Did you know?** A giraffe's tongue is 18 inches long and 
  prehensile (can grip things)!
  
  ⏰ **Giraffe Feeding Experience:** 11:30 AM ($5 per person)

image_url: "[Upload: giraffe.jpg]"
ai_knowledge_base: |
  Tower of 4 giraffes: Twiga (female, 12), her daughter Amara (4), 
  plus Geoffrey and Stretch (males). "Reticulated" refers to their 
  net-like pattern. Each giraffe's pattern is unique. They only need 
  30 minutes of sleep per day, taken in short naps. Heart weighs 
  25 pounds to pump blood up that long neck. Giraffe populations 
  declined 40% in 30 years - a "silent extinction."
sort_order: 7
```

### Item 8: Komodo Dragon
```yaml
name: "Komodo Dragon"
content: |
  **Living Dinosaur** 🦎
  
  **Scientific Name:** *Varanus komodoensis*  
  **Habitat:** Tropical Rainforest Zone  
  **Conservation Status:** Endangered
  
  Raja is our 8-foot Komodo dragon - the world's largest living 
  lizard. These ancient predators have venomous saliva and can 
  detect prey from 6 miles away.
  
  **Did you know?** Komodo dragons can eat 80% of their body 
  weight in a single meal!
  
  ⏰ **Feeding Time:** Fridays 2:00 PM (whole prey demonstration)

image_url: "[Upload: komodo_dragon.jpg]"
ai_knowledge_base: |
  Raja (male, 15) arrived from Denver Zoo in 2015. Komodos only 
  found on 4 Indonesian islands. Venomous bite prevents blood 
  clotting - prey bleeds to death. Can run 13 mph in short bursts. 
  Females can reproduce without males (parthenogenesis). Only 
  3,000-5,000 in wild. Feeding demonstration uses whole rabbits 
  (warning given for sensitive viewers).
sort_order: 8
```

### Item 9: Koala
```yaml
name: "Koala"
content: |
  **Sleepy Eucalyptus Lover** 🐨
  
  **Scientific Name:** *Phascolarctos cinereus*  
  **Habitat:** Australian Outback Zone  
  **Conservation Status:** Vulnerable
  
  Bindi and Bluey are our resident koalas, sleeping up to 22 hours 
  a day. They're not actually bears - they're marsupials who carry 
  their babies in pouches!
  
  **Did you know?** Koalas have fingerprints nearly identical to 
  human fingerprints!
  
  ⏰ **Most Active:** Early morning (around opening time)

image_url: "[Upload: koala.jpg]"
ai_knowledge_base: |
  Bindi (female, 7) and Bluey (male, 5) both from Australian 
  breeding program. Koalas sleep so much because eucalyptus is 
  low in nutrition and takes lots of energy to digest. They have 
  special bacteria in their gut to process eucalyptus toxins. 
  Australian bushfires in 2019-2020 killed 30% of population. 
  We grow 5 species of eucalyptus on-site for their diet.
sort_order: 9
```

### Item 10: Polar Bear
```yaml
name: "Polar Bear"
content: |
  **Arctic Apex Predator** 🐻‍❄️
  
  **Scientific Name:** *Ursus maritimus*  
  **Habitat:** Polar World Zone  
  **Conservation Status:** Vulnerable
  
  Nanook weighs 1,200 pounds and is an excellent swimmer. Polar 
  bears are the largest land carnivores and are perfectly adapted 
  to life on Arctic ice.
  
  **Did you know?** Polar bear fur isn't white - it's transparent! 
  It just appears white because it reflects light.
  
  ⏰ **Enrichment Time:** 2:30 PM daily (watch Nanook solve puzzles!)

image_url: "[Upload: polar_bear.jpg]"
ai_knowledge_base: |
  Nanook (male, 18) born at zoo, never lived in wild. Polar bears 
  are marine mammals - spend most of life on sea ice hunting seals. 
  Black skin under transparent fur helps absorb heat. Only 26,000 
  polar bears remain. Climate change is existential threat - sea 
  ice shrinking means less hunting time. Our habitat includes 
  100,000-gallon pool for swimming.
sort_order: 10
```

---

## Notes for Implementation

1. **Grid mode** is perfect for visual browsing of animals
2. **Digital Access** makes a great souvenir for zoo visitors
3. Each animal has AI knowledge for educational conversations
4. Include **feeding times** and **best viewing times** for visitor planning
5. **Conservation status** educates visitors about wildlife protection
6. Consider adding more animals based on your zoo's collection
7. Update seasonally for baby animals, temporary exhibits, etc.

