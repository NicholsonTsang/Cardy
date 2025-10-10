# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

CardStudio is a comprehensive **digital souvenir and exhibition platform** that creates interactive experiences for museums, tourist attractions, and cultural sites. The platform enables institutions to provide visitors with rich, AI-powered digital content accessible through QR codes on physical souvenir cards, offering detailed explanations, guidance, and multimedia experiences about exhibits, artifacts, and locations.

### Business Model & Architecture

**Three-Tier Ecosystem:**
1. **Card Issuers** (B2B) - Museums, exhibitions, tourist attractions creating digital souvenir experiences ($2/card)
2. **Administrators** (Platform) - CardStudio operators managing verifications and operations  
3. **Visitors** (B2C) - Tourists and museum guests scanning QR codes for free digital content and AI guidance

**Core Value Proposition:**
- **Interactive Digital Souvenirs**: Physical cards with QR codes link to rich multimedia content about exhibits and locations
- **Batch-Based Pricing**: Institutions pay $2 USD per card when creating souvenir batches (no monthly subscriptions)
- **Advanced AI Voice Conversations**: Real-time voice-based AI using OpenAI Realtime API for natural conversations about exhibits
- **Multi-Language Support**: AI guidance available in English, Cantonese, Mandarin, Spanish, and French
- **Professional Souvenir Printing**: High-quality physical souvenir cards with global shipping to institutions

### Target Markets & Use Cases

**1. Museums & Art Galleries**
- **Use Case**: Interactive digital souvenirs for exhibits, artifacts, and collections
- **Benefits**: AI-powered explanations, detailed multimedia content, visitor engagement tracking
- **Example**: Natural history museum cards with AI explaining dinosaur fossils and geological specimens

**2. Tourist Attractions & Landmarks**
- **Use Case**: Enhanced visitor experiences with rich historical and cultural context
- **Benefits**: Multi-language AI guidance, scenic spot details, historical narratives
- **Example**: Historic castle cards with AI tour guide explaining architecture and royal history

**3. Cultural Heritage Sites**
- **Use Case**: Digital preservation and interpretation of cultural significance
- **Benefits**: Immersive storytelling, educational content, cultural context preservation
- **Example**: Ancient temple cards with AI explaining religious practices and architectural significance

**4. Exhibition Centers & Trade Shows**
- **Use Case**: Interactive exhibitor content and educational materials
- **Benefits**: Product explanations, technical details, engagement analytics
- **Example**: Science fair cards with AI explaining experiments and scientific principles

**5. Theme Parks & Entertainment Venues**
- **Use Case**: Collectible digital souvenirs with entertainment content
- **Benefits**: Behind-the-scenes content, character interactions, memorable experiences
- **Example**: Theme park cards with AI character conversations and attraction history

CardStudio is built with Vue 3 + TypeScript, using PrimeVue UI components, Pinia for state management, Tailwind CSS for styling, and Supabase as the backend with PostgreSQL database.

## Core Architecture

### Frontend Stack
- **Vue 3** with Composition API and TypeScript
- **PrimeVue 4** for UI components with custom theming
- **Pinia** for state management
- **Vue Router** for navigation
- **Tailwind CSS** for styling with custom design system
- **Vite** for build tooling

### Backend Stack
- **Supabase** (PostgreSQL database + Auth + Storage + Edge Functions)
- **Stored procedures** in `sql/storeproc/` for ALL database operations
- **RLS policies** for data security
- **No direct table access** - all queries use `supabase.rpc()` calls
- **Stripe** integration for payments (via Edge Functions)
- **OpenAI Realtime API** integration via WebRTC for voice-based AI conversations
- **Edge Functions** for AI token management and API integrations
- **Ephemeral tokens** for secure, temporary OpenAI connections

## Key Commands

```bash
# Frontend Development
npm run dev                 # Start development server (uses .env.local)
npm run dev:local          # Start local development server
npm run build              # Build for production
npm run build:production   # Build for production with production env
npm run type-check         # Run TypeScript type checking
npm run preview            # Preview production build

# Database Operations
supabase start             # Start local Supabase
supabase stop              # Stop local Supabase
supabase db reset          # Reset local database (runs migrations)
supabase gen types typescript --local > src/types/supabase.ts  # Generate TypeScript types

# Database Deployment (Manual via Supabase Dashboard)
# 1. Navigate to SQL Editor in Supabase Dashboard
# 2. Copy contents of sql/schema.sql and execute
# 3. Copy contents of sql/all_stored_procedures.sql and execute
# 4. Copy contents of sql/policy.sql and execute
# 5. Copy contents of sql/triggers.sql and execute

# Edge Functions
npx supabase functions serve                    # Run all functions locally
npx supabase functions serve <function-name>    # Run specific function locally
npx supabase functions deploy <function-name>   # Deploy specific function
./scripts/deploy-edge-functions.sh              # Deploy all functions at once

# Edge Function Secrets (Production)
npx supabase secrets set OPENAI_API_KEY=sk-...
npx supabase secrets set STRIPE_SECRET_KEY=sk_live_...
npx supabase secrets set OPENAI_REALTIME_MODEL=gpt-realtime-mini-2025-10-06

# View Edge Function Logs
npx supabase functions logs <function-name>     # View logs for specific function
npx supabase functions logs <function-name> --follow  # Stream logs in real-time
```

