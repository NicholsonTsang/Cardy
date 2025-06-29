# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Cardy is a Vue 3 + TypeScript application for digital card management and issuance. It uses PrimeVue UI components, Pinia for state management, Tailwind CSS for styling, and Supabase as the backend with PostgreSQL database.

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

## Database Schema Key Points

### Core Tables
- `cards` - Card designs and metadata
- `content_items` - Hierarchical content structure
- `batches` - Card issuance batches
- `issued_cards` - Individual card instances
- `print_requests` - Physical printing requests

### User Roles
- `card_issuer` - Can create cards and issue batches
- `admin` - Can manage verifications and print requests

### Critical Stored Procedures
- `create_card_batch()` - Issues new batch of cards
- `process_stripe_payment()` - Handles payment processing
- `activate_card()` - Activates cards for end users

## Business Logic & Workflows

### Card Creation Flow
1. User creates card design with 2:3 ratio image
2. Adds hierarchical content (series → items)
3. Issues batch with quantity (generates unique codes)
4. Processes payment via Stripe ($2.00 per card)
5. Requests physical printing with shipping address

### User Verification Flow
1. Card issuer submits verification documents
2. Admin reviews and approves/rejects
3. Approved users gain full platform access

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