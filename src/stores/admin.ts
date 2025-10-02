// Legacy compatibility layer for the old admin store
// This file re-exports the new modular stores for backward compatibility
// Components should migrate to import from '@/stores/admin' index file

import { defineStore } from 'pinia'
import { computed } from 'vue'
import { useAdminDashboardStore } from '@/stores/admin/dashboard'
import { useAdminPrintRequestsStore } from '@/stores/admin/printRequests'
import { useAdminBatchesStore } from '@/stores/admin/batches'
import { useAuditLogStore } from '@/stores/admin/auditLog'
import { useOperationsLogStore } from '@/stores/admin/operationsLog'

// Re-export individual stores for direct import
export { useAdminDashboardStore } from '@/stores/admin/dashboard'
export { useAdminPrintRequestsStore } from '@/stores/admin/printRequests'
export { useAdminBatchesStore } from '@/stores/admin/batches'
export { useAuditLogStore } from '@/stores/admin/auditLog'
export { useOperationsLogStore } from '@/stores/admin/operationsLog'

// Re-export all types for backward compatibility
export type { 
  AdminDashboardStats, 
  AdminActivity
} from '@/stores/admin/dashboard'

export type { 
  AdminPrintRequest
} from '@/stores/admin/printRequests'

export type { 
  AdminBatchRequiringAttention
} from '@/stores/admin/batches'

export type {
  AuditLogEntry as AdminAuditLog
} from '@/stores/admin/auditLog'

export type {
  OperationsLogEntry,
  OperationsLogStats
} from '@/stores/admin/operationsLog'

// Legacy admin store that delegates to the new modular stores
export const useAdminStore = defineStore('admin', () => {
  // Get all the modular stores
  const dashboardStore = useAdminDashboardStore()
  const printRequestsStore = useAdminPrintRequestsStore()
  const batchesStore = useAdminBatchesStore()
  const auditLogStore = useAuditLogStore()

  // Computed properties that aggregate data from different stores
  const dashboardStats = computed(() => dashboardStore.dashboardStats)
  const printRequests = computed(() => printRequestsStore.printRequests)
  const batchesRequiringAttention = computed(() => batchesStore.batchesRequiringAttention)
  const recentActivity = computed(() => dashboardStore.recentActivity)

  // Loading states
  const isLoading = computed(() => 
    dashboardStore.isLoading || 
    printRequestsStore.isLoadingPrintRequests ||
    batchesStore.isLoadingBatches
  )
  const isLoadingStats = computed(() => dashboardStore.isLoadingStats)
  const isLoadingPrintRequests = computed(() => printRequestsStore.isLoadingPrintRequests)
  const isLoadingBatches = computed(() => batchesStore.isLoadingBatches)

  // Delegate methods to appropriate stores
  const fetchDashboardStats = dashboardStore.fetchDashboardStats
  const fetchRecentActivity = dashboardStore.fetchRecentActivity
  const loadDashboard = dashboardStore.loadDashboard

  const fetchAllPrintRequests = printRequestsStore.fetchAllPrintRequests
  const updatePrintRequestStatus = printRequestsStore.updatePrintRequestStatus

  const fetchBatchesRequiringAttention = batchesStore.fetchBatchesRequiringAttention
  const waiveBatchPayment = batchesStore.waiveBatchPayment

  const fetchAuditLogs = auditLogStore.fetchAuditLogs
  const fetchAuditLogsCount = auditLogStore.fetchAuditLogsCount

  return {
    // Computed state
    dashboardStats,
    printRequests,
    batchesRequiringAttention,
    recentActivity,

    // Loading states
    isLoading,
    isLoadingStats,
    isLoadingPrintRequests,
    isLoadingBatches,

    // Dashboard methods
    fetchDashboardStats,
    fetchRecentActivity,
    loadDashboard,

    // Print request methods
    fetchAllPrintRequests,
    updatePrintRequestStatus,

    // Batch methods
    fetchBatchesRequiringAttention,
    waiveBatchPayment,

    // Audit methods
    fetchAuditLogs,
    fetchAuditLogsCount
  }
}) 