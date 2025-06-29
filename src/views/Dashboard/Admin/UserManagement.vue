<template>
  <div class="space-y-6">
    <!-- Page Header -->
    <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
      <div>
        <h1 class="text-2xl font-bold text-slate-900">User Management</h1>
        <p class="text-slate-600 mt-1">Manage card issuers and their verification status</p>
      </div>
      <div class="flex items-center gap-3">
        <Button 
          icon="pi pi-refresh" 
          label="Refresh" 
          outlined
          @click="refreshData"
          :loading="verificationsStore.isLoadingVerifications"
        />
        <Button 
          icon="pi pi-download" 
          label="Export CSV" 
          outlined
          @click="exportUsers"
        />
      </div>
    </div>

    <!-- Statistics Cards -->
    <div class="grid grid-cols-1 md:grid-cols-4 gap-6">
      <div class="bg-white rounded-xl shadow-lg border border-slate-200 p-6">
        <div class="flex items-center justify-between">
          <div>
            <h3 class="text-sm font-medium text-slate-600 mb-2">Total Users</h3>
            <p class="text-3xl font-bold text-slate-900">{{ userStats.total_users }}</p>
          </div>
          <div class="p-4 bg-gradient-to-r from-blue-500 to-indigo-500 rounded-xl">
            <i class="pi pi-users text-white text-2xl"></i>
          </div>
        </div>
      </div>

      <div class="bg-white rounded-xl shadow-lg border border-slate-200 p-6">
        <div class="flex items-center justify-between">
          <div>
            <h3 class="text-sm font-medium text-slate-600 mb-2">Verified Users</h3>
            <p class="text-3xl font-bold text-slate-900">{{ userStats.verified_users }}</p>
            <p class="text-sm text-green-600 mt-1">{{ verificationRate }}% verified</p>
          </div>
          <div class="p-4 bg-gradient-to-r from-green-500 to-emerald-500 rounded-xl">
            <i class="pi pi-shield text-white text-2xl"></i>
          </div>
        </div>
      </div>

      <div class="bg-white rounded-xl shadow-lg border border-slate-200 p-6">
        <div class="flex items-center justify-between">
          <div>
            <h3 class="text-sm font-medium text-slate-600 mb-2">Pending Reviews</h3>
            <p class="text-3xl font-bold text-slate-900">{{ userStats.pending_verifications }}</p>
          </div>
          <div class="p-4 bg-gradient-to-r from-amber-500 to-orange-500 rounded-xl">
            <i class="pi pi-clock text-white text-2xl"></i>
          </div>
        </div>
      </div>

      <div class="bg-white rounded-xl shadow-lg border border-slate-200 p-6">
        <div class="flex items-center justify-between">
          <div>
            <h3 class="text-sm font-medium text-slate-600 mb-2">Active This Month</h3>
            <p class="text-3xl font-bold text-slate-900">{{ userStats.active_this_month }}</p>
          </div>
          <div class="p-4 bg-gradient-to-r from-purple-500 to-violet-500 rounded-xl">
            <i class="pi pi-calendar text-white text-2xl"></i>
          </div>
        </div>
      </div>
    </div>

    <!-- Filters and Search -->
    <div class="bg-white rounded-xl shadow-lg border border-slate-200 p-6">
      <h3 class="text-lg font-semibold text-slate-900 mb-4">Filters & Search</h3>
      <div class="grid grid-cols-1 md:grid-cols-5 gap-4">
        <div class="md:col-span-2">
          <IconField>
            <InputIcon class="pi pi-search" />
            <InputText 
              v-model="searchQuery"
              placeholder="Search by name, email, or company..."
              class="w-full"
              @input="debouncedSearch"
            />
          </IconField>
        </div>
        <div>
          <Select 
            v-model="selectedVerificationStatus"
            :options="verificationStatusOptions"
            optionLabel="label"
            optionValue="value"
            placeholder="Verification Status"
            class="w-full"
            @change="filterUsers"
            showClear
          />
        </div>
        <div>
          <Select 
            v-model="selectedUserRole"
            :options="userRoleOptions"
            optionLabel="label"
            optionValue="value"
            placeholder="User Role"
            class="w-full"
            @change="filterUsers"
            showClear
          />
        </div>
        <div>
          <Calendar 
            v-model="registrationDateRange"
            selectionMode="range"
            :manualInput="false"
            placeholder="Registration Date"
            class="w-full"
            @date-select="filterUsers"
            showIcon
            dateFormat="mm/dd/yy"
          />
        </div>
      </div>
      <div class="flex justify-between items-center mt-4">
        <div class="flex items-center gap-4">
          <p class="text-sm text-slate-600">
            Showing {{ filteredUsers.length }} of {{ allUsers.length }} users
          </p>
          <div v-if="hasActiveFilters" class="flex gap-2">
            <Tag 
              v-if="searchQuery" 
              :value="`Search: ${searchQuery}`" 
              severity="info" 
              class="text-xs"
            />
            <Tag 
              v-if="selectedVerificationStatus" 
              :value="`Status: ${selectedVerificationStatus}`" 
              severity="secondary" 
              class="text-xs"
            />
            <Tag 
              v-if="selectedUserRole" 
              :value="`Role: ${selectedUserRole}`" 
              severity="warning" 
              class="text-xs"
            />
            <Tag 
              v-if="registrationDateRange && registrationDateRange.length === 2" 
              value="Date Range Applied" 
              severity="success" 
              class="text-xs"
            />
          </div>
        </div>
        <Button 
          v-if="hasActiveFilters"
          label="Clear All Filters" 
          icon="pi pi-times"
          text
          @click="clearFilters"
          size="small"
        />
      </div>
    </div>

    <!-- Users Table -->
    <div class="bg-white rounded-xl shadow-lg border border-slate-200 overflow-hidden">
      <DataTable 
        :value="paginatedUsers"
        :loading="verificationsStore.isLoadingVerifications"
        class="border-0"
        stripedRows
        responsiveLayout="scroll"
      >
        <template #empty>
          <div class="text-center py-8">
            <i class="pi pi-users text-4xl text-slate-400 mb-4"></i>
            <p class="text-slate-500">No users found</p>
          </div>
        </template>

        <Column field="user_info" header="User" style="min-width: 250px">
          <template #body="{ data }">
            <div class="flex items-center gap-3">
              <div class="w-10 h-10 rounded-full flex items-center justify-center text-white font-medium"
                   :class="getUserAvatarClass(data.public_name)">
                {{ getUserInitials(data.public_name) }}
              </div>
              <div>
                <p class="font-medium text-slate-900">{{ data.public_name || 'Unnamed User' }}</p>
                <p class="text-sm text-slate-600">{{ data.user_email }}</p>
                <p v-if="data.company_name" class="text-xs text-slate-500">{{ data.company_name }}</p>
              </div>
            </div>
          </template>
        </Column>

        <Column field="verification_status" header="Verification" style="min-width: 150px">
          <template #body="{ data }">
            <div class="space-y-1">
              <Tag 
                :value="getVerificationStatusLabel(data.verification_status)"
                :severity="getVerificationSeverity(data.verification_status)"
                class="text-xs px-2 py-1"
              />
              <p v-if="data.verified_at" class="text-xs text-slate-500">
                Verified {{ formatDate(data.verified_at) }}
              </p>
            </div>
          </template>
        </Column>

        <Column field="role" header="Role" style="min-width: 100px">
          <template #body="{ data }">
            <Tag 
              :value="data.role || 'cardIssuer'"
              :severity="getRoleSeverity(data.role)"
              class="text-xs px-2 py-1"
            />
          </template>
        </Column>

        <Column field="created_at" header="Joined" style="min-width: 120px">
          <template #body="{ data }">
            <div>
              <p class="text-sm text-slate-900">{{ formatDate(data.created_at) }}</p>
              <p v-if="data.last_sign_in_at" class="text-xs text-slate-500">
                Last seen {{ formatDate(data.last_sign_in_at) }}
              </p>
            </div>
          </template>
        </Column>

        <Column field="activity" header="Activity" style="min-width: 120px">
          <template #body="{ data }">
            <div class="space-y-1">
              <p class="text-sm text-slate-900">{{ data.cards_count || 0 }} cards</p>
              <p class="text-xs text-slate-500">{{ data.issued_cards_count || 0 }} issued</p>
            </div>
          </template>
        </Column>

        <Column header="Actions" style="min-width: 200px">
          <template #body="{ data }">
            <div class="flex items-center gap-2">
              <Button 
                icon="pi pi-eye"
                size="small"
                outlined
                @click="viewUserDetails(data)"
                v-tooltip="'View Details'"
              />
              <Button 
                icon="pi pi-shield"
                size="small"
                outlined
                severity="info"
                @click="manageVerification(data)"
                v-tooltip="'Manage Verification'"
                v-if="data.verification_status !== 'NOT_SUBMITTED'"
              />
              <Button 
                icon="pi pi-shield"
                size="small"
                outlined
                severity="success"
                @click="manualVerifyUser(data)"
                v-tooltip="'Manual Verification'"
                v-if="data.verification_status === 'NOT_SUBMITTED'"
              />
              <Button 
                icon="pi pi-pencil"
                size="small"
                outlined
                severity="warning"
                @click="editVerificationNotes(data)"
                v-tooltip="'Edit Verification Notes'"
                v-if="data.verification_status === 'APPROVED' || data.verification_status === 'REJECTED'"
              />
              <Button 
                icon="pi pi-cog"
                size="small"
                outlined
                severity="secondary"
                @click="manageUserRole(data)"
                v-tooltip="'Manage Role'"
              />
              <Button 
                icon="pi pi-ban"
                size="small"
                outlined
                severity="danger"
                @click="confirmResetVerification(data)"
                v-tooltip="'Reset Verification'"
                v-if="data.verification_status === 'APPROVED'"
              />
            </div>
          </template>
        </Column>
      </DataTable>

      <!-- Pagination -->
      <div class="p-4 border-t border-slate-200">
        <Paginator 
          :rows="pageSize"
          :totalRecords="filteredUsers.length"
          :first="currentPage * pageSize"
          @page="onPageChange"
          template="FirstPageLink PrevPageLink CurrentPageReport NextPageLink LastPageLink RowsPerPageDropdown"
          :rowsPerPageOptions="[10, 20, 50, 100]"
        />
      </div>
    </div>

    <!-- User Details Dialog -->
    <MyDialog
      v-model="showUserDetailsDialog"
      header="User Details"
      :showConfirm="false"
      @hide="closeUserDetailsDialog"
      style="width: 90vw; max-width: 900px;"
    >
      <div v-if="selectedUser" class="space-y-6">
        <!-- User Information -->
        <div class="bg-slate-50 rounded-lg p-6">
          <h4 class="font-medium text-slate-900 mb-4 flex items-center gap-2">
            <i class="pi pi-user text-blue-600"></i>
            User Information
          </h4>
          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label class="text-sm font-medium text-slate-700">Email</label>
              <p class="text-sm text-slate-900">{{ selectedUser.user_email }}</p>
            </div>
            <div>
              <label class="text-sm font-medium text-slate-700">Public Name</label>
              <p class="text-sm text-slate-900">{{ selectedUser.public_name || 'Not provided' }}</p>
            </div>
            <div>
              <label class="text-sm font-medium text-slate-700">Company</label>
              <p class="text-sm text-slate-900">{{ selectedUser.company_name || 'Not provided' }}</p>
            </div>
            <div>
              <label class="text-sm font-medium text-slate-700">Role</label>
              <p class="text-sm text-slate-900">{{ selectedUser.role || 'cardIssuer' }}</p>
            </div>
            <div>
              <label class="text-sm font-medium text-slate-700">Member Since</label>
              <p class="text-sm text-slate-900">{{ formatDate(selectedUser.created_at) }}</p>
            </div>
            <div>
              <label class="text-sm font-medium text-slate-700">Last Active</label>
              <p class="text-sm text-slate-900">
                {{ selectedUser.last_sign_in_at ? formatDate(selectedUser.last_sign_in_at) : 'Never' }}
              </p>
            </div>
          </div>
          <div v-if="selectedUser.bio" class="mt-4">
            <label class="text-sm font-medium text-slate-700">Bio</label>
            <p class="text-sm text-slate-900 mt-1">{{ selectedUser.bio }}</p>
          </div>
        </div>

        <!-- Verification Information -->
        <div v-if="selectedUser.verification_status !== 'NOT_SUBMITTED'" class="bg-slate-50 rounded-lg p-6">
          <h4 class="font-medium text-slate-900 mb-4 flex items-center gap-2">
            <i class="pi pi-shield text-green-600"></i>
            Verification Information
          </h4>
          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label class="text-sm font-medium text-slate-700">Status</label>
              <div class="mt-1">
                <Tag 
                  :value="getVerificationStatusLabel(selectedUser.verification_status)"
                  :severity="getVerificationSeverity(selectedUser.verification_status)"
                />
              </div>
            </div>
            <div v-if="selectedUser.verified_at">
              <label class="text-sm font-medium text-slate-700">Verified Date</label>
              <p class="text-sm text-slate-900">{{ formatDate(selectedUser.verified_at) }}</p>
            </div>
            <div v-if="selectedUser.full_name">
              <label class="text-sm font-medium text-slate-700">Legal Name</label>
              <p class="text-sm text-slate-900">{{ selectedUser.full_name }}</p>
            </div>
          </div>
          <div v-if="selectedUser.admin_feedback" class="mt-4">
            <label class="text-sm font-medium text-slate-700">Admin Feedback</label>
            <div class="mt-1 p-3 bg-white rounded border">
              <p class="text-sm text-slate-900 whitespace-pre-wrap">{{ selectedUser.admin_feedback }}</p>
              <div class="mt-2 pt-2 border-t border-slate-200">
                <Button 
                  label="Edit Notes" 
                  icon="pi pi-pencil"
                  size="small"
                  text
                  @click="editVerificationNotes(selectedUser)"
                />
              </div>
            </div>
          </div>
          <div v-if="selectedUser.supporting_documents?.length" class="mt-4">
            <label class="text-sm font-medium text-slate-700">Supporting Documents</label>
            <div class="mt-2 space-y-2">
              <div 
                v-for="(doc, index) in selectedUser.supporting_documents" 
                :key="index"
                class="flex items-center justify-between p-3 bg-white rounded border"
              >
                <span class="text-sm text-slate-900">{{ getDocumentName(doc) }}</span>
                <Button 
                  label="View" 
                  icon="pi pi-external-link"
                  size="small"
                  text
                  @click="viewDocument(doc)"
                />
              </div>
            </div>
          </div>
        </div>

        <!-- No Verification Section -->
        <div v-else class="bg-amber-50 rounded-lg p-6 border border-amber-200">
          <h4 class="font-medium text-amber-900 mb-4 flex items-center gap-2">
            <i class="pi pi-exclamation-triangle text-amber-600"></i>
            No Verification Submitted
          </h4>
          <p class="text-sm text-amber-800 mb-4">
            This user hasn't submitted a verification request yet. You can manually verify them if needed.
          </p>
          <Button 
            label="Manual Verification" 
            icon="pi pi-shield"
            size="small"
            severity="success"
            @click="manualVerifyUser(selectedUser)"
          />
        </div>

        <!-- Activity Summary -->
        <div class="bg-slate-50 rounded-lg p-6">
          <h4 class="font-medium text-slate-900 mb-4 flex items-center gap-2">
            <i class="pi pi-chart-bar text-purple-600"></i>
            Activity Summary
          </h4>
          <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div class="text-center p-4 bg-white rounded border">
              <p class="text-2xl font-bold text-slate-900">{{ selectedUser.cards_count || 0 }}</p>
              <p class="text-sm text-slate-600">Card Designs</p>
            </div>
            <div class="text-center p-4 bg-white rounded border">
              <p class="text-2xl font-bold text-slate-900">{{ selectedUser.issued_cards_count || 0 }}</p>
              <p class="text-sm text-slate-600">Cards Issued</p>
            </div>
            <div class="text-center p-4 bg-white rounded border">
              <p class="text-2xl font-bold text-slate-900">{{ selectedUser.print_requests_count || 0 }}</p>
              <p class="text-sm text-slate-600">Print Requests</p>
            </div>
          </div>
        </div>
      </div>
    </MyDialog>

    <!-- Role Management Dialog -->
    <MyDialog
      v-model="showRoleDialog"
      header="Manage User Role"
      :confirmHandle="handleRoleUpdate"
      confirmLabel="Update Role"
      confirmSeverity="primary"
      successMessage="User role updated successfully"
      errorMessage="Failed to update user role"
      :showToasts="true"
      @hide="closeRoleDialog"
    >
      <div v-if="selectedUser" class="space-y-4">
        <div class="bg-amber-50 border border-amber-200 rounded-lg p-4">
          <div class="flex items-start gap-3">
            <i class="pi pi-exclamation-triangle text-amber-600 text-lg mt-0.5"></i>
            <div>
              <h4 class="font-medium text-amber-900">Role Change Warning</h4>
              <p class="text-sm text-amber-800 mt-1">
                Changing user roles will affect their access permissions. This action cannot be undone automatically.
              </p>
            </div>
          </div>
        </div>

        <div>
          <label class="block text-sm font-medium text-slate-700 mb-2">
            Current Role: <span class="font-normal">{{ selectedUser.role || 'cardIssuer' }}</span>
          </label>
          <Select 
            v-model="newUserRole"
            :options="roleChangeOptions"
            optionLabel="label"
            optionValue="value"
            placeholder="Select new role"
            class="w-full"
          />
        </div>

        <div>
          <label class="block text-sm font-medium text-slate-700 mb-2">Reason for Change</label>
          <Textarea 
            v-model="roleChangeReason"
            rows="3"
            class="w-full"
            placeholder="Explain why you're changing this user's role..."
          />
        </div>
      </div>
    </MyDialog>

    <!-- Manual Verification Dialog -->
    <MyDialog
      v-model="showManualVerificationDialog"
      header="Manual Verification"
      :confirmHandle="handleManualVerification"
      confirmLabel="Update Verification"
      confirmSeverity="primary"
      successMessage="User verification updated successfully"
      errorMessage="Failed to update user verification"
      :showToasts="true"
      @hide="closeManualVerificationDialog"
      style="width: 90vw; max-width: 600px;"
    >
      <div v-if="selectedUser" class="space-y-4">
        <div class="bg-blue-50 border border-blue-200 rounded-lg p-4">
          <div class="flex items-start gap-3">
            <i class="pi pi-info-circle text-blue-600 text-lg mt-0.5"></i>
            <div>
              <h4 class="font-medium text-blue-900">Manual Verification</h4>
              <p class="text-sm text-blue-800 mt-1">
                This allows you to verify users manually even if they haven't submitted a verification request.
                You can also edit existing verification notes.
              </p>
            </div>
          </div>
        </div>

        <div>
          <label class="block text-sm font-medium text-slate-700 mb-2">
            User: <span class="font-normal">{{ selectedUser.public_name || selectedUser.user_email }}</span>
          </label>
          <label class="block text-sm font-medium text-slate-700 mb-2">
            Current Status: 
            <Tag 
              :value="getVerificationStatusLabel(selectedUser.verification_status)"
              :severity="getVerificationSeverity(selectedUser.verification_status)"
              class="ml-2"
            />
          </label>
        </div>

        <div>
          <label class="block text-sm font-medium text-slate-700 mb-2">New Verification Status</label>
          <Select 
            v-model="manualVerificationStatus"
            :options="manualVerificationOptions"
            optionLabel="label"
            optionValue="value"
            placeholder="Select verification status"
            class="w-full"
          />
        </div>

        <div v-if="manualVerificationStatus === 'APPROVED'">
          <label class="block text-sm font-medium text-slate-700 mb-2">Legal Name (Optional)</label>
          <InputText 
            v-model="manualVerificationFullName"
            class="w-full"
            placeholder="Enter user's legal name for verification records"
          />
        </div>

        <div>
          <label class="block text-sm font-medium text-slate-700 mb-2">
            Admin Notes <span class="text-red-500">*</span>
          </label>
          <Textarea 
            v-model="manualVerificationNotes"
            rows="4"
            class="w-full"
            placeholder="Enter reason for manual verification or note updates..."
          />
          <p class="text-xs text-slate-500 mt-1">These notes can be edited later and will be visible to the user.</p>
        </div>
      </div>
    </MyDialog>

    <!-- Confirmation Dialogs -->
    <ConfirmDialog group="resetVerification"></ConfirmDialog>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, watch } from 'vue'