## Important File Structure

```
src/
├── components/                    # Reusable Vue components
│   ├── Admin/                     # Admin-specific components
│   │   ├── AdminCardContent.vue   # Admin card content viewer
│   │   ├── AdminUserManagement.vue # User management interface
│   │   └── AdminPrintRequests.vue # Print request management
│   ├── CardComponents/            # Card-related components
│   │   ├── CardCreateEditForm.vue # Card creation/editing
│   │   └── CardView.vue           # Card display/preview
│   ├── CardContent/               # Content management components
│   │   ├── CardContentCreateEditForm.vue # Content creation/editing
│   │   ├── CardContentView.vue    # Content display
│   │   └── ContentItemsList.vue   # Hierarchical content list
│   ├── Layout/                    # Layout components
│   │   ├── AppHeader.vue          # Main dashboard header
│   │   └── Sidebar.vue            # Dashboard sidebar navigation
│   ├── DashboardLanguageSelector.vue # Dashboard language selector
│   └── ...                        # Other shared components
│
├── views/                         # Page-level components
│   ├── Dashboard/                 # Main dashboard views
│   │   ├── Admin/                 # Admin panel views
│   │   │   ├── AdminDashboard.vue # Admin overview
│   │   │   ├── UserManagement.vue # User verification
│   │   │   └── PrintRequests.vue  # Print request management
│   │   └── CardIssuer/            # Card issuer views
│   │       ├── MyCards.vue        # Card management
│   │       ├── CardIssuance.vue   # Batch issuance
│   │       └── Analytics.vue      # Usage analytics
│   │
│   └── MobileClient/              # Mobile card viewing (QR scan experience)
│       ├── PublicCardView.vue     # Main mobile card viewer
│       └── components/
│           ├── MobileHeader.vue             # Mobile header with back button
│           ├── CardOverview.vue             # Card landing page
│           ├── ContentList.vue              # Content items list
│           ├── ContentDetail.vue            # Content item detail view
│           ├── LanguageSelector.vue         # Mobile header language selector
│           ├── LanguageSelectorModal.vue    # Card overview language selector
│           └── AIAssistant/                 # AI conversation system
│               ├── MobileAIAssistant.vue    # Main AI assistant wrapper
│               ├── components/
│               │   ├── AIAssistantModal.vue     # Modal container
│               │   ├── ChatInterface.vue        # Chat completion UI
│               │   ├── RealtimeInterface.vue    # Realtime audio UI
│               │   └── LanguageSelector.vue     # (Deprecated - language now global)
│               ├── composables/
│               │   ├── useWebRTCConnection.ts   # WebRTC Realtime API
│               │   ├── useChatCompletion.ts     # Chat API integration
│               │   ├── useVoiceRecording.ts     # Voice recording logic
│               │   ├── useCostSafeguards.ts     # Cost protection
│               │   └── useInactivityTimer.ts    # Inactivity detection
│               ├── types/index.ts               # TypeScript types
│               └── index.ts                     # Component exports
│
├── stores/                        # Pinia stores for global state
│   ├── language.ts                # Language management (mobile & dashboard)
│   ├── auth.ts                    # Authentication state
│   ├── cards.ts                   # Card management
│   └── ...                        # Other stores
│
├── i18n/                          # Internationalization
│   ├── index.ts                   # i18n configuration
│   └── locales/
│       ├── en.json                # English translations
│       ├── zh-Hant.json           # Traditional Chinese (繁體中文)
│       └── zh-Hans.json           # Simplified Chinese (简体中文)
│
├── lib/                           # Core libraries
│   └── supabase.ts                # Supabase client initialization
│
├── utils/                         # Helper functions
│   ├── cardConfig.ts              # Card aspect ratio utilities
│   ├── excelHandler.js            # Excel import/export
│   └── ...                        # Other utilities
│
└── router/                        # Vue Router configuration
    └── index.ts                   # Route definitions

sql/
├── schema.sql                     # Database schema (tables, enums, indexes)
├── all_stored_procedures.sql      # Combined stored procedures for deployment
├── storeproc/                     # Modular stored procedures
│   ├── client-side/               # Frontend-callable procedures
│   │   ├── 01_auth_functions.sql         # Authentication
│   │   ├── 02_card_management.sql        # Card CRUD
│   │   ├── 03_content_management.sql     # Content CRUD
│   │   ├── 04_batch_management.sql       # Batch issuance
│   │   ├── 06_print_requests.sql         # Print requests
│   │   ├── 07_public_access.sql          # Public card access
│   │   ├── 08_user_profiles.sql          # User profiles
│   │   ├── 09_user_analytics.sql         # Analytics
│   │   ├── 11_admin_functions.sql        # Admin operations
│   │   └── execute_all.sql               # Execute all client-side
│   └── server-side/               # Edge Function procedures
│       ├── 05_payment_management.sql     # Stripe payments
│       └── execute_server_side.sql       # Execute all server-side
├── triggers.sql                   # Database triggers
├── policy.sql                     # RLS policies
└── migrations/                    # Database migrations

supabase/
├── functions/                     # Edge Functions
│   ├── create-checkout-session/  # Stripe checkout
│   ├── process-payment/           # Stripe webhooks
│   ├── chat-with-audio/           # Chat completion (text/voice)
│   ├── chat-with-audio-stream/    # Streaming chat responses
│   ├── generate-tts-audio/        # Text-to-speech
│   ├── openai-realtime-token/     # Realtime API ephemeral tokens
│   └── _shared/                   # Shared utilities (CORS, etc.)
└── config.toml                    # Supabase configuration + secrets
```

