import { ref, onBeforeUnmount } from 'vue'
import type { VoiceRecordingState } from '../types'

export function useVoiceRecording() {
  // State
  const isRecording = ref(false)
  const recordingDuration = ref(0)
  const isCancelZone = ref(false)
  const error = ref<string | null>(null)
  const audioChunks = ref<Blob[]>([])
  const mediaRecorder = ref<MediaRecorder | null>(null)
  const recordingTimer = ref<number | null>(null)
  const waveformData = ref<Uint8Array | null>(null)
  const waveformAnimationFrame = ref<number | null>(null)
  const audioContext = ref<AudioContext | null>(null)
  const analyser = ref<AnalyserNode | null>(null)

  // Start recording
  async function startRecording(): Promise<void> {
    try {
      const stream = await navigator.mediaDevices.getUserMedia({ audio: true })
      
      // Create audio context for waveform
      audioContext.value = new AudioContext()
      const source = audioContext.value.createMediaStreamSource(stream)
      analyser.value = audioContext.value.createAnalyser()
      analyser.value.fftSize = 256
      source.connect(analyser.value)
      waveformData.value = new Uint8Array(analyser.value.frequencyBinCount)

      // Start waveform animation
      startWaveformVisualization()

      // Create media recorder
      mediaRecorder.value = new MediaRecorder(stream, {
        mimeType: 'audio/webm;codecs=opus'
      })

      audioChunks.value = []

      mediaRecorder.value.ondataavailable = (event) => {
        if (event.data.size > 0) {
          audioChunks.value.push(event.data)
        }
      }

      mediaRecorder.value.onstop = async () => {
        stopWaveformVisualization()
        
        if (audioContext.value) {
          audioContext.value.close()
          audioContext.value = null
        }

        // Stop all tracks
        stream.getTracks().forEach(track => track.stop())
      }

      mediaRecorder.value.start()
      isRecording.value = true
      recordingDuration.value = 0

      // Start timer
      recordingTimer.value = window.setInterval(() => {
        recordingDuration.value += 100
      }, 100)

    } catch (err: any) {
      console.error('Failed to start recording:', err)
      error.value = 'Microphone access denied'
      throw err
    }
  }

  // Stop recording
  async function stopRecording(): Promise<Blob | null> {
    return new Promise((resolve) => {
      if (!mediaRecorder.value || !isRecording.value) {
        resolve(null)
        return
      }

      mediaRecorder.value.onstop = async () => {
        stopWaveformVisualization()
        
        if (audioContext.value) {
          audioContext.value.close()
          audioContext.value = null
        }

        // Stop timer
        if (recordingTimer.value) {
          clearInterval(recordingTimer.value)
          recordingTimer.value = null
        }

        if (isCancelZone.value) {
          // Cancelled
          audioChunks.value = []
          resolve(null)
        } else {
          // Process audio
          const audioBlob = new Blob(audioChunks.value, { type: 'audio/webm' })
          
          try {
            // Convert webm to wav
            const wavBlob = await convertToWav(audioBlob)
            resolve(wavBlob)
          } catch (err) {
            console.error('Audio conversion error:', err)
            resolve(audioBlob) // Fallback to original
          }
        }

        // Reset state
        isRecording.value = false
        recordingDuration.value = 0
        isCancelZone.value = false
        audioChunks.value = []
      }

      if (mediaRecorder.value.state !== 'inactive') {
        mediaRecorder.value.stop()
      }
    })
  }

  // Cancel recording
  function cancelRecording(): void {
    isCancelZone.value = true
    stopRecording()
  }

  // Convert WebM to WAV
  async function convertToWav(webmBlob: Blob): Promise<Blob> {
    const audioContext = new AudioContext({ sampleRate: 24000 })
    const arrayBuffer = await webmBlob.arrayBuffer()
    const audioBuffer = await audioContext.decodeAudioData(arrayBuffer)
    
    // Convert to WAV
    const wav = audioBufferToWav(audioBuffer)
    await audioContext.close()
    
    return new Blob([wav], { type: 'audio/wav' })
  }

  // Convert AudioBuffer to WAV format
  function audioBufferToWav(buffer: AudioBuffer): ArrayBuffer {
    const length = buffer.length * buffer.numberOfChannels * 2 + 44
    const arrayBuffer = new ArrayBuffer(length)
    const view = new DataView(arrayBuffer)
    const channels: Float32Array[] = []
    let offset = 0
    let pos = 0

    // Write WAV header
    const setUint16 = (data: number) => {
      view.setUint16(pos, data, true)
      pos += 2
    }

    const setUint32 = (data: number) => {
      view.setUint32(pos, data, true)
      pos += 4
    }

    // RIFF identifier
    setUint32(0x46464952)
    // File length
    setUint32(length - 8)
    // RIFF type
    setUint32(0x45564157)
    // Format chunk identifier
    setUint32(0x20746d66)
    // Format chunk length
    setUint32(16)
    // Sample format (PCM)
    setUint16(1)
    // Channel count
    setUint16(buffer.numberOfChannels)
    // Sample rate
    setUint32(buffer.sampleRate)
    // Byte rate
    setUint32(buffer.sampleRate * buffer.numberOfChannels * 2)
    // Block align
    setUint16(buffer.numberOfChannels * 2)
    // Bits per sample
    setUint16(16)
    // Data chunk identifier
    setUint32(0x61746164)
    // Data chunk length
    setUint32(length - pos - 4)

    // Write interleaved data
    for (let i = 0; i < buffer.numberOfChannels; i++) {
      channels.push(buffer.getChannelData(i))
    }

    while (pos < length) {
      for (let i = 0; i < buffer.numberOfChannels; i++) {
        const sample = Math.max(-1, Math.min(1, channels[i][offset]))
        view.setInt16(pos, sample < 0 ? sample * 0x8000 : sample * 0x7FFF, true)
        pos += 2
      }
      offset++
    }

    return arrayBuffer
  }

  // Waveform visualization
  function startWaveformVisualization(): void {
    if (!analyser.value || !waveformData.value) return

    const animate = () => {
      if (!isRecording.value || !analyser.value || !waveformData.value) return

      analyser.value.getByteFrequencyData(waveformData.value)
      waveformAnimationFrame.value = requestAnimationFrame(animate)
    }

    animate()
  }

  function stopWaveformVisualization(): void {
    if (waveformAnimationFrame.value) {
      cancelAnimationFrame(waveformAnimationFrame.value)
      waveformAnimationFrame.value = null
    }
  }

  // Cleanup
  function cleanup(): void {
    if (isRecording.value) {
      cancelRecording()
    }
    
    stopWaveformVisualization()
    
    if (audioContext.value) {
      audioContext.value.close()
      audioContext.value = null
    }
    
    if (recordingTimer.value) {
      clearInterval(recordingTimer.value)
      recordingTimer.value = null
    }
  }

  // Cleanup on unmount
  onBeforeUnmount(() => {
    cleanup()
  })

  return {
    // State
    isRecording,
    recordingDuration,
    isCancelZone,
    error,
    waveformData,

    // Methods
    startRecording,
    stopRecording,
    cancelRecording,
    cleanup
  }
}

