import { defineStore } from 'pinia'
import { ref } from 'vue'
import { supabase } from '@/lib/supabase'

export interface AdminFeedback {
  id: string;
  admin_user_id: string;
  admin_email: string;
  content: string;
  version_number: number;
  action_context: any;
  created_at: string;
  updated_at: string;
}

export interface AdminAuditLog {
  id: string;
  admin_user_id: string;
  admin_email: string;
  target_user_id: string;
  target_user_email: string;
  action_type: string;
  reason: string;
  old_values: any;
  new_values: any;
  action_details: any;
  created_at: string;
}

export const useAdminFeedbackStore = defineStore('adminFeedback', () => {
  // State
  const feedbackHistory = ref<AdminFeedback[]>([])
  const auditLogs = ref<AdminAuditLog[]>([])
  const isLoadingFeedback = ref(false)
  const isLoadingAudit = ref(false)

  // Feedback Management Actions
  const createOrUpdateFeedback = async (
    targetEntityType: string,
    targetEntityId: string,
    targetUserId: string,
    feedbackType: string,
    content: string,
    actionContext?: any
  ) => {
    try {
      const { data, error } = await supabase.rpc('create_or_update_admin_feedback', {
        p_target_entity_type: targetEntityType,
        p_target_entity_id: targetEntityId,
        p_target_user_id: targetUserId,
        p_feedback_type: feedbackType,
        p_content: content,
        p_action_context: actionContext || null
      })
      
      if (error) throw error
      return data
    } catch (error) {
      console.error('Error creating/updating feedback:', error)
      throw error
    }
  }

  const getCurrentFeedback = async (
    targetEntityType: string,
    targetEntityId: string,
    feedbackType: string
  ) => {
    try {
      const { data, error } = await supabase.rpc('get_current_admin_feedback', {
        p_target_entity_type: targetEntityType,
        p_target_entity_id: targetEntityId,
        p_feedback_type: feedbackType
      })
      
      if (error) throw error
      return data || []
    } catch (error) {
      console.error('Error fetching current feedback:', error)
      throw error
    }
  }

  const getFeedbackHistory = async (
    targetEntityType: string,
    targetEntityId: string,
    feedbackType: string
  ) => {
    isLoadingFeedback.value = true
    try {
      const { data, error } = await supabase.rpc('get_admin_feedback_history', {
        p_target_entity_type: targetEntityType,
        p_target_entity_id: targetEntityId,
        p_feedback_type: feedbackType
      })
      
      if (error) throw error
      
      feedbackHistory.value = data || []
      return data || []
    } catch (error) {
      console.error('Error fetching feedback history:', error)
      throw error
    } finally {
      isLoadingFeedback.value = false
    }
  }

  const getUserFeedbackSummary = async (userId: string) => {
    try {
      const { data, error } = await supabase.rpc('get_user_feedback_summary', {
        p_target_user_id: userId
      })
      if (error) throw error
      return data || []
    } catch (error) {
      console.error('Error fetching user feedback summary:', error)
      throw error
    }
  }

  // Audit Logs Management
  const getAdminAuditLogs = async ({
    action_type = null,
    admin_user_id = null,
    target_user_id = null,
    start_date = null,
    end_date = null,
    limit = 50,
    offset = 0
  } = {}) => {
    isLoadingAudit.value = true
    try {
      const { data, error } = await supabase.rpc('get_admin_audit_logs', {
        p_action_type: action_type,
        p_admin_user_id: admin_user_id || null,
        p_target_user_id: target_user_id || null,
        p_start_date: start_date,
        p_end_date: end_date,
        p_limit: limit,
        p_offset: offset
      })
      
      if (error) throw error
      
      auditLogs.value = data || []
      return data || []
    } catch (error) {
      console.error('Error fetching audit logs:', error)
      throw error
    } finally {
      isLoadingAudit.value = false
    }
  }

  const getAdminAuditLogsCount = async ({
    action_type = null,
    admin_user_id = null,
    target_user_id = null,
    start_date = null,
    end_date = null
  } = {}) => {
    try {
      const { data, error } = await supabase.rpc('get_admin_audit_logs_count', {
        p_action_type: action_type,
        p_admin_user_id: admin_user_id || null,
        p_target_user_id: target_user_id || null,
        p_start_date: start_date,
        p_end_date: end_date
      })
      
      if (error) throw error
      return data || 0
    } catch (error) {
      console.error('Error fetching audit logs count:', error)
      throw error
    }
  }

  const getAdminFeedbackHistory = async ({
    target_entity_type = null,
    target_entity_id = null,
    feedback_type = null
  } = {}) => {
    try {
      const { data, error } = await supabase.rpc('get_admin_feedback_history', {
        p_target_entity_type: target_entity_type,
        p_target_entity_id: target_entity_id,
        p_feedback_type: feedback_type
      })
      
      if (error) throw error
      return data || []
    } catch (error) {
      console.error('Error fetching feedback history:', error)
      throw error
    }
  }

  // Utility functions
  const getActionTypeLabel = (actionType: string): string => {
    const labels: Record<string, string> = {
      'ROLE_CHANGE': 'Role Change',
      'VERIFICATION_REVIEW': 'Verification Review',
      'MANUAL_VERIFICATION': 'Manual Verification',
      'PRINT_REQUEST_UPDATE': 'Print Request Update',
      'BATCH_PAYMENT_WAIVER': 'Batch Payment Waiver',
      'SYSTEM_CONFIG': 'System Configuration',
      'USER_MANAGEMENT': 'User Management'
    }
    return labels[actionType] || actionType
  }

  const getActionTypeColor = (actionType: string): string => {
    const colors: Record<string, string> = {
      'ROLE_CHANGE': 'bg-yellow-500',
      'VERIFICATION_REVIEW': 'bg-green-500',
      'MANUAL_VERIFICATION': 'bg-blue-500',
      'PRINT_REQUEST_UPDATE': 'bg-purple-500',
      'BATCH_PAYMENT_WAIVER': 'bg-orange-500',
      'SYSTEM_CONFIG': 'bg-red-500',
      'USER_MANAGEMENT': 'bg-indigo-500'
    }
    return colors[actionType] || 'bg-slate-500'
  }

  return {
    // State
    feedbackHistory,
    auditLogs,
    isLoadingFeedback,
    isLoadingAudit,
    
    // Feedback Actions
    createOrUpdateFeedback,
    getCurrentFeedback,
    getFeedbackHistory,
    getUserFeedbackSummary,
    
    // Audit Actions
    getAdminAuditLogs,
    getAdminAuditLogsCount,
    getAdminFeedbackHistory,
    
    // Utilities
    getActionTypeLabel,
    getActionTypeColor
  }
}) 