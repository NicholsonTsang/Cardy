# Football Match - Single Mode (Digital Access)

A single-page event guide for a football (soccer) match. Single mode presents all information on one comprehensive page—perfect for events, concerts, or any single-topic content.

---

## Card Settings

```yaml
name: "Match Day Guide - City FC vs United"
description: |
  🏟️ **Welcome to City Stadium!**
  
  Your complete guide for today's Premier League clash.
  
  Tap below for kickoff time, team lineups, stadium map, and more.

content_mode: single
is_grouped: false
group_display: expanded
billing_type: digital
image_url: "[Upload: Stadium photo or match poster]"

# AI Configuration
conversation_ai_enabled: true
ai_instruction: |
  You are an enthusiastic football fan and stadium guide. Help visitors 
  with directions, match information, and general stadium questions. 
  Be excited about the match but remain neutral - fans of both teams 
  are attending! Know the rules of football and can explain them simply.

ai_knowledge_base: |
  City FC vs Manchester United - Premier League Matchday 15
  Date: December 7, 2025 · Kickoff: 3:00 PM
  Venue: City Stadium, 60,000 capacity
  
  Stadium opened 2012, sustainable design with solar panels
  4 entry gates: North (home), South (away), East & West (general)
  
  Food options: Main concourse has 12 vendors
  Alcohol: Beer available in concourse areas only, not at seats
  
  Parking: Lots A-D around stadium, £15 per vehicle
  Public transport: Stadium Station on Blue Line (5 min walk)
  
  Fan zone opens 2 hours before kickoff with entertainment

ai_welcome_general: "Welcome to City Stadium! I can help with directions to your seat, food options, kickoff time, team lineups, stadium rules, or nearby parking. What do you need?"
ai_welcome_item: "Here's your complete match day guide! Ask me about kickoff time, team lineups, where to eat, parking, or how to get to your seat. What do you need help with?"
```

---

## Content Item (Single Page)

