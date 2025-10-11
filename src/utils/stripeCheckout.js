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

/**
 * Create Stripe Checkout session and redirect to payment
 * @param {number} cardCount - Number of cards to purchase
 * @param {string} batchId - UUID of the batch
 * @param {Object} metadata - Additional metadata for the payment
 * @returns {Promise<void>} - Redirects to Stripe Checkout
 */
export const createCheckoutSession = async (cardCount, batchId, metadata = {}) => {
  try {
    // Validate inputs
    if (!cardCount || cardCount <= 0) {
      throw new Error('Invalid card count')
    }
    if (!batchId) {
      throw new Error('Batch ID is required')
    }

    // Check if Stripe is configured
    const publishableKey = import.meta.env.VITE_STRIPE_PUBLISHABLE_KEY
    if (!publishableKey) {
      throw new Error('Stripe is not configured. Please add VITE_STRIPE_PUBLISHABLE_KEY to your .env file')
    }

    // Build base URL for Stripe return (success and cancel both use the same base)
    // The Edge Function will append query parameters (cardId, batchId, tab, success/canceled)
    const baseUrl = import.meta.env.VITE_STRIPE_SUCCESS_URL || `${window.location.origin}/cms/mycards`

    // Create checkout session via Edge Function
    const { data, error } = await supabase.functions.invoke('create-checkout-session', {
      body: {
        cardCount,
        batchId,
        baseUrl,
        metadata
      }
    })

    if (error) {
      console.error('Error creating checkout session:', error)
      throw new Error(error.message || 'Failed to create checkout session')
    }

    if (!data?.sessionId) {
      throw new Error('No session ID returned from server')
    }

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
    console.error('Checkout session error:', error)
    throw error
  }
}

/**
 * Handle successful checkout return
 * @param {string} sessionId - Stripe checkout session ID
 * @returns {Promise<Object>} - Payment confirmation details
 */
export const handleCheckoutSuccess = async (sessionId) => {
  try {
    if (!sessionId) {
      throw new Error('Session ID is required')
    }

    // Call Edge Function to process successful payment
    const { data, error } = await supabase.functions.invoke('handle-checkout-success', {
      body: { sessionId }
    })

    if (error) {
      console.error('Error handling checkout success:', error)
      throw new Error(error.message || 'Failed to process successful payment')
    }

    return data
  } catch (error) {
    console.error('Checkout success handling error:', error)
    throw error
  }
}


/**
 * Calculate payment amount for given card count
 * @param {number} cardCount - Number of cards
 * @returns {Object} - Amount details
 */
export const calculatePaymentAmount = (cardCount) => {
  const pricePerCard = parseInt(import.meta.env.VITE_CARD_PRICE_CENTS) || 200 // $2.00 per card
  const currency = (import.meta.env.VITE_DEFAULT_CURRENCY || 'USD').toLowerCase()
  
  return {
    pricePerCard,
    totalCents: cardCount * pricePerCard,
    totalDollars: (cardCount * pricePerCard) / 100,
    currency,
    cardCount
  }
}

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
 * Calculate batch total cost with formatted output
 * @param {number} cardCount - Number of cards
 * @param {string} currency - Currency code
 * @returns {Object} Cost calculation details
 */
export const calculateBatchCost = (cardCount, currency = 'USD') => {
  const pricePerCard = parseInt(import.meta.env.VITE_CARD_PRICE_CENTS) || 200
  const totalCents = cardCount * pricePerCard
  
  return {
    cardCount,
    pricePerCardCents: pricePerCard,
    pricePerCardFormatted: formatAmount(pricePerCard, currency),
    totalCents,
    totalFormatted: formatAmount(totalCents, currency),
    currency
  }
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