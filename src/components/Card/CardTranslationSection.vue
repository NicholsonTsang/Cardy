<template>
  <div class="translation-section bg-white rounded-xl shadow-lg border border-slate-200 overflow-hidden">
    <!-- Header Section -->
    <div class="px-6 py-4 border-b border-slate-200 bg-gradient-to-r from-blue-50 to-purple-50">
      <div class="flex items-start justify-between">
        <div>
          <h3 class="text-lg font-semibold text-slate-900 flex items-center gap-2">
            <i class="pi pi-language text-blue-600"></i>
            {{ $t('translation.sectionTitle') }}
          </h3>
          <p class="text-sm text-slate-600 mt-1">
            {{ $t('translation.sectionSubtitle') }}
          </p>
        </div>
        <Button
          :label="$t('translation.manageTranslations')"
          icon="pi pi-globe"
          severity="primary"
          @click="showTranslationDialog = true"
          :disabled="loading"
          class="shadow-md hover:shadow-lg transition-shadow"
        />
      </div>
    </div>

    <!-- Content Section -->
    <div class="p-6">
      <!-- Warning Message -->
      <Message 
        v-if="!hasAnyTranslations"
        severity="info" 
        :closable="false"
        class="mb-6"
      >
        <div class="text-sm">
          <strong>{{ $t('translation.beforeYouStart') }}</strong>
          <ul class="list-disc ml-5 mt-2 space-y-1">
            <li>{{ $t('translation.warningFinishContent') }}</li>
            <li>{{ $t('translation.warningCost') }}</li>
            <li>{{ $t('translation.warningQuality') }}</li>
          </ul>
        </div>
      </Message>

      <!-- Loading State -->
      <div v-if="loading" class="flex items-center justify-center py-12">
        <ProgressSpinner style="width: 50px; height: 50px" strokeWidth="4" />
      </div>

      <!-- Translation Status -->
      <div v-if="!loading" class="space-y-6">
        <!-- Stats Row -->
        <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
          <!-- Original Language Card -->
          <div class="bg-white border border-slate-200 rounded-lg p-4 hover:shadow-md transition-all duration-200">
            <div class="flex items-start gap-3">
              <div class="w-10 h-10 rounded-lg bg-gradient-to-br from-slate-500 to-slate-600 flex items-center justify-center shadow-md flex-shrink-0">
                <i class="pi pi-flag text-white text-lg"></i>
              </div>
              <div class="flex-1 min-w-0">
                <p class="text-xs font-medium text-slate-600 mb-1">{{ $t('translation.stats.original') }}</p>
                <h4 class="text-lg font-bold text-slate-900 truncate">{{ originalLanguageName }}</h4>
                <p class="text-xs text-slate-500 mt-0.5">&nbsp;</p>
              </div>
            </div>
          </div>

          <!-- Translated Languages Card -->
          <div class="bg-white border border-slate-200 rounded-lg p-4 hover:shadow-md transition-all duration-200">
            <div class="flex items-start gap-3">
              <div class="w-10 h-10 rounded-lg bg-gradient-to-br from-green-500 to-green-600 flex items-center justify-center shadow-md flex-shrink-0">
                <i class="pi pi-check-circle text-white text-lg"></i>
              </div>
              <div class="flex-1 min-w-0">
                <p class="text-xs font-medium text-slate-600 mb-1">{{ $t('translation.stats.translated') }}</p>
                <h4 class="text-lg font-bold text-slate-900">{{ translatedCount }}<span class="text-base text-slate-500 font-normal">/{{ totalLanguagesCount - 1 }}</span></h4>
                <p class="text-xs text-slate-500 mt-0.5">{{ $t('translation.languages') }}</p>
              </div>
            </div>
          </div>

          <!-- Outdated Languages Card -->
          <div class="bg-white border border-slate-200 rounded-lg p-4 hover:shadow-md transition-all duration-200">
            <div class="flex items-start gap-3">
              <div class="w-10 h-10 rounded-lg bg-gradient-to-br from-amber-500 to-amber-600 flex items-center justify-center shadow-md flex-shrink-0">
                <i class="pi pi-exclamation-triangle text-white text-lg"></i>
              </div>
              <div class="flex-1 min-w-0">
                <div class="flex items-center gap-1 mb-1">
                  <p class="text-xs font-medium text-slate-600">{{ $t('translation.stats.outdated') }}</p>
                  <i 
                    class="pi pi-info-circle text-xs text-slate-400 cursor-help"
                    v-tooltip.top="$t('translation.outdatedBoxTooltip')"
                  ></i>
                </div>
                <h4 class="text-lg font-bold text-slate-900">{{ outdatedCount }}</h4>
                <p class="text-xs text-slate-500 mt-0.5">{{ $t('translation.needsUpdate') }}</p>
              </div>
            </div>
          </div>
        </div>

        <!-- Language Tags -->
        <template v-if="hasAnyTranslations">
          <div class="space-y-3">
            <div class="flex items-center justify-between">
              <h4 class="text-sm font-semibold text-slate-700">{{ $t('translation.availableIn') }}</h4>
              <span class="text-xs text-slate-500">{{ translatedLanguages.length }} {{ $t('translation.languages') }}</span>
            </div>
            <div class="flex flex-wrap gap-2">
              <Tag
                v-for="lang in translatedLanguages"
                :key="lang.language"
                :severity="lang.status === 'up_to_date' ? 'success' : 'warning'"
                class="flex items-center gap-2 px-3 py-1.5"
              >
                <span class="text-base">{{ getLanguageFlag(lang.language) }}</span>
                <span class="font-medium">{{ lang.language_name }}</span>
                <i 
                  v-if="lang.status === 'outdated'" 
                  class="pi pi-exclamation-circle text-xs"
                  v-tooltip.top="$t('translation.outdatedTooltip')"
                ></i>
              </Tag>
            </div>
          </div>
        </template>

        <!-- Empty State -->
        <template v-else>
          <div class="text-center py-12 bg-slate-50 rounded-lg border-2 border-dashed border-slate-300">
            <div class="w-16 h-16 mx-auto mb-4 rounded-full bg-gradient-to-br from-blue-100 to-purple-100 flex items-center justify-center">
              <i class="pi pi-language text-3xl text-blue-600"></i>
            </div>
            <p class="text-slate-900 font-semibold text-base mb-1">{{ $t('translation.noTranslationsYet') }}</p>
            <p class="text-slate-500 text-sm">{{ $t('translation.clickButtonToStart') }}</p>
          </div>
        </template>
      </div>
    </div>

    <!-- Translation Dialog -->
    <TranslationDialog
      v-model:visible="showTranslationDialog"
      :card-id="cardId"
      :available-languages="availableLanguages"
      @translated="handleTranslationSuccess"
    />
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useToast } from 'primevue/usetoast';
import Button from 'primevue/button';
import Tag from 'primevue/tag';
import Message from 'primevue/message';
import ProgressSpinner from 'primevue/progressspinner';
import { useTranslationStore, SUPPORTED_LANGUAGES } from '@/stores/translation';
import TranslationDialog from './TranslationDialog.vue';

