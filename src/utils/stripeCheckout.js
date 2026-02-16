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
// CREDIT PURCHASE FUNCTIONS
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

    // Create checkout session via Backend API
    const response = await fetch(`${import.meta.env.VITE_BACKEND_URL}/api/payments/create-credit-checkout`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${session.access_token}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        creditAmount,
        amountUsd: creditAmount, // 1 credit = $1 USD
        baseUrl,
        metadata
      })
    })

    if (!response.ok) {
      const errorData = await response.json()
      console.error('Error creating credit checkout session:', errorData)
      throw new Error(errorData.message || errorData.error || 'Failed to create checkout session')
    }

    const data = await response.json()

    if (!data?.sessionId) {
      throw new Error('No session ID returned from server')
    }

    // Note: The Backend API already created the purchase record in the database
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
 * @param {string} sessionId - Stripe checkout session ID (optional, for backward compatibility)
 * @returns {Promise<Object>} - Payment confirmation details
 * 
 * NOTE: Credit purchase completion is now handled automatically via Stripe webhooks.
 * The webhook endpoint processes the 'checkout.session.completed' event and credits
 * are added to the user's account automatically. This function is kept for backward
 * compatibility and simply refreshes the credit balance.
 */
export const handleCreditPurchaseSuccess = async (sessionId) => {
  try {
    // Credit purchase is now handled by Stripe webhooks automatically
    // Just refresh the credit balance to show the updated amount
    const creditStore = useCreditStore()
    await creditStore.fetchCreditBalance()

    return {
      success: true,
      message: 'Credit purchase processed successfully',
      sessionId
    }
  } catch (error) {
    console.error('Error refreshing credit balance:', error)
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