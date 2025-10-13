/// <reference types="vite/client" />

interface ImportMetaEnv {
  // Supabase Configuration
  readonly VITE_SUPABASE_URL: string
  readonly VITE_SUPABASE_ANON_KEY: string
  readonly VITE_SUPABASE_USER_FILES_BUCKET: string
  
  // Stripe Configuration (Frontend)
  readonly VITE_STRIPE_PUBLISHABLE_KEY: string
  readonly VITE_STRIPE_SUCCESS_URL: string
  readonly VITE_STRIPE_CANCEL_URL: string
  
  // Landing Page Demo Card
  readonly VITE_DEFAULT_CARD_IMAGE_URL: string
  readonly VITE_SAMPLE_QR_URL: string
  readonly VITE_DEMO_CARD_TITLE: string
  readonly VITE_DEMO_CARD_SUBTITLE: string
  
  // Contact Information
  readonly VITE_CONTACT_EMAIL: string
  readonly VITE_CONTACT_WHATSAPP_URL: string
  readonly VITE_CONTACT_PHONE: string
  
  // Currency
  readonly VITE_DEFAULT_CURRENCY: string
  
  // Aspect Ratios
  readonly VITE_CARD_ASPECT_RATIO_WIDTH: string
  readonly VITE_CARD_ASPECT_RATIO_HEIGHT: string
  readonly VITE_CONTENT_ASPECT_RATIO_WIDTH: string
  readonly VITE_CONTENT_ASPECT_RATIO_HEIGHT: string
  
  // AI Configuration
  readonly VITE_DEFAULT_AI_INSTRUCTION: string
  readonly VITE_OPENAI_REALTIME_MODEL: string
}

interface ImportMeta {
  readonly env: ImportMetaEnv
}
