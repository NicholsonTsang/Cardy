# Unified Header Implementation

## Overview
Created a unified header component that serves both the landing page and dashboard, providing consistent branding and design while adapting to different contexts.

## Changes Made

### 1. New Component: `UnifiedHeader.vue`
**Location:** `src/components/Layout/UnifiedHeader.vue`

**Features:**
- Single header component with two modes: `'landing'` and `'dashboard'`
- Consistent logo, branding, and design language
- Adaptive navigation based on mode:
  - **Landing Mode**: Shows navigation links (About, Demo, Pricing, Contact) + Sign In/Sign Up buttons
  - **Dashboard Mode**: Hides navigation links, shows user dropdown menu with role-based navigation
- Scroll progress bar (landing mode only)
- Language selector (both modes)
- Credit balance display (dashboard mode, card issuers only)

**Props:**
- `mode`: String (`'landing'` or `'dashboard'`) - determines header behavior

**Events:**
- `scroll-to`: Emitted in landing mode when navigation links are clicked (passes section ID)
- `toggle-mobile-menu`: Emitted in landing mode when mobile menu button is clicked

### 2. Updated Landing Page
**File:** `src/views/Public/LandingPage.vue`

**Changes:**
- Replaced inline navigation bar with `<UnifiedHeader mode="landing">`
- Connected scroll navigation via `@scroll-to="scrollToSection"`
- Connected mobile menu toggle via `@toggle-mobile-menu`
- Removed duplicate state (scrolled, scrollProgress) - now handled in UnifiedHeader

### 3. Updated Dashboard Layout
**File:** `src/layouts/AppLayout.vue`

**Changes:**
- Replaced `<AppHeader />` with `<UnifiedHeader mode="dashboard" />`
- Imported new UnifiedHeader component

### 4. Old Component
**File:** `src/components/Layout/AppHeader.vue`

**Status:** Can be deprecated/removed (kept for reference during transition)

## Design Consistency

### Shared Elements (Both Modes)
- Logo with gradient (blue to purple)
- CardStudio branding with tagline
- Language selector
- Responsive design
- Blur backdrop effect on scroll
- Shadow and border styling

### Landing Mode Specific
- Navigation links (About, Demo, Pricing, Contact)
- Sign In button (desktop only)
- Start Free Trial button
- Mobile menu toggle
- Scroll progress bar
- When authenticated: User dropdown menu replaces Sign In/Sign Up

### Dashboard Mode Specific
- Credit balance display (card issuers)
- User dropdown menu with:
  - User email
  - Role-based navigation (admin vs card issuer)
  - Sign out option
- No navigation links

## User Flow

### Landing Page (Not Authenticated)
1. User sees: Logo + Navigation links + Language selector + Sign In + Sign Up
2. Navigation links scroll to sections
3. Sign In/Sign Up redirect to auth pages

### Landing Page (Authenticated)
1. User sees: Logo + Navigation links + Language selector + User dropdown
2. Navigation links scroll to sections
3. User dropdown shows dashboard links and sign out

### Dashboard (Authenticated)
1. User sees: Logo + Credit balance (if card issuer) + Language selector + User dropdown
2. No navigation links (cleaner dashboard header)
3. User dropdown provides all navigation

## Benefits

1. **Consistency**: Same header design and branding across landing and dashboard
2. **DRY Principle**: Single source of truth for header logic
3. **User Experience**: Authenticated users see familiar dropdown menu on both landing and dashboard
4. **Maintainability**: Updates to header only need to be made in one component
5. **Flexibility**: Easy to add new modes or features in the future

## Testing Checklist

- [ ] Landing page (not authenticated) shows navigation links + Sign In/Sign Up
- [ ] Landing page (authenticated) shows navigation links + user dropdown
- [ ] Dashboard shows user dropdown without navigation links
- [ ] Scroll navigation works on landing page
- [ ] Mobile menu toggle works on landing page
- [ ] Language selector works on both landing and dashboard
- [ ] Credit balance displays correctly (dashboard, card issuers)
- [ ] User dropdown menu works (both contexts)
- [ ] Sign out works from both landing and dashboard
- [ ] Responsive behavior at all breakpoints
- [ ] Scroll progress bar visible on landing page only

## Technical Notes

- UnifiedHeader uses `mode` prop to determine behavior
- Emits events for landing page interactions (scroll-to, toggle-mobile-menu)
- Shares authentication logic with dashboard (auth store, credit store)
- Responsive breakpoint: `lg` (1024px) for showing/hiding navigation links
- Mobile menu handled by parent component (LandingPage.vue)

## Future Enhancements

- Add smooth transitions when switching modes (if needed)
- Consider adding more modes (e.g., 'mobile', 'preview')
- Add unit tests for mode-specific behavior
- Consider extracting menu items to separate composable


