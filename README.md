# ExperienceQR - AI-Powered Digital Experience Platform

[![Vue.js](https://img.shields.io/badge/Vue.js-3-4FC08D.svg)](https://vuejs.org/)
[![TypeScript](https://img.shields.io/badge/TypeScript-blue.svg)](https://www.typescriptlang.org/)
[![Supabase](https://img.shields.io/badge/Supabase-3ECF8E.svg)](https://supabase.io/)
[![Express.js](https://img.shields.io/badge/Express.js-4.x-000000.svg)](https://expressjs.com/)
[![Google Cloud Run](https://img.shields.io/badge/Google_Cloud_Run-4285F4.svg)](https://cloud.google.com/run)

ExperienceQR is a comprehensive **AI-powered digital experience platform** that transforms any venue into an interactive guide. The platform enables museums, restaurants, shopping malls, events, and any venue to provide visitors with rich, AI-powered digital content accessible through QR codes. Optional physical souvenir cards add collectible value to the digital experience.

## Project Overview

### Business Model & Architecture

-   **Three-Tier Ecosystem**:
    1.  **Creators** (B2B) - Museums, restaurants, malls, events, and any venue creating interactive digital projects.
    2.  **Administrators** (Platform) - ExperienceQR operators managing platform operations.
    3.  **Visitors** (B2C) - Anyone scanning QR codes for free digital content and AI guidance.

-   **Core Value Proposition**:
    -   **AI-Powered Interactive Guide**: Transform any venue into an intelligent, interactive experience.
    -   **QR Code Access**: Instant access via any smartphone camera—no app required.
    -   **Advanced AI Voice Conversations**: Real-time voice-based AI using OpenAI for natural conversations.
    -   **Multi-Language Support**: AI-powered, one-click translation of content into multiple languages.
    -   **Optional Physical Cards**: Collectible souvenirs that add premium keepsake value.

### Subscription & Pricing

ExperienceQR uses a **subscription-based pricing model**:

| Tier | Price | Projects | Access Limit | Translations |
|------|-------|-------------|--------------|--------------|
| **Free** | $0 | Up to 3 | 50/month pooled | ❌ Not available |
| **Premium** | $50/month | Up to 15 | 3,000/month pooled | ✅ Full support |

#### Free Tier
- Create up to **3 projects**
- **50 monthly access pool** (shared across all projects)
- **No multi-language translations**
- Perfect for personal use or trying the platform

#### Premium Tier
- Up to **15 projects**
- **3,000 monthly access pool** (shared across all projects)
- **Batch overage**: 5 credits = 100 extra access (when limit reached)
- **Full translation support** to 10+ languages
- Stripe-managed billing with customer portal

> **Note**: Usage is tracked in Redis (source of truth) for performance. Database stores subscription metadata only.

### Access Modes

ExperienceQR supports two access modes (selected first when creating, **cannot be changed after creation**):

| Mode | Description | Mobile UX | Best For |
|------|-------------|-----------|----------|
| **Physical Card** | Printed souvenir cards | Card Overview → Content | Museums, exhibitions, events |
| **Digital Access** | QR-code only (no physical card) | Welcome Page → Content | Link-in-bio, menus, campaigns |

## Authentication & Role System

The platform uses Supabase Auth for user management.

### Supported Authentication Methods
- **Email & Password**: Standard registration with email verification.
- **Google Login (OAuth)**: One-click registration and login via Google.
    - Requires configuration in Supabase Dashboard → Authentication → Providers → Google.
    - Redirect URL should include `[YOUR_DOMAIN]/cms`.

### Roles
All new users are automatically assigned the `cardIssuer` role via a database trigger (`handle_new_user`).
- **cardIssuer**: Create and manage their own digital projects.
- **admin**: Access the admin portal for user management and global settings.

#### Physical Card Mode
- Unlimited scans after issuance
- Card image and description displayed on overview page
- Batch issuance with credit consumption (2 credits per card)
- Designed for museums, exhibitions, events

#### Digital Access Mode
- Access counted against subscription tier limits
- Welcome page with animated visual (no card image)
- Designed for link-in-bio, digital menus, campaigns

### Content Modes

Five base layouts are available to structure your content:

| Mode | Structure | Layout | Best For |
|------|-----------|--------|----------|
| **Single** | 1 content item | Full page | Articles, announcements, event info |
| **Grouped** | Categories + Items | Category headers with list | Menus, catalogs, service lists |
| **List** | N items | Vertical list | Link-in-bio, resource lists, contacts |
| **Grid** | N items | 2-column grid | Photo galleries, portfolios, products |
| **Inline** | N items | Full-width cards | Featured items, blog posts, news |

**Grouping Logic:**
- `Grouped` mode enables hierarchical organization with parent items serving as category headers
- `group_display` option controls whether categories are 'expanded' (items visible inline) or 'collapsed' (navigate to view items)

See `planning_docs/BILLING_AND_CONTENT_MODES.md` for complete documentation.

### Template Library

ExperienceQR includes a **Template Library** that allows users to quickly create projects from pre-built templates. Templates are organized by venue type and content mode.

**Architecture:**
Templates are linked to actual `cards` records in the database. This allows full reuse of existing card components for creating and editing template content. When a user imports a template, the linked card and all its content items are copied to create a new card owned by that user.

**User Features:**
- Browse templates by venue type:
  - **Cultural & Arts** - Museums, galleries, auction houses, portfolios
  - **Food & Beverage** - Restaurants, bars, wineries, breweries
  - **Events & Entertainment** - Conferences, shows, sports, festivals, fitness
  - **Hospitality & Wellness** - Hotels, spas, resorts, wellness centers
  - **Shopping & Showrooms** - Malls, car dealerships, real estate, retail
  - **Tours & Education** - Walking tours, campus tours, guided tours
  - **General** - Any other venue type
- Filter by content mode (single, grouped, list, grid, inline)
- Preview template content structure before importing
- Import templates with custom name and billing type selection
- Creates a complete project with all content items and AI configuration

**Admin Features:**
- Create projects using the normal project creation flow (My Projects)
- Link existing projects as templates through the Template Management page
- Configure template settings: slug, venue_type, is_featured, is_active
- Edit template content by navigating to the linked project in My Projects
- Drag-and-drop to reorder templates
- Toggle template active/featured status
- View import statistics per template

**Template Data Structure:**
```
content_templates table:
├── slug (unique URL-friendly identifier)
├── card_id (FK → cards table, contains all card data)
├── venue_type (for filtering: museum, restaurant, event, etc.)
├── is_featured, is_active
├── sort_order, import_count
└── created_at, updated_at
```

The linked card contains all the project data:
- Project info: name, description, content_mode, is_grouped, group_display, billing_type
- AI config: ai_instruction, ai_knowledge_base, ai_welcome_general, ai_welcome_item
- Content items: stored in content_items table with hierarchical relationships (parent_id)

**AI Configuration Best Practices:**

When creating templates, optimize the AI fields for proactive guidance:

| Field | Best Practice | Example |
|-------|--------------|---------|
| `ai_instruction` | Define role, tone, expertise, and boundaries | "You are an enthusiastic art docent. Speak with passion. Be approachable. Avoid academic jargon." |
| `ai_knowledge_base` | Include practical info (hours, layout, pricing, tips) | "Gallery hours: 10am-6pm. East wing: paintings. Café near exit. No flash photography." |
| `ai_welcome_general` | **List 3-4 specific capabilities**, end with engaging question | "I can share artwork stories, explain techniques, suggest highlights, or give directions. What draws your attention?" |
| `ai_welcome_item` | **Offer specific information types** for the item, use `{name}` placeholder | "This is \"{name}\" - I can share the artist's inspiration, techniques, historical context, or related works. What interests you?" |

**Pattern:** Instead of generic "Ask me anything", explicitly list what the AI can help with. This guides users who don't know what questions to ask.

**Workflow:**
1. Admin creates a project with desired content in My Projects
2. Admin opens Template Management and clicks "Create Template"
3. Admin selects the project, enters a slug, and optionally sets venue_type and featured status
4. The project is now available in the Template Library for users to import

### Admin Subscription Management

The Admin Portal includes comprehensive **User Subscription Management** capabilities, allowing administrators to view and manage user subscription tiers.

**Features:**

| Feature | Description |
|---------|-------------|
| **Subscription Overview** | View all users with subscription tier, status, and Stripe info |
| **Filter by Tier** | Filter users by Free or Premium subscription tier |
| **Manual Tier Assignment** | Manually set a user's subscription tier (Free or Premium) |
| **Stripe Integration Visibility** | See which subscriptions are Stripe-managed vs admin-managed |
| **Subscription Status** | View status (Active, Canceling, Past Due, Trialing, Canceled) |
| **CSV Export** | Export user data including subscription details |

**User Management Page (Admin > User Management):**

The enhanced User Management page displays:
- **Statistics Cards**: Total Users, Experience Creators, Admins, Premium Users, Free Users
- **Subscription Columns**: Tier (Free/Premium), Subscription Status
- **Actions**: Manage Role button + Manage Subscription button

**Subscription Management Dialog:**

When clicking the subscription management button, admins can:
1. View current subscription info (Stripe ID, period end, cancellation status)
2. Select new tier (Free or Premium) with feature comparison
3. Provide a reason for the change (required, logged for audit)
4. See warnings when modifying Stripe-managed subscriptions

**Admin-Managed vs Stripe-Managed:**
- **Stripe-managed**: User subscribed via Stripe checkout. Admin can view but should use Stripe Dashboard for billing changes.
- **Admin-managed**: Admin manually set the tier. No Stripe billing involved. Period automatically set to 1 year for Premium.

**Stored Procedures:**
- `admin_get_all_users()` - Returns users with subscription data (tier, status, Stripe info)
- `admin_update_user_subscription(user_id, new_tier, reason)` - Manually update subscription tier
- `admin_get_subscription_stats()` - Aggregate subscription statistics for dashboard

**Use Cases:**
- Promotional upgrades (e.g., grant Premium access for a limited time)
- Support cases (e.g., extend Premium for service issues)
- Partner accounts (e.g., provide Premium access to partners)
- Testing (e.g., test Premium features for a specific user)

> **Warning**: Manually changing a Stripe-managed subscription's tier does not affect Stripe billing. Use Stripe Dashboard for billing changes.

**How to Upgrade a User to Premium:**

1. Navigate to **Admin Portal → User Management**
2. Find the user in the table (use search or filter by tier)
3. Click the **subscription icon button** (💳) in the Actions column
4. In the dialog, select **Premium** tier
5. Review the tier comparison showing features unlocked
6. Enter a **reason** for the upgrade (required for audit trail)
7. Click **Update Subscription**

The user will immediately have access to Premium features:
- Up to 15 projects (instead of 3)
- 3,000 monthly access pool (instead of 50)
- Full translation support
- Admin-managed subscriptions are auto-set to 1-year period

### Mobile Client AI Assistants

The mobile client features a **dual AI assistant system** providing context-aware help at different levels:

| Assistant Type | Purpose | Data Sources | Entry Point |
|---------------|---------|--------------|-------------|
| **General Assistant** | Personal concierge - answers ANY question using experience-level knowledge | Experience name, description, AI instruction, AI knowledge base, custom welcome | "AI Chat" button on Overview page |
| **Item Assistant** | Focused guide for specific content items with specialized expertise | Content item name, description, AI knowledge base + inherited parent context + experience AI instruction | Badge button in Content Detail page and Layout views |

**Key Difference:**
- **General Assistant**: Like a service center - can answer any question (directions, general info, recommendations, FAQs)
- **Item Assistant**: Like a specialist - deep knowledge about the specific item being viewed

**Context Inheritance:**
For hierarchical content (e.g., Category → Items), the Item Assistant automatically inherits parent context. When viewing a sub-item, the AI knows both the parent category's knowledge and the specific item's details.

**Content Mode-Aware Context:**

| Mode | Assistants | General Assistant | Item Assistant |
|------|-----------|------------------|----------------|
| **Single** | 1 (Unified) | N/A | Full knowledge base for the single content |
| **Grouped** | 2 | Answers any question with experience knowledge | Focused on item + inherits category context |
| **List** | 2 | Answers any question with experience knowledge | Dedicated guide for specific item |
| **Grid** | 2 | Answers any question with gallery knowledge | Expert on specific artwork/item |
| **Inline** | 2 | Answers any question with experience knowledge | Specialized guide for featured item |

> **Note:** Single mode uses ONE unified AI assistant since there's only one content item.

**AI Assistant Flow by Content Structure:**

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        FLAT CONTENT STRUCTURE                               │
│                    (is_grouped = false, e.g., List/Grid)                    │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌──────────────────┐    ┌──────────────────┐    ┌──────────────────────┐  │
│  │  Card Overview   │───▶│   Content List   │───▶│   Content Detail     │  │
│  │                  │    │    (Flat List)   │    │                      │  │
│  │ ┌──────────────┐ │    │                  │    │  ┌────────────────┐  │  │
│  │ │🟣 AI Card    │ │    │ ┌──────────────┐ │    │  │ Item Name      │  │  │
│  │ │   (tappable) │ │    │ │ 🟣 Floating  │ │    │  ├────────────────┤  │  │
│  │ └──────────────┘ │    │ │    Button    │ │    │  │ Description    │  │  │
│  │                  │    │ └──────────────┘ │    │  │                │  │  │
│  │  Opens General   │    │                  │    │  │ ┌────────────┐ │  │  │
│  │  Assistant       │    │  Opens General   │    │  │ │🟢 Item     │ │  │  │
│  │                  │    │  Assistant       │    │  │ │  Assistant │ │  │  │
│  └──────────────────┘    │                  │    │  │ └────────────┘ │  │  │
│                          │ ┌──────────────┐ │    │  │                │  │  │
│                          │ │🟢 Item Badge │ │    │  │  Opens Item    │  │  │
│                          │ │ (per item)   │ │    │  │  Assistant     │  │  │
│                          │ └──────────────┘ │    │  └────────────────┘  │  │
│                          └──────────────────┘    └──────────────────────┘  │
│                                                                             │
│  🟣 General Assistant = Experience-level knowledge (directions, overview)   │
│  🟢 Item Assistant = Item-specific knowledge (deep expertise on one item)   │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│                      GROUPED CONTENT STRUCTURE                              │
│                    (is_grouped = true, e.g., Museum)                        │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌──────────────────┐    ┌──────────────────┐    ┌──────────────────────┐  │
│  │  Card Overview   │───▶│ Content (Grouped)│───▶│   Content Detail     │  │
│  │                  │    │                  │    │                      │  │
│  │ ┌──────────────┐ │    │ ┌──────────────┐ │    │  ┌────────────────┐  │  │
│  │ │🟣 AI Card    │ │    │ │ 🟣 Floating  │ │    │  │ Item: "Mona    │  │  │
│  │ │   (tappable) │ │    │ │    Button    │ │    │  │       Lisa"    │  │  │
│  │ └──────────────┘ │    │ └──────────────┘ │    │  ├────────────────┤  │  │
│  │                  │    │                  │    │  │ Parent context │  │  │
│  │  Opens General   │    │ ┌ RENAISSANCE ─┐│    │  │ inherited from │  │  │
│  │  Assistant       │    │ │ • Mona Lisa  ││    │  │ "Renaissance"  │  │  │
│  │                  │    │ │ • Last Supper││    │  │ category       │  │  │
│  └──────────────────┘    │ └──────────────┘│    │  │                │  │  │
│                          │                  │    │  │ ┌────────────┐ │  │  │
│                          │ ┌ BAROQUE ─────┐│    │  │ │🟢 Item     │ │  │  │
│                          │ │ • Girl with..││    │  │ │  Assistant │ │  │  │
│                          │ │ • Night Watch││    │  │ └────────────┘ │  │  │
│                          │ └──────────────┘│    │  │                │  │  │
│                          │                  │    │  │  Knows about   │  │  │
│                          │ ┌──────────────┐│    │  │  Mona Lisa +   │  │  │
│                          │ │🟢 Browse AI  ││    │  │  Renaissance   │  │  │
│                          │ │    Badge     ││    │  └────────────────┘  │  │
│                          │ └──────────────┘│    └──────────────────────┘  │
│                          └──────────────────┘                              │
│                                                                             │
│  Context Inheritance: Item Assistant inherits parent category knowledge     │
│  Example: "Mona Lisa" assistant knows about both the painting AND the       │
│  broader "Renaissance" category context from its parent.                    │
└─────────────────────────────────────────────────────────────────────────────┘
```

**Assistant Placement Summary:**

| View | General Assistant | Item Assistant |
|------|-------------------|----------------|
| **Card Overview** | Tappable AI card in info panel | Not available |
| **Navigation Pages** (List, Grid, Grouped, Inline) | Browse badge at bottom ("Tap to chat with your AI guide") | Not available |
| **Content Detail** | Not shown | Badge below content description |

> **Note:** Navigation pages use the **General Assistant** because users are browsing and more likely to ask general questions like "What should I see first?" or "Where is the most popular item?". The **Item Assistant** is only shown on the Content Detail page where users are viewing a specific item and want item-specific information.

**Knowledge Scope:**

| Assistant | Data Sources | Use Case |
|-----------|--------------|----------|
| **General** | `card_name`, `card_description`, `ai_instruction`, `ai_knowledge_base` | "Where is the restroom?", "What are the highlights?", "How long is the tour?" |
| **Item** | `content_item_name`, `content_item_content`, `content_item_ai_knowledge_base` + parent context | "Who painted this?", "What technique was used?", "What's the history?" |

**Custom Welcome Messages:**

Experience creators can configure custom welcome messages in the experience settings:
- `ai_welcome_general`: Custom greeting for the General AI Assistant (experience-level)
- `ai_welcome_item`: Custom greeting for Content Item AI Assistant (supports `{name}` placeholder for item name)

| Mode | How Custom Welcome Is Used |
|------|---------------------------|
| **Text Chat** | Displayed directly as the initial assistant message |
| **Voice Assistant** | Used as **guidance/reference** - AI generates a natural spoken greeting informed by the welcome message's tone, topics, and suggestions |

For voice conversations, the AI doesn't recite the welcome message verbatim. Instead, it uses the message to understand:
- What tone/personality to use
- What specific topics or features to highlight
- What questions or options to suggest to users

This ensures the greeting sounds natural for voice while reflecting the creator's intent.

**System Prompt Strategy:**
- Experience-Level: Uses experience's `ai_instruction` as role definition, `ai_knowledge_base` for background knowledge, encourages general exploration
- Content Item: Focuses on the specific item, includes parent context for sub-items, mode-specific context guidance

**Proactive AI Guidance:**

The AI assistants are designed to be **proactive guides**, not passive responders. This addresses the common issue where users don't know what they can ask or what information is available.

| Behavior | Description |
|----------|-------------|
| **Initial Greeting** | When starting a realtime voice conversation, the AI proactively suggests 2-3 specific things users can ask about based on its knowledge base |
| **Contextual Suggestions** | AI offers concrete examples like "I can tell you about the artist's techniques, the inspiration behind this work, or interesting stories from its history" |
| **Anticipatory Guidance** | When users seem unsure, AI says things like "Many visitors also ask about..." or "I can also tell you about..." |
| **Unprompted Insights** | AI shares interesting facts, recommendations, or tips when relevant without waiting for specific questions |

Example proactive greeting for a museum exhibit:
> "Hi! I'm your personal guide for the Renaissance Gallery. I can share stories about these masterpieces, explain the artists' techniques, or recommend what to see next. What interests you most?"

This ensures users immediately understand the AI's capabilities and feel confident asking questions.

**Assistant Trigger UI:**

The AI assistants are designed with high-visibility entry points to encourage engagement:

| Assistant | Trigger Element | Visual Design |
|-----------|-----------------|---------------|
| **General Assistant** | Floating button (all content pages) + Tappable card on Overview | Purple gradient pill with "Ask AI" label, pulsing attention rings, slide-up animation |
| **Item Assistant** | Badge button within content detail | Emerald-cyan gradient with shimmer effect, icon + text + arrow layout |

The CardOverview page features an enhanced AI indicator that replaces the static text with a tappable card showing:
- Gradient icon with sparkles
- "AI Voice Guide Available" title
- "Tap to chat with your AI guide" subtitle
- Chevron arrow indicating interactivity

Both assistants support:
- Text chat with streaming responses
- Voice recording with transcription
- Real-time voice conversation (WebRTC)
- Multi-language support with dialect awareness (Cantonese vs Mandarin for Chinese)

---

## Core Architecture

The project follows a modern web architecture with a decoupled frontend, backend, and database.

### 1. Frontend (Vue 3)

-   **Framework**: Vue 3 with Composition API and TypeScript
-   **UI**: PrimeVue 4 and Tailwind CSS
-   **State Management**: Pinia
-   **Routing**: Vue Router
-   **Build Tool**: Vite

### 2. Backend (Express.js)

The backend is an Express.js server located in the `backend-server/` directory. It handles all business logic that requires secure, server-side execution.

-   **Framework**: Express.js with TypeScript
-   **Authentication**: JWT validation via middleware, integrated with Supabase Auth.
-   **Caching**: Upstash Redis for mobile client content caching, scan deduplication, and rate limiting.
-   **Key Services**:
    -   Content translation (Google Gemini)
    -   Payment processing (Stripe checkout and webhooks)
    -   AI chat and voice features (OpenAI)
    -   Ephemeral token generation for WebRTC connections
    -   Mobile client API with Redis caching (public card access)

### 3. Database & Services (Supabase)

-   **Database**: Supabase PostgreSQL for all data storage.
-   **Database Access**: All database operations are exclusively handled via `supabase.rpc()` calls to stored procedures. **Direct table access is disabled for security.**
-   **Authentication**: Supabase Auth for user management and JWT issuance.
-   **Storage**: Supabase Storage for user-uploaded images (experience images, content images).

---

## Local Development Setup

### Prerequisites

-   Node.js (v18+)
-   Supabase CLI (`npm install -g supabase`)
-   Stripe CLI (for webhook testing)

### Step 1: Clone and Install Dependencies

```bash
git clone <repo-url>
cd Cardy

# Install frontend dependencies
npm install

# Install backend dependencies
cd backend-server
npm install
cd ..
```

### Step 2: Configure Environment Variables

You will need to configure `.env` files for both the frontend and backend.

**Frontend (`.env`):**

```bash
# In the root directory
cp .env.example .env
```

Edit the `.env` file and set your Supabase and Stripe public keys.

**Backend (`backend-server/.env`):**

```bash
# In the backend-server directory
cd backend-server
cp .env.example .env
```

Edit the `.env` file and set all required API keys and secrets:
-   `OPENAI_API_KEY` - Your OpenAI API key for AI chat and voice features
-   `SUPABASE_URL` - Your Supabase project URL
-   `SUPABASE_SERVICE_ROLE_KEY` (⚠️ **CRITICAL: Keep this secret!**)
-   `STRIPE_SECRET_KEY` - Your Stripe secret key for payment processing
-   `STRIPE_WEBHOOK_SECRET` - Your Stripe webhook secret for webhook validation

**Redis Configuration** (for mobile client caching):
-   `UPSTASH_REDIS_REST_URL` - Your Upstash Redis REST URL
-   `UPSTASH_REDIS_REST_TOKEN` - Your Upstash Redis token
-   `CACHE_CARD_CONTENT_TTL=300` - Card content cache duration in seconds (default: 5 minutes)
-   `SCAN_DEDUP_WINDOW_SECONDS=300` - Scan deduplication window (default: 5 minutes)

See `backend-server/ENVIRONMENT_VARIABLES.md` for complete documentation of all configuration options.

### Step 3: Start Local Services

1.  **Start Local Supabase**:
    ```bash
    supabase start
    # Note the local URL and keys, update frontend .env if needed
    ```

2.  **Apply Database Schema**:
    ```bash
    # Run schema.sql in Supabase SQL Editor
    # This creates all tables, indexes, and RLS policies
    ```

3.  **Start Backend Server**:
    ```bash
    cd backend-server
    npm run dev
    # Server will run on the port specified in .env (default: http://localhost:8080)
    # Watch for: ✅ Supabase admin client initialized
    #            [Redis] Connected to Upstash Redis
    ```

4.  **Start Frontend Development Server**:
    ```bash
    # From the root directory
    npm run dev
    # Frontend will be available at http://localhost:5173
    ```

---

## Project Structure

```
Cardy/
├── backend-server/    # Express.js Backend
│   ├── src/
│   │   ├── routes/         # API routes (translation, payment, ai, webhooks, mobile)
│   │   ├── services/       # Business logic services
│   │   │   └── gemini-client.ts              # Google Gemini API client
│   │   ├── middleware/     # Auth & rate limiting middleware
│   │   ├── config/         # Supabase & Redis configuration
│   │   └── index.ts        # Server entry point
│   ├── Dockerfile          # For Cloud Run deployment
│   ├── deploy-cloud-run.sh # All-in-one deployment script
│   ├── ENVIRONMENT_VARIABLES.md     # Complete env var documentation
│   ├── REALTIME_JOB_PROCESSOR.md    # Realtime implementation guide
│   └── package.json
│
├── public/                 # Static assets for frontend
├── src/                    # Vue.js Frontend Source
│   ├── assets/
│   ├── components/
│   │   ├── Card/
│   │   │   ├── TranslationDialog.vue         # Translation dialog
│   │   │   └── CardTranslationSection.vue    # Translation section
│   ├── services/
│   │   └── mobileApi.ts    # Mobile client API service (routes through Express)
│   ├── stores/             # Pinia stores
│   ├── utils/
│   ├── views/
│   └── main.ts
│
├── sql/                    # Database Schema & Stored Procedures
│   ├── schema.sql          # All tables, enums, indexes
│   ├── all_stored_procedures.sql  # GENERATED - Do not edit directly
│   ├── storeproc/          # Source files for stored procedures
│   │   ├── client-side/    # Client-accessible procedures (via anon/authenticated)
│   │   └── server-side/    # Backend-only procedures (service role only)
│   │       └── mobile_access.sql  # Credit consumption, card access
│   ├── policy.sql          # RLS policies
│   └── triggers.sql        # Database triggers (includes updated_at triggers)
│
├── supabase/               # Supabase local configuration
│   └── config.toml
│
├── scripts/                # Utility scripts
│   ├── combine-storeproc.sh  # Combines SQL files (includes triggers)
│   └── deploy-cloud-run.sh   # Backend deployment script
│
├── docs_archive/           # Historical documentation and logs
│   ├── backend/            # Backend-specific archival docs
│   └── ...                 # Feature implementation details, bug fixes logs
│
├── CLAUDE.md               # AI assistant project overview and recent updates
├── .env.example            # Frontend environment template
└── package.json            # Frontend dependencies
```

---

## Maintenance & Handover

### Documentation Strategy
-   **Active Documentation**: `README.md` (this file) and `CLAUDE.md` (recent updates/context) are the primary sources of truth.
-   **Historical Documentation**: Detailed implementation logs, feature specs, and bug fix reports are archived in the `docs_archive/` directory. Refer to these for deep dives into specific past decisions.

### Security Best Practices
-   **HTML Sanitization**: The project uses `dompurify` in `src/utils/markdownRenderer.ts` to sanitize HTML rendered from Markdown. Always use `renderMarkdown()` when displaying user-generated content.
-   **Environment Variables**: Never commit `.env` files. Use `.env.example` for templates.
-   **Database Access**: All database access is via Stored Procedures (`.rpc()`). Direct table access (SELECT/INSERT/UPDATE/DELETE) should remain disabled for the `anon` and `authenticated` roles in production to ensure business logic encapsulation.

### Common Maintenance Tasks
-   **Updating Database Schema**:
    1.  Modify files in `sql/` (schema or storeproc).
    2.  Run `./scripts/combine-storeproc.sh` to regenerate `all_stored_procedures.sql`.
    3.  Apply changes via Supabase Dashboard SQL Editor.
-   **Adding New Translations**: Update `src/i18n/locales/*.json` files.
-   **Updating Backend**:
    1.  Make changes in `backend-server/`.
    2.  Test locally with `npm run dev`.
    3.  Deploy using `./scripts/deploy-cloud-run.sh`.

---

## Translation System

ExperienceQR uses a **synchronous translation system** powered by Google Gemini that provides fast, reliable translations with immediate feedback.

### Architecture

**Mode: Synchronous Processing via Express Backend**

-   **Engine**: Google Gemini 2.5 Flash-Lite for fast, accurate translations
-   **Concurrency**: Up to 3 languages processed simultaneously
-   **Batching**: 10 content items per batch for optimal API performance
-   **Reliability**: Immediate feedback with error handling per language

### Key Features

✅ **Synchronous Processing** - Translations complete in a single request with progress feedback  
✅ **Concurrent Processing** - Up to 3 languages processed simultaneously  
✅ **Batch Processing** - 10 content items per batch for optimal API performance  
✅ **Credit Safety** - Credits consumed only after successful translation  
✅ **Error Recovery** - Failed languages can be retried individually  
✅ **Translation Management** - UI for viewing, deleting, and retranslating content

### Documentation Links (Archived)

For detailed implementation details, refer to the following files in `docs_archive/`:
-   **`GEMINI_TRANSLATION_MIGRATION.md`** - Migration from OpenAI to Google Gemini
-   **`CONCURRENT_TRANSLATION_FEATURE.md`** - Concurrent language processing
-   **`TRANSLATION_HASH_FRESHNESS_FIX.md`** - Translation status tracking

For current backend configuration, see:
-   **`backend-server/ENVIRONMENT_VARIABLES.md`** - All configuration options

### Monitoring

**Watch these logs:**

```bash
# Healthy translation processing
📝 Translation request from user [id] for card [id]
   Languages: zh-Hant, ja, ko, Force: false
🌐 Processing language: zh-Hant (1/3)
✅ Translation complete: 3 languages, 15 items
```

---

## Deployment

The project is deployed in two parts: the backend to **Google Cloud Run** and the frontend to a **static host** (like Vercel or Netlify).

### Backend Deployment (Google Cloud Run)

The `backend-server/` directory contains the source code, but the deployment script is now centralized in the `scripts/` directory.

**Prerequisites**:
-   Google Cloud SDK (`gcloud`) installed and authenticated.
-   Your backend `.env` file is correctly configured with all production keys.

**To Deploy:**

```bash
./scripts/deploy-cloud-run.sh
```

The script will guide you through the process:
1.  Prompts for your **GCP Project ID** and **Region**.
2.  Builds the Docker container using `Dockerfile`.
3.  Pushes the container to Google Container Registry.
4.  Deploys the container to Cloud Run.
5.  **Automatically uploads all environment variables** from your `.env` file to the Cloud Run service.
6.  Tests the health endpoint and provides you with the final service URL.

After deployment, update your frontend's `.env` file with the new production `VITE_BACKEND_URL`.

**Redis Configuration**: Ensure your Upstash Redis credentials are set in the Cloud Run environment variables for mobile client caching and rate limiting.

### Frontend Deployment

1.  **Build for Production**:
    ```bash
    npm run build
    ```
2.  **Deploy**: Deploy the generated `dist/` directory to your preferred static hosting provider (Vercel, Netlify, etc.).
3.  **Environment Variables**: Ensure your hosting provider is configured with the production environment variables from your `.env` file, especially:
    -   `VITE_SUPABASE_URL`
    -   `VITE_SUPABASE_ANON_KEY`
    -   `VITE_BACKEND_URL` (from the backend deployment step)
    -   `VITE_STRIPE_PUBLISHABLE_KEY`
    -   `VITE_APP_URL` (Optional: Set to your custom domain like `https://cardstudio.org` for SEO)

### SEO Configuration

The frontend includes a comprehensive SEO optimization system that generates dynamic meta tags, Open Graph tags, and structured data.

1.  **Automatic sitemap**: `public/sitemap.xml` is generated and should be submitted to Google Search Console.
2.  **Robots.txt**: `public/robots.txt` guides search engine crawlers.
3.  **Domain Configuration**: Update `VITE_APP_URL` in your production `.env` to your custom domain (e.g., `https://cardstudio.org`) to ensure Canonical URLs are correct.
4.  **Hosting Configuration**: The `firebase.json` is pre-configured with optimal caching headers for static assets (`max-age=31536000`).