```yaml
name: "Match Day Guide"
content: |
  # City FC vs Manchester United
  ## Premier League · Matchday 15
  
  ---
  
  ## ⏰ Schedule
  
  | Time | Event |
  |------|-------|
  | 1:00 PM | Gates open |
  | 1:30 PM | Fan Zone entertainment begins |
  | 2:30 PM | Teams warm-up |
  | 2:45 PM | Team announcements |
  | 2:55 PM | National anthem |
  | **3:00 PM** | **KICKOFF** |
  | 3:45 PM | Half-time (15 minutes) |
  | ~4:45 PM | Full-time |
  
  ---
  
  ## 🏟️ Stadium Map
  
  **Your Section:** Check your ticket for block, row, and seat number
  
  ### Entry Gates
  - **North Gate** → Blocks 101-120 (Home supporters)
  - **South Gate** → Blocks 201-220 (Away supporters)
  - **East Gate** → Blocks 301-340
  - **West Gate** → Blocks 401-440
  
  ### Key Locations
  - 🍔 **Food & Drink** → Every concourse level
  - 🚻 **Restrooms** → Behind every section
  - 🏥 **First Aid** → Gates N1, S1, E1, W1
  - 👕 **Team Shop** → North Concourse
  - 📸 **Photo Opportunity** → West Concourse (giant shirt display)
  
  ---
  
  ## ⚽ Team Lineups
  
  ### City FC (Home - Blue)
  
  **Manager:** Antonio García
  
  | # | Position | Player |
  |---|----------|--------|
  | 1 | GK | David Martinez |
  | 2 | RB | James Wilson |
  | 5 | CB | Michael Brown |
  | 6 | CB | Carlos Silva |
  | 3 | LB | Ahmed Hassan |
  | 8 | CM | Thomas Mueller |
  | 10 | CM | Paolo Rossi |
  | 7 | RW | Marcus Sterling |
  | 11 | LW | Yuki Tanaka |
  | 9 | ST | **Emmanuel Okonkwo** (C) |
  | 20 | ST | Lucas Fernandez |
  
  **Bench:** 13-Rodriguez, 4-Chen, 14-O'Brien, 16-Kowalski, 
  17-Nguyen, 19-Anderson, 21-Petrov
  
  ### Manchester United (Away - Red)
  
  **Manager:** Roberto Mancini
  
  | # | Position | Player |
  |---|----------|--------|
  | 1 | GK | Peter Schmeichel Jr. |
  | 2 | RB | Kyle Walker-Peters |
  | 4 | CB | Virgil van Berg |
  | 5 | CB | Harry Stone |
  | 3 | LB | Luke Shaw Jr. |
  | 6 | DM | Declan Rice |
  | 8 | CM | Bruno Fernandes Jr. |
  | 7 | RW | Jadon Sancho Jr. |
  | 11 | LW | Marcus Rashford Jr. |
  | 10 | AM | **Mason Mount Jr.** (C) |
  | 9 | ST | Erling Larsen |
  
  **Bench:** 22-Henderson, 15-Maguire Jr., 17-Fred Jr., 18-Eriksen,
  19-Antony Jr., 20-Pellistri, 21-Garnacho Jr.
  
  ---
  
  ## 📊 Head to Head
  
  | Stat | City FC | Man Utd |
  |------|---------|---------|
  | League Position | 2nd | 4th |
  | Points | 32 | 28 |
  | Last 5 Games | W W D W L | W D W L W |
  | Goals Scored | 34 | 29 |
  | Goals Conceded | 12 | 15 |
  
  **Last Meeting:** City FC 2-1 Man Utd (April 2025)
  
  **All-Time Record:**
  - City FC wins: 54
  - Man Utd wins: 61
  - Draws: 38
  
  ---
  
  ## 🍔 Food & Drink
  
  ### Concourse Options
  - **Stadium Burger** - Classic burgers and hot dogs
  - **Pizza Corner** - Slices and whole pies
  - **The Noodle Bar** - Asian street food
  - **Fish & Chips** - Traditional British
  - **Vegan Kitchen** - Plant-based options
  - **Coffee Station** - Hot drinks and pastries
  
  ### Prices
  - Beer (pint): £6.50
  - Burger meal: £12.00
  - Hot dog: £6.00
  - Pizza slice: £5.00
  - Coffee: £3.50
  - Water bottle: £2.50
  
  **📱 Mobile ordering available - skip the queue!**
  Download the City FC app and order to your seat (Blocks 101-140 only)
  
  ---
  
  ## 📍 Getting Home
  
  ### Public Transport
  - **Stadium Station** → Blue Line services every 5 minutes
  - **Special match buses** → City Centre (£3 fare)
  - Allow 20-30 minutes to reach station after final whistle
  
  ### Driving
  - Exit via your designated gate to reduce congestion
  - **Lot A & B** → North exit (Highway 1)
  - **Lot C & D** → South exit (Highway 2)
  - Expected clear time: 45-60 minutes post-match
  
  ### Rideshare
  - **Pickup zone** → East Gate car park
  - Surge pricing likely for 30 min after match
  
  ---
  
  ## 📱 Stay Connected
  
  - **WiFi:** `CityStadium_Guest` (free, no password)
  - **Official App:** Live stats, replays, mobile ordering
  - **Social:** @CityFC on all platforms
  - **Match Hashtag:** #CityVsUnited
  
  ---
  
  ## ⚠️ Important Information
  
  ### Prohibited Items
  ❌ Outside food & drinks  
  ❌ Bags larger than A4 size  
  ❌ Umbrellas  
  ❌ Professional cameras (lens > 20cm)  
  ❌ Drones  
  ❌ Weapons of any kind  
  
  ### Emergency
  - **Emergency services:** Dial 999
  - **Stadium security:** Text 66777
  - **Lost children:** Report to nearest steward
  - **Medical emergency:** Nearest first aid point
  
  ---
  
  ## 🎉 Enjoy the Match!
  
  Thank you for supporting City FC. Sing loud, respect fellow fans, 
  and may the best team win!
  
  *This card is your souvenir of today's match. Collect the whole season!*

image_url: "[Upload: Action shot or team photo]"
ai_knowledge_base: |
  Key players to watch:
  - Emmanuel Okonkwo (City): 12 goals this season, top scorer
  - Erling Larsen (United): Hat-trick last match
  
  Tactical preview: City likely to press high, United may counter-attack
  
  Weather forecast: 12°C, partly cloudy, 10% chance of rain
  
  Referee: Michael Oliver - tends to let game flow, averages 3.2 yellows/match
  
  VAR: Howard Webb - controversial offside decisions recently
  
  Stadium records: Largest crowd 59,847 vs Liverpool 2023
  
  Club history: City FC founded 1892, 3 league titles, 2 FA Cups
  Manchester United: Founded 1878, 20 league titles, 12 FA Cups
sort_order: 1
parent_id: null
```

---

## Notes for Implementation

1. **Single mode** is perfect for event-specific information
2. **Digital Access** becomes a match day souvenir
3. All information on one page - no navigation needed
4. **Markdown formatting** creates clear sections
5. Include **tables** for lineups and statistics
6. **AI knowledge** can provide real-time-like information about players and tactics
7. Update content for each match - reuse card design, change content
8. Consider creating a season pass card with all home matches

