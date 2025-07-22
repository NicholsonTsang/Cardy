/**
 * Standardized toast configurations for consistent user experience
 */

export const TOAST_DURATIONS = {
  SHORT: 2000,    // For micro-interactions, copy confirmations
  NORMAL: 3000,   // For standard operations
  LONG: 5000,     // For important operations, warnings
  EXTENDED: 6000  // For critical errors, complex operations
}

export const TOAST_SEVERITIES = {
  SUCCESS: 'success',
  INFO: 'info', 
  WARN: 'warn',
  ERROR: 'error'
}

/**
 * Standardized toast configurations by operation type
 */
export const TOAST_CONFIGS = {
  // Authentication operations
  AUTH_SUCCESS: {
    severity: TOAST_SEVERITIES.SUCCESS,
    life: TOAST_DURATIONS.NORMAL,
    group: 'br'
  },
  AUTH_ERROR: {
    severity: TOAST_SEVERITIES.ERROR,
    life: TOAST_DURATIONS.NORMAL,
    group: 'br'
  },
  
  // Critical operations (payments, admin actions)
  CRITICAL_SUCCESS: {
    severity: TOAST_SEVERITIES.SUCCESS,
    life: TOAST_DURATIONS.LONG
  },
  CRITICAL_ERROR: {
    severity: TOAST_SEVERITIES.ERROR,
    life: TOAST_DURATIONS.EXTENDED
  },
  
  // Standard operations
  OPERATION_SUCCESS: {
    severity: TOAST_SEVERITIES.SUCCESS,
    life: TOAST_DURATIONS.NORMAL
  },
  OPERATION_ERROR: {
    severity: TOAST_SEVERITIES.ERROR,
    life: TOAST_DURATIONS.NORMAL
  },
  
  // Micro-interactions (should be used sparingly)
  MICRO_SUCCESS: {
    severity: TOAST_SEVERITIES.SUCCESS,
    life: TOAST_DURATIONS.SHORT
  },
  MICRO_ERROR: {
    severity: TOAST_SEVERITIES.ERROR,
    life: TOAST_DURATIONS.SHORT
  },
  
  // Warnings and info
  WARNING: {
    severity: TOAST_SEVERITIES.WARN,
    life: TOAST_DURATIONS.LONG
  },
  INFO: {
    severity: TOAST_SEVERITIES.INFO,
    life: TOAST_DURATIONS.NORMAL,
    group: 'br'
  }
}

/**
 * Helper function to create toast with standard config
 */
export function createToast(type, summary, detail) {
  const config = TOAST_CONFIGS[type] || TOAST_CONFIGS.OPERATION_SUCCESS
  return {
    ...config,
    summary,
    detail
  }
}