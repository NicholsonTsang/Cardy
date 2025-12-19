import { Request, Response, NextFunction } from 'express';

/**
 * Request logging middleware
 * Logs all requests with method, path, status, and duration
 * Enable verbose logging with DEBUG_REQUESTS=true
 */
export const requestLogger = (req: Request, res: Response, next: NextFunction) => {
  const startTime = Date.now();
  const requestId = Math.random().toString(36).substring(7);
  
  // Skip health checks unless in verbose mode
  const isHealthCheck = req.path === '/health';
  const isVerbose = process.env.DEBUG_REQUESTS === 'true';
  
  if (!isHealthCheck || isVerbose) {
    const clientIp = req.headers['x-forwarded-for']?.toString().split(',')[0] || req.ip || 'unknown';
    console.log(`📥 [${requestId}] ${req.method} ${req.path} from ${clientIp}`);
  }
  
  // Capture response
  res.on('finish', () => {
    const duration = Date.now() - startTime;
    const statusIcon = res.statusCode >= 400 ? '❌' : '✅';
    
    if (!isHealthCheck || isVerbose) {
      console.log(`${statusIcon} [${requestId}] ${req.method} ${req.path} → ${res.statusCode} (${duration}ms)`);
    }
  });
  
  next();
};

/**
 * Error logger for failed requests
 * Logs detailed error info for debugging
 */
export const errorLogger = (err: Error, req: Request, _res: Response, next: NextFunction) => {
  const clientIp = req.headers['x-forwarded-for']?.toString().split(',')[0] || req.ip || 'unknown';
  
  console.error('═══════════════════════════════════════');
  console.error(`❌ ERROR: ${req.method} ${req.path}`);
  console.error(`   Client: ${clientIp}`);
  console.error(`   User: ${req.user?.id || 'anonymous'}`);
  console.error(`   Error: ${err.message}`);
  if (process.env.NODE_ENV === 'development') {
    console.error(`   Stack: ${err.stack}`);
  }
  console.error('═══════════════════════════════════════');
  
  next(err);
};

