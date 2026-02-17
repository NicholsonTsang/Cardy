// Legacy compatibility layer for the old admin store
// This file re-exports the new modular stores for backward compatibility
// Components should migrate to import from '@/stores/admin' index file

import { defineStore } from 'pinia'
import { computed } from 'vue'
import { useAdminDashboardStore } from '@/stores/admin/dashboard'
import { useAuditLogStore } from '@/stores/admin/auditLog'
import { useOperationsLogStore } from '@/stores/admin/operationsLog'
import { useAdminUserCardsStore } from '@/stores/admin/userCards'

// Re-export individual stores for direct import
export { useAdminDashboardStore } from '@/stores/admin/dashboard'
export { useAuditLogStore } from '@/stores/admin/auditLog'
export { useOperationsLogStore } from '@/stores/admin/operationsLog'
export { useAdminUserCardsStore } from '@/stores/admin/userCards'

// Re-export all types for backward compatibility
export type {
  AdminDashboardStats,
  AdminActivity
} from '@/stores/admin/dashboard'

export type {
  AuditLogEntry as AdminAuditLog
} from '@/stores/admin/auditLog'

export type {
  OperationsLogEntry,
  OperationsLogStats
} from '@/stores/admin/operationsLog'

export type {
  AdminUserInfo,
  AdminUserCard,
  AdminCardContent
} from '@/stores/admin/userCards'

// Legacy admin store that delegates to the new modular stores
export const useAdminStore = defineStore('admin', () => {
  // Get all the modular stores
  const dashboardStore = useAdminDashboardStore()
  const auditLogStore = useAuditLogStore()

  // Computed properties that aggregate data from different stores
  const dashboardStats = computed(() => dashboardStore.dashboardStats)
  const recentActivity = computed(() => dashboardStore.recentActivity)

  // Loading states
  const isLoading = computed(() => dashboardStore.isLoading)
  const isLoadingStats = computed(() => dashboardStore.isLoadingStats)

  // Delegate methods to appropriate stores
  const fetchDashboardStats = dashboardStore.fetchDashboardStats
  const fetchRecentActivity = dashboardStore.fetchRecentActivity
  const loadDashboard = dashboardStore.loadDashboard

  const fetchAuditLogs = auditLogStore.fetchAuditLogs
  const fetchAuditLogsCount = auditLogStore.fetchAuditLogsCount

  return {
    // Computed state
    dashboardStats,
    recentActivity,

    // Loading states
    isLoading,
    isLoadingStats,

    // Dashboard methods
    fetchDashboardStats,
    fetchRecentActivity,
    loadDashboard,

    // Audit methods
    fetchAuditLogs,
    fetchAuditLogsCount
  }
})
