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

export interface PrintRequest {
  id: string;
  batch_id: string;
  user_id: string;
  status: PrintRequestStatus;
  shipping_address: string | null;
  contact_email: string | null;
  contact_whatsapp: string | null;
  cards_count: number;
  admin_notes: string | null;
  payment_details: string | null;
  requested_at: string;
  updated_at: string;
}

export interface IssuanceStats {
  total_issued: number;
  total_activated: number;
  activation_rate: number;
  total_batches: number;
}

export interface UserIssuedCard extends IssuedCard {
  card_name: string;
  card_image_url: string | null;
}

export interface UserCardBatch extends CardBatch {
  card_name: string;
}

export interface UserIssuanceStats {
  total_issued: number;
  total_activated: number;
  activation_rate: number;
  total_batches: number;
  total_cards: number;
  pending_cards: number;
  disabled_batches: number;
  active_print_requests: number;
}

export interface RecentActivity {
  activity_type: string;
  activity_date: string;
  card_name: string;
  batch_name: string;
  description: string;
  count: number;
}

export interface BatchPayment {
  payment_id: string;
  stripe_checkout_session_id: string;
  stripe_payment_intent_id: string | null;
  amount_cents: number;
  currency: string;
  payment_status: 'pending' | 'succeeded' | 'failed' | 'canceled';
  payment_method: string | null;
  failure_reason: string | null;
  created_at: string;
  updated_at: string;
}

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

  // User-level data (across all cards)
  const userIssuedCards = ref<UserIssuedCard[]>([]);
  const userBatches = ref<UserCardBatch[]>([]);
  const userStats = ref<UserIssuanceStats>({
    total_issued: 0,
    total_activated: 0,
    activation_rate: 0,
    total_batches: 0,
    total_cards: 0,
    pending_cards: 0,
    disabled_batches: 0,
    active_print_requests: 0
  });
  const recentActivity = ref<RecentActivity[]>([]);
  const isLoadingUserData = ref(false);

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

  // User-level functions (across all cards)
  const fetchUserIssuedCards = async (): Promise<UserIssuedCard[]> => {
    const { data, error } = await supabase.rpc('get_user_all_issued_cards');
    if (error) throw error;
    userIssuedCards.value = data || [];
    return data as UserIssuedCard[];
  };

  const fetchUserBatches = async (): Promise<UserCardBatch[]> => {
    const { data, error } = await supabase.rpc('get_user_all_card_batches');
    if (error) throw error;
    userBatches.value = data || [];
    return data as UserCardBatch[];
  };

  const fetchUserStats = async (): Promise<UserIssuanceStats[]> => {
    const { data, error } = await supabase.rpc('get_user_issuance_stats');
    if (error) throw error;
    if (data && data.length > 0) {
      userStats.value = data[0];
    }
    return data as UserIssuanceStats[];
  };

  const fetchRecentActivity = async (limit: number = 50): Promise<RecentActivity[]> => {
    const { data, error } = await supabase.rpc('get_user_recent_activity', {
      p_limit: limit
    });
    if (error) throw error;
    recentActivity.value = data || [];
    return data as RecentActivity[];
  };

  const loadUserData = async () => {
    isLoadingUserData.value = true;
    try {
      await Promise.all([
        fetchUserIssuedCards(),
        fetchUserBatches(),
        fetchUserStats(),
        fetchRecentActivity(20) // Limit to 20 recent activities
      ]);
    } finally {
      isLoadingUserData.value = false;
    }
  };

  // Admin functions for fee waiver and card generation
  const adminWaiveBatchPayment = async (batchId: string, waiverReason: string) => {
    const { data, error } = await supabase.rpc('admin_waive_batch_payment', {
      p_batch_id: batchId,
      p_waiver_reason: waiverReason
    });
    if (error) throw error;
    return data;
  };

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
    loadCardData,
    userIssuedCards,
    userBatches,
    userStats,
    recentActivity,
    isLoadingUserData,
    loadUserData,
    adminWaiveBatchPayment,
    generateBatchCards,
    withdrawPrintRequest
  };
});