## Critical Design Specifications

### Card Image Aspect Ratio
- **Cards must maintain 2:3 aspect ratio (width:height)**
- Use `aspect-ratio: 2/3` in CSS, not `3/4`
- Standard card dimensions: 240px × 360px or similar proportions

### Component Architecture Guidelines
- Large components (>400 lines) should be broken down
- Separate concerns: data fetching, UI rendering, business logic
- Use composition functions for reusable logic
- Maintain consistent error handling patterns

### State Management Patterns
- Use Pinia stores for global state
- Local `ref()` for component-specific state
- Consistent naming: `loading`, `error`, `data`
- Always handle error states with user feedback

### Language & Internationalization System

**Two Independent Language Stores:**
- **`useMobileLanguageStore`** - For mobile client (QR scan experience)
- **`useDashboardLanguageStore`** - For CMS/Dashboard (card issuer interface)
- **Independence**: Changing language in one context does not affect the other

**Language Selectors:**
- **Mobile Client**: 
  - `LanguageSelector.vue` in `MobileHeader` (top-right icon)
  - `LanguageSelectorModal.vue` in `CardOverview` (language chip)
  - Bottom sheet modal design on mobile, centered modal on desktop
- **Dashboard**: 
  - `DashboardLanguageSelector.vue` in `AppHeader` (top-right)
  - Bottom sheet modal design

**Language Store Integration:**
```typescript
// Mobile Client
import { useMobileLanguageStore } from '@/stores/language'
const languageStore = useMobileLanguageStore()

// Dashboard
import { useDashboardLanguageStore } from '@/stores/language'
const languageStore = useDashboardLanguageStore()

// Change language (automatically updates i18n locale)
languageStore.setLanguage(languageCode)

// Access current language
const currentLanguage = languageStore.selectedLanguage // { code, name, flag }
```

**i18n Usage:**
```typescript
import { useI18n } from 'vue-i18n'
const { t } = useI18n()

// In template
{{ $t('common.save') }}
{{ $t('dashboard.card_created') }}
{{ $t('mobile.explore_content') }}

// Pluralization (use pipe syntax, not ICU)
"sub_items_count": "{count} sub-item | {count} sub-items"
```

**Translation Keys Structure:**
- `common.*` - Shared across all contexts
- `dashboard.*` - Dashboard/CMS specific
- `mobile.*` - Mobile client specific
- `auth.*` - Authentication related
- `errors.*` - Error messages

**Supported Languages:**
- English (`en`)
- Traditional Chinese (`zh-Hant`, 繁體中文)
- Simplified Chinese (`zh-Hans`, 简体中文)

**Best Practices:**
- Always use `$t()` or `t()` for user-facing text
- Never hardcode English text in templates
- Use pipe syntax for pluralization in Vue i18n, not ICU message format
- Test language switching in both mobile and dashboard contexts independently
- Ensure translation keys exist in all language files

### Markdown Rendering

**Card Descriptions:**
- Card descriptions (`card_description` field) support **markdown formatting**
- Rendered using `marked` library (no sanitization needed for trusted content)
- Displayed with rich formatting in `CardOverview.vue`

**Content Items:**
- Content item descriptions (`content_item_content` field) support **markdown formatting**
- Rendered in `ContentDetail.vue` using `marked`
- Supports bold, italic, links, lists, headings, code, blockquotes