import { useAdminVerificationsStore, useAdminFeedbackStore } from '@/stores/admin'
import { useConfirm } from 'primevue/useconfirm'
import { useToast } from 'primevue/usetoast'
import { FilterMatchMode } from '@primevue/core/api'
import Button from 'primevue/button'
import DataTable from 'primevue/datatable'
import Column from 'primevue/column'
import Tag from 'primevue/tag'
import InputText from 'primevue/inputtext'
import Textarea from 'primevue/textarea'
import Select from 'primevue/select'
import Dialog from 'primevue/dialog'
import IconField from 'primevue/iconfield'
import InputIcon from 'primevue/inputicon'
import ConfirmDialog from 'primevue/confirmdialog'
import MyDialog from '@/components/MyDialog.vue'
import Calendar from 'primevue/calendar'
import Paginator from 'primevue/paginator'

const verificationsStore = useAdminVerificationsStore()
const feedbackStore = useAdminFeedbackStore()
const confirm = useConfirm()
const toast = useToast()

// Reactive data
const allUsers = ref([])
const filteredUsers = ref([])
const searchQuery = ref('')
const selectedVerificationStatus = ref(null)
const selectedUserRole = ref(null)
const currentPage = ref(0)
const pageSize = ref(20)
const registrationDateRange = ref(null)

