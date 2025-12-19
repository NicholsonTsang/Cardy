import { Router, Request, Response } from 'express';
import { authenticateUser } from '../middleware/auth';
import { supabaseAdmin } from '../config/supabase';
import { SubscriptionConfig, getPricingInfo, getTierDetails } from '../config/subscription';
import { getUsageStats, flushAccessLogBuffer, invalidateUserCache } from '../services/usage-tracker';

const router = Router();

/**
 * GET /api/subscriptions/pricing
 * Get subscription pricing info (public endpoint)
 */
router.get('/pricing', (_req: Request, res: Response) => {
  return res.json(getPricingInfo());
});

/**
 * GET /api/subscriptions
 * Get current user's subscription details
 */
router.get('/', authenticateUser, async (req: Request, res: Response) => {
  try {
    const userId = req.user!.id;

    // Pass business parameters from config to stored procedure
    const { data, error } = await supabaseAdmin.rpc('get_subscription_details', {
      p_user_id: userId,
      p_free_experience_limit: SubscriptionConfig.free.experienceLimit,
      p_premium_experience_limit: SubscriptionConfig.premium.experienceLimit,
      p_free_monthly_access: SubscriptionConfig.free.monthlyAccessLimit,
      p_premium_monthly_access: SubscriptionConfig.premium.monthlyAccessLimit,
      p_premium_monthly_fee: SubscriptionConfig.premium.monthlyFeeUsd,
      p_overage_credits_per_batch: SubscriptionConfig.overage.creditsPerBatch,
      p_overage_access_per_batch: SubscriptionConfig.overage.accessPerBatch
    });

    if (error) {
      console.error('❌ Error fetching subscription:', error);
      return res.status(500).json({
        error: 'Database error',
        message: error.message
      });
    }

    return res.json(data);
  } catch (error: any) {
    console.error('❌ Subscription fetch error:', error);
    return res.status(500).json({
      error: 'Internal server error',
      message: error.message
    });
  }
});

/**
 * POST /api/subscriptions/create-checkout
 * Create Stripe checkout session for Premium subscription
 */
router.post('/create-checkout', authenticateUser, async (req: Request, res: Response) => {
  try {
    const userId = req.user!.id;
    const userEmail = req.user!.email;
    const { baseUrl } = req.body;

    if (!baseUrl) {
      return res.status(400).json({
        error: 'Validation error',
        message: 'Base URL is required'
      });
    }

    // Get Stripe configuration
    const stripeKey = process.env.STRIPE_SECRET_KEY;
    const stripePriceId = process.env.STRIPE_PREMIUM_PRICE_ID;

    if (!stripeKey) {
      return res.status(500).json({
        error: 'Configuration error',
        message: 'Stripe secret key not configured'
      });
    }

    if (!stripePriceId) {
      return res.status(500).json({
        error: 'Configuration error',
        message: 'Premium subscription price ID not configured. Set STRIPE_PREMIUM_PRICE_ID in .env'
      });
    }

    // Check if user already has premium
    const { data: currentSub } = await supabaseAdmin.rpc('get_subscription_details', {
      p_user_id: userId
    });

    if (currentSub?.is_premium && currentSub?.status === 'active') {
      return res.status(400).json({
        error: 'Already subscribed',
        message: 'You already have an active Premium subscription'
      });
    }

    // Import Stripe
    const Stripe = (await import('stripe')).default;
    const stripeApiVersion = process.env.STRIPE_API_VERSION || '2025-08-27.basil';
    const stripe = new Stripe(stripeKey, {
      apiVersion: stripeApiVersion as any,
    });

    // Check if user has existing Stripe customer ID
    let customerId = await supabaseAdmin.rpc(
      'get_subscription_stripe_customer_server',
      { p_user_id: userId }
    ).then(res => res.data);

    // Create customer if doesn't exist
    if (!customerId) {
      const customer = await stripe.customers.create({
        email: userEmail,
        metadata: {
          user_id: userId
        }
      });
      customerId = customer.id;
    }

    // Create Stripe Checkout session for subscription
    const session = await stripe.checkout.sessions.create({
      customer: customerId,
      payment_method_types: ['card'],
      line_items: [
        {
          price: stripePriceId,
          quantity: 1
        }
      ],
      mode: 'subscription',
      success_url: `${baseUrl}?success=true&session_id={CHECKOUT_SESSION_ID}&type=subscription`,
      cancel_url: `${baseUrl}?canceled=true&type=subscription`,
      metadata: {
        user_id: userId,
        type: 'premium_subscription'
      },
      subscription_data: {
        metadata: {
          user_id: userId
        }
      }
    });

    console.log(`📦 Created subscription checkout for user ${userId}, session ${session.id}`);

    return res.json({
      sessionId: session.id,
      url: session.url
    });

  } catch (error: any) {
    console.error('❌ Error creating subscription checkout:', error);
    return res.status(500).json({
      error: 'Payment error',
      message: error.message || 'Failed to create checkout session'
    });
  }
});

