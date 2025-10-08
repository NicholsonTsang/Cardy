<template>
  <PageWrapper :title="$t('admin.user_management')" :description="$t('admin.view_manage_users')">
    <template #actions>
      <Button 
        icon="pi pi-refresh" 
        :label="$t('admin.refresh_data')" 
        severity="secondary"
        outlined
        @click="refreshData"
        :loading="isLoading"
      />
      <Button 
        icon="pi pi-download" 
        :label="$t('admin.export_csv')" 
        severity="secondary"
        outlined
        @click="exportUsers"
      />
    </template>

    <div class="space-y-6">
      <!-- Statistics Cards -->
      <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
        <div class="bg-white rounded-xl shadow-soft border border-slate-200 p-6 hover:shadow-medium transition-shadow duration-200">
          <div class="flex items-center justify-between">
            <div>
              <h3 class="text-sm font-medium text-slate-600 mb-2">{{ $t('admin.total_users') }}</h3>
              <p class="text-3xl font-bold text-slate-900">{{ userStats.total }}</p>
            </div>
            <div class="p-4 bg-gradient-to-r from-blue-500 to-indigo-500 rounded-xl">
              <i class="pi pi-users text-white text-2xl"></i>
            </div>
          </div>
        </div>

        <div class="bg-white rounded-xl shadow-soft border border-slate-200 p-6 hover:shadow-medium transition-shadow duration-200">
          <div class="flex items-center justify-between">
            <div>
              <h3 class="text-sm font-medium text-slate-600 mb-2">{{ $t('admin.card_issuers') || 'Card Issuers' }}</h3>
              <p class="text-3xl font-bold text-slate-900">{{ userStats.cardIssuers }}</p>
            </div>
            <div class="p-4 bg-gradient-to-r from-green-500 to-green-600 rounded-xl">
              <i class="pi pi-id-card text-white text-2xl"></i>
            </div>
          </div>
        </div>

        <div class="bg-white rounded-xl shadow-soft border border-slate-200 p-6 hover:shadow-medium transition-shadow duration-200">
          <div class="flex items-center justify-between">
            <div>
              <h3 class="text-sm font-medium text-slate-600 mb-2">{{ $t('admin.admins') || 'Admins' }}</h3>
              <p class="text-3xl font-bold text-slate-900">{{ userStats.admins }}</p>
            </div>
            <div class="p-4 bg-gradient-to-r from-purple-500 to-violet-500 rounded-xl">
              <i class="pi pi-shield text-white text-2xl"></i>
            </div>
          </div>
        </div>
      </div>

      <!-- Filters and Search -->
      <div class="bg-white rounded-xl shadow-soft border border-slate-200 p-6">
        <h3 class="text-lg font-semibold text-slate-900 mb-4">{{ $t('admin.filters_search') || 'Filters & Search' }}</h3>
        <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
          <div class="md:col-span-2">
            <IconField>
              <InputIcon class="pi pi-search" />
              <InputText 
                v-model="searchQuery"
                :placeholder="$t('admin.search_by_email')"
                class="w-full"
                @input="filterUsers"
              />
            </IconField>
          </div>
          <div>
            <Select 
              v-model="selectedRole"
              :options="roleOptions"
              optionLabel="label"
              optionValue="value"
              :placeholder="$t('admin.filter_by_role') || 'Filter by Role'"
              class="w-full"
              @change="filterUsers"
              showClear
            />
          </div>
        </div>
        <div v-if="hasActiveFilters" class="mt-4 flex items-center justify-between">
          <span class="text-sm text-slate-600">
            {{ filteredUsers.length }} {{ $t('admin.of') || 'of' }} {{ allUsers.length }} {{ $t('admin.users_shown') || 'users shown' }}
          </span>
          <Button 
            :label="$t('admin.clear_filters')" 
            size="small"
            text
            severity="secondary"
            @click="clearFilters"
          />
        </div>
      </div>

      <!-- Users Table -->
      <div class="bg-white rounded-xl shadow-soft border border-slate-200 overflow-hidden">
        <DataTable 
          :value="paginatedUsers"
          :loading="isLoading"
          showGridlines
          :paginator="true"
          :rows="pageSize"
          :totalRecords="filteredUsers.length"
          :lazy="false"
          @page="onPageChange"
          paginatorTemplate="FirstPageLink PrevPageLink PageLinks NextPageLink LastPageLink CurrentPageReport RowsPerPageDropdown"
          :rowsPerPageOptions="[10, 20, 50, 100]"
          :currentPageReportTemplate="$t('admin.current_page_report') || 'Showing {first} to {last} of {totalRecords} users'"
          class="users-table"
          responsiveLayout="scroll"
          :scrollable="true"
          scrollHeight="flex"
        >
          <Column field="user_email" :header="$t('admin.user_email')" sortable :style="{ width: '280px', minWidth: '250px' }" frozen>
            <template #body="{ data }">
              <div class="flex items-center gap-2">
                <div class="w-8 h-8 bg-gradient-to-r from-blue-500 to-indigo-500 rounded-full flex items-center justify-center text-white text-xs font-medium flex-shrink-0">
                  {{ data.user_email.charAt(0).toUpperCase() }}
                </div>
                <span class="font-medium text-slate-900 truncate">{{ data.user_email }}</span>
              </div>
            </template>
          </Column>

          <Column field="role" :header="$t('admin.user_role')" sortable :style="{ width: '140px', minWidth: '140px' }">
            <template #body="{ data }">
              <Tag 
                :value="getRoleLabel(data.role)"
                :severity="getRoleSeverity(data.role)"
                class="whitespace-nowrap"
              />
            </template>
          </Column>

          <Column field="cards_count" :header="$t('batches.cards')" sortable :style="{ width: '100px', minWidth: '100px' }" class="text-center">
            <template #body="{ data }">
              <div class="text-center">
                <span class="inline-flex items-center justify-center px-2 py-1 text-xs font-semibold rounded-full bg-blue-100 text-blue-800">
                  {{ data.cards_count || 0 }}
                </span>
              </div>
            </template>
          </Column>

          <Column field="issued_cards_count" :header="$t('admin.issued') || 'Issued'" sortable :style="{ width: '100px', minWidth: '100px' }" class="text-center">
            <template #body="{ data }">
              <div class="text-center">
                <span class="inline-flex items-center justify-center px-2 py-1 text-xs font-semibold rounded-full bg-green-100 text-green-800">
                  {{ data.issued_cards_count || 0 }}
                </span>
              </div>
            </template>
          </Column>

          <Column field="created_at" :header="$t('admin.registered') || 'Registered'" sortable :style="{ width: '140px', minWidth: '140px' }">
            <template #body="{ data }">
              <span class="text-slate-600 text-xs whitespace-nowrap">{{ formatDate(data.created_at) }}</span>
            </template>
          </Column>

          <Column field="last_sign_in_at" :header="$t('admin.last_sign_in') || 'Last Sign In'" sortable :style="{ width: '140px', minWidth: '140px' }">
            <template #body="{ data }">
              <span class="text-slate-600 text-xs whitespace-nowrap">
                {{ data.last_sign_in_at ? formatDate(data.last_sign_in_at) : ($t('admin.never') || 'Never') }}
              </span>
            </template>
          </Column>

          <Column :header="$t('common.actions')" :style="{ width: '100px', minWidth: '100px' }" frozen alignFrozen="right" class="text-center">
            <template #body="{ data }">
              <div class="flex items-center justify-center gap-2">
                <Button 
                  icon="pi pi-cog"
                  size="small"
                  outlined
                  severity="secondary"
                  @click="manageUserRole(data)"
                  v-tooltip.top="$t('admin.manage_role')"
                />
              </div>
            </template>
          </Column>
        </DataTable>
      </div>

      <!-- Role Management Dialog -->
      <Dialog 
        v-model:visible="showRoleDialog"
        modal
        :header="$t('admin.manage_user_role') || 'Manage User Role'"
        :style="{ width: '90vw', maxWidth: '500px' }"
        @hide="closeRoleDialog"
      >
        <div v-if="selectedUser" class="space-y-4">
          <div>
            <label class="block text-sm font-medium text-slate-700 mb-2">{{ $t('admin.user') || 'User' }}</label>
            <div class="p-3 bg-slate-50 rounded-lg">
              <p class="font-medium text-slate-900">{{ selectedUser.user_email }}</p>
              <p class="text-sm text-slate-600">{{ $t('admin.current_role') || 'Current Role' }}: {{ getRoleLabel(selectedUser.role) }}</p>
            </div>
          </div>

          <div>
            <label for="newRole" class="block text-sm font-medium text-slate-700 mb-2">
              {{ $t('admin.new_role') || 'New Role' }} <span class="text-red-500">*</span>
            </label>
            <Select 
              id="newRole"
              v-model="newUserRole"
              :options="roleChangeOptions"
              optionLabel="label"
              optionValue="value"
              :placeholder="$t('admin.select_new_role') || 'Select new role'"
              class="w-full"
            />
          </div>

          <div>
            <label for="reason" class="block text-sm font-medium text-slate-700 mb-2">
              {{ $t('admin.reason_for_change') || 'Reason for Change' }} <span class="text-red-500">*</span>
            </label>
            <Textarea 
              id="reason"
              v-model="roleChangeReason"
              rows="3"
              :placeholder="$t('admin.reason_placeholder') || 'Explain why this role change is necessary...'"
              class="w-full"
            />
          </div>
        </div>

        <template #footer>
          <Button :label="$t('common.cancel')" text severity="secondary" @click="closeRoleDialog" />
          <Button 
            :label="$t('admin.update_role') || 'Update Role'" 
            severity="primary"
            @click="updateUserRole"
            :disabled="!newUserRole || !roleChangeReason"
          />
        </template>
      </Dialog>
    </div>
  </PageWrapper>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useI18n } from 'vue-i18n'
