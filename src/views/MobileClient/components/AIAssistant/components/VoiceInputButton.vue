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
      :class="{ recording: isRecording, canceling: isCancelZone }"
      :disabled="disabled"
      ref="recordButton"
    >
      <i class="pi pi-microphone"></i>
      <span>Hold to talk</span>
    </button>
    
    <!-- Switch to Text Button -->
    <button 
      @click="$emit('toggle-mode')" 
      class="input-icon-button"
      title="Switch to text input"
    >
      <i class="pi pi-keyboard" />
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

const formattedDuration = computed(() => {
  const seconds = Math.floor(props.recordingDuration / 1000)
  const milliseconds = Math.floor((props.recordingDuration % 1000) / 100)
  return `${seconds}.${milliseconds}s`
})

// Handle recording start
function handleRecordStart(e: MouseEvent | TouchEvent) {
  e.preventDefault()
  emit('start-recording')
}

// Handle recording end
function handleRecordEnd(e: MouseEvent | TouchEvent) {
  e.preventDefault()
  emit('stop-recording')
}

// Handle mouse leave (cancel)
function handleMouseLeave() {
  if (props.isRecording) {
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
})
</script>

<style scoped>
.voice-input-container {
  display: flex;
  gap: 0.75rem;
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
  padding: 0.875rem 1.5rem;
  background: linear-gradient(135deg, #3b82f6 0%, #2563eb 100%);
  color: white;
  border: none;
  border-radius: 12px;
  font-size: 1rem;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s;
  user-select: none;
  -webkit-user-select: none;
  touch-action: none;
}

.hold-talk-button:hover:not(:disabled) {
  background: linear-gradient(135deg, #2563eb 0%, #1d4ed8 100%);
  transform: translateY(-1px);
  box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1);
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

.hold-talk-button.canceling {
  background: linear-gradient(135deg, #6b7280 0%, #4b5563 100%);
}

.input-icon-button {
  width: 48px;
  height: 48px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: white;
  border: 2px solid #e5e7eb;
  border-radius: 12px;
  color: #6b7280;
  font-size: 1.25rem;
  cursor: pointer;
  transition: all 0.2s;
  flex-shrink: 0;
}

.input-icon-button:hover {
  background: #f9fafb;
  border-color: #3b82f6;
  color: #3b82f6;
}

@media (max-width: 640px) {
  .hold-talk-button {
    padding: 0.75rem 1rem;
    font-size: 0.9375rem;
  }
}
</style>

