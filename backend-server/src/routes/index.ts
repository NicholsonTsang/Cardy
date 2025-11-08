import { Router } from 'express';
import translationRoutes from './translation.routes.direct';
import paymentRoutes from './payment.routes';
import aiRoutes from './ai.routes';
import webhookRoutes from './webhook.routes';

const router = Router();

// Mount route modules
router.use('/translations', translationRoutes);
router.use('/payments', paymentRoutes);
router.use('/ai', aiRoutes);
router.use('/webhooks', webhookRoutes);

// API info endpoint
router.get('/', (_req, res) => {
  res.json({
    service: 'CardStudio Backend API',
    version: '1.0.0',
    endpoints: {
      relay: {
        health: 'GET /health',
        offer: 'POST /offer',
      },
      api: {
        translations: {
          translateCard: 'POST /api/translations/translate-card',
        },
        payments: {
          createCreditCheckout: 'POST /api/payments/create-credit-checkout',
        },
        ai: {
          chatStream: 'POST /api/ai/chat/stream',
          generateTts: 'POST /api/ai/generate-tts',
          realtimeToken: 'POST /api/ai/realtime-token',
        },
        webhooks: {
          stripeCredit: 'POST /api/webhooks/stripe-credit',
        },
      },
    },
  });
});

export default router;

