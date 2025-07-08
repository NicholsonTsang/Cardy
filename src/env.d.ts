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
  readonly VITE_SUPABASE_URL: string
  readonly VITE_SUPABASE_ANON_KEY: string
  readonly VITE_SUPABASE_USER_FILES_BUCKET: string
  readonly VITE_STRIPE_PUBLISHABLE_KEY: string
  readonly VITE_DEFAULT_CARD_IMAGE_URL: string
  readonly VITE_APP_BASE_URL: string
  readonly VITE_SAMPLE_QR_URL: string
  readonly VITE_CARD_PRICE_CENTS: string
  readonly VITE_DEFAULT_CURRENCY: string
  readonly VITE_CONTACT_EMAIL: string
  readonly VITE_CONTACT_WHATSAPP_URL: string
  readonly VITE_CONTACT_PHONE: string
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