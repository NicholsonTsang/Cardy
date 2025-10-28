<template>
  <div class="voice-input-container">
    <!-- Recording Overlay (shows when recording) -->
    <div v-if="isRecording" class="voice-recording-overlay">
      <!-- Waveform Visualization -->
      <div class="waveform-section">
        <canvas ref="waveformCanvas" class="waveform-canvas"></canvas>
      </div>

      <!-- Recording Info -->
      <div class="recording-info-section">
        <div class="recording-pulse"></div>
        <span class="recording-duration">{{ formattedDuration }}</span>
        <span class="recording-status">{{ isCancelZone ? 'Release to cancel' : 'Release to send' }}</span>
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
      <!-- Hold progress indicator -->
      <div v-if="isHolding" class="hold-progress-ring">
        <svg class="progress-svg" viewBox="0 0 40 40">
          <circle 
            class="progress-background"
            cx="20" 
            cy="20" 
            r="18"
          />
          <circle 
            class="progress-fill"
            cx="20" 
            cy="20" 
            r="18"
            :style="{ strokeDashoffset: progressDashOffset }"
          />
        </svg>
      </div>
      
      <i class="pi pi-microphone"></i>
      <span>{{ isHolding ? 'Keep holding...' : 'Hold to talk' }}</span>
    </button>
    
    <!-- Switch to Text Button -->
    <button 
      @click="$emit('toggle-mode')" 
      class="input-icon-button"
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

// Progress ring calculation
const progressDashOffset = computed(() => {
  const circumference = 2 * Math.PI * 18 // radius = 18
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
  ctx.fillStyle = props.isCancelZone ? '#ef4444' : '#3b82f6'
  
  for (let i = 0; i < barCount; i++) {
    const barHeight = (props.waveformData[i] / 255) * height * 0.8
    const x = i * barWidth
    const y = (height - barHeight) / 2
    
    ctx.fillRect(x, y, barWidth - 2, barHeight)
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
    waveformCanvas.value.height = 80
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
  gap: 0.5rem;
  align-items: center;
  width: 100%;
  position: relative;
}

.voice-recording-overlay {
  position: absolute;
  bottom: 100%;
  left: 0;
  right: 0;
  background: white;
  border: 2px solid #e5e7eb;
  border-radius: 16px;
  padding: 1.5rem;
  margin-bottom: 1rem;
  box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.1);
  animation: slideUp 0.2s ease-out;
}

@keyframes slideUp {
  from {
    opacity: 0;
    transform: translateY(10px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

.waveform-section {
  margin-bottom: 1rem;
}

.waveform-canvas {
  width: 100%;
  height: 80px;
}

.recording-info-section {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  justify-content: center;
}

.recording-pulse {
  width: 12px;
  height: 12px;
  background: #ef4444;
  border-radius: 50%;
  animation: pulse 1.5s ease-in-out infinite;
}

@keyframes pulse {
  0%, 100% {
    opacity: 1;
    transform: scale(1);
  }
  50% {
    opacity: 0.5;
    transform: scale(1.2);
  }
}

.recording-duration {
  font-size: 1.125rem;
  font-weight: 600;
  color: #1f2937;
}

.recording-status {
  font-size: 0.875rem;
  color: #6b7280;
  font-style: italic;
}

.hold-talk-button {
  flex: 1;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 0.5rem;
  padding: 0.5rem 1rem;
  background: linear-gradient(135deg, #3b82f6 0%, #2563eb 100%);
  color: white;
  border: none;
  border-radius: 10px;
  font-size: 0.9375rem;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s;
  user-select: none;
  -webkit-user-select: none;
  touch-action: none;
  box-shadow: 0 2px 4px rgba(59, 130, 246, 0.2);
  height: 40px;
  position: relative;
  overflow: visible;
}

.hold-talk-button:hover:not(:disabled) {
  background: linear-gradient(135deg, #2563eb 0%, #1d4ed8 100%);
  transform: translateY(-1px);
  box-shadow: 0 4px 6px rgba(59, 130, 246, 0.3);
}

.hold-talk-button:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.hold-talk-button.recording {
  background: linear-gradient(135deg, #ef4444 0%, #dc2626 100%);
  animation: recordingPulse 1.5s ease-in-out infinite;
}

@keyframes recordingPulse {
  0%, 100% {
    transform: scale(1);
  }
  50% {
    transform: scale(1.02);
  }
}

.hold-talk-button.holding {
  background: linear-gradient(135deg, #8b5cf6 0%, #7c3aed 100%);
  transform: scale(1.05);
}

.hold-talk-button.canceling {
  background: linear-gradient(135deg, #6b7280 0%, #4b5563 100%);
}

/* Hold progress ring */
.hold-progress-ring {
  position: absolute;
  top: 50%;
  left: 1rem;
  transform: translateY(-50%);
  width: 40px;
  height: 40px;
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
  stroke-dasharray: 113.1; /* 2 * π * 18 */
  transition: stroke-dashoffset 0.05s linear;
}

.input-icon-button {
  width: 40px;
  height: 40px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: white;
  border: 1.5px solid #e5e7eb;
  border-radius: 10px;
  color: #6b7280;
  font-size: 1.125rem;
  cursor: pointer;
  transition: all 0.2s;
  flex-shrink: 0;
}

.input-icon-button:hover {
  background: #f3f4f6;
  border-color: #9ca3af;
  transform: translateY(-1px);
}

.input-icon-button:active {
  transform: translateY(0);
}

@media (max-width: 640px) {
  .voice-input-container {
    gap: 0.375rem;
  }
  
  .hold-talk-button {
    padding: 0.5rem 0.75rem;
    font-size: 0.875rem;
  }
  
  .input-icon-button {
    width: 36px;
    height: 36px;
    font-size: 1rem;
  }
}
</style>

