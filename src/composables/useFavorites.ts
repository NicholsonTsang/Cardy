/**
 * useFavorites Composable
 *
 * Manages a per-card favorites system backed by localStorage.
 * Each card maintains its own favorites list under the key `favorites_${cardId}`.
 * Favorites are stored as an array of content item IDs.
 */

import { ref, computed, watch } from 'vue'

export interface UseFavoritesOptions {
  cardId: string
}

export function useFavorites(options: UseFavoritesOptions) {
  const { cardId } = options
  const storageKey = `favorites_${cardId}`

  /**
   * Load favorite IDs from localStorage
   */
  function loadFavorites(): string[] {
    try {
      const stored = localStorage.getItem(storageKey)
      if (stored) {
        const parsed = JSON.parse(stored)
        if (Array.isArray(parsed)) {
          return parsed
        }
      }
    } catch {
      // Silently handle corrupt data
      localStorage.removeItem(storageKey)
    }
    return []
  }

  /**
   * Persist favorite IDs to localStorage
   */
  function saveFavorites(ids: string[]) {
    try {
      localStorage.setItem(storageKey, JSON.stringify(ids))
    } catch {
      // localStorage may be full or disabled - fail silently
    }
  }

  // Reactive state
  const favoriteIds = ref<string[]>(loadFavorites())

  // Computed count
  const favoritesCount = computed(() => favoriteIds.value.length)

  /**
   * Check whether a content item is in the favorites list
   */
  function isFavorite(contentItemId: string): boolean {
    return favoriteIds.value.includes(contentItemId)
  }

  /**
   * Toggle a content item in/out of favorites.
   * Returns true if the item is now a favorite, false if it was removed.
   */
  function toggleFavorite(contentItemId: string): boolean {
    const index = favoriteIds.value.indexOf(contentItemId)
    if (index === -1) {
      favoriteIds.value = [...favoriteIds.value, contentItemId]
      saveFavorites(favoriteIds.value)
      return true
    } else {
      favoriteIds.value = favoriteIds.value.filter(id => id !== contentItemId)
      saveFavorites(favoriteIds.value)
      return false
    }
  }

  /**
   * Add an item to favorites (no-op if already present)
   */
  function addFavorite(contentItemId: string) {
    if (!isFavorite(contentItemId)) {
      favoriteIds.value = [...favoriteIds.value, contentItemId]
      saveFavorites(favoriteIds.value)
    }
  }

  /**
   * Remove an item from favorites (no-op if not present)
   */
  function removeFavorite(contentItemId: string) {
    if (isFavorite(contentItemId)) {
      favoriteIds.value = favoriteIds.value.filter(id => id !== contentItemId)
      saveFavorites(favoriteIds.value)
    }
  }

  /**
   * Clear all favorites for this card
   */
  function clearFavorites() {
    favoriteIds.value = []
    saveFavorites(favoriteIds.value)
  }

  return {
    favoriteIds,
    favoritesCount,
    isFavorite,
    toggleFavorite,
    addFavorite,
    removeFavorite,
    clearFavorites
  }
}
