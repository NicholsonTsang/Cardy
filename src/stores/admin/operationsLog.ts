import { defineStore } from 'pinia'
import { ref } from 'vue'
import { supabase } from '@/lib/supabase'

// Operations Log Entry interface
export interface OperationsLogEntry {
  id: string
  user_id: string
  user_email: string
  user_role: 'admin' | 'cardIssuer' | 'user'
  operation: string
  created_at: string
}

// Operations Log Statistics
export interface OperationsLogStats {
  total_operations: number
  operations_today: number
  operations_this_week: number
  operations_this_month: number
  admin_operations: number
  card_issuer_operations: number
  user_operations: number
}

// Filters for operations log
export interface OperationsLogFilters {
  user_id: string | null
  user_role: 'admin' | 'cardIssuer' | 'user' | null
}

export const useOperationsLogStore = defineStore('operationsLog', () => {
  // State
  const operationsLogs = ref<OperationsLogEntry[]>([])
  const isLoading = ref(false)
  const error = ref<string | null>(null)
  const stats = ref<OperationsLogStats | null>(null)

  // Actions
  const fetchOperationsLogs = async (
    filters: Partial<OperationsLogFilters> = {},
    limit = 100,
    offset = 0
  ): Promise<OperationsLogEntry[]> => {
    isLoading.value = true
    error.value = null
    
    try {
      const { data, error: fetchError } = await supabase.rpc('get_operations_log', {
        p_limit: limit,
        p_offset: offset,
        p_user_id: filters.user_id || null,
        p_user_role: filters.user_role || null
      })

      if (fetchError) throw fetchError

      operationsLogs.value = data || []
      return data || []
    } catch (err: any) {
      console.error('Error fetching operations logs:', err)
      error.value = err.message || 'Failed to fetch operations logs'
      throw err
    } finally {
      isLoading.value = false
    }
  }

  const fetchOperationsLogStats = async (): Promise<OperationsLogStats | null> => {
    try {
      const { data, error: statsError } = await supabase.rpc('get_operations_log_stats')

      if (statsError) throw statsError

      const dbStats = (data && data.length > 0) ? data[0] : null
      
      if (!dbStats) return null

      stats.value = {
        total_operations: dbStats.total_operations || 0,
        operations_today: dbStats.operations_today || 0,
        operations_this_week: dbStats.operations_this_week || 0,
        operations_this_month: dbStats.operations_this_month || 0,
        admin_operations: dbStats.admin_operations || 0,
        card_issuer_operations: dbStats.card_issuer_operations || 0,
        user_operations: dbStats.user_operations || 0
      }

      return stats.value
    } catch (err: any) {
      console.error('Error fetching operations log stats:', err)
      throw err
    }
  }

  // Utility to filter logs by operation type (text search)
  const filterByOperationType = (logs: OperationsLogEntry[], searchTerm: string): OperationsLogEntry[] => {
    if (!searchTerm) return logs
    const lowerSearch = searchTerm.toLowerCase()
    return logs.filter(log => log.operation.toLowerCase().includes(lowerSearch))
  }

  // Utility to get operation color based on content
  const getOperationColor = (operation: string): string => {
    const op = operation.toLowerCase()
    if (op.includes('created')) return 'bg-green-500'
    if (op.includes('updated') || op.includes('changed')) return 'bg-blue-500'
    if (op.includes('deleted')) return 'bg-red-500'
    if (op.includes('waived')) return 'bg-orange-500'
    if (op.includes('activated')) return 'bg-purple-500'
    if (op.includes('requested')) return 'bg-indigo-500'
    return 'bg-slate-500'
  }

  // Utility to get operation icon based on content
  const getOperationIcon = (operation: string): string => {
    const op = operation.toLowerCase()
    if (op.includes('card')) return 'pi-credit-card'
    if (op.includes('batch')) return 'pi-box'
    if (op.includes('payment') || op.includes('waived')) return 'pi-dollar'
    if (op.includes('user') || op.includes('role')) return 'pi-user'
    if (op.includes('print')) return 'pi-print'
    if (op.includes('content')) return 'pi-file'
    return 'pi-info-circle'
  }

  return {
    // State
    operationsLogs,
    isLoading,
    error,
    stats,

    // Actions
    fetchOperationsLogs,
    fetchOperationsLogStats,

    // Utilities
    filterByOperationType,
    getOperationColor,
    getOperationIcon
  }
})

