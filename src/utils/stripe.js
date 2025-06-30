/**
 * Stripe Payment Utilities for Batch Issuance
 * This is a dummy implementation for now - replace with actual Stripe integration
 */

// Dummy Stripe class for development
class DummyStripe {
  constructor(publicKey) {
    this.publicKey = publicKey;
    console.log('DummyStripe initialized with key:', publicKey);
  }

  async createPaymentIntent(amount, currency = 'usd', metadata = {}) {
    // Simulate API call delay
    await new Promise(resolve => setTimeout(resolve, 1000));
    
    // Generate dummy payment intent
    const paymentIntentId = `pi_dummy_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    const clientSecret = `${paymentIntentId}_secret_${Math.random().toString(36).substr(2, 16)}`;
    
    console.log('Created dummy payment intent:', {
      id: paymentIntentId,
      amount,
      currency,
      metadata
    });

    return {
      id: paymentIntentId,
      client_secret: clientSecret,
      amount,
      currency,
      status: 'requires_payment_method',
      metadata
    };
  }

  async confirmPayment(clientSecret, paymentMethodData) {
    // Simulate payment processing delay
    await new Promise(resolve => setTimeout(resolve, 2000));
    
    // Simulate random success/failure for testing
    const success = Math.random() > 0.1; // 90% success rate
    
    if (success) {
      console.log('Dummy payment confirmed successfully');
      return {
        paymentIntent: {
          id: clientSecret.split('_secret_')[0],
          status: 'succeeded',
          payment_method: {
            type: 'card',
            card: {
              brand: 'visa',
              last4: '4242'
            }
          }
        },
        error: null
      };
    } else {
      console.log('Dummy payment failed');
      return {
        paymentIntent: null,
        error: {
          type: 'card_error',
          code: 'card_declined',
          message: 'Your card was declined.',
          decline_code: 'generic_decline'
        }
      };
    }
  }

  elements() {
    return new DummyElements();
  }
}

class DummyElements {
  create(type, options = {}) {
    console.log(`Creating dummy ${type} element with options:`, options);
    return new DummyElement(type);
  }
}

class DummyElement {
  constructor(type) {
    this.type = type;
    this.mounted = false;
  }

  mount(selector) {
    console.log(`Mounting dummy ${this.type} element to:`, selector);
    this.mounted = true;
    
    // Create a simple dummy payment form
    const container = typeof selector === 'string' ? document.querySelector(selector) : selector;
    if (container) {
      container.innerHTML = `
        <div style="border: 1px solid #ccc; padding: 16px; border-radius: 4px; background: #f8f9fa; text-align: center;">
          <p style="margin: 0; color: #666; font-size: 14px;">
            🔧 Dummy Stripe Payment Element
          </p>
          <p style="margin: 8px 0 0 0; color: #888; font-size: 12px;">
            This is a placeholder for the actual Stripe payment form
          </p>
        </div>
      `;
    }
  }

  unmount() {
    console.log(`Unmounting dummy ${this.type} element`);
    this.mounted = false;
  }

  on(event, callback) {
    console.log(`Dummy element listening for ${event} events`);
    // Simulate ready event
    if (event === 'ready') {
      setTimeout(callback, 100);
    }
  }
}

// Configuration
const STRIPE_CONFIG = {
  // Replace with your actual Stripe publishable key
  publicKey: import.meta.env.VITE_STRIPE_PUBLISHABLE_KEY || 'pk_test_dummy_key_for_development',
  apiVersion: '2023-10-16',
  defaultCurrency: import.meta.env.VITE_DEFAULT_CURRENCY || 'USD'
};

// Initialize Stripe instance
let stripeInstance = null;

export const getStripe = () => {
  if (!stripeInstance) {
    // For development, use dummy Stripe
    // In production, replace with: stripeInstance = new Stripe(STRIPE_CONFIG.publicKey);
    stripeInstance = new DummyStripe(STRIPE_CONFIG.publicKey);
  }
  return stripeInstance;
};

/**
 * Create a payment intent for batch issuance
 * @param {number} cardCount - Number of cards in the batch
 * @param {Object} metadata - Additional metadata for the payment
 * @returns {Promise<Object>} Payment intent object
 */
export const createBatchPaymentIntent = async (cardCount, metadata = {}) => {
  const stripe = getStripe();
  const pricePerCard = parseInt(import.meta.env.VITE_CARD_PRICE_CENTS) || 200;
  const amountCents = cardCount * pricePerCard; // Price per card in cents
  const currency = (import.meta.env.VITE_DEFAULT_CURRENCY || 'USD').toLowerCase();
  
  const paymentIntent = await stripe.createPaymentIntent(
    amountCents,
    currency,
    {
      ...metadata,
      purpose: 'batch_issuance',
      card_count: cardCount
    }
  );
  
  return paymentIntent;
};

/**
 * Confirm a payment with the provided payment method
 * @param {string} clientSecret - Payment intent client secret
 * @param {Object} paymentMethodData - Payment method data from Stripe Elements
 * @returns {Promise<Object>} Payment confirmation result
 */
export const confirmBatchPayment = async (clientSecret, paymentMethodData = {}) => {
  const stripe = getStripe();
  
  const result = await stripe.confirmPayment(clientSecret, {
    payment_method: {
      type: 'card',
      ...paymentMethodData
    }
  });
  
  return result;
};

/**
 * Format amount for display (cents to dollars)
 * @param {number} amountCents - Amount in cents
 * @returns {string} Formatted amount string
 */
export const formatAmount = (amountCents, currency = 'USD') => {
  const currencyCode = currency.toUpperCase();
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: currencyCode
  }).format(amountCents / 100);
};

/**
 * Calculate batch total cost
 * @param {number} cardCount - Number of cards
 * @returns {Object} Cost breakdown
 */
export const calculateBatchCost = (cardCount) => {
  const pricePerCard = parseInt(import.meta.env.VITE_CARD_PRICE_CENTS) || 200;
  const currency = import.meta.env.VITE_DEFAULT_CURRENCY || 'USD';
  const totalCents = cardCount * pricePerCard;
  
  return {
    cardCount,
    pricePerCardCents: pricePerCard,
    pricePerCardFormatted: formatAmount(pricePerCard, currency),
    totalCents,
    totalFormatted: formatAmount(totalCents, currency),
    currency
  };
};

export { STRIPE_CONFIG }; 