**Markdown Implementation:**
```typescript
import { marked } from 'marked'

const renderedContent = computed(() => {
  if (!content.value) return ''
  return marked(content.value)
})
```

**Supported Markdown:**
- **Bold**: `**text**`
- *Italic*: `*text*`
- [Links](url): `[text](url)`
- Lists: `- item` or `1. item`
- Headings: `# H1`, `## H2`, `### H3`
- `Inline code`: `` `code` ``
- > Blockquotes: `> quote`

**Styling:**
- White text on dark backgrounds
- Links in light blue (`#93c5fd`)
- Code with semi-transparent backgrounds
- Proper spacing and margins
- Mobile-optimized font sizes

## Mobile Client Architecture

### Overview
The Mobile Client (`src/views/MobileClient/`) provides the end-user experience for visitors scanning QR codes on physical souvenir cards. It's a fully responsive, mobile-first interface optimized for smartphones and tablets.

### Main Component: PublicCardView.vue
**Purpose**: Main container component that orchestrates the entire mobile experience

**Key Features:**
- **Route Handling**: Supports both activated cards (`/c/:cardId`) and preview mode (`/preview/:cardId`)
- **View State Management**: Three-view navigation system (card → content list → content detail)
- **Navigation Stack**: Tracks user navigation for proper back button behavior
- **Loading & Error States**: Graceful handling of loading states and error conditions

**View Types:**
1. **Card View** (`isCardView`) - Landing page showing card overview
2. **Content List View** (`isContentListView`) - List of top-level content items
3. **Content Detail View** (`isContentDetailView`) - Detailed view of specific content item with sub-items

### Component Hierarchy

```
PublicCardView.vue (Main Container)
├── MobileHeader.vue (Navigation header, shown in list & detail views)
│   └── LanguageSelector.vue (Language selection in header)
│
├── CardOverview.vue (Card landing page)
│   ├── Language chip button (triggers language selector)
│   └── LanguageSelectorModal.vue (Bottom sheet language selector)
│
├── ContentList.vue (List of content items)
│   └── ContentItem cards (clickable items)
│
└── ContentDetail.vue (Content item detail)
    ├── Content description (markdown rendered)
    ├── Content image (with aspect ratio handling)
    ├── Sub-items list (if parent item)
    └── MobileAIAssistant.vue (AI conversation interface)
```

### Mobile Client Components

**1. MobileHeader.vue**
- Fixed header with back button, title, and language selector
- Glassmorphism design (blur + transparency)
- Emits `@back` event for navigation
- Shows title and optional subtitle

**2. CardOverview.vue**
- Full-screen landing page with card image and description
- **Language selection chip** in info panel
- **Markdown-rendered description** with rich formatting
- "Explore Contents" button to view content list
- Gradient overlay for text readability
- Responsive design for various screen sizes

**3. ContentList.vue**
- Grid layout of content items with images
- Hierarchical display (shows parent items with sub-item counts)
- Click to navigate to detail view
- Loading state while fetching data

**4. ContentDetail.vue**
- Full content item display with image and description
- **Markdown-rendered content** for rich text formatting
- Sub-items list for hierarchical content
- **AI Assistant integration** for conversation about content
- Smooth transitions between content items

**5. LanguageSelector.vue** (Mobile Header)
- Icon button in mobile header (top-right)
- Bottom sheet modal on mobile
- Centered modal on desktop
- Updates global mobile language store

**6. LanguageSelectorModal.vue** (Card Overview)
- Modal-only component (no trigger button)
- Bottom sheet design matching header selector
- Triggered by language chip in CardOverview
- Emits `@select` and `@close` events

### Navigation Flow

```
1. User scans QR code → PublicCardView loads
2. CardOverview displays (view = 'card')
3. User clicks "Explore Contents"
   → ContentList displays (view = 'content-list')
   → Navigation stack: [{ view: 'card', content: null }]
4. User selects a content item
   → ContentDetail displays (view = 'content-detail')
   → Navigation stack: [{ view: 'card', content: null }, { view: 'content-list', content: null }]
5. User clicks back in MobileHeader
   → Navigate back through stack
   → ContentList displays
6. User selects sub-item in ContentDetail
   → ContentDetail updates with new content
   → Navigation stack grows
7. User can always return to CardOverview via back button
```

### Language Selection Flow

```
1. User lands on CardOverview
2. Two language selection entry points:
   a) Language chip in CardOverview info panel
   b) Globe icon in MobileHeader (on list/detail views)
3. User selects language from bottom sheet modal
4. Language updates in useMobileLanguageStore
5. i18n locale automatically updates via setLocale()
6. All UI text and AI conversations follow selected language
7. Language persists across views and sessions (localStorage)
```

### Data Fetching

