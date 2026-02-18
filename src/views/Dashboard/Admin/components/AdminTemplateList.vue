<template>
  <div class="admin-template-list p-6">
    <!-- Header with Actions -->
    <div class="flex flex-col md:flex-row justify-between items-start md:items-center gap-4 mb-6">
      <div>
        <h2 class="text-xl font-bold text-slate-900">{{ $t('templates.admin.all_templates') }}</h2>
        <p class="text-slate-500 text-sm mt-1">{{ filteredTemplates.length }} {{ $t('templates.admin.templates') }}</p>
      </div>
      <div class="flex gap-2">
        <Button 
          icon="pi pi-refresh" 
          text 
          rounded 
          @click="fetchTemplates" 
          :loading="isLoading" 
          v-tooltip="$t('common.refresh')" 
        />
        <Button 
          :label="$t('templates.admin.import_excel')" 
          icon="pi pi-upload" 
          outlined
          @click="$emit('open-import')" 
        />
        <Button 
          :label="$t('templates.admin.export_all')" 
          icon="pi pi-download" 
          outlined
          @click="exportAllTemplates"
          :loading="isExporting"
          :disabled="filteredTemplates.length === 0"
        />
        <Button 
          :label="$t('templates.admin.create_template')" 
          icon="pi pi-plus" 
          @click="showCreateDialog = true" 
        />
      </div>
    </div>

    <!-- Bulk Action Bar (shows when templates are selected) -->
    <div v-if="selectedTemplates.length > 0" class="bg-blue-50 border border-blue-200 rounded-xl p-4 mb-6 flex flex-wrap items-center justify-between gap-4">
      <div class="flex items-center gap-3">
        <span class="text-blue-700 font-medium">
          {{ selectedTemplates.length }} {{ $t('templates.admin.selected') }}
        </span>
        <Button 
          :label="$t('common.clear_selection')" 
          text 
          size="small"
          @click="selectedTemplates = []" 
        />
      </div>
      <div class="flex flex-wrap gap-2">
        <Button 
          :label="$t('templates.admin.export_selected')" 
          icon="pi pi-download" 
          size="small"
          outlined
          @click="exportSelectedTemplates"
          :loading="isExporting"
        />
        <Button 
          :label="$t('templates.admin.activate_selected')" 
          icon="pi pi-eye" 
          size="small"
          severity="success"
          outlined
          @click="bulkActivate(true)"
          :loading="isBulkProcessing"
        />
        <Button 
          :label="$t('templates.admin.deactivate_selected')" 
          icon="pi pi-eye-slash" 
          size="small"
          severity="warning"
          outlined
          @click="bulkActivate(false)"
          :loading="isBulkProcessing"
        />
        <Button 
          :label="$t('templates.admin.feature_selected')" 
          icon="pi pi-star" 
          size="small"
          severity="info"
          outlined
          @click="bulkFeature(true)"
          :loading="isBulkProcessing"
        />
        <Button 
          :label="$t('templates.admin.unfeature_selected')" 
          icon="pi pi-star-fill" 
          size="small"
          severity="secondary"
          outlined
          @click="bulkFeature(false)"
          :loading="isBulkProcessing"
        />
        <Button 
          :label="$t('templates.admin.delete_selected')" 
          icon="pi pi-trash" 
          size="small"
          severity="danger"
          outlined
          @click="confirmBulkDelete"
          :loading="isBulkProcessing"
        />
      </div>
    </div>

    <!-- Filter Bar -->
    <div class="bg-slate-50 p-4 rounded-xl border border-slate-200 mb-6 flex flex-wrap gap-4 items-center">
      <!-- Search -->
      <IconField class="w-full sm:w-auto flex-1 sm:flex-none">
        <InputIcon class="pi pi-search" />
        <InputText v-model="searchQuery" :placeholder="$t('common.search')" class="w-full sm:w-64" />
      </IconField>

      <!-- Scenario Category -->
      <Select
        v-model="selectedScenarioCategory"
        :options="scenarioCategoryOptions"
        optionLabel="label"
        optionValue="value"
        :placeholder="$t('templates.admin.filter_by_type')"
        showClear
        class="w-full sm:w-48"
      >
        <template #option="slotProps">
           <div class="flex items-center gap-2">
             <i v-if="slotProps.option.icon" :class="slotProps.option.icon" class="text-slate-400"></i>
             <span>{{ slotProps.option.label }}</span>
           </div>
        </template>
      </Select>

      <!-- Status Filter -->
      <Select
        v-model="selectedStatus"
        :options="statusOptions"
        optionLabel="label"
        optionValue="value"
        :placeholder="$t('common.status')"
        showClear
        class="w-full sm:w-40"
      />

      <div class="ml-auto text-sm text-slate-500 hidden sm:block">
        {{ filteredTemplates.length }} {{ $t('templates.admin.templates') }}
      </div>
    </div>

    <!-- Loading -->
    <div v-if="isLoading" class="loading-state">
      <ProgressSpinner strokeWidth="4" />
    </div>

    <!-- Empty State -->
    <div v-else-if="filteredTemplates.length === 0" class="empty-state">
      <i class="pi pi-folder-open"></i>
      <h4>{{ $t('templates.admin.no_templates') }}</h4>
      <p>{{ searchQuery || selectedScenarioCategory || selectedStatus !== null ? $t('templates.admin.no_templates_for_filter') : $t('templates.admin.no_templates_desc') }}</p>
      <Button 
        v-if="!searchQuery && !selectedScenarioCategory && selectedStatus === null"
        :label="$t('templates.admin.create_first_template')"
        icon="pi pi-plus"
        class="mt-4 bg-blue-600 hover:bg-blue-700 text-white border-0"
        @click="showCreateDialog = true"
      />
      <Button 
        v-else
        :label="$t('common.clear_filters')"
        icon="pi pi-filter-slash"
        class="mt-4 p-button-outlined"
        @click="clearFilters"
      />
    </div>

    <!-- Templates Table with Selection & Drag -->
    <DataTable 
      v-else
      v-model:selection="selectedTemplates"
      :value="filteredTemplates" 
      :reorderableRows="canReorder"
      @row-reorder="onRowReorder"
      :paginator="filteredTemplates.length > 15"
      :rows="15"
      stripedRows
      class="templates-table"
      responsiveLayout="scroll"
      dataKey="id"
    >
      <!-- Selection Column -->
      <Column selectionMode="multiple" headerStyle="width: 3rem" :reorderableColumn="false"></Column>

      <!-- Drag Handle Column -->
      <Column :rowReorder="canReorder" headerStyle="width: 3rem" :reorderableColumn="false">
        <template #body>
          <i
            class="pi pi-bars"
            :class="canReorder ? 'text-slate-400 cursor-move' : 'text-slate-200 cursor-not-allowed'"
            v-tooltip="canReorder ? $t('templates.admin.drag_reorder_hint') : $t('templates.admin.drag_reorder_disabled_hint')"
          ></i>
        </template>
      </Column>

      <!-- Image Column (New) -->
      <Column :header="$t('dashboard.preview')" style="width: 100px">
        <template #body="{ data }">
           <div class="w-20 h-12 rounded overflow-hidden bg-slate-100 border border-slate-200 relative">
              <img v-if="data.thumbnail_url" :src="data.thumbnail_url" class="w-full h-full object-cover" />
              <div v-else class="w-full h-full flex items-center justify-center text-slate-300">
                <i class="pi pi-image text-xl"></i>
              </div>
           </div>
        </template>
      </Column>

      <!-- Name Column -->
      <Column field="name" :header="$t('templates.admin.name')" sortable style="min-width: 250px">
        <template #body="{ data }">
          <div class="template-name">
            <div class="flex items-center gap-2">
              <span class="name">{{ data.name }}</span>
              <i v-if="data.is_featured" class="pi pi-star-fill text-amber-500" v-tooltip="$t('templates.featured')"></i>
            </div>
            <span class="slug">{{ data.slug }}</span>
          </div>
        </template>
      </Column>
      
      <!-- Scenario Category Column -->
      <Column field="scenario_category" :header="$t('templates.admin.scenario_category')" sortable style="min-width: 140px">
        <template #body="{ data }">
          <div v-if="data.scenario_category" class="flex items-center gap-2">
            <i :class="getScenarioCategoryIcon(data.scenario_category)" class="text-slate-400 text-sm"></i>
            <span class="capitalize">{{ formatScenarioCategory(data.scenario_category) }}</span>
          </div>
          <span v-else class="text-slate-400">—</span>
        </template>
      </Column>
      
      <!-- Content Mode Column -->
      <Column field="content_mode" :header="$t('templates.admin.content_mode')" sortable style="min-width: 120px">
        <template #body="{ data }">
          <Tag :value="formatContentMode(data.content_mode)" :severity="getModeSeverity(data.content_mode)" />
        </template>
      </Column>
      
      <!-- Items Count Column -->
      <Column field="item_count" :header="$t('templates.admin.items')" sortable style="width: 100px">
        <template #body="{ data }">
          <div class="text-center">
             {{ data.item_count || 0 }}
          </div>
        </template>
      </Column>
      
      <!-- Import Count Column -->
      <Column field="import_count" :header="$t('templates.admin.imports')" sortable style="width: 100px">
        <template #body="{ data }">
          <div class="text-center">
            <span class="import-count">{{ data.import_count || 0 }}</span>
          </div>
        </template>
      </Column>
      
      <!-- Status Column -->
      <Column field="is_active" :header="$t('common.status')" style="width: 100px">
        <template #body="{ data }">
          <Tag 
            :value="data.is_active ? $t('common.active') : $t('common.inactive')"
            :severity="data.is_active ? 'success' : 'danger'"
          />
        </template>
      </Column>
      
      <!-- Actions Column (Revamped) -->
      <Column :header="$t('common.actions')" style="width: 100px" alignFrozen="right" frozen>
        <template #body="{ data }">
          <div class="flex justify-end">
            <Button icon="pi pi-ellipsis-v" text rounded @click="toggleMenu($event, data)" />
          </div>
        </template>
      </Column>
    </DataTable>

    <Menu ref="menu" :model="menuItems" :popup="true" />

    <!-- Delete Confirmation Dialog -->
    <ConfirmDialog />

    <!-- Create Template Dialog (link existing card) -->
    <Dialog 
      v-model:visible="showCreateDialog" 
      :header="$t('templates.admin.create_template')"
      :style="{ width: '90vw', maxWidth: '68rem' }"
      :modal="true"
      :contentStyle="{ overflow: 'visible' }"
    >
      <div class="space-y-6">
        <p class="text-sm text-slate-600">
          {{ $t('templates.admin.create_template_desc') }}
        </p>
        
        <!-- Select from admin's cards -->
        <div class="field">
          <label class="block text-sm font-medium text-slate-700 mb-1">
            {{ $t('templates.admin.select_card') }} *
            <span class="text-slate-400 font-normal ml-1">({{ adminCards.length }} total)</span>
          </label>
          <Select 
            v-model="createData.card_id" 
            :options="adminCards"
            optionLabel="card_name"
            optionValue="card_id"
            :optionDisabled="(opt) => !!opt.is_template"
            :placeholder="$t('templates.admin.select_card_placeholder')"
            :loading="loadingCards"
            class="w-full"
            filter
            filterPlaceholder="$t('templates.admin.search_cards')"
            emptyFilterMessage="$t('templates.admin.no_cards_match')"
            emptyMessage="$t('templates.admin.no_cards_available')"
            scrollHeight="300px"
            showClear
          >
            <template #option="{ option }">
              <div class="flex items-center justify-between w-full p-1 gap-3">
                <div class="flex items-center gap-2">
                  <span class="font-medium">{{ option.card_name || $t('templates.admin.unnamed_card') }}</span>
                  <Tag v-if="option.is_template" :value="$t('common.already_template')" severity="warning" class="text-xs" />
                </div>
                <span v-if="option.is_template && option.template_slug" class="text-xs text-slate-500 font-mono">
                  {{ option.template_slug }}
                </span>
              </div>
            </template>
            <template #value="slotProps">
              <span v-if="slotProps.value">
                {{ adminCards.find(c => c.card_id === slotProps.value)?.card_name || 'Selected' }}
              </span>
              <span v-else class="text-slate-400">{{ $t('templates.admin.select_card_placeholder') }}</span>
            </template>
          </Select>
        </div>
        
        <!-- Slug -->
        <div class="field">
          <label class="block text-sm font-medium text-slate-700 mb-1">
            {{ $t('templates.admin.slug') }} *
          </label>
          <div class="p-inputgroup">
            <span class="p-inputgroup-addon text-slate-500 bg-slate-50">templates/</span>
            <InputText 
              v-model="createData.slug" 
              class="w-full"
              placeholder="my-template-slug"
            />
          </div>
          <p class="text-xs text-slate-500 mt-1">
            {{ $t('templates.admin.slug_hint') }}
          </p>
        </div>
        
        <!-- Scenario Category -->
        <div class="field">
          <label class="block text-sm font-medium text-slate-700 mb-1">
            {{ $t('templates.admin.scenario_category') }}
          </label>
          <Select
            v-model="createData.scenario_category"
            :options="scenarioCategoryOptions.filter(v => v.value)"
            optionLabel="label"
            optionValue="value"
            :placeholder="$t('templates.admin.select_scenario_category')"
            showClear
            class="w-full"
          >
             <template #option="slotProps">
              <div class="flex items-center gap-2">
                <i v-if="slotProps.option.icon" :class="slotProps.option.icon" class="text-slate-400"></i>
                <span>{{ slotProps.option.label }}</span>
              </div>
            </template>
            <template #value="slotProps">
               <div v-if="slotProps.value" class="flex items-center gap-2">
                <i v-if="getScenarioCategoryIcon(slotProps.value)" :class="getScenarioCategoryIcon(slotProps.value)" class="text-slate-500"></i>
                <span>{{ getScenarioCategoryLabel(slotProps.value) }}</span>
              </div>
              <span v-else class="text-slate-400">{{ $t('templates.admin.select_scenario_category') }}</span>
            </template>
          </Select>
        </div>
        
        <!-- Options -->
        <div class="flex gap-6 p-4 bg-slate-50 rounded-lg">
          <div class="flex items-center gap-2">
            <Checkbox v-model="createData.is_featured" :binary="true" inputId="create_featured" />
            <label for="create_featured" class="text-sm cursor-pointer font-medium text-slate-700">{{ $t('templates.admin.is_featured') }}</label>
          </div>
        </div>
      </div>
      
      <template #footer>
        <Button :label="$t('common.cancel')" text @click="showCreateDialog = false" />
        <Button 
          :label="$t('templates.admin.create_template')"
          icon="pi pi-plus"
          @click="handleCreateTemplate"
          :disabled="!createData.card_id || !createData.slug || isSelectedCardAlreadyTemplate"
          :loading="isCreating"
          class="bg-blue-600 hover:bg-blue-700 text-white border-0"
        />
      </template>
    </Dialog>

    <!-- Edit Settings Dialog -->
    <Dialog 
      v-model:visible="showSettingsDialog" 
      :header="$t('templates.admin.edit_settings')"
      :style="{ width: '90vw', maxWidth: '52rem' }"
      :modal="true"
    >
      <div class="space-y-4">
        <!-- Slug -->
        <div class="field">
          <label class="block text-sm font-medium text-slate-700 mb-1">
            {{ $t('templates.admin.slug') }}
          </label>
          <div class="p-inputgroup">
            <span class="p-inputgroup-addon text-slate-500 bg-slate-50">templates/</span>
            <InputText 
              v-model="editSettings.slug" 
              class="w-full"
            />
          </div>
        </div>
        
        <!-- Scenario Category -->
        <div class="field">
          <label class="block text-sm font-medium text-slate-700 mb-1">
            {{ $t('templates.admin.scenario_category') }}
          </label>
          <Select
            v-model="editSettings.scenario_category"
            :options="scenarioCategoryOptions.filter(v => v.value)"
            optionLabel="label"
            optionValue="value"
            :placeholder="$t('templates.admin.select_scenario_category')"
            showClear
            class="w-full"
          >
             <template #option="slotProps">
              <div class="flex items-center gap-2">
                <i v-if="slotProps.option.icon" :class="slotProps.option.icon" class="text-slate-400"></i>
                <span>{{ slotProps.option.label }}</span>
              </div>
            </template>
            <template #value="slotProps">
               <div v-if="slotProps.value" class="flex items-center gap-2">
                <i v-if="getScenarioCategoryIcon(slotProps.value)" :class="getScenarioCategoryIcon(slotProps.value)" class="text-slate-500"></i>
                <span>{{ getScenarioCategoryLabel(slotProps.value) }}</span>
              </div>
              <span v-else class="text-slate-400">{{ $t('templates.admin.select_scenario_category') }}</span>
            </template>
          </Select>
        </div>
        
        <!-- Options -->
        <div class="flex gap-6 p-4 bg-slate-50 rounded-lg">
          <div class="flex items-center gap-2">
            <Checkbox v-model="editSettings.is_featured" :binary="true" inputId="edit_featured" />
            <label for="edit_featured" class="text-sm cursor-pointer font-medium text-slate-700">{{ $t('templates.admin.is_featured') }}</label>
          </div>
          <div class="flex items-center gap-2">
            <Checkbox v-model="editSettings.is_active" :binary="true" inputId="edit_active" />
            <label for="edit_active" class="text-sm cursor-pointer font-medium text-slate-700">{{ $t('templates.admin.is_active') }}</label>
          </div>
        </div>
        
        <div class="p-3 bg-blue-50 rounded-lg border border-blue-100">
          <p class="text-sm text-blue-700 flex items-start gap-2">
            <i class="pi pi-info-circle mt-0.5"></i>
            <span>{{ $t('templates.admin.edit_card_hint') }}</span>
          </p>
        </div>
      </div>
      
      <template #footer>
        <Button :label="$t('common.cancel')" text @click="showSettingsDialog = false" />
        <Button 
          :label="$t('common.save')"
          icon="pi pi-check"
          @click="handleSaveSettings"
          :loading="isSavingSettings"
          class="bg-blue-600 hover:bg-blue-700 text-white border-0"
        />
      </template>
    </Dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useI18n } from 'vue-i18n'
