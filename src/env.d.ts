/// <reference types="vite/client" />

declare module '*.vue' {
  import type { DefineComponent } from 'vue'
  const component: DefineComponent<{}, {}, any>
  export default component
}

declare module '@/utils/http' {
  export function sendOpenAIRealtimeRequest(
    model: string,
    sdpOffer: string,
    ephemeralToken: string,
    instructions?: string
  ): Promise<any>
}

declare module '@/utils/http.js' {
  export function sendOpenAIRealtimeRequest(
    model: string,
    sdpOffer: string,
    ephemeralToken: string,
    instructions?: string
  ): Promise<any>
}

interface ImportMetaEnv {
  // Supabase Configuration
  readonly VITE_SUPABASE_URL: string
  readonly VITE_SUPABASE_ANON_KEY: string
  readonly VITE_SUPABASE_USER_FILES_BUCKET: string
  
  // Stripe Configuration (Frontend)
  readonly VITE_STRIPE_PUBLISHABLE_KEY: string
  readonly VITE_STRIPE_SUCCESS_URL: string
  
  // Landing Page Demo - Physical Card Mode
  readonly VITE_DEFAULT_CARD_IMAGE_URL: string
  readonly VITE_SAMPLE_QR_URL: string
  readonly VITE_DEMO_CARD_TITLE: string
  readonly VITE_DEMO_CARD_SUBTITLE: string
  
  // Landing Page Demo - Digital Access Mode
  readonly VITE_DIGITAL_ACCESS_DEMO_URL: string
  readonly VITE_DIGITAL_ACCESS_DEMO_TITLE: string
  readonly VITE_DIGITAL_ACCESS_DEMO_SUBTITLE: string
  
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

  // App Configuration
  readonly VITE_APP_URL: string

  // Digital Access Configuration
  readonly VITE_DIGITAL_ACCESS_DEFAULT_DAILY_LIMIT: string

  // Feature Flags
  readonly VITE_ENABLE_PHYSICAL_CARDS?: string
}

interface ImportMeta {
  readonly env: ImportMetaEnv
}

// Extend HTMLAudioElement to include playsInline property
declare global {
  interface HTMLAudioElement {
    playsInline?: boolean
  }
}