**PublicCardView.vue** handles all data fetching:
```typescript
// Fetch card data
const { data: cardData, error } = await supabase.rpc('get_public_card_by_id', {
  p_card_id: route.params.cardId
})

// Fetch content items (hierarchical)
const { data: contentItems } = await supabase.rpc('get_public_content_items', {
  p_card_id: route.params.cardId
})

// Computed properties
const topLevelContent = computed(() => 
  contentItems.value.filter(item => !item.content_item_parent_id)
)

const subContent = computed(() =>
  contentItems.value.filter(item => 
    item.content_item_parent_id === selectedContent.value?.content_item_id
  )
)
```

### Mobile Optimization

**Performance:**
- Lazy loading of images
- Optimized asset sizes
- Minimal JavaScript bundle
- Fast initial render

**UX:**
- Touch-friendly targets (min 44px)
- Smooth transitions (view-transition animation)
- Responsive images with proper aspect ratios
- Bottom sheet modals for mobile-native feel
- Glassmorphism for modern aesthetic

**Accessibility:**
- Semantic HTML structure
- ARIA labels where needed
- Keyboard navigation support
- High contrast text
- Touch gesture support

### Integration Points

**1. AI Assistant Integration:**
- `ContentDetail.vue` embeds `MobileAIAssistant.vue`
- AI receives content context (name, description, knowledge base)
- Language automatically follows `useMobileLanguageStore`
- Supports both chat and realtime conversation modes

**2. Language System:**
- Independent from dashboard language
- Persists in localStorage
- Updates i18n locale automatically
- Affects all UI text and AI conversations

**3. Analytics:**
- Card scans tracked via database
- Content views logged
- AI interaction metrics captured

## AI Infrastructure & Architecture

### Three AI Conversation Modes

CardStudio offers three distinct modes for AI-powered conversations with exhibits:

| Mode | API | Input | Output | Best For | Status |
|------|-----|-------|--------|----------|--------|
| **Chat Completion** | Chat Completions API | Text + Voice (transcribed) | Text + TTS | Default, cost-effective conversations | ✅ Live |
| **Real-Time Audio** | Realtime API + WebRTC | Live Audio Stream | Live Audio Stream | Natural, low-latency voice calls | 🎨 UI Complete |

### Chat Completion Mode (Current Default)

**Technology Stack:**
- OpenAI Chat Completions API (`gpt-4o-mini`)
- Whisper API for Speech-to-Text (STT)
- OpenAI TTS API for Text-to-Speech
- Server-Sent Events (SSE) for text streaming

**Edge Functions:**
- `chat-with-audio/` - Handles text/voice input, AI generation, and transcription
- `chat-with-audio-stream/` - Streaming text responses
- `generate-tts-audio/` - On-demand audio generation with caching

**Features:**
- ✅ Text and voice input with inline switching
- ✅ Streaming text responses for fast feedback
- ✅ Audio playback with caching (language-aware)
- ✅ Cost-optimized: ~7x cheaper than audio model
- ✅ Multi-language support (10 languages)

### Real-Time Audio Mode (WebRTC Direct Connection)

**Technology Stack:**
- OpenAI Realtime API (`gpt-realtime-mini-2025-10-06`)
- **WebRTC** for direct peer-to-peer connection to OpenAI
- **Ephemeral tokens** for secure, temporary authentication
- PCM16 audio format (24kHz sample rate)
- **RTCPeerConnection** and **RTCDataChannel** for bidirectional communication

**Edge Functions:**
- `openai-realtime-token/` - Generates ephemeral tokens for secure WebRTC connections
- Token lifespan: ~60 seconds (refresh on each connection)
- **Model Configuration**: Centralized in Edge Function via `OPENAI_REALTIME_MODEL` environment variable

**Features:**
- ✅ ChatGPT-style live conversation UI
- ✅ Animated waveform visualization
- ✅ Connection state management
- ✅ **Live transcript display** (both user and AI speech)
- ✅ Status indicators and animations
- ✅ **WebRTC bidirectional audio streaming** (no relay server needed)
- ✅ Direct peer-to-peer connection to OpenAI
- ✅ **AI initiates conversation** with greeting in selected language
- ✅ Barge-in detection (interrupt AI mid-response)
- ✅ **Comprehensive context feeding**: card AI instructions, content knowledge base, parent content context

**AI Features (All Modes):**
- **Multi-language Support**: English, Cantonese (廣東話), Mandarin (國語), Japanese (日本語), Korean (한국어), Spanish (Español), French (Français), Russian (Русский), Arabic (العربية), Thai (ภาษาไทย)
- **Context-Aware Responses**: AI understands specific exhibit content and provides detailed explanations
- **Secure Token Management**: Ephemeral tokens ensure security without exposing main API keys
- **Environment-Based Configuration**: Different models and settings for development vs production
- **Language Enforcement**: Strict language adherence with explicit prompting for Cantonese and Mandarin differentiation

