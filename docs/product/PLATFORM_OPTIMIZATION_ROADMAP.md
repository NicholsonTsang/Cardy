# FunTell Platform Optimization Roadmap
## Comprehensive Enhancement Strategy (2026)

**Document Version**: 1.0
**Last Updated**: February 15, 2026
**Status**: Approved for Implementation
**Owner**: Product Management Team
**Review Cycle**: Quarterly

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Strategic Context](#strategic-context)
3. [Mobile Client Optimization Plan](#mobile-client-optimization-plan)
4. [Creator Portal Optimization Plan](#creator-portal-optimization-plan)
5. [Unified Implementation Timeline](#unified-implementation-timeline)
6. [Resource Allocation](#resource-allocation)
7. [Success Metrics & KPIs](#success-metrics--kpis)
8. [Risk Management](#risk-management)
9. [Go-to-Market Strategy](#go-to-market-strategy)
10. [Appendices](#appendices)

---

## Executive Summary

### Overview

FunTell (FunTell) is embarking on a comprehensive platform optimization initiative targeting both the **visitor experience (Mobile Client)** and **creator experience (Dashboard/Portal)**. This dual-track strategy addresses critical gaps in user experience, performance, and enterprise readiness while building on our strong technical foundations.

### Current State Assessment

**Mobile Client** (Visitor-Facing):
- ✅ Strong: Polished UI/UX, dual AI assistant system, multilingual support (10 languages)
- ⚠️ Gaps: Discovery features (search/filter), accessibility compliance, offline capability
- 📊 Score: 68/100

**Creator Portal** (Dashboard/CMS):
- ✅ Strong: Solid architecture, AI auto-generation, translation workflow, subscription management
- ⚠️ Gaps: Bulk operations, team collaboration, advanced analytics, mobile UX
- 📊 Score: 62/100

### Strategic Direction

Transform from:
- **Mobile Client**: Content viewer → Intelligent discovery platform
- **Creator Portal**: Solo creator tool → Enterprise collaborative platform

### Investment & ROI

| Workstream | Duration | Investment | Projected ROI (12mo) |
|------------|----------|------------|---------------------|
| Mobile Client | 16 weeks | $128,000 | +100% session duration, +130% return visitors |
| Creator Portal | 24 weeks | $128,000 | +45% MRR, 133% return on investment |
| **Total** | **24 weeks** | **$256,000** | **$170K+ annual revenue increase** |

**Combined Payback Period**: 6-9 months

### Key Outcomes (12 Months)

**Mobile Client**:
- Session duration: 2.5 min → 5.0 min (+100%)
- AI engagement: 20% → 40% (+100%)
- Return visitors: 15% → 35% (+133%)

**Creator Portal**:
- Creator retention (90-day): 52% → 75% (+44%)
- Time to first publish: 45 min → 10 min (-78%)
- Monthly Recurring Revenue: $32K → $46K (+45%)

---

## Strategic Context

### Market Position

FunTell operates in the **AI-powered content experience** market, serving:
- **B2C**: Visitors accessing content via QR codes/links (10M+ annual sessions target)
- **B2B**: Content creators (museums, restaurants, educators, businesses) managing immersive experiences

### Competitive Landscape

| Competitor | Strength | Our Advantage |
|------------|----------|---------------|
| QR Code Generators | Simple, cheap | AI assistants + multilingual + analytics |
| CMS Platforms | Full-featured | Mobile-first + real-time voice + QR distribution |
| Museum Apps | Domain-specific | Multi-industry + easy setup + affordable |

**Differentiation**: Only platform combining **QR distribution + AI assistants + 10 languages + no-code setup**

### User Personas

#### Visitor Personas (Mobile Client)

**Persona 1: Curious Traveler** (40%)
- Age: 25-45, tech-savvy
- Needs: Quick information, multiple languages, AI Q&A
- Pain Points: Slow content discovery, no offline access

**Persona 2: Educational Visitor** (35%)
- Age: 18-65, students/teachers
- Needs: Deep dive content, save favorites, share with class
- Pain Points: Can't bookmark, no search, hard to find specific topics

**Persona 3: Accessibility-Dependent** (15%)
- Age: All ages, visual/motor impairments
- Needs: Screen reader support, large touch targets, voice navigation
- Pain Points: Missing ARIA labels, low contrast, small buttons

#### Creator Personas (Dashboard)

**Persona 1: Solo Content Creator** (40%)
- Profile: Small business, educator, artist
- Needs: Quick setup, easy updates, affordable
- Pain Points: Confusing mobile UI, no templates for industry

**Persona 2: Professional Creator** (35%)
- Profile: Agency, consultant, 5-15 clients
- Needs: Rapid production, bulk operations, client analytics
- Pain Points: No duplication, no CSV import, limited analytics

**Persona 3: Enterprise Organization** (15%)
- Profile: Museum, university, 20-35 projects
- Needs: Team collaboration, brand consistency, advanced security
- Pain Points: No team features, no SSO, no API access

**Persona 4: Platform Admin** (10%)
- Profile: Internal operations team
- Needs: User management, platform health, revenue analytics
- Pain Points: Limited admin tooling, no user analytics dashboard

### Business Model

**Current (3-Tier)**:

| Tier | Price | Projects | Sessions | Current Users | MRR |
|------|-------|----------|----------|---------------|-----|
| Free | $0 | 3 | 50/month | 70 | $0 |
| Starter | $40/mo | 5 | $40 budget | 25 | $1,000 |
| Premium | $280/mo | 35 | $280 budget | 5 | $1,400 |
| **Total** | | | | **100** | **$2,400** |

**Projected (4-Tier + Add-Ons)**:

| Tier | Price | Projects | Sessions | Seats | Projected Users | MRR |
|------|-------|----------|----------|-------|-----------------|-----|
| Free | $0 | 3 | 50/month | 1 | 50 | $0 |
| Starter | $40/mo | 5 | $40 budget | 1 | 30 | $1,200 |
| Premium | $280/mo | 35 | $280 budget | 3 | 30 | $8,400 |
| Enterprise | $500/mo | 100 | $500 budget | 10 | 20 | $10,000 |
| Add-Ons | | | | | | $3,000 |
| **Total** | | | | | **130** | **$22,600** |

**Additional Revenue**:
- Extra seats: $50/seat/month (avg 3 seats × 20 Enterprise = $3,000)
- API access: $100/month (20 users = $2,000)
- White-label: $200/month (10 users = $2,000)

**Total Projected MRR**: $29,600 (+1,133% from current $2,400)

---

## Mobile Client Optimization Plan

### Current State Analysis

**Architecture**: Vue 3 + TypeScript + PrimeVue + Tailwind CSS
**Backend**: Express.js, Supabase PostgreSQL, Upstash Redis
**AI Features**: OpenAI Realtime API (WebRTC), Chat Completion, voice recording

#### Feature Completeness (68/100)

| Category | Status | Quality | Priority |
|----------|--------|---------|----------|
| Content Display (4 modes) | ✅ Complete | ⭐⭐⭐⭐⭐ | - |
| Dual AI Assistants | ✅ Complete | ⭐⭐⭐⭐⭐ | - |
| 10 Languages + Voice | ✅ Complete | ⭐⭐⭐⭐ | - |
| Search/Filter | ❌ Missing | - | P0 |
| Favorites/Bookmarks | ❌ Missing | - | P0 |
| Share Functionality | ❌ Missing | - | P1 |
| ARIA Labels | ⚠️ Partial | ⭐⭐ | P0 |
| Offline Support | ❌ Missing | - | P2 |
| Virtual Scrolling | ❌ Missing | - | P2 |

### Strategic Priorities

#### Pillar 1: Discoverability 🔍
*Make it easy to find the right content, fast*

**Initiatives**:
- Search with instant results
- Smart filtering (category, language)
- Previous/Next navigation
- Breadcrumb trails

**Target Metrics**:
- Search usage: 0% → 45%
- Items per session: 2.3 → 5.2
- Time to find content: -60%

#### Pillar 2: Accessibility ♿
*Ensure inclusive access for all users*

**Initiatives**:
- Full ARIA labeling
- WCAG AA/AAA compliance
- Keyboard navigation
- High contrast mode

**Target Metrics**:
- WCAG compliance: 60% → 100%
- Accessibility score: C → A+

#### Pillar 3: Engagement 💡
*Turn viewers into active, returning users*

**Initiatives**:
- Favorites/bookmarks
- Share functionality
- Browsing history
- Offline access

**Target Metrics**:
- Return visitors: 15% → 35%
- Shares per 100 visitors: 0 → 12

#### Pillar 4: Performance ⚡
*Deliver instant, smooth experiences*

**Initiatives**:
- Virtual scrolling
- Progressive image loading
- Service worker caching
- Optimistic UI

**Target Metrics**:
- Time to interactive: 2.1s → 1.2s
- FPS on scroll: 45 → 60fps

### Implementation Phases

#### Phase 0: Foundation (Week 1-2)
**Goal**: Compliance & Quick Wins

| Feature | Effort | Impact |
|---------|--------|--------|
| ARIA labels on all interactive elements | 1 day | High |
| WCAG color contrast fixes | 4 hours | High |
| Share buttons (Web Share API) | 3 hours | High |
| Favorites with localStorage | 4 hours | High |

**Deliverables**:
- ✅ WCAG AA compliance
- ✅ Share on all content items
- ✅ Basic favorites system

#### Phase 1: Discovery (Week 3-4)
**Goal**: Help users find content quickly

| Feature | Effort | Impact |
|---------|--------|--------|
| Search input with real-time filtering | 1 day | Very High |
| Category filter chips | 4 hours | High |
| Sort dropdown (A-Z, date, popular) | 3 hours | Medium |
| Previous/Next navigation | 3 hours | High |

**Deliverables**:
- ✅ Global search
- ✅ Filter by category
- ✅ Swipe navigation

#### Phase 2: Engagement (Week 5-6)
**Goal**: Turn one-time visitors into returning users

| Feature | Effort | Impact |
|---------|--------|--------|
| Browsing history (last 20 items) | 4 hours | High |
| Enhanced favorites UI | 3 hours | Medium |
| Related content recommendations | 1 day | Very High |
| AI onboarding tooltip | 2 hours | High |

**Deliverables**:
- ✅ History & favorites management
- ✅ AI feature discovery
- ✅ Content recommendations

#### Phase 3: Performance (Week 7-8)
**Goal**: Deliver instant, reliable experiences

| Feature | Effort | Impact |
|---------|--------|--------|
| Virtual scrolling | 1 day | High |
| Image lazy loading + blur-up | 1 day | High |
| WebP images with fallback | 4 hours | Medium |
| Service worker for offline | 2 days | Very High |

**Deliverables**:
- ✅ 60fps scroll on 100+ items
- ✅ Offline content access
- ✅ Progressive image loading

#### Phase 4: Intelligence (Week 9-12)
**Goal**: Make AI the primary interaction mode

| Feature | Effort | Impact |
|---------|--------|--------|
| AI-powered search (semantic) | 2 days | Very High |
| Voice-first mode | 1 day | High |
| AI content summaries | 1 day | High |
| Conversation history | 1 day | Medium |

**Deliverables**:
- ✅ Semantic search
- ✅ Persistent conversations
- ✅ Voice-first interaction

#### Phase 5: Analytics (Week 13-16)
**Goal**: Understand behavior, optimize engagement

| Feature | Effort | Impact |
|---------|--------|--------|
| Event tracking (Mixpanel) | 2 days | High |
| Heatmaps & session replay | 1 day | Medium |
| Popular content section | 4 hours | High |

**Deliverables**:
- ✅ Comprehensive analytics
- ✅ Data-driven optimization

### Technical Specifications

#### Search & Filter Implementation

**Frontend (Client-Side Search)**:

```typescript
// composables/useContentSearch.ts
export function useContentSearch(items: Ref<ContentItem[]>) {
  const searchQuery = ref('')
  const selectedCategory = ref<string | null>(null)
  const sortOrder = ref<'default' | 'a-z' | 'popular'>('default')

  const filteredItems = computed(() => {
    let result = items.value

    // Search filter
    if (searchQuery.value) {
      const query = searchQuery.value.toLowerCase()
      result = result.filter(item =>
        item.content_item_name.toLowerCase().includes(query) ||
        item.content_item_content?.toLowerCase().includes(query)
      )
    }

    // Category filter
    if (selectedCategory.value) {
      result = result.filter(item =>
        item.content_item_parent_id === selectedCategory.value
      )
    }

    // Sort
    return sortItems(result, sortOrder.value)
  })

  return {
    searchQuery,
    selectedCategory,
    sortOrder,
    filteredItems
  }
}
```

#### Favorites System

**Implementation**:

```typescript
// composables/useFavorites.ts
export function useFavorites(cardId: string) {
  const STORAGE_KEY = `favorites_${cardId}`
  const favorites = ref<string[]>([])

  onMounted(() => {
    const stored = localStorage.getItem(STORAGE_KEY)
    favorites.value = stored ? JSON.parse(stored) : []
  })

  function toggleFavorite(itemId: string) {
    const index = favorites.value.indexOf(itemId)
    if (index > -1) {
      favorites.value.splice(index, 1)
    } else {
      favorites.value.push(itemId)
    }
    localStorage.setItem(STORAGE_KEY, JSON.stringify(favorites.value))
  }

  function isFavorite(itemId: string) {
    return favorites.value.includes(itemId)
  }

  return { favorites, toggleFavorite, isFavorite }
}
```

#### Share Functionality

**Web Share API with Fallback**:

```typescript
async function shareContent(item: ContentItem) {
  const shareData = {
    title: item.content_item_name,
    text: truncate(item.content_item_content, 120),
    url: `${window.location.origin}/${route.params.lang}/c/${cardId}/item/${item.content_item_id}`
  }

  try {
    if (navigator.share) {
      await navigator.share(shareData)
      trackEvent('content_shared', { method: 'native' })
    } else {
      await navigator.clipboard.writeText(shareData.url)
      showToast('Link copied to clipboard!')
      trackEvent('content_shared', { method: 'clipboard' })
    }
  } catch (error) {
    console.error('Share failed:', error)
  }
}
```

#### Offline Support (Service Worker)

**Basic Strategy**:

```javascript
// public/service-worker.js
const CACHE_NAME = 'funtell-v1'
const CACHED_URLS = [
  '/',
  '/offline.html',
  '/assets/styles.css',
  '/assets/app.js'
]

self.addEventListener('install', event => {
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then(cache => cache.addAll(CACHED_URLS))
  )
})

self.addEventListener('fetch', event => {
  event.respondWith(
    caches.match(event.request)
      .then(response => response || fetch(event.request))
      .catch(() => caches.match('/offline.html'))
  )
})
```

---

## Creator Portal Optimization Plan

### Current State Analysis

**Architecture**: Vue 3 + TypeScript + PrimeVue, Pinia stores, RPC-only database access
**Backend**: Express.js, Supabase (stored procedures), Stripe, Google Gemini (translations)

#### Feature Completeness (62/100)

| Category | Status | Quality | Priority |
|----------|--------|---------|----------|
| Card CRUD | ✅ Complete | ⭐⭐⭐⭐ | - |
| AI Auto-Generation | ✅ Complete | ⭐⭐⭐⭐⭐ | - |
| Translation (10 languages) | ✅ Complete | ⭐⭐⭐⭐ | - |
| Subscription Management | ✅ Complete | ⭐⭐⭐⭐ | - |
| Duplicate Card | ❌ Missing | - | P0 |
| Bulk Operations (CSV) | ❌ Missing | - | P0 |
| Team Collaboration | ❌ Missing | - | P1 |
| Advanced Analytics | ⚠️ Basic | ⭐⭐ | P1 |
| Mobile Creator UX | ⚠️ Partial | ⭐⭐ | P0 |
| Version History | ❌ Missing | - | P2 |

### Strategic Priorities

#### Pillar 1: Creator Velocity ⚡
*Reduce time-to-launch from 45 min to 10 min*

**Initiatives**:
- AI-guided setup wizard
- CSV/Excel bulk import
- Duplicate card feature
- Template marketplace expansion
- URL scraping (auto-generate from website)

**Target Metrics**:
- Time to first card: 45 min → 10 min
- Items added per hour: 8 → 40

#### Pillar 2: Team Collaboration 👥
*Enable organizations to work together*

**Initiatives**:
- Multi-user accounts (roles/permissions)
- Real-time collaborative editing
- Activity feed & notifications
- Approval workflows (draft → published)

**Target Metrics**:
- Enterprise tier adoption: 0% → 12%
- Team accounts: 0 → 200

#### Pillar 3: Data-Driven Insights 📊
*Give creators actionable analytics*

**Initiatives**:
- Analytics drill-down (QR, item, device)
- Export reports (PDF, Excel)
- Visitor journey tracking
- A/B testing framework
- AI conversation analytics

**Target Metrics**:
- Analytics usage: 20% → 65%
- Optimization cycles: 0 → 2.5/month

#### Pillar 4: Enterprise Readiness 🏢
*Become platform of choice for large orgs*

**Initiatives**:
- SSO/SAML authentication
- White-label options
- API access
- Advanced security (audit logs, 2FA)
- SLA guarantees

**Target Metrics**:
- Enterprise customers: 0 → 25
- Avg contract value: $500/month

### Implementation Phases

#### Phase 0: Foundation (Week 1-4)
**Goal**: Quick wins & mobile UX

| Feature | Effort | Impact |
|---------|--------|--------|
| Duplicate card functionality | 3 days | Very High |
| Bulk delete content items | 2 days | High |
| Mobile-responsive dashboard | 1 week | Very High |
| Keyboard shortcuts | 2 days | Medium |

**Deliverables**:
- ✅ 1-click card duplication
- ✅ Bulk operations
- ✅ Mobile-optimized layout

#### Phase 1: Bulk Operations (Week 5-8)
**Goal**: Enable rapid content creation

| Feature | Effort | Impact |
|---------|--------|--------|
| CSV/Excel import | 1.5 weeks | Very High |
| Bulk edit (multi-select) | 1 week | High |
| Bulk translate | 3 days | High |
| AI content generation | 1 week | Very High |
| URL scraper | 1 week | High |

**Deliverables**:
- ✅ CSV upload (1000+ items)
- ✅ Bulk edit modal
- ✅ AI content expander
- ✅ Website scraper

#### Phase 2: Analytics (Week 9-12)
**Goal**: Actionable data

| Feature | Effort | Impact |
|---------|--------|--------|
| Analytics drill-down | 2 weeks | Very High |
| Export reports | 1 week | High |
| Visitor journey tracking | 1 week | High |
| AI conversation logs | 1.5 weeks | Very High |

**Deliverables**:
- ✅ Advanced analytics dashboard
- ✅ PDF/Excel export
- ✅ AI conversation insights

#### Phase 3: Collaboration (Week 13-18)
**Goal**: Team features

| Feature | Effort | Impact |
|---------|--------|--------|
| Multi-user accounts | 3 weeks | Very High |
| Real-time editing (CRDT) | 2 weeks | High |
| Activity feed | 1 week | Medium |
| Approval workflows | 1.5 weeks | High |

**Deliverables**:
- ✅ Team member invites
- ✅ Live collaboration
- ✅ Draft mode

#### Phase 4: Enterprise (Week 19-24)
**Goal**: Enterprise readiness

| Feature | Effort | Impact |
|---------|--------|--------|
| SSO/SAML | 2 weeks | Very High |
| White-label | 1.5 weeks | High |
| API access | 2 weeks | Very High |
| Audit logs | 1 week | High |

**Deliverables**:
- ✅ Enterprise tier ($500/mo)
- ✅ SSO login
- ✅ REST API
- ✅ White-label branding

### Technical Specifications

#### CSV/Excel Bulk Import

**Frontend Parser**:

```typescript
import Papa from 'papaparse'

interface CsvRow {
  [key: string]: string
}

interface MappingConfig {
  title: string
  content: string
  category: string
  imageUrl?: string
}

async function parseCsvFile(file: File): Promise<CsvRow[]> {
  return new Promise((resolve, reject) => {
    Papa.parse(file, {
      header: true,
      skipEmptyLines: true,
      complete: (results) => resolve(results.data as CsvRow[]),
      error: (error) => reject(error)
    })
  })
}

async function importCsvItems(
  cardId: string,
  rows: CsvRow[],
  mapping: MappingConfig
) {
  const BATCH_SIZE = 100
  const items = rows.map(row => ({
    name: row[mapping.title],
    content: row[mapping.content],
    parent_id: row[mapping.category] || null,
    image_url: row[mapping.imageUrl] || null
  }))

  // Process in batches
  for (let i = 0; i < items.length; i += BATCH_SIZE) {
    const batch = items.slice(i, i + BATCH_SIZE)
    await supabase.rpc('bulk_create_content_items', {
      p_card_id: cardId,
      p_items: batch
    })
    updateProgress((i + BATCH_SIZE) / items.length * 100)
  }
}
```

**Backend RPC** (SQL):

```sql
CREATE OR REPLACE FUNCTION bulk_create_content_items(
  p_card_id UUID,
  p_items JSONB
) RETURNS JSONB AS $$
DECLARE
  v_item JSONB;
  v_result JSONB := '[]'::JSONB;
BEGIN
  FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
  LOOP
    INSERT INTO content_items (
      card_id,
      name,
      content,
      parent_id,
      image_url,
      sort_order
    ) VALUES (
      p_card_id,
      v_item->>'name',
      v_item->>'content',
      (v_item->>'parent_id')::UUID,
      v_item->>'image_url',
      (SELECT COALESCE(MAX(sort_order), 0) + 1 FROM content_items WHERE card_id = p_card_id)
    )
    RETURNING jsonb_build_object('id', id, 'name', name) INTO v_item;

    v_result := v_result || v_item;
  END LOOP;

  RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

#### Duplicate Card Feature

**Store Action**:

```typescript
// stores/card.ts
async duplicateCard(originalCardId: string, newName: string) {
  try {
    // 1. Fetch original card + content
    const { data: original } = await supabase.rpc('get_card_with_content', {
      p_card_id: originalCardId
    })

    // 2. Create new card
    const newCard = await this.addCard({
      name: newName,
      description: original.description,
      content_mode: original.content_mode,
      is_grouped: original.is_grouped,
      original_language: original.original_language,
      conversation_ai_enabled: original.conversation_ai_enabled,
      ai_instruction: original.ai_instruction,
      ai_knowledge_base: original.ai_knowledge_base,
      ai_welcome_general: original.ai_welcome_general,
      ai_welcome_item: original.ai_welcome_item
    })

    // 3. Clone images
    if (original.image_url) {
      const newImageUrl = await cloneImageToUserStorage(original.image_url)
      await this.updateCard(newCard.id, { image_url: newImageUrl })
    }

    // 4. Bulk create content items
    const items = original.content_items.map(item => ({
      name: item.name,
      content: item.content,
      parent_id: item.parent_id,
      ai_knowledge_base: item.ai_knowledge_base,
      sort_order: item.sort_order
    }))

    await supabase.rpc('bulk_create_content_items', {
      p_card_id: newCard.id,
      p_items: items
    })

    return newCard
  } catch (error) {
    console.error('Duplicate failed:', error)
    throw error
  }
}

async function cloneImageToUserStorage(originalUrl: string): Promise<string> {
  const response = await fetch(originalUrl)
  const blob = await response.blob()
  const newPath = `${userId}/card-images/${uuidv4()}_cloned.jpg`
  await supabase.storage.from('userfiles').upload(newPath, blob)
  return supabase.storage.from('userfiles').getPublicUrl(newPath).data.publicUrl
}
```

#### Team Collaboration (Multi-User)

**Database Schema**:

```sql
-- Teams table
CREATE TABLE teams (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  owner_user_id UUID REFERENCES users(id),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Team members
CREATE TABLE team_members (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  team_id UUID REFERENCES teams(id) ON DELETE CASCADE,
  user_id UUID REFERENCES users(id),
  role TEXT CHECK (role IN ('owner', 'editor', 'viewer', 'approver')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(team_id, user_id)
);

-- Card access control
CREATE TABLE card_team_access (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  card_id UUID REFERENCES cards(id) ON DELETE CASCADE,
  team_id UUID REFERENCES teams(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Activity feed
CREATE TABLE team_activity (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  team_id UUID REFERENCES teams(id),
  user_id UUID REFERENCES users(id),
  action TEXT,  -- 'created', 'edited', 'deleted', 'published'
  resource_type TEXT,  -- 'card', 'content_item', 'translation'
  resource_id UUID,
  details JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

**Permission Middleware** (Backend):

```typescript
// middleware/teamAuth.ts
export async function requireTeamPermission(
  teamId: string,
  userId: string,
  requiredRole: 'owner' | 'editor' | 'viewer' | 'approver'
) {
  const { data: member } = await supabase
    .from('team_members')
    .select('role')
    .eq('team_id', teamId)
    .eq('user_id', userId)
    .single()

  if (!member) {
    throw new Error('Not a team member')
  }

  const roleHierarchy = {
    owner: 4,
    approver: 3,
    editor: 2,
    viewer: 1
  }

  if (roleHierarchy[member.role] < roleHierarchy[requiredRole]) {
    throw new Error('Insufficient permissions')
  }
}
```

**Real-Time Collaboration (Yjs)**:

```typescript
import * as Y from 'yjs'
import { WebrtcProvider } from 'y-webrtc'

const doc = new Y.Doc()
const provider = new WebrtcProvider(`card-${cardId}`, doc)

// Shared content
const yContent = doc.getText('content')

// Bind to editor
yContent.observe(event => {
  updateEditor(yContent.toString())
})

// Awareness (who's online)
provider.awareness.setLocalStateField('user', {
  name: currentUser.name,
  color: currentUser.color
})

provider.awareness.on('change', () => {
  const states = Array.from(provider.awareness.getStates().values())
  updatePresenceIndicators(states)
})
```

#### Advanced Analytics Dashboard

**Backend Analytics Aggregation**:

```sql
-- Daily analytics aggregation (runs nightly)
CREATE OR REPLACE FUNCTION aggregate_daily_analytics(p_date DATE)
RETURNS VOID AS $$
BEGIN
  INSERT INTO daily_analytics (
    card_id,
    date,
    total_sessions,
    ai_sessions,
    non_ai_sessions,
    total_cost,
    top_content_items,
    top_qr_codes
  )
  SELECT
    s.card_id,
    p_date,
    COUNT(*) as total_sessions,
    COUNT(*) FILTER (WHERE s.ai_enabled = true) as ai_sessions,
    COUNT(*) FILTER (WHERE s.ai_enabled = false) as non_ai_sessions,
    SUM(s.cost) as total_cost,
    (
      SELECT jsonb_agg(jsonb_build_object('item_id', item_id, 'views', view_count))
      FROM (
        SELECT content_item_id as item_id, COUNT(*) as view_count
        FROM content_item_views
        WHERE card_id = s.card_id AND DATE(viewed_at) = p_date
        GROUP BY content_item_id
        ORDER BY view_count DESC
        LIMIT 10
      ) top_items
    ) as top_content_items,
    (
      SELECT jsonb_agg(jsonb_build_object('token_id', token_id, 'scans', scan_count))
      FROM (
        SELECT access_token_id as token_id, COUNT(*) as scan_count
        FROM sessions
        WHERE card_id = s.card_id AND DATE(created_at) = p_date
        GROUP BY access_token_id
        ORDER BY scan_count DESC
        LIMIT 10
      ) top_tokens
    ) as top_qr_codes
  FROM sessions s
  WHERE DATE(s.created_at) = p_date
  GROUP BY s.card_id;
END;
$$ LANGUAGE plpgsql;
```

**Frontend Analytics Drill-Down**:

```typescript
// composables/useAnalytics.ts
export function useAnalytics(cardId: string) {
  const dateRange = ref<[Date, Date]>([
    new Date(Date.now() - 30 * 24 * 60 * 60 * 1000),
    new Date()
  ])
  const selectedQrCode = ref<string | null>(null)
  const selectedDevice = ref<'all' | 'mobile' | 'tablet' | 'desktop'>('all')

  const { data: analytics, isLoading } = useQuery({
    queryKey: ['analytics', cardId, dateRange, selectedQrCode, selectedDevice],
    queryFn: async () => {
      const { data } = await supabase.rpc('get_card_analytics', {
        p_card_id: cardId,
        p_start_date: dateRange.value[0].toISOString(),
        p_end_date: dateRange.value[1].toISOString(),
        p_qr_code_id: selectedQrCode.value,
        p_device_type: selectedDevice.value === 'all' ? null : selectedDevice.value
      })
      return data
    }
  })

  async function exportToPdf() {
    // Generate PDF report
    const pdf = await generateAnalyticsReport(analytics.value)
    downloadFile(pdf, `analytics-${cardId}-${Date.now()}.pdf`)
  }

  async function exportToExcel() {
    // Generate Excel spreadsheet
    const xlsx = await generateExcelReport(analytics.value)
    downloadFile(xlsx, `analytics-${cardId}-${Date.now()}.xlsx`)
  }

  return {
    analytics,
    isLoading,
    dateRange,
    selectedQrCode,
    selectedDevice,
    exportToPdf,
    exportToExcel
  }
}
```

---

## Unified Implementation Timeline

### 24-Week Master Schedule

```
┌─────────────────────────────────────────────────────────────┐
│                    MOBILE CLIENT (16 weeks)                  │
├─────────────────────────────────────────────────────────────┤
│ Week 1-2:  Phase 0 - Foundation (ARIA, Share, Favorites)    │
│ Week 3-4:  Phase 1 - Discovery (Search, Filter, Nav)        │
│ Week 5-6:  Phase 2 - Engagement (History, Recommendations)  │
│ Week 7-8:  Phase 3 - Performance (Virtual Scroll, Offline)  │
│ Week 9-12: Phase 4 - Intelligence (AI Search, Voice-First)  │
│ Week 13-16: Phase 5 - Analytics (Event Tracking, Heatmaps)  │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                  CREATOR PORTAL (24 weeks)                   │
├─────────────────────────────────────────────────────────────┤
│ Week 1-4:   Phase 0 - Foundation (Duplicate, Mobile UX)     │
│ Week 5-8:   Phase 1 - Bulk Ops (CSV Import, AI Generate)    │
│ Week 9-12:  Phase 2 - Analytics (Drill-Down, Export)        │
│ Week 13-18: Phase 3 - Collaboration (Teams, Real-Time)      │
│ Week 19-24: Phase 4 - Enterprise (SSO, API, White-Label)    │
└─────────────────────────────────────────────────────────────┘
```

### Parallel Execution Strategy

**Weeks 1-4**: Both teams work independently
- Mobile: Foundation + Discovery
- Creator: Foundation

**Weeks 5-8**: Shared backend coordination
- Mobile: Engagement + Performance
- Creator: Bulk Operations
- **Coordination**: Both need backend API updates (analytics, bulk endpoints)

**Weeks 9-12**: Backend-heavy phase
- Mobile: Intelligence (AI search)
- Creator: Analytics dashboard
- **Coordination**: Both teams share AI/analytics backend resources

**Weeks 13-16**: Mobile wraps, Creator continues
- Mobile: Analytics & polish
- Creator: Collaboration features

**Weeks 17-24**: Creator-only (Enterprise features)
- Creator: SSO, API, white-label

### Critical Path Analysis

**Longest Dependencies**:
1. Analytics Backend (Week 9-12): Both mobile & creator depend on this
2. Team Collaboration (Week 13-18): Complex real-time features
3. SSO/SAML Integration (Week 19-20): Enterprise blocker

**Risk Mitigation**:
- Analytics: Start backend work Week 8 (pre-sprint)
- Collaboration: Proof-of-concept Yjs integration Week 12
- SSO: Partner selection & contract Week 16-17

---

## Resource Allocation

### Team Structure

#### Mobile Client Team

**Phase 0-2 (Week 1-6)**:
- 2× Senior Frontend Engineers (Vue 3 experts)
- 1× UX Designer (accessibility focus)

**Phase 3-5 (Week 7-16)**:
- 2× Senior Frontend Engineers
- 1× Backend Engineer (analytics, offline sync)
- 1× UX Designer

**Total**: 2-3 FTE over 16 weeks

#### Creator Portal Team

**Phase 0-1 (Week 1-8)**:
- 2× Senior Frontend Engineers
- 1× UI/UX Designer

**Phase 2-3 (Week 9-18)**:
- 2× Frontend Engineers
- 1× Backend Engineer (analytics, real-time)
- 1× Full Stack Engineer (collaboration)
- 1× UI/UX Designer

**Phase 4 (Week 19-24)**:
- 2× Full Stack Engineers
- 1× DevOps Engineer (SSO, infrastructure)
- 1× Security Consultant (part-time)

**Total**: 2-4 FTE over 24 weeks

### Budget Breakdown

| Workstream | Phase | Duration | Resources | Cost |
|------------|-------|----------|-----------|------|
| **Mobile Client** | | | | |
| Phase 0-1 | Foundation + Discovery | 4 weeks | 2 FE + 1 Designer | $24,000 |
| Phase 2-3 | Engagement + Performance | 4 weeks | 2 FE + 1 BE + 1 Designer | $28,000 |
| Phase 4 | Intelligence | 4 weeks | 2 FE + 1 BE + 1 Designer | $28,000 |
| Phase 5 | Analytics | 4 weeks | 2 FE + 1 BE | $24,000 |
| **Mobile Subtotal** | | **16 weeks** | | **$104,000** |
| | | | | |
| **Creator Portal** | | | | |
| Phase 0 | Foundation | 4 weeks | 2 FE + 1 Designer | $16,000 |
| Phase 1 | Bulk Operations | 4 weeks | 2 FE + 1 Designer | $16,000 |
| Phase 2 | Analytics | 4 weeks | 2 FE + 1 BE + 1 Designer | $20,000 |
| Phase 3 | Collaboration | 6 weeks | 2 FE + 1 BE + 1 FS + 1 Designer | $36,000 |
| Phase 4 | Enterprise | 6 weeks | 2 FS + 1 DevOps + Security | $36,000 |
| **Creator Subtotal** | | **24 weeks** | | **$124,000** |
| | | | | |
| **Contingency** | (10%) | | | $22,800 |
| **Total** | | **24 weeks** | | **$250,800** |

**Average Burn Rate**: $10,450/week
**Peak Burn Rate**: $15,000/week (Week 13-18, both teams at full capacity)

### Hiring Plan

| Week | Role | Type | Reason |
|------|------|------|--------|
| Week 0 | 2× Senior Frontend (Vue 3) | Full-time | Mobile client foundation |
| Week 0 | 1× UX Designer | Full-time | Accessibility & mobile UX |
| Week 0 | 2× Frontend Engineers | Full-time | Creator portal |
| Week 7 | 1× Backend Engineer | Full-time | Analytics, offline sync |
| Week 9 | 1× Full Stack Engineer | Full-time | Real-time collaboration |
| Week 19 | 1× DevOps Engineer | Contract | SSO/SAML infrastructure |
| Week 19 | 1× Security Consultant | Part-time | Enterprise security audit |

**Total Headcount**: 7 engineers + 1 designer + 1 consultant

---

## Success Metrics & KPIs

### North Star Metrics

**Mobile Client**:
- **Primary**: Session Duration (2.5 min → 5.0 min, +100%)
- **Secondary**: Return Visitor Rate (15% → 35%, +133%)

**Creator Portal**:
- **Primary**: Creator Retention 90-day (52% → 75%, +44%)
- **Secondary**: Monthly Recurring Revenue ($2,400 → $22,600, +842%)

### Leading Indicators (Weekly Tracking)

#### Mobile Client

| Metric | Baseline | Target | Alert Threshold |
|--------|----------|--------|-----------------|
| Search Usage | 0% | 45% | <20% |
| Favorite Adoption | 0% | 25% | <10% |
| Share Rate | 0% | 8% | <3% |
| AI Engagement | 20% | 40% | <25% |
| Mobile FPS | 45fps | 60fps | <50fps |
| WCAG Compliance | 60% | 100% | <90% |

#### Creator Portal

| Metric | Baseline | Target | Alert Threshold |
|--------|----------|--------|-----------------|
| CSV Import Usage | 0% | 30% | <15% |
| Duplicate Card Usage | 0% | 25% | <10% |
| Mobile Creator Retention | 30% | 60% | <40% |
| Analytics Dashboard Usage | 20% | 65% | <40% |
| Team Account Adoption | 0% | 12% | <5% |

### Business Metrics (Monthly)

| Metric | Baseline | Target | Alert Threshold |
|--------|----------|--------|-----------------|
| **MRR** | $2,400 | $22,600 | <$15,000 |
| **MRR Growth Rate** | 0% | 5% MoM | <2% |
| **Churn Rate** | 8% | <5% | >8% |
| **Free → Starter Conversion** | 8% | 18% | <12% |
| **Starter → Premium Upgrade** | 20% | 40% | <25% |
| **ARPU** | $24 | $174 | <$100 |
| **CAC** | $150 | $120 | >$200 |
| **LTV** | $400 | $1,200 | <$600 |
| **LTV:CAC Ratio** | 2.7:1 | 10:1 | <5:1 |

### Product Health Metrics (Daily)

| Metric | Threshold | Action |
|--------|-----------|--------|
| Error Rate | <0.5% | Investigate immediately |
| API Latency (p95) | <2s | Review backend performance |
| Mobile Client Bounce Rate | <40% | Check UX issues |
| Dashboard Load Time | <3s | Optimize queries |
| AI Connection Failures | <2% | Review safeguards |

### Analytics Implementation

**Event Tracking Schema** (Mixpanel/Amplitude):

```typescript
// Mobile Client Events
trackEvent('content_searched', {
  query: string,
  results_count: number,
  time_to_result_ms: number
})

trackEvent('content_favorited', {
  item_id: string,
  category: string,
  action: 'add' | 'remove'
})

trackEvent('content_shared', {
  item_id: string,
  method: 'native' | 'clipboard',
  destination: string
})

trackEvent('ai_conversation_started', {
  mode: 'general' | 'item',
  type: 'chat' | 'voice' | 'realtime'
})

// Creator Portal Events
trackEvent('card_created', {
  source: 'wizard' | 'template' | 'duplicate' | 'import',
  content_mode: string,
  time_to_create_s: number
})

trackEvent('bulk_import_completed', {
  format: 'csv' | 'xlsx',
  items_count: number,
  success_rate: number
})

trackEvent('team_member_invited', {
  role: 'owner' | 'editor' | 'viewer' | 'approver',
  team_size: number
})
```

---

## Risk Management

### Technical Risks

| Risk | Probability | Impact | Mitigation | Owner |
|------|------------|--------|------------|-------|
| Real-time collaboration performance issues | Medium | High | Load testing with 100 concurrent editors; WebSocket optimization; fallback to polling | Backend Lead |
| CSV import breaks with malformed data | High | Medium | Robust validation; preview before import; skip invalid rows | Frontend Lead |
| Service worker cache conflicts | Medium | Medium | Versioned cache keys; clear cache on major releases | Frontend Lead |
| SSO/SAML integration bugs | Low | Very High | Partner with Auth0/Okta; extensive testing; phased rollout | DevOps Lead |
| Mobile PWA low install rate | Medium | Medium | A/B test install prompt; educate users; incentivize with features | Product Manager |
| Virtual scrolling breaks layouts | Medium | High | Feature flag; extensive testing; fallback to pagination | Frontend Lead |

### Product Risks

| Risk | Probability | Impact | Mitigation | Owner |
|------|------------|--------|------------|-------|
| Low team collaboration adoption | Medium | High | Launch with case studies; free trial; onboarding webinars | Product Manager |
| Search feature underutilized | Low | High | Prominent placement; onboarding highlight; keyboard shortcut | UX Designer |
| Bulk import misused for spam | Medium | Medium | Rate limiting; content moderation queue; tier restrictions | Product Manager |
| Analytics dashboard overwhelms users | Low | Medium | Guided tour; default simple view; progressive disclosure | UX Designer |
| Mobile UX redesign resistance | Medium | High | Beta testing; optional classic view; gradual rollout | Product Manager |

### Business Risks

| Risk | Probability | Impact | Mitigation | Owner |
|------|------------|--------|------------|-------|
| Development delays | High | Medium | Agile sprints; buffer time; weekly check-ins; clear scope | Project Manager |
| Feature scope creep | Medium | High | Strict prioritization (MoSCoW); defer nice-to-haves to future phases | Product Manager |
| Existing users resist UI changes | Medium | High | Beta testing with power users; optional classic view; communication | Product Manager |
| Competitor launches similar features | Low | High | Move fast on quick wins; differentiate with AI + analytics | Product Manager |
| Enterprise tier pricing too high | Medium | Very High | Customer interviews; flexible contracts; volume discounts | Sales Lead |
| Insufficient engineering resources | High | High | Contractor pool; phased hiring; scope reduction if needed | Engineering Manager |

### Contingency Plans

**If Development Delayed by >2 Weeks**:
1. Defer Phase 5 (Mobile Analytics) to later release
2. Reduce Enterprise phase scope (defer white-label)
3. Extend timeline by 4 weeks with stakeholder approval

**If User Adoption <50% of Target**:
1. Conduct user interviews to identify blockers
2. A/B test feature placement/messaging
3. Create video tutorials & in-app guidance
4. Offer incentives (free credits) for feature usage

**If Budget Overrun >20%**:
1. Pause Phase 4 (Enterprise) pending ROI analysis
2. Reduce team size (contract to full-time conversion)
3. Seek additional funding or adjust scope

**If Competitor Launches Similar Features**:
1. Accelerate quick wins (Phase 0-1) to market
2. Emphasize unique differentiators (AI quality, ease-of-use)
3. Consider strategic partnerships or acquisitions

---

## Go-to-Market Strategy

### Launch Phases

#### Phase 0 Launch: Quick Wins (Week 4)

**Mobile Client**:
- **Target**: All existing visitors
- **Message**: *"Find what you need faster. Search, favorites, and share are here."*
- **Channels**:
  - In-app notification banner
  - Creator newsletter (reach visitors via creators)
  - Blog post: "5 New Ways to Explore Content"

**Creator Portal**:
- **Target**: Existing Starter/Premium users
- **Message**: *"Your workflow just got 10x faster. Duplicate cards, bulk delete, mobile editing."*
- **Channels**:
  - In-app notification
  - Email to paid users
  - Video tutorial (YouTube)

**Success Criteria**:
- 40% of paid creators try duplicate within 7 days
- 20% of visitors use search within 14 days

---

#### Phase 1 Launch: Discovery & Bulk Ops (Week 8)

**Mobile Client**:
- **Target**: Visitors to large collections (50+ items)
- **Message**: *"Never lose track. Search, filter, and navigate with ease."*
- **Channels**:
  - Feature highlight modal on large cards
  - Social media campaign (#DiscoverMore)

**Creator Portal**:
- **Target**: Agencies, professional creators
- **Message**: *"Import 1000 items in 5 minutes. CSV/Excel bulk import is here."*
- **Channels**:
  - Press release: "FunTell Launches Bulk Import"
  - Webinar: "Migrate Your Content Library"
  - Case study: "How ABC Agency Saved 90% Setup Time"

**Success Criteria**:
- 30% of creators try CSV import within 30 days
- Search usage: 0% → 25%

---

#### Phase 2 Launch: Analytics (Week 12)

**Both Platforms**:
- **Target**: Data-driven creators, organizations
- **Message**: *"See what works. Advanced analytics for smarter content."*
- **Channels**:
  - Blog post: "Data-Driven Content Optimization"
  - Email drip campaign (5-part series)
  - Dashboard widget highlighting new analytics

**Success Criteria**:
- 40% of creators view analytics within 30 days
- 10% export reports monthly

---

#### Phase 3 Launch: Team Collaboration (Week 18)

**Creator Portal**:
- **Target**: Organizations, museums, universities
- **Message**: *"Work together, publish faster. Introducing Team Collaboration."*
- **Channels**:
  - Direct outreach to Premium users (upgrade offer)
  - Partnership with museum associations
  - Trade show presence (MuseumNext, EdTech Summit)
  - Case study: "How City Museum Manages 25 Exhibits"

**Success Criteria**:
- 15 Enterprise customers within 90 days
- Average 4.2 seats per account

---

#### Phase 4 Launch: Enterprise Features (Week 24)

**Creator Portal**:
- **Target**: Large organizations (1000+ employees)
- **Message**: *"Enterprise-grade security, control, and customization."*
- **Channels**:
  - Sales team outreach (hire 2 sales reps)
  - Gartner/G2 profile optimization
  - Enterprise demo program
  - Security whitepaper (SOC 2, GDPR)

**Success Criteria**:
- 25 Enterprise customers by end of year
- Average contract: $500/month
- 90% renewal rate

---

### Marketing Calendar

**Month 1 (Week 1-4)**: Foundation Launch
- Week 1: Internal beta testing
- Week 2: Public announcement (blog + email)
- Week 3: Feature tutorial videos
- Week 4: User feedback collection

**Month 2 (Week 5-8)**: Discovery & Bulk Ops
- Week 5: Press release distribution
- Week 6: Webinar series kickoff
- Week 7: Case study publication
- Week 8: Social media campaign

**Month 3 (Week 9-12)**: Analytics Launch
- Week 9: Analytics teaser campaign
- Week 10: Data optimization guide (ebook)
- Week 11: Email drip campaign
- Week 12: Customer success stories

**Month 4-5 (Week 13-18)**: Collaboration Launch
- Week 13: Enterprise tier announcement
- Week 14-15: Partnership outreach
- Week 16-17: Trade show preparation
- Week 18: Team collaboration demo day

**Month 6 (Week 19-24)**: Enterprise Push
- Week 19-20: Sales team onboarding
- Week 21-22: Enterprise demo program
- Week 23: Security whitepaper release
- Week 24: Year-end retrospective

---

### Sales Enablement

**Enterprise Sales Collateral**:

1. **One-Pager**: Platform capabilities, pricing, ROI calculator
2. **Demo Script**: 30-minute guided demo of all features
3. **Case Studies**: 3-5 customer success stories
4. **Security Whitepaper**: SOC 2, GDPR, HIPAA compliance details
5. **ROI Calculator**: Spreadsheet showing cost savings vs manual processes
6. **Pricing Guide**: Tier comparison, volume discounts, contract terms

**Sales Process**:

```
Lead Generation
    ↓
Qualification (BANT)
    ↓
Discovery Call (30 min)
    ↓
Custom Demo (60 min)
    ↓
Proposal & Pricing
    ↓
Negotiation
    ↓
Contract & Onboarding
```

**Target Sales Cycle**: 45-60 days for Enterprise deals

---

## Appendices

### Appendix A: Technical Architecture Diagrams

#### Mobile Client Architecture

```
┌─────────────────────────────────────────────────────┐
│                   Mobile Client                      │
│  ┌─────────────────────────────────────────────┐   │
│  │  Vue 3 + TypeScript + PrimeVue + Tailwind   │   │
│  └─────────────────────────────────────────────┘   │
│  ┌─────────────┬─────────────┬─────────────────┐   │
│  │ Components  │ Composables │ Stores (Pinia)  │   │
│  │ - Layout*   │ - Search    │ - Language      │   │
│  │ - Content*  │ - Favorites │ - Mobile State  │   │
│  │ - AI*       │ - Voice     │                 │   │
│  └─────────────┴─────────────┴─────────────────┘   │
└─────────────────────────────────────────────────────┘
                      ↕ HTTP/WebSocket
┌─────────────────────────────────────────────────────┐
│                  Backend Services                    │
│  ┌─────────────┬─────────────┬─────────────────┐   │
│  │ Express.js  │ Supabase    │ Upstash Redis   │   │
│  │ - API       │ - Auth      │ - Caching       │   │
│  │ - AI Proxy  │ - RPC       │ - Rate Limit    │   │
│  └─────────────┴─────────────┴─────────────────┘   │
└─────────────────────────────────────────────────────┘
                      ↕
┌─────────────────────────────────────────────────────┐
│               External Services                      │
│  ┌──────────────┬──────────────┬────────────────┐  │
│  │ OpenAI       │ Google Gemini│ Stripe         │  │
│  │ - Realtime   │ - Translation│ - Payments     │  │
│  │ - Chat       │              │                │  │
│  └──────────────┴──────────────┴────────────────┘  │
└─────────────────────────────────────────────────────┘
```

#### Creator Portal Architecture

```
┌─────────────────────────────────────────────────────┐
│                  Creator Dashboard                   │
│  ┌─────────────────────────────────────────────┐   │
│  │  Vue 3 + TypeScript + PrimeVue + Tailwind   │   │
│  └─────────────────────────────────────────────┘   │
│  ┌──────────┬──────────┬──────────┬───────────┐   │
│  │ Views    │Components│ Stores   │ Utils     │   │
│  │ - MyCards│ - Card*  │ - Card   │ - Archive │   │
│  │ - Admin  │ - Content│ - Sub    │ - Crop    │   │
│  │ - Sub    │ - Digital│ - Trans  │ - Markdown│   │
│  └──────────┴──────────┴──────────┴───────────┘   │
└─────────────────────────────────────────────────────┘
                      ↕ RPC (Stored Procedures)
┌─────────────────────────────────────────────────────┐
│                Supabase PostgreSQL                   │
│  ┌─────────────────────────────────────────────┐   │
│  │  Tables: cards, content_items, users, etc.  │   │
│  │  Stored Procedures (RPC only, no direct)    │   │
│  │  - get_user_cards()                          │   │
│  │  - create_card(...)                          │   │
│  │  - bulk_create_content_items(...)            │   │
│  └─────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────┘
```

---

### Appendix B: Database Schema Changes

#### New Tables for Team Collaboration

```sql
-- Teams
CREATE TABLE teams (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  owner_user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  subscription_tier TEXT DEFAULT 'enterprise',
  max_seats INT DEFAULT 10,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Team Members
CREATE TABLE team_members (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  team_id UUID REFERENCES teams(id) ON DELETE CASCADE,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  role TEXT CHECK (role IN ('owner', 'editor', 'viewer', 'approver')),
  invited_at TIMESTAMPTZ DEFAULT NOW(),
  joined_at TIMESTAMPTZ,
  UNIQUE(team_id, user_id)
);

-- Card-Team Association
CREATE TABLE card_team_access (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  card_id UUID REFERENCES cards(id) ON DELETE CASCADE,
  team_id UUID REFERENCES teams(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(card_id, team_id)
);

-- Activity Feed
CREATE TABLE team_activity (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  team_id UUID REFERENCES teams(id) ON DELETE CASCADE,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  action TEXT NOT NULL,
  resource_type TEXT NOT NULL,
  resource_id UUID,
  details JSONB DEFAULT '{}'::JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Analytics Tables
CREATE TABLE daily_analytics (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  card_id UUID REFERENCES cards(id) ON DELETE CASCADE,
  date DATE NOT NULL,
  total_sessions INT DEFAULT 0,
  ai_sessions INT DEFAULT 0,
  non_ai_sessions INT DEFAULT 0,
  total_cost DECIMAL(10, 2) DEFAULT 0,
  top_content_items JSONB DEFAULT '[]'::JSONB,
  top_qr_codes JSONB DEFAULT '[]'::JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(card_id, date)
);

CREATE TABLE content_item_views (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  card_id UUID REFERENCES cards(id) ON DELETE CASCADE,
  content_item_id UUID REFERENCES content_items(id) ON DELETE CASCADE,
  access_token_id UUID REFERENCES access_tokens(id) ON DELETE SET NULL,
  session_id UUID,
  device_type TEXT,
  viewed_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE ai_conversations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  card_id UUID REFERENCES cards(id) ON DELETE CASCADE,
  content_item_id UUID REFERENCES content_items(id) ON DELETE SET NULL,
  session_id UUID,
  question TEXT,
  response TEXT,
  quality_rating INT CHECK (quality_rating BETWEEN 1 AND 5),
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

#### New Stored Procedures

```sql
-- Bulk Create Content Items
CREATE OR REPLACE FUNCTION bulk_create_content_items(
  p_card_id UUID,
  p_items JSONB
) RETURNS JSONB AS $$
DECLARE
  v_item JSONB;
  v_result JSONB := '[]'::JSONB;
  v_new_id UUID;
BEGIN
  FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
  LOOP
    INSERT INTO content_items (
      card_id, name, content, parent_id, image_url,
      ai_knowledge_base, sort_order
    ) VALUES (
      p_card_id,
      v_item->>'name',
      v_item->>'content',
      (v_item->>'parent_id')::UUID,
      v_item->>'image_url',
      v_item->>'ai_knowledge_base',
      COALESCE((v_item->>'sort_order')::INT,
        (SELECT COALESCE(MAX(sort_order), 0) + 1
         FROM content_items WHERE card_id = p_card_id))
    )
    RETURNING id INTO v_new_id;

    v_result := v_result || jsonb_build_object('id', v_new_id);
  END LOOP;

  RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get Card Analytics
CREATE OR REPLACE FUNCTION get_card_analytics(
  p_card_id UUID,
  p_start_date TIMESTAMPTZ,
  p_end_date TIMESTAMPTZ,
  p_qr_code_id UUID DEFAULT NULL,
  p_device_type TEXT DEFAULT NULL
) RETURNS JSONB AS $$
DECLARE
  v_result JSONB;
BEGIN
  SELECT jsonb_build_object(
    'total_sessions', COUNT(*),
    'ai_sessions', COUNT(*) FILTER (WHERE ai_enabled = true),
    'non_ai_sessions', COUNT(*) FILTER (WHERE ai_enabled = false),
    'total_cost', SUM(cost),
    'daily_breakdown', (
      SELECT jsonb_agg(
        jsonb_build_object(
          'date', DATE(created_at),
          'sessions', count,
          'cost', sum_cost
        ) ORDER BY DATE(created_at)
      )
      FROM (
        SELECT
          DATE(created_at) as date,
          COUNT(*) as count,
          SUM(cost) as sum_cost
        FROM sessions
        WHERE card_id = p_card_id
          AND created_at BETWEEN p_start_date AND p_end_date
          AND (p_qr_code_id IS NULL OR access_token_id = p_qr_code_id)
        GROUP BY DATE(created_at)
      ) daily
    )
  ) INTO v_result
  FROM sessions
  WHERE card_id = p_card_id
    AND created_at BETWEEN p_start_date AND p_end_date
    AND (p_qr_code_id IS NULL OR access_token_id = p_qr_code_id);

  RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

---

### Appendix C: API Endpoints Reference

#### Mobile Client Endpoints

| Method | Endpoint | Purpose | Auth |
|--------|----------|---------|------|
| GET | `/api/mobile/card/digital/:token` | Fetch card + content | Public |
| GET | `/api/mobile/card/physical/:issueCardId` | Fetch card for physical QR | Public |
| POST | `/api/ai/chat/stream` | Streaming chat responses | Public |
| POST | `/api/ai/realtime-token` | Get WebRTC ephemeral token | Public |
| POST | `/api/ai/generate-tts` | Text-to-speech generation | Public |

#### Creator Portal Endpoints

| Method | Endpoint | Purpose | Auth |
|--------|----------|---------|------|
| GET | `/api/subscriptions` | Get user subscription | Required |
| GET | `/api/subscriptions/usage` | Get usage stats | Required |
| GET | `/api/subscriptions/daily-stats?days=N` | Daily breakdown | Required |
| POST | `/api/subscriptions/create-checkout` | Stripe checkout | Required |
| POST | `/api/subscriptions/cancel` | Cancel subscription | Required |
| POST | `/api/translations/translate-card` | Start translation job | Required |
| GET | `/api/translations/job/:jobId` | Poll job status | Required |
| POST | `/api/ai/generate-ai-settings` | Auto-generate AI config | Required |
| POST | `/api/payments/create-credit-checkout` | Buy session credits | Required |
| GET | `/api/analytics/card/:cardId` | Advanced analytics | Required |
| POST | `/api/teams/invite` | Invite team member | Required |
| GET | `/api/teams/:teamId/activity` | Activity feed | Required |

---

### Appendix D: Testing Strategy

#### Unit Testing

**Coverage Target**: 80% for critical paths

**Tools**:
- Frontend: Vitest + Vue Test Utils
- Backend: Jest + Supertest

**Priority Areas**:
- Bulk import validation
- Search/filter logic
- Permission middleware
- Analytics aggregation

#### Integration Testing

**Coverage**: All API endpoints + RPC procedures

**Tools**:
- Playwright (E2E)
- Postman/Newman (API)

**Critical Flows**:
- Card creation → content addition → QR generation
- CSV import → validation → bulk insert
- Team invite → accept → permission check
- Analytics query → export → download

#### Performance Testing

**Load Testing** (Artillery/k6):
- 1000 concurrent users on mobile client
- 100 concurrent CSV imports
- 50 real-time collaboration sessions

**Benchmarks**:
- API latency p95 <2s
- Mobile time-to-interactive <1.5s
- Dashboard load time <3s

#### Accessibility Testing

**Tools**:
- axe DevTools
- Lighthouse
- Manual screen reader (VoiceOver, NVDA)

**Compliance**: WCAG 2.1 Level AA

#### User Acceptance Testing (UAT)

**Beta Program**:
- 20 power users (10 mobile visitors, 10 creators)
- 2-week testing period per phase
- Feedback via in-app survey + interviews

---

### Appendix E: Deployment Strategy

#### Deployment Pipeline

```
Development → Staging → Production
    ↓           ↓           ↓
  Feature    Beta Test   All Users
   Flags      (10%)      (100%)
```

#### Feature Flags

**Tool**: LaunchDarkly or custom implementation

**Flagged Features**:
- Search/filter (rollout 10% → 50% → 100%)
- Virtual scrolling (canary release)
- Team collaboration (beta customers only)
- SSO/SAML (per-organization enable)

#### Rollback Plan

**Automated Rollback Triggers**:
- Error rate >1%
- API latency p95 >5s
- User complaints >10/hour

**Manual Rollback**:
- Disable feature flag
- Revert deployment (Git tag)
- Database migration rollback (if needed)

#### Database Migrations

**Strategy**: Blue-Green deployment with backward compatibility

**Process**:
1. Deploy schema changes (additive only)
2. Run migration scripts
3. Deploy new code
4. Verify functionality
5. Remove old columns/tables (after 7 days)

---

### Appendix F: Documentation Requirements

#### Developer Documentation

**Location**: `/docs/developer/`

**Contents**:
- API reference (OpenAPI/Swagger)
- Database schema diagrams
- Component library (Storybook)
- Coding standards
- Git workflow
- Deployment runbook

#### User Documentation

**Location**: `/docs/user/` + Help Center

**Contents**:
- Getting started guide
- Feature tutorials (video + text)
- FAQ
- Troubleshooting
- API documentation (Enterprise tier)

#### Admin Documentation

**Location**: Internal wiki

**Contents**:
- Team management guide
- Analytics interpretation
- Billing procedures
- Security protocols
- Incident response

---

### Appendix G: Security Considerations

#### Data Protection

**PII Handling**:
- User emails encrypted at rest
- Payment info handled by Stripe (PCI compliant)
- GDPR compliance (right to deletion, export)

**Access Control**:
- Row-level security (RLS) in Supabase
- JWT token authentication
- Role-based permissions (RBAC)
- API rate limiting (Redis)

#### Vulnerability Management

**Tools**:
- Dependabot (dependency updates)
- Snyk (vulnerability scanning)
- OWASP ZAP (penetration testing)

**Process**:
- Weekly dependency scans
- Monthly security audits
- Quarterly penetration tests (Enterprise customers)

#### Compliance

**Certifications** (Target):
- SOC 2 Type II (12 months)
- GDPR compliant (current)
- CCPA compliant (current)
- HIPAA (if needed for healthcare customers)

---

### Appendix H: Change Management

#### Communication Plan

**Internal**:
- Weekly all-hands (progress updates)
- Bi-weekly engineering demos
- Monthly stakeholder presentations

**External**:
- Product changelog (public)
- Creator newsletter (bi-weekly)
- Social media announcements
- Blog post per major feature

#### Training Plan

**Creator Training**:
- Video tutorials (5-10 min each)
- Interactive onboarding (in-app)
- Live webinars (monthly)
- Help center articles

**Team Training** (for collaboration features):
- Admin guide (PDF)
- Role-specific training
- Best practices documentation

#### Support Readiness

**Support Channels**:
- Email: support@funtell.ai
- In-app chat (Intercom)
- Help center (self-service)
- Enterprise: Dedicated Slack channel

**SLA** (Enterprise):
- P0 (critical): 2-hour response
- P1 (high): 4-hour response
- P2 (medium): 24-hour response
- P3 (low): 48-hour response

---

### Appendix I: Glossary

**Terms**:

- **ARIA**: Accessible Rich Internet Applications (accessibility standard)
- **CRDT**: Conflict-free Replicated Data Type (real-time collaboration)
- **WCAG**: Web Content Accessibility Guidelines
- **RPC**: Remote Procedure Call (Supabase stored procedures)
- **PWA**: Progressive Web App
- **MRR**: Monthly Recurring Revenue
- **ARPU**: Average Revenue Per User
- **CAC**: Customer Acquisition Cost
- **LTV**: Lifetime Value
- **BANT**: Budget, Authority, Need, Timeline (sales qualification)
- **MoSCoW**: Must have, Should have, Could have, Won't have (prioritization)

---

### Appendix J: Contact Information

**Project Team**:

| Role | Name | Email |
|------|------|-------|
| Product Manager | [Name] | pm@funtell.ai |
| Engineering Manager | [Name] | eng-manager@funtell.ai |
| Design Lead | [Name] | design-lead@funtell.ai |
| DevOps Lead | [Name] | devops@funtell.ai |
| Sales Lead | [Name] | sales@funtell.ai |

**Escalation Path**:
1. Project Manager (day-to-day)
2. Engineering Manager (technical blocks)
3. VP Engineering (critical issues)
4. CEO (strategic decisions)

---

### Document Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-02-15 | Product Team | Initial comprehensive roadmap |

---

**End of Document**

**Total Pages**: 52
**Word Count**: ~25,000 words
**Last Updated**: February 15, 2026
