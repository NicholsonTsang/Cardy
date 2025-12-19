# Hotel - List Mode (Digital Access)

A hotel guest services directory using simple list mode. Perfect for in-room QR codes allowing guests to quickly access information about hotel amenities, dining, and services.

---

## Card Settings

```yaml
name: "Grand Plaza Hotel - Guest Services"
description: |
  Welcome to **Grand Plaza Hotel** ⭐⭐⭐⭐⭐
  
  Your complete guide to hotel services and amenities.
  
  📞 Front Desk: Dial 0 · 🛎️ Concierge: Dial 1

content_mode: list
is_grouped: true
group_display: expanded
billing_type: digital
image_url: null  # Digital access

# Optional: daily_scan_limit
daily_scan_limit: 2000  # High limit for hotel guests

# AI Configuration
conversation_ai_enabled: true
ai_instruction: |
  You are a helpful hotel concierge. Assist guests with any questions 
  about hotel services, local recommendations, or general inquiries. 
  Be warm, professional, and anticipate guest needs. For urgent matters, 
  always direct guests to call the front desk.

ai_knowledge_base: |
  Grand Plaza Hotel - 5-star luxury hotel
  Address: 100 Plaza Avenue, Downtown
  Built: 1925, renovated 2022
  Rooms: 450 rooms and suites across 25 floors
  
  Check-in: 3:00 PM · Check-out: 11:00 AM
  Late checkout available (fee may apply)
  
  Concierge desk: 24 hours, can arrange anything
  Valet parking: $45/night, self-park $30/night
  
  Pet policy: Dogs under 25 lbs welcome, $75 fee per stay
  Smoking: Non-smoking property, designated outdoor areas

ai_welcome_general: "Welcome to Grand Plaza Hotel! I can help with room service, restaurant reservations, spa bookings, local recommendations, or any hotel amenity. What do you need?"
ai_welcome_item: "For {name}, I can share hours, pricing, how to book, what's included, or answer specific questions. How can I help?"
```

---

## Content Items (Services List)

### Item 1: Room Service
```yaml
name: "Room Service"
content: |
  **24-Hour In-Room Dining**
  
  📞 **Dial 4** from your room phone
  
  Enjoy breakfast, lunch, dinner, or late-night snacks delivered 
  directly to your room.
  
  **Hours:** 24 hours (limited menu midnight-6am)
  
  **Delivery Time:** 30-45 minutes
  
  **Tray Pickup:** Place tray outside door or call for pickup
  
  ---
  
  **Popular Items:**
  - Continental Breakfast: $28
  - Club Sandwich: $24
  - Caesar Salad: $18
  - Wagyu Burger: $42
  - Kids Menu: $15
  
  *Full menu in your room's tablet or call for paper menu*

image_url: "[Upload: room_service_icon.jpg or leave empty]"
ai_knowledge_base: |
  Room service uses restaurant kitchens. Executive Chef Marco prepares 
  all items fresh. 20% service charge automatically added. Special 
  dietary requests accommodated with advance notice. Champagne and 
  wine available. Birthday cakes can be ordered with 24hr notice.
sort_order: 1
```

### Item 2: Restaurant & Bar
```yaml
name: "The Grand Restaurant"
content: |
  **Fine Dining Experience**
  
  📍 **Location:** Lobby Level
  
  **Hours:**
  - Breakfast: 6:30 AM - 10:30 AM
  - Lunch: 12:00 PM - 2:30 PM
  - Dinner: 6:00 PM - 10:30 PM
  
  **Dress Code:** Smart casual (no shorts/flip-flops at dinner)
  
  **Reservations:** Dial 2 or speak to concierge
  
  ---
  
  **The Plaza Bar**
  
  📍 Adjacent to restaurant
  
  **Hours:** 4:00 PM - 1:00 AM
  
  Live jazz Thursday-Saturday, 8-11 PM

image_url: "[Upload: restaurant_icon.jpg]"
ai_knowledge_base: |
  Executive Chef Marco Bellini - 2 Michelin stars. Restaurant seats 120. 
  Private dining room available for up to 20 guests. Vegetarian and 
  vegan tasting menus available. Wine list curated by sommelier Anna 
  Chen - 800 labels. Happy hour 4-7pm with $15 cocktails. 
  Hotel guests receive 10% discount.
sort_order: 2
```

