import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { supabase } from '@/lib/supabase'

export interface AdminBatchRequiringAttention {
  id: string;
  card_id: string;
  card_name: string;
  created_by: string;
  user_email: string;
  batch_name: string;
  batch_number: number;
  cards_count: number;
  payment_amount_cents: number;
  payment_required: boolean;
  payment_completed: boolean;
  payment_waived: boolean;
  cards_generated: boolean;
  created_at: string;
  updated_at: string;
}

export const useAdminBatchesStore = defineStore('adminBatches', () => {
  // State
  const batchesRequiringAttention = ref<AdminBatchRequiringAttention[]>([])
  const isLoadingBatches = ref(false)

  // Computed
  const pendingPaymentBatchCount = computed(() => batchesRequiringAttention.value.length)

  const totalPendingRevenue = computed(() => {
    return batchesRequiringAttention.value.reduce((total, batch) => {
      return total + (batch.payment_amount_cents || 0)
    }, 0)
  })

  // Actions
  const fetchBatchesRequiringAttention = async (): Promise<AdminBatchRequiringAttention[]> => {
    isLoadingBatches.value = true
    try {
      const { data, error } = await supabase.rpc('get_admin_batches_requiring_attention')
      if (error) throw error
      
      batchesRequiringAttention.value = data || []
      return data || []
    } catch (error) {
      console.error('Error fetching batches requiring attention:', error)
      throw error
    } finally {
      isLoadingBatches.value = false
    }
  }

  const waiveBatchPayment = async (batchId: string, waiverReason: string): Promise<boolean> => {
    try {
      const { data, error } = await supabase.rpc('admin_waive_batch_payment', {
        p_batch_id: batchId,
        p_waiver_reason: waiverReason
      })
      if (error) throw error
      
      // Refresh batches requiring attention
      await fetchBatchesRequiringAttention()
      
      return true
    } catch (error) {
      console.error('Error waiving batch payment:', error)
      throw error
    }
  }

  const getBatchById = (batchId: string) => {
    return batchesRequiringAttention.value.find(batch => batch.id === batchId)
  }

  const getBatchesByUser = (userId: string) => {
    return batchesRequiringAttention.value.filter(batch => batch.created_by === userId)
  }

  const formatPaymentAmount = (cents: number): string => {
    return `$${(cents / 100).toFixed(2)}`
  }

  return {
    // State
    batchesRequiringAttention,
    isLoadingBatches,
    
    // Computed
    pendingPaymentBatchCount,
    totalPendingRevenue,
    
    // Actions
    fetchBatchesRequiringAttention,
    waiveBatchPayment,
    getBatchById,
    getBatchesByUser,
    
    // Utilities
    formatPaymentAmount
  }
}) 