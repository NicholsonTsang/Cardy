<template>
  <Dialog
    v-model:visible="dialogVisible"
    :header="dialogTitle"
    :modal="true"
    :closable="!translationStore.isTranslating"
    :close-on-escape="!translationStore.isTranslating"
    class="w-full max-w-2xl"
    @update:visible="handleVisibleChange"
  >
    <!-- Step 1: Language Selection -->
    <div v-if="currentStep === 1" class="space-y-6">
      <!-- Quick Selection Buttons -->
      <div class="flex gap-2 flex-wrap">
        <Button
          :label="$t('translation.dialog.selectAll')"
          icon="pi pi-check-square"
          size="small"
          outlined
          @click="selectAll"
        />
        <Button
          :label="$t('translation.dialog.clearAll')"
          icon="pi pi-times"
          size="small"
          severity="secondary"
          outlined
          @click="clearAll"
          :disabled="selectedLanguages.length === 0"
        />
        <Button
          :label="$t('translation.dialog.selectPopular')"
          icon="pi pi-star"
          size="small"
          outlined
          @click="selectPopular"
        />
        <Button
          v-if="outdatedLanguages.length > 0"
          :label="$t('translation.dialog.selectOutdated', { count: outdatedLanguages.length })"
          icon="pi pi-exclamation-triangle"
          size="small"
          severity="warning"
          outlined
          @click="selectOutdated"
        />
      </div>

      <!-- Language Selection Grid -->
      <div class="grid grid-cols-1 md:grid-cols-2 gap-3">
        <div
          v-for="lang in selectableLanguages"
          :key="lang.language"
          class="flex items-center p-3 border rounded-lg transition-all"
          :class="{
            // Selected state
            'border-blue-400 bg-blue-50': selectedLanguages.includes(lang.language),
            
            // Unselected states
            'border-amber-300 bg-amber-50/30 hover:bg-amber-50 cursor-pointer': lang.status === 'outdated' && !selectedLanguages.includes(lang.language),
            'border-slate-200 bg-white hover:bg-slate-50 cursor-pointer': lang.status === 'not_translated' && !selectedLanguages.includes(lang.language),
            'border-slate-200 bg-slate-50 opacity-60 cursor-not-allowed': lang.status === 'up_to_date' && !selectedLanguages.includes(lang.language),
          }"
          @click="lang.status !== 'up_to_date' && toggleLanguage(lang.language)"
        >
          <Checkbox
            v-model="selectedLanguages"
            :input-id="`lang-${lang.language}`"
            :value="lang.language"
            :disabled="lang.status === 'up_to_date'"
            class="mr-3"
            @click.stop
          />
          <label 
            :for="`lang-${lang.language}`" 
            class="flex-1 flex items-center justify-between"
            :class="lang.status === 'up_to_date' ? 'cursor-not-allowed' : 'cursor-pointer'"
          >
            <div class="flex items-center gap-2">
              <span class="text-lg">{{ getLanguageFlag(lang.language) }}</span>
              <span 
                class="text-sm font-medium"
                :class="lang.status === 'up_to_date' ? 'text-gray-400' : 'text-gray-900'"
              >
                {{ lang.language_name }}
              </span>
            </div>
            
            <!-- Status Indicators - Minimal -->
            <i 
              v-if="lang.status === 'outdated'"
              class="pi pi-exclamation-circle text-amber-600 text-xs"
              v-tooltip.left="$t('translation.dialog.outdatedTooltip')"
            ></i>
            <i 
              v-if="lang.status === 'up_to_date'"
              class="pi pi-check-circle text-green-600 text-xs"
              v-tooltip.left="$t('translation.dialog.upToDateTooltip')"
            ></i>
          </label>
        </div>
      </div>

      <!-- Translation Preview -->
      <div v-if="selectedLanguages.length > 0" class="bg-gray-50 p-4 rounded-lg">
        <h4 class="font-semibold mb-2">{{ $t('translation.dialog.preview') }}</h4>
        <ul class="text-sm text-gray-600 space-y-1">
          <li>• {{ $t('translation.dialog.cardFields') }}</li>
          <li>• {{ $t('translation.dialog.contentItems', { count: contentItemsCount }) }}</li>
          <li class="pt-2 text-gray-800 font-medium">
            {{ $t('translation.dialog.totalFields', { count: totalFieldsCount }) }}
          </li>
        </ul>
      </div>

      <!-- Cost Calculation -->
      <div v-if="selectedLanguages.length > 0" class="bg-blue-50 border border-blue-200 p-4 rounded-lg">
        <div class="flex items-start gap-3">
          <i class="pi pi-info-circle text-blue-600 text-xl mt-1"></i>
          <div class="flex-1">
            <h4 class="font-semibold text-blue-900 mb-2">{{ $t('translation.dialog.costTitle') }}</h4>
            <div class="space-y-1 text-sm text-blue-800">
              <div class="flex justify-between">
                <span>{{ $t('translation.dialog.languages', { count: selectedLanguages.length }) }}</span>
                <span class="font-mono">{{ selectedLanguages.length }} × 1 = {{ selectedLanguages.length }} {{ $t('common.credits') }}</span>
              </div>
              <div class="flex justify-between font-semibold">
                <span>{{ $t('translation.dialog.total') }}</span>
                <span class="font-mono">{{ selectedLanguages.length }} {{ $t('common.credits') }}</span>
              </div>
              <div class="border-t border-blue-300 pt-2 mt-2">
                <div class="flex justify-between">
                  <span>{{ $t('translation.dialog.currentBalance') }}</span>
                  <span class="font-mono">{{ creditStore.balance }} {{ $t('common.credits') }}</span>
                </div>
                <div class="flex justify-between" :class="remainingBalance < 0 ? 'text-red-600' : ''">
                  <span>{{ $t('translation.dialog.afterTranslation') }}</span>
                  <span class="font-mono font-semibold">{{ remainingBalance }} {{ $t('common.credits') }}</span>
                </div>
              </div>
            </div>
            <div v-if="remainingBalance < 0" class="mt-3 p-2 bg-red-50 border border-red-200 rounded text-sm text-red-700">
              <i class="pi pi-exclamation-triangle mr-2"></i>
              {{ $t('translation.dialog.insufficientCredits') }}
              <router-link to="/cms/credits" class="underline font-semibold ml-1">
                {{ $t('translation.dialog.purchaseCredits') }}
              </router-link>
            </div>
          </div>
        </div>
      </div>

      <!-- AI Notice -->
      <div class="text-sm text-gray-600 bg-gray-50 p-3 rounded">
        <i class="pi pi-sparkles mr-2"></i>
        {{ $t('translation.dialog.aiNotice') }}
      </div>

      <!-- Large Content Warning -->
      <div v-if="contentItemsCount > 20" class="text-sm text-yellow-700 bg-yellow-50 p-3 rounded border border-yellow-200">
        <i class="pi pi-exclamation-triangle mr-2"></i>
        {{ $t('translation.dialog.largeContentWarning') }}
      </div>
    </div>

    <!-- Step 2: Translation Progress -->
    <div v-if="currentStep === 2" class="space-y-6">
      <div class="text-center py-8">
        <i class="pi pi-spin pi-spinner text-4xl text-blue-600 mb-4"></i>
        <h3 class="text-xl font-semibold text-gray-900 mb-2">
          {{ $t('translation.dialog.translating') }}
        </h3>
        <p class="text-gray-600 mb-6">
          {{ $t('translation.dialog.translatingMessage', { count: selectedLanguages.length }) }}
        </p>

        <!-- Progress List -->
        <div class="text-left max-w-md mx-auto space-y-2">
          <div
            v-for="(lang, index) in selectedLanguages"
            :key="lang"
            class="flex items-center gap-3 p-2 rounded"
            :class="{
              'bg-green-50': index < translationProgress,
              'bg-blue-50': index === translationProgress,
              'bg-gray-50': index > translationProgress,
            }"
          >
            <i
              class="pi text-lg"
              :class="{
                'pi-check-circle text-green-600': index < translationProgress,
                'pi-spin pi-spinner text-blue-600': index === translationProgress,
                'pi-circle text-gray-400': index > translationProgress,
              }"
            ></i>
            <span class="flex-1">{{ getLanguageName(lang) }}</span>
            <span
              class="text-sm"
              :class="{
                'text-green-600 font-medium': index < translationProgress,
                'text-blue-600': index === translationProgress,
                'text-gray-400': index > translationProgress,
              }"
            >
              {{
                index < translationProgress
                  ? $t('translation.dialog.complete')
                  : index === translationProgress
                  ? $t('translation.dialog.translating')
                  : $t('translation.dialog.pending')
              }}
            </span>
          </div>
        </div>

        <!-- Overall Progress -->
        <ProgressBar
          :value="overallProgress"
          class="mt-6"
          :show-value="true"
        />
        <p class="text-sm text-gray-500 mt-2">
          {{ $t('translation.dialog.estimatedTime', { time: estimatedTimeRemaining }) }}
        </p>
      </div>
    </div>

    <!-- Step 3: Success -->
    <div v-if="currentStep === 3" class="space-y-6">
      <div class="text-center py-8">
        <div class="w-16 h-16 bg-green-100 rounded-full flex items-center justify-center mx-auto mb-4">
          <i class="pi pi-check text-3xl text-green-600"></i>
        </div>
        <h3 class="text-2xl font-semibold text-gray-900 mb-2">
          {{ $t('translation.dialog.successTitle') }}
        </h3>
        <p class="text-gray-600 mb-6">
          {{ $t('translation.dialog.successMessage', { count: selectedLanguages.length }) }}
        </p>

        <!-- Translated Languages List -->
        <div class="bg-gray-50 rounded-lg p-4 text-left max-w-md mx-auto mb-4">
          <h4 class="font-semibold mb-2">{{ $t('translation.dialog.translatedLanguages') }}</h4>
          <div class="flex flex-wrap gap-2">
            <Tag
              v-for="lang in selectedLanguages"
              :key="lang"
              :value="`${getLanguageFlag(lang)} ${getLanguageName(lang)}`"
              severity="success"
            />
          </div>
        </div>

        <!-- Credit Summary -->
        <div class="bg-blue-50 border border-blue-200 rounded-lg p-4 text-left max-w-md mx-auto">
          <div class="flex justify-between text-sm mb-1">
            <span class="text-gray-600">{{ $t('translation.dialog.creditsUsed') }}</span>
            <span class="font-semibold">{{ selectedLanguages.length }}</span>
          </div>
          <div class="flex justify-between text-sm">
            <span class="text-gray-600">{{ $t('translation.dialog.remainingBalance') }}</span>
            <span class="font-semibold">{{ creditStore.balance }} {{ $t('common.credits') }}</span>
          </div>
        </div>

        <p class="text-sm text-gray-500 mt-4">
          {{ $t('translation.dialog.availableMessage') }}
        </p>
      </div>
    </div>

    <!-- Footer -->
    <template #footer>
      <div class="flex justify-end gap-2">
        <Button
          v-if="currentStep === 1"
          :label="$t('common.cancel')"
          icon="pi pi-times"
          severity="secondary"
          outlined
          @click="closeDialog"
        />
        <Button
          v-if="currentStep === 1"
          :label="$t('translation.dialog.translate', { count: selectedLanguages.length })"
          icon="pi pi-language"
          :disabled="selectedLanguages.length === 0 || remainingBalance < 0"
          @click="showConfirmation"
        />
        <Button
          v-if="currentStep === 3"
          :label="$t('common.done')"
          icon="pi pi-check"
          @click="closeDialog"
        />
      </div>
    </template>
  </Dialog>

  <!-- Credit Confirmation Dialog -->
  <CreditConfirmationDialog
    v-model:visible="showCreditConfirmation"
    :credits-to-consume="selectedLanguages.length"
    :current-balance="creditStore.balance"
    :loading="translationStore.isTranslating"
    :action-description="$t('translation.dialog.creditActionDescription', { count: selectedLanguages.length })"
    :confirmation-question="$t('translation.dialog.creditConfirmQuestion')"
    :confirm-label="$t('translation.dialog.confirmTranslate')"
    @confirm="handleConfirmTranslation"
    @cancel="handleCancelConfirmation"
  >
    <template #details>
      <div class="space-y-3">
        <div class="flex justify-between items-center">
          <span class="text-slate-600">{{ $t('translation.dialog.languagesToTranslate') }}:</span>
          <span class="font-semibold text-slate-900">{{ selectedLanguages.length }}</span>
        </div>
        <div class="flex justify-between items-center">
          <span class="text-slate-600">{{ $t('translation.dialog.creditPerLanguage') }}:</span>
          <span class="font-semibold text-slate-900">1 {{ $t('batches.credit') }}</span>
        </div>
      </div>
    </template>
  </CreditConfirmationDialog>
