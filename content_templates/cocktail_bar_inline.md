# Cocktail Bar - Grouped Cards Mode (Digital Access)

A craft cocktail menu organized by spirit type. Perfect for bars, restaurants, and speakeasies that want to showcase their cocktail program with rich descriptions and beautiful imagery.

---

## Card Settings

```yaml
name: "The Velvet Room - Cocktail Menu"
description: |
  **Craft cocktails. Timeless classics. New discoveries.**
  
  Our bartenders blend artistry with tradition, creating drinks that 
  honor the classics while pushing boundaries. Every cocktail tells a story.
  
  🥃 Ask your bartender for recommendations based on your mood.

content_mode: cards
is_grouped: true
group_display: expanded
billing_type: digital
daily_scan_limit: 1000

# AI Configuration
conversation_ai_enabled: true
ai_instruction: |
  You are a knowledgeable craft bartender with a warm, inviting personality. 
  Help guests find their perfect drink based on flavor preferences 
  (sweet, sour, bitter, spirit-forward), mood, or occasion. 
  Share cocktail history and stories. Be enthusiastic but not pretentious.

ai_knowledge_base: |
  The Velvet Room - Craft Cocktail Bar
  Est. 2018 · Named "Best Bar" by City Magazine 2023
  
  Head Bartender: James Monroe (15 years experience)
  Bar philosophy: Classic techniques, quality ingredients, personal touch
  Ice program: All ice cut in-house from 300lb blocks
  Spirits: 400+ bottles, emphasis on small-batch and craft
  
  Non-alcoholic options: Full "Zero Proof" menu available
  Happy hour: 5-7pm, $10 classic cocktails
  Reservations: Recommended for groups of 4+

ai_welcome_general: "Welcome to The Velvet Room! I can recommend drinks based on your taste (sweet, sour, strong), explain any cocktail's ingredients, suggest food pairings, or share the story behind our signatures. What's your mood tonight?"
ai_welcome_item: "The \"{name}\" is excellent! I can describe the flavor profile, list ingredients, suggest similar drinks, or share the cocktail's history. What would you like to know?"
```

---

## Categories (Layer 1)

### ⭐ House Signatures
Our bartender's original creations. Each tells a story and showcases our house style.

### 🥃 Whiskey & Bourbon
Spirit-forward classics and twists. Over 100 bottles from American bourbon to Japanese whisky.

### 🌿 Gin Cocktails
Botanical and refreshing options. Range from bright and citrusy to herbaceous and complex.

### 🌵 Agave Spirits
Tequila and mezcal selections celebrating Mexico's finest spirits.

### 🏝️ Rum & Tropical
Island-inspired refreshers. From light and tropical to dark and complex.

---

## Content Items (Layer 2)

### Category: House Signatures

#### The Velvet Old Fashioned

**Our signature take on the timeless classic**

*Woodford Reserve bourbon · demerara · house bitters · orange oil*

We start with a base of Woodford Reserve, add house-made demerara syrup and our proprietary blend of aromatic bitters, then express orange oil over a single hand-cut ice sphere.

---

🥃 **Spirit:** Bourbon
📊 **Strength:** Strong
🍬 **Profile:** Spirit-forward, subtly sweet, aromatic
💰 **$16**

---

#### Smoke & Mirrors

**A theatrical experience for mezcal lovers**

*Del Maguey Vida mezcal · Aperol · lime · agave · chipotle*

Our most dramatic cocktail: smoky mezcal meets bitter Aperol, brightened with lime. A whisper of chipotle tincture adds warmth without heat.

Served under a glass cloche filled with applewood smoke—lifted tableside.

---

🥃 **Spirit:** Mezcal
📊 **Strength:** Medium-Strong
🍬 **Profile:** Smoky, bitter-sweet, complex
💰 **$18**

---

### Category: Whiskey & Bourbon

#### Tokyo Sour

**East meets West in a glass**

*Suntory Toki · yuzu · egg white · shiso · matcha dust*

A Japanese-inspired whisky sour featuring fresh yuzu juice, silky egg white foam, and aromatic shiso leaf.

---

🥃 **Spirit:** Japanese Whisky
📊 **Strength:** Medium
🍬 **Profile:** Citrus-forward, creamy, aromatic
💰 **$17**
🌿 *Can be made vegan with aquafaba*

---

### Category: Gin Cocktails

#### Garden Party

**Summer in a glass, any time of year**

*Hendrick's gin · elderflower · cucumber · lemon · prosecco*

A spritz-style cocktail that's light, floral, and impossibly refreshing.

---

🥃 **Spirit:** Gin
📊 **Strength:** Light
🍬 **Profile:** Floral, refreshing, effervescent
💰 **$15**

---

## Notes

- **Cards layout**: Rich, full-width cards perfect for cocktail descriptions
- **Grouped by spirit**: Helps guests navigate by preference
- **AI as bartender**: Personal recommendations based on mood and taste
- **Images recommended**: Beautiful cocktail photography enhances the experience