// Dialog states
const showUserDetailsDialog = ref(false)
const showRoleDialog = ref(false)
const showManualVerificationDialog = ref(false)
const selectedUser = ref(null)
const newUserRole = ref('')
const roleChangeReason = ref('')
const manualVerificationStatus = ref('')
const manualVerificationFullName = ref('')
const manualVerificationNotes = ref('')

// Computed
const userStats = computed(() => {
  const total = allUsers.value.length
  const verified = allUsers.value.filter(u => u.verification_status === 'APPROVED').length
  const pending = allUsers.value.filter(u => u.verification_status === 'PENDING_REVIEW').length
  const activeThisMonth = allUsers.value.filter(u => {
    const lastSignIn = new Date(u.last_sign_in_at)
    const monthAgo = new Date()
    monthAgo.setMonth(monthAgo.getMonth() - 1)
    return lastSignIn > monthAgo
  }).length

  return {
    total_users: total,
    verified_users: verified,
    pending_verifications: pending,
    active_this_month: activeThisMonth
  }
})

const verificationRate = computed(() => {
  if (userStats.value.total_users === 0) return 0
  return Math.round((userStats.value.verified_users / userStats.value.total_users) * 100)
})

const paginatedUsers = computed(() => {
  const start = currentPage.value * pageSize.value
  const end = start + pageSize.value
  return filteredUsers.value.slice(start, end)
})