**Frontend AI Component:**
- `MobileAIAssistant.vue` - Complete multi-mode AI assistant interface
- Mode switcher (phone icon for realtime, chat icon for chat-completion)
- **Global language selection** via mobile header and card overview (not inside AI assistant)
- Streaming text responses with typing indicators
- Voice recording with press-and-hold UX
- Audio playback with caching and language awareness
- Real-time conversation UI with waveform visualization
- **Live transcription display** for both user and AI speech in realtime mode

### AI Content Configuration

**Card AI Instructions (ai_instruction field):**
- **Purpose**: Sets the overall AI assistance instructions and role definition
- **Scope**: Applies to all content items within the card
- **Content**: Defines the AI's role, personality, knowledge domain, and interaction requirements
- **Character Limit**: Max 100 words (enforced in UI)
- **Example**: "You are a knowledgeable museum curator specializing in ancient history. Provide detailed, educational explanations about historical artifacts and civilizations. Use engaging storytelling to make complex historical concepts accessible to visitors of all ages."

**Card AI Knowledge Base (ai_knowledge_base field):**
- **Purpose**: Provides detailed background knowledge for card-level AI conversations
- **Scope**: Card-wide knowledge that applies to all exhibits
- **Content**: Historical context, domain facts, specifications, guidelines
- **Character Limit**: Max 2000 words (enforced in UI)
- **Example**: "The Ancient World exhibition spans 3000 BCE to 500 CE, covering major civilizations including Mesopotamia, Egypt, Greece, Rome, India, and China. Key themes include the development of writing systems, architectural innovations, religious beliefs, trade networks, and political structures."

**Content Item AI Knowledge Base (content_item_ai_knowledge_base field):**
- **Purpose**: Provides detailed information for AI to answer user questions about specific content items
- **Scope**: Specific to individual content items (exhibits, artifacts, etc.)
- **Content**: Detailed descriptions, historical context, significance, related facts
- **Format**: Plain text or markdown (supports rich formatting)
- **Character Limit**: Max 2000 words per content item (enforced in UI)
- **Example**: "Lost Cities of Mesopotamia explores the cradle of civilization, including Babylon (founded c. 2300 BCE), Ur (c. 3800 BCE), and Uruk (c. 4000 BCE). Key inventions: cuneiform writing, Hammurabi's Code, ziggurats, irrigation systems. The region gave rise to the Sumerian, Akkadian, Babylonian, and Assyrian empires."

**AI Conversation Flow:**
1. **Card-Level Instructions**: AI instructions establish the overall role and interaction style
2. **Card-Level Knowledge**: AI knowledge base provides broad domain context
3. **Content-Specific Knowledge**: Content item knowledge base provides detailed information about the specific exhibit/artifact
4. **Parent Content Context**: For sub-items, parent content's knowledge base is also provided
5. **Language Enforcement**: Explicit language requirements ensure responses in the correct language
6. **Dynamic Responses**: AI combines all contexts to provide accurate, engaging answers

**Best Practices:**
- Use clear, concise AI instructions that define the AI's role and personality
- Populate knowledge bases with rich, detailed information for comprehensive AI responses
- For hierarchical content, ensure parent knowledge complements sub-item knowledge
- Use markdown in content descriptions for better formatting (bold, lists, links)
- Explicitly specify language requirements to ensure proper AI responses in Cantonese vs Mandarin

## Database Schema Key Points

### Core Tables
- `cards` - Card designs and metadata with AI prompt configuration
- `content_items` - Hierarchical content structure (exhibits → artifacts)
- `batches` - Card issuance batches for institutions
- `issued_cards` - Individual card instances for visitors
- `print_requests` - Physical souvenir card printing requests

### User Roles
- `card_issuer` - Museums/institutions creating exhibition cards and issuing batches
- `admin` - Platform operators managing verifications and print requests

### Database Access Pattern
- **ALL database operations use stored procedures** - no direct table access
- **Stored procedures organized in modules** (01-11): auth, cards, content, batches, payments, print requests, public access, profiles, analytics, shipping, admin
- **Key functions**: `issue_card_batch()`, `confirm_batch_payment()`, `get_user_cards()`, `activate_issued_card()`, `get_batch_payment_info()`

## Business Logic & Workflows

### Card Creation & Issuance Flow
1. **Design Phase**: Card issuer creates custom card design with 2:3 ratio image
2. **Content Setup**: Adds hierarchical content structure (series → items) with multimedia
3. **AI Integration**: Optional conversation AI setup for automated customer interactions
4. **Batch Creation**: Issues batch with specified quantity (generates unique QR codes)
5. **Payment Processing**: Stripe integration processes $2.00 USD per card
6. **Card Activation**: Digital cards become live and scannable after payment
7. **Print Request**: Optional physical card printing with shipping address management
8. **Analytics Tracking**: Real-time metrics on card scans and user engagement

