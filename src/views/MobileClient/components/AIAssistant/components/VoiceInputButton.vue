<template>
  <div class="voice-input-container">
    <!-- Recording Overlay (shows when recording) -->
    <div v-if="isRecording" class="voice-recording-overlay">
      <!-- Waveform Visualization -->
      <div class="waveform-section">
        <canvas ref="waveformCanvas" class="waveform-canvas"></canvas>
      </div>

      <!-- Recording Info -->
      <div class="recording-info">
        <div class="recording-indicator" :class="{ 'cancel-mode': isCancelZone }">
          <div class="pulse-ring"></div>
          <div class="pulse-ring delay-1"></div>
          <div class="inner-dot"></div>
        </div>
        <div class="recording-details">
          <span class="recording-duration">{{ formattedDuration }}</span>
          <span class="recording-status" :class="{ 'cancel-mode': isCancelZone }">
            {{ isCancelZone ? 'Release to cancel' : 'Release to send' }}
          </span>
        </div>
      </div>
    </div>

    <!-- Hold to Talk Button -->
    <button
      @mousedown="handleRecordStart"
      @mouseup="handleRecordEnd"
      @mouseleave="handleMouseLeave"
      @touchstart.prevent="handleRecordStart"
      @touchend.prevent="handleRecordEnd"
      @touchmove.prevent="handleTouchMove"
      class="hold-talk-button"
      :class="{ 
        recording: isRecording, 
        holding: isHolding,
        canceling: isCancelZone 
      }"
      :disabled="disabled"
      ref="recordButton"
    >
      <!-- Hold progress ring -->
      <div v-if="isHolding" class="hold-progress-ring">
        <svg class="progress-svg" viewBox="0 0 44 44">
          <circle 
            class="progress-background"
            cx="22" 
            cy="22" 
            r="20"
          />
          <circle 
            class="progress-fill"
            cx="22" 
            cy="22" 
            r="20"
            :style="{ strokeDashoffset: progressDashOffset }"
          />
        </svg>
      </div>
      
      <div class="button-content">
        <i class="pi pi-microphone"></i>
        <span class="button-text">{{ buttonText }}</span>
      </div>
    </button>
    
    <!-- Switch to Text Button -->
    <button 
      @click="$emit('toggle-mode')" 
      class="mode-switch-button"
      title="Switch to text input"
    >
      <i class="pi pi-comment" />
    </button>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, watch, onMounted, onBeforeUnmount } from 'vue'

const props = defineProps<{
  isRecording: boolean
  recordingDuration: number
  isCancelZone: boolean
  waveformData: Uint8Array | null
  disabled?: boolean
}>()

const emit = defineEmits<{
  (e: 'start-recording'): void
  (e: 'stop-recording'): void
  (e: 'cancel-recording'): void
  (e: 'toggle-mode'): void
  (e: 'update-cancel-zone', value: boolean): void
}>()

const recordButton = ref<HTMLButtonElement | null>(null)
const waveformCanvas = ref<HTMLCanvasElement | null>(null)
const animationFrame = ref<number | null>(null)

// Hold delay state
const HOLD_DELAY_MS = 500 // 500ms hold required before recording starts
const isHolding = ref(false)
const holdProgress = ref(0)
const holdTimer = ref<number | null>(null)
const holdStartTime = ref(0)

const formattedDuration = computed(() => {
  const seconds = Math.floor(props.recordingDuration / 1000)
  const milliseconds = Math.floor((props.recordingDuration % 1000) / 100)
  return `${seconds}.${milliseconds}s`
})

const buttonText = computed(() => {
  if (props.isRecording) return 'Recording...'
  if (isHolding.value) return 'Keep holding...'
  return 'Hold to talk'
})

// Progress ring calculation
const progressDashOffset = computed(() => {
  const circumference = 2 * Math.PI * 20 // radius = 20
  const offset = circumference - (holdProgress.value / 100) * circumference
  return offset
})