import { useRouter } from 'vue-router'
import { useConfirm } from 'primevue/useconfirm'
import { useToast } from 'primevue/usetoast'
import { useTemplateLibraryStore, type AdminContentTemplate } from '@/stores/templateLibrary'
import { supabase } from '@/lib/supabase'
import { exportProject, exportMultipleProjects } from '@/utils/projectArchive'
import { storeToRefs } from 'pinia'

import Button from 'primevue/button'
import DataTable from 'primevue/datatable'
import Column from 'primevue/column'
import Tag from 'primevue/tag'
import Select from 'primevue/select'
import ProgressSpinner from 'primevue/progressspinner'
import ConfirmDialog from 'primevue/confirmdialog'
import Dialog from 'primevue/dialog'
import Checkbox from 'primevue/checkbox'
import InputText from 'primevue/inputtext'
import IconField from 'primevue/iconfield'
import InputIcon from 'primevue/inputicon'
import Menu from 'primevue/menu'

const emit = defineEmits<{
  (e: 'open-import'): void
}>()

const { t } = useI18n()
const router = useRouter()
const confirm = useConfirm()
const toast = useToast()
const templateStore = useTemplateLibraryStore()
const { adminTemplates: templates, adminCards, isLoading } = storeToRefs(templateStore)

// Filter state
const selectedScenarioCategory = ref<string | null>(null)
const selectedStatus = ref<boolean | null>(null) // null = all, true = active, false = inactive
const searchQuery = ref<string>('')
const canReorder = computed(() => !selectedScenarioCategory.value && !searchQuery.value && selectedStatus.value === null)

