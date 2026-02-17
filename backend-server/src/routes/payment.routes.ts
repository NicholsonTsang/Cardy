import { Router, Request, Response } from 'express';
import { authenticateUser } from '../middleware/auth';
import { supabaseAdmin } from '../config/supabase';
import { getStripe, validateRedirectUrl } from '../config/stripe';
import { VOICE_CREDIT_CONFIG } from '../config/subscription';
import { invalidateVoiceCreditCache } from '../services/usage-tracker';

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

    if (!validateRedirectUrl(baseUrl)) {
      return res.status(400).json({
        error: 'Validation error',
        message: 'Invalid base URL'
      });
    }

    const stripe = getStripe();

    // Get or create Stripe customer for this user
    let customerId: string | null = await supabaseAdmin.rpc(
      'get_subscription_stripe_customer_server',
      { p_user_id: userId }
    ).then(res => res.data ?? null);

    if (!customerId) {
      const customer = await stripe.customers.create({
        email: req.user!.email,
        metadata: { user_id: userId }
      });
      customerId = customer.id;
    }

    // Convert to cents for Stripe
    const amountCents = Math.round(amountUsd * 100);

    // Create Stripe Checkout session
    const session = await stripe.checkout.sessions.create({
      customer: customerId,
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

/**
 * POST /api/payments/purchase-voice-credits
 * Purchase voice credits using credit balance (instant deduction)
 * Requires authentication
 */
router.post('/purchase-voice-credits', authenticateUser, async (req: Request, res: Response) => {
  try {
    const userId = req.user!.id;
    const { quantity = 1 } = req.body;

    // Validate quantity
    const qty = Math.max(1, Math.min(10, Math.floor(Number(quantity) || 1)));

    const packageSize = VOICE_CREDIT_CONFIG.PACKAGE_SIZE * qty;
    const creditCost = VOICE_CREDIT_CONFIG.PACKAGE_PRICE_USD * qty;

    console.log(`[VoiceCredits] Purchasing ${packageSize} voice credits (${qty}x package) for user ${userId} (cost: $${creditCost})`);

    const { data, error } = await supabaseAdmin.rpc('purchase_voice_credits_with_credits_server', {
      p_user_id: userId,
      p_package_size: packageSize,
      p_credit_cost: creditCost,
    });

    if (error) {
      console.error('[VoiceCredits] Stored procedure error:', error);
      return res.status(500).json({
        error: 'Purchase failed',
        message: error.message || 'Failed to purchase voice credits',
      });
    }

    // Check if the stored procedure returned a business logic failure (e.g., insufficient credits)
    if (data && !data.success) {
      console.warn(`[VoiceCredits] Purchase denied for user ${userId}:`, data.error);
      return res.status(400).json({
        error: 'Purchase failed',
        message: data.error || 'Insufficient credits',
        current_balance: data.current_balance,
        required: data.required,
      });
    }

    // Invalidate Redis voice credit cache so next read fetches fresh data
    await invalidateVoiceCreditCache(userId);

    console.log(`[VoiceCredits] Purchase complete for user ${userId}:`, data);

    return res.status(200).json(data);
  } catch (error: any) {
    console.error('[VoiceCredits] Error purchasing voice credits:', error);
    return res.status(500).json({
      error: 'Purchase failed',
      message: error.message || 'Failed to purchase voice credits',
    });
  }
});

export default router;

