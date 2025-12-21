import { defineStore } from 'pinia';
import { ref } from 'vue';
import { supabase } from '@/lib/supabase';

export interface IssuedCard {
  id: string; // Unique ID of the issued card itself
  card_id: string; // ID of the main card design it belongs to
  active: boolean;
  issue_at: string;
  active_at: string | null;
  activated_by: string | null;
  batch_id: string;
  batch_name: string;
  batch_number: number;
  batch_is_disabled: boolean;
}

export interface CardBatch {
  id: string;
  card_id: string; // ID of the main card design this batch belongs to
  batch_name: string;
  batch_number: number;
  cards_count: number;
  active_cards_count: number;
  is_disabled: boolean;
  payment_required: boolean;
  payment_completed: boolean;
  payment_amount_cents: number | null;
  payment_completed_at: string | null;
  // Admin fee waiver fields
  payment_waived: boolean;
  payment_waived_by: string | null;
  payment_waived_at: string | null;
  payment_waiver_reason: string | null;
  // Cards generation status
  cards_generated: boolean;
  cards_generated_at: string | null;
  created_at: string;
  updated_at: string;
  print_requests?: PrintRequest[];
}

export const enum PrintRequestStatus {
  SUBMITTED = 'SUBMITTED',
  PAYMENT_PENDING = 'PAYMENT_PENDING',
  PROCESSING = 'PROCESSING',
  SHIPPED = 'SHIPPED',
  COMPLETED = 'COMPLETED',
  CANCELLED = 'CANCELLED',
}

export interface PrintRequestFeedback {
  id: string;
  admin_email: string;
  message: string;
  is_internal: boolean;
  created_at: string;
}

export interface PrintRequest {
  id: string;
  batch_id: string;
  user_id: string;
  status: PrintRequestStatus;
  shipping_address: string | null;
  contact_email: string | null;
  contact_whatsapp: string | null;
  cards_count: number;
  requested_at: string;
  updated_at: string;
  feedbacks?: PrintRequestFeedback[];
}

export interface IssuanceStats {
  total_issued: number;
  total_activated: number;
  activation_rate: number;
  total_batches: number;
}

// Note: BatchPayment interface removed - batch_payments table was dropped in database cleanup
// Batch issuance now uses credit-based payment model, not a separate payment flow