// Action Menu state
const menu = ref()
const activeTemplate = ref<AdminContentTemplate | null>(null)
const menuItems = computed(() => [
  {
    label: 'Actions',
    items: [
      {
        label: t('templates.admin.edit_card'),
        icon: 'pi pi-external-link',
        command: () => {
          if (activeTemplate.value) openCardEditor(activeTemplate.value)
        }
      },
      {
        label: t('templates.admin.edit_settings'),
        icon: 'pi pi-cog',
        command: () => {
          if (activeTemplate.value) openSettingsDialog(activeTemplate.value)
        }
      },
      {
        label: t('templates.admin.export_template'),
        icon: 'pi pi-download',
        command: () => {
          if (activeTemplate.value) exportTemplate(activeTemplate.value)
        }
      },
      {
        separator: true
      },
      {
        label: activeTemplate.value?.is_featured ? t('templates.admin.unfeature') : t('templates.admin.feature'),
        icon: activeTemplate.value?.is_featured ? 'pi pi-star-fill' : 'pi pi-star',
        command: () => {
          if (activeTemplate.value) toggleFeatured(activeTemplate.value)
        }
      },
      {
        label: activeTemplate.value?.is_active ? t('templates.admin.deactivate') : t('templates.admin.activate'),
        icon: activeTemplate.value?.is_active ? 'pi pi-eye-slash' : 'pi pi-eye',
        command: () => {
          if (activeTemplate.value) toggleStatus(activeTemplate.value)
        }
      },
      {
        separator: true
      },
      {
        label: t('common.delete'),
        icon: 'pi pi-trash',
        class: 'text-red-600',
        command: () => {
          if (activeTemplate.value) confirmDelete(activeTemplate.value)
        }
      }
    ]
  }
])

