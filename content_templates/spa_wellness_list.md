# Spa & Wellness Center - List Mode (Digital Access)

A spa menu featuring treatments, services, and wellness offerings. List mode presents each service clearly with descriptions, durations, and pricing.

---

## Card Settings

```yaml
name: "Serenity Spa & Wellness"
description: |
  **Your Sanctuary of Calm**
  
  Experience transformative treatments designed to restore balance and vitality.
  
  📍 Grand Hotel, Level B1
  ⏰ Daily 9:00 AM - 9:00 PM
  📞 Reservations: ext. 8888

content_mode: list
is_grouped: false
group_display: null
billing_type: digital
image_url: "[Upload: Spa logo or serene interior photo]"

# AI Configuration
conversation_ai_enabled: true
ai_instruction: |
  You are a knowledgeable spa concierge. Help guests choose treatments 
  based on their needs - relaxation, rejuvenation, pain relief, or 
  skincare. Be warm and reassuring. Explain treatment benefits without 
  medical claims. Suggest combinations and packages when appropriate.

ai_knowledge_base: |
  Serenity Spa at Grand Hotel
  Hours: 9:00 AM - 9:00 PM daily
  
  Facilities: 8 treatment rooms, couples suite, hydrotherapy pool, 
  steam room, sauna, relaxation lounge
  
  Products: Organic skincare line, essential oils, hot stones
  
  Booking: 24-hour advance recommended, same-day subject to availability
  Cancellation: 4-hour notice required
  
  Gratuity: 18-20% customary, not included in prices
  Health forms required for first visit
  Arrive 30 minutes early to enjoy facilities

ai_welcome_general: "Welcome to Serenity Spa! I can recommend treatments for relaxation, pain relief, or skincare goals, explain what to expect during any service, suggest combinations, or help with booking. What brings you in today?"
ai_welcome_item: "Our {name} is wonderful! I can explain what happens during the treatment, suggest who it's best for, discuss duration and pricing, or recommend add-ons. What would you like to know?"
```

---

## Content Items

### Hidden Category (Required for flat list)
```yaml
name: "Services"
content: ""
image_url: null
ai_knowledge_base: ""
sort_order: 1
parent_id: null
```

#### Signature Hot Stone Massage
```yaml
name: "Signature Hot Stone Massage"
content: |
  **90 minutes | $195**
  
  Warm basalt stones melt away tension while skilled hands work deep 
  into tired muscles. Our signature treatment combines Swedish and 
  deep tissue techniques with heated stones placed along energy 
  meridians.
  
  ---
  
  ✓ Full body treatment
  ✓ Includes scalp massage
  ✓ Aromatherapy oils
  
  *Best for: Deep relaxation, muscle tension, stress relief*

image_url: "[Upload: hot_stone_massage.jpg]"
ai_knowledge_base: |
  Most popular treatment. Stones heated to 130°F. Therapist uses 
  combination of stones and hands. Good for those who like heat 
  and medium-deep pressure. Not recommended if pregnant or have 
  circulation issues. Pairs well with body scrub beforehand.
sort_order: 1
parent_id: "[Reference: Services]"
```

#### Rejuvenating Facial
```yaml
name: "Rejuvenating Facial"
content: |
  **60 minutes | $145**
  
  Customized to your skin type, this results-driven facial includes 
  deep cleansing, exfoliation, extractions, mask, and hydrating 
  finish. Your therapist will analyze your skin and select the 
  perfect products.
  
  ---
  
  ✓ Skin analysis included
  ✓ All skin types
  ✓ LED light therapy add-on available (+$35)
  
  *Best for: Dull skin, congestion, anti-aging*

image_url: "[Upload: facial_treatment.jpg]"
ai_knowledge_base: |
  Uses organic product line. Therapist customizes products based 
  on skin analysis. Extractions are gentle - redness typically 
  fades within 2 hours. LED add-on uses red light for collagen 
  stimulation. No downtime. Avoid sun exposure for 24 hours after.
sort_order: 2
parent_id: "[Reference: Services]"
```