// Handle recording start (with hold delay)
function handleRecordStart(e: MouseEvent | TouchEvent) {
  e.preventDefault()
  
  // Start hold timer
  isHolding.value = true
  holdProgress.value = 0
  holdStartTime.value = Date.now()
  
  // Animate hold progress
  const animateHold = () => {
    const elapsed = Date.now() - holdStartTime.value
    holdProgress.value = Math.min((elapsed / HOLD_DELAY_MS) * 100, 100)
    
    if (elapsed >= HOLD_DELAY_MS && isHolding.value) {
      // Hold complete! Start recording
      isHolding.value = false
      holdProgress.value = 100
      emit('start-recording')
      
      // Add haptic feedback if available
      if ('vibrate' in navigator) {
        navigator.vibrate(50)
      }
    } else if (isHolding.value) {
      // Continue animation
      holdTimer.value = requestAnimationFrame(animateHold)
    }
  }
  
  holdTimer.value = requestAnimationFrame(animateHold)
}

// Handle recording end
function handleRecordEnd(e: MouseEvent | TouchEvent) {
  e.preventDefault()
  
  // If still holding (not yet recording), cancel
  if (isHolding.value) {
    cancelHold()
    return
  }
  
  // If recording, stop recording
  if (props.isRecording) {
    emit('stop-recording')
  }
}

// Cancel hold (user released before delay completed)
function cancelHold() {
  isHolding.value = false
  holdProgress.value = 0
  
  if (holdTimer.value) {
    cancelAnimationFrame(holdTimer.value)
    holdTimer.value = null
  }
}

// Handle mouse leave (cancel)
function handleMouseLeave() {
  if (isHolding.value) {
    cancelHold()
  } else if (props.isRecording) {
    emit('cancel-recording')
  }
}

// Handle touch move (detect cancel zone)
function handleTouchMove(e: TouchEvent) {
  if (!props.isRecording || !recordButton.value) return
  
  const touch = e.touches[0]
  const rect = recordButton.value.getBoundingClientRect()
  
  // Check if touch is outside the button by a certain threshold
  const threshold = 100
  const isOutside = 
    touch.clientY < rect.top - threshold ||
    touch.clientY > rect.bottom + threshold ||
    touch.clientX < rect.left - threshold ||
    touch.clientX > rect.right + threshold
  
  emit('update-cancel-zone', isOutside)
}

// Draw waveform
function drawWaveform() {
  if (!waveformCanvas.value || !props.waveformData) return
  
  const canvas = waveformCanvas.value
  const ctx = canvas.getContext('2d')
  if (!ctx) return
  
  const width = canvas.width
  const height = canvas.height
  const barCount = props.waveformData.length
  const barWidth = width / barCount
  
  ctx.clearRect(0, 0, width, height)
  
  // Create gradient
  const gradient = ctx.createLinearGradient(0, 0, width, 0)
  if (props.isCancelZone) {
    gradient.addColorStop(0, '#f87171')
    gradient.addColorStop(1, '#ef4444')
  } else {
    gradient.addColorStop(0, '#818cf8')
    gradient.addColorStop(1, '#a78bfa')
  }
  ctx.fillStyle = gradient
  
  for (let i = 0; i < barCount; i++) {
    const barHeight = (props.waveformData[i] / 255) * height * 0.8
    const x = i * barWidth
    const y = (height - barHeight) / 2
    
    // Draw rounded bars
    const radius = Math.min(barWidth / 2 - 1, 2)
    ctx.beginPath()
    ctx.roundRect(x + 1, y, barWidth - 2, barHeight, radius)
    ctx.fill()
  }
  
  if (props.isRecording) {
    animationFrame.value = requestAnimationFrame(drawWaveform)
  }
}

// Watch waveform data
watch(() => props.isRecording, (recording) => {
  if (recording) {
    drawWaveform()
  } else if (animationFrame.value) {
    cancelAnimationFrame(animationFrame.value)
    animationFrame.value = null
  }
})

// Setup canvas
onMounted(() => {
  if (waveformCanvas.value) {
    waveformCanvas.value.width = 300
    waveformCanvas.value.height = 60
  }
})

