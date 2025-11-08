<template>
  <div class="translation-management p-6">
    <!-- Header Section -->
    <div class="mb-6">
      <div class="flex justify-between items-center mb-4">
        <div>
          <h2 class="text-2xl font-semibold text-gray-900">
            {{ $t('translation.title') }}
          </h2>
          <p class="text-sm text-gray-600 mt-1">
            {{ $t('translation.subtitle') }}
          </p>
        </div>
        
        <!-- Quick Actions -->
        <div class="flex gap-2">
          <Button
            v-if="translationStore.outdatedLanguages.length > 0"
            :label="`${$t('translation.updateOutdated')} (${translationStore.outdatedLanguages.length})`"
            icon="pi pi-refresh"
            severity="warning"
            @click="handleUpdateOutdated"
          />
          <Button
            :label="$t('translation.translateNew')"
            icon="pi pi-plus"
            @click="showTranslationDialog = true"
          />
        </div>
      </div>

      <!-- Stats Cards -->
      <div class="grid grid-cols-1 md:grid-cols-4 gap-4 mb-6">
        <div class="bg-blue-50 border border-blue-200 rounded-lg p-4">
          <div class="flex items-center justify-between">
            <div>
              <p class="text-sm text-blue-600 font-medium">{{ $t('translation.stats.original') }}</p>
              <p class="text-2xl font-bold text-blue-900">{{ translationStore.originalLanguage?.language_name || 'English' }}</p>
            </div>
            <i class="pi pi-globe text-3xl text-blue-400"></i>
          </div>
        </div>

        <div class="bg-green-50 border border-green-200 rounded-lg p-4">
          <div class="flex items-center justify-between">
            <div>
              <p class="text-sm text-green-600 font-medium">{{ $t('translation.stats.upToDate') }}</p>
              <p class="text-2xl font-bold text-green-900">{{ translationStore.upToDateLanguages.length }}</p>
            </div>
            <i class="pi pi-check-circle text-3xl text-green-400"></i>
          </div>
        </div>

        <div class="bg-yellow-50 border border-yellow-200 rounded-lg p-4">
          <div class="flex items-center justify-between">
            <div>
              <p class="text-sm text-yellow-600 font-medium">{{ $t('translation.stats.outdated') }}</p>
              <p class="text-2xl font-bold text-yellow-900">{{ translationStore.outdatedLanguages.length }}</p>
            </div>
            <i class="pi pi-exclamation-triangle text-3xl text-yellow-400"></i>
          </div>
        </div>

        <div class="bg-gray-50 border border-gray-200 rounded-lg p-4">
          <div class="flex items-center justify-between">
            <div>
              <p class="text-sm text-gray-600 font-medium">{{ $t('translation.stats.total') }}</p>
              <p class="text-2xl font-bold text-gray-900">
                {{ translationStore.translatedCount }}/{{ translationStore.totalLanguagesCount - 1 }}
              </p>
            </div>
            <i class="pi pi-chart-bar text-3xl text-gray-400"></i>
          </div>
        </div>
      </div>
    </div>

    <!-- Translation Status Table -->
    <DataTable
      :value="translationStatusList"
      :loading="loading"
      class="p-datatable-sm"
      striped-rows
      responsive-layout="scroll"
    >
      <template #empty>
        <div class="text-center py-8">
          <i class="pi pi-inbox text-4xl text-gray-400 mb-3"></i>
          <p class="text-gray-600">{{ $t('translation.noData') }}</p>
        </div>
      </template>

      <!-- Language Column -->
      <Column field="language_name" :header="$t('translation.table.language')" sortable>
        <template #body="{ data }">
          <div class="flex items-center gap-2">
            <span class="text-lg">{{ getLanguageFlag(data.language) }}</span>
            <span class="font-medium">{{ data.language_name }}</span>
            <Tag
              v-if="data.status === 'original'"
              :value="$t('translation.status.original')"
              severity="info"
              class="text-xs"
            />
          </div>
        </template>
      </Column>

      <!-- Status Column -->
      <Column field="status" :header="$t('translation.table.status')" sortable>
        <template #body="{ data }">
          <Tag
            :value="$t(`translation.status.${data.status}`)"
            :severity="getStatusSeverity(data.status)"
          />
        </template>
      </Column>

      <!-- Last Updated Column -->
      <Column field="translated_at" :header="$t('translation.table.lastUpdated')" sortable>
        <template #body="{ data }">
          <span v-if="data.translated_at" class="text-sm text-gray-600">
            {{ formatDate(data.translated_at) }}
          </span>
          <span v-else class="text-sm text-gray-400">-</span>
        </template>
      </Column>

      <!-- Fields Count Column -->
      <Column :header="$t('translation.table.fields')">
        <template #body="{ data }">
          <span class="text-sm text-gray-600">
            {{ data.content_fields_count }} {{ $t('translation.fields') }}
          </span>
        </template>
      </Column>

      <!-- Actions Column -->
      <Column :header="$t('translation.table.actions')" style="width: 200px">
        <template #body="{ data }">
          <div class="flex gap-2">
            <!-- Translate/Update Button -->
            <Button
              v-if="data.status !== 'original'"
              :label="data.status === 'not_translated' ? $t('translation.actions.translate') : $t('translation.actions.update')"
              :icon="data.status === 'not_translated' ? 'pi pi-plus' : 'pi pi-refresh'"
              :severity="data.needs_update ? 'warning' : 'secondary'"
              size="small"
              outlined
              @click="translateSingleLanguage(data.language)"
            />

            <!-- Delete Button -->
            <Button
              v-if="data.status !== 'original' && data.status !== 'not_translated'"
              icon="pi pi-trash"
              severity="danger"
              size="small"
              outlined
              @click="confirmDelete(data)"
            />
          </div>
        </template>
      </Column>
    </DataTable>

    <!-- Translation Dialog -->
    <TranslationDialog
      v-model:visible="showTranslationDialog"
      :card-id="cardId"
      :available-languages="availableLanguagesForTranslation"
      @translated="handleTranslationSuccess"
    />

    <!-- Delete Confirmation Dialog -->
    <ConfirmDialog />
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useConfirm } from 'primevue/useconfirm';
import { useToast } from 'primevue/usetoast';
import DataTable from 'primevue/datatable';
import Column from 'primevue/column';
import Button from 'primevue/button';
import Tag from 'primevue/tag';
import ConfirmDialog from 'primevue/confirmdialog';
import { useTranslationStore, type LanguageCode } from '@/stores/translation';
import TranslationDialog from './TranslationDialog.vue';