function toggleMenu(event: Event, template: AdminContentTemplate) {
  activeTemplate.value = template
  menu.value.toggle(event)
}

// Create dialog state
const showCreateDialog = ref(false)
const loadingCards = ref(false)
const isCreating = ref(false)
const createData = ref({
  card_id: null as string | null,
  slug: '',
  scenario_category: null as string | null,
  is_featured: false
})

// Settings dialog state
const showSettingsDialog = ref(false)
const isSavingSettings = ref(false)
const isExporting = ref(false)
const isBulkProcessing = ref(false)
const selectedTemplates = ref<AdminContentTemplate[]>([])
const editSettings = ref({
  template_id: '',
  card_id: '',
  slug: '',
  scenario_category: null as string | null,
  is_featured: false,
  is_active: true
})

const isSelectedCardAlreadyTemplate = computed(() => {
  if (!createData.value.card_id) return false
  return !!adminCards.value.find(c => c.card_id === createData.value.card_id)?.is_template
})

// Scenario category options with icons (consolidated categories)
const scenarioCategoryOptions = computed(() => [
  { label: t('templates.admin.all_types'), value: null, icon: 'pi pi-th-large' },
  { label: t('templates.admin.cultural'), value: 'cultural', icon: 'pi pi-building' },
  { label: t('templates.admin.food'), value: 'food', icon: 'pi pi-star' },
  { label: t('templates.admin.events'), value: 'events', icon: 'pi pi-calendar' },
  { label: t('templates.admin.hospitality'), value: 'hospitality', icon: 'pi pi-heart' },
  { label: t('templates.admin.retail'), value: 'retail', icon: 'pi pi-shopping-bag' },
  { label: t('templates.admin.tours'), value: 'tours', icon: 'pi pi-map' },
  { label: t('templates.admin.general'), value: 'general', icon: 'pi pi-box' }
])