### Item 3: Spa & Wellness
```yaml
name: "Spa & Wellness Center"
content: |
  **Relax and Rejuvenate**
  
  📍 **Location:** 4th Floor
  
  📞 **Reservations:** Dial 5
  
  **Hours:** 7:00 AM - 9:00 PM daily
  
  ---
  
  **Services:**
  - Swedish Massage (60 min): $180
  - Deep Tissue Massage (60 min): $200
  - Aromatherapy Facial (75 min): $165
  - Body Scrub & Wrap (90 min): $220
  - Couples Massage (60 min): $350
  
  **Facilities (complimentary for hotel guests):**
  - Heated indoor pool
  - Jacuzzi and steam room
  - Sauna (dry and wet)
  - Relaxation lounge
  
  *Advance booking recommended, especially weekends*

image_url: "[Upload: spa_icon.jpg]"
ai_knowledge_base: |
  Spa has 8 treatment rooms including couples suite. Pool is 25m 
  lap pool, heated to 82°F. Steam room infused with eucalyptus. 
  Spa director is certified aromatherapist. Hotel guests can use 
  facilities free; day passes available for non-guests ($50). 
  Robes and slippers provided. Gratuity not included in prices.
sort_order: 3
```

### Item 4: Fitness Center
```yaml
name: "Fitness Center"
content: |
  **24-Hour Gym Access**
  
  📍 **Location:** 4th Floor (adjacent to Spa)
  
  **Hours:** Open 24/7
  
  **Access:** Use your room key card
  
  ---
  
  **Equipment:**
  - Cardio machines (treadmills, bikes, ellipticals)
  - Free weights (up to 100 lbs)
  - Weight machines
  - Yoga mats and props
  - Stretching area
  
  **Complimentary:**
  - Towels and water
  - Fitness classes (schedule at concierge)
  - Personal trainer consultation
  
  *Gym wear and athletic shoes required*

image_url: "[Upload: gym_icon.jpg]"
ai_knowledge_base: |
  Gym equipped with Technogym equipment. Morning yoga classes 
  7am weekdays (free for guests). Personal training $100/hour, 
  book 24hr in advance. Running maps of local routes available 
  at front desk. Lockers available, bring your own lock or 
  purchase at front desk ($10).
sort_order: 4
```

### Item 5: Concierge Services
```yaml
name: "Concierge Services"
content: |
  **Your Personal Assistant**
  
  📍 **Location:** Lobby
  
  📞 **Dial 1** or visit in person
  
  **Hours:** 24 hours
  
  ---
  
  **We can arrange:**
  - Restaurant reservations
  - Theater and event tickets
  - Airport transfers
  - Car rentals
  - Tours and activities
  - Flowers and gifts
  - Babysitting services
  - Dry cleaning and laundry
  - Business services
  
  **Local Expertise:**
  Our concierge team knows the city inside out. Let us create 
  a personalized itinerary for your stay.
  
  *No request is too big or too small*

image_url: "[Upload: concierge_icon.jpg]"
ai_knowledge_base: |
  Head Concierge: Michelle Torres, Les Clefs d'Or member (golden keys - 
  elite concierge organization). Team of 6 multilingual concierges. 
  Can get reservations at fully-booked restaurants. Theater tickets 
  usually available same-day. Airport transfer in Mercedes sedan $85, 
  SUV $120. 24hr turnaround on dry cleaning.
sort_order: 5
```

