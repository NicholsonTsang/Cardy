# History Museum - Grouped Mode (Digital Access)

A comprehensive museum experience with exhibits organized by historical era. The grouped mode allows visitors to navigate by category (time period) and explore individual artifacts within each section.

---

## Card Settings

```yaml
name: "Journey Through Time: City Heritage Museum"
description: |
  Discover **5,000 years of history** at the City Heritage Museum.
  
  From ancient civilizations to modern innovations, explore artifacts, stories, 
  and interactive displays that bring our shared past to life.
  
  🏛️ Tap any category to browse exhibits, or use the AI guide for personalized tours.

content_mode: list
is_grouped: true
group_display: expanded
billing_type: digital
image_url: "[Upload: Museum entrance or iconic artifact photo]"

# AI Configuration
conversation_ai_enabled: true
ai_instruction: |
  You are a knowledgeable museum guide with expertise in world history. 
  Share fascinating stories and lesser-known facts about exhibits. 
  Connect historical events to modern life. Be engaging and educational 
  without being dry or overly academic. Encourage curiosity and questions.

ai_knowledge_base: |
  City Heritage Museum - Founded 1892
  
  Collection: Over 50,000 artifacts spanning 5 millennia
  Floors: 4 exhibition floors plus basement archives
  
  Visitor facilities: Café on ground floor, gift shop near exit, 
  accessible restrooms on all floors, wheelchair loan available at reception.
  
  Special programs: School groups welcome, senior discounts on Tuesdays,
  free admission first Sunday of each month.
  
  Photography allowed without flash. Some artifacts have handling 
  restrictions for conservation.

ai_welcome_general: "Welcome to the City Heritage Museum! I can share fascinating stories about any artifact, explain historical context, suggest must-see highlights, or help plan your route. Which era interests you most?"
ai_welcome_item: "You're looking at \"{name}\" - I can tell you how it was made, who used it, why it matters historically, or share surprising stories about it. What would you like to know?"
```

---

## Content Items

### Category 1: Ancient Civilizations (3000 BCE - 500 CE)
```yaml
name: "Ancient Civilizations"
content: "" # Categories in grouped mode typically don't have description
image_url: null # Categories don't use images
ai_knowledge_base: |
  The Ancient Civilizations gallery covers Mesopotamia, Egypt, Greece, Rome, 
  and early Chinese dynasties. Highlights include genuine cuneiform tablets, 
  Egyptian shabtis, Greek pottery, and Roman coins. Climate controlled at 
  21°C with 45% humidity for artifact preservation.
sort_order: 1
parent_id: null
```

#### Item 1.1: Cuneiform Tablet - Trade Record
```yaml
name: "Cuneiform Tablet - Trade Record"
content: |
  **Origin:** Mesopotamia (modern-day Iraq)  
  **Date:** c. 2100 BCE  
  **Material:** Clay
  
  This clay tablet records a shipment of barley and wool between merchants 
  in the ancient city of Ur. The cuneiform script, one of humanity's earliest 
  writing systems, was pressed into wet clay using a reed stylus.
  
  The tablet provides rare insight into daily commerce in ancient Sumer, 
  showing that trade networks, contracts, and accounting existed over 4,000 years ago.

image_url: "[Upload: cuneiform_tablet.jpg]"
ai_knowledge_base: |
  Found during excavations at Ur in 1928. Translated by Professor Samuel Kramer. 
  Records 50 bushels of barley and 3 bolts of wool. Mentions a merchant named 
  Ur-Nammu (not the king). Shows early math - Sumerians used base-60 number system, 
  which is why we have 60 seconds in a minute today.
sort_order: 1
parent_id: "[Reference: Ancient Civilizations category ID]"
```

#### Item 1.2: Egyptian Shabti Figure
```yaml
name: "Egyptian Shabti Figure"
content: |
  **Origin:** Thebes, Egypt  
  **Date:** c. 1300 BCE (New Kingdom)  
  **Material:** Faience (glazed ceramic)
  
  Shabtis were placed in tombs to serve the deceased in the afterlife. 
  Ancient Egyptians believed these small figures would magically come to 
  life to perform manual labor for their owner in the next world.
  
  This shabti bears hieroglyphic inscriptions identifying it as belonging 
  to a scribe named Amenhotep.

image_url: "[Upload: shabti_figure.jpg]"
ai_knowledge_base: |
  Wealthy Egyptians were buried with 365 shabtis - one for each day of the year. 
  This example is 15cm tall, typical for a middle-class official. The blue-green 
  faience glaze was associated with rebirth and the Nile's life-giving waters. 
  Acquired by the museum in 1905 from the Egypt Exploration Fund.
sort_order: 2
parent_id: "[Reference: Ancient Civilizations category ID]"
```