import { supabase } from '@/lib/supabase'
import { useToast } from 'primevue/usetoast'
import Button from 'primevue/button'
import DataTable from 'primevue/datatable'
import Column from 'primevue/column'
import Dialog from 'primevue/dialog'
import InputText from 'primevue/inputtext'
import InputIcon from 'primevue/inputicon'
import IconField from 'primevue/iconfield'
import Select from 'primevue/select'
import Tag from 'primevue/tag'
import Textarea from 'primevue/textarea'
import PageWrapper from '@/components/Layout/PageWrapper.vue'

const { t } = useI18n()
const toast = useToast()

// State
const isLoading = ref(false)
const allUsers = ref([])
const filteredUsers = ref([])
const searchQuery = ref('')
const selectedRole = ref(null)
const currentPage = ref(0)
const pageSize = ref(20)

// Dialog state
const showRoleDialog = ref(false)
const selectedUser = ref(null)
const newUserRole = ref('')
const roleChangeReason = ref('')

// Computed
const userStats = computed(() => {
  const total = allUsers.value.length
  const cardIssuers = allUsers.value.filter(u => u.role === 'cardIssuer' || u.role === 'card_issuer').length
  const admins = allUsers.value.filter(u => u.role === 'admin').length

  return {
    total,
    cardIssuers,
    admins
  }
})

