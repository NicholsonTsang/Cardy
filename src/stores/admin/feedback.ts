import { defineStore } from 'pinia'
import { ref } from 'vue'
import { supabase } from '@/lib/supabase'

// Simplified feedback interface with foreign key relationships
export interface AdminFeedback {
  id: string;
  admin_user_id: string;
  admin_email: string;
  verification_user_id?: string;
  print_request_id?: string;
  message: string;
  created_at: string;
}

export const useAdminFeedbackStore = defineStore('adminFeedback', () => {
  // State
  const feedbackHistory = ref<AdminFeedback[]>([])
  const isLoading = ref(false)
  const error = ref<string | null>(null)

  // Actions
  const createFeedback = async (
    targetUserId: string,
    entityType: 'verification' | 'print_request',
    entityId: string,
    message: string
  ): Promise<string> => {
    isLoading.value = true
    error.value = null

    try {
      const { data, error: createError } = await supabase.rpc('create_admin_feedback', {
        p_target_user_id: targetUserId,
        p_entity_type: entityType,
        p_entity_id: entityId,
        p_message: message
      })

      if (createError) throw createError

      return data
    } catch (err: any) {
      console.error('Error creating feedback:', err)
      error.value = err.message || 'Failed to create feedback'
      throw err
    } finally {
      isLoading.value = false
    }
  }

  const getFeedbackHistory = async (
    entityType: 'verification' | 'print_request',
    entityId: string
  ): Promise<AdminFeedback[]> => {
    isLoading.value = true
    error.value = null

    try {
      const { data, error: fetchError } = await supabase.rpc('get_admin_feedback_history', {
        p_entity_type: entityType,
        p_entity_id: entityId
      })

      if (fetchError) throw fetchError

      feedbackHistory.value = data || []
      return data || []
    } catch (err: any) {
      console.error('Error fetching feedback history:', err)
      error.value = err.message || 'Failed to fetch feedback history'
      return []
    } finally {
      isLoading.value = false
    }
  }

  const clearFeedbackHistory = () => {
    feedbackHistory.value = []
    error.value = null
  }

  // New simplified functions for direct foreign key relationships
  const getVerificationFeedbacks = async (userId: string): Promise<AdminFeedback[]> => {
    isLoading.value = true
    error.value = null

    try {
      const { data, error: fetchError } = await supabase.rpc('get_verification_feedbacks', {
        p_user_id: userId
      })

      if (fetchError) throw fetchError

      feedbackHistory.value = data || []
      return data || []
    } catch (err: any) {
      console.error('Error fetching verification feedbacks:', err)
      error.value = err.message || 'Failed to fetch verification feedbacks'
      return []
    } finally {
      isLoading.value = false
    }
  }

  const getPrintRequestFeedbacks = async (requestId: string): Promise<AdminFeedback[]> => {
    isLoading.value = true
    error.value = null

    try {
      const { data, error: fetchError } = await supabase.rpc('get_print_request_feedbacks', {
        p_request_id: requestId
      })

      if (fetchError) throw fetchError

      feedbackHistory.value = data || []
      return data || []
    } catch (err: any) {
      console.error('Error fetching print request feedbacks:', err)
      error.value = err.message || 'Failed to fetch print request feedbacks'
      return []
    } finally {
      isLoading.value = false
    }
  }

  // Backward compatibility functions (for existing code)
  const createOrUpdateFeedback = async (
    targetEntityType: string,
    targetEntityId: string,
    targetUserId: string,
    feedbackType: string,
    content: string,
    actionContext?: any
  ) => {
    // Map to new simplified system
    const entityType = targetEntityType === 'user_profile' ? 'verification' : 'print_request'
    return createFeedback(targetUserId, entityType as any, targetEntityId, content)
  }

  return {
    // State
    feedbackHistory,
    isLoading,
    error,

    // New simplified actions
    createFeedback,
    getFeedbackHistory,
    clearFeedbackHistory,

    // Direct foreign key relationship functions
    getVerificationFeedbacks,
    getPrintRequestFeedbacks,

    // Backward compatibility
    createOrUpdateFeedback
  }
})