#### Deep Tissue Massage
```yaml
name: "Deep Tissue Massage"
content: |
  **60 minutes | $155 | 90 minutes | $215**
  
  Focused, therapeutic massage targeting chronic muscle tension and 
  knots. Our therapists use sustained pressure and slow strokes to 
  reach deeper layers of muscle and fascia.
  
  ---
  
  ✓ Pressure customized to tolerance
  ✓ Focus areas available
  ✓ Arnica gel finish
  
  *Best for: Athletes, chronic pain, injury recovery*

image_url: "[Upload: deep_tissue.jpg]"
ai_knowledge_base: |
  Firm to very firm pressure. Communicate with therapist about 
  pressure - should feel "good hurt" not sharp pain. May cause 
  soreness next day. Drink extra water after. 90-minute version 
  recommended for full body; 60 minutes better for focus areas.
sort_order: 3
parent_id: "[Reference: Services]"
```

#### Couples Retreat Package
```yaml
name: "Couples Retreat Package"
content: |
  **2.5 hours | $450 per couple**
  
  Share a romantic escape in our private couples suite. Begin with 
  champagne and chocolate, followed by side-by-side massages. 
  Conclude with time in the private jacuzzi.
  
  ---
  
  ✓ Private suite with jacuzzi
  ✓ Champagne & artisan chocolates
  ✓ 60-minute couples massage
  ✓ Exclusive suite access (90 min)
  
  *Best for: Anniversaries, honeymoons, date nights*

image_url: "[Upload: couples_suite.jpg]"
ai_knowledge_base: |
  Most romantic offering. Suite has two massage tables, private 
  jacuzzi, fireplace, rain shower. Can upgrade to 90-minute 
  massage. Book 48 hours ahead for suite. Peak times: Friday 
  evening, weekends. Non-alcoholic option available. Can add 
  rose petals and candles for special occasions (+$50).
sort_order: 4
parent_id: "[Reference: Services]"
```

#### Express Refresh
```yaml
name: "Express Refresh"
content: |
  **30 minutes | $85**
  
  Short on time? Our express treatments target key areas for 
  maximum impact. Choose from:
  
  - **Back & Shoulders** - Release tension
  - **Scalp & Neck** - Relieve headaches
  - **Feet & Legs** - Restore tired legs
  
  ---
  
  ✓ No changing required
  ✓ Same-day booking welcome
  ✓ Combine two for 50-minute treatment
  
  *Best for: Busy schedules, lunch breaks, travel recovery*

image_url: "[Upload: express_massage.jpg]"
ai_knowledge_base: |
  Popular with business travelers and hotel guests. Can stay 
  clothed for back/shoulders option. Scalp massage great for 
  jet lag and headaches. Foot treatment uses reflexology points. 
  Easy to fit between meetings. Often available same-day.
sort_order: 5
parent_id: "[Reference: Services]"
```

#### Detox Body Wrap
```yaml
name: "Detox Body Wrap"
content: |
  **75 minutes | $175**
  
  Purify and tone with our signature body wrap. Begins with 
  full-body exfoliation, followed by warm mineral mud application. 
  Wrapped in thermal blankets, you'll deeply relax while toxins 
  are drawn out.
  
  ---
  
  ✓ Full-body exfoliation
  ✓ Mineral-rich mud mask
  ✓ Scalp massage during wrap
  ✓ Moisturizing finish
  
  *Best for: Detoxification, skin smoothing, water retention*

image_url: "[Upload: body_wrap.jpg]"
ai_knowledge_base: |
  Uses Dead Sea mud and seaweed extracts. Helps with skin texture 
  and temporary inch loss (water weight). Exfoliation removes 
  dead skin cells. Will feel warm during wrap portion. Great 
  prep before vacation or event. Avoid if claustrophobic.
sort_order: 6
parent_id: "[Reference: Services]"
```

---

## Notes for Implementation

1. **List Mode** presents services cleanly for easy browsing
2. **Digital Access** ideal for in-room hotel tablets or QR at reception
3. Include **pricing and duration** prominently
4. AI knowledge should cover contraindications and recommendations
5. Keep descriptions benefit-focused and sensory
6. Update seasonally with special treatments
7. Consider grouping if menu exceeds 10+ items