#### Item 1.3: Greek Black-Figure Amphora
```yaml
name: "Greek Black-Figure Amphora"
content: |
  **Origin:** Athens, Greece  
  **Date:** c. 530 BCE  
  **Material:** Terracotta
  
  This storage vessel depicts Heracles battling the Nemean lion, one of 
  his famous Twelve Labors. The "black-figure" technique involves painting 
  figures in slip that turns black when fired, with details incised to 
  reveal the red clay beneath.
  
  Such vessels were prized throughout the Mediterranean and often exported 
  filled with olive oil or wine.

image_url: "[Upload: greek_amphora.jpg]"
ai_knowledge_base: |
  Attributed to the Antimenes Painter, one of the most prolific black-figure 
  artists. 52cm tall, holds approximately 30 liters. Found in an Etruscan tomb 
  in Italy - showing how Greek goods spread across the ancient world. 
  The scene shows the moment Heracles realizes arrows won't pierce the lion's hide.
sort_order: 3
parent_id: "[Reference: Ancient Civilizations category ID]"
```

---

### Category 2: Medieval World (500 - 1500 CE)
```yaml
name: "Medieval World"
content: ""
image_url: null
ai_knowledge_base: |
  The Medieval gallery explores European, Islamic, and Asian civilizations 
  during this period. Includes armor, manuscripts, religious art, and trade goods. 
  Features a reconstructed monk's scriptorium and interactive knight's armor display.
sort_order: 2
parent_id: null
```

#### Item 2.1: Illuminated Manuscript Page
```yaml
name: "Illuminated Manuscript Page"
content: |
  **Origin:** England  
  **Date:** c. 1150 CE  
  **Material:** Vellum (calfskin), gold leaf, mineral pigments
  
  This page from a psalter (book of psalms) showcases the incredible artistry 
  of medieval monks. The large decorated initial "B" (for "Beatus") contains 
  intricate interlacing patterns and gold leaf highlights.
  
  Creating such manuscripts was painstaking work—a single book could take 
  years to complete.

image_url: "[Upload: illuminated_manuscript.jpg]"
ai_knowledge_base: |
  From a psalter produced at Canterbury Cathedral. The blue pigment is 
  ultramarine, made from lapis lazuli imported from Afghanistan - more 
  expensive than gold. Red is vermilion from cinnabar. The gold is 23-karat, 
  hammered into leaf 1/10,000th of a millimeter thick. Acquired from a private 
  collection in 1956.
sort_order: 1
parent_id: "[Reference: Medieval World category ID]"
```

#### Item 2.2: Knight's Great Helm
```yaml
name: "Knight's Great Helm"
content: |
  **Origin:** Germany  
  **Date:** c. 1350 CE  
  **Material:** Steel, brass rivets
  
  The "great helm" or "pot helm" offered maximum protection for knights 
  in tournament combat. This example features a flat top and narrow eye 
  slits, typical of 14th-century design.
  
  Weighing 3.2kg, it would have been worn over a padded cap and chainmail coif. 
  The restricted vision and ventilation made it impractical for battlefield 
  use, so it was primarily ceremonial and for jousting.

image_url: "[Upload: knights_helm.jpg]"
ai_knowledge_base: |
  Shows hammer marks from hand-forging. The brass rivets are original. 
  Originally had a crest mount on top for identifying the knight. Could 
  withstand lance impact but cooking hot in summer sun. Knights often 
  collapsed from heat exhaustion rather than wounds. Purchased at 
  Sotheby's auction in 1972.
sort_order: 2
parent_id: "[Reference: Medieval World category ID]"
```

