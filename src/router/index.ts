import { createRouter, createWebHistory } from 'vue-router'
import AppLayout from '../layouts/AppLayout.vue'
import { useAuthStore } from '@/stores/auth'
import { useToast } from 'primevue/usetoast';

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    {
      path: '/cms',
      component: AppLayout,
      meta: { requiresAuth: true },
      children: [
        // Default redirect - will be handled by navigation guard
        {
          path: '',
          redirect: { name: 'projects' }
        },
        // Project Creator Routes (accessible by both cardIssuer and admin)
        {
          path: 'projects',
          name: 'projects',
          component: () => import('@/views/Dashboard/CardIssuer/MyCards.vue'),
          meta: { requiredRoles: ['cardIssuer', 'admin'] }
        },
        // Backward compatibility redirect
        {
          path: 'mycards',
          redirect: { name: 'projects' }
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
        // Backward compatibility redirect
        {
          path: 'plan',
          redirect: { name: 'subscription' }
        },
        
        // Admin Routes (now using the same DashboardLayout)
        // Redirect old print-requests route to batches page
        {
          path: 'admin/print-requests',
          redirect: { name: 'admin-batches' }
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
          meta: { requiredRole: 'admin' }
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
        // Backward compatibility redirect
        {
          path: 'admin/user-cards',
          redirect: { name: 'admin-user-projects' }
        },
        {
          path: 'admin/templates',
          name: 'admin-templates',
          component: () => import('@/views/Dashboard/Admin/TemplateManagement.vue'),
          meta: { requiredRole: 'admin' }
        },
        // Redirect old issue-batch route to batches page
        {
          path: 'admin/issue-batch',
          redirect: { name: 'admin-batches' }
        },
      ]
    },
    {
      path: '/login',
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
      path: '/signup',
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
      path: '/reset-password',
      component: AppLayout,
      children: [
        {
          path: '',
          name: 'reset-password',
          component: () => import('@/views/Dashboard/ResetPassword.vue')
        }
      ]
    },
    {
      path: '/c/:issue_card_id',
      name: 'publiccardview',
      component: () => import('@/views/MobileClient/PublicCardView.vue')
    },
    {
      path: '/preview/:card_id',
      name: 'cardpreview',
      component: () => import('@/views/MobileClient/PublicCardView.vue'),
      meta: { requiresAuth: true, isPreviewMode: true }
    },
    {
      path: '/',
      name: 'landing',
      component: () => import('@/views/Public/LandingPage.vue')
    },
    {
      path: '/docs',
      name: 'documentation',
      component: () => import('@/views/Public/Documentation.vue')
    },
    // Catch-all for any other routes
    {
      path: '/:pathMatch(.*)*',
      redirect: '/'
    }
  ],
  scrollBehavior(to, from, savedPosition) {
    if (savedPosition) {
      return savedPosition
    } else {
      return { top: 0 }
    }
  }
})

// =================================================================
// NAVIGATION GUARD
// =================================================================

const getUserRole = (authStore: any): string | undefined => {
  // Check both app_metadata and user_metadata for role
  // user_metadata comes from raw_user_meta_data in the database  
  const user = authStore.session?.user;
  
  let role = user?.app_metadata?.role || user?.user_metadata?.role || user?.raw_user_meta_data?.role;
  
  // Handle both cardIssuer and card_issuer formats for backward compatibility
  if (role === 'card_issuer') return 'cardIssuer';
  
  // If no role is found and user is logged in, assume cardIssuer (default role)
  if (!role && user) {
    console.warn('No role found for logged in user, defaulting to cardIssuer');
    return 'cardIssuer';
  }
  
  return role;
};

const hasRequiredRole = (userRole: string | undefined, requiredRole: string | string[] | undefined): boolean => {
  if (!requiredRole) return true; // No role required
  if (Array.isArray(requiredRole)) {
    // Support multiple allowed roles
    return requiredRole.includes(userRole || '');
  }
  return userRole === requiredRole;
};

const getDefaultRouteForRole = (userRole: string | undefined): { name: string } => {
  if (userRole === 'admin') {
    return { name: 'admin-dashboard' };
  }
  if (userRole === 'cardIssuer') {
    return { name: 'projects' };
  }
  // If no role is found, default to projects (most users are cardIssuer)
  return { name: 'projects' };
};

// Track if auth has been initialized to avoid redundant checks
let authInitialized = false;

router.beforeEach(async (to, from, next) => {
  const authStore = useAuthStore();
  const toast = useToast(); 

  // Early return for public routes that don't need any auth checks
  // This skips all auth logic for landing page and public card views
  const requiresAuth = to.matched.some(record => record.meta.requiresAuth);
  const isAuthRoute = to.name === 'login' || to.name === 'signup';
  
  if (!requiresAuth && !isAuthRoute) {
    // Public routes like landing page and public card views - no auth needed
    return next();
  }

  // Initialize auth store only once on first navigation (for protected routes)
  if (!authInitialized && authStore.loading) {
    await authStore.initialize();
    authInitialized = true;
  }

  const isLoggedIn = !!authStore.session?.user;
  const userRole = getUserRole(authStore);
  // Support both single role (requiredRole) and multiple roles (requiredRoles)
  const requiredRole = (to.meta.requiredRoles || to.meta.requiredRole) as string | string[] | undefined;

  // Check if route requires authentication
  if (requiresAuth) {
    if (!isLoggedIn) {
      // User is not logged in, redirect to login
      if (to.name !== 'login') {
        toast.add({
          severity: 'info',
          summary: 'Authentication Required',
          detail: 'Please log in to access this page.',
          group: 'br',
          life: 3000
        });
        next({ name: 'login' });
      } else {
        next();
      }
    } else {
      // User is logged in, check role requirements
      if (hasRequiredRole(userRole, requiredRole)) {
        next();
      } else {
        // User does not have the required role, redirect to their default page
        toast.add({
          severity: 'error',
          summary: 'Access Denied',
          detail: `You don't have permission to access this section. Required role: ${requiredRole}`,
          group: 'br',
          life: 5000
        });
        next(getDefaultRouteForRole(userRole));
      }
    }
  } else {
    // For public routes (no auth required)
    if (isLoggedIn && (to.name === 'login' || to.name === 'signup')) {
      // If logged in, redirect from login/signup to their dashboard
      // But only if we have a valid role to prevent infinite redirects
      if (userRole) {
        // Silently redirect already logged-in users to their dashboard
        next(getDefaultRouteForRole(userRole));
      } else {
        // If no role found, allow access to login page to prevent infinite redirect
        next();
      }
    } else {
      // Allow navigation to public routes (landing, login, signup, public card view)
      next();
    }
  }
});

export default router;
