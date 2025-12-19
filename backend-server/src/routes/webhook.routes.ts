import { Router, Request, Response } from 'express';
import { supabaseAdmin } from '../config/supabase';
import { resetUsage, updateUserTier } from '../services/usage-tracker';

const router = Router();

/**
 * Helper: Get Stripe instance
 */
async function getStripe() {
  const stripeKey = process.env.STRIPE_SECRET_KEY;
  if (!stripeKey) throw new Error('Stripe secret key not configured');
  
  const Stripe = (await import('stripe')).default;
  return new Stripe(stripeKey, {
    apiVersion: (process.env.STRIPE_API_VERSION || '2025-08-27.basil') as any,
  });
}

/**
 * Helper: Verify webhook signature
 */
async function verifyWebhook(req: Request, webhookSecret: string) {
  const signature = req.headers['stripe-signature'];
  if (!signature) throw new Error('No stripe-signature header');
  
  const rawBody = req.body;
  if (!Buffer.isBuffer(rawBody)) {
    throw new Error('Webhook must receive raw body for signature verification');
  }
  
  const stripe = await getStripe();
  return stripe.webhooks.constructEvent(rawBody, signature, webhookSecret);
}

/**
 * POST /api/webhooks/stripe
 * Unified Stripe webhook handler for all events
 */
