# Socket.IO Real-Time Translation Progress

**Date:** November 5, 2025  
**Status:** ✅ Implemented

## Overview

Socket.IO is now integrated to provide real-time translation progress updates to the frontend. Clients can join a room for their specific translation job and receive live updates about language progress, batch completion, and errors.

## Architecture

### Backend Components

1. **Socket Service** (`src/services/socket.service.ts`)
   - Manages Socket.IO server instance
   - Provides event emission utilities
   - Defines typed event interfaces

2. **Server Integration** (`src/index.ts`)
   - Initializes Socket.IO with HTTP server
   - Configures CORS for WebSocket connections

3. **Translation Routes** (`src/routes/translation.routes.ts`)
   - Emits progress events at key milestones
   - Uses room-based messaging for targeted updates

## Event Types

### 1. `translation:started`
Emitted when translation job begins for all languages.

```typescript
{
  type: 'translation:started',
  cardId: string,
  totalLanguages: number,
  languages: string[],
  timestamp: string
}
```

### 2. `language:started`
Emitted when a specific language starts processing. Now includes `totalBatches` so the frontend can display accurate progress from the start.

```typescript
{
  type: 'language:started',
  cardId: string,
  language: string,           // e.g., 'ja', 'zh-Hans'
  languageIndex: number,       // Current language (1-indexed)
  totalLanguages: number,
  totalBatches: number,        // Total number of batches for this language
  timestamp: string
}
```

### 3. `batch:progress`
Emitted when a batch within a language **completes** processing. This ensures the progress bar only updates after work is done.

```typescript
{
  type: 'batch:progress',
  cardId: string,
  language: string,
  batchIndex: number,          // Completed batch number (1-indexed)
  totalBatches: number,
  itemsInBatch: number,
  timestamp: string
}
```

### 4. `language:completed`
Emitted when a language is successfully translated and saved.

```typescript
{
  type: 'language:completed',
  cardId: string,
  language: string,
  languageIndex: number,
  totalLanguages: number,
  timestamp: string
}
```

### 5. `language:failed`
Emitted when a language fails to translate.

```typescript
{
  type: 'language:failed',
  cardId: string,
  language: string,
  error: string,
  timestamp: string
}
```

### 6. `translation:completed`
Emitted when all languages have been processed.

```typescript
{
  type: 'translation:completed',
  cardId: string,
  completedLanguages: string[],
  failedLanguages: string[],
  duration: number,            // Total time in ms
  timestamp: string
}
```

### 7. `translation:error`
Emitted when the entire translation job fails (before language processing).

```typescript
{
  type: 'translation:error',
  cardId: string,
  error: string,
  timestamp: string
}
```

## Frontend Integration (Vue 3)

### Install Socket.IO Client

```bash
npm install socket.io-client
```

### Example: Translation Progress Component

```vue
<script setup lang="ts">
import { ref, onMounted, onBeforeUnmount } from 'vue';
import { io, Socket } from 'socket.io-client';
import { useAuthStore } from '@/stores/auth';

const props = defineProps<{
  cardId: string;
}>();

const authStore = useAuthStore();
let socket: Socket | null = null;

// Progress state
const isTranslating = ref(false);
const currentLanguage = ref<string>('');
const currentBatch = ref(0);
const totalBatches = ref(0);
const completedLanguages = ref<string[]>([]);
const failedLanguages = ref<string[]>([]);
const progressMessage = ref('');

// Connect to Socket.IO
onMounted(() => {
  const backendUrl = import.meta.env.VITE_BACKEND_URL || 'http://localhost:8080';
  
  socket = io(backendUrl, {
    transports: ['websocket', 'polling'],
  });

  socket.on('connect', () => {
    console.log('✅ Connected to Socket.IO');
    
    // Join the translation room
    socket?.emit('join-translation', {
      userId: authStore.user?.id,
      cardId: props.cardId,
    });
  });

  // Listen for translation progress
  socket.on('translation:progress', (event) => {
    console.log('📡 Translation event:', event);
    
    switch (event.type) {
      case 'translation:started':
        isTranslating.value = true;
        progressMessage.value = `Starting translation for ${event.totalLanguages} languages...`;
        break;
        
      case 'language:started':
        currentLanguage.value = event.language;
        progressMessage.value = `Translating to ${event.language} (${event.languageIndex}/${event.totalLanguages})...`;
        break;
        
      case 'batch:progress':
        currentBatch.value = event.batchIndex;
        totalBatches.value = event.totalBatches;
        progressMessage.value = `Processing batch ${event.batchIndex}/${event.totalBatches} for ${event.language}...`;
        break;
        
      case 'language:completed':
        completedLanguages.value.push(event.language);
        progressMessage.value = `✅ Completed ${event.language}`;
        break;
        
      case 'language:failed':
        failedLanguages.value.push(event.language);
        progressMessage.value = `❌ Failed ${event.language}: ${event.error}`;
        break;
        
      case 'translation:completed':
        isTranslating.value = false;
        completedLanguages.value = event.completedLanguages;
        failedLanguages.value = event.failedLanguages;
        progressMessage.value = `✅ Translation completed! (${event.completedLanguages.length} succeeded, ${event.failedLanguages.length} failed)`;
        break;
        
      case 'translation:error':
        isTranslating.value = false;
        progressMessage.value = `❌ Translation error: ${event.error}`;
        break;
    }
  });

  socket.on('disconnect', () => {
    console.log('❌ Disconnected from Socket.IO');
  });
});

// Cleanup
onBeforeUnmount(() => {
  if (socket) {
    socket.emit('leave-translation', {
      userId: authStore.user?.id,
      cardId: props.cardId,
    });
    socket.disconnect();
  }
});

// Calculate progress percentage
const progressPercentage = computed(() => {
  if (!totalBatches.value) return 0;
  return Math.round((currentBatch.value / totalBatches.value) * 100);
});
</script>

<template>
  <div v-if="isTranslating" class="translation-progress">
    <div class="progress-bar">
      <div class="progress-fill" :style="{ width: `${progressPercentage}%` }"></div>
    </div>
    <p class="progress-message">{{ progressMessage }}</p>
    <div v-if="completedLanguages.length" class="completed-languages">
      ✅ Completed: {{ completedLanguages.join(', ') }}
    </div>
    <div v-if="failedLanguages.length" class="failed-languages">
      ❌ Failed: {{ failedLanguages.join(', ') }}
    </div>
  </div>
</template>

<style scoped>
.translation-progress {
  padding: 1rem;
  border: 1px solid #e0e0e0;
  border-radius: 8px;
  background: #f9f9f9;
}

.progress-bar {
  width: 100%;
  height: 8px;
  background: #e0e0e0;
  border-radius: 4px;
  overflow: hidden;
  margin-bottom: 0.5rem;
}

.progress-fill {
  height: 100%;
  background: linear-gradient(90deg, #4CAF50, #66BB6A);
  transition: width 0.3s ease;
}

.progress-message {
  font-size: 0.9rem;
  color: #555;
  margin: 0.5rem 0;
}

.completed-languages,
.failed-languages {
  font-size: 0.85rem;
  margin-top: 0.5rem;
}

.completed-languages {
  color: #4CAF50;
}

.failed-languages {
  color: #f44336;
}
</style>
```

