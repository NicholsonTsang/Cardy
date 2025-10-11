import { defineStore } from 'pinia'
import { ref } from 'vue'
import { supabase } from '@/lib/supabase'

interface AdminCreditPurchase {
  id: string
  user_id: string
  user_email: string
  user_name: string
  amount_usd: number
  credits_amount: number
  status: string
  stripe_session_id?: string
  payment_method?: any
  receipt_url?: string
  created_at: string
  completed_at?: string
}

interface AdminCreditConsumption {
  id: string
  user_id: string
  user_email: string
  user_name: string
  batch_id?: string
  batch_name?: string
  card_id?: string
  card_name?: string
  consumption_type: string
  quantity: number
  credits_per_unit: number
  total_credits: number
  description?: string
  created_at: string
}

interface AdminCreditTransaction {
  id: string
  user_id: string
  user_email: string
  user_name: string
  type: string
  amount: number
  balance_before: number
  balance_after: number
  reference_type?: string
  reference_id?: string
  description?: string
  metadata?: any
  created_at: string
}

interface UserCredit {
  user_id: string
  user_email: string
  user_name: string
  balance: number
  total_purchased: number
  total_consumed: number
  created_at: string
  updated_at: string
  total_count?: number
}

interface CreditSystemStatistics {
  total_credits_in_circulation: number
  total_credits_purchased: number
  total_credits_consumed: number
  total_users_with_credits: number
  total_revenue_usd: number
  monthly_purchases: number
  monthly_consumption: number
  pending_purchases: number
}

export const useAdminCreditStore = defineStore('adminCredits', () => {
  const purchases = ref<AdminCreditPurchase[]>([])
  const consumptions = ref<AdminCreditConsumption[]>([])
  const transactions = ref<AdminCreditTransaction[]>([])
  const userCredits = ref<UserCredit[]>([])
  const totalRecords = ref(0)
  const systemStats = ref<CreditSystemStatistics | null>(null)
  const loading = ref(false)
  const error = ref<string | null>(null)

  // Fetch all credit purchases
  async function fetchCreditPurchases(
    limit = 50,
    offset = 0,
    userId?: string,
    status?: string
  ) {
    loading.value = true
    error.value = null
    try {
      const { data, error: err } = await supabase.rpc('admin_get_credit_purchases', {
        p_limit: limit,
        p_offset: offset,
        p_user_id: userId,
        p_status: status
      })
      if (err) throw err
      purchases.value = data || []
    } catch (err: any) {
      error.value = err.message
      console.error('Error fetching admin credit purchases:', err)
    } finally {
      loading.value = false
    }
  }

  // Fetch all credit consumptions
  async function fetchCreditConsumptions(
    limit = 50,
    offset = 0,
    userId?: string,
    dateFrom?: string,
    dateTo?: string
  ) {
    loading.value = true
    error.value = null
    try {
      const { data, error: err } = await supabase.rpc('admin_get_credit_consumptions', {
        p_limit: limit,
        p_offset: offset,
        p_user_id: userId,
        p_date_from: dateFrom,
        p_date_to: dateTo
      })
      if (err) throw err
      consumptions.value = data || []
    } catch (err: any) {
      error.value = err.message
      console.error('Error fetching admin credit consumptions:', err)
    } finally {
      loading.value = false
    }
  }

  // Fetch all credit transactions
  async function fetchCreditTransactions(
    limit = 50,
    offset = 0,
    userId?: string,
    type?: string
  ) {
    loading.value = true
    error.value = null
    try {
      const { data, error: err } = await supabase.rpc('admin_get_credit_transactions', {
        p_limit: limit,
        p_offset: offset,
        p_user_id: userId,
        p_type: type
      })
      if (err) throw err
      transactions.value = data || []
    } catch (err: any) {
      error.value = err.message
      console.error('Error fetching admin credit transactions:', err)
    } finally {
      loading.value = false
    }
  }

  // Fetch user credit balances with pagination and search
  async function fetchUserCredits(
    limit = 20,
    offset = 0,
    search = '',
    sortField = 'balance',
    sortOrder = 'DESC'
  ) {
    loading.value = true
    error.value = null
    try {
      const { data, error: err } = await supabase.rpc('admin_get_user_credits', {
        p_limit: limit,
        p_offset: offset,
        p_search: search || null,
        p_sort_field: sortField,
        p_sort_order: sortOrder
      })
      if (err) throw err
      userCredits.value = data || []
      
      // Extract total count from first row
      if (data && data.length > 0) {
        totalRecords.value = data[0].total_count || 0
      } else {
        totalRecords.value = 0
      }
    } catch (err: any) {
      error.value = err.message
      console.error('Error fetching user credits:', err)
    } finally {
      loading.value = false
    }
  }

  // Fetch system statistics
  async function fetchSystemStatistics() {
    loading.value = true
    error.value = null
    try {
      const { data, error: err } = await supabase.rpc('admin_get_credit_statistics')
      if (err) throw err
      systemStats.value = data
    } catch (err: any) {
      error.value = err.message
      console.error('Error fetching credit system statistics:', err)
    } finally {
      loading.value = false
    }
  }

  // Adjust user credits (admin action)
  async function adjustUserCredits(
    targetUserId: string,
    amount: number,
    reason: string
  ) {
    loading.value = true
    error.value = null
    try {
      const { data, error: err } = await supabase.rpc('admin_adjust_user_credits', {
        p_target_user_id: targetUserId,
        p_amount: amount,
        p_reason: reason
      })
      if (err) throw err
      
      // Refresh data
      await fetchUserCredits()
      
      return data
    } catch (err: any) {
      error.value = err.message
      console.error('Error adjusting user credits:', err)
      throw err
    } finally {
      loading.value = false
    }
  }

  // Clear store
  function clearStore() {
    purchases.value = []
    consumptions.value = []
    transactions.value = []
    userCredits.value = []
    systemStats.value = null
    error.value = null
  }

  return {
    // State
    purchases,
    consumptions,
    transactions,
    userCredits,
    totalRecords,
    systemStats,
    loading,
    error,
    
    // Actions
    fetchCreditPurchases,
    fetchCreditConsumptions,
    fetchCreditTransactions,
    fetchUserCredits,
    fetchSystemStatistics,
    adjustUserCredits,
    clearStore
  }
})