const statusOptions = computed(() => [
  { label: t('templates.admin.all_statuses'), value: null },
  { label: t('common.active'), value: true },
  { label: t('common.inactive'), value: false }
])

// Filtered templates
const filteredTemplates = computed(() => {
  let result = templates.value

  // Scenario Category Filter
  if (selectedScenarioCategory.value) {
    result = result.filter(t => t.scenario_category === selectedScenarioCategory.value)
  }

  // Status Filter
  if (selectedStatus.value !== null) {
    result = result.filter(t => t.is_active === selectedStatus.value)
  }

  // Search Filter
  if (searchQuery.value) {
    const query = searchQuery.value.toLowerCase()
    result = result.filter(t => 
      t.name.toLowerCase().includes(query) || 
      t.slug.toLowerCase().includes(query)
    )
  }

  return result
})

// Fetch templates and cards on mount
onMounted(async () => {
  await fetchTemplates()
  await fetchAdminCards()
})

async function fetchTemplates() {
  await templateStore.adminFetchAllTemplates()
}

async function fetchAdminCards() {
  loadingCards.value = true
  try {
    await templateStore.adminFetchCards()
  } finally {
    loadingCards.value = false
  }
}

function clearFilters() {
  selectedScenarioCategory.value = null
  selectedStatus.value = null
  searchQuery.value = ''
}

function formatScenarioCategory(type: string): string {
  if (!type) return ''
  const option = scenarioCategoryOptions.value.find(v => v.value === type)
  return option ? option.label : type.charAt(0).toUpperCase() + type.slice(1).replace(/_/g, ' ')
}

