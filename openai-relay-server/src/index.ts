import express from 'express'
import { WebSocketServer, WebSocket as WSWebSocket } from 'ws'
import { createServer } from 'http'
import cors from 'cors'
import helmet from 'helmet'
import compression from 'compression'
import dotenv from 'dotenv'
import { IncomingMessage } from 'http'

// Load environment variables
dotenv.config()

// Types
interface ClientConnection {
  clientWs: WSWebSocket
  openaiWs: WSWebSocket | null
  isAlive: boolean
  lastActivity: number
  sessionId: string
}

interface OpenAIMessage {
  type: string
  [key: string]: any
}

// Configuration
const PORT = parseInt(process.env.PORT || '8080', 10)
const OPENAI_API_URL = process.env.OPENAI_API_URL || 'wss://api.openai.com/v1/realtime'
const OPENAI_API_KEY = process.env.OPENAI_API_KEY || ''
const MAX_CONNECTIONS = parseInt(process.env.MAX_CONNECTIONS || '100', 10)
const HEARTBEAT_INTERVAL = parseInt(process.env.HEARTBEAT_INTERVAL || '30000', 10)
const INACTIVITY_TIMEOUT = parseInt(process.env.INACTIVITY_TIMEOUT || '300000', 10) // 5 minutes
const ALLOWED_ORIGINS = process.env.ALLOWED_ORIGINS?.split(',') || ['*']

// Validate required configuration
if (!OPENAI_API_KEY) {
  log.error('OPENAI_API_KEY environment variable is required')
  process.exit(1)
}

// Logging utilities
const log = {
  info: (msg: string, data?: any) => {
    console.log(`[INFO] ${new Date().toISOString()} - ${msg}`, data || '')
  },
  error: (msg: string, error?: any) => {
    console.error(`[ERROR] ${new Date().toISOString()} - ${msg}`, error || '')
  },
  warn: (msg: string, data?: any) => {
    console.warn(`[WARN] ${new Date().toISOString()} - ${msg}`, data || '')
  },
  debug: (msg: string, data?: any) => {
    if (process.env.DEBUG === 'true') {
      console.debug(`[DEBUG] ${new Date().toISOString()} - ${msg}`, data || '')
    }
  }
}

// Stats tracking
const stats = {
  totalConnections: 0,
  activeConnections: 0,
  messagesRelayed: 0,
  errors: 0,
  startTime: Date.now()
}

// Active connections map
const connections = new Map<string, ClientConnection>()

// Create Express app
const app = express()

// Middleware
app.use(helmet({
  contentSecurityPolicy: false,
  crossOriginEmbedderPolicy: false
}))
app.use(compression())
app.use(cors({
  origin: ALLOWED_ORIGINS[0] === '*' ? '*' : ALLOWED_ORIGINS,
  credentials: true
}))
app.use(express.json())

// Health check endpoint
app.get('/health', (_req, res) => {
  const uptime = Date.now() - stats.startTime
  const health = {
    status: 'healthy',
    uptime: Math.floor(uptime / 1000),
    stats: {
      totalConnections: stats.totalConnections,
      activeConnections: stats.activeConnections,
      messagesRelayed: stats.messagesRelayed,
      errors: stats.errors
    },
    timestamp: new Date().toISOString()
  }
  res.json(health)
})

// Readiness check endpoint
app.get('/ready', (_req, res) => {
  if (stats.activeConnections < MAX_CONNECTIONS) {
    res.json({ status: 'ready' })
  } else {
    res.status(503).json({ status: 'capacity_reached' })
  }
})

// Stats endpoint
app.get('/stats', (_req, res) => {
  res.json({
    ...stats,
    maxConnections: MAX_CONNECTIONS,
    uptime: Math.floor((Date.now() - stats.startTime) / 1000)
  })
})

// Create HTTP server
const server = createServer(app)

// Create WebSocket server
const wss = new WebSocketServer({ 
  server,
  path: '/realtime',
  perMessageDeflate: {
    zlibDeflateOptions: {
      chunkSize: 1024,
      memLevel: 7,
      level: 3
    },
    zlibInflateOptions: {
      chunkSize: 10 * 1024
    },
    clientNoContextTakeover: true,
    serverNoContextTakeover: true,
    serverMaxWindowBits: 10,
    concurrencyLimit: 10,
    threshold: 1024
  }
})

log.info('WebSocket server initialized')

// Parse WebSocket URL to extract model parameter
function parseWebSocketAuth(req: IncomingMessage): { model: string } {
  const url = new URL(req.url || '', `http://${req.headers.host}`)
  const model = url.searchParams.get('model') || 'gpt-4o-mini-realtime-preview-2024-12-17'
  
  log.debug('WebSocket connection request', { model })
  
  return { model }
}

