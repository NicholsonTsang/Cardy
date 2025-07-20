import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { supabase } from '@/lib/supabase'

export interface AdminPrintRequest {
  id: string;
  batch_id: string;
  batch_name: string;
  batch_number: number;
  card_name: string;
  cards_count: number;
  user_id: string;
  user_email: string;
  user_public_name: string;
  status: string;
  shipping_address: string;
  contact_email?: string;
  contact_whatsapp?: string;
  admin_notes: string;
  requested_at: string;
  updated_at: string;
}

export const useAdminPrintRequestsStore = defineStore('adminPrintRequests', () => {
  // State
  const printRequests = ref<AdminPrintRequest[]>([])
  const isLoadingPrintRequests = ref(false)

  // Computed
  const activePrintRequestCount = computed(() => 
    printRequests.value.filter(request => 
      !['COMPLETED', 'CANCELLED'].includes(request.status)
    ).length
  )

  const pendingPrintRequestCount = computed(() => 
    printRequests.value.filter(request => request.status === 'SUBMITTED').length
  )

  // Actions
  const fetchAllPrintRequests = async (status?: string): Promise<AdminPrintRequest[]> => {
    isLoadingPrintRequests.value = true
    try {
      const { data, error } = await supabase.rpc('get_all_print_requests', {
        p_status: status || null
      })
      if (error) {
        console.error('RPC Error:', error)
        throw error
      }
      
      console.log('Fetched print requests:', data)
      printRequests.value = data || []
      return data || []
    } catch (error) {
      console.error('Error fetching print requests:', error)
      throw error
    } finally {
      isLoadingPrintRequests.value = false
    }
  }

  const updatePrintRequestStatus = async (
    requestId: string,
    status: string,
    adminNotes?: string
  ): Promise<boolean> => {
    try {
      const { data, error } = await supabase.rpc('admin_update_print_request_status', {
        p_request_id: requestId,
        p_new_status: status,
        p_admin_notes: adminNotes || null
      })
      
      if (error) throw error
      
      // Refresh print requests after update
      await fetchAllPrintRequests()
      
      return data
    } catch (error) {
      console.error('Error updating print request status:', error)
      throw error
    }
  }

  const getPrintRequestsByStatus = (status: string) => {
    return printRequests.value.filter(request => request.status === status)
  }

  const getPrintRequestById = (requestId: string) => {
    return printRequests.value.find(request => request.id === requestId)
  }

  return {
    // State
    printRequests,
    isLoadingPrintRequests,
    
    // Computed
    activePrintRequestCount,
    pendingPrintRequestCount,
    
    // Actions
    fetchAllPrintRequests,
    updatePrintRequestStatus,
    getPrintRequestsByStatus,
    getPrintRequestById
  }
}) 