function getScenarioCategoryIcon(value: string): string {
  if (!value) return ''
  const option = scenarioCategoryOptions.value.find(v => v.value === value)
  return option ? option.icon : 'pi pi-box'
}

function getScenarioCategoryLabel(value: string): string {
  if (!value) return ''
  return scenarioCategoryOptions.value.find(o => o.value === value)?.label || value
}

function formatContentMode(mode: string): string {
  if (!mode) return t('dashboard.mode_list')
  const map: Record<string, string> = {
    'single': t('dashboard.mode_single'),
    'grouped': t('dashboard.is_grouped'),
    'list': t('dashboard.mode_list'),
    'grid': t('dashboard.mode_grid'),
    'inline': t('dashboard.mode_cards'),
    'cards': t('dashboard.mode_cards') // Legacy alias
  }
  return map[mode] || mode.charAt(0).toUpperCase() + mode.slice(1)
}

function getModeSeverity(mode: string): string {
  const severities: Record<string, string> = {
    single: 'success', // Green
    list: 'info',      // Blue
    grid: 'warning',   // Orange
    grouped: 'help',   // Purple
    inline: 'secondary', // Grey
    cards: 'secondary'  // Legacy alias
  }
  return severities[mode] || 'secondary'
}

// Open card editor in MyCards page
function openCardEditor(template: AdminContentTemplate) {
  // Navigate to MyCards page and select this card
  router.push({
    name: 'projects',
    query: { cardId: template.card_id }
  })
}

// Open settings dialog
function openSettingsDialog(template: AdminContentTemplate) {
  editSettings.value = {
    template_id: template.id,
    card_id: template.card_id,
    slug: template.slug,
    scenario_category: template.scenario_category,
    is_featured: template.is_featured,
    is_active: template.is_active
  }
  showSettingsDialog.value = true
}

// Create template from card
async function handleCreateTemplate() {
  if (!createData.value.card_id || !createData.value.slug) return
  
  isCreating.value = true
  try {
    const result = await templateStore.createTemplateFromCard(
      createData.value.card_id,
      createData.value.slug,
      createData.value.scenario_category,
      createData.value.is_featured,
      templates.value.length // Add at end
    )
    
    if (result.success) {
      toast.add({
        severity: 'success',
        summary: t('templates.admin.template_created'),
        life: 3000
      })
      showCreateDialog.value = false
      createData.value = { card_id: null, slug: '', scenario_category: null, is_featured: false }
      await fetchAdminCards() // Refresh available cards
    } else {
      toast.add({
        severity: 'error',
        summary: t('common.error'),
        detail: result.message,
        life: 5000
      })
    }
  } finally {
    isCreating.value = false
  }
}

// Save template settings
async function handleSaveSettings() {
  isSavingSettings.value = true
  try {
    const result = await templateStore.updateTemplateSettings(editSettings.value.template_id, {
      slug: editSettings.value.slug,
      scenario_category: editSettings.value.scenario_category,
      is_featured: editSettings.value.is_featured,
      is_active: editSettings.value.is_active
    })
    
    if (result.success) {
      toast.add({
        severity: 'success',
        summary: t('templates.admin.template_updated'),
        life: 3000
      })
      showSettingsDialog.value = false
    } else {
      toast.add({
        severity: 'error',
        summary: t('common.error'),
        detail: result.message,
        life: 5000
      })
    }
  } finally {
    isSavingSettings.value = false
  }
}

// Handle row reorder (drag & drop)
async function onRowReorder(event: any) {
  if (!canReorder.value) {
    toast.add({
      severity: 'warn',
      summary: t('templates.admin.drag_reorder_disabled_title'),
      detail: t('templates.admin.drag_reorder_disabled_hint'),
      life: 3500
    })
    return
  }
  const reorderedTemplates = event.value as AdminContentTemplate[]
  
  const updates = reorderedTemplates.map((template, index) => ({
    id: template.id,
    sort_order: index
  }))
  
  // Update local state immediately
  templates.value = reorderedTemplates.map((t, i) => ({ ...t, sort_order: i }))
  
  try {
    const result = await templateStore.batchUpdateOrder(updates)
    
    if (result.success) {
      toast.add({
        severity: 'success',
        summary: t('templates.admin.order_updated'),
        life: 2000
      })
    } else {
      throw new Error(result.message)
    }
  } catch (error: any) {
    toast.add({
      severity: 'error',
      summary: t('common.error'),
      detail: error.message,
      life: 5000
    })
    await fetchTemplates()
  }
}

// Toggle featured status
async function toggleFeatured(template: AdminContentTemplate) {
  const result = await templateStore.updateTemplateSettings(template.id, {
    is_featured: !template.is_featured
  })
  
  if (result.success) {
    toast.add({
      severity: 'success',
      summary: template.is_featured ? t('templates.admin.unfeatured') : t('templates.admin.featured_success'),
      life: 3000
    })
  } else {
    toast.add({
      severity: 'error',
      summary: t('common.error'),
      detail: result.message,
      life: 5000
    })
  }
}

