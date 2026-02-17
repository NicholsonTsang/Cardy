import { Router, Request, Response } from 'express';
import { authenticateUser } from '../middleware/auth';
import { supabaseAdmin } from '../config/supabase';
import { SubscriptionConfig, getPricingInfo, getTierDetails } from '../config/subscription';
import { getUsageStats, flushAccessLogBuffer, invalidateUserCache, updateUserTier, getVoiceCreditBalance } from '../services/usage-tracker';
import { getStripe, validateRedirectUrl } from '../config/stripe';

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

    // Pass business parameters from config to stored procedure (session-based model)
    const { data, error } = await supabaseAdmin.rpc('get_subscription_details', {
      p_user_id: userId,
      p_free_project_limit: SubscriptionConfig.free.projectLimit,
      p_starter_project_limit: SubscriptionConfig.starter.projectLimit,
      p_premium_project_limit: SubscriptionConfig.premium.projectLimit,
      p_free_monthly_sessions: SubscriptionConfig.free.monthlySessionLimit,
      p_starter_monthly_budget: SubscriptionConfig.starter.monthlyBudgetUsd,
      p_premium_monthly_budget: SubscriptionConfig.premium.monthlyBudgetUsd,
      p_starter_ai_session_cost: SubscriptionConfig.starter.aiEnabledSessionCostUsd,
      p_starter_non_ai_session_cost: SubscriptionConfig.starter.aiDisabledSessionCostUsd,
      p_premium_ai_session_cost: SubscriptionConfig.premium.aiEnabledSessionCostUsd,
      p_premium_non_ai_session_cost: SubscriptionConfig.premium.aiDisabledSessionCostUsd,
      p_enterprise_project_limit: SubscriptionConfig.enterprise.projectLimit,
      p_enterprise_monthly_budget: SubscriptionConfig.enterprise.monthlyBudgetUsd,
      p_enterprise_ai_session_cost: SubscriptionConfig.enterprise.aiEnabledSessionCostUsd,
      p_enterprise_non_ai_session_cost: SubscriptionConfig.enterprise.aiDisabledSessionCostUsd,
      p_overage_credits_per_batch: SubscriptionConfig.overage.creditsPerBatch
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
 * Create Stripe checkout session for subscription (Starter or Premium)
 * If user has an existing DIFFERENT tier subscription, it will be canceled automatically
 */
router.post('/create-checkout', authenticateUser, async (req: Request, res: Response) => {
  try {
    const userId = req.user!.id;
    const userEmail = req.user!.email;
    const { baseUrl, tier = 'premium' } = req.body;

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

    if (!['starter', 'premium', 'enterprise'].includes(tier)) {
      return res.status(400).json({
        error: 'Validation error',
        message: 'Invalid tier selected'
      });
    }

    const tierNames: Record<string, string> = { starter: 'Starter', premium: 'Premium', enterprise: 'Enterprise' };
    const stripePriceId = tier === 'starter'
      ? process.env.STRIPE_STARTER_PRICE_ID
      : tier === 'enterprise'
        ? process.env.STRIPE_ENTERPRISE_PRICE_ID
        : process.env.STRIPE_PREMIUM_PRICE_ID;

    if (!stripePriceId) {
      return res.status(500).json({
        error: 'Configuration error',
        message: `${tierNames[tier]} subscription price ID not configured`
      });
    }

    const stripe = getStripe();

    // Check if user has existing subscription
    const { data: currentSubRows } = await supabaseAdmin.rpc('get_subscription_by_user_server', {
      p_user_id: userId
    });
    const currentSub = currentSubRows?.[0];

    // Check if user already has this SAME tier subscription active
    if (currentSub?.tier === tier && currentSub?.status === 'active' && !currentSub?.cancel_at_period_end) {
      return res.status(400).json({
        error: 'Already subscribed',
        message: `You already have an active ${tierNames[tier]} subscription`
      });
    }

    // Determine if this is an upgrade or downgrade
    const tierOrder = { free: 0, starter: 1, premium: 2, enterprise: 3 };
    const currentTierLevel = tierOrder[currentSub?.tier as keyof typeof tierOrder] || 0;
    const newTierLevel = tierOrder[tier as keyof typeof tierOrder];
    const isUpgrade = newTierLevel > currentTierLevel;
    const isDowngrade = newTierLevel < currentTierLevel;
    
    // Variables for checkout session
    let canceledPreviousTier: string | null = null;
    let trialEndTimestamp: number | undefined = undefined;
    
    // If user has a DIFFERENT tier subscription, handle it based on upgrade/downgrade
    if (currentSub?.stripe_subscription_id && 
        currentSub?.tier !== 'free' && 
        currentSub?.tier !== tier &&
        currentSub?.status === 'active') {
      try {
        if (isUpgrade) {
          // UPGRADE: Cancel old subscription immediately, new one starts immediately
          await stripe.subscriptions.cancel(currentSub.stripe_subscription_id);
          canceledPreviousTier = currentSub.tier;
          console.log(`⬆️ UPGRADE: Canceled ${currentSub.tier} subscription immediately for user ${userId} to switch to ${tier}`);
          
          // Update local database record
          await supabaseAdmin.rpc('cancel_subscription_server', {
            p_stripe_subscription_id: currentSub.stripe_subscription_id,
            p_cancel_at_period_end: false,
            p_immediate: true,
            p_user_id: userId,
            p_scheduled_tier: null
          });
          
          // Update Redis cache
          await updateUserTier(userId, 'free');
        } else if (isDowngrade) {
          // DOWNGRADE: Cancel at period end, keep current privileges until then
          // New subscription starts with trial until current period ends
          await stripe.subscriptions.update(currentSub.stripe_subscription_id, {
            cancel_at_period_end: true
          });
          canceledPreviousTier = currentSub.tier;
          
          // Calculate trial end (when current subscription period ends)
          if (currentSub.current_period_end) {
            trialEndTimestamp = Math.floor(new Date(currentSub.current_period_end).getTime() / 1000);
          }
          
          console.log(`⬇️ DOWNGRADE: Set ${currentSub.tier} to cancel at period end for user ${userId}, new ${tier} will start billing after ${currentSub.current_period_end}`);
          
          // Update local database to record the scheduled tier change
          await supabaseAdmin.rpc('cancel_subscription_server', {
            p_stripe_subscription_id: currentSub.stripe_subscription_id,
            p_cancel_at_period_end: true,
            p_immediate: false,
            p_user_id: userId,
            p_scheduled_tier: tier  // Record that user is switching to this tier
          });
          
          // Keep current tier in Redis (user keeps privileges until period end)
          // No need to update Redis - they keep Premium privileges
        }
      } catch (cancelError: any) {
        console.error('❌ Error handling existing subscription:', cancelError);
        return res.status(500).json({
          error: 'Subscription switch error',
          message: 'Failed to process existing subscription for tier switch'
        });
      }
    }

    // Check if user has existing Stripe customer ID
    let customerId: string | null = await supabaseAdmin.rpc(
      'get_subscription_stripe_customer_server',
      { p_user_id: userId }
    ).then(res => res.data ?? null);

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

    // Build subscription_data with optional trial for downgrades
    const subscriptionData: any = {
      metadata: {
        user_id: userId
      }
    };
    
    // For downgrades, set trial_end so new subscription billing starts after current period ends
    if (isDowngrade && trialEndTimestamp) {
      subscriptionData.trial_end = trialEndTimestamp;
      console.log(`📅 Setting trial_end for downgrade: ${new Date(trialEndTimestamp * 1000).toISOString()}`);
    }

    // Create Stripe Checkout session for subscription
    const session = await stripe.checkout.sessions.create({
      customer: customerId as string,
      line_items: [
        {
          price: stripePriceId,
          quantity: 1
        }
      ],
      mode: 'subscription',
      success_url: `${baseUrl}?success=true&session_id={CHECKOUT_SESSION_ID}&type=subscription${canceledPreviousTier ? `&switched_from=${canceledPreviousTier}` : ''}${isDowngrade ? '&downgrade=true' : ''}`,
      cancel_url: `${baseUrl}?canceled=true&type=subscription`,
      metadata: {
        user_id: userId,
        type: `${tier}_subscription`,
        ...(canceledPreviousTier ? { switched_from: canceledPreviousTier } : {}),
        ...(isDowngrade ? { is_downgrade: 'true' } : {})
      },
      subscription_data: subscriptionData
    });

    console.log(`📦 Created subscription checkout for user ${userId}, session ${session.id}${canceledPreviousTier ? ` (switched from ${canceledPreviousTier})` : ''}${isDowngrade ? ' (DOWNGRADE with trial)' : ''}`);

    return res.json({
      sessionId: session.id,
      url: session.url,
      switchedFrom: canceledPreviousTier
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

    if (!['starter', 'premium', 'enterprise'].includes(subscription.tier)) {
      return res.status(400).json({
        error: 'Invalid request',
        message: 'Only paid subscriptions can be canceled'
      });
    }

    if (!subscription.stripe_subscription_id) {
      return res.status(400).json({
        error: 'Invalid state',
        message: 'No Stripe subscription linked'
      });
    }

    const stripe = getStripe();

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
    // scheduled_tier defaults to 'free' when canceling to free plan
    const { error: updateError } = await supabaseAdmin.rpc('cancel_subscription_server', {
      p_stripe_subscription_id: subscription.stripe_subscription_id,
      p_cancel_at_period_end: !immediate,
      p_immediate: immediate,
      p_user_id: userId,
      p_scheduled_tier: 'free'  // Canceling goes to free tier
    });

    if (updateError) {
      console.error('❌ RPC cancel_subscription_server error:', updateError.message);
      // The Stripe cancellation succeeded, so the webhook will eventually update the DB.
      // Log the error but don't fail the request.
    } else {
      console.log(`✅ RPC success: cancel_at_period_end=${!immediate} for user ${userId}`);
    }

    // Invalidate any Redis cache for this user
    await invalidateUserCache(userId);
    console.log(`🗑️ Invalidated Redis cache for user ${userId}`);

    return res.json({
      success: true,
      message: immediate
        ? 'Subscription canceled immediately'
        : 'Subscription will be canceled at the end of the billing period',
      immediate
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

    const stripe = getStripe();

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

    // Validate returnUrl to prevent open redirect
    if (!validateRedirectUrl(returnUrl)) {
      return res.status(400).json({
        error: 'Validation error',
        message: 'Invalid return URL'
      });
    }

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

    const stripe = getStripe();

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

    // Count projects
    const { data: projectCount } = await supabaseAdmin.rpc(
      'count_user_projects_server',
      { p_user_id: userId }
    );

    // Get recent access history (for display only)
    const { data: recentAccess } = await supabaseAdmin.rpc(
      'get_recent_access_logs_server',
      { p_user_id: userId, p_limit: 10 }
    );

    const tier = usageStats.tier as 'free' | 'starter' | 'premium' | 'enterprise';
    const isPaid = tier === 'starter' || tier === 'premium' || tier === 'enterprise';
    const isPremium = tier === 'premium' || tier === 'enterprise';
    const tierDetails = getTierDetails(tier);

    return res.json({
      tier,
      is_premium: isPremium,
      
      // Project limits
      project_count: projectCount || 0,
      project_limit: tierDetails.projectLimit,
      can_create_project: isPremium || (projectCount || 0) < (tierDetails.projectLimit || Infinity),
      
      // Access usage from Redis (source of truth)
      monthly_access_used: usageStats.budgetConsumed,
      monthly_access_limit: usageStats.monthlyBudget,
      monthly_access_remaining: usageStats.budgetRemaining,
      can_buy_overage: isPaid,
      
      // Pricing info
      overage: tierDetails.overage ? {
        credits_per_batch: tierDetails.overage.creditsPerBatch,
        access_per_batch: tierDetails.overage.aiEnabledSessionsPerBatch,
        cost_per_access: tierDetails.overage.creditsPerBatch / tierDetails.overage.aiEnabledSessionsPerBatch,
      } : null,
      monthly_fee: tierDetails.monthlyFeeUsd,
      
      // Period info
      current_period_start: subscription?.current_period_start,
      current_period_end: subscription?.current_period_end,
      
      // Features
      features: {
        translations_enabled: tierDetails.translationsEnabled,
        can_buy_overage: isPaid
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
 * Now includes AI-enabled vs non-AI session breakdown
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

    // Get daily access counts from card_access_log (now includes is_ai_enabled and session_cost_usd)
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

    // Group by day with AI breakdown
    const dailyStats: Record<string, { 
      total: number; 
      overage: number;
      ai_sessions: number;
      non_ai_sessions: number;
      ai_cost_usd: number;
      non_ai_cost_usd: number;
    }> = {};
    
    // Initialize all days with 0
    for (let d = new Date(startDate); d <= endDate; d.setDate(d.getDate() + 1)) {
      const dateKey = d.toISOString().split('T')[0];
      dailyStats[dateKey] = { 
        total: 0, 
        overage: 0, 
        ai_sessions: 0, 
        non_ai_sessions: 0,
        ai_cost_usd: 0,
        non_ai_cost_usd: 0
      };
    }

    // Count access per day with AI breakdown
    for (const log of accessLogs || []) {
      const dateKey = new Date(log.accessed_at).toISOString().split('T')[0];
      if (dailyStats[dateKey]) {
        dailyStats[dateKey].total++;
        if (log.was_overage) {
          dailyStats[dateKey].overage++;
        }
        // Track AI vs non-AI sessions
        if (log.is_ai_enabled) {
          dailyStats[dateKey].ai_sessions++;
          dailyStats[dateKey].ai_cost_usd += parseFloat(log.session_cost_usd) || 0;
        } else {
          dailyStats[dateKey].non_ai_sessions++;
          dailyStats[dateKey].non_ai_cost_usd += parseFloat(log.session_cost_usd) || 0;
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
        included: stats.total - stats.overage,
        ai_sessions: stats.ai_sessions,
        non_ai_sessions: stats.non_ai_sessions,
        ai_cost_usd: Math.round(stats.ai_cost_usd * 100) / 100,
        non_ai_cost_usd: Math.round(stats.non_ai_cost_usd * 100) / 100
      }));

    // Calculate summary with AI breakdown
    const totalAccess = chartData.reduce((sum, d) => sum + d.total, 0);
    const totalOverage = chartData.reduce((sum, d) => sum + d.overage, 0);
    const totalAiSessions = chartData.reduce((sum, d) => sum + d.ai_sessions, 0);
    const totalNonAiSessions = chartData.reduce((sum, d) => sum + d.non_ai_sessions, 0);
    const totalAiCostUsd = chartData.reduce((sum, d) => sum + d.ai_cost_usd, 0);
    const totalNonAiCostUsd = chartData.reduce((sum, d) => sum + d.non_ai_cost_usd, 0);
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
        peak_count: peakDay?.total || 0,
        // AI breakdown
        ai_sessions: totalAiSessions,
        non_ai_sessions: totalNonAiSessions,
        ai_cost_usd: Math.round(totalAiCostUsd * 100) / 100,
        non_ai_cost_usd: Math.round(totalNonAiCostUsd * 100) / 100,
        total_cost_usd: Math.round((totalAiCostUsd + totalNonAiCostUsd) * 100) / 100
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

    // Convert credits to cents (1 credit = $1)
    const amountCents = Math.round(amount * 100);

    // Create checkout session for one-time payment
    const session = await stripe.checkout.sessions.create({
      customer: customerId,
      line_items: [
        {
          price_data: {
            currency: 'usd',
            product_data: {
              name: 'FunTell Credits',
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

/**
 * GET /api/subscriptions/voice-credits
 * Get current user's voice credit balance
 */
router.get('/voice-credits', authenticateUser, async (req: Request, res: Response) => {
  try {
    const userId = req.user!.id;

    const balance = await getVoiceCreditBalance(userId);

    return res.json({ balance });
  } catch (error: any) {
    console.error('❌ Error fetching voice credit balance:', error);
    return res.status(500).json({
      error: 'Internal server error',
      message: error.message
    });
  }
});

export default router;

