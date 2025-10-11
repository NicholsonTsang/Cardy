import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import Stripe from 'https://esm.sh/stripe@14.5.0?target=deno'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.1'

serve(async (req) => {
  try {
    // Initialize Stripe
    const stripeKey = Deno.env.get('STRIPE_SECRET_KEY')
    const webhookSecret = Deno.env.get('STRIPE_WEBHOOK_SECRET')
    
    if (!stripeKey || !webhookSecret) {
      throw new Error('Stripe configuration missing')
    }

    const stripe = new Stripe(stripeKey, {
      apiVersion: '2023-10-16',
      httpClient: Stripe.createFetchHttpClient()
    })

    // Verify webhook signature
    const signature = req.headers.get('stripe-signature')
    if (!signature) {
      throw new Error('No signature provided')
    }

    const body = await req.text()
    
    let event: Stripe.Event
    try {
      // Use async version for Deno's async crypto
      event = await stripe.webhooks.constructEventAsync(body, signature, webhookSecret)
    } catch (err) {
      console.error('Webhook signature verification failed:', err)
      return new Response(
        JSON.stringify({ error: 'Invalid signature' }),
        { status: 400 }
      )
    }

    // Initialize Supabase
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    const supabase = createClient(supabaseUrl, supabaseServiceKey)

    // Handle different event types
    switch (event.type) {
      case 'checkout.session.completed': {
        const session = event.data.object as Stripe.Checkout.Session
        
        // Check if this is a credit purchase
        if (session.metadata?.type !== 'credit_purchase') {
          console.log('Not a credit purchase, skipping')
          return new Response(JSON.stringify({ received: true }), { status: 200 })
        }

        // Get the full session with payment intent
        const fullSession = await stripe.checkout.sessions.retrieve(session.id, {
          expand: ['payment_intent']
        })

        const creditAmount = parseFloat(fullSession.metadata?.credit_amount || '0')
        
        if (creditAmount > 0) {
          const paymentIntent = fullSession.payment_intent as Stripe.PaymentIntent
          const receiptUrl = paymentIntent?.charges?.data?.[0]?.receipt_url || null

          // Complete the credit purchase
          const { error } = await supabase.rpc('complete_credit_purchase', {
            p_stripe_session_id: session.id,
            p_stripe_payment_intent_id: paymentIntent?.id || null,
            p_receipt_url: receiptUrl,
            p_payment_method: {
              type: paymentIntent?.payment_method_types?.[0] || 'card'
            }
          })

          if (error) {
            console.error('Error completing credit purchase:', error)
            throw error
          }

          console.log(`Credit purchase completed: ${creditAmount} credits for session ${session.id}`)
        }
        break
      }

      case 'charge.refunded': {
        const charge = event.data.object as Stripe.Charge
        
        // Find the credit purchase by payment intent
        if (charge.payment_intent) {
          // First, find the purchase by stripe payment intent ID
          const { data: purchases, error: findError } = await supabase
            .from('credit_purchases')
            .select('id, credits_amount')
            .eq('stripe_payment_intent_id', charge.payment_intent)
            .single()

          if (findError) {
            console.error('Error finding purchase for refund:', findError)
          } else if (purchases) {
            // Calculate refund amount in credits
            const refundAmountCents = charge.amount_refunded
            const refundCredits = refundAmountCents / 100 // 1 credit = $1

            // Process the refund
            const { error: refundError } = await supabase.rpc('refund_credit_purchase', {
              p_purchase_id: purchases.id,
              p_refund_amount: refundCredits,
              p_reason: 'Stripe refund processed'
            })

            if (refundError) {
              console.error('Error processing credit refund:', refundError)
              throw refundError
            }

            console.log(`Credit refund processed: ${refundCredits} credits for purchase ${purchases.id}`)
          }
        }
        break
      }

      default:
        console.log(`Unhandled event type: ${event.type}`)
    }

    return new Response(
      JSON.stringify({ received: true }),
      { status: 200 }
    )
  } catch (error) {
    console.error('Webhook error:', error)
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 400 }
    )
  }
})