router.post('/stripe', async (req: Request, res: Response) => {
  try {
    const webhookSecret = process.env.STRIPE_WEBHOOK_SECRET;
    if (!webhookSecret) {
      console.error('❌ Stripe webhook secret not configured');
      return res.status(500).json({ error: 'Webhook secret not configured' });
    }

    let event: any;
    try {
      event = await verifyWebhook(req, webhookSecret);
    } catch (err: any) {
      console.error('❌ Webhook signature verification failed:', err.message);
      return res.status(400).json({ error: 'Invalid signature', message: err.message });
    }

    console.log(`📨 Webhook received: ${event.type}`);
    const stripe = await getStripe();

    switch (event.type) {
      // =================================================================
      // SUBSCRIPTION EVENTS
      // =================================================================
      case 'customer.subscription.created':
      case 'customer.subscription.updated': {
        const subscription = event.data.object;
        const userId = subscription.metadata?.user_id;
        
        if (!userId) {
          console.warn(`⚠️ No user_id in subscription metadata for ${subscription.id}. ` +
            `Ensure checkout session includes metadata.user_id. Event: ${event.type}`);
          break;
        }

        const status = subscription.status;
        
        // Safely parse dates - use current time as fallback if missing
        const now = new Date();
        const periodStart = subscription.current_period_start 
          ? new Date(subscription.current_period_start * 1000).toISOString()
          : now.toISOString();
        const periodEnd = subscription.current_period_end 
          ? new Date(subscription.current_period_end * 1000).toISOString()
          : new Date(now.getTime() + 30 * 24 * 60 * 60 * 1000).toISOString(); // +30 days fallback

        console.log(`📅 Subscription period: ${periodStart} to ${periodEnd}`);

        if (status === 'active' || status === 'trialing') {
          // Activate/update premium subscription
          // Respect cancel_at_period_end from Stripe object
          const cancelAtPeriodEnd = subscription.cancel_at_period_end || false;
          
          const { error } = await supabaseAdmin.rpc('activate_premium_subscription_server', {
            p_user_id: userId,
            p_stripe_customer_id: subscription.customer,
            p_stripe_subscription_id: subscription.id,
            p_stripe_price_id: subscription.items?.data?.[0]?.price?.id || null,
            p_period_start: periodStart,
            p_period_end: periodEnd,
            p_cancel_at_period_end: cancelAtPeriodEnd
          });

          if (error) {
            console.error('❌ Error activating subscription:', error);
          } else {
            console.log(`✅ Premium subscription updated for user ${userId} (cancel_at_period_end: ${cancelAtPeriodEnd})`);
            
            // Update Redis cache with premium tier
            await updateUserTier(userId, 'premium');
          }
        } else if (subscription.cancel_at_period_end) {
          // Fallback if status is NOT active but scheduled for cancellation (rare)
          await supabaseAdmin.rpc('update_subscription_cancel_status_server', {
            p_user_id: userId,
            p_cancel_at_period_end: true,
            p_canceled_at: new Date().toISOString()
          });
          
          console.log(`⏳ Subscription ${subscription.id} scheduled for cancellation (fallback handler)`);
        }
        break;
      }

      case 'customer.subscription.deleted': {
        const subscription = event.data.object as any;
        
        // Downgrade to free tier
        const { data: cancelResult, error } = await supabaseAdmin.rpc('cancel_subscription_server', {
          p_stripe_subscription_id: subscription.id,
          p_cancel_at_period_end: false,
          p_immediate: true
        });

        if (error) {
          console.error('❌ Error canceling subscription:', error);
        } else {
          console.log(`🚫 Subscription ${subscription.id} canceled and downgraded to free`);
          
          // Update Redis cache to free tier
          // Use user_id from stored procedure result (more reliable than metadata)
          const userId = cancelResult?.user_id || subscription.metadata?.user_id;
          if (userId) {
            await updateUserTier(userId, 'free');
            console.log(`🔄 Redis tier updated to free for user ${userId}`);
          } else {
            console.warn('⚠️ Could not determine user_id for Redis tier update');
          }
        }
        break;
      }

      case 'invoice.payment_succeeded': {
        const invoice = event.data.object;
        
        // Only process subscription invoices for billing cycle renewals
        if (invoice.subscription && invoice.billing_reason === 'subscription_cycle') {
          // Reset monthly usage for new billing period
          const subscription = await stripe.subscriptions.retrieve(invoice.subscription as string) as any;
          const periodStart = new Date(subscription.current_period_start * 1000).toISOString();
          const periodEnd = new Date(subscription.current_period_end * 1000).toISOString();

          const { data: resetResult, error } = await supabaseAdmin.rpc('reset_subscription_usage_server', {
            p_stripe_subscription_id: invoice.subscription,
            p_new_period_start: periodStart,
            p_new_period_end: periodEnd
          });

          if (error) {
            console.error('❌ Error resetting subscription usage:', error);
          } else {
            console.log(`🔄 Monthly usage reset for subscription ${invoice.subscription}`);
            
            // Reset Redis usage counter (source of truth)
            // Use user_id from stored procedure result (more reliable than metadata)
            const userId = resetResult?.user_id || subscription.metadata?.user_id;
            if (userId) {
              await resetUsage(userId);
              console.log(`🔄 Redis usage reset for user ${userId}`);
            } else {
              console.warn('⚠️ Could not determine user_id for Redis usage reset');
            }
          }
        }
        break;
      }

      case 'invoice.payment_failed': {
        const invoice = event.data.object;
        
        if (invoice.subscription) {
          // Update subscription status to past_due via stored procedure
          await supabaseAdmin.rpc('update_subscription_status_server', {
            p_stripe_subscription_id: invoice.subscription as string,
            p_status: 'past_due'
          });
          
          console.log(`⚠️ Payment failed for subscription ${invoice.subscription}`);
        }
        break;
      }

      // =================================================================
      // CHECKOUT SESSION EVENTS (Credits & Subscriptions)
      // =================================================================
      case 'checkout.session.completed': {
        const session = event.data.object;
        const type = session.metadata?.type;

        if (type === 'credit_purchase') {
          // Handle credit purchase
          const userId = session.metadata?.user_id;
          if (!userId) {
            console.error('❌ User ID not found in session metadata');
            break;
          }

          const fullSession = await stripe.checkout.sessions.retrieve(session.id, {
            expand: ['payment_intent']
          });

          const creditAmount = parseFloat(fullSession.metadata?.credit_amount || '0');

          if (creditAmount > 0) {
            const paymentIntent = fullSession.payment_intent as any;
            const receiptUrl = paymentIntent?.charges?.data?.[0]?.receipt_url || null;

            const { error } = await supabaseAdmin.rpc('complete_credit_purchase', {
              p_user_id: userId,
              p_stripe_session_id: session.id,
              p_stripe_payment_intent_id: paymentIntent?.id || null,
              p_amount_paid_cents: session.amount_total,
              p_receipt_url: receiptUrl,
              p_payment_method: { type: paymentIntent?.payment_method_types?.[0] || 'card' }
            });

            if (error) {
              console.error('❌ Error completing credit purchase:', error);
            } else {
              console.log(`✅ Credit purchase completed: ${creditAmount} credits for user ${userId}`);
            }
          }
        } else if (type === 'premium_subscription') {
          // Subscription is handled by customer.subscription.created event
          console.log('Subscription checkout completed, waiting for subscription.created event');
        }
        break;
      }

      // =================================================================
      // REFUND EVENTS
      // =================================================================
      case 'charge.refunded': {
        const charge = event.data.object;

        if (charge.payment_intent) {
          // Get purchase via stored procedure
          const { data: purchaseRows } = await supabaseAdmin.rpc(
            'get_credit_purchase_by_intent_server',
            { p_payment_intent_id: charge.payment_intent as string }
          );

          const purchase = purchaseRows?.[0];

          if (purchase) {
            const refundCredits = charge.amount_refunded / 100;

            const { error } = await supabaseAdmin.rpc('refund_credit_purchase', {
              p_user_id: purchase.user_id,
              p_purchase_id: purchase.id,
              p_refund_amount: refundCredits,
              p_reason: 'Stripe refund processed'
            });

            if (error) {
              console.error('❌ Error processing refund:', error);
            } else {
              console.log(`✅ Credit refund: ${refundCredits} credits for user ${purchase.user_id}`);
            }
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
    return res.status(500).json({ error: 'Webhook processing error', message: error.message });
  }
});

// Legacy /stripe-credit endpoint removed - use /stripe instead

export default router;

