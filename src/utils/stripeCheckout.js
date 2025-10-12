import { loadStripe } from '@stripe/stripe-js'
import { supabase } from '@/lib/supabase'
import { useCreditStore } from '@/stores/credits'

// Initialize Stripe instance
let stripeInstance = null

/**
 * Get Stripe instance with publishable key
 */
export const getStripe = async () => {
  if (!stripeInstance) {
    const publishableKey = import.meta.env.VITE_STRIPE_PUBLISHABLE_KEY
    if (!publishableKey) {
      console.warn('Stripe publishable key is not configured - running in demo mode')
      return null
    }
    stripeInstance = await loadStripe(publishableKey)
  }
  return stripeInstance
}

// ============================================================================
// LEGACY BATCH PAYMENT FUNCTIONS REMOVED
// ============================================================================
// The following functions have been removed as they're no longer used:
// - createCheckoutSession() - Replaced by credit-based batch issuance
// - handleCheckoutSuccess() - Replaced by credit-based batch issuance
// - calculatePaymentAmount() - Replaced by credit calculations
// - calculateBatchCost() - Replaced by credit calculations
// - formatAmount() - Still available below for credit system
//
// Current system: Users purchase credits first, then use credits to issue batches
// See: CardIssuanceCheckout.vue and useCreditStore().issueBatchWithCredits()
// ============================================================================

/**
 * Format amount in cents to currency string
 * @param {number} amountCents - Amount in cents
 * @param {string} currency - Currency code (default: USD)
 * @returns {string} Formatted amount string
 */
export const formatAmount = (amountCents, currency = 'USD') => {
  const currencyCode = currency.toUpperCase()
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: currencyCode
  }).format(amountCents / 100)
}

/**
 * Create Stripe Checkout session for credit purchase
 * @param {number} creditAmount - Amount of credits to purchase (1 credit = $1 USD)
 * @param {Object} metadata - Additional metadata for the payment
 * @returns {Promise<void>} - Redirects to Stripe Checkout
 */
export const createCreditPurchaseCheckout = async (creditAmount, metadata = {}) => {
  try {
    // Check if user is authenticated
    const { data: { session }, error: sessionError } = await supabase.auth.getSession()
    
    if (sessionError || !session) {
      console.error('Session error:', sessionError)
      throw new Error('Your session has expired. Please refresh the page and log in again.')
    }

    const { data: { user }, error: authError } = await supabase.auth.getUser()
    
    if (authError || !user) {
      console.error('Authentication error:', authError)
      throw new Error('You must be logged in to purchase credits. Please refresh the page and try again.')
    }

    console.log('Creating credit checkout for user:', user.id)
    console.log('Session access token present:', !!session?.access_token)

    // Validate inputs
    if (!creditAmount || creditAmount <= 0) {
      throw new Error('Invalid credit amount')
    }

    // Check if Stripe is configured
    const publishableKey = import.meta.env.VITE_STRIPE_PUBLISHABLE_KEY
    if (!publishableKey) {
      throw new Error('Stripe is not configured. Please add VITE_STRIPE_PUBLISHABLE_KEY to your .env file')
    }

    // Build base URL for Stripe return
    const baseUrl = import.meta.env.VITE_STRIPE_SUCCESS_URL || `${window.location.origin}/cms/credits`

    // Create checkout session via Edge Function
    // Explicitly pass the authorization header to ensure it's included
    const { data, error } = await supabase.functions.invoke('create-credit-checkout-session', {
      headers: {
        Authorization: `Bearer ${session.access_token}`
      },
      body: {
        creditAmount,
        amountUsd: creditAmount, // 1 credit = $1 USD
        baseUrl,
        metadata
      }
    })

    if (error) {
      console.error('Error creating credit checkout session:', error)
      throw new Error(error.message || 'Failed to create checkout session')
    }

    if (!data?.sessionId) {
      throw new Error('No session ID returned from server')
    }

    // Note: The Edge Function already created the purchase record in the database
    // No need to create it again here

    // Get Stripe instance
    const stripe = await getStripe()
    if (!stripe) {
      throw new Error('Failed to load Stripe')
    }

    // Redirect to Stripe Checkout
    const { error: redirectError } = await stripe.redirectToCheckout({
      sessionId: data.sessionId
    })

    if (redirectError) {
      console.error('Stripe redirect error:', redirectError)
      throw new Error(redirectError.message || 'Failed to redirect to checkout')
    }

  } catch (error) {
    console.error('Credit checkout session error:', error)
    throw error
  }
}

/**
 * Handle successful credit purchase checkout
 * @param {string} sessionId - Stripe checkout session ID
 * @returns {Promise<Object>} - Payment confirmation details
 */
export const handleCreditPurchaseSuccess = async (sessionId) => {
  try {
    if (!sessionId) {
      throw new Error('Session ID is required')
    }

    // Call Edge Function to process successful credit purchase
    const { data, error } = await supabase.functions.invoke('handle-credit-purchase-success', {
      body: { sessionId }
    })

    if (error) {
      console.error('Error handling credit purchase success:', error)
      throw new Error(error.message || 'Failed to process successful payment')
    }

    // Refresh credit balance
    const creditStore = useCreditStore()
    await creditStore.fetchCreditBalance()

    return data
  } catch (error) {
    console.error('Credit purchase success handling error:', error)
    throw error
  }
}

/**
 * Calculate credit purchase amount
 * @param {number} creditAmount - Number of credits to purchase
 * @returns {Object} - Amount details
 */
export const calculateCreditPurchaseAmount = (creditAmount) => {
  const pricePerCredit = 100 // $1.00 per credit in cents
  const currency = (import.meta.env.VITE_DEFAULT_CURRENCY || 'USD').toLowerCase()
  
  return {
    pricePerCredit,
    totalCents: creditAmount * pricePerCredit,
    totalDollars: creditAmount,
    currency,
    creditAmount
  }
}