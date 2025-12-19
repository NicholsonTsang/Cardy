# Fitness Studio - List Mode (Digital Access)

A boutique fitness studio guide showcasing classes, trainers, and membership options. List mode presents each offering clearly for easy browsing.

---

## Card Settings

```yaml
name: "Pulse Fitness Studio - Class Guide"
description: |
  **Move. Sweat. Transform.**
  
  Boutique fitness experiences designed to challenge and inspire.
  
  📍 456 Health Street, Suite 200
  ⏰ Mon-Fri 6 AM - 9 PM | Weekends 7 AM - 6 PM
  📞 (555) GETPULSE

content_mode: list
is_grouped: false
group_display: null
billing_type: digital
image_url: "[Upload: Studio interior or dynamic class shot]"

# AI Configuration
conversation_ai_enabled: true
ai_instruction: |
  You are an encouraging fitness advisor. Help clients choose 
  classes based on their goals, fitness level, and schedule. Be 
  motivating without being intimidating. Explain modifications 
  for beginners. Emphasize that all levels are welcome. Never 
  give specific medical advice.

ai_knowledge_base: |
  Pulse Fitness Studio - Boutique fitness
  Opened: 2019
  Location: Downtown, near Metro station
  
  Class types: HIIT, spin, yoga, barre, strength, boxing
  Class size: 15-20 per class
  Equipment: Peloton bikes, TRX, free weights, boxing bags
  
  Instructors: 12 certified trainers, various specialties
  
  Pricing:
  - Drop-in: $35/class
  - 10-pack: $280 ($28/class)
  - Monthly unlimited: $199
  - Annual: $149/month
  
  New client special: First class free
  Cancellation: 12 hours notice required
  
  Amenities: Showers, lockers (day use), towels, 
  water station, retail boutique
  
  App: Book classes, track progress, view schedule

ai_welcome_general: "Hey! Welcome to Pulse Fitness! I can recommend classes based on your goals or fitness level, explain what to expect as a beginner, share the schedule, or help you choose between different workout styles. What are you looking for?"
ai_welcome_item: "Our {name} class is great! I can explain the workout format, suggest what to bring, describe the intensity level, or let you know if it's good for beginners. What would help?"
```

---

## Content Items

### Hidden Category (Required for flat list)
```yaml
name: "Classes"
content: ""
image_url: null
ai_knowledge_base: ""
sort_order: 1
parent_id: null
```

#### HIIT Burn
```yaml
name: "HIIT Burn"
content: |
  **High-Intensity Interval Training**
  
  ⚡ 45 minutes | 500-700 calories
  
  Fast-paced circuits alternating intense bursts with active 
  recovery. Full-body workout using bodyweight, dumbbells, and 
  cardio equipment.
  
  ---
  
  🎯 **Benefits**
  - Maximum calorie burn
  - Improved cardio endurance
  - Build lean muscle
  - Afterburn effect (EPOC)
  
  👤 **Intensity:** ●●●●○
  
  📅 *Mon/Wed/Fri 6:30 AM, 12 PM, 6 PM*
  
  *All fitness levels welcome - modifications provided*

image_url: "[Upload: hiit_class.jpg]"
ai_knowledge_base: |
  Most popular class. Format: 45 seconds work, 15 seconds rest. 
  Three circuits, different exercises each. Instructors always 
  show low-impact modifications. Bring water - you'll sweat! 
  Heart rate monitors available for rent. Great for beginners 
  who want to push themselves with built-in rest periods.
sort_order: 1
parent_id: "[Reference: Classes]"
```

#### Power Spin
```yaml
name: "Power Spin"
content: |
  **Indoor Cycling**
  
  🚴 45 minutes | 400-600 calories
  
  Rhythm-based cycling to high-energy playlists. Hills, sprints, 
  and intervals set to the beat in a candlelit studio.
  
  ---
  
  🎯 **Benefits**
  - Low-impact cardio
  - Leg strength & endurance
  - Mental stress relief
  - Community energy
  
  👤 **Intensity:** ●●●○○ to ●●●●●
  
  📅 *Daily 7 AM, 9 AM, 5:30 PM, 7 PM*
  
  *First-timers: Arrive 10 min early for bike setup*

image_url: "[Upload: spin_class.jpg]"
ai_knowledge_base: |
  Peloton bikes with screens showing metrics. Resistance is 
  yours to control - go at your own pace. Candlelit for vibe, 
  not pitch dark. Clip-in shoes available (free) or wear 
  sneakers. Water and towel essential. 7 PM classes most popular 
  - book 2+ days ahead. Gentle on joints, great for runners 
  recovering from injury.
sort_order: 2
parent_id: "[Reference: Classes]"
```