/**
 * POST /api/subscriptions/cancel
 * Cancel Premium subscription
 */
router.post('/cancel', authenticateUser, async (req: Request, res: Response) => {
  try {
    const userId = req.user!.id;
    const { immediate = false } = req.body;

    // Get current subscription
    const { data: subscriptionRows, error: subError } = await supabaseAdmin.rpc(
      'get_subscription_by_user_server',
      { p_user_id: userId }
    );

    const subscription = subscriptionRows?.[0];

    if (subError || !subscription) {
      return res.status(404).json({
        error: 'Not found',
        message: 'No subscription found'
      });
    }

    if (subscription.tier !== 'premium') {
      return res.status(400).json({
        error: 'Invalid request',
        message: 'Only premium subscriptions can be canceled'
      });
    }

    if (!subscription.stripe_subscription_id) {
      return res.status(400).json({
        error: 'Invalid state',
        message: 'No Stripe subscription linked'
      });
    }

    // Get Stripe
    const stripeKey = process.env.STRIPE_SECRET_KEY;
    if (!stripeKey) {
      return res.status(500).json({
        error: 'Configuration error',
        message: 'Stripe not configured'
      });
    }

    const Stripe = (await import('stripe')).default;
    const stripe = new Stripe(stripeKey, {
      apiVersion: (process.env.STRIPE_API_VERSION || '2025-08-27.basil') as any,
    });

    if (immediate) {
      // Cancel immediately
      await stripe.subscriptions.cancel(subscription.stripe_subscription_id);
      console.log(`🚫 Immediately canceled subscription for user ${userId}`);
    } else {
      // Cancel at period end
      await stripe.subscriptions.update(subscription.stripe_subscription_id, {
        cancel_at_period_end: true
      });
      console.log(`⏳ Scheduled cancellation at period end for user ${userId}`);
    }

    // Update local record (webhook will also update, but do it here for immediate feedback)
    // Try RPC first, fallback to direct update if RPC fails
    const { data: rpcResult, error: updateError } = await supabaseAdmin.rpc('cancel_subscription_server', {
      p_stripe_subscription_id: subscription.stripe_subscription_id,
      p_cancel_at_period_end: !immediate,
      p_immediate: immediate,
      p_user_id: userId
    });

    if (updateError) {
      console.error('❌ RPC error, trying direct update:', updateError.message);
      
      // Fallback: Direct database update
      if (immediate) {
        const { error: directError } = await supabaseAdmin
          .from('subscriptions')
          .update({
            tier: 'free',
            status: 'canceled',
            cancel_at_period_end: false,
            canceled_at: new Date().toISOString(),
            updated_at: new Date().toISOString()
          })
          .eq('user_id', userId);
        
        if (directError) {
          console.error('❌ Direct update also failed:', directError.message);
        } else {
          console.log(`✅ Direct update: immediate cancellation for user ${userId}`);
        }
      } else {
        const { error: directError } = await supabaseAdmin
          .from('subscriptions')
          .update({
            cancel_at_period_end: true,
            canceled_at: new Date().toISOString(),
            updated_at: new Date().toISOString()
          })
          .eq('user_id', userId);
        
        if (directError) {
          console.error('❌ Direct update also failed:', directError.message);
        } else {
          console.log(`✅ Direct update: cancel_at_period_end=true for user ${userId}`);
        }
      }
    } else {
      console.log(`✅ RPC success: cancel_at_period_end=${!immediate} for user ${userId}`, rpcResult);
    }

    // Invalidate any Redis cache for this user
    await invalidateUserCache(userId);
    console.log(`🗑️ Invalidated Redis cache for user ${userId}`);

    // Verify the update by reading back from database
    const { data: verifyData, error: verifyError } = await supabaseAdmin
      .from('subscriptions')
      .select('cancel_at_period_end, canceled_at, tier, status')
      .eq('user_id', userId)
      .single();
    
    console.log(`🔍 Verification read:`, verifyData, verifyError?.message || 'no error');

    return res.json({
      success: true,
      message: immediate 
        ? 'Subscription canceled immediately' 
        : 'Subscription will be canceled at the end of the billing period',
      immediate,
      // Include verification data in response for debugging
      debug: {
        cancel_at_period_end: verifyData?.cancel_at_period_end,
        canceled_at: verifyData?.canceled_at,
        tier: verifyData?.tier,
        status: verifyData?.status
      }
    });

  } catch (error: any) {
    console.error('❌ Error canceling subscription:', error);
    return res.status(500).json({
      error: 'Cancellation error',
      message: error.message
    });
  }
});

