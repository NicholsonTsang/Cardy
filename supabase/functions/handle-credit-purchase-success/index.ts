import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import Stripe from 'https://esm.sh/stripe@14.5.0?target=deno'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.1'
import { corsHeaders } from '../_shared/cors.ts'

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Initialize Stripe
    const stripeKey = Deno.env.get('STRIPE_SECRET_KEY')
    if (!stripeKey) {
      throw new Error('Stripe secret key not configured')
    }

    const stripe = new Stripe(stripeKey, {
      apiVersion: '2023-10-16',
      httpClient: Stripe.createFetchHttpClient()
    })

    // Initialize Supabase client with service role key
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    
    const supabase = createClient(supabaseUrl, supabaseServiceKey)

    const { sessionId } = await req.json()

    if (!sessionId) {
      throw new Error('Session ID is required')
    }

    // Retrieve the session from Stripe
    const session = await stripe.checkout.sessions.retrieve(sessionId, {
      expand: ['payment_intent']
    })

    // Verify the payment was successful
    if (session.payment_status !== 'paid') {
      throw new Error('Payment not completed')
    }

    // Extract metadata
    const creditAmount = parseFloat(session.metadata?.credit_amount || '0')
    const amountUsd = parseFloat(session.metadata?.amount_usd || '0')

    if (creditAmount <= 0) {
      throw new Error('Invalid credit amount in session metadata')
    }

    // Get payment intent details
    const paymentIntent = session.payment_intent as Stripe.PaymentIntent
    const receiptUrl = paymentIntent?.charges?.data?.[0]?.receipt_url || null

    // Complete the credit purchase in the database
    const { data, error } = await supabase.rpc('complete_credit_purchase', {
      p_stripe_session_id: sessionId,
      p_stripe_payment_intent_id: paymentIntent?.id || null,
      p_receipt_url: receiptUrl,
      p_payment_method: {
        type: paymentIntent?.payment_method_types?.[0] || 'card',
        last4: paymentIntent?.charges?.data?.[0]?.payment_method_details?.card?.last4 || null,
        brand: paymentIntent?.charges?.data?.[0]?.payment_method_details?.card?.brand || null
      }
    })

    if (error) {
      console.error('Database error completing credit purchase:', error)
      throw new Error(error.message || 'Failed to complete credit purchase in database')
    }

    return new Response(
      JSON.stringify({
        success: true,
        data,
        creditAmount,
        receiptUrl
      }),
      {
        headers: {
          ...corsHeaders,
          'Content-Type': 'application/json'
        }
      }
    )
  } catch (error) {
    console.error('Error handling credit purchase success:', error)
    return new Response(
      JSON.stringify({
        error: error.message || 'Failed to process credit purchase'
      }),
      {
        status: 400,
        headers: {
          ...corsHeaders,
          'Content-Type': 'application/json'
        }
      }
    )
  }
})
