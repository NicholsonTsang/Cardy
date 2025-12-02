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
              
              <!-- Issuance Tab (Physical Cards Only) -->
              <div v-if="getTabComponent(index) === 'issuance'">
                <AdminCardIssuance
                  :cardId="selectedCard.id"
                  :batches="batches"
                  :isLoading="isLoadingBatches"
                />
              </div>
              
              <!-- QR & Access Tab -->
              <div v-if="getTabComponent(index) === 'qr'">
                <CardAccessQR
                  :cardId="selectedCard.id"
                  :cardName="selectedCard.name"
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
import AdminCardIssuance from './AdminCardIssuance.vue'
import CardAccessQR from '@/components/CardComponents/CardAccessQR.vue'

const { t } = useI18n()
import MobilePreview from '@/components/CardComponents/MobilePreview.vue'

interface Card {
  id: string
  name: string
  description: string | null
  image_url: string | null
  original_image_url: string | null
  crop_parameters: any
  conversation_ai_enabled: boolean
  ai_instruction: string | null
  ai_knowledge_base: string | null
  qr_code_position: string
  content_mode?: 'solo' | 'stack' | 'catalog' | 'guide'
  billing_type?: 'physical' | 'digital'
  max_scans?: number | null
  current_scans?: number
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
  ai_metadata: string | null
}

interface Batch {
  id: string
  batch_name: string
  batch_number: number
  cards_count: number
  payment_status: string
  is_disabled: boolean
  created_at: string
}

interface Props {
  selectedCard: Card | null
  content: ContentItem[]
  batches: Batch[]
  isLoadingContent: boolean
  isLoadingBatches: boolean
  activeTab: string
}

const props = defineProps<Props>()

const emit = defineEmits<{
  (e: 'update:activeTab', value: string): void
}>()

// Tabs are dynamic based on billing_type (access mode)
const tabs = computed(() => {
  const baseTabs = [
    { label: t('dashboard.general'), icon: 'pi pi-info-circle' },
    { label: t('dashboard.content'), icon: 'pi pi-list' }
  ]
  
  // Physical cards have Issuance tab (for batch printing)
  if (props.selectedCard?.billing_type !== 'digital') {
    baseTabs.push({ label: t('dashboard.issuance'), icon: 'pi pi-box' })
  }
  
  // Both have QR & Access tab
  baseTabs.push({ label: t('dashboard.qr_access'), icon: 'pi pi-qrcode' })
  
  // Both have Preview tab
  baseTabs.push({ label: t('dashboard.preview'), icon: 'pi pi-mobile' })
  
  return baseTabs
})

// Map tab index to component type based on billing_type
const getTabComponent = (index: number): string | null => {
  const isDigital = props.selectedCard?.billing_type === 'digital'
  
  if (index === 0) return 'general'
  if (index === 1) return 'content'
  
  if (isDigital) {
    // Digital: [General, Content, QR, Preview]
    if (index === 2) return 'qr'
    if (index === 3) return 'preview'
  } else {
    // Physical: [General, Content, Issuance, QR, Preview]
    if (index === 2) return 'issuance'
    if (index === 3) return 'qr'
    if (index === 4) return 'preview'
  }
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