/**
 * POST /api/subscriptions/reactivate
 * Reactivate a subscription scheduled for cancellation
 */
router.post('/reactivate', authenticateUser, async (req: Request, res: Response) => {
  try {
    const userId = req.user!.id;

    // Get current subscription
    const { data: subscriptionRows, error: subError } = await supabaseAdmin.rpc(
      'get_subscription_by_user_server',
      { p_user_id: userId }
    );

    const subscription = subscriptionRows?.[0];

    if (subError || !subscription) {
      return res.status(404).json({
        error: 'Not found',
        message: 'No subscription found'
      });
    }

    if (!subscription.cancel_at_period_end) {
      return res.status(400).json({
        error: 'Invalid request',
        message: 'Subscription is not scheduled for cancellation'
      });
    }

    // Get Stripe
    const stripeKey = process.env.STRIPE_SECRET_KEY;
    const Stripe = (await import('stripe')).default;
    const stripe = new Stripe(stripeKey!, {
      apiVersion: (process.env.STRIPE_API_VERSION || '2025-08-27.basil') as any,
    });

    // Reactivate subscription
    await stripe.subscriptions.update(subscription.stripe_subscription_id!, {
      cancel_at_period_end: false
    });

    // Update local record
    await supabaseAdmin.rpc('update_subscription_cancel_status_server', {
      p_user_id: userId,
      p_cancel_at_period_end: false,
      p_canceled_at: null
    });

    console.log(`✅ Reactivated subscription for user ${userId}`);

    return res.json({
      success: true,
      message: 'Subscription reactivated successfully'
    });

  } catch (error: any) {
    console.error('❌ Error reactivating subscription:', error);
    return res.status(500).json({
      error: 'Reactivation error',
      message: error.message
    });
  }
});

/**
 * GET /api/subscriptions/portal
 * Get Stripe Customer Portal URL for managing subscription
 */
router.get('/portal', authenticateUser, async (req: Request, res: Response) => {
  try {
    const userId = req.user!.id;
    const returnUrl = req.query.returnUrl as string || process.env.FRONTEND_URL || 'http://localhost:5173';

    // Get subscription with Stripe customer ID
    const { data: stripeCustomerId, error: subError } = await supabaseAdmin.rpc(
      'get_subscription_stripe_customer_server',
      { p_user_id: userId }
    );

    if (subError || !stripeCustomerId) {
      return res.status(404).json({
        error: 'Not found',
        message: 'No Stripe customer found'
      });
    }

    // Get Stripe
    const stripeKey = process.env.STRIPE_SECRET_KEY;
    const Stripe = (await import('stripe')).default;
    const stripe = new Stripe(stripeKey!, {
      apiVersion: (process.env.STRIPE_API_VERSION || '2025-08-27.basil') as any,
    });

    // Create portal session
    const portalSession = await stripe.billingPortal.sessions.create({
      customer: stripeCustomerId,
      return_url: returnUrl
    });

    return res.json({
      url: portalSession.url
    });

  } catch (error: any) {
    console.error('❌ Error creating portal session:', error);
    return res.status(500).json({
      error: 'Portal error',
      message: error.message
    });
  }
});

