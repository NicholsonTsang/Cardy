<template>
  <div class="import-form">
    <!-- Template Summary -->
    <div class="template-summary">
      <div class="summary-icon">
        <i :class="getModeIcon(template.content_mode)"></i>
      </div>
      <div class="summary-info">
        <h4>{{ template.name }}</h4>
        <p>{{ template.item_count }} {{ $t('templates.content_items') }}</p>
        <!-- Template badges -->
        <div class="template-badges">
          <span class="badge badge-mode">
            <i :class="getModeSmallIcon(template.content_mode)"></i>
            {{ getModeLabel(template.content_mode) }}
          </span>
          <span v-if="template.original_language" class="badge badge-language">
            {{ getLanguageFlag(template.original_language) }}
            {{ getLanguageName(template.original_language) }}
          </span>
          <span v-if="template.is_grouped" class="badge badge-grouped">
            <i class="pi pi-sitemap"></i>
            {{ $t('templates.grouped') }}
          </span>
        </div>
        <!-- Translation badges -->
        <div v-if="hasTranslations" class="translation-badges">
          <span class="badge badge-translation">
            <i class="pi pi-language"></i>
            {{ $t('templates.translations_available', { count: template.translation_languages.length }) }}
          </span>
          <span 
            v-for="lang in template.translation_languages.slice(0, 4)" 
            :key="lang" 
            class="badge badge-translation-lang"
          >
            {{ getLanguageFlag(lang) }} {{ lang }}
          </span>
          <span v-if="template.translation_languages.length > 4" class="badge badge-translation-more">
            +{{ template.translation_languages.length - 4 }}
          </span>
        </div>
      </div>
    </div>
    
    <!-- Access Limits Info (if configured) -->
    <div v-if="hasAccessLimits" class="access-limits-info">
      <div class="limits-header">
        <i class="pi pi-info-circle"></i>
        <span>{{ $t('templates.access_limits_info') }}</span>
      </div>
      <div class="limits-details">
        <span v-if="template.default_daily_session_limit" class="limit-item">
          <i class="pi pi-clock"></i>
          {{ $t('templates.daily_limit', { count: template.default_daily_session_limit }) }}
        </span>
      </div>
    </div>

    <!-- Form -->
    <form @submit.prevent="handleImport" class="form-content">
      <!-- Import Language Selection -->
      <div v-if="availableLanguages.length > 1" class="form-field">
        <label>{{ $t('templates.import_language') }}</label>
        <small class="field-hint mb-2">{{ $t('templates.import_language_hint') }}</small>
        <div class="language-options">
          <div 
            v-for="lang in availableLanguages" 
            :key="lang.code"
            class="language-option"
            :class="{ selected: selectedLanguage === lang.code }"
            @click="selectedLanguage = lang.code"
          >
            <span class="lang-flag">{{ lang.flag }}</span>
            <span class="lang-name">{{ lang.name }}</span>
            <span v-if="lang.isOriginal" class="lang-badge original">{{ $t('templates.original') }}</span>
            <span v-else class="lang-badge translated">{{ $t('templates.translated') }}</span>
            <i v-if="selectedLanguage === lang.code" class="pi pi-check check-icon"></i>
          </div>
        </div>
      </div>

      <!-- Custom Name -->
      <div class="form-field">
        <label for="customName">{{ $t('templates.custom_name') }}</label>
        <InputText 
          id="customName"
          v-model="customName"
          :placeholder="getPlaceholderName()"
          class="w-full"
        />
        <small class="field-hint">{{ $t('templates.custom_name_hint') }}</small>
      </div>

      <!-- Actions -->
      <div class="form-actions">
        <Button 
          type="button"
          :label="$t('common.cancel')"
          text
          @click="$emit('cancel')"
          :disabled="isImporting"
        />
        <Button 
          type="submit"
          :label="isImporting ? $t('templates.importing') : $t('templates.create_from_template')"
          icon="pi pi-check"
          :loading="isImporting"
          class="bg-indigo-600 hover:bg-indigo-700 text-white border-0"
        />
      </div>
    </form>

    <!-- Error Message -->
    <Message v-if="errorMessage" severity="error" :closable="true" @close="errorMessage = ''">
      {{ errorMessage }}
    </Message>
  </div>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import { useI18n } from 'vue-i18n'