### Item 6: Business Center
```yaml
name: "Business Center"
content: |
  **Work Away From Home**
  
  📍 **Location:** Mezzanine Level
  
  📞 **Dial 6** for assistance
  
  **Hours:** 6:00 AM - 10:00 PM (after hours access with room key)
  
  ---
  
  **Complimentary Services:**
  - High-speed WiFi
  - Computer workstations (Mac & PC)
  - Printing (first 20 pages free)
  - Scanning and faxing
  - Phone charging stations
  
  **Paid Services:**
  - Printing over 20 pages: $0.25/page
  - Binding and laminating
  - Courier services
  - Notary (by appointment)
  
  **Meeting Rooms:**
  Available for rent - see Meetings & Events

image_url: "[Upload: business_icon.jpg]"
ai_knowledge_base: |
  Business center has 6 private workstations with dividers. 
  Complimentary coffee and tea. Secretarial services available 
  $50/hour. International calling cards at front desk. 
  Printer is color laser, accepts USB drives. WiFi password 
  is room number + last name (case sensitive).
sort_order: 6
```

### Item 7: Meetings & Events
```yaml
name: "Meetings & Events"
content: |
  **Professional Event Spaces**
  
  📞 **Events Team:** Dial 7
  
  📧 **events@grandplaza.com**
  
  ---
  
  **Venues:**
  
  | Room | Capacity | Size |
  |------|----------|------|
  | Grand Ballroom | 500 | 8,000 sq ft |
  | Plaza Room | 150 | 2,500 sq ft |
  | Boardroom A | 20 | 600 sq ft |
  | Boardroom B | 12 | 400 sq ft |
  | Executive Suite | 8 | 300 sq ft |
  
  **Services:**
  - A/V equipment and technician
  - Catering and bar service
  - Event planning assistance
  - Breakout rooms
  
  *Request a proposal for your next event*

image_url: "[Upload: events_icon.jpg]"
ai_knowledge_base: |
  Events Director: Sarah Chen. Grand Ballroom perfect for weddings 
  (up to 250 seated dinner). Corporate rate: 20% off for 10+ room 
  nights. Packages include AV, WiFi, coffee breaks. Popular for 
  conferences and product launches. Rooftop terrace available 
  for cocktail events (weather permitting, max 100 guests).
sort_order: 7
```

### Item 8: Housekeeping
```yaml
name: "Housekeeping"
content: |
  **Keeping Your Room Perfect**
  
  📞 **Dial 8** for any housekeeping needs
  
  **Daily Service:** 9:00 AM - 4:00 PM
  
  ---
  
  **Request:**
  - Extra towels or pillows
  - Additional toiletries
  - Iron and ironing board
  - Crib or rollaway bed
  - Room refresh
  
  **Green Program:**
  Hang your towels to reuse them. Place the green card on your 
  bed if you don't need sheets changed.
  
  *Help us reduce our environmental impact*
  
  **Do Not Disturb:**
  Use the sign or press the button by your door

image_url: "[Upload: housekeeping_icon.jpg]"
ai_knowledge_base: |
  Housekeeping manager: Rosa Martinez. Team of 50 housekeepers. 
  Turndown service available 6-9pm on request. Hypoallergenic 
  pillows and bedding available. Baby amenities (crib, bottle 
  warmer, baby bath) free of charge. Lost items held for 90 days. 
  Laundry returned same day if submitted by 9am.
sort_order: 8
```

### Item 9: WiFi & Technology
```yaml
name: "WiFi & Technology"
content: |
  **Stay Connected**
  
  **WiFi Network:** GrandPlaza_Guest
  
  **Password:** Your room number + last name
  *(Example: 1234Smith)*
  
  ---
  
  **In-Room Technology:**
  - Smart TV with streaming apps
  - USB charging ports (bedside and desk)
  - Bluetooth speaker (ask housekeeping)
  - Universal power adapters (at front desk)
  
  **Troubleshooting:**
  📞 **Dial 0** for technical support (24 hours)
  
  **Tip:** For fastest speeds, connect to the 5GHz network 
  (GrandPlaza_Guest_5G)

image_url: "[Upload: wifi_icon.jpg]"
ai_knowledge_base: |
  WiFi speed: 100 Mbps throughout property. Premium WiFi available 
  for high-bandwidth needs ($15/day, 500 Mbps). Smart TV has Netflix, 
  Prime, Disney+ - sign in with your accounts. Chromecast in all 
  rooms for screen mirroring. IT support can assist with video 
  conferencing setup.
sort_order: 9
```