### User Verification & Compliance Flow
1. **Registration**: Card issuer signs up and creates business profile
2. **Document Submission**: Upload business verification documents and identification
3. **Admin Review**: Platform administrators verify business legitimacy and compliance
4. **Approval Process**: Approve, reject, or request additional documentation
5. **Account Activation**: Verified users gain full platform access and card creation rights
6. **Ongoing Monitoring**: Continuous compliance monitoring and periodic re-verification

### End-User Experience Flow (Mobile Client)
1. **QR Code Discovery**: User encounters QR code on physical card or digital media
2. **Mobile Scan**: Smartphone camera scans QR code (optimized for various lighting)
3. **Instant Load**: Mobile-optimized digital card experience loads immediately
4. **Content Interaction**: Browse multimedia content, company info, and calls-to-action
5. **Contact Actions**: Save contact info, visit website, call, email, or connect on social
6. **AI Interaction**: Optional chatbot conversations for support, sales, or information
7. **Analytics Capture**: Interaction data captured for card issuer insights

### Payment & Billing Workflows
1. **Batch Payment**: Stripe processes batch payments at $2 USD per card
2. **Payment Verification**: Automated verification and batch activation
3. **Fee Waivers**: Admin capability to waive fees for promotional or enterprise deals
4. **Refund Handling**: Payment reversals for cancelled or problematic batches
5. **Invoice Generation**: Automatic billing records and receipt generation

### Print Request Management
1. **Print Submission**: Card issuer requests physical card printing
2. **Address Verification**: Shipping address validation and management
3. **Production Queue**: Print requests enter production workflow
4. **Quality Control**: Physical card production and quality assurance
5. **Shipping Coordination**: Global shipping with tracking integration
6. **Delivery Confirmation**: Automated delivery notifications and confirmations

### Administrative Operations
1. **User Management**: Monitor and manage card issuer accounts
2. **Verification Queue**: Process verification requests and documentation
3. **Payment Oversight**: Monitor transactions, disputes, and fee waivers
4. **Print Operations**: Coordinate physical card production and shipping
5. **Platform Analytics**: System-wide metrics, user growth, and performance monitoring
6. **Compliance Monitoring**: Ensure platform compliance with business regulations

## UI/UX Standards

### Design System
- **Primary colors**: Blue-based palette (`primary-500: #3b82f6`)
- **Typography**: Inter font family
- **Spacing**: Tailwind's spacing scale
- **Shadows**: Custom soft shadows (`shadow-soft`, `shadow-medium`)
- **Animations**: Subtle transitions (0.2s ease-in-out)

### Component Standards
- PrimeVue components with consistent overrides
- Form validation with clear error messages
- Loading states with spinners or skeletons
- Responsive design with mobile-first approach
- **Standardized DataTable styling**: All tables use consistent fonts, spacing, colors, and action buttons

### Mobile Optimization
- Touch-friendly interactions (min 44px touch targets)
- Simplified navigation for mobile views
- Optimized card preview component (`MobilePreview.vue`)
- **Auto-refresh mobile preview**: MobilePreview component refreshes every time the preview tab is clicked

## Error Handling Patterns

```javascript
// Standard error handling in stores - ALL operations use RPC
try {
  const { data, error } = await supabase.rpc('stored_procedure_name', { 
    p_param: value 
  })
  if (error) throw error
  return data
} catch (err: any) {
  console.error('Error context:', err)
  error.value = err.message || 'An unknown error occurred'
  throw err
}

// Component error handling with toast
const toast = useToast()
try {
  await store.action()
} catch (err) {
  toast.add({
    severity: 'error',
    summary: 'Error',
    detail: err.message,
    life: 5000
  })
}
```

## Security Considerations

- All database access via RLS policies
- File uploads validated for type and size
- Stripe payment processing server-side only
- User authentication via Supabase Auth
- Input sanitization for XSS prevention

## Performance Guidelines

- Use `v-memo` for expensive list renders
- Implement lazy loading for images
- Tree-shake PrimeVue component imports
- Optimize bundle size with dynamic imports
- Use computed properties for derived state

## Common Issues to Avoid