const hasActiveFilters = computed(() => {
  return searchQuery.value || selectedVerificationStatus.value || selectedUserRole.value || 
         (registrationDateRange.value && registrationDateRange.value.length === 2)
})

// Options
const verificationStatusOptions = [
  { label: 'All Statuses', value: null },
  { label: 'Not Submitted', value: 'NOT_SUBMITTED' },
  { label: 'Pending Review', value: 'PENDING_REVIEW' },
  { label: 'Approved', value: 'APPROVED' },
  { label: 'Rejected', value: 'REJECTED' }
]

const userRoleOptions = [
  { label: 'All Roles', value: null },
  { label: 'Card Issuer', value: 'cardIssuer' },
  { label: 'Admin', value: 'admin' },
  { label: 'User', value: 'user' }
]

const roleChangeOptions = [
  { label: 'Card Issuer', value: 'cardIssuer' },
  { label: 'Admin', value: 'admin' },
  { label: 'User', value: 'user' }
]

const manualVerificationOptions = [
  { label: 'Not Submitted', value: 'NOT_SUBMITTED' },
  { label: 'Pending Review', value: 'PENDING_REVIEW' },
  { label: 'Approved', value: 'APPROVED' },
  { label: 'Rejected', value: 'REJECTED' }
]

// Methods
const refreshData = async () => {
  try {
    await verificationsStore.loadUsersWithDetails()
    allUsers.value = verificationsStore.allUsers || []
    filterUsers()
  } catch (error) {
    console.error('Failed to refresh user data:', error)
    toast.add({
      severity: 'error',
      summary: 'Error',
      detail: 'Failed to load user data',
      life: 3000
    })
  }
}

