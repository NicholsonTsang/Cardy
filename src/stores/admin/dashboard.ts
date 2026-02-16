import { defineStore } from 'pinia'
import { ref } from 'vue'
import { supabase } from '@/lib/supabase'

export interface AdminDashboardStats {
  total_users: number;
  total_cards: number;
  // Audit-related metrics
  total_audit_entries: number;
  critical_actions_today: number;
  high_severity_actions_week: number;
  unique_admin_users_month: number;
  // Revenue metrics
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
  digital_cards_count: number;
  // Digital Access metrics
  total_digital_scans: number;
  daily_digital_scans: number;
  weekly_digital_scans: number;
  monthly_digital_scans: number;
  digital_credits_consumed: number;
  // Content Mode distribution (matches schema: single, list, grid, cards)
  content_mode_single: number;
  content_mode_list: number;
  content_mode_grid: number;
  content_mode_cards: number;
  is_grouped_count: number;
  // Subscription metrics (3 tiers: free, starter, premium)
  total_free_users: number;
  total_starter_users: number;
  total_premium_users: number;
  active_subscriptions: number;
  estimated_mrr_cents: number;
  // Access Log metrics
  monthly_total_accesses: number;
  monthly_overage_accesses: number;
  // QR Code metrics (Multi-QR system)
  total_qr_codes: number;
  active_qr_codes: number;
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

  // Actions
  const fetchDashboardStats = async (): Promise<AdminDashboardStats> => {
    isLoadingStats.value = true
    try {
      const { data, error } = await supabase.rpc('admin_get_system_stats_enhanced')
      if (error) throw error
      
      // The stored procedure returns an array with a single object
      const dbStats = (data && data.length > 0) ? data[0] : null
      
      if (!dbStats) {
        throw new Error('No data returned from admin_get_system_stats_enhanced')
      }
      
      // Map database fields to interface format
      const stats: AdminDashboardStats = {
        total_users: dbStats.total_users || 0,
        total_cards: dbStats.total_cards || 0,
        // Audit metrics
        total_audit_entries: dbStats.total_audit_entries || 0,
        critical_actions_today: dbStats.critical_actions_today || 0,
        high_severity_actions_week: dbStats.high_severity_actions_week || 0,
        unique_admin_users_month: dbStats.unique_admin_users_month || 0,
        // Revenue metrics
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
        digital_cards_count: dbStats.digital_cards_count || 0,
        // Digital Access metrics
        total_digital_scans: dbStats.total_digital_scans || 0,
        daily_digital_scans: dbStats.daily_digital_scans || 0,
        weekly_digital_scans: dbStats.weekly_digital_scans || 0,
        monthly_digital_scans: dbStats.monthly_digital_scans || 0,
        digital_credits_consumed: parseFloat(dbStats.digital_credits_consumed) || 0,
        // Content Mode distribution (matches schema: single, list, grid, cards)
        content_mode_single: dbStats.content_mode_single || 0,
        content_mode_list: dbStats.content_mode_list || 0,
        content_mode_grid: dbStats.content_mode_grid || 0,
        content_mode_cards: dbStats.content_mode_cards || 0,
        is_grouped_count: dbStats.is_grouped_count || 0,
        // Subscription metrics
        total_free_users: dbStats.total_free_users || 0,
        total_starter_users: dbStats.total_starter_users || 0,
        total_premium_users: dbStats.total_premium_users || 0,
        active_subscriptions: dbStats.active_subscriptions || 0,
        estimated_mrr_cents: dbStats.estimated_mrr_cents || 0,
        // Access Log metrics
        monthly_total_accesses: dbStats.monthly_total_accesses || 0,
        monthly_overage_accesses: dbStats.monthly_overage_accesses || 0,
        // QR Code metrics
        total_qr_codes: dbStats.total_qr_codes || 0,
        active_qr_codes: dbStats.active_qr_codes || 0
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
      // Use new operations_log system instead of old admin_audit_log
      const { data, error } = await supabase.rpc('get_operations_log', {
        p_limit: limit,
        p_offset: 0,
        p_user_id: null,
        p_user_role: 'admin' // Filter to admin operations only
      })
      
      if (error) {
        console.warn('get_operations_log function error, returning empty array:', error)
        recentActivity.value = []
        return []
      }
      
      // Transform operations_log format to AdminActivity format
      const transformedData = (data || []).map((log: any) => ({
        activity_type: log.operation.split(':')[0].trim(), // Extract type from operation text
        activity_date: log.created_at,
        user_email: log.user_email || '',
        user_public_name: log.user_email?.split('@')[0] || 'Unknown',
        description: log.operation,
        details: null
      }))
      
      recentActivity.value = transformedData
      return transformedData
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
    
    // Actions
    fetchDashboardStats,
    fetchRecentActivity,
    getAdminAuditLogs,
    loadDashboard
  }
}) 