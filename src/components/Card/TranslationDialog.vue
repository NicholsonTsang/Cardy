<template>
  <Dialog
    v-model:visible="dialogVisible"
    :header="dialogTitle"
    :modal="true"
    :closable="!translationStore.isTranslating && !isDeletingBatch"
    :close-on-escape="!translationStore.isTranslating && !isDeletingBatch"
    class="w-full max-w-2xl"
    @update:visible="handleVisibleChange"
  >
    <!-- Step 1: Language Selection -->
    <div v-if="currentStep === 1" class="space-y-6">
      <!-- Mode Tabs -->
      <div class="flex gap-2 border-b border-slate-200">
        <button
          @click="viewMode = 'translate'"
          class="px-4 py-2 font-medium transition-all"
          :class="{
            'text-blue-600 border-b-2 border-blue-600': viewMode === 'translate',
            'text-slate-600 hover:text-slate-900': viewMode !== 'translate'
          }"
        >
          <i class="pi pi-language mr-2"></i>
          {{ $t('translation.dialog.addTranslations') }}
        </button>
        <button
          @click="viewMode = 'manage'"
          class="px-4 py-2 font-medium transition-all relative"
          :class="{
            'text-red-600 border-b-2 border-red-600': viewMode === 'manage',
            'text-slate-600 hover:text-slate-900': viewMode !== 'manage'
          }"
        >
          <i class="pi pi-cog mr-2"></i>
          {{ $t('translation.dialog.manageExisting') }}
          <span class="ml-2 px-2 py-0.5 text-xs font-bold rounded-full bg-slate-200 text-slate-700">
            {{ existingTranslations.length }}
          </span>
        </button>
      </div>

      <!-- Translate Mode -->
      <div v-show="viewMode === 'translate'" class="space-y-6">
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
              'border-blue-400 bg-blue-50': selectedLanguages.includes(lang.language as LanguageCode),
              
              // Unselected states
              'border-amber-300 bg-amber-50/30 hover:bg-amber-50 cursor-pointer': lang.status === 'outdated' && !selectedLanguages.includes(lang.language as LanguageCode),
              'border-slate-200 bg-white hover:bg-slate-50 cursor-pointer': lang.status === 'not_translated' && !selectedLanguages.includes(lang.language as LanguageCode),
              'border-slate-200 bg-slate-50 opacity-60 cursor-not-allowed': lang.status === 'up_to_date' && !selectedLanguages.includes(lang.language as LanguageCode),
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

      <!-- Large Content Warning -->
      <div v-if="contentItemsCount > 20" class="text-sm text-yellow-700 bg-yellow-50 p-3 rounded border border-yellow-200">
        <i class="pi pi-exclamation-triangle mr-2"></i>
        {{ $t('translation.dialog.largeContentWarning') }}
      </div>
      </div>

      <!-- Manage Existing Mode -->
      <div v-show="viewMode === 'manage'" class="space-y-4">
        <!-- Warning Banner -->
        <div class="bg-red-50 border border-red-200 rounded-lg p-4">
          <div class="flex items-start gap-3">
            <i class="pi pi-exclamation-triangle text-red-600 text-xl mt-0.5"></i>
            <div class="flex-1">
              <h4 class="font-semibold text-red-900 mb-1">{{ $t('translation.dialog.manageMode') }}</h4>
              <p class="text-sm text-red-800">{{ $t('translation.dialog.manageModeWarning') }}</p>
            </div>
          </div>
        </div>

        <!-- Bulk Actions -->
        <div v-if="existingTranslations.length > 0" class="flex gap-2 flex-wrap">
          <Button
            :label="selectedForDelete.length === existingTranslations.length ? $t('translation.dialog.deselectAll') : $t('translation.dialog.selectAll')"
            :icon="selectedForDelete.length === existingTranslations.length ? 'pi pi-times' : 'pi pi-check-square'"
            size="small"
            outlined
            severity="secondary"
            @click="toggleSelectAllForDelete"
            :disabled="isDeletingBatch"
          />
          <Button
            v-if="selectedForDelete.length > 0"
            :label="$t('translation.dialog.deleteSelected', { count: selectedForDelete.length })"
            icon="pi pi-trash"
            size="small"
            severity="danger"
            @click="confirmBatchDelete"
            :loading="isDeletingBatch"
            :disabled="isDeletingBatch"
          />
        </div>

        <!-- Batch Delete Progress -->
        <div v-if="isDeletingBatch" class="bg-slate-50 border border-slate-200 rounded-lg p-4">
          <div class="flex justify-between items-center mb-2">
            <span class="text-sm font-medium text-slate-700">
              {{ $t('translation.dialog.deletingProgress') }}
            </span>
            <span class="text-sm font-semibold text-slate-900">
              {{ deleteProgress.completed }}/{{ deleteProgress.total }}
            </span>
          </div>
          <ProgressBar
            :value="(deleteProgress.completed / deleteProgress.total) * 100"
            :show-value="false"
            class="mb-2"
          />
          <p v-if="deleteProgress.current" class="text-xs text-slate-600">
            {{ $t('translation.dialog.deletingLanguage', { language: getLanguageName(deleteProgress.current) }) }}
          </p>
        </div>
        
        <!-- Existing Translations List -->
        <div class="space-y-2">
          <div
            v-for="trans in existingTranslations"
            :key="trans.language"
            class="flex items-center gap-3 p-3 border rounded-lg transition-all cursor-pointer"
            :class="{
              'border-red-400 bg-red-50': selectedForDelete.includes(trans.language),
              'border-slate-200 bg-white hover:bg-slate-50': !selectedForDelete.includes(trans.language)
            }"
            @click="toggleDeleteSelection(trans.language)"
          >
            <Checkbox
              v-model="selectedForDelete"
              :input-id="`delete-${trans.language}`"
              :value="trans.language"
              :disabled="isDeletingBatch"
              @click.stop
            />
            <div class="flex-1 flex items-center gap-3">
              <span class="text-lg">{{ getLanguageFlag(trans.language) }}</span>
              <div class="flex-1">
                <div class="font-medium text-slate-900">{{ trans.language_name }}</div>
                <div class="flex gap-2 mt-1">
                  <Tag 
                    :value="$t(`translation.status.${trans.status}`)"
                    :severity="getStatusSeverity(trans.status)"
                    class="text-xs"
                  />
                  <span v-if="trans.translated_at" class="text-xs text-slate-500">
                    {{ formatRelativeTime(trans.translated_at) }}
                </span>
              </div>
            </div>
            </div>
            <!-- Individual Actions -->
            <div class="flex gap-2" @click.stop>
              <Button
                v-if="trans.status === 'outdated'"
                icon="pi pi-refresh"
                size="small"
                severity="warning"
                outlined
                @click="retranslateLanguage(trans.language)"
                :disabled="isDeletingBatch"
                v-tooltip.left="$t('translation.dialog.retranslate')"
              />
            <Button
              icon="pi pi-trash"
                size="small"
              severity="danger"
                outlined
                @click="confirmSingleDelete(trans)"
                :disabled="isDeletingBatch"
                v-tooltip.left="$t('translation.dialog.delete')"
            />
          </div>
        </div>
      </div>

      <!-- Empty State -->
      <div v-if="existingTranslations.length === 0" class="text-center py-12 bg-slate-50 rounded-lg border-2 border-dashed border-slate-200">
        <i class="pi pi-inbox text-5xl text-slate-400 mb-4 block"></i>
        <p class="text-slate-600 font-medium">{{ $t('translation.dialog.noTranslations') }}</p>
      </div>
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

        <!-- Progress List - Parallel Execution -->
        <div class="text-left max-w-md mx-auto space-y-2">
          <div
            v-for="(lang, index) in selectedLanguages"
            :key="lang"
            class="flex items-center gap-3 p-2 rounded transition-all duration-300"
            :class="{
              'bg-green-50': translationProgress >= selectedLanguages.length,
              'bg-blue-50 animate-pulse': translationProgress < selectedLanguages.length,
            }"
          >
            <i
              class="pi text-lg transition-all duration-300"
                  :class="{
                'pi-check-circle text-green-600': translationProgress >= selectedLanguages.length,
                'pi-spin pi-spinner text-blue-600': translationProgress < selectedLanguages.length,
                  }"
                ></i>
            <span class="flex-1">{{ getLanguageName(lang) }}</span>
              <span 
              class="text-sm transition-all duration-300"
                :class="{
                'text-green-600 font-medium': translationProgress >= selectedLanguages.length,
                'text-blue-600 font-medium': translationProgress < selectedLanguages.length,
              }"
            >
              {{
                translationProgress >= selectedLanguages.length
                  ? $t('translation.dialog.complete')
                  : $t('translation.dialog.translating')
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

    <!-- Step 3: Success/Failure Results -->
    <div v-if="currentStep === 3" class="space-y-6">
      <div class="text-center py-8">
        <!-- Icon based on results -->
        <div 
          class="w-16 h-16 rounded-full flex items-center justify-center mx-auto mb-4"
          :class="{
            'bg-green-100': failedLanguages.length === 0,
            'bg-yellow-100': failedLanguages.length > 0 && completedLanguages.length > 0,
            'bg-red-100': failedLanguages.length > 0 && completedLanguages.length === 0
          }"
        >
          <i 
            class="text-3xl"
            :class="{
              'pi pi-check text-green-600': failedLanguages.length === 0,
              'pi pi-exclamation-triangle text-yellow-600': failedLanguages.length > 0 && completedLanguages.length > 0,
              'pi pi-times text-red-600': failedLanguages.length > 0 && completedLanguages.length === 0
            }"
          ></i>
        </div>
        
        <!-- Title based on results -->
        <h3 class="text-2xl font-semibold text-gray-900 mb-2">
          <template v-if="failedLanguages.length === 0">
            {{ $t('translation.dialog.successTitle') }}
          </template>
          <template v-else-if="completedLanguages.length > 0">
            {{ $t('translation.dialog.partialSuccessTitle') }}
          </template>
          <template v-else>
            {{ $t('translation.dialog.failureTitle') }}
          </template>
        </h3>
        
        <p class="text-gray-600 mb-6">
          <template v-if="failedLanguages.length === 0">
            {{ $t('translation.dialog.successMessage', { count: completedLanguages.length }) }}
          </template>
          <template v-else-if="completedLanguages.length > 0">
            {{ $t('translation.dialog.partialSuccessMessage', { 
              completed: completedLanguages.length, 
              failed: failedLanguages.length 
            }) }}
          </template>
          <template v-else>
            {{ $t('translation.dialog.failureMessage', { count: failedLanguages.length }) }}
          </template>
        </p>

        <!-- Successfully Translated Languages -->
        <div v-if="completedLanguages.length > 0" class="bg-green-50 border border-green-200 rounded-lg p-4 text-left max-w-md mx-auto mb-4">
          <h4 class="font-semibold mb-2 text-green-900">
            <i class="pi pi-check-circle mr-2"></i>
            {{ $t('translation.dialog.successfullyTranslated', { count: completedLanguages.length }) }}
          </h4>
          <div class="flex flex-wrap gap-2">
            <Tag
              v-for="lang in completedLanguages"
              :key="lang"
              :value="`${getLanguageFlag(lang)} ${getLanguageName(lang)}`"
              severity="success"
            />
          </div>
        </div>

        <!-- Failed Languages -->
        <div v-if="failedLanguages.length > 0" class="bg-red-50 border border-red-200 rounded-lg p-4 text-left max-w-md mx-auto mb-4">
          <h4 class="font-semibold mb-2 text-red-900">
            <i class="pi pi-times-circle mr-2"></i>
            {{ $t('translation.dialog.failedTranslations', { count: failedLanguages.length }) }}
          </h4>
          <div class="flex flex-wrap gap-2 mb-3">
            <Tag
              v-for="lang in failedLanguages"
              :key="lang"
              :value="`${getLanguageFlag(lang)} ${getLanguageName(lang)}`"
              severity="danger"
            />
          </div>
          <Button
            :label="$t('translation.dialog.retryFailed')"
            icon="pi pi-refresh"
            size="small"
            severity="warning"
            @click="retryFailedLanguages"
            class="w-full"
          />
        </div>

        <!-- Credit Summary -->
        <div v-if="completedLanguages.length > 0" class="bg-blue-50 border border-blue-200 rounded-lg p-4 text-left max-w-md mx-auto">
          <div class="flex justify-between text-sm mb-1">
            <span class="text-gray-600">{{ $t('translation.dialog.creditsUsed') }}</span>
            <span class="font-semibold">{{ completedLanguages.length }}</span>
          </div>
          <div class="flex justify-between text-sm">
            <span class="text-gray-600">{{ $t('translation.dialog.remainingBalance') }}</span>
            <span class="font-semibold">{{ creditStore.balance }} {{ $t('common.credits') }}</span>
          </div>
        </div>

        <p v-if="completedLanguages.length > 0" class="text-sm text-gray-500 mt-4">
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
          v-if="currentStep === 1 && viewMode === 'translate'"
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

  <!-- Confirmation Dialog -->
  <ConfirmDialog />

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
import ConfirmDialog from 'primevue/confirmdialog';
import { useConfirm } from 'primevue/useconfirm';
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
const confirm = useConfirm();
const translationStore = useTranslationStore();
const creditStore = useCreditStore();

