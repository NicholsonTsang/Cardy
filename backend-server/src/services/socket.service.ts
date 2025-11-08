import { Server as SocketIOServer, Socket } from 'socket.io';
import { Server as HTTPServer } from 'http';

let io: SocketIOServer | null = null;

/**
 * Initialize Socket.IO server
 */
export function initializeSocket(httpServer: HTTPServer, allowedOrigins: string[]): SocketIOServer {
  io = new SocketIOServer(httpServer, {
    cors: {
      origin: allowedOrigins.includes('*') ? '*' : allowedOrigins,
      methods: ['GET', 'POST'],
      credentials: true,
    },
    transports: ['websocket', 'polling'], // Support both transports
  });

  io.on('connection', (socket: Socket) => {
    console.log(`🔌 Socket connected: ${socket.id}`);

    // Join a room for a specific translation job
    socket.on('join-translation', (data: { userId: string; cardId: string }) => {
      const roomName = `translation:${data.userId}:${data.cardId}`;
      socket.join(roomName);
      console.log(`👤 Socket ${socket.id} joined room: ${roomName}`);
    });

    // Leave a room
    socket.on('leave-translation', (data: { userId: string; cardId: string }) => {
      const roomName = `translation:${data.userId}:${data.cardId}`;
      socket.leave(roomName);
      console.log(`👋 Socket ${socket.id} left room: ${roomName}`);
    });

    socket.on('disconnect', () => {
      console.log(`🔌 Socket disconnected: ${socket.id}`);
    });
  });

  console.log('✅ Socket.IO initialized');
  return io;
}

/**
 * Get the Socket.IO server instance
 */
export function getIO(): SocketIOServer {
  if (!io) {
    throw new Error('Socket.IO not initialized. Call initializeSocket first.');
  }
  return io;
}

/**
 * Emit translation progress events to a specific user/card room
 */
export function emitTranslationProgress(
  userId: string,
  cardId: string,
  event: TranslationProgressEvent
): void {
  if (!io) {
    console.warn('⚠️  Socket.IO not initialized, skipping event emission');
    return;
  }

  const roomName = `translation:${userId}:${cardId}`;
  io.to(roomName).emit('translation:progress', event);
  
  console.log(`📡 Emitted ${event.type} to room ${roomName}`);
}

// Event types
export type TranslationProgressEvent =
  | TranslationStartedEvent
  | LanguageStartedEvent
  | BatchProgressEvent
  | BatchCompletedEvent
  | LanguageCompletedEvent
  | LanguageFailedEvent
  | TranslationCompletedEvent
  | TranslationErrorEvent
  | TranslationRetryEvent
  | TranslationFailedEvent;

export interface TranslationStartedEvent {
  type: 'translation:started';
  jobId?: string;  // Optional for synchronous translations
  cardId: string;
  totalLanguages: number;
  languages: string[];
  timestamp: string;
}

export interface LanguageStartedEvent {
  type: 'language:started';
  jobId?: string;  // Optional for synchronous translations
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

export interface BatchCompletedEvent {
  type: 'batch:completed';
  jobId?: string;  // Optional for synchronous translations
  cardId: string;
  language: string;
  batchIndex: number;
  totalBatches: number;
  timestamp: string;
}

export interface LanguageCompletedEvent {
  type: 'language:completed';
  jobId?: string;  // Optional for synchronous translations
  cardId: string;
  language: string;
  languageIndex?: number;  // Optional for synchronous translations
  totalLanguages?: number;  // Optional for synchronous translations
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
  jobId?: string;  // Optional for synchronous translations
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

export interface TranslationRetryEvent {
  type: 'translation:retry';
  jobId?: string;  // Optional for synchronous translations
  cardId: string;
  retryCount: number;
  maxRetries: number;
  timestamp: string;
}

export interface TranslationFailedEvent {
  type: 'translation:failed';
  jobId?: string;  // Optional for synchronous translations
  cardId: string;
  error: string;
  retryCount: number;
  timestamp: string;
}

