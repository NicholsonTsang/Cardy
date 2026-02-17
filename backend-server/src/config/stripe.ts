/**
 * Shared Stripe singleton instance
 * Avoids creating a new Stripe instance on every request
 */
import Stripe from 'stripe';

let stripeInstance: Stripe | null = null;

export function getStripe(): Stripe {
  if (!stripeInstance) {
    const stripeKey = process.env.STRIPE_SECRET_KEY;
    if (!stripeKey) {
      throw new Error('Stripe secret key not configured');
    }

    const stripeApiVersion = process.env.STRIPE_API_VERSION || '2025-08-27.basil';
    stripeInstance = new Stripe(stripeKey, {
      apiVersion: stripeApiVersion as any,
    });
  }
  return stripeInstance;
}

/**
 * Validate a URL against allowed origins to prevent open redirect attacks
 */
export function validateRedirectUrl(url: string): boolean {
  const allowedOrigins = (
    process.env.ALLOWED_ORIGINS || process.env.FRONTEND_URL || 'http://localhost:5173'
  ).split(',').map(s => s.trim());

  // Wildcard allows all origins (development mode)
  if (allowedOrigins.includes('*')) {
    try {
      new URL(url); // Just validate it's a well-formed URL
      return true;
    } catch {
      return false;
    }
  }

  try {
    const parsedUrl = new URL(url);
    return allowedOrigins.some(origin => {
      try {
        return parsedUrl.origin === new URL(origin).origin;
      } catch {
        return false;
      }
    });
  } catch {
    return false;
  }
}
