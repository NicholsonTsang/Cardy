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
- **OpenAI Realtime API** integration for voice-based AI conversations
- **Edge Functions** for AI token management and WebRTC proxy

## Key Commands

```bash
# Development
npm run dev                 # Start development server (uses .env.local)
npm run dev:local          # Start local development server
npm run build              # Build for production
npm run build:production   # Build for production with production env
npm run type-check         # Run TypeScript type checking
npm run preview            # Preview production build

# Database
supabase start             # Start local Supabase
supabase db reset          # Reset local database
supabase gen types typescript --local > src/types/supabase.ts
```

## Important File Structure

```
src/
├── components/           # Reusable Vue components
│   ├── Card/            # Card-related components
│   ├── CardContent/     # Content management components
│   └── Profile/         # User profile components
├── views/               # Page-level components
│   ├── Dashboard/       # Main dashboard views
│   │   ├── Admin/       # Admin panel views
│   │   └── CardIssuer/  # Card issuer views
│   └── MobileClient/    # Mobile card viewing
├── stores/              # Pinia stores for state management
├── utils/               # Helper functions
└── router/              # Vue Router configuration

sql/
├── schema.sql           # Database schema
├── storeproc/           # Modular stored procedures (01-11)
├── triggers.sql         # Database triggers
└── policy.sql           # RLS policies
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

### Real-Time Audio Mode (UI Complete, Backend Pending)

**Technology Stack:**
- OpenAI Realtime API (`gpt-4o-mini-realtime-preview`)
- WebRTC for peer-to-peer audio streaming
- Server-Sent Events for signaling

**Edge Functions (Planned):**
- `openai-realtime-relay/` - WebRTC relay between client and OpenAI

**Features (UI Complete):**
- ✅ ChatGPT-style live conversation UI
- ✅ Animated waveform visualization
- ✅ Connection state management
- ✅ Live transcript display
- ✅ Status indicators and animations
- ⏳ WebRTC implementation (pending)
- ⏳ Actual audio streaming (pending)

**AI Features (All Modes):**
- **Multi-language Support**: English, Cantonese, Mandarin, Japanese, Korean, Spanish, French, Russian, Arabic, Thai
- **Context-Aware Responses**: AI understands specific exhibit content and provides detailed explanations
- **Secure Token Management**: Ephemeral tokens ensure security without exposing main API keys
- **Environment-Based Configuration**: Different models and settings for development vs production

**Frontend AI Component:**
- `MobileAIAssistant.vue` - Complete multi-mode AI assistant interface
- Mode switcher (phone icon for realtime, chat icon for chat-completion)
- Language selection screen before conversation
- Streaming text responses with typing indicators
- Voice recording with press-and-hold UX
- Audio playback with caching and language awareness
- Real-time conversation UI with waveform visualization

### AI Content Configuration

**Card AI Prompt (ai_prompt field):**
- **Purpose**: Sets the overall AI assistance instructions and role definition
- **Scope**: Applies to all content items within the card
- **Content**: Defines the AI's role, personality, knowledge domain, and interaction requirements
- **Example**: "You are a knowledgeable museum curator specializing in ancient history. Provide detailed, educational explanations about historical artifacts and civilizations. Use engaging storytelling to make complex historical concepts accessible to visitors of all ages."

**Content Item AI Metadata (ai_metadata field):**
- **Purpose**: Provides supplemental information for AI to answer user questions about specific content items
- **Scope**: Specific to individual content items (exhibits, artifacts, etc.)
- **Content**: Keywords, topics, and contextual information relevant to the specific content
- **Format**: Short phrases separated by commas and spaces for optimal UI display
- **Example**: "ancient civilizations, mesopotamia, egypt, greece, rome"
- **Usage**: AI uses this metadata to understand the context and provide relevant responses about specific exhibits

**AI Conversation Flow:**
1. **Card-Level Context**: AI prompt establishes the overall role and interaction style
2. **Content-Specific Context**: AI metadata provides detailed information about the specific exhibit/artifact
3. **Dynamic Responses**: AI combines both contexts to provide accurate, engaging answers about the content
4. **Multi-Language Support**: All AI responses adapt to the visitor's selected language

**Best Practices:**
- Keep AI metadata concise with short phrases to prevent UI overflow
- Use descriptive but brief terms that capture the essence of the content
- Separate metadata items with commas and spaces for proper text wrapping
- Ensure AI prompts are clear and specific to the museum/exhibition context

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
OPENAI_AUDIO_MODEL=gpt-4o-mini-audio-preview
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