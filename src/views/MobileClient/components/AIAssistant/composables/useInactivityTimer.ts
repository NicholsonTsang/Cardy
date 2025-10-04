import { ref, onBeforeUnmount } from 'vue'

export function useInactivityTimer(
  timeoutMs: number = 300000, // 5 minutes default
  onTimeout: () => void
) {
  const inactivityTimer = ref<number | null>(null)
  const lastActivityTime = ref<number>(Date.now())

  function resetTimer(): void {
    lastActivityTime.value = Date.now()
    
    if (inactivityTimer.value) {
      clearTimeout(inactivityTimer.value)
    }

    inactivityTimer.value = window.setTimeout(() => {
      console.log('⏰ Inactivity timeout - disconnecting for cost safety')
      onTimeout()
    }, timeoutMs)
  }

  function clearTimer(): void {
    if (inactivityTimer.value) {
      clearTimeout(inactivityTimer.value)
      inactivityTimer.value = null
    }
  }

  function startTimer(): void {
    resetTimer()
  }

  // Cleanup on unmount
  onBeforeUnmount(() => {
    clearTimer()
  })

  return {
    inactivityTimer,
    lastActivityTime,
    resetTimer,
    clearTimer,
    startTimer
  }
}

