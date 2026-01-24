# ExperienceQR Content Templates

This folder contains sample content templates for different venue types and content modes. Use these templates as a starting point when creating your digital experiences.

> **⚠️ Schema Update Required (Dec 2025):** The SQL templates in `sql/` folder use the old schema (`is_access_enabled`, `access_token` on cards table). The new multi-QR code architecture stores access tokens in `card_access_tokens` table. When using these templates, remove the `is_access_enabled` and `access_token` columns from the INSERT and add a separate INSERT into `card_access_tokens` after the card is created. See `auction_house_grouped.sql` for an updated example.

## Template Structure

Each template file follows the naming convention: `{venue_type}_{content_mode}.md`

### Access Modes

| Mode | Description | Billing |
|------|-------------|---------|
| **Physical Card** | Printed souvenir cards with QR codes | 2 credits per card |
| **Digital Access** | QR-code-only (no physical card) | 0.03 credits per scan |

> **Note:** All templates in this folder use **Digital Access** mode by default.

### Content Modes

Four base layouts with optional grouping:

| Mode | Database Value | Structure | Best For |
|------|----------------|-----------|----------|
| **Single Page** | `single` | 1 content item, full page | Articles, announcements, event info |
| **List** | `list` | Vertical list | Link-in-bio, resource lists, contacts |
| **Grid** | `grid` | 2-column visual grid | Photo galleries, portfolios, products |
| **Cards** | `cards` | Full-width cards, one per row | Featured items, articles, news |

### Grouping Options

For list, grid, and cards modes, content can be grouped into categories:

| Field | Values | Description |
|-------|--------|-------------|
| `is_grouped` | `true` / `false` | Enable category-based organization |
| `group_display` | `expanded` / `collapsed` | How grouped items are shown |

- **Expanded**: Items shown inline under category headers
- **Collapsed**: Tap category to navigate and view items

> **Note:** Templates with "*_grouped" in their filename use `is_grouped: true` with `group_display: expanded`.

## Venue Type Categories

| Category | Code | Description |
|----------|------|-------------|
| Cultural & Arts | `cultural` | Museums, galleries, auction houses, portfolios |
| Food & Beverage | `food` | Restaurants, bars, wineries, breweries |
| Events & Entertainment | `events` | Conferences, shows, sports, festivals, fitness |
| Hospitality & Wellness | `hospitality` | Hotels, spas, resorts, wellness centers |
| Shopping & Showrooms | `retail` | Malls, car dealerships, real estate |
| Tours & Education | `tours` | Walking tours, campus tours, guided experiences |
| General | `general` | Any other venue type |

## Available Templates

| File | Description | Category | Mode |
|------|-------------|----------|------|
| **Cultural & Arts** ||||
| `art_gallery_grid.md` | Contemporary Art Gallery | cultural | Grid |
| `history_museum_grouped.md` | History Museum | cultural | List (grouped) |
| `zoo_grid.md` | Zoo / Wildlife Park | cultural | Grid |
| `auction_house_grouped.md` | Auction House / Art Sale | cultural | List (grouped) |
| `illustrator_portfolio_grid.md` | Illustrator Portfolio | cultural | Grid |
| **Food & Beverage** ||||
| `fine_dining_grouped.md` | Fine Dining Restaurant | food | List (grouped) |
| `cocktail_bar_inline.md` | Craft Cocktail Bar | food | Cards |
| `winery_tour_inline.md` | Winery / Vineyard | food | Cards |
| **Events & Entertainment** ||||
| `conference_grouped.md` | Tech Conference | events | List (grouped) |
| `football_match_single.md` | Sports Event | events | Single |
| `fashion_show_grouped.md` | Fashion Show / Runway | events | List (grouped) |
| `entertainment_venue_grouped.md` | Theatre / Performing Arts | events | List (grouped) |
| `fitness_studio_list.md` | Fitness Studio / Gym | events | List |
| **Hospitality & Wellness** ||||
| `hotel_services_list.md` | Hotel Guest Services | hospitality | List |
| `spa_wellness_list.md` | Spa & Wellness Center | hospitality | List |
| **Shopping & Showrooms** ||||
| `shopping_mall_list.md` | Shopping Mall | retail | List |
| `car_dealership_grid.md` | Car Dealership | retail | Grid |
| `real_estate_showroom_grid.md` | Real Estate Showroom | retail | Grid |
| **Tours & Education** ||||
| `tourist_landmark_inline.md` | Tourist Walking Tour | tours | Cards |
| `university_campus_grouped.md` | University Campus Tour | tours | List (grouped) |

