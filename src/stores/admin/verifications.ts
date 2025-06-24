import { defineStore } from 'pinia'
import { ref, computed, readonly } from 'vue'
import { supabase } from '@/lib/supabase'

export interface AdminVerification {
  user_id: string;
  user_email: string;
  public_name: string;
  bio: string;
  company_name: string;
  full_name: string;
  verification_status: string;
  supporting_documents: string[];
  admin_feedback: string;
  verified_at: string;
  created_at: string;
  updated_at: string;
}

export interface AdminUser {
  user_id: string
  user_email: string
  role?: string
  public_name?: string
  bio?: string
  company_name?: string
  full_name?: string
  verification_status: 'NOT_SUBMITTED' | 'PENDING_REVIEW' | 'APPROVED' | 'REJECTED'
  supporting_documents?: string[]
  admin_feedback?: string
  verified_at?: string
  created_at: string
  updated_at?: string
  last_sign_in_at?: string
  cards_count?: number
  issued_cards_count?: number
  print_requests_count?: number
}

export interface AdminUserActivity {
  total_cards: number
  published_cards: number
  total_batches: number
  total_issued_cards: number
  activated_cards: number
  total_print_requests: number
  completed_print_requests: number
  last_card_created?: string
  last_batch_created?: string
  last_print_request?: string
}

export const useAdminVerificationsStore = defineStore('adminVerifications', () => {
  // State
  const pendingVerifications = ref<AdminVerification[]>([])
  const allVerifications = ref<AdminVerification[]>([])
  const allUsers = ref<AdminUser[]>([])
  const selectedVerificationUser = ref<AdminUser | null>(null)
  const isLoadingVerifications = ref(false)
  const isLoading = ref(false)

  // Computed
  const pendingVerificationCount = computed(() => pendingVerifications.value.length)

  // Actions
  const fetchPendingVerifications = async (): Promise<AdminVerification[]> => {
    isLoadingVerifications.value = true
    try {
      const { data, error } = await supabase.rpc('get_all_pending_verifications')
      if (error) throw error
      
      pendingVerifications.value = data || []
      return data || []
    } catch (error) {
      console.error('Error fetching pending verifications:', error)
      throw error
    } finally {
      isLoadingVerifications.value = false
    }
  }

  const fetchAllVerifications = async (status?: string): Promise<AdminVerification[]> => {
    isLoadingVerifications.value = true
    try {
      const { data, error } = await supabase.rpc('get_all_verifications', {
        p_status: status || null
      })
      if (error) throw error
      
      allVerifications.value = data || []
      return data || []
    } catch (error) {
      console.error('Error fetching all verifications:', error)
      throw error
    } finally {
      isLoadingVerifications.value = false
    }
  }

  const fetchVerificationById = async (userId: string): Promise<AdminVerification | null> => {
    try {
      const { data, error } = await supabase.rpc('get_verification_by_id', {
        p_user_id: userId
      })
      if (error) throw error
      
      return data?.[0] || null
    } catch (error) {
      console.error('Error fetching verification by ID:', error)
      throw error
    }
  }

  const reviewVerification = async (
    userId: string, 
    status: 'APPROVED' | 'REJECTED', 
    feedback: string
  ): Promise<boolean> => {
    try {
      const { data, error } = await supabase.rpc('review_verification', {
        p_target_user_id: userId,
        p_new_status: status,
        p_admin_feedback: feedback
      })
      
      if (error) throw error
      
      // Refresh pending verifications
      await fetchPendingVerifications()
      
      return data
    } catch (error) {
      console.error('Error reviewing verification:', error)
      throw error
    }
  }

  const loadUsersWithDetails = async () => {
    isLoading.value = true
    try {
      const { data, error } = await supabase.rpc('get_all_users_with_details')
      
      if (error) throw error
      
      allUsers.value = data || []
      return data || []
    } catch (error) {
      console.error('Error loading users:', error)
      throw error
    } finally {
      isLoading.value = false
    }
  }

  const updateUserRole = async (userEmail: string, newRole: string, reason: string) => {
    isLoading.value = true
    try {
      const { data, error } = await supabase.rpc('update_user_role', {
        p_user_email: userEmail,
        p_new_role: newRole,
        p_reason: reason
      })
      
      if (error) throw error
      
      return data
    } catch (error) {
      console.error('Error updating user role:', error)
      throw error
    } finally {
      isLoading.value = false
    }
  }

  const resetUserVerification = async (userId: string) => {
    isLoading.value = true
    try {
      const { data, error } = await supabase.rpc('reset_user_verification', {
        p_user_id: userId
      })
      
      if (error) throw error
      
      return data
    } catch (error) {
      console.error('Error resetting user verification:', error)
      throw error
    } finally {
      isLoading.value = false
    }
  }

  const manualVerification = async (
    userId: string,
    status: 'APPROVED' | 'REJECTED' | 'NOT_SUBMITTED',
    adminFeedback: string,
    fullName?: string
  ) => {
    isLoading.value = true
    try {
      const { data, error } = await supabase.rpc('admin_manual_verification', {
        p_target_user_id: userId,
        p_new_status: status,
        p_admin_feedback: adminFeedback,
        p_full_name: fullName || null
      })
      
      if (error) throw error
      
      return data
    } catch (error) {
      console.error('Error performing manual verification:', error)
      throw error
    } finally {
      isLoading.value = false
    }
  }

  const getUserActivitySummary = async (userId: string): Promise<AdminUserActivity> => {
    isLoading.value = true
    try {
      const { data, error } = await supabase.rpc('get_user_activity_summary', {
        p_user_id: userId
      })
      
      if (error) throw error
      
      return data?.[0] || {
        total_cards: 0,
        published_cards: 0,
        total_batches: 0,
        total_issued_cards: 0,
        activated_cards: 0,
        total_print_requests: 0,
        completed_print_requests: 0
      }
    } catch (error) {
      console.error('Error loading user activity summary:', error)
      throw error
    } finally {
      isLoading.value = false
    }
  }

  const setSelectedVerificationUser = (user: AdminUser | null) => {
    selectedVerificationUser.value = user
  }

  return {
    // State
    pendingVerifications,
    allVerifications,
    allUsers: readonly(allUsers),
    selectedVerificationUser: readonly(selectedVerificationUser),
    isLoadingVerifications,
    isLoading,
    
    // Computed
    pendingVerificationCount,
    
    // Actions
    fetchPendingVerifications,
    fetchAllVerifications,
    fetchVerificationById,
    reviewVerification,
    loadUsersWithDetails,
    updateUserRole,
    resetUserVerification,
    manualVerification,
    getUserActivitySummary,
    setSelectedVerificationUser
  }
}) 