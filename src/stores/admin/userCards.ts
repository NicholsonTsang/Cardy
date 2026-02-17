import { defineStore } from 'pinia'
import { ref } from 'vue'
import { supabase } from '@/lib/supabase'

export interface AdminUserInfo {
  user_id: string
  email: string
  role: string
  created_at: string
  subscription_tier: string
  subscription_status: string
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
  billing_type: 'digital'
  default_daily_session_limit: number | null // Default for new QR codes
  metadata?: Record<string, any>
  // Aggregated from access tokens
  total_sessions: number
  daily_sessions: number
  active_qr_codes: number
  total_qr_codes: number
  translations: Record<string, any> | null
  original_language: string | null
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

export const useAdminUserCardsStore = defineStore('adminUserCards', () => {
  // State
  const currentUser = ref<AdminUserInfo | null>(null)
  const userCards = ref<AdminUserCard[]>([])
  const selectedCardContent = ref<AdminCardContent[]>([])
  const isLoading = ref(false)
  const isLoadingCards = ref(false)
  const isLoadingContent = ref(false)
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

  const clearCurrentUser = () => {
    currentUser.value = null
    userCards.value = []
    selectedCardContent.value = []
    error.value = null
  }

  const clearSelectedCard = () => {
    selectedCardContent.value = []
  }

  return {
    // State
    currentUser,
    userCards,
    selectedCardContent,
    isLoading,
    isLoadingCards,
    isLoadingContent,
    error,
    // Actions
    searchUserByEmail,
    fetchUserCards,
    fetchCardContent,
    clearCurrentUser,
    clearSelectedCard
  }
})

