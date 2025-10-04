import { ref } from 'vue'
import { supabase } from '@/lib/supabase'
import type { Message, ChatCompletionState } from '../types'

export function useChatCompletion() {
  // State
  const isLoading = ref(false)
  const error = ref<string | null>(null)
  const streamingMessageId = ref<string | null>(null)
  const currentPlayingMessageId = ref<string | null>(null)

  // Get AI response with text input
  async function getAIResponse(
    messages: Message[],
    systemInstructions: string,
    onStreamUpdate: (content: string) => void
  ): Promise<{ content: string; error?: string }> {
    isLoading.value = true
    error.value = null

    try {
      const { data, error: invokeError } = await supabase.functions.invoke(
        'chat-with-audio-stream',
        {
          body: {
            messages: messages.map(m => ({
              role: m.role,
              content: m.content
            })),
            systemInstructions
          }
        }
      )

      if (invokeError) throw invokeError

      // Handle streaming response
      if (data && typeof data === 'string') {
        const lines = data.split('\n')
        let fullContent = ''

        for (const line of lines) {
          if (line.startsWith('data: ')) {
            try {
              const chunk = JSON.parse(line.substring(6))
              if (chunk.content) {
                fullContent += chunk.content
                onStreamUpdate(fullContent)
              }
            } catch (e) {
              // Skip invalid JSON
            }
          }
        }

        return { content: fullContent }
      }

      throw new Error('Invalid response format')
    } catch (err: any) {
      console.error('AI response error:', err)
      error.value = err.message || 'Failed to get AI response'
      return { content: '', error: err.message }
    } finally {
      isLoading.value = false
    }
  }

  // Get AI response with voice input
  async function getAIResponseWithVoice(
    audioBlob: Blob,
    messages: Message[],
    systemInstructions: string,
    language: string
  ): Promise<{ textContent: string; userTranscription: string; error?: string }> {
    isLoading.value = true
    error.value = null

    try {
      // Convert blob to base64
      const arrayBuffer = await audioBlob.arrayBuffer()
      const bytes = new Uint8Array(arrayBuffer)
      const base64Audio = btoa(String.fromCharCode(...bytes))

      const { data, error: invokeError } = await supabase.functions.invoke(
        'chat-with-audio',
        {
          body: {
            audioData: base64Audio,
            audioFormat: 'wav',
            messages: messages.map(m => ({
              role: m.role,
              content: m.content
            })),
            systemInstructions,
            language,
            voiceInput: true,
            modalities: ['text']
          }
        }
      )

      if (invokeError) throw invokeError
      if (!data) throw new Error('No response from server')

      return {
        textContent: data.content || '',
        userTranscription: data.userTranscription || '[Voice input]'
      }
    } catch (err: any) {
      console.error('AI voice response error:', err)
      error.value = err.message || 'Failed to get AI response'
      return { textContent: '', userTranscription: '[Voice input]', error: err.message }
    } finally {
      isLoading.value = false
    }
  }

  // Generate and play TTS audio
  async function generateAndPlayTTS(
    text: string,
    messageId: string,
    language: string,
    message: Message
  ): Promise<string | null> {
    // Check if audio already cached and language matches
    if (message.audioUrl && message.language === language) {
      return message.audioUrl
    }

    // If language changed, revoke old audio URL
    if (message.audioUrl && message.language !== language) {
      URL.revokeObjectURL(message.audioUrl)
      message.audioUrl = undefined
      message.language = undefined
    }

    message.audioLoading = true

    try {
      // Use fetch to get binary audio data directly
      const supabaseUrl = import.meta.env.VITE_SUPABASE_URL as string
      const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY as string
      
      const response = await fetch(`${supabaseUrl}/functions/v1/generate-tts-audio`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${supabaseAnonKey}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          text,
          language,
          voice: 'alloy'
        })
      })

      if (!response.ok) {
        const errorText = await response.text()
        throw new Error(`TTS failed: ${errorText}`)
      }

      // Get audio as blob
      const audioBlob = await response.blob()
      const audioUrl = URL.createObjectURL(audioBlob)

      // Cache the audio URL and language
      message.audioUrl = audioUrl
      message.language = language

      return audioUrl
    } catch (err: any) {
      console.error('TTS generation error:', err)
      return null
    } finally {
      message.audioLoading = false
    }
  }

  // Play audio from URL
  function playAudioUrl(audioUrl: string, messageId: string): Promise<void> {
    return new Promise((resolve, reject) => {
      const audio = new Audio(audioUrl)
      currentPlayingMessageId.value = messageId

      audio.onended = () => {
        currentPlayingMessageId.value = null
        resolve()
      }

      audio.onerror = (err) => {
        currentPlayingMessageId.value = null
        reject(err)
      }

      audio.play().catch(reject)
    })
  }

  // Play message audio (generate if needed, or play cached)
  async function playMessageAudio(message: Message, language: string) {
    // If already playing this message, stop it
    if (currentPlayingMessageId.value === message.id) {
      // Stop current audio (would need audio element reference)
      currentPlayingMessageId.value = null
      return
    }

    // If playing another message, stop it
    if (currentPlayingMessageId.value) {
      currentPlayingMessageId.value = null
    }

    // Generate or retrieve cached audio
    const audioUrl = await generateAndPlayTTS(
      message.content,
      message.id,
      language,
      message
    )

    if (audioUrl) {
      try {
        await playAudioUrl(audioUrl, message.id)
      } catch (err) {
        console.error('Audio playback error:', err)
      }
    }
  }

  return {
    // State
    isLoading,
    error,
    streamingMessageId,
    currentPlayingMessageId,

    // Methods
    getAIResponse,
    getAIResponseWithVoice,
    generateAndPlayTTS,
    playAudioUrl,
    playMessageAudio
  }
}

