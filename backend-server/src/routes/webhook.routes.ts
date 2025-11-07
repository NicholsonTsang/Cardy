import { Router, Request, Response } from 'express';
import { supabaseAdmin } from '../config/supabase';

const router = Router();

/**
 * POST /api/webhooks/stripe-credit
 * Handle Stripe webhooks for credit purchases
 * Uses Stripe signature verification (no JWT auth)
 */
router.post('/stripe-credit', async (req: Request, res: Response) => {
  try {
    // Get Stripe configuration
    const stripeKey = process.env.STRIPE_SECRET_KEY;
    const webhookSecret = process.env.STRIPE_WEBHOOK_SECRET;

    if (!stripeKey || !webhookSecret) {
      console.error('❌ Stripe configuration missing');
      return res.status(500).json({
        error: 'Configuration error',
        message: 'Stripe configuration missing'
      });
    }

    // Import Stripe
    const Stripe = (await import('stripe')).default;
    const stripeApiVersion = process.env.STRIPE_API_VERSION || '2025-08-27.basil';
    const stripe = new Stripe(stripeKey, {
      apiVersion: stripeApiVersion as any,
    });

    // Get signature from headers
    const signature = req.headers['stripe-signature'];
    if (!signature) {
      return res.status(400).json({
        error: 'Missing signature',
        message: 'No stripe-signature header'
      });
    }

    // Get raw body buffer (express.raw() middleware provides this)
    // CRITICAL: Must use raw body, not parsed JSON, for signature verification
    const rawBody = req.body;
    
    if (!Buffer.isBuffer(rawBody)) {
      console.error('❌ Raw body is not a buffer. Check middleware configuration.');
      return res.status(400).json({
        error: 'Invalid request',
        message: 'Webhook must receive raw body for signature verification'
      });
    }

    // Verify webhook signature
    let event: any;
    try {
      event = stripe.webhooks.constructEvent(rawBody, signature, webhookSecret);
    } catch (err: any) {
      console.error('❌ Webhook signature verification failed:', err.message);
      return res.status(400).json({
        error: 'Invalid signature',
        message: err.message
      });
    }

    console.log(`📨 Webhook received: ${event.type}`);

    // Handle different event types
    switch (event.type) {
      case 'checkout.session.completed': {
        const session = event.data.object;

        // Check if this is a credit purchase
        if (session.metadata?.type !== 'credit_purchase') {
          console.log('Not a credit purchase, skipping');
          return res.status(200).json({ received: true });
        }

        const userId = session.metadata?.user_id;
        if (!userId) {
          console.error('❌ User ID not found in session metadata');
          return res.status(400).json({
            error: 'Missing user ID',
            message: 'User ID not found in session metadata'
          });
        }

        // Get full session with payment intent
        const fullSession = await stripe.checkout.sessions.retrieve(session.id, {
          expand: ['payment_intent']
        });

        const creditAmount = parseFloat(fullSession.metadata?.credit_amount || '0');

        if (creditAmount > 0) {
          const paymentIntent = fullSession.payment_intent as any;
          const receiptUrl = paymentIntent?.charges?.data?.[0]?.receipt_url || null;
          const amountPaidCents = session.amount_total;

          // Complete the credit purchase
          const { error } = await supabaseAdmin.rpc('complete_credit_purchase', {
            p_user_id: userId,
            p_stripe_session_id: session.id,
            p_stripe_payment_intent_id: paymentIntent?.id || null,
            p_amount_paid_cents: amountPaidCents,
            p_receipt_url: receiptUrl,
            p_payment_method: {
              type: paymentIntent?.payment_method_types?.[0] || 'card'
            }
          });

          if (error) {
            console.error('❌ Error completing credit purchase:', error);
            return res.status(500).json({
              error: 'Database error',
              message: error.message
            });
          }

          console.log(`✅ Credit purchase completed: ${creditAmount} credits for user ${userId}`);
        }
        break;
      }

      case 'charge.refunded': {
        const charge = event.data.object;

        if (charge.payment_intent) {
          // Find purchase by payment intent
          const { data: purchase, error: findError } = await supabaseAdmin
            .from('credit_purchases')
            .select('id, user_id, credits_amount')
            .eq('stripe_payment_intent_id', charge.payment_intent)
            .single();

          if (findError) {
            console.error('❌ Error finding purchase for refund:', findError);
          } else if (purchase) {
            // Calculate refund amount in credits
            const refundAmountCents = charge.amount_refunded;
            const refundCredits = refundAmountCents / 100;

            // Process refund
            const { error: refundError } = await supabaseAdmin.rpc('refund_credit_purchase', {
              p_user_id: purchase.user_id,
              p_purchase_id: purchase.id,
              p_refund_amount: refundCredits,
              p_reason: 'Stripe refund processed'
            });

            if (refundError) {
              console.error('❌ Error processing credit refund:', refundError);
              return res.status(500).json({
                error: 'Refund error',
                message: refundError.message
              });
            }

            console.log(`✅ Credit refund processed: ${refundCredits} credits for user ${purchase.user_id}`);
          }
        }
        break;
      }

      default:
        console.log(`Unhandled event type: ${event.type}`);
    }

    return res.status(200).json({ received: true });

  } catch (error: any) {
    console.error('❌ Webhook error:', error);
    return res.status(500).json({
      error: 'Webhook processing error',
      message: error.message
    });
  }
});

export default router;