import { useTemplateLibraryStore, type ContentTemplate } from '@/stores/templateLibrary'
import { useSubscriptionStore } from '@/stores/subscription'
import { getLanguageFlag, getLanguageName } from '@/utils/formatters'
import InputText from 'primevue/inputtext'
import Button from 'primevue/button'
import Message from 'primevue/message'
const { t } = useI18n()
const templateStore = useTemplateLibraryStore()
const subscriptionStore = useSubscriptionStore()

const props = defineProps<{
  template: ContentTemplate
  defaultLanguage?: string | null  // Pre-selected language from browse view
}>()

const emit = defineEmits<{
  imported: [result: { cardId: string }]
  cancel: []
}>()

// Form state
const customName = ref('')
const selectedBillingType = ref<'digital'>('digital')
// Use defaultLanguage from browse view if provided, otherwise use template's original language
const selectedLanguage = ref<string>(
  props.defaultLanguage && isLanguageAvailable(props.defaultLanguage) 
    ? props.defaultLanguage 
    : props.template.original_language || 'en'
)

// Check if a language is available for this template (either original or translated)
function isLanguageAvailable(lang: string): boolean {
  if (lang === props.template.original_language) return true
  return props.template.translation_languages?.includes(lang) || false
}
const isImporting = ref(false)
const errorMessage = ref('')

// Computed for access limits
const hasAccessLimits = computed(() => {
  return props.template.default_daily_session_limit && props.template.default_daily_session_limit !== 500
})

// Computed for translations
const hasTranslations = computed(() => {
  return props.template.translation_languages && props.template.translation_languages.length > 0
})

// Available languages for import (original + translations)
interface LanguageOption {
  code: string
  name: string
  flag: string
  isOriginal: boolean
}

const availableLanguages = computed<LanguageOption[]>(() => {
  const languages: LanguageOption[] = []
  
  // Add original language first
  const originalLang = props.template.original_language || 'en'
  languages.push({
    code: originalLang,
    name: getLanguageName(originalLang),
    flag: getLanguageFlag(originalLang),
    isOriginal: true
  })
  
  // Add translated languages
  if (props.template.translation_languages) {
    for (const lang of props.template.translation_languages) {
      if (lang !== originalLang) {  // Avoid duplicates
        languages.push({
          code: lang,
          name: getLanguageName(lang),
          flag: getLanguageFlag(lang),
          isOriginal: false
        })
      }
    }
  }
  
  return languages
})

// Get placeholder name based on selected language
function getPlaceholderName(): string {
  // If selecting original language, use template name
  // Otherwise, we don't know the translated name here (it's in the DB)
  // So just show the original name as placeholder
  return props.template.name
}

function getModeIcon(mode: string): string {
  const icons: Record<string, string> = {
    single: 'pi pi-file',
    list: 'pi pi-list',
    grid: 'pi pi-th-large',
    cards: 'pi pi-clone',
    inline: 'pi pi-bars'
  }
  return icons[mode] || 'pi pi-file'
}

function getModeSmallIcon(mode: string): string {
  const icons: Record<string, string> = {
    single: 'pi pi-file',
    list: 'pi pi-list',
    grid: 'pi pi-th-large',
    cards: 'pi pi-clone',
    inline: 'pi pi-bars'
  }
  return icons[mode] || 'pi pi-file'
}

function getModeLabel(mode: string): string {
  const labels: Record<string, string> = {
    single: t('templates.mode_single'),
    list: t('templates.mode_list'),
    grid: t('templates.mode_grid'),
    cards: t('templates.mode_cards'),
    inline: t('templates.mode_inline')
  }
  return labels[mode] || mode
}

