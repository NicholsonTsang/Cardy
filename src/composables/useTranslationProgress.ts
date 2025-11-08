import { ref, onUnmounted, computed } from 'vue';
import { io, Socket } from 'socket.io-client';

// Event types matching backend
export type TranslationProgressEvent =
  | TranslationStartedEvent
  | LanguageStartedEvent
  | BatchProgressEvent
  | LanguageCompletedEvent
  | LanguageFailedEvent
  | TranslationCompletedEvent
  | TranslationErrorEvent;

export interface TranslationStartedEvent {
  type: 'translation:started';
  cardId: string;
  totalLanguages: number;
  languages: string[];
  timestamp: string;
}

export interface LanguageStartedEvent {
  type: 'language:started';
  cardId: string;
  language: string;
  languageIndex: number;
  totalLanguages: number;
  totalBatches: number;
  timestamp: string;
}

export interface BatchProgressEvent {
  type: 'batch:progress';
  cardId: string;
  language: string;
  batchIndex: number;
  totalBatches: number;
  itemsInBatch: number;
  timestamp: string;
}

export interface LanguageCompletedEvent {
  type: 'language:completed';
  cardId: string;
  language: string;
  languageIndex: number;
  totalLanguages: number;
  duration?: number; // Duration in milliseconds
  timestamp: string;
}

export interface LanguageFailedEvent {
  type: 'language:failed';
  cardId: string;
  language: string;
  error: string;
  timestamp: string;
}

export interface TranslationCompletedEvent {
  type: 'translation:completed';
  cardId: string;
  completedLanguages: string[];
  failedLanguages: string[];
  duration: number;
  timestamp: string;
}

export interface TranslationErrorEvent {
  type: 'translation:error';
  cardId: string;
  error: string;
  timestamp: string;
}

// Language names mapping
const LANGUAGE_NAMES: Record<string, string> = {
  'en': 'English',
  'zh-Hant': 'Traditional Chinese',
  'zh-Hans': 'Simplified Chinese',
  'ja': 'Japanese',
  'ko': 'Korean',
  'es': 'Spanish',
  'fr': 'French',
  'ru': 'Russian',
  'ar': 'Arabic',
  'th': 'Thai',
};

// Per-language progress tracking
export interface LanguageProgress {
  language: string;
  status: 'pending' | 'in_progress' | 'completed' | 'failed';
  currentBatch: number;
  totalBatches: number;
  batchProgress: number;
  error?: string;
}