// Toggle active status
async function toggleStatus(template: AdminContentTemplate) {
  const result = await templateStore.toggleTemplateStatus(template.id, !template.is_active)
  if (result.success) {
    toast.add({
      severity: 'success',
      summary: result.message,
      life: 3000
    })
  } else {
    toast.add({
      severity: 'error',
      summary: t('common.error'),
      detail: result.message,
      life: 5000
    })
  }
}

// Confirm delete
function confirmDelete(template: AdminContentTemplate) {
  confirm.require({
    message: t('templates.admin.delete_confirm', { name: template.name }),
    header: t('templates.admin.delete_template'),
    icon: 'pi pi-exclamation-triangle',
    acceptClass: 'p-button-danger',
    accept: async () => {
      const result = await templateStore.deleteTemplate(template.id, false)
      if (result.success) {
        toast.add({
          severity: 'success',
          summary: result.message,
          life: 3000
        })
        await fetchAdminCards()
      } else {
        toast.add({
          severity: 'error',
          summary: t('common.error'),
          detail: result.message,
          life: 5000
        })
      }
    }
  })
}

// Export single template
async function exportTemplate(template: AdminContentTemplate) {
  isExporting.value = true
  try {
    // Fetch full template details including content items
    const { data: templateData, error: templateError } = await supabase.rpc('get_content_template', {
      p_template_id: template.id,
      p_slug: null
    })

    if (templateError) throw templateError
    if (!templateData || templateData.length === 0) throw new Error('Template not found')

    const fullTemplate = templateData[0]

    // Export as ZIP using projectArchive
    const { blob } = await exportProject(fullTemplate, fullTemplate.content_items || [])

    // Download file
    const url = URL.createObjectURL(blob)
    const link = document.createElement('a')
    link.href = url
    link.download = `template_${template.slug}_${new Date().toISOString().split('T')[0]}.zip`
    link.click()
    URL.revokeObjectURL(url)

    toast.add({
      severity: 'success',
      summary: t('templates.admin.export_success'),
      life: 3000
    })
  } catch (error: any) {
    console.error('Export error:', error)
    toast.add({
      severity: 'error',
      summary: t('common.error'),
      detail: error.message || t('templates.admin.export_failed'),
      life: 5000
    })
  } finally {
    isExporting.value = false
  }
}

// Export all filtered templates
async function exportAllTemplates() {
  if (filteredTemplates.value.length === 0) return

  isExporting.value = true
  try {
    // Build projects array for multi-project export
    const projects: Array<{ card: Record<string, unknown>; contentItems: Record<string, unknown>[] }> = []

    for (const template of filteredTemplates.value) {
      const { data: templateData } = await supabase.rpc('get_content_template', {
        p_template_id: template.id,
        p_slug: null
      })

      if (templateData && templateData.length > 0) {
        const fullTemplate = templateData[0]
        projects.push({
          card: fullTemplate,
          contentItems: fullTemplate.content_items || []
        })
      }
    }

    // Export as combined ZIP
    const blob = await exportMultipleProjects(projects)

    // Download file
    const url = URL.createObjectURL(blob)
    const link = document.createElement('a')
    link.href = url
    link.download = `templates_export_${new Date().toISOString().split('T')[0]}.zip`
    link.click()
    URL.revokeObjectURL(url)

    toast.add({
      severity: 'success',
      summary: t('templates.admin.export_success'),
      detail: `${filteredTemplates.value.length} ${t('templates.admin.templates')} exported`,
      life: 3000
    })
  } catch (error: any) {
    console.error('Export error:', error)
    toast.add({
      severity: 'error',
      summary: t('common.error'),
      detail: error.message || t('templates.admin.export_failed'),
      life: 5000
    })
  } finally {
    isExporting.value = false
  }
}

// Export selected templates
async function exportSelectedTemplates() {
  if (selectedTemplates.value.length === 0) return

  isExporting.value = true
  try {
    // Build projects array for multi-project export
    const projects: Array<{ card: Record<string, unknown>; contentItems: Record<string, unknown>[] }> = []

    for (const template of selectedTemplates.value) {
      const { data: templateData } = await supabase.rpc('get_content_template', {
        p_template_id: template.id,
        p_slug: null
      })

      if (templateData && templateData.length > 0) {
        const fullTemplate = templateData[0]
        projects.push({
          card: fullTemplate,
          contentItems: fullTemplate.content_items || []
        })
      }
    }

    // Export as combined ZIP
    const blob = await exportMultipleProjects(projects)

    // Download file
    const url = URL.createObjectURL(blob)
    const link = document.createElement('a')
    link.href = url
    link.download = `templates_selected_${new Date().toISOString().split('T')[0]}.zip`
    link.click()
    URL.revokeObjectURL(url)

    toast.add({
      severity: 'success',
      summary: t('templates.admin.export_success'),
      detail: `${selectedTemplates.value.length} ${t('templates.admin.templates')} exported`,
      life: 3000
    })
    selectedTemplates.value = []
  } catch (error: any) {
    console.error('Export error:', error)
    toast.add({
      severity: 'error',
      summary: t('common.error'),
      detail: error.message || t('templates.admin.export_failed'),
      life: 5000
    })
  } finally {
    isExporting.value = false
  }
}

