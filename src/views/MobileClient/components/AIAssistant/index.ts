// Main component
export { default as MobileAIAssistant } from './MobileAIAssistantRefactored.vue'

// Sub-components
export { default as AIAssistantModal } from './components/AIAssistantModal.vue'
export { default as ChatInterface } from './components/ChatInterface.vue'
export { default as RealtimeInterface } from './components/RealtimeInterface.vue'
export { default as LanguageSelector } from './components/LanguageSelector.vue'
export { default as MessageBubble } from './components/MessageBubble.vue'
export { default as VoiceInputButton } from './components/VoiceInputButton.vue'

// Composables
export { useRealtimeConnection } from './composables/useRealtimeConnection'
export { useChatCompletion } from './composables/useChatCompletion'
export { useVoiceRecording } from './composables/useVoiceRecording'
export { useCostSafeguards } from './composables/useCostSafeguards'
export { useInactivityTimer } from './composables/useInactivityTimer'

// Types
export type * from './types'

