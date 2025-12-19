# Entertainment Venue - Grouped List (Digital Access)

A theatre or performing arts center guide with shows organized by category. Grouped list helps audiences explore current performances, upcoming events, and venue information.

---

## Card Settings

```yaml
name: "Majestic Theatre - Season Guide"
description: |
  **2025 Season**
  
  Experience world-class performances in our historic venue.
  
  📍 250 Broadway, Downtown
  🎭 Box Office: Open 10 AM - 8 PM
  📞 (555) THEATRE

content_mode: list
is_grouped: true
group_display: expanded
billing_type: digital
image_url: "[Upload: Theatre facade or marquee]"

# AI Configuration
conversation_ai_enabled: true
ai_instruction: |
  You are a friendly theatre concierge. Help guests learn about shows, 
  find the best seats, understand venue amenities, and plan their visit. 
  Be enthusiastic about performances without spoiling plots. Help with 
  accessibility needs and dining recommendations nearby.

ai_knowledge_base: |
  Majestic Theatre - Opened 1927, 1,800 seats
  Historic landmark with Art Deco interior
  
  Seating: Orchestra, Mezzanine, Balcony
  Premium seats: Center Orchestra rows D-M
  Accessible seating: Orchestra, aisle access
  
  Amenities: Two bars, coat check, gift shop
  Pre-show dining: Partner restaurants with prix fixe
  
  Box Office: 250 Broadway, open daily 10 AM - 8 PM
  Same-day rush tickets available 2 hours before showtime
  Student/Senior discounts on select performances
  
  Parking: City Garage adjacent ($25 event rate)
  Subway: Blue Line, Theatre District station

ai_welcome_general: "Welcome to the Majestic Theatre! I can tell you about current shows, recommend the best seats for your budget, explain dining options nearby, or share our venue's history. What would you like to know?"
ai_welcome_item: "You're interested in {name}! I can share the show synopsis (no spoilers!), suggest best seats, tell you the run time, or help with accessibility needs. What would help?"
```

---

## Content Items

### Category 1: Now Playing
```yaml
name: "Now Playing"
content: ""
image_url: null
ai_knowledge_base: |
  Current shows running through Spring 2025.
  All performances Tuesday-Sunday.
  Best availability: Tuesday, Wednesday, Thursday evenings.
sort_order: 1
parent_id: null
```

#### The Phantom Legacy
```yaml
name: "The Phantom Legacy"
content: |
  **A New Musical Thriller**
  
  ⭐ Critics' Choice - "Breathtaking!" - NY Times
  
  Paris, 1920. The Opera Populaire reopens after decades of darkness. 
  But someone remembers the music of the night...
  
  ---
  
  🎭 **Now through May 2025**
  
  📅 Tue-Sat 8 PM | Wed & Sat 2 PM | Sun 3 PM
  
  ⏱ 2 hours 30 minutes (one intermission)
  
  💰 $79 - $175
  
  *Recommended ages 12+*

image_url: "[Upload: phantom_legacy_poster.jpg]"
ai_knowledge_base: |
  Flagship production, running since October 2024. Original score 
  by Broadway veterans. Cast of 32, full orchestra. Features 
  famous chandelier effect in Act 2 (center orchestra best view). 
  Most popular: Saturday evening. Best availability: Wednesday 
  matinee. VIP package includes backstage tour. Standing ovations 
  every night. Not affiliated with other "Phantom" productions.
sort_order: 1
parent_id: "[Reference: Now Playing]"
```

#### Comedy Tonight!
```yaml
name: "Comedy Tonight!"
content: |
  **Stand-Up Showcase**
  
  The city's best comedians take the stage for an unforgettable 
  night of laughter. Rotating headliners weekly.
  
  ---
  
  🎭 **Fridays & Saturdays**
  
  📅 10:30 PM (late show)
  
  ⏱ 90 minutes (no intermission)
  
  💰 $45 - $65
  
  🍸 Two-drink minimum
  
  *Ages 18+ only*

image_url: "[Upload: comedy_night.jpg]"
ai_knowledge_base: |
  Late-night show in Cabaret space (200 seats). Different headliner 
  each weekend. Bar seating and table seating available. Full bar 
  service during show. Famous comedians have performed here as 
  surprise guests. Great date night option. Book early - sells out.
sort_order: 2
parent_id: "[Reference: Now Playing]"
```

---

### Category 2: Coming Soon
```yaml
name: "Coming Soon"
content: ""
image_url: null
ai_knowledge_base: |
  Upcoming productions. Premium subscriber presale one week before 
  public. Sign up for email alerts for on-sale announcements.
sort_order: 2
parent_id: null
```

