import { createRouter, createWebHistory, RouterView } from 'vue-router'
import AppLayout from '../layouts/AppLayout.vue'
import { useAuthStore } from '@/stores/auth'
import { useToast } from 'primevue/usetoast'
import { setLocale } from '@/i18n'
import { 
  URL_SUPPORTED_LANGUAGES, 
  DEFAULT_LANGUAGE,
  DASHBOARD_LANGUAGES,
  extractLanguageFromPath, 
  isValidLanguage, 
  getSavedLanguage,
  saveLanguagePreference,
  detectBrowserLanguage
} from './languageRouting'
import type { LanguageCode } from '@/stores/translation'

// ===== LANGUAGE ROUTE PATTERN =====
// Format: /:lang/... where lang is one of URL_SUPPORTED_LANGUAGES
// Examples: /en/cms/projects, /zh-Hant/c/abc123, /ja/login

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    // ===== LANGUAGE-PREFIXED ROUTES =====
    {
      path: '/:lang',
      component: RouterView, // Render children in a router-view
      beforeEnter: (to, from, next) => {
        // Validate language parameter
        const lang = to.params.lang as string
        if (!isValidLanguage(lang)) {
          // Invalid language, redirect to detected language
          const detectedLang = getSavedLanguage()
          const pathWithoutLang = to.path.replace(`/${lang}`, '') || '/'
          next(`/${detectedLang}${pathWithoutLang}`)
        } else {
          next()
        }
      },
      children: [
        // Landing page with language
        {
          path: '',
          name: 'landing-lang',
          component: () => import('@/views/Public/LandingPage.vue')
        },
        
        // Dashboard routes with language prefix
        {
          path: 'cms',
          component: AppLayout,
          meta: { requiresAuth: true },
          children: [
            // Default redirect - dynamically routes based on user role
            {
              path: '',
              name: 'cms-home',
              redirect: (to) => {
                const authStore = useAuthStore()
                const user = authStore.session?.user
                const role = user?.app_metadata?.role || user?.user_metadata?.role
                const lang = to.params.lang || DEFAULT_LANGUAGE
                
                if (role === 'admin') {
                  return { name: 'admin-dashboard', params: { lang } }
                }
                return { name: 'projects', params: { lang } }
              }
            },
            // Project Creator Routes
            {
              path: 'projects',
              name: 'projects',
              component: () => import('@/views/Dashboard/CardIssuer/MyCards.vue'),
              meta: { requiredRoles: ['cardIssuer', 'admin'] }
            },
            {
              path: 'mycards',
              redirect: (to) => ({ name: 'projects', params: { lang: to.params.lang } })
            },
            {
              path: 'credits',
              name: 'credits',
              component: () => import('@/views/Dashboard/CardIssuer/CreditManagement.vue'),
              meta: { requiredRoles: ['cardIssuer', 'admin'] }
            },
            {
              path: 'subscription',
              name: 'subscription',
              component: () => import('@/views/Dashboard/CardIssuer/SubscriptionManagement.vue'),
              meta: { requiredRoles: ['cardIssuer', 'admin'] }
            },
            {
              path: 'plan',
              redirect: (to) => ({ name: 'subscription', params: { lang: to.params.lang } })
            },
            
            // Admin Routes
            {
              path: 'admin/print-requests',
              redirect: (to) => ({ name: 'admin-batches', params: { lang: to.params.lang } })
            },
            {
              path: 'admin/users',
              name: 'admin-users',
              component: () => import('@/views/Dashboard/Admin/UserManagement.vue'),
              meta: { requiredRole: 'admin' }
            },
            {
              path: 'admin/batches',
              name: 'admin-batches',
              component: () => import('@/views/Dashboard/Admin/BatchManagement.vue'),
              meta: { requiredRole: 'admin', requiresPhysicalCards: true }
            },
            {
              path: 'admin/credits',
              name: 'admin-credits',
              component: () => import('@/views/Dashboard/Admin/AdminCreditManagement.vue'),
              meta: { requiredRole: 'admin' }
            },
            {
              path: 'admin',
              name: 'admin-dashboard',
              component: () => import('@/views/Dashboard/Admin/AdminDashboard.vue'),
              meta: { requiredRole: 'admin' }
            },
            {
              path: 'admin/history',
              name: 'admin-history-logs',
              component: () => import('@/views/Dashboard/Admin/HistoryLogs.vue'),
              meta: { requiredRole: 'admin' }
            },
            {
              path: 'admin/user-projects',
              name: 'admin-user-projects',
              component: () => import('@/views/Dashboard/Admin/UserCardsView.vue'),
              meta: { requiredRole: 'admin' }
            },
            {
              path: 'admin/user-cards',
              redirect: (to) => ({ name: 'admin-user-projects', params: { lang: to.params.lang } })
            },
            {
              path: 'admin/templates',
              name: 'admin-templates',
              component: () => import('@/views/Dashboard/Admin/TemplateManagement.vue'),
              meta: { requiredRole: 'admin' }
            },
            {
              path: 'admin/issue-batch',
              redirect: (to) => ({ name: 'admin-batches', params: { lang: to.params.lang } })
            },
          ]
        },
        
        // Auth routes with language prefix
        {
          path: 'login',
          component: AppLayout,
          children: [
            {
              path: '',
              name: 'login',
              component: () => import('@/views/Dashboard/SignIn.vue')
            }
          ]
        },
        {
          path: 'signup',
          component: AppLayout,
          children: [
            {
              path: '',
              name: 'signup',
              component: () => import('@/views/Dashboard/SignUp.vue')
            }
          ]
        },
        {
          path: 'reset-password',
          component: AppLayout,
          children: [
            {
              path: '',
              name: 'reset-password',
              component: () => import('@/views/Dashboard/ResetPassword.vue')
            }
          ]
        },
        
        // Mobile client public card view with language
        {
          path: 'c/:issue_card_id',
          name: 'publiccardview',
          component: () => import('@/views/MobileClient/PublicCardView.vue')
        },
        {
          path: 'c/:issue_card_id/list',
          name: 'publiccardview-list',
          component: () => import('@/views/MobileClient/PublicCardView.vue')
        },
        {
          path: 'c/:issue_card_id/item/:content_item_id',
          name: 'publiccardview-item',
          component: () => import('@/views/MobileClient/PublicCardView.vue')
        },
        
        // Preview mode with language
        {
          path: 'preview/:card_id',
          name: 'cardpreview',
          component: () => import('@/views/MobileClient/PublicCardView.vue'),
          meta: { requiresAuth: true, isPreviewMode: true }
        },
        
        // Documentation with language
        {
          path: 'docs',
          name: 'documentation',
          component: () => import('@/views/Public/Documentation.vue')
        },
      ]
    },
    
    // ===== ROOT ROUTES (redirect to language-prefixed) =====
    {
      path: '/',
      name: 'landing',
      redirect: (to) => {
        // Landing page defaults to English (not browser detection)
        // Only use saved preference if user explicitly chose a language before
        const savedLocale = localStorage.getItem('userLocale')
        const lang = savedLocale && isValidLanguage(savedLocale) ? savedLocale : 'en'
        if (to.hash) {
          return `/${lang}${to.hash}`
        }
        return `/${lang}`
      }
    },
    
    // Legacy routes without language prefix - redirect to language-prefixed versions
    {
      path: '/cms/:pathMatch(.*)*',
      redirect: (to) => {
        const lang = getSavedLanguage(true) // Dashboard only languages
        return `/${lang}/cms${to.path.replace('/cms', '')}`
      }
    },
    {
      path: '/c/:issue_card_id',
      redirect: (to) => {
        const lang = getSavedLanguage()
        return `/${lang}/c/${to.params.issue_card_id}`
      }
    },
    {
      path: '/c/:issue_card_id/list',
      redirect: (to) => {
        const lang = getSavedLanguage()
        return `/${lang}/c/${to.params.issue_card_id}/list`
      }
    },
    {
      path: '/c/:issue_card_id/item/:content_item_id',
      redirect: (to) => {
        const lang = getSavedLanguage()
        return `/${lang}/c/${to.params.issue_card_id}/item/${to.params.content_item_id}`
      }
    },
    {
      path: '/preview/:card_id',
      redirect: (to) => {
        const lang = getSavedLanguage()
        return `/${lang}/preview/${to.params.card_id}`
      }
    },
    {
      path: '/login',
      redirect: () => `/${getSavedLanguage(true)}/login`
    },
    {
      path: '/signup',
      redirect: () => `/${getSavedLanguage(true)}/signup`
    },
    {
      path: '/reset-password',
      redirect: () => `/${getSavedLanguage(true)}/reset-password`
    },
    {
      path: '/docs',
      redirect: () => `/${getSavedLanguage()}/docs`
    },
    
    // Catch-all for any other routes - redirect to landing with detected language
    {
      path: '/:pathMatch(.*)*',
      redirect: () => {
        const lang = getSavedLanguage()
        return `/${lang}`
      }
    }
  ],
  scrollBehavior(to, from, savedPosition) {
    if (savedPosition) {
      return savedPosition
    }
    if (to.hash) {
      return {
        el: to.hash,
        behavior: 'smooth',
      }
    }
    return { top: 0 }
  }
})

