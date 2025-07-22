// Legacy compatibility layer for the old admin store
// This file re-exports the new modular stores for backward compatibility
// Components should migrate to import from '@/stores/admin' index file

import { defineStore } from 'pinia'
import { computed } from 'vue'
import { useAdminDashboardStore } from '@/stores/admin/dashboard'
import { useAdminVerificationsStore } from '@/stores/admin/verifications'
import { useAdminPrintRequestsStore } from '@/stores/admin/printRequests'
import { useAdminBatchesStore } from '@/stores/admin/batches'
import { useAdminFeedbackStore } from '@/stores/admin/feedback'
import { useAuditLogStore } from '@/stores/admin/auditLog'

// Re-export individual stores for direct import
export { useAdminDashboardStore } from '@/stores/admin/dashboard'
export { useAdminVerificationsStore } from '@/stores/admin/verifications'
export { useAdminPrintRequestsStore } from '@/stores/admin/printRequests'
export { useAdminBatchesStore } from '@/stores/admin/batches'
export { useAdminFeedbackStore } from '@/stores/admin/feedback'

// Re-export all types for backward compatibility
export type { 
  AdminDashboardStats, 
  AdminActivity
} from '@/stores/admin/dashboard'

export type { 
  AdminVerification, 
  AdminUser, 
  AdminUserActivity
} from '@/stores/admin/verifications'

export type { 
  AdminPrintRequest
} from '@/stores/admin/printRequests'

export type { 
  AdminBatchRequiringAttention
} from '@/stores/admin/batches'

export type { 
  AdminFeedback
} from '@/stores/admin/feedback'

export type {
  AuditLogEntry as AdminAuditLog
} from '@/stores/admin/auditLog'

// Legacy admin store that delegates to the new modular stores
export const useAdminStore = defineStore('admin', () => {
  // Get all the modular stores
  const dashboardStore = useAdminDashboardStore()
  const verificationsStore = useAdminVerificationsStore()
  const printRequestsStore = useAdminPrintRequestsStore()
  const batchesStore = useAdminBatchesStore()
  const feedbackStore = useAdminFeedbackStore()
  const auditLogStore = useAuditLogStore()

  // Computed properties that aggregate data from different stores
  const dashboardStats = computed(() => dashboardStore.dashboardStats)
  const allVerifications = computed(() => verificationsStore.allVerifications)
  const pendingVerifications = computed(() => verificationsStore.pendingVerifications)
  const allUsers = computed(() => verificationsStore.allUsers)
  const printRequests = computed(() => printRequestsStore.printRequests)
  const batchesRequiringAttention = computed(() => batchesStore.batchesRequiringAttention)
  const recentActivity = computed(() => dashboardStore.recentActivity)

  // Loading states
  const isLoading = computed(() => 
    dashboardStore.isLoading || 
    verificationsStore.isLoading ||
    printRequestsStore.isLoadingPrintRequests ||
    batchesStore.isLoadingBatches
  )
  const isLoadingStats = computed(() => dashboardStore.isLoadingStats)
  const isLoadingVerifications = computed(() => verificationsStore.isLoadingVerifications)
  const isLoadingPrintRequests = computed(() => printRequestsStore.isLoadingPrintRequests)
  const isLoadingBatches = computed(() => batchesStore.isLoadingBatches)

  // Delegate methods to appropriate stores
  const fetchDashboardStats = dashboardStore.fetchDashboardStats
  const fetchRecentActivity = dashboardStore.fetchRecentActivity
  const loadDashboard = dashboardStore.loadDashboard

  const fetchPendingVerifications = verificationsStore.fetchPendingVerifications
  const fetchAllVerifications = verificationsStore.fetchAllVerifications
  const fetchVerificationById = verificationsStore.fetchVerificationById
  const reviewVerification = verificationsStore.reviewVerification
  const loadUsersWithDetails = verificationsStore.loadUsersWithDetails
  const updateUserRole = verificationsStore.updateUserRole
  const resetUserVerification = verificationsStore.resetUserVerification
  const manualVerification = verificationsStore.manualVerification
  const getUserActivitySummary = verificationsStore.getUserActivitySummary
  const setSelectedVerificationUser = verificationsStore.setSelectedVerificationUser

  const fetchAllPrintRequests = printRequestsStore.fetchAllPrintRequests
  const updatePrintRequestStatus = printRequestsStore.updatePrintRequestStatus

  const fetchBatchesRequiringAttention = batchesStore.fetchBatchesRequiringAttention
  const waiveBatchPayment = batchesStore.waiveBatchPayment

  const fetchAuditLogs = auditLogStore.fetchAuditLogs
  const fetchAuditLogsCount = auditLogStore.fetchAuditLogsCount
  const getFeedbackHistory = feedbackStore.getFeedbackHistory
  const createOrUpdateFeedback = feedbackStore.createOrUpdateFeedback

  return {
    // Computed state
    dashboardStats,
    allVerifications,
    pendingVerifications,
    allUsers,
    printRequests,
    batchesRequiringAttention,
    recentActivity,

    // Loading states
    isLoading,
    isLoadingStats,
    isLoadingVerifications,
    isLoadingPrintRequests,
    isLoadingBatches,

    // Dashboard methods
    fetchDashboardStats,
    fetchRecentActivity,
    loadDashboard,

    // Verification methods
    fetchPendingVerifications,
    fetchAllVerifications,
    fetchVerificationById,
    reviewVerification,
    loadUsersWithDetails,
    updateUserRole,
    resetUserVerification,
    manualVerification,
    getUserActivitySummary,
    setSelectedVerificationUser,

    // Print request methods
    fetchAllPrintRequests,
    updatePrintRequestStatus,

    // Batch methods
    fetchBatchesRequiringAttention,
    waiveBatchPayment,

    // Feedback and audit methods
    fetchAuditLogs,
    fetchAuditLogsCount,
    getFeedbackHistory,
    createOrUpdateFeedback
  }
}) 