// Props
const props = defineProps<{
  cardId: string;
}>();

// Composables
const { t } = useI18n();
const confirm = useConfirm();
const toast = useToast();
const translationStore = useTranslationStore();

// State
const loading = ref(false);
const showTranslationDialog = ref(false);

// Computed
const translationStatusList = computed(() => {
  return Object.values(translationStore.translationStatus).sort((a, b) => {
    // Sort: original first, then up-to-date, then outdated, then not translated
    const statusOrder = { original: 0, up_to_date: 1, outdated: 2, not_translated: 3 };
    return statusOrder[a.status] - statusOrder[b.status];
  });
});

const availableLanguagesForTranslation = computed(() => {
  return Object.values(translationStore.translationStatus).filter(
    (status) => status.status === 'not_translated' || status.status === 'outdated'
  );
});

// Methods
const loadTranslationStatus = async () => {
  loading.value = true;
  try {
    await translationStore.fetchTranslationStatus(props.cardId);
  } catch (error: any) {
    toast.add({
      severity: 'error',
      summary: t('translation.error.loadFailed'),
      detail: error.message,
      life: 5000,
    });
  } finally {
    loading.value = false;
  }
};

const translateSingleLanguage = async (language: LanguageCode) => {
  // Open dialog with single language pre-selected
  showTranslationDialog.value = true;
};

const handleUpdateOutdated = () => {
  showTranslationDialog.value = true;
};

const handleTranslationSuccess = () => {
  // Don't show toast here - real-time progress already shows completion
  // Just reload status after translation completes
  setTimeout(() => {
    loadTranslationStatus();
  }, 1000);
};

const confirmDelete = (translation: any) => {
  confirm.require({
    message: t('translation.delete.confirm', { language: translation.language_name }),
    header: t('translation.delete.title'),
    icon: 'pi pi-exclamation-triangle',
    acceptClass: 'p-button-danger',
    accept: () => deleteTranslation(translation.language),
  });
};

const deleteTranslation = async (language: LanguageCode) => {
  try {
    await translationStore.deleteTranslation(props.cardId, language);
    // No success toast needed - Table updates visually to show deletion
    loadTranslationStatus();
  } catch (error: any) {
    toast.add({
      severity: 'error',
      summary: t('translation.delete.error'),
      detail: error.message,
      life: 5000,
    });
  }
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

const formatDate = (dateString: string): string => {
  const date = new Date(dateString);
  const now = new Date();
  const diffMs = now.getTime() - date.getTime();
  const diffHours = Math.floor(diffMs / (1000 * 60 * 60));
  const diffDays = Math.floor(diffHours / 24);

  if (diffHours < 1) return t('translation.time.justNow');
  if (diffHours < 24) return t('translation.time.hoursAgo', { hours: diffHours });
  if (diffDays < 7) return t('translation.time.daysAgo', { days: diffDays });
  
  return date.toLocaleDateString();
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
</script>

<style scoped>
.translation-management {
  min-height: 400px;
}
</style>

