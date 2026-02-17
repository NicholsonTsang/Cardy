import { ref, computed, onBeforeUnmount } from 'vue'

/**
 * Hard Timer Composable
 *
 * Enforces an absolute time limit on voice calls.
 * Unlike the inactivity timer, this counts down from a fixed limit
 * regardless of user activity.
 *
 * Features:
 * - Countdown from configurable limit (default 180s / 3 min)
 * - Warning state when time is running low (last 30s)
 * - Critical state in last 10s
 * - Auto-fires onExpire callback when timer reaches 0
 * - Formatted time display (MM:SS)
 */
export function useHardTimer(
  limitSeconds: number,
  onExpire: () => void
) {
  const remainingSeconds = ref(limitSeconds)
  const isRunning = ref(false)
  const isExpired = ref(false)

  let intervalId: number | null = null

  // Warning at 30 seconds remaining
  const isWarning = computed(() => remainingSeconds.value <= 30 && remainingSeconds.value > 10 && isRunning.value)
  // Critical at 10 seconds remaining
  const isCritical = computed(() => remainingSeconds.value <= 10 && remainingSeconds.value > 0 && isRunning.value)

  // Formatted display string (MM:SS)
  const formattedTime = computed(() => {
    const mins = Math.floor(remainingSeconds.value / 60)
    const secs = remainingSeconds.value % 60
    return `${mins}:${secs.toString().padStart(2, '0')}`
  })

  // Show countdown overlay (last 30 seconds)
  const showCountdown = computed(() => (isWarning.value || isCritical.value) && !isExpired.value)

  function start() {
    if (isRunning.value) return

    remainingSeconds.value = limitSeconds
    isExpired.value = false
    isRunning.value = true

    intervalId = window.setInterval(() => {
      remainingSeconds.value--

      if (remainingSeconds.value <= 0) {
        remainingSeconds.value = 0
        isExpired.value = true
        isRunning.value = false
        stop()
        console.log('⏰ [HARD TIMER] Voice call time limit reached - disconnecting')
        onExpire()
      }
    }, 1000)
  }

  function stop() {
    if (intervalId !== null) {
      clearInterval(intervalId)
      intervalId = null
    }
    isRunning.value = false
  }

  function reset() {
    stop()
    remainingSeconds.value = limitSeconds
    isExpired.value = false
  }

  // Cleanup on unmount
  onBeforeUnmount(() => {
    stop()
  })

  return {
    // State
    remainingSeconds,
    isRunning,
    isExpired,
    isWarning,
    isCritical,
    formattedTime,
    showCountdown,

    // Methods
    start,
    stop,
    reset
  }
}
