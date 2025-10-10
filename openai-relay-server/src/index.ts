import express from 'express'
import { createServer } from 'http'
import { WebSocketServer, WebSocket as WSWebSocket } from 'ws'
import cors from 'cors'
import dotenv from 'dotenv'

// Load environment variables
dotenv.config()

// Configuration
const PORT = process.env.PORT || 8080
const OPENAI_API_KEY = process.env.OPENAI_API_KEY
const OPENAI_API_URL = process.env.OPENAI_API_URL || 'wss://api.openai.com/v1/realtime'
const OPENAI_REALTIME_MODEL = process.env.OPENAI_REALTIME_MODEL || 'gpt-4o-mini-realtime-preview-2024-12-17'
const ALLOWED_ORIGINS = process.env.ALLOWED_ORIGINS?.split(',') || ['*']

// Validate required configuration
if (!OPENAI_API_KEY) {
  console.error('[ERROR] OPENAI_API_KEY environment variable is required')
  process.exit(1)
}

// Simple logger
const log = {
  info: (msg: string, data?: any) => {
    console.log(`[INFO] ${new Date().toISOString()} - ${msg}`, data || '')
  },
  error: (msg: string, data?: any) => {
    console.error(`[ERROR] ${new Date().toISOString()} - ${msg}`, data || '')
  },
  debug: (msg: string, data?: any) => {
    if (process.env.DEBUG === 'true') {
      console.log(`[DEBUG] ${new Date().toISOString()} - ${msg}`, data || '')
    }
  },
  warn: (msg: string, data?: any) => {
    console.warn(`[WARN] ${new Date().toISOString()} - ${msg}`, data || '')
  }
}

// Connection tracking
const connections = new Map<string, {
  clientWs: any
  openaiWs: any
  sessionId: string
}>()

// Create Express app
const app = express()
app.use(cors({ origin: ALLOWED_ORIGINS }))
app.use(express.json())

// Health check endpoint
app.get('/health', (_req: any, res: any) => {
  res.json({ 
    status: 'healthy',
    connections: connections.size,
    timestamp: new Date().toISOString()
  })
})

// Create HTTP server
const server = createServer(app)

// Create WebSocket server
const wss = new WebSocketServer({ 
  server,
  path: '/realtime'
})

// Handle WebSocket connections
wss.on('connection', (clientWs: any, req: any) => {
  const sessionId = `session-${Date.now()}-${Math.random().toString(36).substring(7)}`
  const clientIp = req.headers['x-forwarded-for'] || req.socket.remoteAddress
  
  log.info(`New client connection: ${sessionId}`, { 
    ip: clientIp,
    origin: req.headers.origin 
  })
  
  // Use model from environment only (security: prevent client from specifying model)
  const model = OPENAI_REALTIME_MODEL
  
  log.info(`Using model: ${model}`)
  
  // Store connection
  const connection = {
    clientWs,
    openaiWs: null as any,
    sessionId
  }
  connections.set(sessionId, connection)
  
  // Connect to OpenAI with model in URL
  try {
    const openaiUrl = `${OPENAI_API_URL}?model=${model}`
    const openaiWs = new WSWebSocket(openaiUrl, 'realtime', {
      headers: {
        'Authorization': `Bearer ${OPENAI_API_KEY}`,
        'OpenAI-Beta': 'realtime=v1'
      }
    })
    
    connection.openaiWs = openaiWs
    
    // OpenAI connection opened
    openaiWs.on('open', () => {
      log.info(`Connected to OpenAI: ${sessionId}`)
    })
    
    // Relay messages from OpenAI to client
    openaiWs.on('message', (data: Buffer) => {
      if (clientWs.readyState === WSWebSocket.OPEN) {
        clientWs.send(data)
        
        // Log important messages
        try {
          const message = JSON.parse(data.toString())
          if (message.type === 'error') {
            log.error(`OpenAI error: ${sessionId}`, message.error)
          } else if (message.type === 'session.created') {
            log.debug(`Session created: ${sessionId}`)
          } else if (message.type === 'session.updated') {
            log.debug(`Session updated: ${sessionId}`)
          }
        } catch {
          // Binary data, skip logging
        }
      }
    })
    
    // OpenAI connection error
    openaiWs.on('error', (error: any) => {
      log.error(`OpenAI error: ${sessionId}`, error)
      clientWs.close(1011, 'OpenAI connection error')
    })
    
    // OpenAI connection closed
    openaiWs.on('close', (code: any, reason: any) => {
      log.info(`OpenAI closed: ${sessionId}`, { code, reason: reason.toString() })
      if (clientWs.readyState === WSWebSocket.OPEN) {
        clientWs.close(code, reason.toString())
      }
      connections.delete(sessionId)
    })
    
  } catch (err) {
    log.error(`Failed to connect to OpenAI: ${sessionId}`, err)
    clientWs.close(1011, 'Failed to connect to OpenAI')
    connections.delete(sessionId)
    return
  }
  
  // Relay messages from client to OpenAI
  clientWs.on('message', (data: Buffer) => {
    if (connection.openaiWs?.readyState === WSWebSocket.OPEN) {
      connection.openaiWs.send(data)
      
      // Log session updates for debugging
      try {
        const message = JSON.parse(data.toString())
        if (message.type === 'session.update') {
          log.info(`Session update from client: ${sessionId}`, message.session)
        }
      } catch {
        // Not a JSON message, probably binary audio data
      }
    } else {
      log.warn(`OpenAI connection not ready: ${sessionId}`)
    }
  })
  
  // Client error
  clientWs.on('error', (error: any) => {
    log.error(`Client error: ${sessionId}`, error)
  })
  
  // Client disconnected
  clientWs.on('close', (code: any, reason: any) => {
    log.info(`Client disconnected: ${sessionId}`, { code, reason })
    
    // Close OpenAI connection
    if (connection.openaiWs) {
      connection.openaiWs.close(1000, 'Client disconnected')
    }
    
    connections.delete(sessionId)
  })
})

// Start server
server.listen(PORT, () => {
  log.info('OpenAI Realtime Relay Server started', {
    port: PORT,
    mode: 'OPEN PROXY',
    connections: 0
  })
  
  console.log(`
╔════════════════════════════════════════════════════╗
║                                                    ║
║     OpenAI Realtime Relay Server (Simplified)     ║
║                                                    ║
║     Mode: OPEN PROXY                              ║
║     Port: ${PORT}                                    ║
║     Status: Ready                                  ║
║                                                    ║
║     ⚠️  Server uses its own API key               ║
║                                                    ║
╚════════════════════════════════════════════════════╝
  `)
})

// Graceful shutdown
process.on('SIGTERM', () => {
  log.info('SIGTERM received, closing connections...')
  
  connections.forEach(conn => {
    conn.clientWs.close(1001, 'Server shutting down')
    conn.openaiWs?.close(1001, 'Server shutting down')
  })
  
  server.close(() => {
    log.info('Server shut down gracefully')
    process.exit(0)
  })
})
