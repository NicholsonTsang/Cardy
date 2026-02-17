import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { supabase } from '@/lib/supabase'

interface CreditBalance {
  balance: number
  total_purchased: number
  total_consumed: number
  created_at: string
  updated_at: string
}

interface CreditTransaction {
  id: string
  type: 'purchase' | 'consumption' | 'refund' | 'adjustment'
  amount: number
  balance_before: number
  balance_after: number
  reference_type?: string
  reference_id?: string
  description?: string
  metadata?: any
  created_at: string
}

interface CreditPurchase {
  id: string
  amount_usd: number
  credits_amount: number
  status: 'pending' | 'completed' | 'failed' | 'refunded'
  payment_method?: any
  receipt_url?: string
  created_at: string
  completed_at?: string
}

interface CreditConsumption {
  id: string
  card_id?: string
  consumption_type: string
  quantity: number
  credits_per_unit: number
  total_credits: number
  description?: string
  created_at: string
  card_name?: string
}

interface CreditStatistics {
  current_balance: number
  total_purchased: number
  total_consumed: number
  recent_transactions: CreditTransaction[]
  monthly_consumption: number
  monthly_purchases: number
}

export const useCreditStore = defineStore('credits', () => {
  const creditBalance = ref<CreditBalance | null>(null)
  const transactions = ref<CreditTransaction[]>([])
  const purchases = ref<CreditPurchase[]>([])
  const consumptions = ref<CreditConsumption[]>([])
  const statistics = ref<CreditStatistics | null>(null)
  const loading = ref(false)
  const error = ref<string | null>(null)

  const balance = computed(() => creditBalance.value?.balance || 0)
  const formattedBalance = computed(() => balance.value.toFixed(2))

  // Initialize/Get user credits
  async function fetchCreditBalance() {
    loading.value = true
    error.value = null
    try {
      const { data, error: err } = await supabase.rpc('get_user_credits')
      if (err) throw err
      creditBalance.value = data?.[0] || null
    } catch (err: any) {
      error.value = err.message
      console.error('Error fetching credit balance:', err)
    } finally {
      loading.value = false
    }
  }

  // Get credit statistics
  async function fetchCreditStatistics() {
    loading.value = true
    error.value = null
    try {
      const { data, error: err } = await supabase.rpc('get_credit_statistics')
      if (err) throw err
      statistics.value = data
    } catch (err: any) {
      error.value = err.message
      console.error('Error fetching credit statistics:', err)
    } finally {
      loading.value = false
    }
  }

  // Get transaction history
  async function fetchTransactions(limit = 50, offset = 0, type?: string) {
    loading.value = true
    error.value = null
    try {
      const { data, error: err } = await supabase.rpc('get_credit_transactions', {
        p_limit: limit,
        p_offset: offset,
        p_type: type
      })
      if (err) throw err
      transactions.value = data || []
    } catch (err: any) {
      error.value = err.message
      console.error('Error fetching transactions:', err)
    } finally {
      loading.value = false
    }
  }

  // Get purchase history
  async function fetchPurchases(limit = 50, offset = 0) {
    loading.value = true
    error.value = null
    try {
      const { data, error: err } = await supabase.rpc('get_credit_purchases', {
        p_limit: limit,
        p_offset: offset
      })
      if (err) throw err
      purchases.value = data || []
    } catch (err: any) {
      error.value = err.message
      console.error('Error fetching purchases:', err)
    } finally {
      loading.value = false
    }
  }

  // Get consumption history
  async function fetchConsumptions(limit = 50, offset = 0) {
    loading.value = true
    error.value = null
    try {
      const { data, error: err } = await supabase.rpc('get_credit_consumptions', {
        p_limit: limit,
        p_offset: offset
      })
      if (err) throw err
      consumptions.value = data || []
    } catch (err: any) {
      error.value = err.message
      console.error('Error fetching consumptions:', err)
    } finally {
      loading.value = false
    }
  }

  // Check if user has sufficient credits
  async function checkCreditBalance(requiredCredits: number): Promise<boolean> {
    try {
      const { data, error: err } = await supabase.rpc('check_credit_balance', {
        p_required_credits: requiredCredits
      })
      if (err) throw err
      return data || false
    } catch (err: any) {
      console.error('Error checking credit balance:', err)
      return false
    }
  }

  // Create credit purchase record (before Stripe checkout)
  async function createCreditPurchase(
    stripeSessionId: string,
    amountUsd: number,
    creditsAmount: number,
    metadata?: any
  ) {
    try {
      const { data, error: err } = await supabase.rpc('create_credit_purchase', {
        p_stripe_session_id: stripeSessionId,
        p_amount_usd: amountUsd,
        p_credits_amount: creditsAmount,
        p_metadata: metadata
      })
      if (err) throw err
      return data
    } catch (err: any) {
      console.error('Error creating credit purchase:', err)
      throw err
    }
  }

  // Clear store
  function clearStore() {
    creditBalance.value = null
    transactions.value = []
    purchases.value = []
    consumptions.value = []
    statistics.value = null
    error.value = null
  }

  return {
    // State
    creditBalance,
    transactions,
    purchases,
    consumptions,
    statistics,
    loading,
    error,
    
    // Computed
    balance,
    formattedBalance,
    
    // Actions
    fetchCreditBalance,
    fetchCreditStatistics,
    fetchTransactions,
    fetchPurchases,
    fetchConsumptions,
    checkCreditBalance,
    createCreditPurchase,
    clearStore
  }
})
