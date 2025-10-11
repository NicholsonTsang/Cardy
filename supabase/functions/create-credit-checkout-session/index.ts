import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import Stripe from 'https://esm.sh/stripe@14.5.0?target=deno'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.1'
import { corsHeaders } from '../_shared/cors.ts'

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Log authorization header for debugging
    const authHeader = req.headers.get('Authorization')
    console.log('Authorization header present:', !!authHeader)
    console.log('Authorization header value:', authHeader ? authHeader.substring(0, 20) + '...' : 'null')

    if (!authHeader) {
      console.error('No Authorization header found')
      return new Response(
        JSON.stringify({ error: 'No authorization header provided' }),
        {
          status: 401,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      )
    }

    // Initialize Supabase client with service role for admin operations
    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? Deno.env.get('SUPABASE_ANON_KEY') ?? '',
    )

    // Verify the JWT token and get user
    const token = authHeader.replace('Bearer ', '')
    const { data: { user }, error: userError } = await supabaseAdmin.auth.getUser(token)

    if (userError) {
      console.error('Error verifying JWT token:', userError)
      return new Response(
        JSON.stringify({ error: 'Invalid or expired token', details: userError.message }),
        {
          status: 401,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      )
    }

    if (!user) {
      console.error('No user found in JWT token')
      return new Response(
        JSON.stringify({ error: 'Unauthorized - invalid token' }),
        {
          status: 401,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      )
    }
    
    console.log(`Creating credit checkout for user: ${user.id}`)

    const stripeKey = Deno.env.get('STRIPE_SECRET_KEY')
    if (!stripeKey) {
      throw new Error('Stripe secret key not configured')
    }

    const stripe = new Stripe(stripeKey, {
      apiVersion: '2023-10-16',
      httpClient: Stripe.createFetchHttpClient()
    })

    const { creditAmount, amountUsd, baseUrl, metadata = {} } = await req.json()

    // Validate inputs
    if (!creditAmount || creditAmount <= 0) {
      throw new Error('Invalid credit amount')
    }

    // Convert to cents for Stripe
    const amountCents = Math.round(amountUsd * 100)

    // Create Stripe Checkout session for credit purchase
    const session = await stripe.checkout.sessions.create({
      payment_method_types: ['card'],
      line_items: [
        {
          price_data: {
            currency: 'usd',
            product_data: {
              name: 'CardStudio Credits',
              description: `Purchase ${creditAmount} credits for card issuance`,
              metadata: {
                type: 'credit_purchase'
              }
            },
            unit_amount: amountCents
          },
          quantity: 1
        }
      ],
      mode: 'payment',
      success_url: `${baseUrl}?success=true&session_id={CHECKOUT_SESSION_ID}&type=credit`,
      cancel_url: `${baseUrl}?canceled=true&type=credit`,
      metadata: {
        ...metadata,
        type: 'credit_purchase',
        credit_amount: creditAmount.toString(),
        amount_usd: amountUsd.toString(),
        user_id: user.id
      }
    })

    // Create pending credit purchase record in database
    // Pass the user_id explicitly since we're using service role
    const { data: purchaseRecord, error: dbError } = await supabaseAdmin
      .rpc('create_credit_purchase_record', {
        p_stripe_session_id: session.id,
        p_amount_usd: amountUsd,
        p_credits_amount: creditAmount,
        p_metadata: metadata,
        p_user_id: user.id
      })

    if (dbError) {
      console.error('Error creating credit purchase record:', dbError)
      throw new Error(`Failed to create purchase record: ${dbError.message}`)
    }

    console.log(`Created pending credit purchase: ${creditAmount} credits for user ${user.id}, session ${session.id}`)

    return new Response(
      JSON.stringify({
        sessionId: session.id,
        url: session.url,
        purchaseId: purchaseRecord
      }),
      {
        headers: {
          ...corsHeaders,
          'Content-Type': 'application/json'
        }
      }
    )
  } catch (error) {
    console.error('Error creating credit checkout session:', error)
    return new Response(
      JSON.stringify({
        error: error.message || 'Failed to create checkout session'
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
