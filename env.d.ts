/// <reference types="vite/client" />

interface ImportMetaEnv {
  readonly VITE_SUPABASE_URL: string
  readonly VITE_SUPABASE_ANON_KEY: string
  readonly VITE_SUPABASE_USER_FILES_BUCKET: string
  readonly VITE_STRIPE_PUBLISHABLE_KEY: string
  readonly VITE_APP_BASE_URL: string
  readonly VITE_CARD_PRICE_CENTS: string
  readonly VITE_DEFAULT_CURRENCY: string
  readonly VITE_CONTACT_EMAIL: string
  readonly VITE_CONTACT_WHATSAPP_URL: string
  readonly VITE_CONTACT_PHONE: string
  readonly VITE_STRIPE_SUCCESS_URL: string
  readonly VITE_STRIPE_CANCEL_URL: string
  readonly VITE_DEFAULT_AI_INSTRUCTION: string
}

interface ImportMeta {
  readonly env: ImportMetaEnv
}
