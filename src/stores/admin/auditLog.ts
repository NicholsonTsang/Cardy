import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { supabase } from '@/lib/supabase'

// Simplified interfaces for basic audit log
export interface AuditLogEntry {
  id: string;
  admin_user_id: string;
  admin_email: string;
  target_user_id: string | null;
  target_user_email: string | null;
  action_type: string;
  description: string;
  details: any;
  created_at: string;
}

export interface AuditLogFilters {
  action_type: string | null;
  admin_user_id: string | null;
  target_user_id: string | null;
  start_date: Date | null;
  end_date: Date | null;
}

// Action types matching stored procedures
export const ACTION_TYPES = {
  USER_REGISTRATION: 'USER_REGISTRATION',
  CARD_CREATION: 'CARD_CREATION',
  CARD_UPDATE: 'CARD_UPDATE', 
  CARD_DELETION: 'CARD_DELETION',
  BATCH_STATUS_CHANGE: 'BATCH_STATUS_CHANGE',
  CARD_GENERATION: 'CARD_GENERATION',
  VERIFICATION_REVIEW: 'VERIFICATION_REVIEW',
  PRINT_REQUEST_UPDATE: 'PRINT_REQUEST_UPDATE',
  PRINT_REQUEST_WITHDRAWAL: 'PRINT_REQUEST_WITHDRAWAL',
  PAYMENT_WAIVER: 'PAYMENT_WAIVER',
  ROLE_CHANGE: 'ROLE_CHANGE'
} as const

export const useAuditLogStore = defineStore('auditLog', () => {
  // State
  const auditLogs = ref<AuditLogEntry[]>([])
  const isLoading = ref(false)
  const error = ref<string | null>(null)
  const totalCount = ref(0)

  // Actions
  const fetchAuditLogs = async (filters: Partial<AuditLogFilters> = {}, limit = 50, offset = 0): Promise<AuditLogEntry[]> => {
    isLoading.value = true
    error.value = null
    
    try {
      const { data, error: fetchError } = await supabase.rpc('get_admin_audit_logs', {
        p_action_type: filters.action_type || null,
        p_admin_user_id: filters.admin_user_id || null,
        p_target_user_id: filters.target_user_id || null,
        p_start_date: filters.start_date?.toISOString() || null,
        p_end_date: filters.end_date?.toISOString() || null,
        p_limit: limit,
        p_offset: offset
      })

      if (fetchError) throw fetchError

      auditLogs.value = data || []
      return data || []
    } catch (err: any) {
      console.error('Error fetching audit logs:', err)
      error.value = err.message || 'Failed to fetch audit logs'
      throw err
    } finally {
      isLoading.value = false
    }
  }

  const fetchAuditLogsCount = async (filters: Partial<AuditLogFilters> = {}): Promise<number> => {
    try {
      const { data, error: countError } = await supabase.rpc('get_admin_audit_logs_count', {
        p_action_type: filters.action_type || null,
        p_admin_user_id: filters.admin_user_id || null,
        p_target_user_id: filters.target_user_id || null,
        p_start_date: filters.start_date?.toISOString() || null,
        p_end_date: filters.end_date?.toISOString() || null
      })

      if (countError) throw countError

      totalCount.value = data || 0
      return data || 0
    } catch (err: any) {
      console.error('Error fetching audit logs count:', err)
      throw err
    }
  }

  const fetchRecentActivity = async (limit = 20): Promise<any[]> => {
    isLoading.value = true
    error.value = null

    try {
      const { data, error: fetchError } = await supabase.rpc('get_recent_admin_activity', {
        p_limit: limit
      })

      if (fetchError) throw fetchError

      return data || []
    } catch (err: any) {
      console.error('Error fetching recent activity:', err)
      error.value = err.message || 'Failed to fetch recent activity'
      return []
    } finally {
      isLoading.value = false
    }
  }

  // Utility functions
  const getActionTypeLabel = (actionType: string): string => {
    const labels: Record<string, string> = {
      'USER_REGISTRATION': 'User Registration',
      'ROLE_CHANGE': 'Role Change',
      'VERIFICATION_REVIEW': 'Verification Review',
      'VERIFICATION_RESET': 'Verification Reset',
      'MANUAL_VERIFICATION': 'Manual Verification',
      'PAYMENT_WAIVER': 'Payment Waiver',
      'PRINT_REQUEST_UPDATE': 'Print Request Update'
    }
    return labels[actionType] || actionType.replace('_', ' ')
  }

  const getActionTypeColor = (actionType: string): string => {
    const colors: Record<string, string> = {
      'USER_REGISTRATION': 'bg-green-500',
      'ROLE_CHANGE': 'bg-yellow-500',
      'VERIFICATION_REVIEW': 'bg-blue-500',
      'VERIFICATION_RESET': 'bg-blue-400',
      'MANUAL_VERIFICATION': 'bg-blue-600',
      'PAYMENT_WAIVER': 'bg-orange-500',
      'PRINT_REQUEST_UPDATE': 'bg-purple-500'
    }
    return colors[actionType] || 'bg-slate-500'
  }

  return {
    // State
    auditLogs,
    isLoading,
    error,
    totalCount,

    // Actions
    fetchAuditLogs,
    fetchAuditLogsCount,
    fetchRecentActivity,

    // Utilities
    getActionTypeLabel,
    getActionTypeColor
  }
})