// =================================================================
// NAVIGATION GUARD
// =================================================================

const getUserRole = (authStore: any): string | undefined => {
  const user = authStore.session?.user
  let role = user?.app_metadata?.role || user?.user_metadata?.role || user?.raw_user_meta_data?.role
  
  // Handle both cardIssuer and card_issuer formats
  if (role === 'card_issuer') return 'cardIssuer'
  
  // Default to cardIssuer for logged-in users without role
  if (!role && user) {
    console.warn('No role found for logged in user, defaulting to cardIssuer')
    return 'cardIssuer'
  }
  
  return role
}

const hasRequiredRole = (userRole: string | undefined, requiredRole: string | string[] | undefined): boolean => {
  if (!requiredRole) return true
  if (Array.isArray(requiredRole)) {
    return requiredRole.includes(userRole || '')
  }
  return userRole === requiredRole
}

const getDefaultRouteForRole = (userRole: string | undefined, lang: LanguageCode): { name: string; params: { lang: LanguageCode } } => {
  if (userRole === 'admin') {
    return { name: 'admin-dashboard', params: { lang } }
  }
  if (userRole === 'cardIssuer') {
    return { name: 'projects', params: { lang } }
  }
  return { name: 'projects', params: { lang } }
}

// Check if physical cards feature is enabled via environment variable
const isPhysicalCardsEnabled = (): boolean => {
  const envValue = import.meta.env.VITE_ENABLE_PHYSICAL_CARDS
  return envValue !== 'false'
}