// Handle WebSocket connections from clients
wss.on('connection', (clientWs: WSWebSocket, req: IncomingMessage) => {
  const sessionId = `session-${Date.now()}-${Math.random().toString(36).slice(2, 9)}`
  
  log.info(`New client connection: ${sessionId}`, {
    ip: req.socket.remoteAddress,
    origin: req.headers.origin
  })
  
  // Check connection limit
  if (stats.activeConnections >= MAX_CONNECTIONS) {
    log.warn(`Connection limit reached (${MAX_CONNECTIONS}), rejecting: ${sessionId}`)
    clientWs.close(1008, 'Server at capacity')
    return
  }
  
  // Parse model from URL parameters
  const { model } = parseWebSocketAuth(req)
  log.info(`Connection accepted: ${sessionId}`, { model })
  
  // Update stats
  stats.totalConnections++
  stats.activeConnections++
  
  // Create connection object
  const connection: ClientConnection = {
    clientWs,
    openaiWs: null,
    isAlive: true,
    lastActivity: Date.now(),
    sessionId
  }
  
  connections.set(sessionId, connection)
  
  // Connect to OpenAI Realtime API
  const openaiUrl = `${OPENAI_API_URL}?model=${encodeURIComponent(model)}`
  log.info(`Connecting to OpenAI: ${sessionId}`, { url: openaiUrl })
  
  try {
    // Use the server's OpenAI API key from environment
    const openaiWs = new WSWebSocket(openaiUrl, [
      'realtime',
      `openai-insecure-api-key.${OPENAI_API_KEY}`
      // Note: 'openai-beta.realtime-v1' removed - using GA API (2024-12-17 model)
    ])
    
    connection.openaiWs = openaiWs
    
    // OpenAI WebSocket handlers
    openaiWs.on('open', () => {
      log.info(`Connected to OpenAI: ${sessionId}`)
      // Note: Don't send relay.connected message as it may interfere with OpenAI protocol
      // The client will know connection is successful when it receives OpenAI's session.created
    })
    
    openaiWs.on('message', (data: Buffer) => {
      connection.lastActivity = Date.now()
      stats.messagesRelayed++
      
      // Forward message to client
      if (clientWs.readyState === WSWebSocket.OPEN) {
        try {
          clientWs.send(data)
          
          // Log message type for debugging
          try {
            const message = JSON.parse(data.toString()) as OpenAIMessage
            
            // Always log errors in full detail
            if (message.type === 'error') {
              log.error(`❌ OpenAI Error Message: ${sessionId}`, message)
            } else {
              log.debug(`OpenAI → Client: ${sessionId}`, { type: message.type })
            }
          } catch {
            // Binary data, skip logging
          }
        } catch (err) {
          log.error(`Failed to forward OpenAI message to client: ${sessionId}`, err)
          stats.errors++
        }
      }
    })
    
    openaiWs.on('error', (error) => {
      log.error(`OpenAI WebSocket error: ${sessionId}`, error)
      stats.errors++
      
      // Notify client of error
      if (clientWs.readyState === WSWebSocket.OPEN) {
        clientWs.send(JSON.stringify({
          type: 'error',
          error: {
            type: 'relay_error',
            message: 'OpenAI connection error'
          }
        }))
      }
    })
    
    openaiWs.on('close', (code, reason) => {
      log.info(`OpenAI connection closed: ${sessionId}`, { code, reason: reason.toString() })
      
      // Close client connection
      if (clientWs.readyState === WSWebSocket.OPEN) {
        clientWs.close(code, reason.toString())
      }
      
      cleanup(sessionId)
    })
    
  } catch (err) {
    log.error(`Failed to connect to OpenAI: ${sessionId}`, err)
    stats.errors++
    clientWs.close(1011, 'Failed to establish upstream connection')
    cleanup(sessionId)
    return
  }
  
  // Client WebSocket handlers
  clientWs.on('message', (data: Buffer) => {
    connection.lastActivity = Date.now()
    stats.messagesRelayed++
    
    // Forward message to OpenAI
    if (connection.openaiWs && connection.openaiWs.readyState === WSWebSocket.OPEN) {
      try {
        connection.openaiWs.send(data)
        
        // Log message type for debugging
        try {
          const message = JSON.parse(data.toString()) as OpenAIMessage
          
          // Always log session.update in full detail for debugging
          if (message.type === 'session.update') {
            log.info(`📤 session.update payload: ${sessionId}`, message)
          } else {
            log.debug(`Client → OpenAI: ${sessionId}`, { type: message.type })
          }
        } catch {
          // Binary data, skip logging
        }
      } catch (err) {
        log.error(`Failed to forward client message to OpenAI: ${sessionId}`, err)
        stats.errors++
      }
    } else {
      log.warn(`OpenAI connection not ready: ${sessionId}`)
    }
  })
  
  clientWs.on('error', (error) => {
    log.error(`Client WebSocket error: ${sessionId}`, error)
    stats.errors++
  })
  
  clientWs.on('close', (code, reason) => {
    log.info(`Client disconnected: ${sessionId}`, { code, reason: reason.toString() })
    
    // Close OpenAI connection
    if (connection.openaiWs && connection.openaiWs.readyState === WSWebSocket.OPEN) {
      connection.openaiWs.close(1000, 'Client disconnected')
    }
    
    cleanup(sessionId)
  })
  
  // Heartbeat - pong response
  clientWs.on('pong', () => {
    connection.isAlive = true
    connection.lastActivity = Date.now()
  })
})