const paginatedUsers = computed(() => {
  const start = currentPage.value * pageSize.value
  const end = start + pageSize.value
  return filteredUsers.value.slice(start, end)
})

const hasActiveFilters = computed(() => {
  return searchQuery.value || selectedRole.value
})

// Options
const roleOptions = computed(() => [
  { label: t('admin.all_roles'), value: null },
  { label: t('common.card_issuer'), value: 'cardIssuer' },
  { label: t('common.admin'), value: 'admin' },
  { label: t('admin.user'), value: 'user' }
])

const roleChangeOptions = computed(() => [
  { label: t('common.card_issuer'), value: 'cardIssuer' },
  { label: t('common.admin'), value: 'admin' },
  { label: t('admin.user'), value: 'user' }
])

// Methods
const loadUsers = async () => {
  isLoading.value = true
  try {
    const { data, error } = await supabase.rpc('admin_get_all_users')
    if (error) throw error
    
    allUsers.value = data || []
    filterUsers()
  } catch (error) {
    console.error('Error loading users:', error)
    toast.add({
      severity: 'error',
      summary: t('common.error'),
      detail: t('admin.failed_to_load_users'),
      life: 3000
    })
  } finally {
    isLoading.value = false
  }
}

const filterUsers = () => {
  let filtered = [...allUsers.value]

  // Search filter
  if (searchQuery.value) {
    const query = searchQuery.value.toLowerCase()
    filtered = filtered.filter(user =>
      user.user_email?.toLowerCase().includes(query)
    )
  }

  // Role filter
  if (selectedRole.value) {
    filtered = filtered.filter(user => user.role === selectedRole.value)
  }

  filteredUsers.value = filtered
  currentPage.value = 0 // Reset to first page
}

const clearFilters = () => {
  searchQuery.value = ''
  selectedRole.value = null
  filterUsers()
}