#### Vinyasa Flow
```yaml
name: "Vinyasa Flow"
content: |
  **Yoga**
  
  🧘 60 minutes | Mind-body connection
  
  Breath-linked movement through dynamic sequences. Build 
  strength, flexibility, and mindfulness in our heated studio.
  
  ---
  
  🎯 **Benefits**
  - Improved flexibility
  - Core strength
  - Stress reduction
  - Better posture
  
  👤 **Intensity:** ●●○○○ to ●●●○○
  
  🌡 *Heated to 80°F*
  
  📅 *Daily 8 AM, 12 PM, 7:30 PM*
  
  *Mats and props provided*

image_url: "[Upload: yoga_class.jpg]"
ai_knowledge_base: |
  Not hot yoga (80°F, not 105°F) - warm enough to loosen muscles 
  without extreme heat. All levels in same class - instructor 
  offers variations. Beginners start in front to see better. 
  Props encouraged, not a crutch. Sunday 8 AM is especially 
  peaceful. Great complement to high-intensity classes.
sort_order: 3
parent_id: "[Reference: Classes]"
```

#### Boxing Bootcamp
```yaml
name: "Boxing Bootcamp"
content: |
  **Boxing + Strength**
  
  🥊 50 minutes | 600-800 calories
  
  Learn boxing fundamentals while getting a killer workout. 
  Heavy bag rounds combined with strength circuits.
  
  ---
  
  🎯 **Benefits**
  - Full-body strength
  - Stress release
  - Coordination
  - Self-defense basics
  
  👤 **Intensity:** ●●●●○
  
  📅 *Tue/Thu 6 AM, 5:30 PM | Sat 10 AM*
  
  *Gloves provided - wraps available for purchase*

image_url: "[Upload: boxing_class.jpg]"
ai_knowledge_base: |
  No boxing experience needed - all combos taught from basics. 
  Format: warm-up, technique drill, 6 rounds of bag work with 
  strength exercises between. Huge stress reliever - clients 
  love it after tough work days. Wraps ($15) keep gloves 
  hygienic and wrists protected. Saturday class is most social.
sort_order: 4
parent_id: "[Reference: Classes]"
```

#### Barre Sculpt
```yaml
name: "Barre Sculpt"
content: |
  **Ballet-Inspired Toning**
  
  💃 55 minutes | Lean muscle definition
  
  Low-impact, high-rep movements at the ballet barre. Sculpt 
  long, lean muscles using small, controlled movements.
  
  ---
  
  🎯 **Benefits**
  - Muscle definition
  - Improved posture
  - Core stability
  - Flexibility
  
  👤 **Intensity:** ●●○○○
  
  📅 *Mon/Wed/Fri 9:30 AM | Tue/Thu 7 PM*
  
  *Sticky socks required (available for purchase $12)*

image_url: "[Upload: barre_class.jpg]"
ai_knowledge_base: |
  No dance experience needed. Small isometric movements = 
  muscle fatigue = results. "The shake" is normal and means 
  it's working. Lower impact on joints than jumping exercises. 
  Great for rehab from injury. Sticky socks grip the floor - 
  required for safety. Complements other workouts by targeting 
  smaller stabilizer muscles.
sort_order: 5
parent_id: "[Reference: Classes]"
```

#### Strength Lab
```yaml
name: "Strength Lab"
content: |
  **Weight Training**
  
  🏋️ 50 minutes | Build strength
  
  Structured strength training with barbells, dumbbells, and 
  kettlebells. Learn proper form while building functional 
  strength.
  
  ---
  
  🎯 **Benefits**
  - Build muscle
  - Boost metabolism
  - Bone density
  - Functional movement
  
  👤 **Intensity:** ●●●○○ to ●●●●●
  
  📅 *Mon/Wed/Fri 5:30 PM | Sat/Sun 8 AM*
  
  *Small groups (max 12) for personalized coaching*

image_url: "[Upload: strength_class.jpg]"
ai_knowledge_base: |
  Structured like personal training but in group setting. 
  Coach demonstrates every lift, corrects form individually. 
  Progressive program - weights increase over time. Beginners 
  start with lighter weights, focus on form. Great for women 
  intimidated by weight rooms - supportive environment. Track 
  your lifts in our app.
sort_order: 6
parent_id: "[Reference: Classes]"
```

#### Recovery & Stretch
```yaml
name: "Recovery & Stretch"
content: |
  **Active Recovery**
  
  🧘‍♀️ 45 minutes | Restore & recover
  
  Gentle stretching, foam rolling, and mobility work. Essential 
  for preventing injury and improving performance.
  
  ---
  
  🎯 **Benefits**
  - Muscle recovery
  - Injury prevention
  - Improved mobility
  - Relaxation
  
  👤 **Intensity:** ●○○○○
  
  📅 *Sun 11 AM, 4 PM | Wed 8 PM*
  
  *Foam rollers and massage balls provided*

image_url: "[Upload: recovery_class.jpg]"
ai_knowledge_base: |
  Often overlooked but crucial class. Targets fascia and tight 
  muscles from intense workouts. Foam rolling can be 
  uncomfortable on tight spots - that's normal. Great after 
  leg day or long run. Wednesday night slot perfect for mid-week 
  reset. Therapist designed the sequences. Free for unlimited 
  members.
sort_order: 7
parent_id: "[Reference: Classes]"
```

---

## Notes for Implementation

1. **List Mode** presents class offerings cleanly
2. **Digital Access** works for studio tablets, website, or new member guides
3. Include **duration, calories, schedule** consistently
4. AI knowledge should cover class expectations and beginner tips
5. Use intensity ratings for quick reference
6. Update schedules seasonally
7. Consider adding trainer bios as separate grouped section


