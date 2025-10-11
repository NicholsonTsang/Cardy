# CardStudio Internationalization (i18n) Implementation Guide

## Overview

CardStudio now supports **10 languages** with full internationalization using Vue I18n.

### Supported Languages

| Language | Code | Native Name | Flag |
|----------|------|-------------|------|
| English | `en` | English | 🇺🇸 |
| Traditional Chinese | `zh-Hant` | 繁體中文 | 🇭🇰 |
| Simplified Chinese | `zh-Hans` | 简体中文 | 🇨🇳 |
| Japanese | `ja` | 日本語 | 🇯🇵 |
| Korean | `ko` | 한국어 | 🇰🇷 |
| Spanish | `es` | Español | 🇪🇸 |
| French | `fr` | Français | 🇫🇷 |
| Russian | `ru` | Русский | 🇷🇺 |
| Arabic | `ar` | العربية | 🇸🇦 |
| Thai | `th` | ไทย | 🇹🇭 |

---

## Installation

```bash
npm install vue-i18n@9
```

---

## File Structure

```
src/
├── i18n/
│   ├── index.ts                 # i18n configuration & setup
│   └── locales/
│       ├── en.json              # English (base)
│       ├── zh-Hant.json         # Traditional Chinese
│       ├── zh-Hans.json         # Simplified Chinese
│       ├── ja.json              # Japanese
│       ├── ko.json              # Korean
│       ├── es.json              # Spanish
│       ├── fr.json              # French
│       ├── ru.json              # Russian
│       ├── ar.json              # Arabic
│       └── th.json              # Thai
├── components/
│   └── LanguageSwitcher.vue     # Language selection component
└── main.ts                      # Register i18n plugin
```

---

## Configuration (`src/i18n/index.ts`)

### Features:
- ✅ Composition API mode
- ✅ Fallback to English
- ✅ Locale persistence (localStorage)
- ✅ RTL support for Arabic
- ✅ Date/time formatting
- ✅ Number/currency formatting

### Helper Functions:
```typescript
import { setLocale } from '@/i18n'

// Change language
setLocale('zh-Hant')  // Switch to Traditional Chinese
setLocale('ar')       // Switch to Arabic (enables RTL)
```

---

## Usage in Components

### 1. **Composition API** (Recommended)

```vue
<script setup>
import { useI18n } from 'vue-i18n'

const { t, locale } = useI18n()

// Use translations
console.log(t('auth.sign_in'))  // "Sign In"
</script>

<template>
  <h1>{{ $t('auth.welcome_back') }}</h1>
  <Button :label="$t('common.save')" />
</template>
```

### 2. **Options API**

```vue
<template>
  <div>{{ $t('dashboard.my_cards') }}</div>
</template>

<script>
export default {
  methods: {
    showMessage() {
      console.log(this.$t('messages.save_success'))
    }
  }
}
</script>
```

### 3. **Template Syntax**

```vue
<!-- Simple translation -->
<p>{{ $t('common.loading') }}</p>

<!-- With interpolation -->
<p>{{ $t('validation.max_words_exceeded', { max: 100 }) }}</p>

<!-- Pluralization -->
<p>{{ $t('batches.cards_issued', { count: 5 }) }}</p>

<!-- Date formatting -->
<p>{{ $d(new Date(), 'short') }}</p>

<!-- Currency formatting -->
<p>{{ $n(2.00, 'currency') }}</p>
```

---

## Translation File Structure

All translation files follow the same JSON structure:

```json
{
  "common": {
    "app_name": "CardStudio",
    "loading": "Loading...",
    "save": "Save"
  },
  "auth": {
    "sign_in": "Sign In",
    "welcome_back": "Welcome Back"
  },
  "dashboard": {
    "my_cards": "My Cards",
    "create_card": "Create Card"
  }
}
```

### Translation Categories:

1. **`common`** - Shared UI elements (buttons, actions, status)
2. **`auth`** - Authentication (sign in, sign up, password reset)
3. **`dashboard`** - Dashboard & card management
4. **`content`** - Content management
5. **`batches`** - Batch issuance
6. **`admin`** - Admin panel
7. **`mobile`** - Mobile client
8. **`validation`** - Form validation messages
9. **`messages`** - Toast/alert messages

---

## Language Switcher Component

### Location: `src/components/LanguageSwitcher.vue`

```vue
<template>
  <Dropdown 
    v-model="currentLocale" 
    :options="languages" 
    optionLabel="name"
    optionValue="code"
    @change="handleLocaleChange"
  >
    <template #value="{ value }">
      {{ languages.find(l => l.code === value)?.flag }} 
      {{ languages.find(l => l.code === value)?.name }}
    </template>
    <template #option="{ option }">
      {{ option.flag }} {{ option.name }}
    </template>
  </Dropdown>
</template>

<script setup>
import { ref, watch } from 'vue'
import { useI18n } from 'vue-i18n'
import { setLocale } from '@/i18n'
import Dropdown from 'primevue/dropdown'

const { locale } = useI18n()
const currentLocale = ref(locale.value)

const languages = [
  { code: 'en', name: 'English', flag: '🇺🇸' },
  { code: 'zh-Hant', name: '繁體中文', flag: '🇭🇰' },
  { code: 'zh-Hans', name: '简体中文', flag: '🇨🇳' },
  { code: 'ja', name: '日本語', flag: '🇯🇵' },
  { code: 'ko', name: '한국어', flag: '🇰🇷' },
  { code: 'es', name: 'Español', flag: '🇪🇸' },
  { code: 'fr', name: 'Français', flag: '🇫🇷' },
  { code: 'ru', name: 'Русский', flag: '🇷🇺' },
  { code: 'ar', name: 'العربية', flag: '🇸🇦' },
  { code: 'th', name: 'ไทย', flag: '🇹🇭' }
]

function handleLocaleChange(event) {
  setLocale(event.value)
}
</script>
```

