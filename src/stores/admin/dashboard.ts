import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { supabase } from '@/lib/supabase'

export interface AdminDashboardStats {
  total_users: number;
  total_card_designs: number;
  total_issued_cards: number;
  total_activated_cards: number;
  pending_verifications: number;
  approved_verifications: number;
  rejected_verifications: number;
  pending_print_requests: number;
  active_print_requests: number;
  completed_print_requests: number;
  total_batches: number;
  paid_batches: number;
  unpaid_batches: number;
  waived_batches: number;
  pending_payment_batches: number;
  total_revenue_cents: number;
  total_waived_amount_cents: number;
}

export interface AdminActivity {
  activity_type: string;
  activity_date: string;
  user_email: string;
  user_public_name: string;
  description: string;
  details: any;
}

export const useAdminDashboardStore = defineStore('adminDashboard', () => {
  // State
  const dashboardStats = ref<AdminDashboardStats | null>(null)
  const recentActivity = ref<AdminActivity[]>([])
  const isLoadingStats = ref(false)
  const isLoadingActivity = ref(false)
  const isLoading = ref(false)

  // Computed
  const pendingVerificationCount = computed(() => dashboardStats.value?.pending_verifications || 0)
  const activePrintRequestCount = computed(() => dashboardStats.value?.active_print_requests || 0)

  // Actions
  const fetchDashboardStats = async (): Promise<AdminDashboardStats> => {
    isLoadingStats.value = true
    try {
      const { data, error } = await supabase.rpc('get_admin_dashboard_stats')
      if (error) throw error
      
      // The stored procedure returns an array with a single object
      const stats = (data && data.length > 0) ? data[0] : {
        total_users: 0,
        total_card_designs: 0,
        total_issued_cards: 0,
        total_activated_cards: 0,
        pending_verifications: 0,
        approved_verifications: 0,
        rejected_verifications: 0,
        pending_print_requests: 0,
        active_print_requests: 0,
        completed_print_requests: 0,
        total_batches: 0,
        paid_batches: 0,
        unpaid_batches: 0,
        waived_batches: 0,
        pending_payment_batches: 0,
        total_revenue_cents: 0,
        total_waived_amount_cents: 0
      }
      
      dashboardStats.value = stats
      return stats
    } catch (error) {
      console.error('Error fetching dashboard stats:', error)
      throw error
    } finally {
      isLoadingStats.value = false
    }
  }

  const fetchRecentActivity = async (limit: number = 50): Promise<AdminActivity[]> => {
    isLoadingActivity.value = true
    try {
      const { data, error } = await supabase.rpc('get_recent_admin_activity', {
        p_limit: limit
      })
      if (error) throw error
      
      recentActivity.value = data || []
      return data || []
    } catch (error) {
      console.error('Error fetching recent activity:', error)
      throw error
    } finally {
      isLoadingActivity.value = false
    }
  }

  const getAdminAuditLogs = async ({
    action_type = null,
    admin_user_id = null,
    target_user_id = null,
    start_date = null,
    end_date = null,
    limit = 50,
    offset = 0
  } = {}) => {
    try {
      const { data, error } = await supabase.rpc('get_admin_audit_logs', {
        p_action_type: action_type,
        p_admin_user_id: admin_user_id || null,
        p_target_user_id: target_user_id || null,
        p_start_date: start_date,
        p_end_date: end_date,
        p_limit: limit,
        p_offset: offset
      })
      
      if (error) throw error
      return data || []
    } catch (error) {
      console.error('Error fetching audit logs:', error)
      throw error
    }
  }

  const loadDashboard = async () => {
    isLoading.value = true
    try {
      await Promise.all([
        fetchDashboardStats(),
        fetchRecentActivity(20)
      ])
    } catch (error) {
      console.error('Error loading admin dashboard:', error)
      throw error
    } finally {
      isLoading.value = false
    }
  }

  return {
    // State
    dashboardStats,
    recentActivity,
    isLoadingStats,
    isLoadingActivity,
    isLoading,
    
    // Computed
    pendingVerificationCount,
    activePrintRequestCount,
    
    // Actions
    fetchDashboardStats,
    fetchRecentActivity,
    getAdminAuditLogs,
    loadDashboard
  }
}) 