# CardStudio Product Iteration Plan
## Q1 2026 Roadmap

**Document Owner:** Product Management  
**Last Updated:** December 2025  
**Status:** Draft for Review

---

## Executive Summary

CardStudio has evolved from a simple museum guide into a versatile **Digital Souvenir & Interactive Content Platform**. With the recent implementation of 5 content modes and dual billing models (Physical/Digital), we've expanded our Total Addressable Market significantly. This iteration plan focuses on **monetization optimization**, **platform stickiness**, and **operational efficiency** while addressing accumulated technical debt.

---

## Part 1: Current State Assessment

### ✅ Recently Completed Features (Nov-Dec 2025)

| Feature | Business Impact | Status |
|---------|----------------|--------|
| 5 Content Modes (Single, Grouped, List, Grid, Inline) | Expanded use cases from museums to restaurants, events, link-in-bio | ✅ Complete |
| Dual Access Modes (Physical/Digital) | New revenue stream via per-scan billing | ✅ Complete |
| Digital Access Charging | Real-time credit deduction + daily limits | ✅ Complete |
| Daily Credit Aggregation | Prevents transaction table fragmentation | ✅ Complete |
| Mobile Client UI/UX Overhaul | Modern, mode-specific layouts | ✅ Complete |
| CMS Contextual Forms | Intuitive per-mode content editing | ✅ Complete |
| Admin Portal Adaptation | Full visibility into new fields | ✅ Complete |
| Excel Export/Import | Includes all new fields | ✅ Complete |

### ⚠️ Known Technical Debt

| Debt Item | Severity | Impact | Est. Effort |
|-----------|----------|--------|-------------|
| **No analytics dashboard** | High | Can't measure engagement, churn | 3-5 days |
| **Missing webhook for low credit alerts** | Medium | Issuers run out of credits unexpectedly | 1-2 days |
| **Translation job history cleanup** | Low | Old jobs accumulate in database | 0.5 day |
| **No mobile push notifications** | Medium | Can't re-engage visitors | 5-7 days |
| **Image CDN optimization** | Medium | Slow load times for image-heavy cards | 2-3 days |
| **No bulk card duplication** | Low | Each card requires manual recreation | 1-2 days |
| **Test coverage gaps** | Medium | Regression risk on core flows | Ongoing |

### 📊 Platform Metrics (Estimated Baseline)

| Metric | Current | Target Q1 2026 |
|--------|---------|----------------|
| Active Card Issuers | — | +100% |
| Monthly Credit Consumption | — | +200% |
| Digital Access Adoption | 0% (new) | 30% of new cards |
| Average Content Items per Card | ~5 | 8+ |
| Visitor Return Rate | — | >15% |

---

## Part 2: Strategic Priorities

### 🎯 P0 - Revenue & Retention (Must Have)

These directly impact revenue generation and customer retention.

#### 2.1 Analytics Dashboard (Issuer Portal)
**Why:** Issuers cannot measure ROI without engagement data. This is the #1 feature request.

**Features:**
- Total scans (daily/weekly/monthly trends)
- Unique visitors vs repeat visitors
- Geographic distribution (by country/region)
- Content engagement (which items are viewed most)
- Peak usage times
- Comparison across cards

**Technical Approach:**
- Create `card_analytics` table with daily aggregated metrics
- Log anonymized scan events (IP country, timestamp, card_id, content_id)
- Build dashboard with Chart.js or similar
- Respect privacy (no PII stored)

**Effort:** 5-7 days  
**Revenue Impact:** High (demonstrates value, reduces churn)

---

#### 2.2 Low Credit Email Alerts
**Why:** Issuers' digital cards stop working when credits run out—often without warning.

**Features:**
- Email notification at 25%, 10%, 5% credit thresholds
- Weekly credit usage summary email
- In-app notification banner when balance < 10 credits

**Technical Approach:**
- Trigger function on `user_credits` update
- Integrate with email service (Resend, SendGrid, or Supabase Edge Functions)
- Store notification preferences in user settings

**Effort:** 2-3 days  
**Revenue Impact:** Prevents involuntary churn, increases credit purchases

---

#### 2.3 Credit Auto-Recharge (Stripe Subscriptions)
**Why:** Reduce friction for high-volume digital access users.

**Features:**
- Enable "Auto-recharge when balance drops below X credits"
- Configurable recharge amount ($10, $25, $50, $100)
- Stripe Customer Portal for payment method management
- Transaction history shows auto-recharges

**Technical Approach:**
- Extend Stripe integration with Subscriptions/Invoices API
- Add `auto_recharge_enabled`, `auto_recharge_threshold`, `auto_recharge_amount` to user settings
- Webhook handler for successful/failed payments

**Effort:** 4-5 days  
**Revenue Impact:** Very High (predictable recurring revenue)