### Usage:
```vue
<template>
  <div class="header">
    <LanguageSwitcher />
  </div>
</template>

<script setup>
import LanguageSwitcher from '@/components/LanguageSwitcher.vue'
</script>
```

---

## RTL Support (Arabic)

When Arabic is selected:
- `dir="rtl"` is automatically applied to `<html>`
- Layout mirrors from right-to-left
- Text alignment reverses

To handle RTL in custom CSS:
```css
/* LTR default */
.my-component {
  margin-left: 10px;
}

/* RTL override */
[dir="rtl"] .my-component {
  margin-right: 10px;
  margin-left: 0;
}
```

Or use logical properties (automatic):
```css
.my-component {
  margin-inline-start: 10px;  /* Auto-adapts to LTR/RTL */
}
```

---

## Main.ts Integration

```typescript
import { createApp } from 'vue'
import App from './App.vue'
import router from './router'
import i18n from './i18n'  // Import i18n

const app = createApp(App)

app.use(router)
app.use(i18n)  // Register i18n plugin

app.mount('#app')
```

---

## Migration Checklist

### For Each Component:

- [ ] Replace hardcoded text with `$t()` calls
- [ ] Add translation keys to all locale files
- [ ] Test with multiple languages
- [ ] Verify RTL layout for Arabic
- [ ] Check date/currency formatting

### Priority Order:

1. ✅ **Auth Pages** (SignIn, SignUp, ResetPassword)
2. ✅ **Dashboard** (MyCards, Card forms)
3. ✅ **Content Management** (Content forms, lists)
4. ✅ **Admin Panel** (User management, logs)
5. ✅ **Mobile Client** (Card view, AI assistant)
6. ✅ **Components** (Headers, modals, toasts)

---

## Translation Workflow

### 1. Add English Key (Base)
```json
// en.json
{
  "dashboard": {
    "create_new_card": "Create New Card"
  }
}
```

### 2. Add to All Languages
```json
// zh-Hant.json
{
  "dashboard": {
    "create_new_card": "創建新卡片"
  }
}

// es.json
{
  "dashboard": {
    "create_new_card": "Crear Nueva Tarjeta"
  }
}

// ... (repeat for all languages)
```

### 3. Use in Component
```vue
<Button :label="$t('dashboard.create_new_card')" />
```

---

## Best Practices

### 1. **Key Naming Convention**
- Use `snake_case` for keys
- Group related translations
- Be specific and descriptive

```json
{
  "auth": {
    "sign_in": "Sign In",           // ✅ Good
    "sign_in_button": "Sign In",    // ❌ Redundant
    "btn": "Sign In"                // ❌ Not descriptive
  }
}
```

### 2. **Avoid Concatenation**
```json
// ❌ Bad
{ "welcome": "Welcome, {name}!" }

// ✅ Good
{ "welcome_user": "Welcome, {name}!" }
```

### 3. **Handle Plurals**
```json
{
  "items_count": "no items | 1 item | {count} items"
}
```

```vue
<!-- Usage -->
<p>{{ $t('items_count', { count: 5 }) }}</p>
<!-- Output: "5 items" -->
```

### 4. **Dynamic Content**
```json
{
  "greeting": "Hello, {name}!"
}
```

```vue
<p>{{ $t('greeting', { name: userName }) }}</p>
```

### 5. **Use Fallback**
```vue
<!-- If key is missing, fallback to key name -->
<p>{{ $t('missing.key') }}</p>
<!-- Output: "missing.key" (in development) -->
```

---

## Testing

### 1. **Switch Languages in Dev**
```javascript
import { setLocale } from '@/i18n'

// Test each language
setLocale('zh-Hant')
setLocale('ja')
setLocale('ar')  // Test RTL
```

### 2. **Check for Missing Keys**
```bash
# Enable missing key warnings in dev
# Check browser console for warnings
```

### 3. **Visual Testing**
- [ ] Text fits in buttons/containers
- [ ] No text overflow
- [ ] RTL layout works correctly
- [ ] Date/currency formats correctly

---

## Known Limitations

1. **User-Generated Content** (Card names, descriptions)
   - Not automatically translated
   - Users must provide multilingual content

2. **Toast Messages**
   - Must update all `toast.add()` calls to use `$t()`

3. **Dynamic Imports**
   - Locale files loaded on app start
   - No lazy loading (for simplicity)

---

## Maintenance

### Adding a New Language:

1. Create new locale file: `src/i18n/locales/[code].json`
2. Copy structure from `en.json`
3. Translate all keys
4. Import in `src/i18n/index.ts`:
   ```typescript
   import newLang from './locales/new-lang.json'
   ```
5. Add to messages object:
   ```typescript
   messages: {
     // ...
     'new-lang': newLang
   }
   ```
6. Add to language switcher dropdown

### Adding a New Translation Key:

1. Add to `en.json` (base)
2. Add to all other locale files
3. Use in component with `$t('category.key')`

---

## Support & Resources

- **Vue I18n Docs**: https://vue-i18n.intlify.dev/
- **PrimeVue i18n**: https://primevue.org/configuration/#locale
- **ISO Language Codes**: https://www.loc.gov/standards/iso639-2/php/code_list.php

---

## Summary

✅ **Installed**: vue-i18n@9
✅ **Configured**: 10 languages with RTL support
✅ **Structured**: JSON files organized by feature
✅ **Integrated**: Ready to use in all components
✅ **Persistent**: Saves user's language preference

**Next Steps**: Migrate components to use i18n translations!

