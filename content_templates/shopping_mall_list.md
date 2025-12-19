# Shopping Mall - Grouped List Mode (Digital Access)

A mall store directory organized by category. Perfect for shopping centers, malls, and retail complexes that want to help visitors find stores, restaurants, and services quickly.

---

## Card Settings

```yaml
name: "Central Plaza Mall - Store Directory"
description: |
  🛍️ Welcome to **Central Plaza Mall**
  
  200+ stores across 4 floors. Find your favorite brands below.
  
  📍 Guest Services: Level 1 near Main Entrance

content_mode: list
is_grouped: true
group_display: expanded
billing_type: digital

# AI Configuration
conversation_ai_enabled: true
ai_instruction: |
  You are a friendly mall concierge. Help shoppers find stores, restaurants, 
  and services. Give directions, share current promotions, and suggest 
  alternatives if a store doesn't have what they need. 
  Be helpful and enthusiastic about shopping!

ai_knowledge_base: |
  Central Plaza Mall - Premier Shopping Destination
  Address: 500 Central Avenue
  Hours: Mon-Sat 10am-9pm, Sun 11am-7pm
  Stores: 200+ retail locations
  Floors: 4 levels + parking garage
  
  Layout:
  - Level 1: Fashion, accessories, main entrances
  - Level 2: Electronics, home goods, food court
  - Level 3: Entertainment, kids, services
  - Level 4: Department stores, specialty retail
  
  Parking: 3 hours free with validation, $3/hour after
  WiFi: CentralPlaza_Guest (free)

ai_welcome_general: "Welcome to Central Plaza Mall! I can help you find specific stores, give directions, share current sales and promotions, suggest restaurants, or locate services like ATMs. What are you looking for?"
ai_welcome_item: "For {name}, I can give you directions, share their hours, tell you about current promotions, or suggest similar stores nearby. What do you need?"
```

---

## Categories (Layer 1)

### 👗 Fashion & Apparel
Clothing, shoes, and accessories. Primarily on Level 1 and Level 4.

### 📱 Electronics & Tech
Phones, computers, and gadgets. Located on Level 2.

### 🍽️ Dining
Restaurants and food court. Quick bites to sit-down dining on Level 2.

### ℹ️ Services & Facilities
Guest services and amenities spread throughout the mall.

---

## Content Items (Layer 2)

### Category: Fashion & Apparel

#### Zara

**Fast Fashion & Trendy Styles**

📍 Level 1, Store #112
⏰ Mall Hours

Latest runway-inspired fashion at accessible prices. New arrivals twice weekly.

---

🏷️ Women's, Men's, Kids
💳 Mall gift cards accepted

**AI Knowledge:** Zara is one of mall's largest stores (8,000 sq ft). New inventory Tuesdays and Fridays. Return policy: 30 days with receipt.

---

#### H&M

**Affordable Fashion for Everyone**

📍 Level 1, Store #108
⏰ Mall Hours

Trendy, sustainable fashion at great prices. Features Conscious Collection made from recycled materials.

---

🏷️ Women's, Men's, Kids, Home
💳 Student discount 15% (with ID)

---

#### Nordstrom

**Premium Department Store**

📍 Level 4, Anchor Store
⏰ 10am-9pm Mon-Sat, 11am-7pm Sun

Designer brands, exceptional service, and free alterations. Personal stylists available by appointment.

---

🏷️ Full Department Store
💳 Nordstrom Card earns 3x points
🛋️ Café & Espresso Bar inside

---

### Category: Electronics & Tech

#### Apple Store

**Official Apple Retail Location**

📍 Level 2, Store #215
⏰ Mall Hours

Latest iPhones, Macs, iPads, and accessories. Genius Bar support and Today at Apple workshops.

---

🏷️ Electronics
🔧 Genius Bar: Book online
📱 Trade-in available

---

#### Best Buy

**Electronics Superstore**

📍 Level 2, Store #201
⏰ Mall Hours

TVs, computers, appliances, and smart home tech. Expert advice and installation services.

---

🏷️ Electronics, Appliances
🛠️ Geek Squad support
💳 Best Buy Credit: 18 months 0% APR

---

### Category: Dining

#### Food Court

**Quick Bites & Global Flavors**

📍 Level 2, Center Court
⏰ 10am-9pm daily

**12 Restaurants:**
- Panda Express (Chinese)
- Chick-fil-A (Chicken)
- Sbarro (Pizza)
- Chipotle (Mexican)
- Subway (Sandwiches)
- + more

---

🪑 Seating: 500+ seats
👶 High chairs available

---

### Category: Services & Facilities

#### Guest Services

**We're Here to Help**

📍 Level 1, Near Main Entrance
⏰ Mall Hours

**Services:**
- Wheelchair & stroller rental
- Gift cards (accepted at all stores)
- Package holding
- Lost & found
- Information & directions

---

📞 Call: (555) 123-MALL
💳 Mall gift cards: $10-$500

---

## Notes

- **List layout**: Easy scanning for store names and locations
- **Grouped by type**: Helps shoppers find what they need quickly
- **AI as concierge**: Provides directions, promotions, and alternatives
- **High scan limit**: Suitable for high-traffic public locations
