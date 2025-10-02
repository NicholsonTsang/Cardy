<template>
  <PageWrapper 
    title="User Cards Viewer" 
    description="View card designs and content for any user by email (read-only)">
    
    <!-- User Search Section -->
    <div class="bg-white rounded-xl shadow-lg border border-slate-200 p-6 mb-6">
      <div class="flex items-center gap-4 mb-4">
        <div class="flex-1">
          <label class="block text-sm font-medium text-slate-700 mb-2">
            <i class="pi pi-search mr-2"></i>
            Search User by Email
          </label>
          <div class="flex gap-3">
            <IconField class="flex-1">
              <InputIcon>
                <i class="pi pi-envelope" />
              </InputIcon>
              <InputText
                v-model="searchEmail"
                placeholder="Enter user email address..."
                class="w-full"
                :disabled="isLoading"
                @keyup.enter="handleSearchUser"
              />
            </IconField>
            <Button
              label="Search"
              icon="pi pi-search"
              @click="handleSearchUser"
              :loading="isLoading"
              severity="primary"
            />
            <Button
              v-if="currentUser"
              label="Clear"
              icon="pi pi-times"
              @click="handleClearSearch"
              severity="secondary"
              outlined
            />
          </div>
        </div>
      </div>

      <!-- Current User Info -->
      <div v-if="currentUser" class="mt-4 p-4 bg-blue-50 border border-blue-200 rounded-lg">
        <div class="flex items-center justify-between">
          <div class="flex items-center gap-3">
            <div class="w-10 h-10 rounded-full bg-blue-500 flex items-center justify-center">
              <i class="pi pi-user text-white"></i>
            </div>
            <div>
              <p class="font-semibold text-slate-900">{{ currentUser.email }}</p>
              <div class="flex items-center gap-2 text-sm text-slate-600">
                <Tag :value="currentUser.role" severity="info" class="px-2 py-1 text-xs" />
                <span>•</span>
                <span>{{ userCards.length }} card{{ userCards.length !== 1 ? 's' : '' }}</span>
                <span>•</span>
                <span>Joined {{ formatDate(currentUser.created_at) }}</span>
              </div>
            </div>
          </div>
          <div class="text-xs text-slate-500">
            <i class="pi pi-eye mr-1"></i>
            Read-only view
          </div>
        </div>
      </div>

      <!-- Error Message -->
      <div v-if="error && !currentUser" class="mt-4 p-4 bg-red-50 border border-red-200 rounded-lg">
        <div class="flex items-center gap-2 text-red-700">
          <i class="pi pi-exclamation-circle"></i>
          <span>{{ error }}</span>
        </div>
      </div>
    </div>

    <!-- Cards Display -->
    <div v-if="currentUser" class="grid grid-cols-1 lg:grid-cols-4 gap-6 min-h-[calc(100vh-400px)]">
      <!-- Card List Panel (Read-only) -->
      <div class="lg:col-span-1">
        <AdminCardListPanel
          :cards="userCards"
          :selectedCardId="selectedCardId"
          :isLoading="isLoadingCards"
          @select-card="handleSelectCard"
        />
      </div>

      <!-- Card Detail Panel (Read-only) -->
      <div class="lg:col-span-3">
        <AdminCardDetailPanel
          :selectedCard="selectedCard"
          :content="selectedCardContent"
          :batches="selectedCardBatches"
          :isLoadingContent="isLoadingContent"
          :isLoadingBatches="isLoadingBatches"
          v-model:activeTab="activeTabString"
        />
      </div>
    </div>

    <!-- Empty State (No User Selected) -->
    <div v-else class="bg-white rounded-xl shadow-lg border border-slate-200 p-12 text-center">
      <i class="pi pi-search text-6xl text-slate-300 mb-4"></i>
      <h3 class="text-xl font-semibold text-slate-700 mb-2">Search for a User</h3>
      <p class="text-slate-500">Enter a user's email address above to view their cards</p>
    </div>
  </PageWrapper>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import { useAdminUserCardsStore } from '@/stores/admin/userCards'
import { storeToRefs } from 'pinia'
import { useToast } from 'primevue/usetoast'
import PageWrapper from '@/components/Layout/PageWrapper.vue'
import Button from 'primevue/button'
import InputText from 'primevue/inputtext'
import IconField from 'primevue/iconfield'
import InputIcon from 'primevue/inputicon'
import Tag from 'primevue/tag'
import AdminCardListPanel from '@/components/Admin/AdminCardListPanel.vue'
import AdminCardDetailPanel from '@/components/Admin/AdminCardDetailPanel.vue'

// Stores and composables
const adminUserCardsStore = useAdminUserCardsStore()
const {
  currentUser,
  userCards,
  selectedCardContent,
  selectedCardBatches,
  isLoading,
  isLoadingCards,
  isLoadingContent,
  isLoadingBatches,
  error
} = storeToRefs(adminUserCardsStore)

const toast = useToast()

// Component state
const searchEmail = ref('')
const selectedCardId = ref<string | null>(null)
const activeTab = ref(0)

// Computed
const selectedCard = computed(() => {
  if (!selectedCardId.value) return null
  return userCards.value.find(c => c.id === selectedCardId.value) || null
})

const activeTabString = computed({
  get: () => activeTab.value.toString(),
  set: (value: string) => {
    activeTab.value = parseInt(value)
  }
})

// Methods
const handleSearchUser = async () => {
  if (!searchEmail.value.trim()) {
    toast.add({
      severity: 'warn',
      summary: 'Email Required',
      detail: 'Please enter a user email address',
      life: 3000
    })
    return
  }

  try {
    const user = await adminUserCardsStore.searchUserByEmail(searchEmail.value.trim())
    if (user) {
      await adminUserCardsStore.fetchUserCards(user.user_id)
      selectedCardId.value = null
      
      toast.add({
        severity: 'success',
        summary: 'User Found',
        detail: `Loaded ${userCards.value.length} cards for ${user.email}`,
        life: 3000
      })
    }
  } catch (err: any) {
    toast.add({
      severity: 'error',
      summary: 'Search Failed',
      detail: err.message || 'Failed to search user',
      life: 5000
    })
  }
}

const handleClearSearch = () => {
  searchEmail.value = ''
  selectedCardId.value = null
  adminUserCardsStore.clearCurrentUser()
}

const handleSelectCard = async (cardId: string) => {
  selectedCardId.value = cardId
  activeTab.value = 0
  
  try {
    await Promise.all([
      adminUserCardsStore.fetchCardContent(cardId),
      adminUserCardsStore.fetchCardBatches(cardId)
    ])
  } catch (err: any) {
    toast.add({
      severity: 'error',
      summary: 'Load Failed',
      detail: 'Failed to load card details',
      life: 3000
    })
  }
}

const formatDate = (dateString: string) => {
  return new Date(dateString).toLocaleDateString('en-US', {
    month: 'short',
    day: 'numeric',
    year: 'numeric'
  })
}
</script>

<style scoped>
/* Component styles are handled by child components */
</style>