---

### 🎯 P1 - Platform Expansion (Should Have)

Features that expand market reach and use cases.

#### 2.4 QR Code Customization
**Why:** Branded QR codes increase scan rates and brand consistency.

**Features:**
- Custom colors (foreground/background)
- Logo embedding (center of QR)
- Frame/border options
- Download in multiple formats (PNG, SVG, PDF)

**Technical Approach:**
- Extend existing QR generation with `qrcode` library options
- Add preview in CMS
- Store customization preferences per card

**Effort:** 2-3 days  
**Revenue Impact:** Medium (differentiator, reduces need for external tools)

---

#### 2.5 Scheduled Content Publishing
**Why:** Event organizers need content to go live at specific times.

**Features:**
- Set publish date/time for content items
- Set expiry date for time-limited content
- Visual indicator in CMS for scheduled/expired items
- Mobile client respects publish windows

**Technical Approach:**
- Add `published_at`, `expires_at` columns to `content_items`
- Filter in `get_public_card_content` stored procedure
- CMS date/time pickers

**Effort:** 2-3 days  
**Revenue Impact:** Medium (unlocks event use case)

---

#### 2.6 Multi-Language AI Voice
**Why:** Current AI voice is English-only. Multilingual visitors expect native language support.

**Features:**
- AI conversations in visitor's selected language
- Voice output in matching language/accent
- Automatic language detection option

**Technical Approach:**
- Already have language infrastructure from translations
- Update OpenAI Realtime API calls with language parameter
- Map languages to appropriate voice models

**Effort:** 3-4 days  
**Revenue Impact:** High (international market expansion)

---

### 🎯 P2 - Operational Excellence (Nice to Have)

Improve efficiency and reduce support burden.

#### 2.7 Card Templates / Duplication
**Why:** Issuers creating similar cards waste time rebuilding from scratch.

**Features:**
- "Duplicate Card" button
- Save card as template
- Browse and use community templates (future)
- Include content items in duplication

**Technical Approach:**
- New stored procedure `duplicate_card`
- Deep copy card + content items + sub-items
- Reset analytics counters

**Effort:** 1-2 days  
**Revenue Impact:** Low (time savings for power users)

---

#### 2.8 Bulk Operations
**Why:** Managing many cards/content items is tedious.

**Features:**
- Bulk delete cards
- Bulk enable/disable AI for multiple cards
- Bulk update content mode
- Bulk archive/unarchive

**Technical Approach:**
- Multi-select UI in card list
- Batch update stored procedures

**Effort:** 2-3 days  
**Revenue Impact:** Low (reduces support tickets)

---

#### 2.9 Image CDN & Optimization
**Why:** Image-heavy cards (Grid mode) load slowly.

**Features:**
- Automatic image compression on upload
- WebP format conversion
- Responsive image sizes (thumbnail, medium, full)
- CDN caching headers

**Technical Approach:**
- Supabase Storage transforms or external service (Cloudinary)
- Generate multiple sizes on upload
- Update image URLs in mobile client

**Effort:** 3-4 days  
**Revenue Impact:** Medium (better UX, reduced bounce)

---

### 🎯 P3 - Future Vision (Backlog)

Ideas for future consideration.

| Feature | Description | Effort |
|---------|-------------|--------|
| **Team Collaboration** | Multiple users manage same cards | Large |
| **White-Label Option** | Remove CardStudio branding for enterprise | Medium |
| **Offline Mode** | Cache card content for areas with poor connectivity | Medium |
| **AR Integration** | Augmented reality for museum exhibits | Large |
| **Visitor Feedback** | Like/comment on content items | Small |
| **Social Sharing** | Share card links with preview images | Small |
| **API Access** | Developer API for integrations | Large |
| **Custom Domains** | Issuers use their own domain for QR URLs | Medium |

---

## Part 3: Technical Debt Paydown Schedule

| Sprint | Debt Item | Effort | Notes |
|--------|-----------|--------|-------|
| Sprint 1 | Translation job cleanup cron | 0.5 day | Delete jobs older than 30 days |
| Sprint 1 | Add TypeScript strict mode | 1 day | Catch type errors early |
| Sprint 2 | Unit tests for credit system | 2 days | Critical path, high risk |
| Sprint 3 | E2E tests for card creation flow | 2 days | Vitest + Playwright |
| Sprint 4 | Performance audit | 1 day | Lighthouse, bundle analysis |

---

## Part 4: Proposed Sprint Plan

### Sprint 1 (Weeks 1-2): Foundation
| Item | Type | Effort | Owner |
|------|------|--------|-------|
| Analytics Dashboard - Backend | P0 Feature | 3 days | Backend |
| Analytics Dashboard - Frontend | P0 Feature | 3 days | Frontend |
| Translation job cleanup | Tech Debt | 0.5 day | Backend |
| TypeScript strict mode | Tech Debt | 1 day | Full Stack |