#### Item 2.3: Islamic Astrolabe
```yaml
name: "Islamic Astrolabe"
content: |
  **Origin:** Toledo, Spain  
  **Date:** c. 1100 CE  
  **Material:** Brass, silver inlay
  
  This sophisticated astronomical instrument was used for navigation, 
  timekeeping, and determining the direction of Mecca for prayer. 
  Islamic scholars preserved and advanced Greek astronomical knowledge 
  during the medieval period.
  
  The Arabic inscriptions include star names and astronomical tables—many 
  of which are still used in Western astronomy today.

image_url: "[Upload: islamic_astrolabe.jpg]"
ai_knowledge_base: |
  Made during Islamic rule of Spain (Al-Andalus). Signed by craftsman 
  Ibrahim ibn Sa'id al-Sahli. Could determine latitude to within 1 degree. 
  Star names like Betelgeuse, Rigel, and Aldebaran come from Arabic. 
  This instrument type wasn't surpassed until the invention of the sextant 
  in the 18th century.
sort_order: 3
parent_id: "[Reference: Medieval World category ID]"
```

---

### Category 3: Age of Exploration (1500 - 1800)
```yaml
name: "Age of Exploration"
content: ""
image_url: null
ai_knowledge_base: |
  This gallery covers European expansion, colonial trade, the Scientific 
  Revolution, and the Enlightenment. Features navigation instruments, 
  trade goods, early scientific equipment, and art from the period.
sort_order: 3
parent_id: null
```

#### Item 3.1: Dutch East India Company Porcelain
```yaml
name: "Dutch East India Company Porcelain"
content: |
  **Origin:** Jingdezhen, China (exported to Europe)  
  **Date:** c. 1720  
  **Material:** Hard-paste porcelain, cobalt blue glaze
  
  This plate was commissioned by the Dutch East India Company (VOC) for 
  export to wealthy European households. Chinese artisans adapted their 
  traditional blue-and-white designs to suit European tastes.
  
  The VOC shipped millions of pieces of porcelain westward, making Chinese 
  porcelain so fashionable that European factories spent decades trying 
  to recreate the secret formula.

image_url: "[Upload: voc_porcelain.jpg]"
ai_knowledge_base: |
  Part of a set of 200 pieces ordered for a Dutch merchant family. 
  "Kraak" style porcelain with panels radiating from center. The VOC 
  mark on bottom verified authenticity. Took 18 months from order to 
  delivery via ship around Cape of Good Hope. Europeans didn't discover 
  how to make true porcelain until 1708 at Meissen.
sort_order: 1
parent_id: "[Reference: Age of Exploration category ID]"
```

#### Item 3.2: Mariner's Compass
```yaml
name: "Mariner's Compass"
content: |
  **Origin:** London, England  
  **Date:** 1753  
  **Maker:** Henry Gregory
  
  This brass mariner's compass helped navigate the world's oceans during 
  the height of British naval power. The gimbal mount keeps the compass 
  level despite the ship's rolling motion.
  
  Such instruments were essential for the trade routes that connected 
  continents and transformed global commerce.

image_url: "[Upload: mariners_compass.jpg]"
ai_knowledge_base: |
  Maker Henry Gregory was official instrument maker to the Royal Navy. 
  The compass card is hand-painted on mica. The gimbal design prevents 
  tilting up to 45 degrees. Would have been used alongside charts, sextant, 
  and log line. Donated by descendants of Captain James Harewood in 1891.
sort_order: 2
parent_id: "[Reference: Age of Exploration category ID]"
```

---

### Category 4: Industrial Revolution (1800 - 1914)
```yaml
name: "Industrial Revolution"
content: ""
image_url: null
ai_knowledge_base: |
  The Industrial Revolution gallery showcases the transformation from 
  agrarian society to industrial power. Features machinery, photographs, 
  worker artifacts, and items showing daily life during rapid change. 
  Includes a working steam engine demonstration (Saturdays at 2pm).
sort_order: 4
parent_id: null
```

#### Item 4.1: Spinning Jenny Model
```yaml
name: "Spinning Jenny Model"
content: |
  **Origin:** Lancashire, England  
  **Date:** c. 1785 (replica of 1764 original)  
  **Material:** Wood, metal, cotton thread
  
  James Hargreaves' Spinning Jenny revolutionized textile production by 
  allowing one worker to operate eight spindles simultaneously. This 
  working model demonstrates the mechanism that helped spark the 
  Industrial Revolution.
  
  Before the Jenny, spinning thread was slow hand-work. After, cloth 
  production increased dramatically, transforming the global economy.

image_url: "[Upload: spinning_jenny.jpg]"
ai_knowledge_base: |
  Working replica built by museum workshop in 1923. Original could 
  produce 8 threads at once vs. 1 on a spinning wheel - 8x productivity. 
  Named "Jenny" possibly after Hargreaves' daughter. Hand-spinners 
  initially attacked the machines, fearing job losses. Led to factory 
  system replacing cottage industry.
sort_order: 1
parent_id: "[Reference: Industrial Revolution category ID]"
```

