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
  search_query: string | null;
}

// Action types for UI (constants)
export const ACTION_TYPES = {
  // User Management
  USER_REGISTRATION: 'USER_REGISTRATION',
  ROLE_CHANGE: 'ROLE_CHANGE',
  SUBSCRIPTION_CHANGE: 'SUBSCRIPTION_CHANGE',
  
  // Card Management
  CARD_CREATION: 'CARD_CREATION',
  CARD_UPDATE: 'CARD_UPDATE', 
  CARD_DELETION: 'CARD_DELETION',
  CARD_ACTIVATION: 'CARD_ACTIVATION',
  CARD_GENERATION: 'CARD_GENERATION',
  
  // Content Management
  CONTENT_ITEM_CREATION: 'CONTENT_ITEM_CREATION',
  CONTENT_ITEM_UPDATE: 'CONTENT_ITEM_UPDATE',
  CONTENT_ITEM_DELETION: 'CONTENT_ITEM_DELETION',
  CONTENT_ITEM_REORDER: 'CONTENT_ITEM_REORDER',

  // Credit Management
  CREDIT_ADJUSTMENT: 'CREDIT_ADJUSTMENT',
  CREDIT_PURCHASE: 'CREDIT_PURCHASE',
  CREDIT_CONSUMPTION: 'CREDIT_CONSUMPTION'
} as const

// Map ACTION_TYPES to actual search keywords in operation logs
// This is needed because logs store descriptive text, not action type constants
export const ACTION_TYPE_SEARCH_KEYWORDS: Record<string, string> = {
  // User Management
  USER_REGISTRATION: 'New user registered',  // Matches "New user registered: email" from handle_new_user trigger
  ROLE_CHANGE: 'Changed user role',
  SUBSCRIPTION_CHANGE: 'Admin changed subscription tier',  // Matches "Admin changed subscription tier from X to Y"
  
  // Card Management
  CARD_CREATION: 'Created',  // Matches "Created digital card:" and "Imported card" (legacy: "Created physical card:")
  CARD_UPDATE: 'Updated card:',
  CARD_DELETION: 'Deleted card:',
  CARD_ACTIVATION: 'activated',  // Legacy: matches "Activated issued card" and "Card auto-activated"
  CARD_GENERATION: 'Generated',  // Legacy: matches "Generated X cards for batch"
  
  // Content Management
  CONTENT_ITEM_CREATION: 'Created content item:',
  CONTENT_ITEM_UPDATE: 'Updated content item:',
  CONTENT_ITEM_DELETION: 'Deleted content item:',
  CONTENT_ITEM_REORDER: 'Reordered content item',

  // Credit Management
  CREDIT_ADJUSTMENT: 'Admin adjusted credits',
  CREDIT_PURCHASE: 'Credit purchase',
  CREDIT_CONSUMPTION: 'Credit consumption'
}

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
      // Convert action_type to search keyword if provided
      let searchQuery = filters.search_query || null
      if (filters.action_type && !filters.search_query) {
        // Map the action type constant to actual search keyword in logs
        searchQuery = ACTION_TYPE_SEARCH_KEYWORDS[filters.action_type] || filters.action_type
      }
      
      // Use new operations_log system instead of old admin_audit_log
      const { data, error: fetchError } = await supabase.rpc('get_operations_log', {
        p_limit: limit,
        p_offset: offset,
        p_user_id: filters.admin_user_id || filters.target_user_id || null,
        p_user_role: null, // Get all roles
        p_search_query: searchQuery,
        p_start_date: filters.start_date?.toISOString() || null,
        p_end_date: filters.end_date?.toISOString() || null
      })

      if (fetchError) throw fetchError

      // Transform operations_log to match old AuditLogEntry format for backward compatibility
      const transformedData = (data || []).map((log: any) => ({
        id: log.id,
        admin_user_id: log.user_id,
        admin_email: log.user_email || '',
        target_user_id: log.user_id, // In operations_log, same as user_id
        target_user_email: log.user_email || '',
        action_type: log.operation.split(':')[0].trim() || 'OPERATION', // Extract action from operation text
        description: log.operation,
        details: null, // No JSONB details in new system
        created_at: log.created_at
      }))

      auditLogs.value = transformedData
      return transformedData
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
      // Use new operations_log_stats instead of old admin_audit_logs_count
      const { data, error: countError } = await supabase.rpc('get_operations_log_stats')

      if (countError) throw countError

      const stats = (data && data.length > 0) ? data[0] : null
      const count = stats ? stats.total_operations : 0

      totalCount.value = count
      return count
    } catch (err: any) {
      console.error('Error fetching audit logs count:', err)
      throw err
    }
  }

  const fetchRecentActivity = async (limit = 20): Promise<any[]> => {
    isLoading.value = true
    error.value = null

    try {
      // Use new operations_log system
      const { data, error: fetchError } = await supabase.rpc('get_operations_log', {
        p_limit: limit,
        p_offset: 0,
        p_user_id: null,
        p_user_role: null // Get all operations
      })

      if (fetchError) throw fetchError

      // Transform to match old format
      const transformedData = (data || []).map((log: any) => ({
        activity_type: log.operation.split(':')[0].trim() || 'OPERATION',
        activity_date: log.created_at,
        user_email: log.user_email,
        user_public_name: log.user_email?.split('@')[0] || 'Unknown',
        description: log.operation,
        details: null
      }))

      return transformedData
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
      'SUBSCRIPTION_CHANGE': 'Subscription Change'
    }
    return labels[actionType] || actionType.replace('_', ' ')
  }

  const getActionTypeColor = (actionType: string): string => {
    const colors: Record<string, string> = {
      'USER_REGISTRATION': 'bg-green-500',
      'ROLE_CHANGE': 'bg-yellow-500',
      'SUBSCRIPTION_CHANGE': 'bg-purple-500'
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