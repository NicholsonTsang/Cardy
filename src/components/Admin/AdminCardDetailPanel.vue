<template>
  <div class="bg-white rounded-xl shadow-lg border border-slate-200 flex flex-col overflow-hidden">
    <!-- Empty State -->
    <div v-if="!selectedCard" class="flex-1 flex items-center justify-center p-8 min-h-[500px]">
      <div class="text-center">
        <div class="w-20 h-20 bg-slate-100 rounded-full flex items-center justify-center mx-auto mb-4">
          <i class="pi pi-id-card text-3xl text-slate-400"></i>
        </div>
        <h3 class="text-xl font-medium text-slate-900 mb-2">
          {{ $t('admin.select_a_card') }}
        </h3>
        <p class="text-slate-500">
          {{ $t('admin.choose_card_to_view') }}
        </p>
      </div>
    </div>

    <!-- Card Details -->
    <div v-else class="flex-1 flex flex-col">
      <!-- Card Header -->
      <div class="p-6 border-b border-slate-200 bg-white">
        <div class="flex items-center justify-between">
          <div>
            <h2 class="text-xl font-semibold text-slate-900">{{ selectedCard.name }}</h2>
            <p class="text-slate-600 mt-1 text-sm flex items-center gap-2">
              <i class="pi pi-eye text-xs"></i>
              {{ $t('admin.read_only_view') }}
            </p>
          </div>
        </div>
      </div>

      <!-- Tabs -->
      <Tabs :value="activeTab" @update:value="handleTabChange" class="flex-1 flex flex-col">
        <TabList class="flex-shrink-0 border-b border-slate-200 bg-white px-6">
          <Tab v-for="(tab, index) in tabs" :key="index" :value="index.toString()" 
               class="px-4 py-3 font-medium text-sm text-slate-600 hover:text-slate-900 transition-colors">
            <i :class="tab.icon" class="mr-2"></i>
            {{ tab.label }}
          </Tab>
        </TabList>
        <TabPanels class="flex-1 overflow-hidden bg-slate-50">
          <TabPanel v-for="(tab, index) in tabs" :value="index.toString()" class="h-full">
            <div class="h-full overflow-y-auto p-6">
              <!-- General Tab -->
              <div v-if="getTabComponent(index) === 'general'">
                <AdminCardGeneral :card="selectedCard" />
              </div>
              
              <!-- Content Tab -->
              <div v-if="getTabComponent(index) === 'content'">
                <AdminCardContent
                  :cardId="selectedCard.id"
                  :content="content"
                  :isLoading="isLoadingContent"
                />
              </div>
              
              <!-- QR & Access Tab -->
              <div v-if="getTabComponent(index) === 'qr'">
                <DigitalAccessQR
                  :card="selectedCard"
                  :cardName="selectedCard.name"
                  :readOnly="true"
                />
              </div>
              
              <!-- Preview Tab -->
              <div v-if="getTabComponent(index) === 'preview'">
                <MobilePreview
                  :cardProp="selectedCard"
                />
              </div>
            </div>
          </TabPanel>
        </TabPanels>
      </Tabs>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { useI18n } from 'vue-i18n'
import Tabs from 'primevue/tabs'
import TabList from 'primevue/tablist'
import Tab from 'primevue/tab'
import TabPanels from 'primevue/tabpanels'
import TabPanel from 'primevue/tabpanel'
import AdminCardGeneral from './AdminCardGeneral.vue'
import AdminCardContent from './AdminCardContent.vue'
import DigitalAccessQR from '@/components/DigitalAccess/DigitalAccessQR.vue'
import MobilePreview from '@/components/CardComponents/MobilePreview.vue'

const { t } = useI18n()

interface Card {
  id: string
  user_id: string
  name: string
  description: string
  image_url: string | null
  original_image_url: string | null
  crop_parameters: any
  conversation_ai_enabled: boolean
  ai_instruction: string
  ai_knowledge_base: string
  ai_welcome_general: string
  ai_welcome_item: string
  qr_code_position: string
  translations?: Record<string, any>
  original_language?: string
  content_hash?: string
  last_content_update?: string
  content_mode: 'single' | 'grid' | 'list' | 'cards'
  is_grouped: boolean
  group_display: 'expanded' | 'collapsed'
  default_daily_session_limit: number | null
  total_sessions: number
  monthly_sessions: number
  daily_sessions: number
  active_qr_codes: number
  total_qr_codes: number
  created_at: string
  updated_at: string
}

interface ContentItem {
  id: string
  name: string
  content: string | null
  image_url: string | null
  parent_id: string | null
  ai_knowledge_base: string | null
}

interface Props {
  selectedCard: Card | null
  content: ContentItem[]
  isLoadingContent: boolean
  activeTab: string
}

const props = defineProps<Props>()

const emit = defineEmits<{
  (e: 'update:activeTab', value: string): void
}>()

// Tabs: [General, Content, QR & Access, Preview]
const tabs = computed(() => [
  { label: t('dashboard.general'), icon: 'pi pi-info-circle' },
  { label: t('dashboard.content'), icon: 'pi pi-list' },
  { label: t('dashboard.qr_access'), icon: 'pi pi-qrcode' },
  { label: t('dashboard.preview'), icon: 'pi pi-mobile' }
])

// Map tab index to component type
const getTabComponent = (index: number): string | null => {
  if (index === 0) return 'general'
  if (index === 1) return 'content'
  if (index === 2) return 'qr'
  if (index === 3) return 'preview'
  return null
}

const handleTabChange = (value: string | number) => {
  emit('update:activeTab', String(value))
}
</script>

<style scoped>
:deep(.p-tabview-panels) {
  padding: 0;
}

:deep(.p-tabview-nav) {
  border-bottom: 1px solid #e2e8f0;
}
</style>