/**
 * GET /api/subscriptions/usage
 * Get current usage statistics
 */
router.get('/usage', authenticateUser, async (req: Request, res: Response) => {
  try {
    const userId = req.user!.id;

    // Get usage from Redis (source of truth)
    const usageStats = await getUsageStats(userId);

    // Get subscription for tier and period info
    const { data: subscriptionRows } = await supabaseAdmin.rpc(
      'get_subscription_by_user_server',
      { p_user_id: userId }
    );
    const subscription = subscriptionRows?.[0];

    // Count experiences
    const { data: experienceCount } = await supabaseAdmin.rpc(
      'count_user_experiences_server',
      { p_user_id: userId }
    );

    // Get recent access history (for display only)
    const { data: recentAccess } = await supabaseAdmin.rpc(
      'get_recent_access_logs_server',
      { p_user_id: userId, p_limit: 10 }
    );

    const tier = usageStats.tier as 'free' | 'premium';
    const isPremium = tier === 'premium';
    const tierDetails = getTierDetails(tier);

    return res.json({
      tier,
      is_premium: isPremium,
      
      // Experience limits
      experience_count: experienceCount || 0,
      experience_limit: tierDetails.experienceLimit,
      can_create_experience: isPremium || (experienceCount || 0) < (tierDetails.experienceLimit || Infinity),
      
      // Access usage from Redis (source of truth)
      monthly_access_used: usageStats.used,
      monthly_access_limit: usageStats.limit,
      monthly_access_remaining: usageStats.remaining,
      can_buy_overage: isPremium,
      
      // Pricing info
      overage: tierDetails.overage ? {
        credits_per_batch: tierDetails.overage.creditsPerBatch,
        access_per_batch: tierDetails.overage.accessPerBatch,
        cost_per_access: tierDetails.overage.creditsPerBatch / tierDetails.overage.accessPerBatch,
      } : null,
      monthly_fee: tierDetails.monthlyFeeUsd,
      
      // Period info
      current_period_start: subscription?.current_period_start,
      current_period_end: subscription?.current_period_end,
      
      // Features
      features: {
        translations_enabled: tierDetails.translationsEnabled,
        can_buy_overage: isPremium
      },
      
      // Recent activity
      recent_access: recentAccess || []
    });

  } catch (error: any) {
    console.error('❌ Error fetching usage:', error);
    return res.status(500).json({
      error: 'Usage fetch error',
      message: error.message
    });
  }
});

/**
 * GET /api/subscriptions/daily-stats
 * Get daily access statistics for the chart
 */
