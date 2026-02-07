<template>
  <PageWrapper 
    :title="$t('admin.user_cards_viewer')" 
    :description="$t('admin.user_cards_viewer_desc')">
    
    <!-- User Search Section -->
    <div class="bg-white rounded-xl shadow-lg border border-slate-200 p-6 mb-6">
      <div class="flex items-center gap-4 mb-4">
        <div class="flex-1">
          <label class="block text-sm font-medium text-slate-700 mb-2">
            <i class="pi pi-search mr-2"></i>
            {{ $t('admin.search_user_by_email') }}
          </label>
          <div class="flex gap-3">
            <IconField class="flex-1">
              <InputIcon>
                <i class="pi pi-envelope" />
              </InputIcon>
              <InputText
                v-model="searchEmail"
                :placeholder="$t('admin.enter_user_email_address')"
                class="w-full"
                :disabled="isLoading"
                @keyup.enter="handleSearchUser"
              />
            </IconField>
            <Button
              :label="$t('common.search')"
              icon="pi pi-search"
              @click="handleSearchUser"
              :loading="isLoading"
              severity="primary"
            />
            <Button
              v-if="currentUser"
              :label="$t('common.clear')"
              icon="pi pi-times"
              @click="handleClearSearch"
              severity="secondary"
              outlined
            />
          </div>
        </div>
      </div>

      <!-- Current User Info -->
      <div v-if="currentUser" class="mt-4 p-4 bg-gradient-to-r from-blue-50 to-indigo-50 border border-blue-200 rounded-xl">
        <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
          <div class="flex items-center gap-3">
            <div class="w-12 h-12 rounded-xl bg-gradient-to-br from-blue-500 to-indigo-600 flex items-center justify-center shadow-lg">
              <i class="pi pi-user text-white text-lg"></i>
            </div>
            <div>
              <p class="font-semibold text-slate-900">{{ currentUser.email }}</p>
              <div class="flex items-center gap-2 text-sm text-slate-600 flex-wrap">
                <span 
                  class="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs font-medium"
                  :class="currentUser.role === 'admin' ? 'bg-red-100 text-red-700' : 'bg-blue-100 text-blue-700'"
                >
                  {{ currentUser.role }}
                </span>
                <span 
                  class="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs font-medium"
                  :class="{
                    'bg-amber-100 text-amber-700': currentUser.subscription_tier === 'premium',
                    'bg-emerald-100 text-emerald-700': currentUser.subscription_tier === 'starter',
                    'bg-slate-100 text-slate-700': currentUser.subscription_tier === 'free' || !currentUser.subscription_tier
                  }"
                >
                  <i :class="{
                    'pi pi-star-fill': currentUser.subscription_tier === 'premium',
                    'pi pi-bolt': currentUser.subscription_tier === 'starter',
                    'pi pi-user': currentUser.subscription_tier === 'free' || !currentUser.subscription_tier
                  }" style="font-size: 0.6rem;"></i>
                  {{ currentUser.subscription_tier || 'free' }}
                </span>
                <span class="text-slate-400">•</span>
                <span>{{ $t('admin.registered') }} {{ formatDate(currentUser.created_at) }}</span>
              </div>
            </div>
          </div>
          
          <!-- Card Stats Summary -->
          <div class="flex items-center gap-3 sm:gap-4">
            <div class="text-center px-3 py-1.5 bg-white rounded-lg border border-slate-200 shadow-sm">
              <p class="text-lg font-bold text-slate-900">{{ userCards.length }}</p>
              <p class="text-[10px] text-slate-500 uppercase">{{ $t('batches.cards') }}</p>
            </div>
            <div class="text-center px-3 py-1.5 bg-white rounded-lg border border-purple-200 shadow-sm">
              <p class="text-lg font-bold text-purple-600">{{ physicalCardsCount }}</p>
              <p class="text-[10px] text-slate-500 uppercase">{{ $t('admin.physical') }}</p>
            </div>
            <div class="text-center px-3 py-1.5 bg-white rounded-lg border border-cyan-200 shadow-sm">
              <p class="text-lg font-bold text-cyan-600">{{ digitalCardsCount }}</p>
              <p class="text-[10px] text-slate-500 uppercase">{{ $t('admin.digital') }}</p>
            </div>
            <div class="hidden sm:flex items-center gap-1 text-xs text-slate-400 ml-2">
              <i class="pi pi-eye"></i>
              {{ $t('admin.read_only_view') }}
            </div>
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
          :selectedCard="selectedCard as any"
          :content="selectedCardContent as any"
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
      <h3 class="text-xl font-semibold text-slate-700 mb-2">{{ $t('admin.search_for_user') }}</h3>
      <p class="text-slate-500">{{ $t('admin.enter_email_to_view_cards') }}</p>
    </div>
  </PageWrapper>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import { useI18n } from 'vue-i18n'
import { useAdminUserCardsStore } from '@/stores/admin/userCards'
import { storeToRefs } from 'pinia'
import { useToast } from 'primevue/usetoast'
import PageWrapper from '@/components/Layout/PageWrapper.vue'
import Button from 'primevue/button'
import InputText from 'primevue/inputtext'
import IconField from 'primevue/iconfield'
import InputIcon from 'primevue/inputicon'
import AdminCardListPanel from '@/components/Admin/AdminCardListPanel.vue'
import AdminCardDetailPanel from '@/components/Admin/AdminCardDetailPanel.vue'
import { formatDate } from '@/utils/formatters'

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
const { t } = useI18n()

// Component state
const searchEmail = ref('')
const selectedCardId = ref<string | null>(null)
const activeTab = ref(0)

// Computed
const selectedCard = computed(() => {
  if (!selectedCardId.value) return null
  const card = userCards.value.find(c => c.id === selectedCardId.value)
  if (!card) return null
  // Inject user_id from currentUser for components that need it (e.g., DigitalAccessQR)
  return {
    ...card,
    user_id: currentUser.value?.user_id || '',
    // Ensure non-null values for required fields
    description: card.description || '',
    ai_instruction: card.ai_instruction || '',
    ai_knowledge_base: card.ai_knowledge_base || ''
  }
})

const physicalCardsCount = computed(() => {
  return userCards.value.filter(c => c.billing_type === 'physical').length
})

const digitalCardsCount = computed(() => {
  return userCards.value.filter(c => c.billing_type === 'digital').length
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
      summary: t('common.email_required'),
      detail: t('admin.please_enter_email'),
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
        summary: t('admin.user_found'),
        detail: t('admin.loaded_cards', { count: userCards.value.length, email: user.email }),
        life: 3000
      })
    }
  } catch (err: any) {
    toast.add({
      severity: 'error',
      summary: t('admin.search_failed'),
      detail: err.message || t('admin.failed_to_search_user'),
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
      summary: t('messages.load_failed'),
      detail: t('messages.failed_to_load_card_details'),
      life: 3000
    })
  }
}

</script>

<style scoped>
/* Component styles are handled by child components */
</style>