// State
const viewMode = ref<'translate' | 'manage'>('translate');
const currentStep = ref(1); // 1: Selection, 2: Progress, 3: Success
const selectedLanguages = ref<LanguageCode[]>([]);
const selectedForDelete = ref<LanguageCode[]>([]);
const completedLanguages = ref<LanguageCode[]>([]);
const failedLanguages = ref<LanguageCode[]>([]);
const translationProgress = ref(0);
const contentItemsCount = ref(5); // Will be fetched from card data
const showCreditConfirmation = ref(false);
const isDeletingBatch = ref(false);
const deleteProgress = ref({
  completed: 0,
  total: 0,
  current: null as LanguageCode | null,
});

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

const existingTranslations = computed(() => {
  return props.availableLanguages.filter(
    lang => lang.status !== 'original' && lang.status !== 'not_translated'
  );
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
  // With parallel execution, all languages translate simultaneously
  // Time is roughly the same regardless of language count (~30-40 seconds)
  if (translationProgress.value >= selectedLanguages.value.length) {
    return t('translation.dialog.seconds', { seconds: 0 });
  }
  
  // Estimate based on parallel execution
  const baseTime = 30; // Base translation time
  const overhead = Math.min(selectedLanguages.value.length * 0.5, 10); // Small overhead for many languages
  const estimatedTotal = Math.ceil(baseTime + overhead);
  
  if (estimatedTotal < 60) {
    return t('translation.dialog.seconds', { seconds: estimatedTotal });
  }
  const minutes = Math.ceil(estimatedTotal / 60);
  return t('translation.dialog.minutes', { minutes });
});

