# Frontend Guide

This guide covers the Vue 3 frontend application structure, patterns, and best practices.

## Directory Structure

```
src/
├── components/           # Reusable Vue components
│   ├── *.vue            # General components
│   └── ui/              # UI-specific components
├── views/               # Page components
│   ├── Dashboard/       # Creator dashboard pages
│   ├── MobileClient/    # Visitor mobile experience
│   └── Public/          # Landing page, docs
├── stores/              # Pinia state management
├── services/            # API and external service clients
├── i18n/                # Internationalization
│   └── locales/         # Translation JSON files
├── utils/               # Utility functions
├── types/               # TypeScript type definitions
└── router/              # Vue Router configuration
```

## View Organization

### Dashboard (`/views/Dashboard/`)

Creator-facing pages for managing projects:

| View | Route | Purpose |
|------|-------|---------|
| DashboardHome | `/dashboard` | Overview and navigation |
| CardListView | `/dashboard/cards` | List all projects |
| CardDetailView | `/dashboard/cards/:id` | Edit single project |
| ContentEditor | `/dashboard/cards/:id/content` | Manage content items |
| BatchManagement | `/dashboard/cards/:id/batches` | Physical card batches |
| AccessTokenManager | `/dashboard/cards/:id/tokens` | QR code management |

### Mobile Client (`/views/MobileClient/`)

Visitor-facing experience:

| View | Route | Purpose |
|------|-------|---------|
| PublicCardView | `/c/:accessToken` | Main card experience |
| ContentDetailView | `/c/:accessToken/item/:itemId` | Single content item |

### Public (`/views/Public/`)

Marketing and information pages:

| View | Route | Purpose |
|------|-------|---------|
| LandingPage | `/` | Marketing home page |
| DocsView | `/docs` | User documentation |

## Pinia Stores

Located in `src/stores/`:

| Store | File | Purpose |
|-------|------|---------|
| Auth | `auth.ts` | User authentication state |
| Card | `card.ts` | Project/card data management |
| ContentItem | `contentItem.ts` | Content items within cards |
| Subscription | `subscription.ts` | User subscription status |
| Credits | `credits.ts` | Credit balance and transactions |
| Translation | `translation.ts` | Content translation state |
| Language | `language.ts` | UI language preferences |
| Admin | `admin.ts` | Admin-only operations |
| TemplateLibrary | `templateLibrary.ts` | Content templates |

### Store Pattern

Stores follow a consistent pattern:

```typescript
// src/stores/example.ts
import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { supabase } from '@/lib/supabase'

export const useExampleStore = defineStore('example', () => {
  // State
  const items = ref<Item[]>([])
  const loading = ref(false)
  const error = ref<string | null>(null)

  // Computed
  const itemCount = computed(() => items.value.length)

  // Actions - use stored procedures
  const fetchItems = async () => {
    loading.value = true
    try {
      const { data, error: err } = await supabase.rpc('get_items')
      if (err) throw err
      items.value = data
    } catch (e) {
      error.value = e.message
    } finally {
      loading.value = false
    }
  }

  return { items, loading, error, itemCount, fetchItems }
})
```

## Component Patterns

### Component Structure

```vue
<script setup lang="ts">
// 1. Imports
import { ref, computed, onMounted } from 'vue'
import { useI18n } from 'vue-i18n'
import Button from 'primevue/button'

// 2. Props and Emits
const props = defineProps<{
  title: string
  count?: number
}>()

const emit = defineEmits<{
  submit: [value: string]
  cancel: []
}>()

// 3. Composables
const { t } = useI18n()

// 4. State
const inputValue = ref('')

// 5. Computed
const isValid = computed(() => inputValue.value.length > 0)

// 6. Methods
const handleSubmit = () => {
  emit('submit', inputValue.value)
}

// 7. Lifecycle
onMounted(() => {
  // Initialize
})
</script>

<template>
  <div class="p-4">
    <h2 class="text-lg font-semibold">{{ title }}</h2>
    <input v-model="inputValue" class="border rounded px-2 py-1" />
    <Button :label="t('common.submit')" @click="handleSubmit" />
  </div>
</template>
```

### Styling Guidelines

1. **Use Tailwind CSS** for all styling
2. **Don't override PrimeVue styles** - use built-in props
3. **Use PrimeVue component props** for customization:

```vue
<!-- Good: Use props -->
<Button severity="danger" outlined size="small" />

<!-- Bad: Override styles -->
<Button class="!bg-red-500 !text-white" />
```

4. **Minimal scoped CSS** - only when Tailwind can't achieve the result

## Internationalization (i18n)

### Adding Translations

Update files in `src/i18n/locales/`:

```json
// en.json
{
  "feature": {
    "title": "Feature Title",
    "description": "Description text"
  }
}

// zh-Hant.json
{
  "feature": {
    "title": "功能標題",
    "description": "描述文字"
  }
}
```

### Using Translations

```vue
<script setup>
import { useI18n } from 'vue-i18n'
const { t } = useI18n()
</script>

<template>
  <p>{{ $t('feature.title') }}</p>
  <p>{{ t('feature.description') }}</p>
</template>
```

### Language Support

| Context | Languages | Selector Component |
|---------|-----------|-------------------|
| Landing/Mobile | 10 languages | `LandingLanguageSelector` |
| Dashboard | 2 languages (en, zh-Hant) | `DashboardLanguageSelector` |

## Routing

### URL-Based Language Routing

All routes include language prefix: `/:lang/...`

```typescript
// Example routes
'/en/dashboard'           // English dashboard
'/zh-Hant/dashboard'      // Traditional Chinese dashboard
'/en/c/abc123xyz'         // English mobile client
```

### Route Guards

Authentication enforced via router guards:

```typescript
// Requires authentication
{ path: '/dashboard', meta: { requiresAuth: true } }

// Admin only
{ path: '/admin', meta: { requiresAuth: true, requiresAdmin: true } }
```

## API Communication

### Supabase Client (Frontend-accessible procedures)

```typescript
import { supabase } from '@/lib/supabase'

// Uses auth.uid() automatically
const { data, error } = await supabase.rpc('get_user_cards')
```

### Backend API (Sensitive operations)

```typescript
import { mobileApi } from '@/services/mobileApi'

// Routes through Express backend
const cardData = await mobileApi.getCardByAccessToken(token)
```

## Mobile Client Service

Located at `src/services/mobileApi.ts`:

```typescript
// Key methods
mobileApi.getCardByAccessToken(token)      // Fetch card data
mobileApi.getCardByIssueCardId(id)         // Fetch by physical card ID
mobileApi.invalidateCache(cardId)          // Clear content cache
```

## Error Handling

### Toast Notifications

```typescript
import { useToast } from 'primevue/usetoast'

const toast = useToast()

// Success
toast.add({ severity: 'success', summary: 'Saved', life: 3000 })

// Error
toast.add({ severity: 'error', summary: 'Error', detail: error.message })
```

### Form Validation

Use PrimeVue's built-in validation or VeeValidate:

```vue
<InputText v-model="email" :invalid="!isValidEmail" />
<small v-if="!isValidEmail" class="text-red-500">
  {{ $t('validation.invalid_email') }}
</small>
```

## Performance Tips

1. **Lazy load routes** - Use dynamic imports
2. **Use `v-memo`** for expensive renders
3. **Debounce search inputs**
4. **Paginate large lists** - Use pagination procedures