// Track auth initialization
let authInitialized = false

router.beforeEach(async (to, from, next) => {
  const authStore = useAuthStore()
  const toast = useToast()

  // ===== LANGUAGE HANDLING =====
  const lang = to.params.lang as LanguageCode | undefined
  
  // If route has valid language param, sync i18n locale
  if (lang && isValidLanguage(lang)) {
    // Check if dashboard route requires dashboard-only languages
    const isDashboardRoute = to.path.includes('/cms')
    if (isDashboardRoute && !DASHBOARD_LANGUAGES.includes(lang)) {
      // Redirect to a supported dashboard language
      const dashboardLang = getSavedLanguage(true)
      const newPath = to.path.replace(`/${lang}/`, `/${dashboardLang}/`)
      return next(newPath)
    }
    
    // Update i18n locale and save preference
    setLocale(lang)
    saveLanguagePreference(lang)
  }

  // ===== AUTH HANDLING =====
  const requiresAuth = to.matched.some(record => record.meta.requiresAuth)
  const isAuthRoute = to.name === 'login' || to.name === 'signup'
  
  // Early return for public routes
  if (!requiresAuth && !isAuthRoute) {
    return next()
  }

  // Initialize auth store once
  if (!authInitialized) {
    if (authStore.loading) {
      await authStore.initialize()
    }
    authInitialized = true
  }

  const isLoggedIn = !!authStore.session?.user
  const userRole = getUserRole(authStore)
  const requiredRole = (to.meta.requiredRoles || to.meta.requiredRole) as string | string[] | undefined
  const currentLang = (lang || DEFAULT_LANGUAGE) as LanguageCode

  // Check authentication
  if (requiresAuth) {
    if (!isLoggedIn) {
      if (to.name !== 'login') {
        toast.add({
          severity: 'info',
          summary: 'Authentication Required',
          detail: 'Please log in to access this page.',
          group: 'br',
          life: 3000
        })
        next({ name: 'login', params: { lang: currentLang } })
      } else {
        next()
      }
    } else {
      // Check role requirements
      if (hasRequiredRole(userRole, requiredRole)) {
        // Check if route requires physical cards feature
        const requiresPhysicalCards = to.matched.some(record => record.meta.requiresPhysicalCards)
        if (requiresPhysicalCards && !isPhysicalCardsEnabled()) {
          toast.add({
            severity: 'info',
            summary: 'Feature Disabled',
            detail: 'Physical cards feature is not enabled.',
            group: 'br',
            life: 3000
          })
          next(getDefaultRouteForRole(userRole, currentLang))
        } else {
          next()
        }
      } else {
        toast.add({
          severity: 'error',
          summary: 'Access Denied',
          detail: `You don't have permission to access this section. Required role: ${requiredRole}`,
          group: 'br',
          life: 5000
        })
        next(getDefaultRouteForRole(userRole, currentLang))
      }
    }
  } else {
    // Public routes - redirect logged-in users from auth pages
    if (isLoggedIn && (to.name === 'login' || to.name === 'signup')) {
      if (userRole) {
        next(getDefaultRouteForRole(userRole, currentLang))
      } else {
        next()
      }
    } else {
      next()
    }
  }
})

export default router
