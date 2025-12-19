# Car Dealership - Grid Mode (Digital Access)

An automotive showroom guide featuring vehicle inventory, specifications, and services. Grid mode presents vehicles visually for easy comparison.

---

## Card Settings

```yaml
name: "Premier Motors - Vehicle Showcase"
description: |
  **Drive Excellence**
  
  Your authorized luxury automotive destination.
  New, certified pre-owned, and service.
  
  📍 500 Auto Drive, Motor Mile
  ⏰ Mon-Sat 9 AM - 8 PM | Sun 11 AM - 5 PM
  📞 (555) PREMIER

content_mode: grid
is_grouped: false
group_display: null
billing_type: digital
image_url: "[Upload: Showroom exterior or featured vehicle]"

# AI Configuration
conversation_ai_enabled: true
ai_instruction: |
  You are a knowledgeable automotive advisor. Help customers 
  understand vehicle features, compare models, and explore 
  financing options. Be helpful without being pushy. Provide 
  honest assessments of vehicle capabilities. Acknowledge 
  that test drives are the best way to decide. Direct complex 
  questions to sales consultants.

ai_knowledge_base: |
  Premier Motors - Authorized luxury dealership
  Brands: Full luxury lineup
  Established: 1985, family-owned
  
  Inventory: 150+ new, 75+ certified pre-owned
  
  Services offered:
  - New vehicle sales
  - Certified pre-owned
  - Trade-in appraisals
  - Financing & leasing
  - Factory service center
  - Parts department
  
  Business hours:
  - Sales: Mon-Sat 9 AM - 8 PM, Sun 11 AM - 5 PM
  - Service: Mon-Fri 7 AM - 6 PM, Sat 8 AM - 3 PM
  
  Financing partners: Major banks, manufacturer financing
  Special programs: First-time buyer, loyalty, conquest
  
  Test drives: Walk-in welcome, appointments preferred
  Home delivery available

ai_welcome_general: "Welcome to Premier Motors! I can compare models, explain features and specs, discuss financing options, share trade-in info, or help you find a vehicle that fits your needs. What are you looking for?"
ai_welcome_item: "The {name} is excellent! I can detail the specs, compare it to competitors, explain pricing and packages, or discuss test drive options. What would you like to know?"
```

---

## Content Items

### Hidden Category (Required for flat grid)
```yaml
name: "Vehicles"
content: ""
image_url: null
ai_knowledge_base: ""
sort_order: 1
parent_id: null
```

#### 2025 Executive Sedan
```yaml
name: "2025 Executive Sedan"
content: |
  **Refined Performance**
  
  💰 Starting at $52,900
  
  The benchmark in luxury sedans. Effortless power, 
  advanced technology, and handcrafted comfort for 
  every journey.
  
  ---
  
  🔧 **Specifications**
  - 2.0L Turbo | 255 HP
  - 8-speed automatic
  - AWD available
  - 28 city / 36 highway MPG
  
  ⭐ **Highlights**
  - 12.3" digital cockpit
  - Panoramic moonroof
  - Heated leather seats
  - Driver assistance suite
  
  *5 in stock | 12 colors available*

image_url: "[Upload: executive_sedan.jpg]"
ai_knowledge_base: |
  Best-selling model for professionals. Competitor to BMW 3, 
  Mercedes C-Class. Available in base, Premium, and Sport 
  trims. Premium ($58K) adds 360 camera, premium audio. 
  Sport ($62K) adds adaptive suspension, sport exhaust. 
  AWD adds $2,500. Popular lease: $599/month, 36 months, 
  $4,000 due at signing. Test drive tip: try highway merge.
sort_order: 1
parent_id: "[Reference: Vehicles]"
```

#### 2025 Sport SUV
```yaml
name: "2025 Sport SUV"
content: |
  **Versatile Adventure**
  
  💰 Starting at $48,500
  
  Compact luxury SUV with bold styling and agile handling. 
  Premium comfort meets everyday practicality.
  
  ---
  
  🔧 **Specifications**
  - 2.0L Turbo | 248 HP
  - AWD standard
  - 25 city / 32 highway MPG
  - Towing: 3,500 lbs
  
  ⭐ **Highlights**
  - Hands-free liftgate
  - Wireless CarPlay/Android
  - Adaptive cruise control
  - 40/20/40 rear seats
  
  *8 in stock | Test drives available*

image_url: "[Upload: sport_suv.jpg]"
ai_knowledge_base: |
  Fastest growing segment. Competes with BMW X1, Audi Q3, 
  Lexus NX. Standard AWD is differentiator vs competitors. 
  Popular with young professionals and small families. Cargo: 
  25 cu ft behind rear seats, 54 cu ft seats folded. Available 
  tow package ($750) for light trailers. Most popular color: 
  white, followed by black. Best value in lineup.
sort_order: 2
parent_id: "[Reference: Vehicles]"
```

#### 2025 Grand Touring SUV
```yaml
name: "2025 Grand Touring SUV"
content: |
  **Commanding Presence**
  
  💰 Starting at $72,900
  
  Full-size luxury SUV with three-row seating and 
  uncompromising capability. First-class comfort for 
  the entire family.
  
  ---
  
  🔧 **Specifications**
  - 3.0L Twin-Turbo V6 | 375 HP
  - AWD standard
  - 19 city / 25 highway MPG
  - Towing: 7,500 lbs
  
  ⭐ **Highlights**
  - Seating for 7
  - Air suspension
  - Executive rear seats
  - Premium 19-speaker audio
  
  *3 in stock | Factory orders welcome*

image_url: "[Upload: grand_touring_suv.jpg]"
ai_knowledge_base: |
  Flagship SUV. Competes with BMW X7, Mercedes GLS, Range Rover. 
  Third row actually usable for adults. Executive rear seats 
  ($3,500) add captain's chairs with massage. Air suspension 
  adjusts ride height - raises for off-road, lowers for entry. 
  Tow package standard. Popular with families, executives. 
  Factory orders 8-10 weeks. Residual value strong - 58% at 
  36 months.
sort_order: 3
parent_id: "[Reference: Vehicles]"
```