const filterUsers = () => {
  let filtered = [...allUsers.value]

  // Search filter
  if (searchQuery.value) {
    const query = searchQuery.value.toLowerCase()
    filtered = filtered.filter(user => 
      (user.public_name || '').toLowerCase().includes(query) ||
      (user.user_email || '').toLowerCase().includes(query) ||
      (user.company_name || '').toLowerCase().includes(query)
    )
  }

  // Verification status filter
  if (selectedVerificationStatus.value) {
    filtered = filtered.filter(user => user.verification_status === selectedVerificationStatus.value)
  }

  // Role filter
  if (selectedUserRole.value) {
    filtered = filtered.filter(user => (user.role || 'cardIssuer') === selectedUserRole.value)
  }

  // Registration date range filter
  if (registrationDateRange.value && registrationDateRange.value.length === 2) {
    const [startDate, endDate] = registrationDateRange.value
    filtered = filtered.filter(user => {
      const createdDate = new Date(user.created_at)
      return createdDate >= startDate && createdDate <= endDate
    })
  }

  filteredUsers.value = filtered
  currentPage.value = 0
}

const debouncedSearch = (() => {
  let timeout
  return () => {
    clearTimeout(timeout)
    timeout = setTimeout(filterUsers, 300)
  }
})()

const clearFilters = () => {
  searchQuery.value = ''
  selectedVerificationStatus.value = null
  selectedUserRole.value = null
  registrationDateRange.value = null
  filterUsers()
}

