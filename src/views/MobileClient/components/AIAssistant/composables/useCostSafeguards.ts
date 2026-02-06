import { onBeforeUnmount, watch } from 'vue'
import type { Ref } from 'vue'

export function useCostSafeguards(
  isRealtimeConnected: Ref<boolean>,
  connectionStatus: Ref<string>,
  disconnectCallback: () => void
) {
  let hasAddedListeners = false
  let lastConnectedAt = 0
  const GRACE_MS = 10000 // 10 seconds grace period to allow connection to fully establish

  // Safeguard 1: Tab visibility change
  const handleVisibilityChange = () => {
    if (document.hidden && (isRealtimeConnected.value || connectionStatus.value === 'connecting')) {
      const sinceConnect = Date.now() - lastConnectedAt
      if (sinceConnect < GRACE_MS) {
        console.log('🛡️ [COST SAFEGUARD] Tab hidden shortly after connect - ignoring (grace)')
        return
      }
      console.log('🛡️ [COST SAFEGUARD] Tab hidden - disconnecting realtime')
      disconnectCallback()
    }
  }

  // Safeguard 2: Before page unload
  const handleBeforeUnload = () => {
    if (isRealtimeConnected.value || connectionStatus.value === 'connecting') {
      console.log('🛡️ [COST SAFEGUARD] Page closing - disconnecting realtime')
      disconnectCallback()
    }
  }

  // Safeguard 3: Window blur (user switches apps)
  const handleWindowBlur = () => {
    if (isRealtimeConnected.value || connectionStatus.value === 'connecting') {
      const sinceConnect = Date.now() - lastConnectedAt
      if (sinceConnect < GRACE_MS) {
        console.log('🛡️ [COST SAFEGUARD] Window blur shortly after connect - ignoring (grace)')
        return
      }
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

  // Watch connection state and status to manage listeners automatically
  watch(
    [isRealtimeConnected, connectionStatus],
    ([connected, status]) => {
      if (connected || status === 'connecting') {
        if (connected) {
          lastConnectedAt = Date.now()
        }
        addSafeguards()
      } else {
        removeSafeguards()
      }
    }
  )

  // Cleanup on unmount (Safeguard 4: Component unmount)
  onBeforeUnmount(() => {
    if (isRealtimeConnected.value || connectionStatus.value === 'connecting') {
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
