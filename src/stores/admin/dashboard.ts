import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { supabase } from '@/lib/supabase'

export interface AdminDashboardStats {
  total_users: number;
  total_verified_users: number;
  total_cards: number;
  total_batches: number;
  total_issued_cards: number;
  total_activated_cards: number;
  pending_verifications: number;
  pending_payment_batches: number;
  paid_batches: number;
  waived_batches: number;
  print_requests_submitted: number;
  print_requests_processing: number;
  print_requests_shipping: number;
  daily_revenue_cents: number;
  weekly_revenue_cents: number;
  monthly_revenue_cents: number;
  total_revenue_cents: number;
  daily_new_users: number;
  weekly_new_users: number;
  monthly_new_users: number;
  daily_new_cards: number;
  weekly_new_cards: number;
  monthly_new_cards: number;
  daily_issued_cards: number;
  weekly_issued_cards: number;
  monthly_issued_cards: number;
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
  const totalPrintRequestsCount = computed(() => {
    const stats = dashboardStats.value
    if (!stats) return 0
    return (stats.print_requests_submitted || 0) + (stats.print_requests_processing || 0) + (stats.print_requests_shipping || 0)
  })

  // Actions
  const fetchDashboardStats = async (): Promise<AdminDashboardStats> => {
    isLoadingStats.value = true
    try {
      const { data, error } = await supabase.rpc('admin_get_system_stats')
      if (error) throw error
      
      // The stored procedure returns an array with a single object
      const dbStats = (data && data.length > 0) ? data[0] : null
      
      if (!dbStats) {
        throw new Error('No data returned from admin_get_system_stats')
      }
      
      // Map database fields to interface format
      const stats: AdminDashboardStats = {
        total_users: dbStats.total_users || 0,
        total_verified_users: dbStats.total_verified_users || 0,
        total_cards: dbStats.total_cards || 0,
        total_batches: dbStats.total_batches || 0,
        total_issued_cards: dbStats.total_issued_cards || 0,
        total_activated_cards: dbStats.total_activated_cards || 0,
        pending_verifications: dbStats.pending_verifications || 0,
        pending_payment_batches: dbStats.pending_payment_batches || 0,
        paid_batches: dbStats.paid_batches || 0,
        waived_batches: dbStats.waived_batches || 0,
        print_requests_submitted: dbStats.print_requests_submitted || 0,
        print_requests_processing: dbStats.print_requests_processing || 0,
        print_requests_shipping: dbStats.print_requests_shipping || 0,
        daily_revenue_cents: dbStats.daily_revenue_cents || 0,
        weekly_revenue_cents: dbStats.weekly_revenue_cents || 0,
        monthly_revenue_cents: dbStats.monthly_revenue_cents || 0,
        total_revenue_cents: dbStats.total_revenue_cents || 0,
        daily_new_users: dbStats.daily_new_users || 0,
        weekly_new_users: dbStats.weekly_new_users || 0,
        monthly_new_users: dbStats.monthly_new_users || 0,
        daily_new_cards: dbStats.daily_new_cards || 0,
        weekly_new_cards: dbStats.weekly_new_cards || 0,
        monthly_new_cards: dbStats.monthly_new_cards || 0,
        daily_issued_cards: dbStats.daily_issued_cards || 0,
        weekly_issued_cards: dbStats.weekly_issued_cards || 0,
        monthly_issued_cards: dbStats.monthly_issued_cards || 0
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
      if (error) {
        console.warn('get_recent_admin_activity function not found, returning empty array')
        recentActivity.value = []
        return []
      }
      
      recentActivity.value = data || []
      return data || []
    } catch (error) {
      console.error('Error fetching recent activity:', error)
      // Return empty array instead of throwing to prevent dashboard crash
      recentActivity.value = []
      return []
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
      
      if (error) {
        console.warn('get_admin_audit_logs function not found, returning empty array')
        return []
      }
      return data || []
    } catch (error) {
      console.error('Error fetching audit logs:', error)
      // Return empty array instead of throwing to prevent dashboard crash
      return []
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
    totalPrintRequestsCount,
    
    // Actions
    fetchDashboardStats,
    fetchRecentActivity,
    getAdminAuditLogs,
    loadDashboard
  }
}) 