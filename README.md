# Cardy CMS - Digital Souvenir & Exhibition Platform

<div align="center">
  <img src="https://images.unsplash.com/photo-1513475382585-d06e58bcb0e0?q=80&w=500" alt="Cardy CMS" width="600">
  
  **Transform museum visits into lasting digital experiences**
  
  [![Vue 3](https://img.shields.io/badge/Vue-3.5.13-4FC08D?logo=vue.js)](https://vuejs.org/)
  [![PrimeVue](https://img.shields.io/badge/PrimeVue-4.3.3-6366F1)](https://primevue.org/)
  [![Supabase](https://img.shields.io/badge/Supabase-PostgreSQL-3ECF8E?logo=supabase)](https://supabase.com/)
  [![TypeScript](https://img.shields.io/badge/TypeScript-5.x-3178C6?logo=typescript)](https://www.typescriptlang.org/)
</div>

## 🎯 Overview

Cardy is a comprehensive **digital souvenir and exhibition platform** that creates interactive experiences for museums, tourist attractions, and cultural sites. The platform enables institutions to provide visitors with rich, AI-powered digital content accessible through QR codes on physical souvenir cards.

### 🌟 Key Features

- **🎨 Digital Souvenir Cards** - Create beautifully designed cards with 2:3 aspect ratio
- **🤖 AI Voice Conversations** - Real-time multilingual AI curator using OpenAI Realtime API
- **📱 Mobile-First Experience** - Optimized for instant QR code scanning and viewing
- **💳 Batch Pricing Model** - Simple $2.00 per card pricing, no subscriptions
- **🎯 Hierarchical Content** - Organize exhibits, artifacts, and collections
- **🌍 Multi-Language Support** - English, Cantonese, Mandarin, Spanish, and French
- **📊 Analytics & Insights** - Track visitor engagement and card performance
- **🖨️ Physical Card Printing** - Professional printing with global shipping

## 🏗️ Project Structure

```
cardy-cms/
├── src/
│   ├── components/           # Reusable Vue components
│   │   ├── Card/            # Card management components
│   │   ├── CardComponents/  # Card creation & display
│   │   ├── CardContent/     # Content management
│   │   └── Profile/         # User profile & verification
│   ├── views/               # Page-level components
│   │   ├── Dashboard/       # Admin & Card Issuer dashboards
│   │   ├── MobileClient/    # Mobile QR viewing experience
│   │   └── Public/          # Landing page
│   ├── stores/              # Pinia state management
│   ├── utils/               # Helper functions
│   └── router/              # Vue Router configuration
├── sql/
│   ├── schema.sql           # Database schema
│   ├── storeproc/           # Modular stored procedures
│   │   ├── client-side/     # Frontend operations (11 modules)
│   │   └── server-side/     # Payment processing
│   ├── triggers.sql         # Database triggers
│   └── policy.sql           # RLS policies
└── supabase/
    └── functions/           # Edge Functions
        ├── get-openai-ephemeral-token/
        ├── openai-realtime-proxy/
        ├── create-checkout-session/
        └── handle-checkout-success/
```

## 🚀 Quick Start

### Prerequisites

- Node.js 18+ and npm
- Supabase account
- Stripe account (for payments)
- OpenAI API access (for AI features)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/your-org/cardy-cms.git
   cd cardy-cms
   ```

2. **Install dependencies**
   ```bash
   npm install
   ```

3. **Set up environment variables**
   ```bash
   cp .env.example .env
   ```

   Configure the following in `.env`:
   ```env
   # Supabase
   VITE_SUPABASE_URL=your_supabase_project_url
   VITE_SUPABASE_ANON_KEY=your_supabase_anon_key
   VITE_SUPABASE_USER_FILES_BUCKET=userfiles

   # Stripe
   VITE_STRIPE_PUBLISHABLE_KEY=pk_test_xxx
   STRIPE_SECRET_KEY=sk_test_xxx  # For Edge Functions

   # OpenAI (for Edge Functions)
   OPENAI_API_KEY=sk-xxx

   # Application
   VITE_CARD_PRICE_CENTS=200
   VITE_DEFAULT_CURRENCY=USD
   VITE_APP_BASE_URL=http://localhost:5173
   ```

4. **Set up Supabase database**
   ```bash
   # Start local Supabase
   supabase start

   # Apply database schema
   supabase db reset

   # Deploy stored procedures
   npm run deploy:db

   # Generate TypeScript types
   npm run generate:types
   ```

5. **Deploy Edge Functions**
   ```bash
   supabase functions deploy get-openai-ephemeral-token
   supabase functions deploy openai-realtime-proxy
   supabase functions deploy create-checkout-session
   supabase functions deploy handle-checkout-success
   ```

6. **Start development server**
   ```bash
   npm run dev
   ```

   Visit `http://localhost:5173` to see the application.

## 📋 Common Use Cases

### 1. Museums & Art Galleries
- **Digital Exhibition Cards**: Create interactive souvenirs for special exhibits
- **AI Curator**: Visitors can ask questions about artifacts in their preferred language
- **Collection Management**: Organize content hierarchically (exhibits → artifacts → details)

### 2. Tourist Attractions
- **Landmark Information**: Rich multimedia content about historical sites
- **Guided Tours**: AI-powered voice guidance for self-paced exploration
- **Souvenir Sales**: Physical cards as memorable keepsakes

### 3. Cultural Heritage Sites
- **Cultural Preservation**: Document and share cultural significance
- **Educational Content**: Detailed explanations for students and researchers
- **Multi-language Access**: Reach international visitors

### 4. Exhibition Centers
- **Trade Show Cards**: Interactive product demonstrations
- **Event Souvenirs**: Memorable takeaways from conferences
- **Lead Generation**: Track visitor engagement with exhibits

## 🔄 Core Workflows

### Card Issuer Workflow
1. **Create Account** → Business verification by admin
2. **Design Card** → Upload images, write descriptions (2:3 ratio)
3. **Add Content** → Build hierarchical content structure
4. **Configure AI** → Set up conversation prompts and languages
5. **Issue Batch** → Generate QR codes, process payment ($2/card)
6. **Print Cards** → Optional physical card production
7. **Track Analytics** → Monitor visitor engagement

### Visitor Workflow
1. **Scan QR Code** → Use any smartphone camera
2. **View Card** → Instant mobile-optimized experience
3. **Explore Content** → Navigate through exhibits and artifacts
4. **AI Conversations** → Voice chat about the content
5. **Save & Share** → Keep digital souvenir for later

### Administrator Workflow
1. **User Management** → Verify businesses, manage accounts
2. **Payment Oversight** → Monitor transactions, process refunds
3. **Print Coordination** → Manage physical card production
4. **Platform Analytics** → System-wide usage metrics

## 🛠️ Technology Stack

### Frontend
- **Vue 3.5.13** - Progressive JavaScript framework
- **PrimeVue 4.3.3** - Rich UI component library
- **Pinia 3.0.1** - State management
- **TypeScript 5.x** - Type safety
- **Tailwind CSS 3.4** - Utility-first styling
- **Vite 6.2** - Lightning-fast build tool

### Backend
- **Supabase** - Backend as a Service
  - PostgreSQL 15 database
  - Row Level Security (RLS)
  - Edge Functions (Deno)
  - Real-time subscriptions
  - File storage
- **Stripe** - Payment processing
- **OpenAI Realtime API** - Voice conversations

### Infrastructure
- **Vercel/Netlify** - Frontend hosting
- **Supabase Cloud** - Backend hosting
- **Cloudflare CDN** - Global content delivery

## 📚 Development

### Available Scripts

```bash
# Development
npm run dev              # Start dev server
npm run build            # Build for production
npm run preview          # Preview production build
npm run type-check       # Run TypeScript checks

# Database
npm run deploy:db        # Deploy all stored procedures
npm run generate:types   # Generate TypeScript types from DB

# Testing
npm run test            # Run unit tests
npm run test:e2e        # Run end-to-end tests
```

### Code Style Guidelines

- **Components**: Keep under 400 lines, use composition API
- **State Management**: Use Pinia stores, avoid component state duplication
- **Database Access**: Always use stored procedures via `supabase.rpc()`
- **Styling**: Use Tailwind utilities, maintain consistent design system
- **Images**: Always maintain 2:3 aspect ratio for cards
- **Error Handling**: Provide user-friendly error messages

### Database Operations

All database operations use stored procedures organized into modules:

**Client-side modules:**
1. `01_user_profile.sql` - Profile management
2. `02_card_management.sql` - Card CRUD operations
3. `03_content_management.sql` - Content items
4. `04_batch_operations.sql` - Batch issuance
5. `05_issued_cards.sql` - Individual card management
6. `06_payment_tracking.sql` - Payment records
7. `07_public_access.sql` - Public card viewing
8. `08_print_operations.sql` - Print requests
9. `09_admin_operations.sql` - Admin functions
10. `10_analytics.sql` - Usage metrics
11. `11_utility_functions.sql` - Helper functions

## 🔒 Security

- **Row Level Security (RLS)**: Fine-grained access control
- **Authentication**: Supabase Auth with email/password
- **API Security**: Secure Edge Functions with auth checks
- **Payment Security**: PCI-compliant Stripe integration
- **File Upload**: Type and size validation
- **Input Sanitization**: XSS prevention

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

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

- **Documentation**: Check our [docs](https://docs.cardy.com)
- **Issues**: Report bugs on [GitHub Issues](https://github.com/your-org/cardy-cms/issues)
- **Email**: support@cardy.com
- **Discord**: Join our [community](https://discord.gg/cardy)

---

<div align="center">
  Made with ❤️ by the Cardy Team
  
  [Website](https://cardy.com) • [Documentation](https://docs.cardy.com) • [Blog](https://blog.cardy.com)
</div>