**Deliverable:** Issuers can see basic scan analytics

---

### Sprint 2 (Weeks 3-4): Revenue
| Item | Type | Effort | Owner |
|------|------|--------|-------|
| Low Credit Email Alerts | P0 Feature | 2 days | Backend |
| Credit Auto-Recharge | P0 Feature | 4 days | Full Stack |
| Unit tests for credit system | Tech Debt | 2 days | Backend |

**Deliverable:** Automated credit management, reduced involuntary churn

---

### Sprint 3 (Weeks 5-6): Expansion
| Item | Type | Effort | Owner |
|------|------|--------|-------|
| QR Code Customization | P1 Feature | 2 days | Frontend |
| Scheduled Content Publishing | P1 Feature | 3 days | Full Stack |
| E2E tests for card creation | Tech Debt | 2 days | QA |

**Deliverable:** Event organizers can schedule content, branded QR codes

---

### Sprint 4 (Weeks 7-8): Polish
| Item | Type | Effort | Owner |
|------|------|--------|-------|
| Multi-Language AI Voice | P1 Feature | 4 days | Backend |
| Card Duplication | P2 Feature | 2 days | Full Stack |
| Performance audit | Tech Debt | 1 day | Full Stack |
| Documentation update | Maintenance | 1 day | All |

**Deliverable:** International AI experience, power user features

---

## Part 5: Success Metrics

### Business KPIs
| Metric | Current | Target (End Q1) | Measurement |
|--------|---------|-----------------|-------------|
| Monthly Active Issuers | — | +50% | Unique logins |
| Credit Consumption Growth | — | +200% | Monthly total |
| Digital Access Share | 0% | 30% | % new cards using digital billing |
| Auto-Recharge Adoption | 0% | 20% | % paying users |
| NPS Score | — | >40 | Survey |

### Technical KPIs
| Metric | Current | Target | Measurement |
|--------|---------|--------|-------------|
| Mobile Load Time (P90) | ~3s | <2s | Lighthouse |
| API Error Rate | — | <0.1% | Logs |
| Test Coverage | ~10% | >50% | Jest/Vitest |
| Build Time | ~45s | <30s | CI/CD |

---

## Part 6: Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Stripe integration complexity delays auto-recharge | Medium | High | Start with MVP, iterate |
| Analytics increases database load | Low | Medium | Use aggregated tables, not raw logs |
| Multi-language AI increases OpenAI costs | Medium | Medium | Monitor usage, implement rate limits |
| Competition launches similar features | Medium | Medium | Focus on UX differentiation |

---

## Part 7: Dependencies

| Feature | External Dependency | Status |
|---------|---------------------|--------|
| Email Alerts | Email service (Resend/SendGrid) | Need to select provider |
| Auto-Recharge | Stripe Billing API | Available, need subscription setup |
| Multi-Language AI | OpenAI language models | Available for most languages |
| Image CDN | Supabase Transforms or Cloudinary | Evaluate cost/benefit |

---

## Appendix A: Database Schema Changes

```sql
-- Analytics (Sprint 1)
CREATE TABLE card_analytics_daily (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    card_id UUID REFERENCES cards(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    total_scans INTEGER DEFAULT 0,
    unique_visitors INTEGER DEFAULT 0,
    top_content_ids UUID[],
    country_distribution JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(card_id, date)
);

-- Scheduled Publishing (Sprint 3)
ALTER TABLE content_items 
ADD COLUMN published_at TIMESTAMPTZ DEFAULT NOW(),
ADD COLUMN expires_at TIMESTAMPTZ DEFAULT NULL;

-- Auto-Recharge (Sprint 2)
ALTER TABLE user_credits
ADD COLUMN auto_recharge_enabled BOOLEAN DEFAULT FALSE,
ADD COLUMN auto_recharge_threshold DECIMAL(10,2) DEFAULT 10,
ADD COLUMN auto_recharge_amount DECIMAL(10,2) DEFAULT 50;
```

---

## Appendix B: API Endpoints (New)

| Endpoint | Method | Sprint | Description |
|----------|--------|--------|-------------|
| `/api/analytics/:cardId` | GET | Sprint 1 | Get card analytics |
| `/api/analytics/:cardId/daily` | GET | Sprint 1 | Get daily breakdown |
| `/api/user/notifications/preferences` | GET/PUT | Sprint 2 | Email alert preferences |
| `/api/user/auto-recharge` | GET/PUT | Sprint 2 | Auto-recharge settings |
| `/api/stripe/create-subscription` | POST | Sprint 2 | Setup auto-recharge |

---

## Document Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | Dec 2025 | PM | Initial draft |

---

*This document should be reviewed and updated at the start of each sprint.*


