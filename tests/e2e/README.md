# E2E Tests (Selenium)

## Setup

```bash
npm install --save-dev selenium-webdriver @types/selenium-webdriver
```

Chrome and chromedriver must be available. Selenium 4+ includes `selenium-manager` which auto-downloads drivers.

## Running

```bash
# Start frontend dev server
npm run dev

# Run all test suites (in separate terminals)
TEST_CREATOR_EMAIL="creator@example.com" TEST_CREATOR_PASSWORD="pass" \
TEST_ADMIN_EMAIL="admin@example.com" TEST_ADMIN_PASSWORD="pass" \
TEST_PUBLIC_CARD_ID="your-card-id" \
npx ts-node tests/e2e/auth.test.ts

# Run individual suites
npx ts-node tests/e2e/creator-portal.test.ts
npx ts-node tests/e2e/admin-portal.test.ts
npx ts-node tests/e2e/mobile-client.test.ts
```

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `TEST_BASE_URL` | `http://localhost:5173` | Frontend URL |
| `TEST_CREATOR_EMAIL` | (required for creator/auth tests) | Creator account email |
| `TEST_CREATOR_PASSWORD` | (required for creator/auth tests) | Creator account password |
| `TEST_ADMIN_EMAIL` | (required for admin tests) | Admin account email |
| `TEST_ADMIN_PASSWORD` | (required for admin tests) | Admin account password |
| `TEST_PUBLIC_CARD_ID` | (required for mobile tests) | A public card ID in the test environment |
| `TEST_HEADLESS` | `true` | Set to `false` to see the browser |

## Test Suites

### auth.test.ts - Authentication & Route Guards
- **Login Page**: Form rendering, inputs, submit, branding, invalid credentials, empty field validation
- **Signup Page**: Form rendering, inputs, sign-in link
- **Password Reset**: Page renders correctly
- **Route Guards**: Unauthenticated access to /cms/* redirects to login
- **Language Routing**: Root redirect, English, Traditional Chinese
- **Creator Login Flow**: Login + redirect to /cms/projects
- **Admin Login Flow**: Login + redirect to /cms/admin

### creator-portal.test.ts - Creator Dashboard
- **Navigation Menu**: User menu, dropdown items, navigation
- **Header Credit Balance**: Wallet icon in header
- **Projects Page**: Card list panel, create/filter/more buttons, project count
- **Project Selection**: Clicking project, detail panel, tabs
- **Create Dialog**: Open/close project creation dialog
- **Credit Management**: Balance cards (current/purchased/consumed), purchase button, history tabs
- **Voice Credits**: Section visibility, balance display, buy button
- **Voice Credit Purchase Dialog**: Warning banner, quantity stepper (--/++), defaults, increment/decrement, disabled states, balance impact, cancel, reset on re-open
- **Credit Purchase Dialog**: Quick select amounts, highlighting, close
- **Subscription Page**: Page load, heading, plan info, daily access chart
- **Subscription Voice Credits**: Paid user voice credit section and dialog

### admin-portal.test.ts - Admin Dashboard
- **Route Access**: Admin can access all /cms/admin/* routes
- **Dashboard**: Metrics (users, revenue, cards, digital access), refresh, quick actions
- **User Management**: Stats cards, table, pagination, search, role/tier filters, export CSV
- **Role Dialog**: Open, role selector, reason field, close
- **Subscription Dialog**: Open, tier cards, reason field, close
- **Credit Management**: System stats, user credits table, search, action buttons
- **Credit Dialogs**: Purchases, consumptions, transactions, adjust balance (amount + reason)
- **History Logs**: Filters (search, type, date range), activity list, pagination, export
- **User Projects**: Email search, user info banner, clear, empty state
- **Template Management**: Create/import/refresh buttons, search, venue filter, table/empty state
- **Template Create Dialog**: Card selector, slug input, close

### mobile-client.test.ts - Public Card Access (No Auth)
- **Card Overview**: Page load, title, explore button, language chip, info panel
- **Branding**: FunTell footer (non-premium) or hidden (premium)
- **AI Assistant (Overview)**: Indicator button, sparkles icon, open/close modal
- **Navigate to List**: Explore button navigation
- **Content List**: Layout detection (list/grid/grouped/collapsed/inline/single), items, ARIA roles
- **AI Badge (List)**: Browse badge visibility, opens modal
- **Content Detail**: Navigation from list, title, ARIA label
- **Detail Actions**: Favorite button, share button
- **Detail AI**: Item-level badge, content-item mode modal
- **Language Switching**: Language chip, selector opens, URL prefix switching
- **Error States**: Invalid card ID, error message
- **Mobile Viewport**: 375x812 rendering, title/button visibility

## Architecture

```
tests/e2e/
  helpers.ts              # Shared: driver setup, login, assertions, selectors
  auth.test.ts            # Authentication & route guards
  creator-portal.test.ts  # Creator dashboard (requires creator credentials)
  admin-portal.test.ts    # Admin dashboard (requires admin credentials)
  mobile-client.test.ts   # Public card access (requires card ID, no auth)
```
