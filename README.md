# CardStudio CMS - Digital Souvenir & Exhibition Platform

<div align="center">
  <img src="https://images.unsplash.com/photo-1513475382585-d06e58bcb0e0?q=80&w=500" alt="CardStudio CMS" width="600">
  
  **Transform museum visits into lasting digital experiences**
  
  [![Vue 3](https://img.shields.io/badge/Vue-3.5.13-4FC08D?logo=vue.js)](https://vuejs.org/)
  [![PrimeVue](https://img.shields.io/badge/PrimeVue-4.3.3-6366F1)](https://primevue.org/)
  [![Supabase](https://img.shields.io/badge/Supabase-PostgreSQL-3ECF8E?logo=supabase)](https://supabase.com/)
  [![TypeScript](https://img.shields.io/badge/TypeScript-5.x-3178C6?logo=typescript)](https://www.typescriptlang.org/)
</div>

## 🎯 Overview

CardStudio is a comprehensive **digital souvenir and exhibition platform** that creates interactive experiences for museums, tourist attractions, and cultural sites. The platform enables institutions to provide visitors with rich, AI-powered digital content accessible through QR codes on physical souvenir cards, offering detailed explanations, guidance, and multimedia experiences about exhibits, artifacts, and locations.

### 🌟 Key Features

- **🎨 Digital Souvenir Cards** - Create beautifully designed cards with 2:3 aspect ratio
- **🤖 AI Voice Conversations** - Real-time multilingual AI curator using OpenAI Realtime API
- **📱 Mobile-First Experience** - Optimized for instant QR code scanning and viewing
- **💳 Batch Pricing Model** - Simple $2.00 per card pricing, no subscriptions
- **🎯 Hierarchical Content** - Organize exhibits, artifacts, and collections
- **🌍 Multi-Language Support** - English, Cantonese, Mandarin, Spanish, and French
- **📊 Analytics & Insights** - Track visitor engagement and card performance
- **🖨️ Physical Card Printing** - Professional printing with global shipping

### 🏢 Business Model

**Three-Tier Ecosystem:**
1. **Card Issuers** (B2B) - Museums, exhibitions, tourist attractions creating digital souvenir experiences ($2/card)
2. **Administrators** (Platform) - CardStudio operators managing verifications and operations  
3. **Visitors** (B2C) - Tourists and museum guests scanning QR codes for free digital content and AI guidance

**Target Markets:**
- Museums & Art Galleries
- Tourist Attractions & Landmarks  
- Cultural Heritage Sites
- Exhibition Centers & Trade Shows
- Theme Parks & Entertainment Venues

## 🚀 Quick Start

### Prerequisites

- Node.js 18+ and npm
- Supabase account
- Stripe account (for payments)
- OpenAI API access (for AI features)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/your-org/cardstudio-cms.git
   cd cardstudio-cms
   ```

2. **Install dependencies**
   ```bash
   npm install
   ```

3. **Environment Setup**

   The platform uses environment-specific configurations:

   **Development (.env.local):**
   ```env
   # Supabase
   VITE_SUPABASE_URL=https://your-project.supabase.co
   VITE_SUPABASE_ANON_KEY=your_supabase_anon_key
   VITE_SUPABASE_USER_FILES_BUCKET=userfiles

   # Stripe (Test)
   VITE_STRIPE_PUBLISHABLE_KEY=pk_test_xxx
   STRIPE_SECRET_KEY=sk_test_xxx

   # OpenAI (Cost-effective model for development)
   VITE_OPENAI_MODEL=gpt-4o-mini-realtime-preview-2024-12-17
   OPENAI_API_KEY=sk-xxx

   # Application
   VITE_CARD_PRICE_CENTS=200
   VITE_DEFAULT_CURRENCY=USD
   VITE_APP_BASE_URL=http://localhost:5173
   ```

   **Production (.env.production):**
   ```env
   # Same as above but with:
   VITE_STRIPE_PUBLISHABLE_KEY=pk_live_xxx
   STRIPE_SECRET_KEY=sk_live_xxx
   VITE_OPENAI_MODEL=gpt-4o-realtime-preview-2025-06-03  # Full model for production
   VITE_APP_BASE_URL=https://your-domain.com
   ```

4. **Database Setup**

   ```bash
   # Start local Supabase
   supabase start

   # Reset database with schema
   supabase db reset

   # Deploy stored procedures (all 11 modules)
   supabase db push

   # Generate TypeScript types
   supabase gen types typescript --local > src/types/supabase.ts
   ```

5. **Configure Supabase Edge Functions**

   Set the following secrets in your Supabase dashboard:
   ```bash
   # For development
   supabase secrets set OPENAI_API_KEY=sk-xxx
   supabase secrets set OPENAI_MODEL=gpt-4o-mini-realtime-preview-2024-12-17
   supabase secrets set STRIPE_SECRET_KEY=sk_test_xxx

   # Deploy Edge Functions
   supabase functions deploy get-openai-ephemeral-token
   supabase functions deploy openai-realtime-proxy
   supabase functions deploy create-checkout-session
   supabase functions deploy handle-checkout-success
   ```

6. **Start development**
   ```bash
   # Development with cost-effective AI model
   npm run dev

   # Local development
   npm run dev:local

   # Production build
   npm run build:production
   ```

## 🎯 Platform Features & Implementation Status

### 🎨 Card Issuer Dashboard (✅ Complete)
- **User Management**: Registration, profile management, business verification
- **Card Designer**: Visual card creation with 2:3 aspect ratio enforcement
- **Content Management**: Hierarchical content structure (series → items)
- **AI Configuration**: Conversation prompts and multilingual setup
- **Batch Operations**: Card issuance with QR code generation
- **Payment Integration**: Stripe checkout for $2/card pricing
- **Print Requests**: Physical card ordering with shipping
- **Analytics**: Real-time engagement metrics and visitor insights

### 📱 Mobile Client Experience (✅ Complete)
- **QR Code Scanning**: Instant card recognition and loading
- **Responsive Design**: Optimized for all mobile devices
- **Content Browsing**: Smooth navigation through exhibits
- **AI Voice Chat**: Real-time conversations in 5 languages
- **Offline Support**: Core content accessible without internet
- **Social Sharing**: Share cards and experiences
- **Contact Integration**: Save business details to contacts

### 🛡️ Administrator Panel (✅ Complete)
- **User Verification**: Business document review and approval
- **Payment Oversight**: Transaction monitoring and refund processing
- **Print Management**: Physical card production coordination
- **Platform Analytics**: System-wide usage and performance metrics
- **Content Moderation**: Review and approve card content
- **Fee Management**: Promotional pricing and enterprise deals

### 🤖 AI Voice Assistant (✅ Complete)
- **OpenAI Realtime API**: WebRTC integration for low-latency conversations
- **Multi-language Support**: English, Cantonese, Mandarin, Spanish, French
- **Context Awareness**: Understands specific exhibit content
- **Environment-based Models**: Different AI models for dev/production
- **Secure Token Management**: Ephemeral tokens for enhanced security

## 🏗️ Architecture

### Frontend Stack
- **Vue 3.5.13** with Composition API and TypeScript
- **PrimeVue 4.3.3** for UI components with custom theming
- **Pinia 3.0.1** for state management
- **Tailwind CSS 3.4** for styling with custom design system
- **Vite 6.2** for lightning-fast build tooling

### Backend Stack
- **Supabase** (PostgreSQL database + Auth + Storage + Edge Functions)
- **Stored procedures** in 11 modular files for ALL database operations
- **Row Level Security (RLS)** policies for data security
- **Stripe** integration for payment processing
- **OpenAI Realtime API** for voice-based AI conversations

### Database Architecture

All database operations use stored procedures organized into modules:

**Client-side modules (01-11):**
1. `01_user_profile.sql` - Profile management and verification
2. `02_card_management.sql` - Card CRUD operations  
3. `03_content_management.sql` - Content items and hierarchy
4. `04_batch_operations.sql` - Batch issuance and QR generation
5. `05_issued_cards.sql` - Individual card management
6. `06_payment_tracking.sql` - Payment records and reconciliation
7. `07_public_access.sql` - Public card viewing (no auth required)
8. `08_print_operations.sql` - Print requests and shipping
9. `09_admin_operations.sql` - Admin functions and user management
10. `10_analytics.sql` - Usage metrics and reporting
11. `11_utility_functions.sql` - Helper functions and utilities

**Server-side modules:**
- Payment processing for Stripe webhooks
- Batch activation and payment confirmation

## 🔄 Core Workflows

### Card Issuer Workflow
1. **Registration** → Business verification by admin
2. **Card Design** → Upload images (2:3 ratio), write descriptions
3. **Content Creation** → Build hierarchical structure (exhibits → artifacts)
4. **AI Setup** → Configure conversation prompts and languages
5. **Batch Issuance** → Generate QR codes, process payment ($2/card)
6. **Print Ordering** → Optional physical card production
7. **Analytics Review** → Monitor visitor engagement and feedback

### Visitor Experience
1. **QR Scan** → Instant mobile-optimized card loading
2. **Content Browse** → Explore exhibits, artifacts, and details
3. **AI Interaction** → Voice conversations about content in preferred language
4. **Social Actions** → Save contact info, share experiences
5. **Feedback** → Rate and review experiences

### Administrator Operations
1. **User Verification** → Review business documents and approve accounts
2. **Payment Monitoring** → Track transactions, handle disputes
3. **Print Coordination** → Manage physical card production queue
4. **Analytics Review** → Platform-wide metrics and growth analysis
5. **Content Moderation** → Ensure quality and compliance

## 🛠️ Development

### Available Scripts

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

### Code Style Guidelines

- **Components**: Keep under 400 lines, use composition API
- **State Management**: Use Pinia stores, avoid component state duplication  
- **Database Access**: Always use stored procedures via `supabase.rpc()`
- **Styling**: Use Tailwind utilities, maintain consistent design system
- **Images**: Always maintain 2:3 aspect ratio for cards
- **Error Handling**: Provide user-friendly error messages with toast notifications

### Common Development Patterns

```javascript
// Database operations - always use RPC
const { data, error } = await supabase.rpc('stored_procedure_name', { 
  p_param: value 
})

// Error handling with user feedback
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

## 💳 Stripe Payment Integration

### Setup Requirements

1. **Stripe Account Configuration**
   ```bash
   # Business Information
   - Company name and address
   - Business type and description  
   - Tax ID / Business registration
   - Bank account for payouts
   ```

2. **API Keys Setup**
   ```bash
   # Test Environment
   VITE_STRIPE_PUBLISHABLE_KEY=pk_test_xxx
   STRIPE_SECRET_KEY=sk_test_xxx

   # Production Environment  
   VITE_STRIPE_PUBLISHABLE_KEY=pk_live_xxx
   STRIPE_SECRET_KEY=sk_live_xxx
   ```

3. **Webhook Configuration**
   ```bash
   # Endpoint: https://your-project.supabase.co/functions/v1/handle-checkout-success
   # Events: checkout.session.completed, payment_intent.succeeded
   ```

### Payment Flow Architecture

1. **Batch Creation** → User creates card batch with quantity
2. **Checkout Session** → Stripe checkout session created via Edge Function
3. **Payment Processing** → User completes payment on Stripe-hosted page
4. **Webhook Verification** → Stripe webhook confirms payment
5. **Batch Activation** → Cards become live and scannable
6. **Analytics Tracking** → Payment and usage metrics recorded

## 🔒 Security

- **Row Level Security (RLS)**: Fine-grained database access control
- **Authentication**: Supabase Auth with email/password
- **API Security**: Secure Edge Functions with authentication checks
- **Payment Security**: PCI-compliant Stripe integration
- **File Upload**: Type and size validation for images
- **Input Sanitization**: XSS prevention across all user inputs
- **Environment Separation**: Different configurations for dev/production

## 📊 Analytics & Monitoring

### Key Metrics Tracked
- **Card Performance**: Scan rates, engagement duration, return visits
- **Payment Analytics**: Revenue tracking, conversion rates, refund rates
- **User Behavior**: Content interaction patterns, AI usage statistics
- **Platform Health**: System performance, error rates, uptime monitoring

### Available Reports
- Card issuer dashboard with real-time metrics
- Administrator panel with platform-wide analytics
- Revenue reporting and financial summaries
- User engagement and retention analysis

## 🌐 AI Integration

### OpenAI Realtime API Features
- **Real-time Voice Conversations**: Natural voice interactions with exhibits
- **WebRTC Audio Streaming**: Low-latency audio for responsive conversations
- **Multi-language Support**: 5 languages with native voice models
- **Context-Aware Responses**: AI understands specific exhibit content
- **Environment-Based Models**: Cost-effective dev models, full production models

### AI Configuration
```javascript
// Development
VITE_OPENAI_MODEL=gpt-4o-mini-realtime-preview-2024-12-17

// Production  
VITE_OPENAI_MODEL=gpt-4o-realtime-preview-2025-06-03
```

## 🧪 Testing

### Test Coverage
- Component tests for critical user flows
- Integration tests for database operations
- End-to-end tests for complete workflows
- Payment testing with Stripe test cards
- AI conversation testing with mock responses

### Testing Stripe Integration
```bash
# Test card numbers
4242424242424242  # Visa - succeeds
4000000000000002  # Visa - declined
4000000000009995  # Visa - insufficient funds
```

## 🚨 Troubleshooting

### Common Issues

**Database Connection Issues:**
```bash
# Reset local database
supabase db reset
supabase gen types typescript --local > src/types/supabase.ts
```

**Stripe Payment Failures:**
- Verify webhook endpoint is accessible
- Check Stripe secret keys in Supabase secrets
- Ensure test mode matches between frontend and backend

**AI Voice Chat Not Working:**
- Verify OpenAI API key in Supabase secrets
- Check browser microphone permissions
- Ensure HTTPS for production (required for WebRTC)

**Build Errors:**
```bash
npm run type-check  # Check TypeScript errors
npm run build       # Verify production build
```

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Follow code style guidelines
4. Add tests for new features
5. Commit your changes (`git commit -m 'Add amazing feature'`)
6. Push to the branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

### Commit Convention
- `feat:` New features
- `fix:` Bug fixes  
- `docs:` Documentation updates
- `style:` Code style changes
- `refactor:` Code refactoring
- `test:` Test updates
- `chore:` Build/config updates

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

- **Documentation**: [CLAUDE.md](./CLAUDE.md) for detailed development guidance
- **Issues**: Report bugs on [GitHub Issues](https://github.com/your-org/cardstudio-cms/issues)
- **Email**: support@cardstudio.org
- **Phone**: +852 55992159

---

<div align="center">
  Made with ❤️ by the CardStudio Team
  
  [Website](https://cardstudio.org) • [Documentation](https://docs.cardstudio.org) • [Blog](https://blog.cardstudio.org)
</div>