### Pinia Store Integration

```typescript
// stores/translation.ts
import { defineStore } from 'pinia';
import { io, Socket } from 'socket.io-client';

export const useTranslationStore = defineStore('translation', {
  state: () => ({
    socket: null as Socket | null,
    isTranslating: false,
    currentLanguage: '',
    progress: 0,
    completedLanguages: [] as string[],
    failedLanguages: [] as string[],
  }),

  actions: {
    initSocket(userId: string, cardId: string) {
      const backendUrl = import.meta.env.VITE_BACKEND_URL || 'http://localhost:8080';
      
      this.socket = io(backendUrl, {
        transports: ['websocket', 'polling'],
      });

      this.socket.on('connect', () => {
        this.socket?.emit('join-translation', { userId, cardId });
      });

      this.socket.on('translation:progress', (event) => {
        this.handleProgressEvent(event);
      });
    },

    handleProgressEvent(event: any) {
      switch (event.type) {
        case 'translation:started':
          this.isTranslating = true;
          this.completedLanguages = [];
          this.failedLanguages = [];
          break;
          
        case 'language:started':
          this.currentLanguage = event.language;
          break;
          
        case 'batch:progress':
          this.progress = (event.batchIndex / event.totalBatches) * 100;
          break;
          
        case 'language:completed':
          this.completedLanguages.push(event.language);
          break;
          
        case 'language:failed':
          this.failedLanguages.push(event.language);
          break;
          
        case 'translation:completed':
          this.isTranslating = false;
          this.completedLanguages = event.completedLanguages;
          this.failedLanguages = event.failedLanguages;
          break;
      }
    },

    disconnectSocket() {
      if (this.socket) {
        this.socket.disconnect();
        this.socket = null;
      }
    },
  },
});
```

## Room-Based Messaging

Clients join rooms using the pattern: `translation:{userId}:{cardId}`

This ensures:
- ✅ Only relevant clients receive updates
- ✅ Multiple users can translate different cards simultaneously
- ✅ Multiple browser tabs for the same user/card all receive updates

## Environment Configuration

No additional environment variables needed. Socket.IO uses the same CORS configuration as the REST API:

```bash
ALLOWED_ORIGINS=*  # or comma-separated list
```

## Testing

### Manual Test with Browser Console

```javascript
// Connect to Socket.IO
const socket = io('http://localhost:8080');

// Join a translation room
socket.emit('join-translation', {
  userId: 'your-user-id',
  cardId: 'your-card-id'
});

// Listen for progress
socket.on('translation:progress', (event) => {
  console.log('Progress:', event);
});
```

## Benefits

1. **Real-time feedback** - Users see progress as it happens
2. **Better UX** - No need to poll for status
3. **Multi-tab support** - All tabs get updates
4. **Efficient** - Only transmits events, no polling overhead
5. **Reliable** - Automatic reconnection on disconnect

## Files Modified

- `backend-server/package.json` - Added `socket.io`
- `backend-server/src/services/socket.service.ts` - New socket service
- `backend-server/src/index.ts` - Initialize Socket.IO server
- `backend-server/src/routes/translation.routes.ts` - Emit progress events

## Next Steps (Frontend)

1. Install `socket.io-client` in frontend
2. Create translation progress component or integrate into existing
3. Connect to Socket.IO on component mount
4. Join translation room with user/card IDs
5. Handle progress events to update UI
6. Disconnect socket on component unmount

## Production Considerations

- ✅ Socket.IO automatically handles reconnection
- ✅ Uses WebSocket for low latency, falls back to polling
- ✅ CORS configured same as REST API
- ✅ Room-based messaging prevents cross-contamination
- ⚠️ Consider adding authentication to socket connections (future enhancement)
- ⚠️ Monitor socket connection count in production

