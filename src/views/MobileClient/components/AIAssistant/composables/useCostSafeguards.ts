import { onBeforeUnmount, watch } from 'vue'
import type { Ref } from 'vue'

export function useCostSafeguards(
  isRealtimeConnected: Ref<boolean>,
  disconnectCallback: () => void
) {
  let hasAddedListeners = false

  // Safeguard 1: Tab visibility change
  const handleVisibilityChange = () => {
    if (document.hidden && isRealtimeConnected.value) {
      console.log('🛡️ [COST SAFEGUARD] Tab hidden - disconnecting realtime')
      disconnectCallback()
    }
  }

  // Safeguard 2: Before page unload
  const handleBeforeUnload = (e: BeforeUnloadEvent) => {
    if (isRealtimeConnected.value) {
      console.log('🛡️ [COST SAFEGUARD] Page closing - disconnecting realtime')
      disconnectCallback()
      
      // Show confirmation dialog
      e.preventDefault()
      e.returnValue = 'Active call will be disconnected'
      return 'Active call will be disconnected'
    }
  }

  // Safeguard 3: Window blur (user switches apps)
  const handleWindowBlur = () => {
    if (isRealtimeConnected.value) {
      console.log('🛡️ [COST SAFEGUARD] Window lost focus - disconnecting realtime')
      disconnectCallback()
    }
  }

  // Add all event listeners
  function addSafeguards(): void {
    if (hasAddedListeners) return

    document.addEventListener('visibilitychange', handleVisibilityChange)
    window.addEventListener('beforeunload', handleBeforeUnload)
    window.addEventListener('blur', handleWindowBlur)
    
    hasAddedListeners = true
    console.log('🛡️ Cost safeguards activated')
  }

  // Remove all event listeners
  function removeSafeguards(): void {
    if (!hasAddedListeners) return

    document.removeEventListener('visibilitychange', handleVisibilityChange)
    window.removeEventListener('beforeunload', handleBeforeUnload)
    window.removeEventListener('blur', handleWindowBlur)
    
    hasAddedListeners = false
    console.log('🛡️ Cost safeguards deactivated')
  }

  // Watch connection state and manage listeners
  watch(isRealtimeConnected, (connected) => {
    if (connected) {
      addSafeguards()
    } else {
      removeSafeguards()
    }
  })

  // Cleanup on unmount (Safeguard 4: Component unmount)
  onBeforeUnmount(() => {
    if (isRealtimeConnected.value) {
      console.log('🛡️ [COST SAFEGUARD] Component unmounting - disconnecting realtime')
      disconnectCallback()
    }
    removeSafeguards()
  })

  return {
    addSafeguards,
    removeSafeguards
  }
}

