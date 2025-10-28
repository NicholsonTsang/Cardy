import express, { Request, Response } from 'express';
import cors from 'cors';
import helmet from 'helmet';
import rateLimit from 'express-rate-limit';
import dotenv from 'dotenv';

// Load environment variables
dotenv.config();

const app = express();
const PORT = process.env.PORT || 8080;
const OPENAI_API_KEY = process.env.OPENAI_API_KEY;

// Validate required environment variables
if (!OPENAI_API_KEY) {
  console.error('❌ ERROR: OPENAI_API_KEY is required');
  process.exit(1);
}

// Security middleware
app.use(helmet());

// CORS configuration - allow your frontend origins
const allowedOrigins = process.env.ALLOWED_ORIGINS?.split(',') || ['http://localhost:5173', 'http://localhost:3000'];
app.use(cors({
  origin: (origin, callback) => {
    // Allow requests with no origin (mobile apps, Postman, etc.)
    if (!origin) return callback(null, true);
    
    // Allow all origins in development (when * is specified)
    if (allowedOrigins.includes('*')) return callback(null, true);
    
    if (allowedOrigins.includes(origin)) {
      callback(null, true);
    } else {
      console.warn(`⚠️  Blocked request from origin: ${origin}`);
      callback(new Error('Not allowed by CORS'));
    }
  },
  credentials: true
}));

// Rate limiting to prevent abuse
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // Limit each IP to 100 requests per windowMs
  message: 'Too many requests from this IP, please try again later.',
  standardHeaders: true,
  legacyHeaders: false,
});
app.use('/offer', limiter);

// Body parsing middleware
app.use(express.json({ limit: '10mb' }));
app.use(express.text({ type: 'application/sdp' }));

// Health check endpoint
app.get('/health', (_req: Request, res: Response) => {
  res.json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    version: process.env.npm_package_version || '1.0.0'
  });
});

// Main relay endpoint - handles WebRTC SDP exchange
app.post('/offer', async (req: Request, res: Response) => {
  const startTime = Date.now();
  
  try {
    const { sdp, model, token } = req.body;
    
    // Validate request
    if (!sdp) {
      return res.status(400).json({
        error: 'Missing SDP offer',
        message: 'Request body must contain "sdp" field'
      });
    }
    
    if (!model) {
      return res.status(400).json({
        error: 'Missing model',
        message: 'Request body must contain "model" field (e.g., gpt-realtime-mini-2025-10-06)'
      });
    }
    
    if (!token) {
      return res.status(400).json({
        error: 'Missing ephemeral token',
        message: 'Request body must contain "token" field (ephemeral token from OpenAI)'
      });
    }
    
    console.log(`📡 Relaying WebRTC offer to OpenAI (model: ${model})`);
    
    // Forward the SDP offer to OpenAI's Realtime API
    const openaiUrl = `https://api.openai.com/v1/realtime?model=${encodeURIComponent(model)}`;
    
    const response = await fetch(openaiUrl, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/sdp'
      },
      body: sdp
    });
    
    if (!response.ok) {
      const errorText = await response.text();
      console.error(`❌ OpenAI API error (${response.status}):`, errorText);
      
      return res.status(response.status).json({
        error: 'OpenAI API error',
        message: errorText,
        status: response.status
      });
    }
    
    // Get the SDP answer from OpenAI
    const answerSdp = await response.text();
    
    const duration = Date.now() - startTime;
    console.log(`✅ Successfully relayed offer (${duration}ms)`);
    
    // Return the SDP answer to the client
    return res.json({
      sdp: answerSdp,
      relayed: true,
      duration
    });
    
  } catch (error: any) {
    console.error('❌ Relay error:', error);
    
    return res.status(500).json({
      error: 'Relay server error',
      message: error.message || 'Internal server error'
    });
  }
});

// Error handling middleware
app.use((err: Error, _req: Request, res: Response, _next: any) => {
  console.error('❌ Unhandled error:', err);
  res.status(500).json({
    error: 'Internal server error',
    message: process.env.NODE_ENV === 'development' ? err.message : 'Something went wrong'
  });
});

// 404 handler
app.use((req: Request, res: Response) => {
  res.status(404).json({
    error: 'Not found',
    message: `Endpoint ${req.method} ${req.path} not found`,
    availableEndpoints: [
      'GET  /health',
      'POST /offer'
    ]
  });
});

// Start server
const server = app.listen(PORT, () => {
  console.log('');
  console.log('🚀 OpenAI Realtime API Relay Server');
  console.log('=====================================');
  console.log(`📡 Server listening on port ${PORT}`);
  console.log(`🌍 Environment: ${process.env.NODE_ENV || 'development'}`);
  console.log(`🔑 OpenAI API key: ${OPENAI_API_KEY ? '✅ Configured' : '❌ Missing'}`);
  console.log(`🌐 Allowed origins: ${allowedOrigins.join(', ')}`);
  console.log('');
  console.log('Available endpoints:');
  console.log(`  GET  http://localhost:${PORT}/health`);
  console.log(`  POST http://localhost:${PORT}/offer`);
  console.log('');
});

// Graceful shutdown
const gracefulShutdown = (signal: string) => {
  console.log(`\n⚠️  Received ${signal}, shutting down gracefully...`);
  
  server.close(() => {
    console.log('✅ Server closed');
    process.exit(0);
  });
  
  // Force shutdown after 10 seconds
  setTimeout(() => {
    console.error('❌ Forced shutdown after timeout');
    process.exit(1);
  }, 10000);
};

process.on('SIGTERM', () => gracefulShutdown('SIGTERM'));
process.on('SIGINT', () => gracefulShutdown('SIGINT'));

// Handle uncaught errors
process.on('uncaughtException', (error) => {
  console.error('❌ Uncaught Exception:', error);
  process.exit(1);
});

process.on('unhandledRejection', (reason, promise) => {
  console.error('❌ Unhandled Rejection at:', promise, 'reason:', reason);
  process.exit(1);
});

