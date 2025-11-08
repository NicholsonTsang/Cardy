import { Request, Response, NextFunction } from 'express';
import { supabaseAdmin } from '../config/supabase';

// Extend Express Request to include user
declare global {
  namespace Express {
    interface Request {
      user?: {
        id: string;
        email?: string;
        role?: string;
      };
    }
  }
}

/**
 * Authentication middleware - validates JWT token and attaches user to request
 * Required for all endpoints that need user authentication
 */
export const authenticateUser = async (
  req: Request,
  res: Response,
  next: NextFunction
) => {
  try {
    // Extract token from Authorization header
    const authHeader = req.headers.authorization;
    
    if (!authHeader) {
      return res.status(401).json({
        error: 'Unauthorized',
        message: 'Missing Authorization header'
      });
    }

    const token = authHeader.replace('Bearer ', '');
    
    if (!token) {
      return res.status(401).json({
        error: 'Unauthorized',
        message: 'Invalid Authorization header format'
      });
    }

    // Validate token with Supabase
    const { data: { user }, error } = await supabaseAdmin.auth.getUser(token);
    
    if (error || !user) {
      console.warn(`❌ Authentication failed: ${error?.message || 'Invalid token'}`);
      return res.status(401).json({
        error: 'Unauthorized',
        message: 'Invalid or expired token'
      });
    }

    // Attach user to request
    req.user = {
      id: user.id,
      email: user.email,
      role: user.user_metadata?.role
    };

    // Only log authentication in development (too verbose for production)
    if (process.env.NODE_ENV === 'development' && process.env.DEBUG_AUTH) {
    console.log(`✅ Authenticated user: ${user.email} (${user.id})`);
    }
    
    return next();
  } catch (error: any) {
    console.error('❌ Authentication error:', error);
    return res.status(500).json({
      error: 'Internal server error',
      message: 'Authentication failed'
    });
  }
};

/**
 * Optional authentication - doesn't fail if no token provided
 * Useful for endpoints that work for both authenticated and public users
 */
export const optionalAuth = async (
  req: Request,
  _res: Response,
  next: NextFunction
) => {
  try {
    const authHeader = req.headers.authorization;
    
    if (!authHeader) {
      // No auth provided, continue without user
      return next();
    }

    const token = authHeader.replace('Bearer ', '');
    
    if (token) {
      const { data: { user }, error } = await supabaseAdmin.auth.getUser(token);
      
      if (!error && user) {
        req.user = {
          id: user.id,
          email: user.email,
          role: user.user_metadata?.role
        };
        // Only log in debug mode (too verbose for production)
        if (process.env.DEBUG_AUTH) {
        console.log(`✅ Optional auth: Authenticated user ${user.email}`);
        }
      }
    }
    
    return next();
  } catch (error) {
    // Don't fail, just continue without auth
    console.warn('⚠️  Optional auth failed, continuing without user:', error);
    return next();
  }
};