#### Item 4.2: Victorian Factory Worker's Lunch Pail
```yaml
name: "Victorian Factory Worker's Lunch Pail"
content: |
  **Origin:** Birmingham, England  
  **Date:** c. 1890  
  **Material:** Tin-plated steel
  
  This humble lunch pail tells the story of ordinary workers who powered 
  the Industrial Revolution. Factory shifts of 12-14 hours meant workers 
  brought meals from home.
  
  The two-compartment design kept food separate—typically bread and cheese 
  in one section, cold tea or water in the other. Scratched initials 
  "J.W." are visible on the bottom.

image_url: "[Upload: lunch_pail.jpg]"
ai_knowledge_base: |
  Found during demolition of old textile mill in 1967. J.W. possibly 
  John or James Williams - common names in factory records. Factory 
  workers earned 10-15 shillings per week. Women and children earned 
  less. Lunch breaks were often just 30 minutes. No refrigeration meant 
  food spoiled quickly in summer heat of factories.
sort_order: 2
parent_id: "[Reference: Industrial Revolution category ID]"
```

---

### Category 5: Modern Era (1914 - Present)
```yaml
name: "Modern Era"
content: ""
image_url: null
ai_knowledge_base: |
  The Modern Era gallery covers both World Wars, social movements, 
  technological innovation, and contemporary history. Includes oral 
  history stations with video testimonies. Sensitive content warnings 
  at gallery entrance.
sort_order: 5
parent_id: null
```

#### Item 5.1: WWI Soldier's Trench Art
```yaml
name: "WWI Soldier's Trench Art"
content: |
  **Origin:** Western Front, France  
  **Date:** c. 1917  
  **Material:** Brass artillery shell casing, hand-engraved
  
  Soldiers on both sides of WWI created "trench art" from battlefield 
  debris during quiet moments. This shell casing has been transformed 
  into a decorative vase, engraved with flowers and the word "VERDUN."
  
  Such items served as both souvenirs and coping mechanisms for trauma. 
  They remain powerful reminders of the human experience amid industrial warfare.

image_url: "[Upload: trench_art.jpg]"
ai_knowledge_base: |
  18-pounder British artillery shell. Verdun was one of the war's longest 
  battles - 10 months, 700,000 casualties. Soldier identity unknown but 
  style suggests British or Canadian maker. Donated by soldier's grandson 
  in 1998. Trench art ranged from simple ashtrays to elaborate sculptures. 
  Created during long periods of waiting between attacks.
sort_order: 1
parent_id: "[Reference: Modern Era category ID]"
```

#### Item 5.2: Original Apple Macintosh (1984)
```yaml
name: "Original Apple Macintosh (1984)"
content: |
  **Origin:** Cupertino, California, USA  
  **Date:** January 1984  
  **Material:** Plastic housing, CRT monitor, electronics
  
  The Apple Macintosh introduced millions to personal computing with its 
  revolutionary graphical user interface and mouse. Steve Jobs' vision 
  of "a computer for the rest of us" transformed how humans interact 
  with technology.
  
  This unit is one of the first 1,000 produced, still in working condition.

image_url: "[Upload: macintosh_1984.jpg]"
ai_knowledge_base: |
  Serial number indicates production in January 1984, first month of 
  manufacture. Cost $2,495 - equivalent to about $7,500 today. 128KB RAM, 
  9-inch black & white screen. Came with MacWrite and MacPaint software. 
  The "1984" Super Bowl commercial is considered one of the greatest 
  ads ever made. Donated by the original owner in 2010.
sort_order: 2
parent_id: "[Reference: Modern Era category ID]"
```

---

## Notes for Implementation

1. **Category items** (parent_id: null) serve as section headers in grouped mode
2. **Sub-items** must reference their parent category's ID
3. Categories typically don't need images or long descriptions
4. **Sort order** determines both category order and item order within categories
5. AI knowledge on categories helps the assistant understand the broader context
6. Consider adding more items per category based on your collection

