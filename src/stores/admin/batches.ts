import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { supabase } from '@/lib/supabase'

export interface AdminBatch {
  id: string;
  batch_number: number;
  user_email: string;
  payment_status: 'PENDING' | 'PAID' | 'FREE';
  cards_count: number;
  created_at: string;
}

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
  const allBatches = ref<AdminBatch[]>([])
  const batchesRequiringAttention = ref<AdminBatchRequiringAttention[]>([])
  const isLoadingBatches = ref(false)
  const isLoadingAllBatches = ref(false)

  // Computed
  const pendingPaymentBatchCount = computed(() => batchesRequiringAttention.value.length)

  const totalPendingRevenue = computed(() => {
    return batchesRequiringAttention.value.reduce((total, batch) => {
      return total + (batch.payment_amount_cents || 0)
    }, 0)
  })

  // Actions
  const fetchAllBatches = async (
    emailSearch?: string, 
    paymentStatus?: 'PENDING' | 'PAID' | 'FREE',
    limit = 100,
    offset = 0
  ): Promise<AdminBatch[]> => {
    isLoadingAllBatches.value = true
    try {
      const { data, error } = await supabase.rpc('get_admin_all_batches', {
        p_email_search: emailSearch || null,
        p_payment_status: paymentStatus || null,
        p_limit: limit,
        p_offset: offset
      })
      if (error) throw error
      
      allBatches.value = data || []
      return data || []
    } catch (error) {
      console.error('Error fetching all batches:', error)
      throw error
    } finally {
      isLoadingAllBatches.value = false
    }
  }

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

  const issueBatch = async (
    userEmail: string,
    cardId: string,
    cardsCount: number,
    reason: string
  ): Promise<string> => {
    try {
      const { data, error } = await supabase.rpc('admin_issue_free_batch', {
        p_user_email: userEmail,
        p_card_id: cardId,
        p_cards_count: cardsCount,
        p_reason: reason
      })
      if (error) throw error
      
      // Refresh batches lists
      await Promise.all([
        fetchAllBatches(),
        fetchBatchesRequiringAttention()
      ])
      
      return data
    } catch (error) {
      console.error('Error issuing free batch:', error)
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
    allBatches,
    batchesRequiringAttention,
    isLoadingBatches,
    isLoadingAllBatches,
    
    // Computed
    pendingPaymentBatchCount,
    totalPendingRevenue,
    
    // Actions
    fetchAllBatches,
    fetchBatchesRequiringAttention,
    issueBatch,
    getBatchById,
    getBatchesByUser,
    
    // Utilities
    formatPaymentAmount
  }
}) 