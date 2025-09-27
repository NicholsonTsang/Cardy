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
    const { sessionId } = await req.json()

    if (!sessionId) {
      return new Response(
        JSON.stringify({ error: 'Session ID is required' }),
        {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      )
    }

    // Retrieve the checkout session from Stripe
    const session = await stripe.checkout.sessions.retrieve(sessionId, {
      expand: ['payment_intent'],
    })

    if (!session) {
      return new Response(
        JSON.stringify({ error: 'Session not found' }),
        {
          status: 404,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      )
    }

    // Verify the session belongs to this user
    const batchId = session.metadata?.batch_id
    const sessionUserId = session.metadata?.user_id
    const isPendingBatch = session.metadata?.is_pending_batch === 'true'

    if (sessionUserId !== user.id) {
      return new Response(
        JSON.stringify({ error: 'Unauthorized session access' }),
        {
          status: 403,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      )
    }

    // For pending batches, we don't expect a real batch_id yet
    if (!isPendingBatch && !batchId) {
      return new Response(
        JSON.stringify({ error: 'Invalid session metadata' }),
        {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      )
    }

    // Check if payment was successful
    if (session.payment_status !== 'paid') {
      return new Response(
        JSON.stringify({ 
          error: 'Payment not completed',
          status: session.payment_status 
        }),
        {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      )
    }

    let confirmedBatchId = batchId

    if (isPendingBatch) {
      // Payment-first flow: confirm pending payment and create batch
      console.log('Confirming pending batch payment:', {
        sessionId,
        cardId: session.metadata?.card_id,
        cardCount: session.metadata?.card_count,
        batchName: session.metadata?.batch_name
      })
      
      const { data: newBatchId, error: confirmError } = await supabaseClient.rpc(
        'confirm_pending_batch_payment',
        {
          p_stripe_checkout_session_id: sessionId,
          p_payment_method: 'card'
        }
      )

      if (confirmError) {
        console.error('Error confirming pending batch payment:', confirmError)
        return new Response(
          JSON.stringify({ 
            error: 'Failed to confirm pending batch payment',
            details: confirmError.message 
          }),
          {
            status: 500,
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          }
        )
      }

      confirmedBatchId = newBatchId
      console.log('Pending batch payment confirmed, batch created:', newBatchId)
    } else {
      // Existing batch: confirm payment for existing batch
      const { data: batchIdResult, error: confirmError } = await supabaseClient.rpc(
        'confirm_batch_payment_by_session',
        {
          p_stripe_checkout_session_id: sessionId,
          p_payment_method: 'card'
        }
      )

      if (confirmError) {
        console.error('Error confirming payment:', confirmError)
        return new Response(
          JSON.stringify({ 
            error: 'Failed to confirm payment',
            details: confirmError.message 
          }),
          {
            status: 500,
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          }
        )
      }

      confirmedBatchId = batchIdResult || batchId
    }

    return new Response(
      JSON.stringify({
        success: true,
        sessionId: sessionId,
        batchId: confirmedBatchId || batchId,
        cardCount: parseInt(session.metadata?.card_count || '0'),
        paymentStatus: session.payment_status,
        paymentIntentId: typeof session.payment_intent === 'string' 
          ? session.payment_intent 
          : session.payment_intent?.id,
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      }
    )

  } catch (error) {
    console.error('Error handling checkout success:', error)
    
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