</template>

<script setup lang="ts">
import { ref, computed, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useToast } from 'primevue/usetoast';
import Dialog from 'primevue/dialog';
import Button from 'primevue/button';
import Checkbox from 'primevue/checkbox';
import Tag from 'primevue/tag';
import ProgressBar from 'primevue/progressbar';
import { useTranslationStore, SUPPORTED_LANGUAGES, type LanguageCode, type TranslationStatus } from '@/stores/translation';
import { useCreditStore } from '@/stores/credits';
import CreditConfirmationDialog from '@/components/CreditConfirmationDialog.vue';

// Props & Emits
const props = defineProps<{
  visible: boolean;
  cardId: string;
  availableLanguages: TranslationStatus[];
}>();

const emit = defineEmits<{
  (e: 'update:visible', value: boolean): void;
  (e: 'translated'): void;
}>();

// Composables
const { t } = useI18n();
const toast = useToast();
const translationStore = useTranslationStore();
const creditStore = useCreditStore();

// State
const currentStep = ref(1); // 1: Selection, 2: Progress, 3: Success
const selectedLanguages = ref<LanguageCode[]>([]);
const translationProgress = ref(0);
const contentItemsCount = ref(5); // Will be fetched from card data
const showCreditConfirmation = ref(false);

// Computed
const dialogVisible = computed({
  get: () => props.visible,
  set: (value) => emit('update:visible', value),
});

