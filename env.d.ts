/// <reference types="vite/client" />

interface ImportMetaEnv {
  // Supabase Configuration
  readonly VITE_SUPABASE_URL: string
  readonly VITE_SUPABASE_ANON_KEY: string
  readonly VITE_SUPABASE_USER_FILES_BUCKET: string
  
  // Stripe Configuration (Frontend)
  readonly VITE_STRIPE_PUBLISHABLE_KEY: string
  readonly VITE_STRIPE_SUCCESS_URL: string
  
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
  
  // Backend Configuration
  readonly VITE_BACKEND_URL: string
  
  // AI Configuration
  readonly VITE_DEFAULT_AI_INSTRUCTION: string
  readonly VITE_OPENAI_REALTIME_MODEL: string
  
  // Batch Configuration
  readonly VITE_BATCH_MIN_QUANTITY: string
  
  // Content Pagination & Lazy Loading Configuration
  readonly VITE_CONTENT_PAGE_SIZE: string
  readonly VITE_CONTENT_PREVIEW_LENGTH: string
  readonly VITE_LARGE_CARD_THRESHOLD: string
  readonly VITE_INFINITE_SCROLL_THRESHOLD: string
  
  // Subscription Business Parameters
  readonly VITE_FREE_TIER_PROJECT_LIMIT: string
  readonly VITE_FREE_TIER_MONTHLY_SESSION_LIMIT: string
  readonly VITE_STARTER_PROJECT_LIMIT: string
  readonly VITE_STARTER_MONTHLY_FEE_USD: string
  readonly VITE_STARTER_MONTHLY_BUDGET_USD: string
  readonly VITE_STARTER_AI_ENABLED_SESSION_COST_USD: string
  readonly VITE_STARTER_AI_DISABLED_SESSION_COST_USD: string
  readonly VITE_PREMIUM_PROJECT_LIMIT: string
  readonly VITE_PREMIUM_MONTHLY_FEE_USD: string
  readonly VITE_PREMIUM_MONTHLY_BUDGET_USD: string
  readonly VITE_PREMIUM_AI_ENABLED_SESSION_COST_USD: string
  readonly VITE_PREMIUM_AI_DISABLED_SESSION_COST_USD: string
  readonly VITE_ENTERPRISE_PROJECT_LIMIT: string
  readonly VITE_ENTERPRISE_MONTHLY_FEE_USD: string
  readonly VITE_ENTERPRISE_MONTHLY_BUDGET_USD: string
  readonly VITE_ENTERPRISE_AI_ENABLED_SESSION_COST_USD: string
  readonly VITE_ENTERPRISE_AI_DISABLED_SESSION_COST_USD: string

  // Overage Batch Pricing (Paid users)
  readonly VITE_OVERAGE_CREDITS_PER_BATCH: string
}

interface ImportMeta {
  readonly env: ImportMetaEnv
}