export const useIssuedCardStore = defineStore('issuedCard', () => {
  const issuedCards = ref<IssuedCard[]>([]);
  const batches = ref<CardBatch[]>([]);
  const stats = ref<IssuanceStats>({
    total_issued: 0,
    total_activated: 0,
    activation_rate: 0,
    total_batches: 0
  });
  const isLoading = ref(false);
  const error = ref<string | null>(null);
  const printRequestsForBatch = ref<Record<string, PrintRequest[]>>({});

  const fetchIssuedCards = async (cardId: string): Promise<IssuedCard[]> => {
    isLoading.value = true;
    error.value = null;
    try {
      const { data, error } = await supabase.rpc('get_issued_cards_with_batch', {
        p_card_id: cardId
      });
      if (error) throw error;
      issuedCards.value = data || [];
      return data as IssuedCard[];
    } catch (err: any) {
      console.error('Error fetching issued cards:', err);
      error.value = err.message || 'An unknown error occurred';
      throw err;
    } finally {
      isLoading.value = false;
    }
  };

  const fetchCardBatches = async (cardId: string): Promise<CardBatch[]> => {
    isLoading.value = true;
    error.value = null;
    try {
      const { data, error } = await supabase.rpc('get_card_batches', {
        p_card_id: cardId
      });
      if (error) throw error;
      batches.value = data || [];
      return data as CardBatch[];
    } catch (err: any) {
      console.error('Error fetching card batches:', err);
      error.value = err.message || 'An unknown error occurred';
      throw err;
    } finally {
      isLoading.value = false;
    }
  };

  const fetchIssuanceStats = async (cardId: string): Promise<IssuanceStats[]> => {
    isLoading.value = true;
    error.value = null;
    try {
      const { data, error } = await supabase.rpc('get_card_issuance_stats', {
        p_card_id: cardId
      });
      if (error) throw error;
      if (data && data.length > 0) {
        stats.value = data[0];
      }
      return data as IssuanceStats[];
    } catch (err: any) {
      console.error('Error fetching issuance stats:', err);
      error.value = err.message || 'An unknown error occurred';
      throw err;
    } finally {
      isLoading.value = false;
    }
  };


  // Payment information is now handled by Edge Functions in the payment-first flow

  const toggleBatchDisabledStatus = async (batchId: string, disableStatus: boolean, cardDesignId?: string) => {
    const { data, error } = await supabase.rpc('toggle_card_batch_disabled_status', {
      p_batch_id: batchId,
      p_disable_status: disableStatus
    });
    if (error) throw error;
    
    const batch = batches.value.find(b => b.id === batchId);
    if (batch && batch.card_id) { 
        await fetchCardBatches(batch.card_id); 
    } else if (cardDesignId) { // Use explicitly passed cardDesignId if batch.card_id is not available
        await fetchCardBatches(cardDesignId);
    } else {
        console.warn('Card ID for refreshing batches not found. Full UI refresh might be needed or pass cardDesignId to toggleBatchDisabledStatus.');
    }
    return data;
  };

  const activateCard = async (issuedCardId: string) => {
    const { data, error } = await supabase.rpc('activate_issued_card', {
      p_card_id: issuedCardId // This RPC expects the issued_card.id
    });
    if (error) throw error;
    return data;
  };

  const deleteIssuedCard = async (issuedCardId: string) => {
    const { data, error } = await supabase.rpc('delete_issued_card', {
      p_issued_card_id: issuedCardId
    });
    if (error) throw error;
    return data;
  };

  const fetchPrintRequestsForBatch = async (batchId: string): Promise<PrintRequest[]> => {
    const { data, error } = await supabase.rpc('get_print_requests_for_batch', { 
        p_batch_id: batchId 
    });
    if (error) throw error;
    printRequestsForBatch.value[batchId] = data || [];
    return data as PrintRequest[];
  };

  const requestPrintForBatch = async (
    batchId: string, 
    shippingAddress: string, 
    contactEmail?: string, 
    contactWhatsapp?: string
  ) => {
    const { data, error } = await supabase.rpc('request_card_printing', {
      p_batch_id: batchId,
      p_shipping_address: shippingAddress,
      p_contact_email: contactEmail || null,
      p_contact_whatsapp: contactWhatsapp || null
    });
    
    if (error) throw error;
    await fetchPrintRequestsForBatch(batchId);
    return data;
  };

  const withdrawPrintRequest = async (requestId: string, withdrawalReason?: string) => {
    const { data, error } = await supabase.rpc('withdraw_print_request', {
      p_request_id: requestId,
      p_withdrawal_reason: withdrawalReason || null
    });
    if (error) throw error;
    return data;
  };

  const fetchPrintRequestFeedbacks = async (requestId: string): Promise<PrintRequestFeedback[]> => {
    const { data, error } = await supabase.rpc('get_print_request_feedbacks', {
      p_request_id: requestId
    });
    if (error) throw error;
    return data || [];
  };

  const loadCardData = async (cardId: string) => {
    isLoading.value = true;
    try {
      // Fetch batches first, as their IDs are needed for print requests
      const fetchedBatches = await fetchCardBatches(cardId);
      
      const promises: Promise<any>[] = [
        fetchIssuedCards(cardId),
        fetchIssuanceStats(cardId)
      ];

      if (fetchedBatches && fetchedBatches.length > 0) {
        const printRequestPromises = fetchedBatches.map(batch => fetchPrintRequestsForBatch(batch.id));
        promises.push(...printRequestPromises);
      }
      
      await Promise.all(promises);

    } finally {
      isLoading.value = false;
    }
  };

  // Admin functions for card generation
  const generateBatchCards = async (batchId: string) => {
    const { data, error } = await supabase.rpc('generate_batch_cards', {
      p_batch_id: batchId
    });
    if (error) throw error;
    return data;
  };

  return {
    issuedCards,
    batches,
    stats,
    isLoading,
    error,
    printRequestsForBatch,
    fetchIssuedCards,
    fetchCardBatches,
    fetchIssuanceStats,
    toggleBatchDisabledStatus,
    activateCard,
    deleteIssuedCard,
    requestPrintForBatch,
    fetchPrintRequestsForBatch,
    fetchPrintRequestFeedbacks,
    loadCardData,
    generateBatchCards,
    withdrawPrintRequest
  };
});