// Cleanup function
function cleanup(sessionId: string) {
  const connection = connections.get(sessionId)
  if (connection) {
    // Close OpenAI connection if still open
    if (connection.openaiWs) {
      try {
        if (connection.openaiWs.readyState === WSWebSocket.OPEN || 
            connection.openaiWs.readyState === WSWebSocket.CONNECTING) {
          connection.openaiWs.close(1000)
        }
      } catch (err) {
        log.error(`Error closing OpenAI connection: ${sessionId}`, err)
      }
    }
    
    // Close client connection if still open
    try {
      if (connection.clientWs.readyState === WSWebSocket.OPEN || 
          connection.clientWs.readyState === WSWebSocket.CONNECTING) {
        connection.clientWs.close(1000)
      }
    } catch (err) {
      log.error(`Error closing client connection: ${sessionId}`, err)
    }
    
    connections.delete(sessionId)
    stats.activeConnections--
    
    log.info(`Cleaned up connection: ${sessionId}`, {
      remainingConnections: stats.activeConnections
    })
  }
}

// Heartbeat interval - ping all clients
const heartbeatInterval = setInterval(() => {
  const now = Date.now()
  
  connections.forEach((connection, sessionId) => {
    // Check if connection is inactive
    if (now - connection.lastActivity > INACTIVITY_TIMEOUT) {
      log.warn(`Closing inactive connection: ${sessionId}`)
      cleanup(sessionId)
      return
    }
    
    // Check if client is alive
    if (!connection.isAlive) {
      log.warn(`Terminating dead connection: ${sessionId}`)
      cleanup(sessionId)
      return
    }
    
    // Send ping
    connection.isAlive = false
    try {
      if (connection.clientWs.readyState === WSWebSocket.OPEN) {
        connection.clientWs.ping()
      }
    } catch (err) {
      log.error(`Failed to ping client: ${sessionId}`, err)
      cleanup(sessionId)
    }
  })
  
  log.debug('Heartbeat check completed', {
    activeConnections: stats.activeConnections,
    totalConnections: stats.totalConnections
  })
}, HEARTBEAT_INTERVAL)

// Graceful shutdown
process.on('SIGTERM', () => {
  log.info('SIGTERM received, starting graceful shutdown')
  
  clearInterval(heartbeatInterval)
  
  // Close all connections
  connections.forEach((_connection, sessionId) => {
    cleanup(sessionId)
  })
  
  // Close WebSocket server
  wss.close(() => {
    log.info('WebSocket server closed')
  })
  
  // Close HTTP server
  server.close(() => {
    log.info('HTTP server closed')
    process.exit(0)
  })
  
  // Force exit after 30 seconds
  setTimeout(() => {
    log.error('Forced shutdown after timeout')
    process.exit(1)
  }, 30000)
})

process.on('SIGINT', () => {
  log.info('SIGINT received, starting graceful shutdown')
  process.emit('SIGTERM' as any)
})

// Start server
server.listen(PORT, () => {
  log.info(`OpenAI Realtime Relay Server started (OPEN PROXY MODE)`, {
    port: PORT,
    maxConnections: MAX_CONNECTIONS,
    heartbeatInterval: HEARTBEAT_INTERVAL,
    inactivityTimeout: INACTIVITY_TIMEOUT,
    environment: process.env.NODE_ENV || 'development',
    warning: '⚠️  Server uses OpenAI API key directly - ensure proper network security!'
  })
})

// Handle uncaught errors
process.on('uncaughtException', (error) => {
  log.error('Uncaught exception', error)
  stats.errors++
})

process.on('unhandledRejection', (reason, promise) => {
  log.error('Unhandled rejection', { reason, promise })
  stats.errors++
})

