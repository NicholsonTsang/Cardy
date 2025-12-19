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
      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-5 gap-4">
        <div class="bg-white rounded-xl shadow-soft border border-slate-200 p-5 hover:shadow-medium transition-shadow duration-200">
          <div class="flex items-center justify-between">
            <div>
              <h3 class="text-sm font-medium text-slate-600 mb-1">{{ $t('admin.total_users') }}</h3>
              <p class="text-2xl font-bold text-slate-900">{{ userStats.total }}</p>
            </div>
            <div class="p-3 bg-gradient-to-r from-blue-500 to-indigo-500 rounded-xl">
              <i class="pi pi-users text-white text-xl"></i>
            </div>
          </div>
        </div>

        <div class="bg-white rounded-xl shadow-soft border border-slate-200 p-5 hover:shadow-medium transition-shadow duration-200">
          <div class="flex items-center justify-between">
            <div>
              <h3 class="text-sm font-medium text-slate-600 mb-1">{{ $t('admin.card_issuers') || 'Experience Creators' }}</h3>
              <p class="text-2xl font-bold text-slate-900">{{ userStats.cardIssuers }}</p>
            </div>
            <div class="p-3 bg-gradient-to-r from-green-500 to-green-600 rounded-xl">
              <i class="pi pi-id-card text-white text-xl"></i>
            </div>
          </div>
        </div>

        <div class="bg-white rounded-xl shadow-soft border border-slate-200 p-5 hover:shadow-medium transition-shadow duration-200">
          <div class="flex items-center justify-between">
            <div>
              <h3 class="text-sm font-medium text-slate-600 mb-1">{{ $t('admin.admins') || 'Admins' }}</h3>
              <p class="text-2xl font-bold text-slate-900">{{ userStats.admins }}</p>
            </div>
            <div class="p-3 bg-gradient-to-r from-purple-500 to-violet-500 rounded-xl">
              <i class="pi pi-shield text-white text-xl"></i>
            </div>
          </div>
        </div>

        <div class="bg-white rounded-xl shadow-soft border border-slate-200 p-5 hover:shadow-medium transition-shadow duration-200">
          <div class="flex items-center justify-between">
            <div>
              <h3 class="text-sm font-medium text-slate-600 mb-1">{{ $t('admin.premium_users') || 'Premium Users' }}</h3>
              <p class="text-2xl font-bold text-amber-600">{{ userStats.premiumUsers }}</p>
            </div>
            <div class="p-3 bg-gradient-to-r from-amber-500 to-orange-500 rounded-xl">
              <i class="pi pi-star-fill text-white text-xl"></i>
            </div>
          </div>
        </div>

        <div class="bg-white rounded-xl shadow-soft border border-slate-200 p-5 hover:shadow-medium transition-shadow duration-200">
          <div class="flex items-center justify-between">
            <div>
              <h3 class="text-sm font-medium text-slate-600 mb-1">{{ $t('admin.free_users') || 'Free Users' }}</h3>
              <p class="text-2xl font-bold text-slate-700">{{ userStats.freeUsers }}</p>
            </div>
            <div class="p-3 bg-gradient-to-r from-slate-400 to-slate-500 rounded-xl">
              <i class="pi pi-user text-white text-xl"></i>
            </div>
          </div>
        </div>
      </div>

      <!-- Filters and Search -->
      <div class="bg-white rounded-xl shadow-soft border border-slate-200 p-6">
        <h3 class="text-lg font-semibold text-slate-900 mb-4">{{ $t('admin.filters_search') || 'Filters & Search' }}</h3>
        <div class="grid grid-cols-1 md:grid-cols-4 gap-4">
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
          <div>
            <Select 
              v-model="selectedTier"
              :options="tierOptions"
              optionLabel="label"
              optionValue="value"
              :placeholder="$t('admin.filter_by_tier') || 'Filter by Tier'"
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
              <span class="text-sm text-slate-600 whitespace-nowrap">{{ formatDate(data.created_at) }}</span>
            </template>
          </Column>

          <Column field="subscription_tier" :header="$t('admin.subscription_tier') || 'Tier'" sortable :style="{ width: '120px', minWidth: '120px' }">
            <template #body="{ data }">
              <Tag 
                :value="getTierLabel(data.subscription_tier)"
                :severity="getTierSeverity(data.subscription_tier)"
                class="whitespace-nowrap"
              >
                <template #icon>
                  <i :class="data.subscription_tier === 'premium' ? 'pi pi-star-fill mr-1' : 'pi pi-user mr-1'" style="font-size: 0.7rem;"></i>
                </template>
              </Tag>
            </template>
          </Column>

          <Column field="subscription_status" :header="$t('admin.subscription_status') || 'Sub Status'" sortable :style="{ width: '120px', minWidth: '120px' }">
            <template #body="{ data }">
              <div class="flex items-center gap-1">
                <Tag 
                  :value="getSubscriptionStatusLabel(data)"
                  :severity="getSubscriptionStatusSeverity(data)"
                  class="whitespace-nowrap text-xs"
                />
              </div>
            </template>
          </Column>

          <Column field="last_sign_in_at" :header="$t('admin.last_sign_in') || 'Last Sign In'" sortable :style="{ width: '140px', minWidth: '140px' }">
            <template #body="{ data }">
              <span class="text-sm text-slate-600 whitespace-nowrap">
                {{ data.last_sign_in_at ? formatDate(data.last_sign_in_at) : ($t('admin.never') || 'Never') }}
              </span>
            </template>
          </Column>

          <Column :header="$t('common.actions')" :style="{ width: '140px', minWidth: '140px' }" frozen alignFrozen="right" class="text-center">
            <template #body="{ data }">
              <div class="flex items-center justify-center gap-1">
                <Button 
                  icon="pi pi-cog"
                  size="small"
                  outlined
                  severity="secondary"
                  @click="manageUserRole(data)"
                  v-tooltip.top="$t('admin.manage_role')"
                />
                <Button 
                  icon="pi pi-star"
                  size="small"
                  outlined
                  :severity="data.subscription_tier === 'premium' ? 'warning' : 'info'"
                  @click="manageUserSubscription(data)"
                  v-tooltip.top="$t('admin.manage_subscription') || 'Manage Subscription'"
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

      <!-- Subscription Management Dialog -->
      <Dialog 
        v-model:visible="showSubscriptionDialog"
        modal
        :header="$t('admin.manage_subscription') || 'Manage Subscription'"
        :style="{ width: '90vw', maxWidth: '550px' }"
        @hide="closeSubscriptionDialog"
      >
        <div v-if="selectedUser" class="space-y-4">
          <!-- User Info -->
          <div>
            <label class="block text-sm font-medium text-slate-700 mb-2">{{ $t('admin.user') || 'User' }}</label>
            <div class="p-3 bg-slate-50 rounded-lg">
              <p class="font-medium text-slate-900">{{ selectedUser.user_email }}</p>
              <div class="flex items-center gap-2 mt-1">
                <Tag 
                  :value="getTierLabel(selectedUser.subscription_tier)"
                  :severity="getTierSeverity(selectedUser.subscription_tier)"
                  size="small"
                >
                  <template #icon>
                    <i :class="selectedUser.subscription_tier === 'premium' ? 'pi pi-star-fill mr-1' : 'pi pi-user mr-1'" style="font-size: 0.65rem;"></i>
                  </template>
                </Tag>
                <Tag 
                  :value="getSubscriptionStatusLabel(selectedUser)"
                  :severity="getSubscriptionStatusSeverity(selectedUser)"
                  size="small"
                />
              </div>
            </div>
          </div>

          <!-- Current Subscription Info -->
          <div v-if="selectedUser.subscription_tier === 'premium'" class="p-3 bg-amber-50 border border-amber-200 rounded-lg">
            <div class="flex items-center gap-2 mb-2">
              <i class="pi pi-info-circle text-amber-600"></i>
              <span class="font-medium text-amber-800">{{ $t('admin.current_subscription_info') || 'Current Subscription Info' }}</span>
            </div>
            <div class="text-sm text-amber-700 space-y-1">
              <p v-if="selectedUser.stripe_subscription_id">
                <span class="font-medium">{{ $t('admin.stripe_managed') || 'Stripe Managed' }}:</span> 
                <code class="bg-amber-100 px-1 rounded text-xs">{{ selectedUser.stripe_subscription_id }}</code>
              </p>
              <p v-else>
                <span class="font-medium">{{ $t('admin.admin_managed') || 'Admin Managed' }}</span> ({{ $t('admin.no_stripe_subscription') || 'No Stripe subscription' }})
              </p>
              <p v-if="selectedUser.current_period_end">
                <span class="font-medium">{{ $t('admin.period_ends') || 'Period Ends' }}:</span> 
                {{ formatDate(selectedUser.current_period_end) }}
              </p>
              <p v-if="selectedUser.cancel_at_period_end" class="text-red-600">
                <i class="pi pi-exclamation-triangle mr-1"></i>
                {{ $t('admin.scheduled_cancellation') || 'Scheduled for cancellation at period end' }}
              </p>
            </div>
          </div>

          <!-- Tier Selection -->
          <div>
            <label for="newTier" class="block text-sm font-medium text-slate-700 mb-2">
              {{ $t('admin.new_tier') || 'New Tier' }} <span class="text-red-500">*</span>
            </label>
            <div class="grid grid-cols-2 gap-3">
              <div 
                @click="newSubscriptionTier = 'free'"
                :class="[
                  'p-4 border-2 rounded-xl cursor-pointer transition-all duration-200',
                  newSubscriptionTier === 'free' 
                    ? 'border-slate-500 bg-slate-50' 
                    : 'border-slate-200 hover:border-slate-300'
                ]"
              >
                <div class="flex items-center gap-2 mb-2">
                  <i class="pi pi-user text-slate-600"></i>
                  <span class="font-semibold text-slate-900">{{ $t('subscription.free_plan') || 'Free' }}</span>
                </div>
                <ul class="text-xs text-slate-600 space-y-1">
                  <li>• {{ $t('admin.free_tier_experiences') || '3 experiences' }}</li>
                  <li>• {{ $t('admin.free_tier_access') || '50 monthly access' }}</li>
                  <li>• {{ $t('admin.no_translations') || 'No translations' }}</li>
                </ul>
              </div>
              <div 
                @click="newSubscriptionTier = 'premium'"
                :class="[
                  'p-4 border-2 rounded-xl cursor-pointer transition-all duration-200',
                  newSubscriptionTier === 'premium' 
                    ? 'border-amber-500 bg-amber-50' 
                    : 'border-slate-200 hover:border-amber-200'
                ]"
              >
                <div class="flex items-center gap-2 mb-2">
                  <i class="pi pi-star-fill text-amber-500"></i>
                  <span class="font-semibold text-slate-900">{{ $t('subscription.premium_plan') || 'Premium' }}</span>
                </div>
                <ul class="text-xs text-slate-600 space-y-1">
                  <li>• {{ $t('admin.premium_tier_experiences') || '15 experiences' }}</li>
                  <li>• {{ $t('admin.premium_tier_access') || '3,000 monthly access' }}</li>
                  <li>• {{ $t('admin.full_translations') || 'Full translations' }}</li>
                </ul>
              </div>
            </div>
          </div>

          <!-- Reason -->
          <div>
            <label for="subscriptionReason" class="block text-sm font-medium text-slate-700 mb-2">
              {{ $t('admin.reason_for_change') || 'Reason for Change' }} <span class="text-red-500">*</span>
            </label>
            <Textarea 
              id="subscriptionReason"
              v-model="subscriptionChangeReason"
              rows="3"
              :placeholder="$t('admin.subscription_reason_placeholder') || 'Explain why this subscription change is necessary (e.g., promotional upgrade, support case, etc.)'"
              class="w-full"
            />
          </div>

          <!-- Warning for Stripe-managed subscriptions -->
          <div v-if="selectedUser.stripe_subscription_id && newSubscriptionTier !== selectedUser.subscription_tier" class="p-3 bg-red-50 border border-red-200 rounded-lg">
            <div class="flex items-start gap-2">
              <i class="pi pi-exclamation-triangle text-red-600 mt-0.5"></i>
              <div class="text-sm text-red-700">
                <p class="font-medium">{{ $t('admin.stripe_warning_title') || 'Warning: Stripe-managed subscription' }}</p>
                <p class="mt-1">
                  {{ $t('admin.stripe_warning_desc') || 'This user has an active Stripe subscription. Manually changing the tier will not affect their Stripe billing. Consider using Stripe Dashboard to manage billing changes.' }}
                </p>
              </div>
            </div>
          </div>
        </div>

        <template #footer>
          <Button :label="$t('common.cancel')" text severity="secondary" @click="closeSubscriptionDialog" />
          <Button 
            :label="$t('admin.update_subscription') || 'Update Subscription'" 
            :severity="newSubscriptionTier === 'premium' ? 'warning' : 'primary'"
            @click="updateUserSubscription"
            :disabled="!newSubscriptionTier || !subscriptionChangeReason || newSubscriptionTier === selectedUser?.subscription_tier"
            :loading="isUpdatingSubscription"
          >
            <template #icon>
              <i :class="newSubscriptionTier === 'premium' ? 'pi pi-star-fill mr-2' : 'pi pi-user mr-2'"></i>
            </template>
          </Button>
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
const selectedTier = ref(null)
const currentPage = ref(0)
const pageSize = ref(20)

