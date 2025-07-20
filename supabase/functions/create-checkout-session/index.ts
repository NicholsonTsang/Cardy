import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import Stripe from 'https://esm.sh/stripe@14.21.0'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Initialize Stripe
    const stripe = new Stripe(Deno.env.get('STRIPE_SECRET_KEY') || '', {
      apiVersion: '2023-10-16',
    })

    // Initialize Supabase client
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      {
        global: {
          headers: { Authorization: req.headers.get('Authorization')! },
        },
      }
    )

    // Get user session
    const {
      data: { user },
    } = await supabaseClient.auth.getUser()

    if (!user) {
      return new Response(
        JSON.stringify({ error: 'Unauthorized' }),
        {
          status: 401,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      )
    }

    // Parse request body
    const { cardCount, batchId, metadata = {} } = await req.json()

    // Validate input
    if (!cardCount || !batchId || cardCount <= 0) {
      return new Response(
        JSON.stringify({ error: 'Invalid card count or batch ID' }),
        {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      )
    }

    // Calculate amount
    const pricePerCard = 200 // $2.00 in cents
    const totalAmount = cardCount * pricePerCard

    // Validate minimum amount (Stripe requirement)
    if (totalAmount < 50) {
      return new Response(
        JSON.stringify({ error: 'Minimum amount is $0.50' }),
        {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      )
    }

    // Get batch and card information for checkout session
    const { data: batchData, error: batchError } = await supabaseClient
      .rpc('get_batch_for_checkout', {
        p_batch_id: batchId
      })

    if (batchError || !batchData || batchData.length === 0) {
      return new Response(
        JSON.stringify({ error: 'Batch not found or unauthorized' }),
        {
          status: 404,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      )
    }

    const batch = batchData[0]

    // Construct the checkout session
    const baseUrl = req.headers.get('origin') || 'http://localhost:5173'
    
    const checkoutSession = await stripe.checkout.sessions.create({
      payment_method_types: ['card'],
      mode: 'payment',
      line_items: [
        {
          price_data: {
            currency: 'usd',
            product_data: {
              name: `Digital Cards - ${batch.card_name || 'CardStudio Experience'}`,
              description: `${cardCount} cards for ${batch.card_name}`,
              images: [batch.card_image_url || 'https://images.unsplash.com/photo-1557683311-eac922347aa1?w=600&h=900&fit=crop'],
            },
            unit_amount: pricePerCard,
          },
          quantity: cardCount,
        },
      ],
      success_url: `${baseUrl}/cms/mycards?session_id={CHECKOUT_SESSION_ID}&batch_id=${batchId}`,
      cancel_url: `${baseUrl}/cms/mycards?canceled=true&batch_id=${batchId}`,
      metadata: {
        batch_id: batchId,
        user_id: user.id,
        card_count: cardCount.toString(),
        ...metadata,
      },
      customer_email: user.email,
      billing_address_collection: 'auto',
      payment_intent_data: {
        metadata: {
          batch_id: batchId,
          user_id: user.id,
          card_count: cardCount.toString(),
        },
      },
    })

    // Check if payment already exists for this batch
    const { data: existingPaymentData, error: checkError } = await supabaseClient
      .rpc('get_existing_batch_payment', {
        p_batch_id: batchId
      })

    if (checkError) {
      console.error('Error checking existing payment:', checkError)
      return new Response(
        JSON.stringify({ error: 'Failed to check payment status' }),
        {
          status: 500,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      )
    }

    const existingPayment = existingPaymentData && existingPaymentData.length > 0 ? existingPaymentData[0] : null

    // If payment already exists and is completed, return error
    if (existingPayment && existingPayment.payment_status === 'succeeded') {
      return new Response(
        JSON.stringify({ error: 'Payment already completed for this batch' }),
        {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      )
    }

    // If payment exists but is pending, try to retrieve the existing session
    if (existingPayment && existingPayment.payment_status === 'pending') {
      try {
        const existingSession = await stripe.checkout.sessions.retrieve(
          existingPayment.stripe_checkout_session_id
        )
        
        // If session is still valid and not expired, return it
        if (existingSession.status === 'open' && existingSession.url) {
          return new Response(
            JSON.stringify({
              sessionId: existingSession.id,
              url: existingSession.url,
            }),
            {
              headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            }
          )
        }
      } catch (sessionError) {
        console.error('Error retrieving existing session:', sessionError)
        // Continue to create new session if existing one is invalid
      }
    }

    // Create a record to track this checkout session using stored procedure
    // Note: payment_intent may be null in test mode, use session ID as fallback
    const paymentIntentId = checkoutSession.payment_intent as string || checkoutSession.id
    
    const { error: insertError } = await supabaseClient.rpc('create_batch_checkout_payment', {
      p_batch_id: batchId,
      p_stripe_payment_intent_id: paymentIntentId,
      p_stripe_checkout_session_id: checkoutSession.id,
      p_amount_cents: totalAmount,
      p_metadata: {
        card_count: cardCount,
        batch_name: batch.batch_name,
        checkout_session: true,
        stripe_mode: 'test',
        ...metadata,
      }
    })

    if (insertError) {
      console.error('Error creating payment record:', insertError)
      return new Response(
        JSON.stringify({ 
          error: 'Failed to create payment record',
          details: insertError.message 
        }),
        {
          status: 500,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      )
    }

    return new Response(
      JSON.stringify({
        sessionId: checkoutSession.id,
        url: checkoutSession.url,
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      }
    )

  } catch (error) {
    console.error('Error creating checkout session:', error)
    
    return new Response(
      JSON.stringify({ 
        error: 'Internal server error',
        details: error.message 
      }),
      {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      }
    )
  }
})