#### Shakespeare in Summer
```yaml
name: "Shakespeare in Summer"
content: |
  **A Midsummer Night's Dream**
  
  An enchanting outdoor production in our rooftop garden. Bring 
  blankets and picnics for this magical evening under the stars.
  
  ---
  
  🎭 **June 15 - August 31, 2025**
  
  📅 Wed-Sun 7:30 PM
  
  ⏱ 2 hours (one intermission)
  
  💰 $55 - $95 | Lawn seating $35
  
  🍷 Picnic packages available
  
  *Family friendly*
  
  **ON SALE MARCH 1**

image_url: "[Upload: summer_shakespeare.jpg]"
ai_knowledge_base: |
  Rooftop venue holds 500. Modern dress production with live 
  musicians. Bring blankets for lawn section. Chairs provided in 
  premium sections. Rain policy: show goes on unless severe weather; 
  covered seating available. Sunset start time means show ends 
  under stars. Picnic basket from partner deli available for pre-order.
sort_order: 1
parent_id: "[Reference: Coming Soon]"
```

#### Holiday Spectacular
```yaml
name: "Holiday Spectacular"
content: |
  **A Majestic Christmas**
  
  Our beloved annual tradition returns! Featuring the Rockettes-style 
  dance troupe, live orchestra, and Santa's grand arrival.
  
  ---
  
  🎭 **November 20 - December 30, 2025**
  
  📅 Daily performances
  
  ⏱ 90 minutes (no intermission)
  
  💰 $59 - $149
  
  🎁 Photo packages with Santa available
  
  *All ages welcome*
  
  **PRESALE STARTS OCTOBER 1**

image_url: "[Upload: holiday_show.jpg]"
ai_knowledge_base: |
  35-year tradition. Cast of 50+ dancers. Real snow effect in 
  finale. Santa meet-and-greet after matinees (book ahead). 
  School groups welcome - special rates for 20+. Most popular 
  performances: Thanksgiving weekend, week before Christmas. 
  Best availability: November weekdays.
sort_order: 2
parent_id: "[Reference: Coming Soon]"
```

---

### Category 3: Venue Guide
```yaml
name: "Venue Guide"
content: ""
image_url: null
ai_knowledge_base: |
  Practical information for visitors. Staff available in lobby 
  30 minutes before showtime for assistance.
sort_order: 3
parent_id: null
```

#### Seating Guide
```yaml
name: "Seating Guide"
content: |
  **Find Your Perfect Seat**
  
  **Orchestra** - Main floor, closest to stage
  - Premium: Rows D-M center
  - Value: Rear orchestra, partial view
  
  **Mezzanine** - Elevated, great sightlines
  - Front row has excellent leg room
  - Bar service during intermission
  
  **Balcony** - Upper level, full stage view
  - Most affordable option
  - Best for spectacle shows
  
  ---
  
  ♿ **Accessible Seating**
  - Wheelchair: Orchestra, aisle
  - Transfer seats available
  - Hearing loop: All sections
  - Audio description: Select shows

image_url: "[Upload: seating_chart.jpg]"
ai_knowledge_base: |
  Orchestra center rows D-M considered best - not too close, 
  centered. Row A very close, neck strain possible. Mezzanine 
  front row is hidden gem - great view, private feel. Balcony 
  side seats have partial obstruction. For musicals, center 
  is key. For plays, slight angle fine. Children need booster 
  seats in orchestra. Accessible seating book through box office.
sort_order: 1
parent_id: "[Reference: Venue Guide]"
```

#### Before the Show
```yaml
name: "Before the Show"
content: |
  **Plan Your Visit**
  
  📍 **Location**
  250 Broadway, Downtown
  
  🚇 **Getting Here**
  - Subway: Blue Line, Theatre District
  - Parking: City Garage ($25 event rate)
  - Drop-off: Front entrance on Broadway
  
  🍽 **Dining Partners**
  Show your ticket for prix fixe specials:
  - Bistro Laurent (French) - $55
  - Trattoria Bella (Italian) - $45
  - The Grill Room (American) - $65
  
  ⏰ **Arrival**
  - Doors open 45 minutes before
  - Latecomers seated at suitable break
  - Coat check available ($3)

image_url: "[Upload: theatre_entrance.jpg]"
ai_knowledge_base: |
  Arrive 30 minutes early for best experience. Pre-show drinks 
  at lobby bars. Partner restaurants 5-10 minute walk - make 
  reservations. Garage fills up on weekends - arrive early or 
  use subway. No re-entry once show starts. Photos in lobby 
  allowed, not in auditorium. Gift shop has show merchandise.
sort_order: 2
parent_id: "[Reference: Venue Guide]"
```

---

## Notes for Implementation

1. **Grouped List** organizes by performance status and venue info
2. **Digital Access** works as playbill supplement or lobby display
3. Include **show times, prices, duration** consistently
4. AI knowledge should cover seating recommendations and venue tips
5. Update "Now Playing" section as shows change
6. Consider adding cast bios for major productions
7. Include accessibility information throughout


