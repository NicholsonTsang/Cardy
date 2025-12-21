import { defineStore } from 'pinia'
import { ref } from 'vue'
import { supabase } from '@/lib/supabase'

export interface AdminUserInfo {
  user_id: string
  email: string
  role: string
  created_at: string
}

export interface AdminUserCard {
  id: string
  user_id?: string // Injected from currentUser when needed
  card_name: string // Alias for name
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
  content_mode: 'single' | 'list' | 'grid' | 'cards'
  is_grouped: boolean
  group_display: 'expanded' | 'collapsed'
  billing_type: 'physical' | 'digital'
  max_scans: number | null
  current_scans: number
  daily_scan_limit: number | null
  daily_scans: number
  is_access_enabled: boolean
  access_token: string
  translations: Record<string, any> | null
  original_language: string | null
  batches_count: number
  created_at: string
  updated_at: string
  user_email: string
}

export interface AdminCardContent {
  id: string
  card_id: string
  parent_id: string | null
  name: string
  content: string | null
  image_url: string | null
  original_image_url: string | null
  crop_parameters: any
  ai_knowledge_base: string | null
  sort_order: number
  created_at: string
  updated_at: string
}

export interface AdminCardBatch {
  id: string
  card_id: string
  batch_name: string
  batch_number: number
  payment_status: 'PAID' | 'FREE'  // PAID = credits, FREE = admin-issued
  is_disabled: boolean
  cards_count: number
  created_at: string
  updated_at: string
}

export interface AdminBatchIssuedCard {
  id: string
  batch_id: string
  card_id: string
  active: boolean
  issue_at: string
  active_at: string | null
}

export const useAdminUserCardsStore = defineStore('adminUserCards', () => {
  // State
  const currentUser = ref<AdminUserInfo | null>(null)
  const userCards = ref<AdminUserCard[]>([])
  const selectedCardContent = ref<AdminCardContent[]>([])
  const selectedCardBatches = ref<AdminCardBatch[]>([])
  const batchIssuedCards = ref<Map<string, AdminBatchIssuedCard[]>>(new Map())
  const isLoading = ref(false)
  const isLoadingCards = ref(false)
  const isLoadingContent = ref(false)
  const isLoadingBatches = ref(false)
  const error = ref<string | null>(null)

  // Actions
  const searchUserByEmail = async (email: string): Promise<AdminUserInfo | null> => {
    isLoading.value = true
    error.value = null
    
    try {
      const { data, error: searchError } = await supabase.rpc('admin_get_user_by_email', {
        p_email: email
      })

      if (searchError) throw searchError

      if (!data || data.length === 0) {
        error.value = 'User not found'
        currentUser.value = null
        userCards.value = []
        return null
      }

      currentUser.value = data[0]
      return data[0]
    } catch (err: any) {
      console.error('Error searching user:', err)
      error.value = err.message || 'Failed to search user'
      currentUser.value = null
      userCards.value = []
      throw err
    } finally {
      isLoading.value = false
    }
  }

  const fetchUserCards = async (userId: string): Promise<AdminUserCard[]> => {
    isLoadingCards.value = true
    error.value = null
    
    try {
      const { data, error: fetchError } = await supabase.rpc('admin_get_user_cards', {
        p_user_id: userId
      })

      if (fetchError) throw fetchError

      userCards.value = data || []
      return userCards.value
    } catch (err: any) {
      console.error('Error fetching user cards:', err)
      error.value = err.message || 'Failed to fetch user cards'
      userCards.value = []
      throw err
    } finally {
      isLoadingCards.value = false
    }
  }

  const fetchCardContent = async (cardId: string): Promise<AdminCardContent[]> => {
    isLoadingContent.value = true
    error.value = null
    
    try {
      const { data, error: fetchError } = await supabase.rpc('admin_get_card_content', {
        p_card_id: cardId
      })

      if (fetchError) throw fetchError

      selectedCardContent.value = data || []
      return selectedCardContent.value
    } catch (err: any) {
      console.error('Error fetching card content:', err)
      error.value = err.message || 'Failed to fetch card content'
      selectedCardContent.value = []
      throw err
    } finally {
      isLoadingContent.value = false
    }
  }

  const fetchCardBatches = async (cardId: string): Promise<AdminCardBatch[]> => {
    isLoadingBatches.value = true
    error.value = null
    
    try {
      const { data, error: fetchError } = await supabase.rpc('admin_get_card_batches', {
        p_card_id: cardId
      })

      if (fetchError) throw fetchError

      selectedCardBatches.value = data || []
      return selectedCardBatches.value
    } catch (err: any) {
      console.error('Error fetching card batches:', err)
      error.value = err.message || 'Failed to fetch card batches'
      selectedCardBatches.value = []
      throw err
    } finally {
      isLoadingBatches.value = false
    }
  }

  const fetchBatchIssuedCards = async (batchId: string): Promise<AdminBatchIssuedCard[]> => {
    try {
      const { data, error: fetchError } = await supabase.rpc('admin_get_batch_issued_cards', {
        p_batch_id: batchId
      })

      if (fetchError) throw fetchError

      const cards = data || []
      batchIssuedCards.value.set(batchId, cards)
      return cards
    } catch (err: any) {
      console.error('Error fetching batch issued cards:', err)
      throw err
    }
  }

  const clearCurrentUser = () => {
    currentUser.value = null
    userCards.value = []
    selectedCardContent.value = []
    selectedCardBatches.value = []
    batchIssuedCards.value.clear()
    error.value = null
  }

  const clearSelectedCard = () => {
    selectedCardContent.value = []
    selectedCardBatches.value = []
    batchIssuedCards.value.clear()
  }

  return {
    // State
    currentUser,
    userCards,
    selectedCardContent,
    selectedCardBatches,
    batchIssuedCards,
    isLoading,
    isLoadingCards,
    isLoadingContent,
    isLoadingBatches,
    error,
    // Actions
    searchUserByEmail,
    fetchUserCards,
    fetchCardContent,
    fetchCardBatches,
    fetchBatchIssuedCards,
    clearCurrentUser,
    clearSelectedCard
  }
})