// Bulk activate/deactivate selected templates
async function bulkActivate(activate: boolean) {
  if (selectedTemplates.value.length === 0) return
  
  isBulkProcessing.value = true
  let successCount = 0
  let failCount = 0
  
  try {
    for (const template of selectedTemplates.value) {
      const result = await templateStore.toggleTemplateStatus(template.id, activate)
      if (result.success) {
        successCount++
      } else {
        failCount++
      }
    }
    
    if (successCount > 0) {
      toast.add({
        severity: 'success',
        summary: activate ? t('templates.admin.bulk_activated') : t('templates.admin.bulk_deactivated'),
        detail: `${successCount} ${t('templates.admin.templates')} ${activate ? 'activated' : 'deactivated'}`,
        life: 3000
      })
    }
    
    if (failCount > 0) {
      toast.add({
        severity: 'warn',
        summary: t('common.partial_success'),
        detail: `${failCount} ${t('templates.admin.templates')} failed`,
        life: 5000
      })
    }
    
    selectedTemplates.value = []
  } catch (error: any) {
    toast.add({
      severity: 'error',
      summary: t('common.error'),
      detail: error.message,
      life: 5000
    })
  } finally {
    isBulkProcessing.value = false
  }
}

// Bulk feature/unfeature selected templates
async function bulkFeature(feature: boolean) {
  if (selectedTemplates.value.length === 0) return
  
  isBulkProcessing.value = true
  let successCount = 0
  let failCount = 0
  
  try {
    for (const template of selectedTemplates.value) {
      const result = await templateStore.updateTemplateSettings(template.id, {
        is_featured: feature
      })
      if (result.success) {
        successCount++
      } else {
        failCount++
      }
    }
    
    if (successCount > 0) {
      toast.add({
        severity: 'success',
        summary: feature ? t('templates.admin.bulk_featured') : t('templates.admin.bulk_unfeatured'),
        detail: `${successCount} ${t('templates.admin.templates')} ${feature ? 'featured' : 'unfeatured'}`,
        life: 3000
      })
    }
    
    if (failCount > 0) {
      toast.add({
        severity: 'warn',
        summary: t('common.partial_success'),
        detail: `${failCount} ${t('templates.admin.templates')} failed`,
        life: 5000
      })
    }
    
    selectedTemplates.value = []
  } catch (error: any) {
    toast.add({
      severity: 'error',
      summary: t('common.error'),
      detail: error.message,
      life: 5000
    })
  } finally {
    isBulkProcessing.value = false
  }
}

// Confirm bulk delete
function confirmBulkDelete() {
  confirm.require({
    message: t('templates.admin.bulk_delete_confirm', { count: selectedTemplates.value.length }),
    header: t('templates.admin.delete_templates'),
    icon: 'pi pi-exclamation-triangle',
    acceptClass: 'p-button-danger',
    accept: async () => {
      await bulkDelete()
    }
  })
}

// Bulk delete selected templates
async function bulkDelete() {
  if (selectedTemplates.value.length === 0) return
  
  isBulkProcessing.value = true
  let successCount = 0
  let failCount = 0
  
  try {
    for (const template of selectedTemplates.value) {
      const result = await templateStore.deleteTemplate(template.id, false)
      if (result.success) {
        successCount++
      } else {
        failCount++
      }
    }
    
    if (successCount > 0) {
      toast.add({
        severity: 'success',
        summary: t('templates.admin.bulk_deleted'),
        detail: `${successCount} ${t('templates.admin.templates')} deleted`,
        life: 3000
      })
      await fetchAdminCards()
    }
    
    if (failCount > 0) {
      toast.add({
        severity: 'warn',
        summary: t('common.partial_success'),
        detail: `${failCount} ${t('templates.admin.templates')} failed to delete`,
        life: 5000
      })
    }
    
    selectedTemplates.value = []
  } catch (error: any) {
    toast.add({
      severity: 'error',
      summary: t('common.error'),
      detail: error.message,
      life: 5000
    })
  } finally {
    isBulkProcessing.value = false
  }
}

</script>

<style scoped>
.admin-template-list {
  @apply space-y-4;
}


.loading-state {
  @apply flex items-center justify-center py-12;
}

.empty-state {
  @apply text-center py-12 bg-white rounded-lg border border-slate-200;
}

.empty-state i {
  @apply text-4xl text-slate-300 mb-4;
}

.empty-state h4 {
  @apply font-semibold text-slate-700 mb-2;
}

.empty-state p {
  @apply text-sm text-slate-500;
}

.templates-table {
  @apply border border-slate-200 rounded-lg overflow-hidden;
}

.template-name {
  @apply flex flex-col;
}

.template-name .name {
  @apply font-medium text-slate-900;
}

.template-name .slug {
  @apply text-xs text-slate-500 font-mono;
}

.import-count {
  @apply font-medium text-blue-600 bg-blue-50 px-2 py-1 rounded-full text-xs;
}

</style>