### Item 10: Transportation
```yaml
name: "Transportation"
content: |
  **Getting Around**
  
  📞 **Valet:** Dial 9
  
  ---
  
  **Parking:**
  - Valet: $45/night (in and out privileges)
  - Self-park: $30/night (garage level P2)
  - Electric charging: 4 stations available
  
  **Airport Transfers:**
  - Sedan: $85 one-way
  - SUV: $120 one-way
  - Book through concierge (Dial 1)
  
  **Car Rental:**
  Hertz desk in lobby, 7am-7pm daily
  
  **Rideshare:**
  Pickup zone at East entrance
  
  **Public Transit:**
  Metro station 2 blocks north (Plaza Station)

image_url: "[Upload: transport_icon.jpg]"
ai_knowledge_base: |
  Valet uses secure underground garage. Airport is 25 minutes in 
  normal traffic, allow 45 minutes during rush hour. Hertz offers 
  hotel guest discount (code: GRANDPLAZA). Bike rentals available 
  through concierge - city bike share station across street. 
  Private driver available for hourly hire ($75/hour, 4hr minimum).
sort_order: 10
```

### Item 11: Local Attractions
```yaml
name: "Local Attractions"
content: |
  **Explore the City**
  
  *Ask our concierge to book tours or tickets*
  
  ---
  
  **Walking Distance (< 15 min):**
  - City Museum - 5 min
  - Central Park - 8 min
  - Theater District - 10 min
  - Shopping Mall - 12 min
  
  **Worth the Trip:**
  - Art Gallery - 20 min by taxi
  - Historic District - 25 min by metro
  - Beach - 40 min by car
  - Wine Country - 1 hour by car
  
  **Hotel Tours:**
  - City Walking Tour: Daily 10am ($35)
  - Food Tour: Sat/Sun 2pm ($75)
  - Wine Tasting: Fri 4pm ($95)
  
  *Book through concierge*

image_url: "[Upload: attractions_icon.jpg]"
ai_knowledge_base: |
  Top restaurant recommendations: La Maison (French, $$$), 
  Sake House (Japanese, $$), Taco Loco (Mexican, $). Best brunch: 
  Sunny Side Café (15 min walk). Museum free on Thursdays after 5pm. 
  Central Park has free summer concerts. Hotel has partnership with 
  Broadway - can often get last-minute tickets.
sort_order: 11
```

### Item 12: Emergency Information
```yaml
name: "Emergency Information"
content: |
  **Safety First**
  
  🚨 **Emergency:** Dial 911
  
  🏥 **Hotel Security:** Dial 0 (24 hours)
  
  ---
  
  **Fire Safety:**
  - Fire exits marked on back of room door
  - Do not use elevators during fire
  - Meet at designated assembly point (front of hotel)
  
  **Medical:**
  - First aid available at front desk
  - Nearest hospital: City General (10 min by car)
  - 24-hour pharmacy: CVS, 2 blocks east
  
  **Lost & Found:**
  - Items found in hotel: Front desk
  - Items left after checkout: Call (555) 123-4567
  
  **Safe Deposit:**
  In-room safe included. Front desk safe for valuables.

image_url: "[Upload: emergency_icon.jpg]"
ai_knowledge_base: |
  Hotel has full sprinkler system and smoke detectors in all rooms. 
  AED machines on every floor. Security team includes former police 
  officers. Doctor on call 24 hours (house call $150). Wheelchair 
  accessible throughout. Service animals welcome. In-room safes 
  hold standard laptop size.
sort_order: 12
```

---

## Notes for Implementation

1. **List mode** provides quick access to all services
2. **Digital Access** is perfect for hotel rooms - QR code in room directory
3. Simple icons work better than photos for list mode
4. Each service has AI knowledge for detailed questions
5. Include **dial codes** for easy phone access
6. **Sort order** should prioritize most-requested services
7. Update seasonally for special promotions or seasonal offerings
8. Consider multiple QR codes: bedside, bathroom mirror, desk