const dialogTitle = computed(() => {
  if (currentStep.value === 1) return t('translation.dialog.title');
  if (currentStep.value === 2) return t('translation.dialog.translatingTitle');
  return t('translation.dialog.successTitle');
});

const selectableLanguages = computed(() => {
  return props.availableLanguages.filter(lang => lang.status !== 'original');
});

const outdatedLanguages = computed(() => {
  return props.availableLanguages.filter(lang => lang.status === 'outdated');
});

const totalFieldsCount = computed(() => {
  return 2 + (contentItemsCount.value * 2); // 2 card fields + N items × 2 fields (name, content)
});

const remainingBalance = computed(() => {
  return creditStore.balance - selectedLanguages.value.length;
});

const overallProgress = computed(() => {
  if (selectedLanguages.value.length === 0) return 0;
  return Math.round((translationProgress.value / selectedLanguages.value.length) * 100);
});

const estimatedTimeRemaining = computed(() => {
  const remaining = selectedLanguages.value.length - translationProgress.value;
  const secondsPerLanguage = 30;
  const totalSeconds = remaining * secondsPerLanguage;
  
  if (totalSeconds < 60) return t('translation.dialog.seconds', { seconds: totalSeconds });
  const minutes = Math.ceil(totalSeconds / 60);
  return t('translation.dialog.minutes', { minutes });
});