router.get('/daily-stats', authenticateUser, async (req: Request, res: Response) => {
  try {
    const userId = req.user!.id;
    const days = parseInt(req.query.days as string) || 30;

    // Flush buffered access logs to DB before fetching stats
    // This ensures the chart shows recent access data
    await flushAccessLogBuffer();

    // Calculate date range
    const endDate = new Date();
    const startDate = new Date();
    startDate.setDate(startDate.getDate() - days + 1);
    startDate.setHours(0, 0, 0, 0);

    // Get daily access counts from card_access_log
    const { data: accessLogs, error } = await supabaseAdmin.rpc(
      'get_daily_access_stats_server',
      {
        p_user_id: userId,
        p_start_date: startDate.toISOString(),
        p_end_date: endDate.toISOString()
      }
    );

    if (error) {
      console.error('❌ Error fetching daily stats:', error);
      return res.status(500).json({ error: 'Database error', message: error.message });
    }

    // Group by day
    const dailyStats: Record<string, { total: number; overage: number }> = {};
    
    // Initialize all days with 0
    for (let d = new Date(startDate); d <= endDate; d.setDate(d.getDate() + 1)) {
      const dateKey = d.toISOString().split('T')[0];
      dailyStats[dateKey] = { total: 0, overage: 0 };
    }

    // Count access per day
    for (const log of accessLogs || []) {
      const dateKey = new Date(log.accessed_at).toISOString().split('T')[0];
      if (dailyStats[dateKey]) {
        dailyStats[dateKey].total++;
        if (log.was_overage) {
          dailyStats[dateKey].overage++;
        }
      }
    }

    // Convert to array format for chart
    const chartData = Object.entries(dailyStats)
      .sort(([a], [b]) => a.localeCompare(b))
      .map(([date, stats]) => ({
        date,
        total: stats.total,
        overage: stats.overage,
        included: stats.total - stats.overage
      }));

    // Calculate summary
    const totalAccess = chartData.reduce((sum, d) => sum + d.total, 0);
    const totalOverage = chartData.reduce((sum, d) => sum + d.overage, 0);
    const avgDaily = Math.round(totalAccess / days);
    const peakDay = chartData.reduce((max, d) => d.total > max.total ? d : max, chartData[0]);

    return res.json({
      period: {
        start: startDate.toISOString().split('T')[0],
        end: endDate.toISOString().split('T')[0],
        days
      },
      data: chartData,
      summary: {
        total_access: totalAccess,
        total_overage: totalOverage,
        total_included: totalAccess - totalOverage,
        average_daily: avgDaily,
        peak_day: peakDay?.date || null,
        peak_count: peakDay?.total || 0
      }
    });

  } catch (error: any) {
    console.error('❌ Error fetching daily stats:', error);
    return res.status(500).json({
      error: 'Stats fetch error',
      message: error.message
    });
  }
});

/**
 * POST /api/subscriptions/buy-credits
 * Buy additional credits for overage (Premium users)
 */
router.post('/buy-credits', authenticateUser, async (req: Request, res: Response) => {
  try {
    const userId = req.user!.id;
    const { amount, baseUrl } = req.body;

    if (!amount || amount <= 0) {
      return res.status(400).json({
        error: 'Validation error',
        message: 'Invalid credit amount'
      });
    }

    if (!baseUrl) {
      return res.status(400).json({
        error: 'Validation error',
        message: 'Base URL is required'
      });
    }

    // Get Stripe
    const stripeKey = process.env.STRIPE_SECRET_KEY;
    if (!stripeKey) {
      return res.status(500).json({
        error: 'Configuration error',
        message: 'Stripe not configured'
      });
    }

    const Stripe = (await import('stripe')).default;
    const stripe = new Stripe(stripeKey, {
      apiVersion: (process.env.STRIPE_API_VERSION || '2025-08-27.basil') as any,
    });

    // Convert credits to cents (1 credit = $1)
    const amountCents = Math.round(amount * 100);

    // Create checkout session for one-time payment
    const session = await stripe.checkout.sessions.create({
      payment_method_types: ['card'],
      line_items: [
        {
          price_data: {
            currency: 'usd',
            product_data: {
              name: 'ExperienceQR Credits',
              description: `${amount} credits for overage access`
            },
            unit_amount: amountCents
          },
          quantity: 1
        }
      ],
      mode: 'payment',
      success_url: `${baseUrl}?success=true&session_id={CHECKOUT_SESSION_ID}&type=credits`,
      cancel_url: `${baseUrl}?canceled=true&type=credits`,
      metadata: {
        user_id: userId,
        type: 'credit_purchase',
        credit_amount: amount.toString()
      }
    });

    // Create pending purchase record
    await supabaseAdmin.rpc('create_credit_purchase_record', {
      p_stripe_session_id: session.id,
      p_amount_usd: amount,
      p_credits_amount: amount,
      p_metadata: { type: 'overage_credits' },
      p_user_id: userId
    });

    console.log(`💳 Created credit purchase checkout for user ${userId}, ${amount} credits`);

    return res.json({
      sessionId: session.id,
      url: session.url
    });

  } catch (error: any) {
    console.error('❌ Error creating credit checkout:', error);
    return res.status(500).json({
      error: 'Payment error',
      message: error.message
    });
  }
});

export default router;