#### 2025 Performance Coupe
```yaml
name: "2025 Performance Coupe"
content: |
  **Pure Driving Thrill**
  
  💰 Starting at $67,500
  
  Two-door sports car engineered for driving enthusiasts. 
  Race-inspired performance meets everyday usability.
  
  ---
  
  🔧 **Specifications**
  - 3.0L Twin-Turbo | 385 HP
  - 0-60: 4.2 seconds
  - RWD (AWD available)
  - Sport exhaust standard
  
  ⭐ **Highlights**
  - Adaptive sport suspension
  - Launch control
  - Carbon fiber trim
  - Sport bucket seats
  
  *2 in stock | Limited availability*

image_url: "[Upload: performance_coupe.jpg]"
ai_knowledge_base: |
  For driving enthusiasts. RWD is purer driving experience, 
  AWD adds $3,000 and better launch times (3.9s 0-60). 
  Available track package ($5,500) adds ceramic brakes, 
  limited-slip diff. Surprisingly practical - usable back 
  seat for short trips. Popular as second car. Manual 
  transmission no longer available. Exhaust has active 
  valves - quiet in comfort mode, loud in sport.
sort_order: 4
parent_id: "[Reference: Vehicles]"
```

#### 2025 Electric SUV
```yaml
name: "2025 Electric SUV"
content: |
  **Zero Emissions Luxury**
  
  💰 Starting at $79,900
  
  All-electric performance SUV with instant torque and 
  cutting-edge technology. The future of driving, today.
  
  ---
  
  🔧 **Specifications**
  - Dual motor AWD | 516 HP
  - 0-60: 3.8 seconds
  - Range: 320 miles (EPA)
  - DC fast charging: 10-80% in 25 min
  
  ⭐ **Highlights**
  - Glass panoramic roof
  - Over-the-air updates
  - Augmented reality nav
  - Intelligent regeneration
  
  *Available for order | $2,500 deposit*

image_url: "[Upload: electric_suv.jpg]"
ai_knowledge_base: |
  First full EV in lineup. Eligible for $7,500 federal tax 
  credit (verify eligibility). Home charging: Level 2 adds 
  ~30 miles/hour. DC fast charging at 800+ locations 
  nationally. Range in winter drops ~15-20%. Maintenance 
  costs 40% lower than gas - no oil changes. Performance 
  mode unlocks full 516 HP. Over-the-air updates add features 
  over time. Most advanced tech in our lineup.
sort_order: 5
parent_id: "[Reference: Vehicles]"
```

#### Certified Pre-Owned
```yaml
name: "Certified Pre-Owned"
content: |
  **Premium Value**
  
  💰 Starting at $32,900
  
  Factory-certified vehicles with extended warranty 
  and confidence. Every CPO vehicle passes 200+ point 
  inspection.
  
  ---
  
  ✓ **CPO Benefits**
  - 2-year unlimited mile warranty
  - 24/7 roadside assistance
  - Vehicle history report
  - Exchange privilege (7 days)
  - Special financing rates
  
  📊 **Current Inventory**
  - Sedans: 22 available
  - SUVs: 35 available
  - Coupes: 8 available
  
  *New arrivals weekly*

image_url: "[Upload: cpo_lineup.jpg]"
ai_knowledge_base: |
  Best value proposition. CPO cars typically 3-4 years old, 
  under 50,000 miles. Warranty better than most new car 
  warranties. Financing rates typically 0.5-1% higher than 
  new. Popular models sell fast - check inventory often. 
  Exchange privilege lets you return within 7 days if not 
  satisfied. Recent lease returns in excellent condition. 
  Ask about specific models - can search regional inventory.
sort_order: 6
parent_id: "[Reference: Vehicles]"
```

#### Service Center
```yaml
name: "Service Center"
content: |
  **Factory-Trained Care**
  
  Our technicians know your vehicle inside and out. 
  Genuine parts, advanced diagnostics, and transparent 
  pricing.
  
  ---
  
  🔧 **Services**
  - Maintenance (oil, tires, brakes)
  - Warranty repairs
  - Recall service
  - Performance upgrades
  - Collision repair
  
  ⏰ **Hours**
  Mon-Fri 7 AM - 6 PM
  Saturday 8 AM - 3 PM
  
  🚗 **Amenities**
  - Complimentary loaner cars
  - Wi-Fi lounge
  - Shuttle service
  - Express service lane
  
  📞 **Schedule: (555) SERVICE**

image_url: "[Upload: service_center.jpg]"
ai_knowledge_base: |
  Factory-trained technicians only. Loaner cars for service 
  over 2 hours - same brand vehicles. Express lane for oil 
  changes and simple maintenance (no appointment, under 1 hour). 
  Price match guarantee on tires. First maintenance visit 
  complimentary for new car purchases. Shuttle runs to downtown 
  and mall. Customer lounge has coffee, snacks, work stations.
sort_order: 7
parent_id: "[Reference: Vehicles]"
```

---

## Notes for Implementation

1. **Grid Mode** showcases vehicles visually for easy comparison
2. **Digital Access** works for showroom tablets and customer browsing
3. Include **pricing, specs, availability** consistently
4. AI knowledge should cover honest comparisons and buying advice
5. Update inventory counts regularly
6. Professional photography essential for vehicle appeal
7. Consider adding financing calculator or trade-in section