// Props
const props = defineProps<{
  cardId: string;
}>();

// Composables
const { t } = useI18n();
const toast = useToast();
const translationStore = useTranslationStore();

// State
const loading = ref(false);
const showTranslationDialog = ref(false);

// Computed
const originalLanguageName = computed(() => {
  const original = translationStore.originalLanguage;
  return original ? original.language_name : 'English';
});

const translatedCount = computed(() => {
  return translationStore.upToDateLanguages.length + translationStore.outdatedLanguages.length;
});

const outdatedCount = computed(() => {
  return translationStore.outdatedLanguages.length;
});

const totalLanguagesCount = computed(() => {
  return Object.keys(SUPPORTED_LANGUAGES).length;
});

const hasAnyTranslations = computed(() => {
  return translatedCount.value > 0;
});

const translatedLanguages = computed(() => {
  if (!translationStore.translationStatus) return [];
  
  return [
    ...translationStore.upToDateLanguages,
    ...translationStore.outdatedLanguages
  ].sort((a, b) => {
    if (a.status === 'up_to_date' && b.status === 'outdated') return -1;
    if (a.status === 'outdated' && b.status === 'up_to_date') return 1;
    return a.language_name.localeCompare(b.language_name);
  });
});

const availableLanguages = computed(() => {
  if (!translationStore.translationStatus) return [];
  
  // Return all languages (except original) to show their status in dialog
  return Object.values(translationStore.translationStatus).filter(
    (status) => status.status !== 'original'
  );
});

// Methods
const loadTranslationStatus = async () => {
  loading.value = true;
  try {
    await translationStore.fetchTranslationStatus(props.cardId);
  } catch (error: any) {
    console.error('Failed to load translation status:', error);
  } finally {
    loading.value = false;
  }
};

const handleTranslationSuccess = () => {
  // No toast needed - Dialog already shows success screen (Step 3)
  // Visual feedback: status badges update to show new translations
  loadTranslationStatus();
};

const getLanguageFlag = (languageCode: string): string => {
  const flagMap: Record<string, string> = {
    en: '🇬🇧',
    'zh-Hant': '🇹🇼',
    'zh-Hans': '🇨🇳',
    ja: '🇯🇵',
    ko: '🇰🇷',
    es: '🇪🇸',
    fr: '🇫🇷',
    ru: '🇷🇺',
    ar: '🇸🇦',
    th: '🇹🇭',
  };
  return flagMap[languageCode] || '🌐';
};

// Lifecycle
onMounted(() => {
  loadTranslationStatus();
});

// Watch for card ID changes and reload translation status
watch(() => props.cardId, (newCardId, oldCardId) => {
  if (newCardId && newCardId !== oldCardId) {
    // Reset store state to clear previous card's data
    translationStore.reset();
    // Load new card's translation status
    loadTranslationStatus();
  }
}, { immediate: false });

// Expose methods for parent component to call
defineExpose({
  loadTranslationStatus
});
</script>

<style scoped>
/* No custom styles needed - using Tailwind utility classes */
</style>