// Cleanup
onBeforeUnmount(() => {
  if (animationFrame.value) {
    cancelAnimationFrame(animationFrame.value)
  }
  if (holdTimer.value) {
    cancelAnimationFrame(holdTimer.value)
  }
})
</script>

<style scoped>
.voice-input-container {
  display: flex;
  flex-wrap: wrap;
  gap: 0.5rem;
  align-items: center;
  width: 100%;
  position: relative;
}

/* Recording Overlay */
.voice-recording-overlay {
  position: absolute;
  bottom: calc(100% + 0.75rem);
  left: 0;
  right: 0;
  background: linear-gradient(180deg, rgba(30, 41, 59, 0.98) 0%, rgba(15, 23, 42, 0.98) 100%);
  border: 1px solid rgba(255, 255, 255, 0.12);
  border-radius: 20px;
  padding: 1.5rem;
  backdrop-filter: blur(20px);
  -webkit-backdrop-filter: blur(20px);
  box-shadow: 
    0 0 0 1px rgba(255, 255, 255, 0.05),
    0 24px 48px -12px rgba(0, 0, 0, 0.6),
    0 0 40px rgba(99, 102, 241, 0.1);
  animation: overlaySlideUp 0.3s cubic-bezier(0.16, 1, 0.3, 1);
}

@keyframes overlaySlideUp {
  from {
    opacity: 0;
    transform: translateY(8px) scale(0.98);
  }
  to {
    opacity: 1;
    transform: translateY(0) scale(1);
  }
}

.waveform-section {
  margin-bottom: 1rem;
}

.waveform-canvas {
  width: 100%;
  height: 60px;
  border-radius: 8px;
  background: rgba(0, 0, 0, 0.2);
}

.recording-info {
  display: flex;
  align-items: center;
  gap: 0.875rem;
}