const refreshData = () => {
  loadUsers()
}

const onPageChange = (event) => {
  currentPage.value = event.page
  pageSize.value = event.rows
}

const exportUsers = () => {
  const csvData = filteredUsers.value.map(user => ({
    Email: user.user_email,
    Role: user.role || 'cardIssuer',
    'Cards Count': user.cards_count || 0,
    'Issued Cards': user.issued_cards_count || 0,
    'Created Date': formatDate(user.created_at),
    'Last Sign In': user.last_sign_in_at ? formatDate(user.last_sign_in_at) : 'Never'
  }))

  const csv = [
    Object.keys(csvData[0]).join(','),
    ...csvData.map(row => Object.values(row).map(val => `"${val}"`).join(','))
  ].join('\n')

  const blob = new Blob([csv], { type: 'text/csv' })
  const url = URL.createObjectURL(blob)
  const a = document.createElement('a')
  a.href = url
  a.download = `users-export-${new Date().toISOString().split('T')[0]}.csv`
  a.click()
  URL.revokeObjectURL(url)
}

const manageUserRole = (user) => {
  selectedUser.value = user
  newUserRole.value = user.role || 'cardIssuer'
  roleChangeReason.value = ''
  showRoleDialog.value = true
}

const closeRoleDialog = () => {
  selectedUser.value = null
  newUserRole.value = ''
  roleChangeReason.value = ''
  showRoleDialog.value = false
}

const updateUserRole = async () => {
  if (!selectedUser.value || !newUserRole.value || !roleChangeReason.value) return

  try {
    const { error } = await supabase.rpc('admin_update_user_role', {
      p_user_id: selectedUser.value.user_id,
      p_new_role: newUserRole.value,
      p_reason: roleChangeReason.value
    })

    if (error) throw error

    toast.add({
      severity: 'success',
      summary: t('common.success'),
      detail: t('admin.user_role_updated_successfully'),
      life: 3000
    })

    closeRoleDialog()
    await refreshData()
  } catch (error) {
    console.error('Error updating user role:', error)
    toast.add({
      severity: 'error',
      summary: t('common.error'),
      detail: t('admin.failed_to_update_user_role'),
      life: 3000
    })
  }
}

// Helper functions
const getRoleLabel = (role) => {
  if (role === 'cardIssuer' || role === 'card_issuer') return t('common.card_issuer')
  if (role === 'admin') return t('common.admin')
  return t('admin.user')
}

const getRoleSeverity = (role) => {
  if (role === 'admin') return 'danger'
  if (role === 'cardIssuer' || role === 'card_issuer') return 'success'
  return 'secondary'
}

const formatDate = (dateString) => {
  if (!dateString) return 'N/A'
  return new Date(dateString).toLocaleDateString('en-US', {
    year: 'numeric',
    month: 'short',
    day: 'numeric'
  })
}

// Lifecycle
onMounted(() => {
  loadUsers()
})
</script>

<style scoped>
:deep(.users-table) {
  font-size: 0.875rem;
}

:deep(.users-table .p-datatable-thead > tr > th) {
  background-color: #f8fafc;
  color: #475569;
  font-weight: 600;
  font-size: 0.875rem;
  padding: 0.75rem 1rem;
  white-space: nowrap;
}

:deep(.users-table .p-datatable-tbody > tr > td) {
  padding: 0.75rem 1rem;
  vertical-align: middle;
}

:deep(.users-table .p-datatable-tbody > tr:hover) {
  background-color: #f8fafc;
}

/* Frozen columns styling */
:deep(.users-table .p-frozen-column) {
  background-color: white;
  z-index: 1;
}

:deep(.users-table .p-datatable-thead .p-frozen-column) {
  background-color: #f8fafc;
}

/* Scrollable table wrapper */
:deep(.users-table .p-datatable-wrapper) {
  overflow-x: auto;
}

/* Responsive adjustments for smaller screens */
@media (max-width: 768px) {
  :deep(.users-table .p-datatable-thead > tr > th) {
    padding: 0.5rem 0.75rem;
    font-size: 0.75rem;
  }
  
  :deep(.users-table .p-datatable-tbody > tr > td) {
    padding: 0.5rem 0.75rem;
  }
}

/* Table container max height */
:deep(.users-table .p-datatable-scrollable-body) {
  max-height: calc(100vh - 400px);
  min-height: 400px;
}
</style>