1. **Card aspect ratio**: Always use 2:3, never 3:4
2. **Component size**: Break down components >400 lines
3. **State management**: Don't duplicate store state in components
4. **Error handling**: Always provide user feedback on errors
5. **Mobile UX**: Test touch interactions on actual devices
6. **Database**: NEVER use `supabase.from()` - ALL operations must use `supabase.rpc()` with stored procedures
7. **Table styling**: Don't override global table theme - use inline styling with consistent CSS classes
8. **Table header consistency**: All tables use standard sizing (0.875rem headers) - avoid `p-datatable-sm` unless absolutely necessary
9. **Language stores**: Use `useMobileLanguageStore` for mobile client, `useDashboardLanguageStore` for dashboard - they are independent
10. **i18n pluralization**: Use pipe syntax (`{count} item | {count} items`), NOT ICU message format
11. **Translation keys**: Always check that keys exist in ALL language files before using
12. **Markdown rendering**: Use `marked(text)` for rendering, display with `v-html` for trusted content
13. **AI language enforcement**: Include explicit language requirements in system instructions for Cantonese/Mandarin differentiation

## Testing Strategy

- Component tests for critical user flows
- Integration tests for store actions
- E2E tests for complete workflows
- Manual testing on mobile devices
- Database migration testing

## Environment Variables Configuration

### Frontend Environment Variables

**Core Configuration (.env.local / .env.production):**
```bash
# Supabase Backend
VITE_SUPABASE_URL=https://your-project.supabase.co
VITE_SUPABASE_ANON_KEY=your-anon-key-here
VITE_SUPABASE_USER_FILES_BUCKET=userfiles

# Payment Processing
VITE_STRIPE_PUBLISHABLE_KEY=pk_test_your_stripe_key_here
VITE_STRIPE_SUCCESS_URL=http://localhost:5173/cms/mycards  # or production URL

# Application URLs
VITE_APP_BASE_URL=https://app.cardy.com

# Pricing (200 cents = $2.00 USD per card)
VITE_CARD_PRICE_CENTS=200
VITE_DEFAULT_CURRENCY=USD

# Contact Information
VITE_CONTACT_WHATSAPP_URL=https://wa.me/852xxxxxx
VITE_CONTACT_PHONE=+852 xxxxxx
```

### Edge Functions Configuration

**📖 See `EDGE_FUNCTIONS_CONFIG.md` for complete documentation**

**Quick Reference:**

**Local Development (`supabase/config.toml`):**
```toml
[edge_runtime.secrets]
# Stripe (Test Mode)
STRIPE_SECRET_KEY = "sk_test_..."

# OpenAI (Cost-effective)
OPENAI_API_KEY = "sk-proj-..."
OPENAI_AUDIO_MODEL = "gpt-4o-mini-audio-preview"
OPENAI_MAX_TOKENS = "2000"
OPENAI_TTS_VOICE = "alloy"
OPENAI_AUDIO_FORMAT = "wav"
```

**Production (Supabase Dashboard Secrets):**
```bash
# Required
STRIPE_SECRET_KEY=sk_live_...
OPENAI_API_KEY=sk-proj-...

# Optional (have defaults)
OPENAI_AUDIO_MODEL=gpt-4o-mini-audio-preview  # For chat completion mode
OPENAI_REALTIME_MODEL=gpt-realtime-mini-2025-10-06  # For realtime mode
OPENAI_MAX_TOKENS=3500
OPENAI_TTS_VOICE=alloy
OPENAI_AUDIO_FORMAT=wav
```

**Setup Scripts:**
```bash
# Interactive setup for production secrets
./scripts/setup-production-secrets.sh

# Deploy all Edge Functions
./scripts/deploy-edge-functions.sh

# Verify configuration
./scripts/deploy-edge-functions.sh --verify
```

### Configuration Files

- `.env.local` - Frontend development environment
- `.env.production` - Frontend production environment
- `supabase/config.toml` - Supabase local development + Edge Function secrets
- `EDGE_FUNCTIONS_CONFIG.md` - Complete Edge Functions documentation

### Critical Production Settings

1. **Security**: Never commit actual API keys to version control
2. **URLs**: Update `VITE_APP_BASE_URL` and `VITE_STRIPE_SUCCESS_URL` for proper redirects
3. **Pricing**: Configure `VITE_CARD_PRICE_CENTS` for different markets
4. **Contact**: Set appropriate contact information for customer support
5. **AI Models**: Use cost-effective models for development, full models for production
6. **Stripe**: Use test keys in development, live keys only in production

## Deployment

### Frontend Deployment
- Production builds deploy to CDN
- Run `npm run build:production` for production builds
- Environment variables configured via `.env.production`

### Backend Deployment
- Database migrations via `schema.sql` and stored procedures
- Edge Functions via `npx supabase functions deploy` or deployment script
- Secrets configured via Supabase Dashboard or CLI
- See `EDGE_FUNCTIONS_CONFIG.md` for complete guide

### Quick Deployment Commands
```bash
# Frontend
npm run build:production

# Edge Functions (all at once)
./scripts/deploy-edge-functions.sh

# Database (manual via Supabase Dashboard)
# 1. Copy schema.sql and all_stored_procedures.sql
# 2. Execute in SQL Editor
```