async function handleImport() {
  isImporting.value = true
  errorMessage.value = ''

  try {
    // Check subscription limit before importing
    await subscriptionStore.fetchSubscription()
    
    if (!subscriptionStore.canCreateExperience) {
      errorMessage.value = t('subscription.upgrade_to_create_more', {
        limit: subscriptionStore.experienceLimit,
        current: subscriptionStore.experienceCount
      })
      isImporting.value = false
      return
    }
    
    const result = await templateStore.importTemplate(
      props.template.id,
      customName.value || undefined,
      selectedBillingType.value,
      selectedLanguage.value  // Pass selected language
    )

    if (result.success && result.card_id) {
      emit('imported', { cardId: result.card_id })
    } else {
      errorMessage.value = result.message || t('templates.import_failed')
    }
  } catch (error: any) {
    errorMessage.value = error.message || t('templates.import_failed')
  } finally {
    isImporting.value = false
  }
}
</script>

<style scoped>
.import-form {
  @apply space-y-6;
}

.template-summary {
  @apply flex items-center gap-4 p-4 bg-slate-50 rounded-lg;
}

.summary-icon {
  @apply w-12 h-12 bg-indigo-100 rounded-lg flex items-center justify-center text-indigo-600 text-xl;
}

.summary-info h4 {
  @apply font-semibold text-slate-900;
}

.summary-info p {
  @apply text-sm text-slate-500;
}

.template-badges {
  @apply flex flex-wrap gap-2 mt-2;
}

.badge {
  @apply inline-flex items-center gap-1 px-2 py-1 rounded-full text-xs font-medium;
}

.badge-mode {
  @apply bg-blue-100 text-blue-700;
}

.badge-language {
  @apply bg-slate-100 text-slate-700;
}

.badge-grouped {
  @apply bg-purple-100 text-purple-700;
}

.access-limits-info {
  @apply bg-amber-50 border border-amber-200 rounded-lg p-3;
}

.limits-header {
  @apply flex items-center gap-2 text-amber-800 text-sm font-medium mb-2;
}

.limits-details {
  @apply flex flex-wrap gap-3;
}

.limit-item {
  @apply inline-flex items-center gap-1 text-sm text-amber-700;
}

.translation-badges {
  @apply flex flex-wrap gap-2 mt-2;
}

.badge-translation {
  @apply bg-green-100 text-green-700;
}

.badge-translation-lang {
  @apply bg-green-50 text-green-600 text-xs;
}

.badge-translation-more {
  @apply bg-green-100 text-green-700 text-xs;
}

.form-content {
  @apply space-y-5;
}

.form-field {
  @apply space-y-2;
}

.form-field label {
  @apply block text-sm font-medium text-slate-700;
}

.field-hint {
  @apply text-xs text-slate-500;
}

.form-actions {
  @apply flex justify-end gap-3 pt-4 border-t border-slate-200;
}

/* Language Selection */
.language-options {
  @apply flex flex-col gap-2;
}

.language-option {
  @apply flex items-center gap-3 p-3 border border-slate-200 rounded-lg cursor-pointer transition-all hover:border-indigo-300 hover:bg-slate-50;
}

.language-option.selected {
  @apply border-indigo-500 bg-indigo-50;
}

.lang-flag {
  @apply text-xl;
}

.lang-name {
  @apply font-medium text-slate-700 flex-grow;
}

.language-option.selected .lang-name {
  @apply text-indigo-700;
}

.lang-badge {
  @apply text-xs px-2 py-0.5 rounded-full;
}

.lang-badge.original {
  @apply bg-slate-100 text-slate-600;
}

.lang-badge.translated {
  @apply bg-green-100 text-green-700;
}

.check-icon {
  @apply text-indigo-600;
}

/* Mobile responsive */
@media (max-width: 480px) {
  .language-option {
    @apply p-2;
  }
  
  .lang-flag {
    @apply text-lg;
  }
  
  .lang-name {
    @apply text-sm;
  }
}
</style>