// Dialog state - Role
const showRoleDialog = ref(false)
const selectedUser = ref(null)
const newUserRole = ref('')
const roleChangeReason = ref('')

// Dialog state - Subscription
const showSubscriptionDialog = ref(false)
const newSubscriptionTier = ref('')
const subscriptionChangeReason = ref('')
const isUpdatingSubscription = ref(false)

// Computed
const userStats = computed(() => {
  const total = allUsers.value.length
  const cardIssuers = allUsers.value.filter(u => u.role === 'cardIssuer' || u.role === 'card_issuer').length
  const admins = allUsers.value.filter(u => u.role === 'admin').length
  const premiumUsers = allUsers.value.filter(u => u.subscription_tier === 'premium').length
  const freeUsers = total - premiumUsers

  return {
    total,
    cardIssuers,
    admins,
    premiumUsers,
    freeUsers
  }
})

const paginatedUsers = computed(() => {
  const start = currentPage.value * pageSize.value
  const end = start + pageSize.value
  return filteredUsers.value.slice(start, end)
})

const hasActiveFilters = computed(() => {
  return searchQuery.value || selectedRole.value || selectedTier.value
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

const tierOptions = computed(() => [
  { label: t('admin.all_tiers') || 'All Tiers', value: null },
  { label: t('subscription.premium_plan') || 'Premium', value: 'premium' },
  { label: t('subscription.free_plan') || 'Free', value: 'free' }
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

  // Tier filter
  if (selectedTier.value) {
    filtered = filtered.filter(user => user.subscription_tier === selectedTier.value)
  }

  filteredUsers.value = filtered
  currentPage.value = 0 // Reset to first page
}

const clearFilters = () => {
  searchQuery.value = ''
  selectedRole.value = null
  selectedTier.value = null
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
    'Subscription Tier': user.subscription_tier || 'free',
    'Subscription Status': user.subscription_status || 'active',
    'Cards Count': user.cards_count || 0,
    'Issued Cards': user.issued_cards_count || 0,
    'Created Date': formatDate(user.created_at),
    'Last Sign In': user.last_sign_in_at ? formatDate(user.last_sign_in_at) : 'Never',
    'Stripe Subscription ID': user.stripe_subscription_id || '',
    'Period End': user.current_period_end ? formatDate(user.current_period_end) : ''
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

// Subscription management methods
const manageUserSubscription = (user) => {
  selectedUser.value = user
  newSubscriptionTier.value = user.subscription_tier || 'free'
  subscriptionChangeReason.value = ''
  showSubscriptionDialog.value = true
}

const closeSubscriptionDialog = () => {
  selectedUser.value = null
  newSubscriptionTier.value = ''
  subscriptionChangeReason.value = ''
  showSubscriptionDialog.value = false
}

const updateUserSubscription = async () => {
  if (!selectedUser.value || !newSubscriptionTier.value || !subscriptionChangeReason.value) return
  if (newSubscriptionTier.value === selectedUser.value.subscription_tier) return

  isUpdatingSubscription.value = true
  
  try {
    const { error } = await supabase.rpc('admin_update_user_subscription', {
      p_user_id: selectedUser.value.user_id,
      p_new_tier: newSubscriptionTier.value,
      p_reason: subscriptionChangeReason.value
    })

    if (error) throw error

    toast.add({
      severity: 'success',
      summary: t('common.success'),
      detail: t('admin.subscription_updated_successfully') || 'Subscription updated successfully',
      life: 3000
    })

    closeSubscriptionDialog()
    await refreshData()
  } catch (error) {
    console.error('Error updating user subscription:', error)
    toast.add({
      severity: 'error',
      summary: t('common.error'),
      detail: t('admin.failed_to_update_subscription') || 'Failed to update subscription',
      life: 3000
    })
  } finally {
    isUpdatingSubscription.value = false
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

const getTierLabel = (tier) => {
  if (tier === 'premium') return t('subscription.premium_plan') || 'Premium'
  return t('subscription.free_plan') || 'Free'
}

const getTierSeverity = (tier) => {
  if (tier === 'premium') return 'warning'
  return 'secondary'
}

const getSubscriptionStatusLabel = (user) => {
  if (!user) return 'Active'
  
  if (user.cancel_at_period_end) {
    return t('admin.canceling') || 'Canceling'
  }
  
  const status = user.subscription_status || 'active'
  switch (status) {
    case 'active': return t('common.active') || 'Active'
    case 'past_due': return t('admin.past_due') || 'Past Due'
    case 'canceled': return t('admin.canceled') || 'Canceled'
    case 'trialing': return t('admin.trialing') || 'Trialing'
    default: return status
  }
}

const getSubscriptionStatusSeverity = (user) => {
  if (!user) return 'success'
  
  if (user.cancel_at_period_end) return 'warning'
  
  const status = user.subscription_status || 'active'
  switch (status) {
    case 'active': return 'success'
    case 'past_due': return 'danger'
    case 'canceled': return 'secondary'
    case 'trialing': return 'info'
    default: return 'secondary'
  }
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
