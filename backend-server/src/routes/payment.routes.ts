import { Router, Request, Response } from 'express';
import { authenticateUser } from '../middleware/auth';
import { supabaseAdmin } from '../config/supabase';

const router = Router();

/**
 * POST /api/payments/create-credit-checkout
 * Create Stripe checkout session for credit purchase
 * Requires authentication
 */
router.post('/create-credit-checkout', authenticateUser, async (req: Request, res: Response) => {
  try {
    const userId = req.user!.id;
    const { creditAmount, amountUsd, baseUrl, metadata = {} } = req.body;

    console.log(`💳 Creating credit checkout for user ${userId}: ${creditAmount} credits`);

    // Validate inputs
    if (!creditAmount || creditAmount <= 0) {
      return res.status(400).json({
        error: 'Validation error',
        message: 'Invalid credit amount'
      });
    }

    if (!amountUsd || amountUsd <= 0) {
      return res.status(400).json({
        error: 'Validation error',
        message: 'Invalid amount USD'
      });
    }

    if (!baseUrl) {
      return res.status(400).json({
        error: 'Validation error',
        message: 'Base URL is required'
      });
    }

    // Validate baseUrl against allowed origins to prevent open redirect
    const allowedOrigins = (process.env.ALLOWED_ORIGINS || process.env.FRONTEND_URL || 'http://localhost:5173').split(',').map(s => s.trim());
    try {
      const parsedUrl = new URL(baseUrl);
      if (!allowedOrigins.some(origin => parsedUrl.origin === new URL(origin).origin)) {
        return res.status(400).json({
          error: 'Validation error',
          message: 'Invalid base URL'
        });
      }
    } catch {
      return res.status(400).json({
        error: 'Validation error',
        message: 'Invalid base URL format'
      });
    }

    // Get Stripe key
    const stripeKey = process.env.STRIPE_SECRET_KEY;
    if (!stripeKey) {
      return res.status(500).json({
        error: 'Configuration error',
        message: 'Stripe secret key not configured'
      });
    }

    // Import Stripe dynamically
    const Stripe = (await import('stripe')).default;
    const stripeApiVersion = process.env.STRIPE_API_VERSION || '2025-08-27.basil';
    const stripe = new Stripe(stripeKey, {
      apiVersion: stripeApiVersion as any,
    });

    // Convert to cents for Stripe
    const amountCents = Math.round(amountUsd * 100);

    // Create Stripe Checkout session
    const session = await stripe.checkout.sessions.create({
      payment_method_types: ['card'],
      line_items: [
        {
          price_data: {
            currency: 'usd',
            product_data: {
              name: 'FunTell Credits',
              description: `Purchase ${creditAmount} FunTell credits`,
              metadata: {
                type: 'credit_purchase'
              }
            },
            unit_amount: amountCents
          },
          quantity: 1
        }
      ],
      mode: 'payment',
      success_url: `${baseUrl}?success=true&session_id={CHECKOUT_SESSION_ID}&type=credit`,
      cancel_url: `${baseUrl}?canceled=true&type=credit`,
      metadata: {
        ...metadata,
        type: 'credit_purchase',
        credit_amount: creditAmount.toString(),
        amount_usd: amountUsd.toString(),
        user_id: userId
      }
    });

    // Create pending credit purchase record
    const { data: purchaseRecord, error: dbError } = await supabaseAdmin.rpc(
      'create_credit_purchase_record',
      {
        p_stripe_session_id: session.id,
        p_amount_usd: amountUsd,
        p_credits_amount: creditAmount,
        p_metadata: metadata,
        p_user_id: userId
      }
    );

    if (dbError) {
      console.error('❌ Error creating credit purchase record:', dbError);
      return res.status(500).json({
        error: 'Database error',
        message: `Failed to create purchase record: ${dbError.message}`
      });
    }

    console.log(`✅ Created pending credit purchase: ${creditAmount} credits for user ${userId}, session ${session.id}`);

    return res.status(200).json({
      sessionId: session.id,
      url: session.url,
      purchaseId: purchaseRecord
    });

  } catch (error: any) {
    console.error('❌ Error creating credit checkout session:', error);
    return res.status(500).json({
      error: 'Payment error',
      message: error.message || 'Failed to create checkout session'
    });
  }
});

export default router;