// Methods
const toggleLanguage = (lang: LanguageCode) => {
  const index = selectedLanguages.value.indexOf(lang);
  if (index > -1) {
    selectedLanguages.value.splice(index, 1);
  } else {
    selectedLanguages.value.push(lang);
  }
};

const selectAll = () => {
  // Only select languages that are not already up-to-date
  selectedLanguages.value = selectableLanguages.value
    .filter(lang => lang.status !== 'up_to_date')
    .map(lang => lang.language as LanguageCode);
};

const clearAll = () => {
  selectedLanguages.value = [];
};

const selectPopular = () => {
  // Popular languages: Chinese (both), Japanese, Korean
  const popular = ['zh-Hant', 'zh-Hans', 'ja', 'ko'] as LanguageCode[];
  selectedLanguages.value = popular.filter(lang =>
    selectableLanguages.value.some(l => l.language === lang)
  );
};

const selectOutdated = () => {
  selectedLanguages.value = outdatedLanguages.value.map(lang => lang.language as LanguageCode);
};

// Show credit confirmation dialog
const showConfirmation = () => {
  showCreditConfirmation.value = true;
};

// Handle credit confirmation
const handleConfirmTranslation = async () => {
  showCreditConfirmation.value = false;
  await startTranslation();
};

// Handle credit confirmation cancel
const handleCancelConfirmation = () => {
  showCreditConfirmation.value = false;
};

const startTranslation = async () => {
  currentStep.value = 2;
  translationProgress.value = 0;

  try {
    // Call translation store
    await translationStore.translateCard(props.cardId, selectedLanguages.value);
    
    translationProgress.value = selectedLanguages.value.length;
    currentStep.value = 3;
    
    emit('translated');
  } catch (error: any) {
    toast.add({
      severity: 'error',
      summary: t('translation.error.failed'),
      detail: error.message,
      life: 5000,
    });
    closeDialog();
  }
};

const closeDialog = () => {
  dialogVisible.value = false;
  // Reset after animation
  setTimeout(() => {
    currentStep.value = 1;
    selectedLanguages.value = [];
    translationProgress.value = 0;
  }, 300);
};

const handleVisibleChange = (visible: boolean) => {
  if (!visible && currentStep.value === 2) {
    // Prevent closing during translation
    return;
  }
  emit('update:visible', visible);
};

const getLanguageName = (code: LanguageCode): string => {
  return SUPPORTED_LANGUAGES[code] || code;
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

// Watchers
watch(() => props.visible, (visible) => {
  if (visible) {
    // Refresh credit balance when dialog opens
    creditStore.fetchCreditBalance();
  }
});
</script>

