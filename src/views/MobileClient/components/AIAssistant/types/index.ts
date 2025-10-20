// Shared TypeScript types for AI Assistant

export interface Language {
  code: string
  name: string
  flag: string
}

export interface Message {
  id: string
  role: 'user' | 'assistant'
  content: string
  timestamp: Date
  isStreaming?: boolean
  audio?: {
    data: string
    format: string
  }
  audioUrl?: string
  audioLoading?: boolean
  language?: string
}

export interface CardData {
  card_name: string
  card_description: string
  card_image_url: string
  conversation_ai_enabled: boolean
  ai_instruction: string
  ai_knowledge_base: string
  ai_prompt?: string  // Legacy field, mapped from ai_instruction
  is_activated: boolean
}

export interface AIAssistantProps {
  contentItemName: string
  contentItemContent: string
  contentItemKnowledgeBase: string // Content item's own knowledge (max 500 words)
  parentContentKnowledgeBase: string // Parent content item's knowledge (for sub-items)
  cardData: CardData
}

export type ConversationMode = 'chat-completion' | 'realtime'
export type InputMode = 'text' | 'voice'

export interface RealtimeConnectionState {
  isConnected: boolean
  isSpeaking: boolean
  status: 'disconnected' | 'connecting' | 'connected' | 'error'
  error: string | null
}

export interface SessionConfig {
  model: string
  modalities?: string[]  // GA API uses "modalities"
  voice?: string  // GA API: voice at top level
  instructions?: string
  input_audio_format?: string  // GA API: simple format string
  output_audio_format?: string  // GA API: simple format string
  turn_detection?: {
    type: string
    threshold?: number
    prefix_padding_ms?: number
    silence_duration_ms?: number
  }
  temperature?: number
  max_response_output_tokens?: number
}

export interface ChatCompletionState {
  isLoading: boolean
  error: string | null
  streamingMessageId: string | null
}

export interface VoiceRecordingState {
  isRecording: boolean
  recordingDuration: number
  isCancelZone: boolean
  error: string | null
}