export function useTranslationProgress() {
  const socket = ref<Socket | null>(null);
  const isConnected = ref(false);
  
  // Progress state
  const isTranslating = ref(false);
  const currentLanguage = ref('');
  const currentLanguageIndex = ref(0);
  const totalLanguages = ref(0);
  const currentBatch = ref(0);
  const totalBatches = ref(0);
  const completedLanguages = ref<string[]>([]);
  const failedLanguages = ref<string[]>([]);
  const progressMessage = ref('');
  const errorMessage = ref('');
  
  // Per-language progress tracking
  const languageProgress = ref<Record<string, LanguageProgress>>({});
  
  // Computed percentage
  const overallProgress = computed(() => {
    if (totalLanguages.value === 0) return 0;
    const completedCount = completedLanguages.value.length + failedLanguages.value.length;
    return Math.round((completedCount / totalLanguages.value) * 100);
  });
  
  const batchProgress = computed(() => {
    if (totalBatches.value === 0) return 0;
    return Math.round((currentBatch.value / totalBatches.value) * 100);
  });

  const currentLanguageName = computed(() => {
    return LANGUAGE_NAMES[currentLanguage.value] || currentLanguage.value;
  });

  /**
   * Connect to Socket.IO server
   */
  function connect(userId: string, cardId: string) {
    if (socket.value?.connected) {
      console.log('⚠️ Socket already connected');
      return;
    }

    const backendUrl = import.meta.env.VITE_BACKEND_URL || 'http://localhost:8080';
    
    console.log('🔌 Connecting to Socket.IO at', backendUrl);
    
    socket.value = io(backendUrl, {
      transports: ['websocket', 'polling'],
      reconnection: true,
      reconnectionDelay: 1000,
      reconnectionAttempts: 5,
    });

    socket.value.on('connect', () => {
      console.log('✅ Socket.IO connected');
      isConnected.value = true;
      
      // Join the translation room
      socket.value?.emit('join-translation', { userId, cardId });
      console.log(`📡 Joined translation room for card ${cardId}`);
    });

    socket.value.on('disconnect', () => {
      console.log('❌ Socket.IO disconnected');
      isConnected.value = false;
    });

    socket.value.on('connect_error', (error) => {
      console.error('🔴 Socket.IO connection error:', error);
      isConnected.value = false;
    });

    // Listen for translation progress events
    socket.value.on('translation:progress', handleProgressEvent);
  }

  /**
   * Handle progress events from backend
   */
  function handleProgressEvent(event: TranslationProgressEvent) {
    console.log('📡 Translation event:', event.type, event);
    
    switch (event.type) {
      case 'translation:started':
        isTranslating.value = true;
        totalLanguages.value = event.totalLanguages;
        completedLanguages.value = [];
        failedLanguages.value = [];
        currentLanguage.value = '';
        currentLanguageIndex.value = 0;
        currentBatch.value = 0;
        totalBatches.value = 0;
        errorMessage.value = '';
        progressMessage.value = `Starting translation for ${event.totalLanguages} language${event.totalLanguages > 1 ? 's' : ''}...`;
        
        // Initialize language progress for all languages
        languageProgress.value = {};
        event.languages.forEach(lang => {
          languageProgress.value[lang] = {
            language: lang,
            status: 'pending',
            currentBatch: 0,
            totalBatches: 0,
            batchProgress: 0,
          };
        });
        break;
        
      case 'language:started':
        currentLanguage.value = event.language;
        currentLanguageIndex.value = event.languageIndex;
        totalLanguages.value = event.totalLanguages;
        currentBatch.value = 0;
        totalBatches.value = event.totalBatches;
        progressMessage.value = `Translating to ${LANGUAGE_NAMES[event.language] || event.language} (${event.languageIndex}/${event.totalLanguages})...`;
        
        // Update language progress with known totalBatches
        if (languageProgress.value[event.language]) {
          languageProgress.value[event.language].status = 'in_progress';
          languageProgress.value[event.language].currentBatch = 0;
          languageProgress.value[event.language].totalBatches = event.totalBatches;
          languageProgress.value[event.language].batchProgress = 0;
        }
        break;
        
      case 'batch:progress':
        currentBatch.value = event.batchIndex;
        totalBatches.value = event.totalBatches;
        progressMessage.value = `Completed batch ${event.batchIndex}/${event.totalBatches} for ${LANGUAGE_NAMES[event.language] || event.language} (${event.itemsInBatch} items)`;
        
        // Update language progress
        if (languageProgress.value[event.language]) {
          languageProgress.value[event.language].currentBatch = event.batchIndex;
          languageProgress.value[event.language].totalBatches = event.totalBatches;
          languageProgress.value[event.language].batchProgress = Math.round((event.batchIndex / event.totalBatches) * 100);
        }
        break;
        
      case 'language:completed':
        if (!completedLanguages.value.includes(event.language)) {
          completedLanguages.value.push(event.language);
        }
        progressMessage.value = `✅ Completed ${LANGUAGE_NAMES[event.language] || event.language}`;
        
        // Update language progress
        if (languageProgress.value[event.language]) {
          languageProgress.value[event.language].status = 'completed';
          languageProgress.value[event.language].batchProgress = 100;
        }
        break;
        
      case 'language:failed':
        if (!failedLanguages.value.includes(event.language)) {
          failedLanguages.value.push(event.language);
        }
        errorMessage.value = event.error;
        progressMessage.value = `❌ Failed ${LANGUAGE_NAMES[event.language] || event.language}: ${event.error}`;
        
        // Update language progress
        if (languageProgress.value[event.language]) {
          languageProgress.value[event.language].status = 'failed';
          languageProgress.value[event.language].error = event.error;
        }
        break;
        
      case 'translation:completed':
        isTranslating.value = false;
        completedLanguages.value = event.completedLanguages;
        failedLanguages.value = event.failedLanguages;
        currentLanguage.value = '';
        currentBatch.value = 0;
        totalBatches.value = 0;
        
        const total = event.completedLanguages.length + event.failedLanguages.length;
        if (event.failedLanguages.length === 0) {
          progressMessage.value = `✅ All ${event.completedLanguages.length} language${event.completedLanguages.length > 1 ? 's' : ''} completed successfully!`;
        } else {
          progressMessage.value = `Translation completed: ${event.completedLanguages.length} succeeded, ${event.failedLanguages.length} failed`;
        }
        break;
        
      case 'translation:error':
        isTranslating.value = false;
        errorMessage.value = event.error;
        progressMessage.value = `❌ Translation error: ${event.error}`;
        break;
    }
  }

  /**
   * Disconnect from Socket.IO
   */
  function disconnect() {
    if (socket.value) {
      console.log('🔌 Disconnecting Socket.IO');
      socket.value.disconnect();
      socket.value = null;
      isConnected.value = false;
    }
  }

  /**
   * Reset progress state
   */
  function reset() {
    isTranslating.value = false;
    currentLanguage.value = '';
    currentLanguageIndex.value = 0;
    totalLanguages.value = 0;
    currentBatch.value = 0;
    totalBatches.value = 0;
    completedLanguages.value = [];
    failedLanguages.value = [];
    progressMessage.value = '';
    errorMessage.value = '';
    languageProgress.value = {};
  }

  // Cleanup on component unmount
  onUnmounted(() => {
    disconnect();
  });

  return {
    // Connection state
    socket,
    isConnected,
    
    // Progress state
    isTranslating,
    currentLanguage,
    currentLanguageName,
    currentLanguageIndex,
    totalLanguages,
    currentBatch,
    totalBatches,
    completedLanguages,
    failedLanguages,
    progressMessage,
    errorMessage,
    languageProgress,
    
    // Computed
    overallProgress,
    batchProgress,
    
    // Methods
    connect,
    disconnect,
    reset,
  };
}

