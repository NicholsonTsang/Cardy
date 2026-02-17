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
  card_id?: string  // Card UUID for voice billing (passed from route params)
  card_name: string
  card_description: string
  card_image_url: string
  conversation_ai_enabled: boolean
  ai_instruction?: string
  ai_knowledge_base?: string
  ai_welcome_general?: string  // Custom welcome message for General AI Assistant
  ai_welcome_item?: string  // Custom welcome message for Content Item AI Assistant
  ai_prompt?: string  // Legacy field, mapped from ai_instruction
  content_directory?: string  // Compact list of all content items for General Assistant context
  realtime_voice_enabled?: boolean  // Per-project toggle for realtime voice conversations
  is_activated: boolean
}

// Assistant mode types
export type AssistantMode = 'card-level' | 'content-item'

// Props for Card-Level Assistant (General)
export interface CardLevelAssistantProps {
  mode: 'card-level'
  cardData: CardData
}

// Props for Content Item Assistant
export interface ContentItemAssistantProps {
  mode: 'content-item'
  contentItemName: string
  contentItemContent: string
  contentItemKnowledgeBase: string // Content item's own knowledge (max 500 words)
  parentContentName?: string // Parent content item name (for sub-items)
  parentContentDescription?: string // Parent content item description (for sub-items)
  parentContentKnowledgeBase?: string // Parent content item's knowledge (for sub-items)
  cardData: CardData
}

// Union type for AI Assistant props
export type AIAssistantProps = CardLevelAssistantProps | ContentItemAssistantProps

// Legacy props interface for backward compatibility
export interface LegacyAIAssistantProps {
  contentItemName: string
  contentItemContent: string
  contentItemKnowledgeBase: string
  parentContentKnowledgeBase: string
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

