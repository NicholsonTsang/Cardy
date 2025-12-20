/**
 * Pagination Configuration
 * 
 * Reads pagination settings from environment variables with fallback defaults.
 * Configure in .env file for different environments.
 */

// Default values (used if env vars are not set)
const DEFAULTS = {
  PAGE_SIZE: 20,
  PREVIEW_LENGTH: 200,
  LARGE_CARD_THRESHOLD: 50,
  INFINITE_SCROLL_THRESHOLD: 200
}

/**
 * Get the number of content items to load per page
 * @default 20
 */
export function getPageSize(): number {
  const envValue = import.meta.env.VITE_CONTENT_PAGE_SIZE
  return envValue ? parseInt(envValue, 10) : DEFAULTS.PAGE_SIZE
}

/**
 * Get the number of characters to show in content preview
 * @default 200
 */
export function getPreviewLength(): number {
  const envValue = import.meta.env.VITE_CONTENT_PREVIEW_LENGTH
  return envValue ? parseInt(envValue, 10) : DEFAULTS.PREVIEW_LENGTH
}

/**
 * Get the threshold for using pagination (cards with more items use pagination)
 * @default 50
 */
export function getLargeCardThreshold(): number {
  const envValue = import.meta.env.VITE_LARGE_CARD_THRESHOLD
  return envValue ? parseInt(envValue, 10) : DEFAULTS.LARGE_CARD_THRESHOLD
}

/**
 * Get the scroll distance from bottom (in pixels) to trigger infinite scroll
 * @default 200
 */
export function getInfiniteScrollThreshold(): number {
  const envValue = import.meta.env.VITE_INFINITE_SCROLL_THRESHOLD
  return envValue ? parseInt(envValue, 10) : DEFAULTS.INFINITE_SCROLL_THRESHOLD
}

/**
 * Get all pagination config values at once
 */
export function getPaginationConfig() {
  return {
    pageSize: getPageSize(),
    previewLength: getPreviewLength(),
    largeCardThreshold: getLargeCardThreshold(),
    infiniteScrollThreshold: getInfiniteScrollThreshold()
  }
}

// Export defaults for reference
export const PAGINATION_DEFAULTS = DEFAULTS






