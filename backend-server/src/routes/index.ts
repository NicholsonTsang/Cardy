import { Router } from 'express';
import translationRoutes from './translation.routes.direct';
import paymentRoutes from './payment.routes';
import aiRoutes from './ai.routes';
import webhookRoutes from './webhook.routes';
import mobileRoutes from './mobile.routes';
import subscriptionRoutes from './subscription.routes';

const router = Router();

// Mount route modules
router.use('/translations', translationRoutes);
router.use('/payments', paymentRoutes);
router.use('/ai', aiRoutes);
router.use('/webhooks', webhookRoutes);
router.use('/mobile', mobileRoutes);
router.use('/subscriptions', subscriptionRoutes);

// API info endpoint
router.get('/', (_req, res) => {
  res.json({
    service: 'FunTell Backend API',
    version: '2.0.0',
    endpoints: {
      relay: {
        health: 'GET /health',
        offer: 'POST /offer',
      },
      api: {
        subscriptions: {
          get: 'GET /api/subscriptions',
          createCheckout: 'POST /api/subscriptions/create-checkout',
          cancel: 'POST /api/subscriptions/cancel',
          reactivate: 'POST /api/subscriptions/reactivate',
          portal: 'GET /api/subscriptions/portal',
          usage: 'GET /api/subscriptions/usage',
          buyCredits: 'POST /api/subscriptions/buy-credits',
        },
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
          generateAiSettings: 'POST /api/ai/generate-ai-settings',
        },
        webhooks: {
          stripe: 'POST /api/webhooks/stripe',
        },
        mobile: {
          digitalCard: 'GET /api/mobile/card/digital/:accessToken',
          physicalCard: 'GET /api/mobile/card/physical/:issueCardId',
          invalidateCache: 'POST /api/mobile/card/:cardId/invalidate-cache',
        },
      },
    },
  });
});

export default router;

