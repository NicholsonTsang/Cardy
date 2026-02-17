import { Router, Request, Response } from 'express';
import { supabaseAdmin } from '../config/supabase';
import { resetUsage, updateUserTier } from '../services/usage-tracker';
import { getStripe } from '../config/stripe';

const router = Router();

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

    const signature = req.headers['stripe-signature'];
    if (!signature) {
      return res.status(400).json({ error: 'No stripe-signature header' });
    }

    const rawBody = req.body;
    if (!Buffer.isBuffer(rawBody)) {
      return res.status(400).json({ error: 'Webhook must receive raw body for signature verification' });
    }

    const stripe = getStripe();
    let event: any;
    try {
      event = stripe.webhooks.constructEvent(rawBody, signature, webhookSecret);
    } catch (err: any) {
      console.error('❌ Webhook signature verification failed:', err.message);
      return res.status(400).json({ error: 'Invalid signature', message: err.message });
    }

    console.log(`📨 Webhook received: ${event.type}`);

    // Once signature is verified, always return 200 to prevent Stripe retries
    // on processing errors (which would fail the same way on retry)
    try {
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
          // Activate/update subscription (Starter or Premium)
          // Respect cancel_at_period_end from Stripe object
          const cancelAtPeriodEnd = subscription.cancel_at_period_end || false;
          const priceId = subscription.items?.data?.[0]?.price?.id || null;
          
          // Determine tier based on price ID
          const starterPriceId = process.env.STRIPE_STARTER_PRICE_ID;
          const premiumPriceId = process.env.STRIPE_PREMIUM_PRICE_ID;
          const enterprisePriceId = process.env.STRIPE_ENTERPRISE_PRICE_ID;
          let tier: 'starter' | 'premium' | 'enterprise' = 'premium'; // Default to premium

          if (priceId === starterPriceId) {
            tier = 'starter';
          } else if (priceId === premiumPriceId) {
            tier = 'premium';
          } else if (priceId === enterprisePriceId) {
            tier = 'enterprise';
          } else {
            console.warn(`⚠️ Unknown price ID: ${priceId}. Defaulting to premium tier.`);
          }
          
          const { error } = await supabaseAdmin.rpc('activate_premium_subscription_server', {
            p_user_id: userId,
            p_stripe_customer_id: subscription.customer,
            p_stripe_subscription_id: subscription.id,
            p_stripe_price_id: priceId,
            p_period_start: periodStart,
            p_period_end: periodEnd,
            p_cancel_at_period_end: cancelAtPeriodEnd,
            p_tier: tier
          });

          if (error) {
            console.error('❌ Error activating subscription:', error);
          } else {
            console.log(`✅ ${tier.charAt(0).toUpperCase() + tier.slice(1)} subscription updated for user ${userId} (cancel_at_period_end: ${cancelAtPeriodEnd})`);
            
            // Update Redis cache with the correct tier
            await updateUserTier(userId, tier);
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
        const userId = subscription.metadata?.user_id;
        
        // First, check if there's a scheduled tier change (for downgrades)
        // If scheduled_tier is set (e.g., 'starter'), the user has already subscribed to a new lower tier
        // that will take over. Otherwise, they're canceling to free tier.
        const { data: applyResult } = await supabaseAdmin.rpc('apply_scheduled_tier_change_server', {
          p_stripe_subscription_id: subscription.id,
          p_user_id: userId
        });
        
        if (applyResult?.success) {
          // Scheduled tier change was applied (downgrade scenario)
          const newTier = applyResult.new_tier || 'free';
          console.log(`🔄 Applied scheduled tier change: ${applyResult.previous_tier} → ${newTier} for user ${applyResult.user_id}`);
          
          // Update Redis cache with new tier
          if (applyResult.user_id) {
            await updateUserTier(applyResult.user_id, newTier);
            console.log(`🔄 Redis tier updated to ${newTier} for user ${applyResult.user_id}`);
          }
        } else {
          // No scheduled tier - cancel to free tier
          const { data: cancelResult, error: cancelError } = await supabaseAdmin.rpc('cancel_subscription_server', {
            p_stripe_subscription_id: subscription.id,
            p_cancel_at_period_end: false,
            p_immediate: true,
            p_user_id: userId,
            p_scheduled_tier: 'free'
          });

          if (cancelError) {
            console.error('❌ Error canceling subscription:', cancelError);
          } else {
            console.log(`🚫 Subscription ${subscription.id} canceled and downgraded to free`);
            
            // Update Redis cache to free tier
            const effectiveUserId = cancelResult?.user_id || userId;
            if (effectiveUserId) {
              await updateUserTier(effectiveUserId, 'free');
              console.log(`🔄 Redis tier updated to free for user ${effectiveUserId}`);
            } else {
              console.warn('⚠️ Could not determine user_id for Redis tier update');
            }
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
    } catch (processingError: any) {
      // Log but don't return error - signature was valid, so returning 500
      // would cause Stripe to retry an event we already received
      console.error(`❌ Webhook processing error for ${event.type}:`, processingError);
    }

    return res.status(200).json({ received: true });

  } catch (error: any) {
    console.error('❌ Webhook error:', error);
    return res.status(500).json({ error: 'Webhook processing error', message: error.message });
  }
});

// Legacy /stripe-credit endpoint removed - use /stripe instead

export default router;