// Methods
const toggleLanguage = (lang: string) => {
  const index = selectedLanguages.value.indexOf(lang as LanguageCode);
  if (index > -1) {
    selectedLanguages.value.splice(index, 1);
  } else {
    selectedLanguages.value.push(lang as LanguageCode);
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
  completedLanguages.value = [];
  failedLanguages.value = [];

  try {
    // Call translation store
    const result = await translationStore.translateCard(props.cardId, selectedLanguages.value);
    
    // Store successful and failed languages
    completedLanguages.value = (result.translated_languages || []) as LanguageCode[];
    failedLanguages.value = (result.failed_languages || []) as LanguageCode[];
    
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
    viewMode.value = 'translate';
    selectedLanguages.value = [];
    selectedForDelete.value = [];
    completedLanguages.value = [];
    failedLanguages.value = [];
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

// Management Methods
const toggleDeleteSelection = (lang: LanguageCode) => {
  const index = selectedForDelete.value.indexOf(lang);
  if (index > -1) {
    selectedForDelete.value.splice(index, 1);
  } else {
    selectedForDelete.value.push(lang);
  }
};

const toggleSelectAllForDelete = () => {
  if (selectedForDelete.value.length === existingTranslations.value.length) {
    selectedForDelete.value = [];
  } else {
    selectedForDelete.value = existingTranslations.value.map(t => t.language);
  }
};

const confirmSingleDelete = (translation: TranslationStatus) => {
  confirm.require({
    message: t('translation.dialog.confirmDeleteMessage', { language: translation.language_name }),
    header: t('translation.dialog.confirmDeleteTitle'),
    icon: 'pi pi-exclamation-triangle',
    acceptClass: 'p-button-danger',
    accept: () => deleteSingle(translation.language),
  });
};

const deleteSingle = async (language: LanguageCode) => {
  try {
    await translationStore.deleteTranslation(props.cardId, language);
    // Success feedback shown via empty state or updated list
    emit('translated'); // Refresh parent
  } catch (error: any) {
    toast.add({
      severity: 'error',
      summary: t('translation.dialog.deleteFailed'),
      detail: error.message,
      life: 5000,
    });
  }
};

const confirmBatchDelete = () => {
  const languageNames = selectedForDelete.value.map(lang => getLanguageName(lang)).join(', ');
  confirm.require({
    message: t('translation.dialog.confirmBatchDeleteMessage', {
      count: selectedForDelete.value.length,
      languages: languageNames,
    }),
    header: t('translation.dialog.confirmBatchDeleteTitle'),
    icon: 'pi pi-exclamation-triangle',
    acceptClass: 'p-button-danger',
    accept: () => deleteBatch(),
  });
};

const deleteBatch = async () => {
  isDeletingBatch.value = true;
  deleteProgress.value = {
    completed: 0,
    total: selectedForDelete.value.length,
    current: null,
  };

  const languagesToDelete = [...selectedForDelete.value];
  let successCount = 0;
  let failCount = 0;
  
  for (const language of languagesToDelete) {
    deleteProgress.value.current = language;
    try {
      await translationStore.deleteTranslation(props.cardId, language);
      successCount++;
    } catch (error) {
      failCount++;
    }
      deleteProgress.value.completed++;
  }

  isDeletingBatch.value = false;
  deleteProgress.value.current = null;
  selectedForDelete.value = [];

  // Show result only for errors (success is shown via empty state)
  if (successCount === 0) {
    toast.add({
      severity: 'error',
      summary: t('translation.dialog.batchDeleteFailed'),
      detail: t('translation.dialog.allDeletesFailed'),
      life: 5000,
    });
  } else {
    toast.add({
      severity: 'warn',
      summary: t('translation.dialog.batchDeletePartial'),
      detail: t('translation.dialog.partialDeleteResult', { success: successCount, failed: failCount }),
      life: 5000,
    });
  }
  
  emit('translated'); // Refresh parent
};

const retranslateLanguage = (language: LanguageCode) => {
  // Switch to translate mode and pre-select this language
  viewMode.value = 'translate';
  selectedLanguages.value = [language];
  // User can then click translate button
};

const retryFailedLanguages = () => {
  // Reset to step 1 with failed languages selected
  currentStep.value = 1;
  viewMode.value = 'translate';
  selectedLanguages.value = [...failedLanguages.value];
  // Clear the failed list
  failedLanguages.value = [];
  // Show confirmation
  showConfirmation();
};

const getStatusSeverity = (status: string) => {
  const severityMap: Record<string, any> = {
    original: 'info',
    up_to_date: 'success',
    outdated: 'warning',
    not_translated: 'secondary',
  };
  return severityMap[status] || 'secondary';
};

const formatRelativeTime = (dateString: string): string => {
  const date = new Date(dateString);
  const now = new Date();
  const diffMs = now.getTime() - date.getTime();
  const diffMins = Math.floor(diffMs / 60000);
  
  if (diffMins < 1) return t('translation.dialog.justNow');
  if (diffMins < 60) return t('translation.dialog.minutesAgo', { count: diffMins });
  
  const diffHours = Math.floor(diffMins / 60);
  if (diffHours < 24) return t('translation.dialog.hoursAgo', { count: diffHours });
  
  const diffDays = Math.floor(diffHours / 24);
  return t('translation.dialog.daysAgo', { count: diffDays });
};

// Watchers
watch(() => props.visible, (visible) => {
  if (visible) {
    // Refresh credit balance when dialog opens
    creditStore.fetchCreditBalance();
  }
});
</script>