.recording-indicator {
  position: relative;
  width: 32px;
  height: 32px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.pulse-ring {
  position: absolute;
  width: 100%;
  height: 100%;
  border: 2px solid rgba(239, 68, 68, 0.4);
  border-radius: 50%;
  animation: pulseRing 1.5s ease-out infinite;
}

.pulse-ring.delay-1 {
  animation-delay: 0.5s;
}

.recording-indicator.cancel-mode .pulse-ring {
  border-color: rgba(239, 68, 68, 0.5);
}

@keyframes pulseRing {
  0% {
    transform: scale(0.8);
    opacity: 1;
  }
  100% {
    transform: scale(1.5);
    opacity: 0;
  }
}

.inner-dot {
  width: 12px;
  height: 12px;
  background: #ef4444;
  border-radius: 50%;
  box-shadow: 0 0 12px rgba(239, 68, 68, 0.5);
}

.recording-details {
  display: flex;
  flex-direction: column;
  gap: 0.125rem;
}

.recording-duration {
  font-size: 1.25rem;
  font-weight: 600;
  color: white;
  font-variant-numeric: tabular-nums;
}

.recording-status {
  font-size: 0.8125rem;
  color: rgba(255, 255, 255, 0.5);
  transition: color 0.2s;
}

.recording-status.cancel-mode {
  color: #fca5a5;
}

/* Hold to Talk Button */
.hold-talk-button {
  flex: 1;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 0.75rem 1.25rem;
  background: linear-gradient(135deg, #6366f1 0%, #8b5cf6 100%);
  color: white;
  border: none;
  border-radius: 14px;
  font-size: 0.9375rem;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.25s cubic-bezier(0.4, 0, 0.2, 1);
  user-select: none;
  -webkit-user-select: none;
  touch-action: none;
  box-shadow: 
    0 4px 16px rgba(99, 102, 241, 0.35),
    inset 0 1px 0 rgba(255, 255, 255, 0.2);
  height: 48px;
  position: relative;
  overflow: visible;
}

.hold-talk-button::before {
  content: '';
  position: absolute;
  inset: 0;
  border-radius: 14px;
  background: linear-gradient(135deg, rgba(255, 255, 255, 0.1) 0%, transparent 50%);
  opacity: 0;
  transition: opacity 0.25s;
}

.hold-talk-button:hover:not(:disabled):not(.recording):not(.holding) {
  background: linear-gradient(135deg, #4f46e5 0%, #7c3aed 100%);
  transform: translateY(-2px);
  box-shadow: 
    0 8px 24px rgba(99, 102, 241, 0.45),
    inset 0 1px 0 rgba(255, 255, 255, 0.25);
}

.hold-talk-button:hover:not(:disabled)::before {
  opacity: 1;
}

.hold-talk-button:active:not(:disabled):not(.recording) {
  transform: translateY(0) scale(0.98);
}

.hold-talk-button:disabled {
  opacity: 0.4;
  cursor: not-allowed;
  box-shadow: none;
}

.hold-talk-button.holding {
  background: linear-gradient(135deg, #7c3aed 0%, #6366f1 100%);
  transform: scale(1.03);
  box-shadow: 
    0 8px 28px rgba(124, 58, 237, 0.5),
    0 0 30px rgba(124, 58, 237, 0.2);
}

.hold-talk-button.recording {
  background: linear-gradient(135deg, #ef4444 0%, #dc2626 100%);
  box-shadow: 
    0 4px 20px rgba(239, 68, 68, 0.45),
    0 0 40px rgba(239, 68, 68, 0.2);
  animation: recordingPulse 1.5s ease-in-out infinite;
}

.hold-talk-button.canceling {
  background: linear-gradient(135deg, #6b7280 0%, #4b5563 100%);
  box-shadow: 0 4px 12px rgba(107, 114, 128, 0.3);
}

@keyframes recordingPulse {
  0%, 100% { 
    transform: scale(1);
    box-shadow: 0 4px 20px rgba(239, 68, 68, 0.45), 0 0 40px rgba(239, 68, 68, 0.2);
  }
  50% { 
    transform: scale(1.02);
    box-shadow: 0 6px 28px rgba(239, 68, 68, 0.55), 0 0 50px rgba(239, 68, 68, 0.3);
  }
}

.button-content {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  position: relative;
  z-index: 1;
}

.button-content i {
  font-size: 1rem;
}

.button-text {
  white-space: nowrap;
}

/* Hold progress ring */
.hold-progress-ring {
  position: absolute;
  top: 50%;
  left: 0.875rem;
  transform: translateY(-50%);
  width: 28px;
  height: 28px;
  pointer-events: none;
}

.progress-svg {
  width: 100%;
  height: 100%;
  transform: rotate(-90deg);
}

.progress-background {
  fill: none;
  stroke: rgba(255, 255, 255, 0.2);
  stroke-width: 3;
}

.progress-fill {
  fill: none;
  stroke: white;
  stroke-width: 3;
  stroke-linecap: round;
  stroke-dasharray: 125.6; /* 2 * π * 20 */
  transition: stroke-dashoffset 0.05s linear;
}

/* Mode Switch Button */
.mode-switch-button {
  width: 48px;
  height: 48px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: rgba(255, 255, 255, 0.05);
  border: 1px solid rgba(255, 255, 255, 0.1);
  border-radius: 14px;
  color: rgba(255, 255, 255, 0.5);
  font-size: 1.125rem;
  cursor: pointer;
  transition: all 0.25s cubic-bezier(0.4, 0, 0.2, 1);
  flex-shrink: 0;
}

.mode-switch-button:hover {
  background: rgba(99, 102, 241, 0.15);
  border-color: rgba(99, 102, 241, 0.3);
  color: #c4b5fd;
  transform: scale(1.05);
}

.mode-switch-button:active {
  transform: scale(0.95);
}

/* Mobile Optimizations */
@media (max-width: 640px) {
  .voice-input-container {
    gap: 0.5rem;
  }
  
  .hold-talk-button {
    padding: 0.625rem 1rem;
    font-size: 0.875rem;
    height: 48px;
  }
  
  .mode-switch-button {
    width: 48px;
    height: 48px;
  }
  
  .voice-recording-overlay {
    padding: 1.25rem;
    border-radius: 18px;
  }
}
</style>