## Field Reference

### Card Fields
| Field | Required | Description |
|-------|----------|-------------|
| `name` | ✅ | Experience/card name |
| `description` | Recommended | Overview description (Markdown supported) |
| `content_mode` | ✅ | single, grid, list, or cards |
| `is_grouped` | ✅ | true or false - whether content has categories |
| `group_display` | Grouped only | expanded or collapsed - how grouped items display |
| `billing_type` | ✅ | physical or digital |
| `image_url` | Physical only | Card artwork image |
| `ai_instruction` | Optional | AI assistant role/personality (max 100 words) |
| `ai_knowledge_base` | Optional | Background knowledge for AI (max 2000 words) |
| `ai_welcome_general` | Optional | Custom welcome for General AI Assistant |
| `ai_welcome_item` | Optional | Custom welcome for Item AI (use {name} placeholder) |

### Content Item Fields
| Field | Required | Description |
|-------|----------|-------------|
| `name` | ✅ | Item name/title |
| `content` | Recommended | Item description (Markdown supported) |
| `image_url` | Mode-dependent | Item image |
| `parent_id` | ✅ | Reference to parent category (see Data Model below) |
| `ai_knowledge_base` | Optional | Item-specific AI knowledge (max 500 words) |
| `sort_order` | Optional | Display order (lower = first) |

### Data Model

Content items follow a two-layer hierarchy:

```
Layer 1 (parent_id = null): Categories
Layer 2 (parent_id = UUID):  Actual content items
```

| Mode | Layer 1 | Layer 2 |
|------|---------|---------|
| **Flat** (`is_grouped = false`) | Hidden (exists but not shown) | Content items (displayed) |
| **Grouped** (`is_grouped = true`) | Categories (shown as headers) | Content items (under categories) |

> **Note:** All SQL templates create a default hidden category for flat mode content. This ensures consistent data structure regardless of whether grouping is enabled.

## AI Configuration Best Practices

The AI assistant is proactive - it guides users on what they can ask. Follow these patterns for optimal AI configuration:

### `ai_instruction` (Role Definition)
Define the AI's persona, expertise, tone, and boundaries:
```yaml
ai_instruction: |
  You are an enthusiastic art docent at a contemporary art gallery. 
  Speak with passion about the artworks, artists, and artistic movements. 
  Help visitors understand the meaning, techniques, and context behind each piece. 
  Be approachable and encourage questions. Avoid overly academic language.
```

### `ai_knowledge_base` (Background Info)
Include practical information visitors need:
- Hours, location, layout
- Key facts and figures
- Pricing, tips, policies
- Special programs or events

### `ai_welcome_general` (Experience-Level Greeting)
**Pattern:** Explicitly list 3-4 specific capabilities, end with engaging question.

❌ **Bad:** "Welcome! Ask me anything about our gallery."

✅ **Good:** "Welcome to Modern Visions! I can tell you about any artwork's meaning, the artist's story, techniques used, or suggest what to see based on your interests. What draws your attention?"

### `ai_welcome_item` (Item-Level Greeting)
**Pattern:** Offer specific information types available for the item, use `{name}` placeholder.

❌ **Bad:** "I'd love to tell you more about \"{name}\". What would you like to know?"

✅ **Good:** "This is \"{name}\" - I can share the artist's inspiration, explain the technique, give historical context, or connect it to other works here. What interests you?"

> **Key Insight:** Users often don't know what to ask. By listing specific topics, the AI guides them to valuable information they didn't know was available.

## Usage

1. Choose a template that matches your venue type and desired layout
2. Copy the content to your ExperienceQR dashboard
3. Replace placeholder text with your actual content
4. Upload your images
5. Customize AI settings if needed
6. Publish and generate QR codes

---

*Last updated: December 2025*
