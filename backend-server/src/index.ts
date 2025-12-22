import express, { Request, Response } from 'express';
import cors from 'cors';
import helmet from 'helmet';
import rateLimit from 'express-rate-limit';
import dotenv from 'dotenv';
import apiRoutes from './routes/index';
import { getRedisClient, getRateLimiter } from './config/redis';
import { requestLogger, errorLogger } from './middleware/requestLogger';

// Load environment variables
dotenv.config();

// Initialize Redis (non-blocking)
const redisClient = getRedisClient();
const rateLimiter = getRateLimiter();

const app = express();
const PORT = process.env.PORT || 8080;
const OPENAI_API_KEY = process.env.OPENAI_API_KEY;

// Validate required environment variables
if (!OPENAI_API_KEY) {
  console.error('❌ ERROR: OPENAI_API_KEY is required');
  process.exit(1);
}

// Also validate Supabase credentials for API routes
const SUPABASE_URL = process.env.SUPABASE_URL;
const SUPABASE_SERVICE_ROLE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) {
  console.warn('⚠️  WARNING: SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY not set - API routes will not work');
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

// Request logging (enable verbose with DEBUG_REQUESTS=true)
app.use(requestLogger);

// Rate limiting to prevent abuse and DDoS
// NOTE: In-memory rate limiting has limitations on Cloud Run (multi-instance)
// For critical endpoints, database-level deduplication is the source of truth
// This provides basic protection for single-instance and burst scenarios
const rateLimitWindow = parseInt(process.env.RATE_LIMIT_WINDOW_MS || '900000'); // Default: 15 minutes
const rateLimitMax = parseInt(process.env.RATE_LIMIT_MAX_REQUESTS || '100'); // Default: 100 requests

// General rate limiter for all API routes
// Works best when Cloud Run is set to min-instances=1, max-instances=1
// For multi-instance, consider using Redis or rely on database-level deduplication
const generalLimiter = rateLimit({
  windowMs: rateLimitWindow,
  max: rateLimitMax,
  message: { error: 'Too many requests from this IP, please try again later.' },
  standardHeaders: true,
  legacyHeaders: false,
  keyGenerator: (req) => {
    // Use X-Forwarded-For header (set by Cloud Run/Firebase) or fall back to IP
    return req.headers['x-forwarded-for']?.toString().split(',')[0] || req.ip || 'unknown';
  }
});

// Strict rate limiter for sensitive endpoints (WebRTC, AI chat)
const strictLimiter = rateLimit({
  windowMs: 60000, // 1 minute
  max: 20, // 20 requests per minute
  message: { error: 'Rate limit exceeded. Please slow down.' },
  standardHeaders: true,
  legacyHeaders: false,
  keyGenerator: (req) => {
    return req.headers['x-forwarded-for']?.toString().split(',')[0] || req.ip || 'unknown';
  }
});

// Apply rate limiters
app.use('/api', generalLimiter);  // All API routes
app.use('/offer', strictLimiter); // WebRTC - stricter limit

// Body parsing middleware
// Special handling for Stripe webhooks - need raw body for signature verification
// MUST be before express.json() to receive raw body
app.use('/api/webhooks/stripe', express.raw({ type: 'application/json' }));

// Regular JSON parsing for all other routes
app.use(express.json({ limit: '10mb' }));
app.use(express.text({ type: 'application/sdp' }));

// Health check endpoint
app.get('/health', (_req: Request, res: Response) => {
  res.json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    version: process.env.npm_package_version || '1.0.0',
    services: {
      openai: !!OPENAI_API_KEY,
      supabase: !!SUPABASE_URL && !!SUPABASE_SERVICE_ROLE_KEY,
      redis: !!redisClient,
      rateLimiter: rateLimiter ? 'redis' : 'memory',
    }
  });
});

// Mount API routes
app.use('/api', apiRoutes);

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

// Error logging middleware (detailed logging before sending response)
app.use(errorLogger);

// Error handling middleware
app.use((err: Error, _req: Request, res: Response, _next: any) => {
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
const server = app.listen(PORT, async () => {
  console.log('');
  console.log('🚀 FunTell Backend Server');
  console.log('=====================================');
  console.log(`📡 Server listening on port ${PORT}`);
  console.log(`🌍 Environment: ${process.env.NODE_ENV || 'development'}`);
  console.log(`🔑 OpenAI API key: ${OPENAI_API_KEY ? '✅ Configured' : '❌ Missing'}`);
  console.log(`🗄️  Supabase: ${SUPABASE_URL && SUPABASE_SERVICE_ROLE_KEY ? '✅ Configured' : '❌ Missing'}`);
  console.log(`📦 Redis: ${redisClient ? '✅ Connected (Upstash)' : '⚠️  Not configured (using fallback)'}`);
  console.log(`🚦 Rate Limiter: ${rateLimiter ? '✅ Redis-backed' : '⚠️  In-memory fallback'}`);
  console.log(`🌐 Allowed origins: ${allowedOrigins.join(', ')}`);
  console.log('');
  console.log('Available endpoints:');
  console.log('  Relay:');
  console.log(`    GET  http://localhost:${PORT}/health`);
  console.log(`    POST http://localhost:${PORT}/offer`);
  console.log('  API:');
  console.log(`    GET  http://localhost:${PORT}/api`);
  console.log(`    POST http://localhost:${PORT}/api/translations/translate-card`);
  console.log(`    POST http://localhost:${PORT}/api/payments/create-credit-checkout`);
  console.log(`    POST http://localhost:${PORT}/api/ai/chat/stream`);
  console.log(`    POST http://localhost:${PORT}/api/ai/generate-tts`);
  console.log(`    POST http://localhost:${PORT}/api/ai/realtime-token`);
  console.log(`    POST http://localhost:${PORT}/api/webhooks/stripe`);
  console.log('  Mobile:');
  console.log(`    GET  http://localhost:${PORT}/api/mobile/card/digital/:accessToken`);
  console.log(`    GET  http://localhost:${PORT}/api/mobile/card/physical/:issueCardId`);
  console.log('');
});

// Graceful shutdown
const gracefulShutdown = async (signal: string) => {
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