const onPageChange = (event) => {
  currentPage.value = event.page
  pageSize.value = event.rows
}

const exportUsers = () => {
  const csvData = filteredUsers.value.map(user => ({
    Email: user.user_email,
    'Public Name': user.public_name || '',
    'Company': user.company_name || '',
    'Role': user.role || 'cardIssuer',
    'Verification Status': user.verification_status,
    'Verified Date': user.verified_at ? formatDate(user.verified_at) : '',
    'Created Date': formatDate(user.created_at),
    'Last Sign In': user.last_sign_in_at ? formatDate(user.last_sign_in_at) : 'Never',
    'Cards Count': user.cards_count || 0,
    'Issued Cards': user.issued_cards_count || 0
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

// User management methods
const viewUserDetails = (user) => {
  selectedUser.value = user
  showUserDetailsDialog.value = true
}

const closeUserDetailsDialog = () => {
  selectedUser.value = null
  showUserDetailsDialog.value = false
}

const manageVerification = (user) => {
  // Navigate to verification management with specific user
  verificationsStore.setSelectedVerificationUser(user)
  window.open(`/admin/verifications?user=${user.user_id}`, '_blank')
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

const handleRoleUpdate = async () => {
  if (!selectedUser.value || !newUserRole.value) {
    return Promise.reject('Invalid role selection')
  }

  if (newUserRole.value === (selectedUser.value.role || 'cardIssuer')) {
    return Promise.reject('New role is the same as current role')
  }

  if (!roleChangeReason.value.trim()) {
    return Promise.reject('Please provide a reason for the role change')
  }

  try {
    await verificationsStore.updateUserRole(
      selectedUser.value.user_email,
      newUserRole.value,
      roleChangeReason.value.trim()
    )
    
    await refreshData()
    return Promise.resolve()
  } catch (error) {
    return Promise.reject(error.message || 'Failed to update user role')
  }
}

const confirmResetVerification = (user) => {
  confirm.require({
    group: 'resetVerification',
    message: `Are you sure you want to reset the verification status for ${user.public_name || user.user_email}? This will change their status back to "Not Submitted" and remove all verification data.`,
    header: 'Reset Verification',
    icon: 'pi pi-exclamation-triangle',
    acceptLabel: 'Reset',
    rejectLabel: 'Cancel',
    acceptClass: 'p-button-danger',
    accept: () => resetUserVerification(user)
  })
}

const resetUserVerification = async (user) => {
  try {
    await verificationsStore.resetUserVerification(user.user_id)
    await refreshData()
    toast.add({
      severity: 'success',
      summary: 'Success',
      detail: 'User verification status has been reset',
      life: 3000
    })
  } catch (error) {
    toast.add({
      severity: 'error',
      summary: 'Error',
      detail: error.message || 'Failed to reset verification',
      life: 3000
    })
  }
}

const handleManualVerification = async () => {
  if (!selectedUser.value || !manualVerificationStatus.value) {
    return Promise.reject('Invalid verification status selection')
  }

  if (!manualVerificationNotes.value.trim()) {
    return Promise.reject('Admin notes are required')
  }

  try {
    await verificationsStore.manualVerification(
      selectedUser.value.user_id,
      manualVerificationStatus.value,
      manualVerificationNotes.value.trim(),
      manualVerificationFullName.value || undefined
    )
    
    await refreshData()
    return Promise.resolve()
  } catch (error) {
    return Promise.reject(error.message || 'Failed to update user verification')
  }
}

const manualVerifyUser = (user) => {
  selectedUser.value = user
  manualVerificationStatus.value = 'APPROVED' // Default to approved for new verifications
  manualVerificationFullName.value = user.full_name || ''
  manualVerificationNotes.value = ''
  showManualVerificationDialog.value = true
}

const editVerificationNotes = (user) => {
  selectedUser.value = user
  manualVerificationStatus.value = user.verification_status
  manualVerificationFullName.value = user.full_name || ''
  manualVerificationNotes.value = user.admin_feedback || ''
  showManualVerificationDialog.value = true
}

const closeManualVerificationDialog = () => {
  selectedUser.value = null
  manualVerificationStatus.value = ''
  manualVerificationFullName.value = ''
  manualVerificationNotes.value = ''
  showManualVerificationDialog.value = false
}

// Utility methods
const formatDate = (dateString) => {
  return new Date(dateString).toLocaleDateString('en-US', {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit'
  })
}

const getUserInitials = (name) => {
  if (!name) return 'U'
  return name.split(' ').map(n => n[0]).join('').toUpperCase().slice(0, 2)
}

const getUserAvatarClass = (name) => {
  const colors = [
    'bg-blue-500', 'bg-green-500', 'bg-purple-500', 'bg-pink-500',
    'bg-indigo-500', 'bg-yellow-500', 'bg-red-500', 'bg-teal-500'
  ]
  const hash = (name || '').split('').reduce((a, b) => a + b.charCodeAt(0), 0)
  return colors[hash % colors.length]
}

const getVerificationStatusLabel = (status) => {
  const labels = {
    'NOT_SUBMITTED': 'Not Submitted',
    'PENDING_REVIEW': 'Pending Review',
    'APPROVED': 'Approved',
    'REJECTED': 'Rejected'
  }
  return labels[status] || status
}

const getVerificationSeverity = (status) => {
  const severities = {
    'NOT_SUBMITTED': 'secondary',
    'PENDING_REVIEW': 'warning',
    'APPROVED': 'success',
    'REJECTED': 'danger'
  }
  return severities[status] || 'secondary'
}

const getRoleSeverity = (role) => {
  const severities = {
    'admin': 'danger',
    'cardIssuer': 'primary',
    'user': 'secondary'
  }
  return severities[role] || 'primary'
}

const getDocumentName = (url) => {
  try {
    const urlParts = url.split('/')
    return urlParts[urlParts.length - 1] || 'Document'
  } catch {
    return 'Document'
  }
}

const viewDocument = (documentUrl) => {
  window.open(documentUrl, '_blank')
}

// Watchers
watch([selectedVerificationStatus, selectedUserRole], filterUsers)

// Initialize
onMounted(() => {
  refreshData()
})
</script>

<style scoped>
/* Component-specific styles - global table theme now handles standard styling */

/* Responsive adjustments */
@media (max-width: 768px) {
  :deep(.p-datatable .p-datatable-tbody > tr > td) {
    padding: 0.5rem;
  }
}
</style> 