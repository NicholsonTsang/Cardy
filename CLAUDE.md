# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Cardy is a comprehensive **digital souvenir and exhibition platform** that creates interactive experiences for museums, tourist attractions, and cultural sites. The platform enables institutions to provide visitors with rich, AI-powered digital content accessible through QR codes on physical souvenir cards, offering detailed explanations, guidance, and multimedia experiences about exhibits, artifacts, and locations.

### Business Model & Architecture

**Three-Tier Ecosystem:**
1. **Card Issuers** (B2B) - Museums, exhibitions, tourist attractions creating digital souvenir experiences ($2/card)
2. **Administrators** (Platform) - Cardy operators managing verifications and operations  
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

Cardy is built with Vue 3 + TypeScript, using PrimeVue UI components, Pinia for state management, Tailwind CSS for styling, and Supabase as the backend with PostgreSQL database.

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
- **Stored procedures** in `sql/schemaStoreProc.sql` for business logic
- **RLS policies** for data security
- **Stripe** integration for payments (via Edge Functions)
- **OpenAI Realtime API** integration for voice-based AI conversations
- **Edge Functions** for AI token management and WebRTC proxy

## Key Commands

```bash
# Development
npm run dev                 # Start development server
npm run build              # Build for production
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
├── schemaStoreProc.sql  # Stored procedures
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

### OpenAI Realtime API Integration
Cardy implements sophisticated voice-based AI conversations using OpenAI's Realtime API with WebRTC for low-latency audio streaming.

**Edge Functions:**
- `get-openai-ephemeral-token/` - Securely generates ephemeral tokens for OpenAI sessions
- `openai-realtime-proxy/` - Proxies WebRTC SDP offers/answers between client and OpenAI

**AI Features:**
- **Real-time Voice Conversations**: Natural voice interactions with museum exhibits and artifacts
- **Multi-language Support**: English, Cantonese, Mandarin, Spanish, French
- **WebRTC Audio Streaming**: Low-latency audio for responsive conversations
- **Context-Aware Responses**: AI understands specific exhibit content and provides detailed explanations
- **Secure Token Management**: Ephemeral tokens ensure security without exposing main API keys

**Frontend AI Component:**
- `ContentItemConversationAI.vue` - Complete voice chat interface with microphone controls
- Supports both compact and full-screen conversation modes
- Language selection and voice settings management
- Real-time audio visualization and connection status

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

### Critical Stored Procedures
- `create_card_batch()` - Issues new batch of souvenir cards
- `process_stripe_payment()` - Handles institution payment processing
- `activate_card()` - Activates cards for visitor access

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
// Standard error handling in stores
try {
  const { data, error } = await supabase.from('table').select()
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
6. **Database**: Use stored procedures for complex business logic
7. **Table styling**: Don't override global table theme - use `src/utils/tableConfig.js` for customizations
8. **Table header consistency**: All tables use standard sizing (0.875rem headers) - avoid `p-datatable-sm` unless absolutely necessary

## Testing Strategy

- Component tests for critical user flows
- Integration tests for store actions
- E2E tests for complete workflows
- Manual testing on mobile devices
- Database migration testing

## Deployment

- Production builds deploy to CDN
- Supabase projects for staging/production
- Environment variables for API keys
- Database migrations via Supabase CLI
- Edge Functions for serverless logic