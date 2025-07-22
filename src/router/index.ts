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
        // Default redirect based on user role
        {
          path: '',
          redirect: (to) => {
            // This will be handled by the router guard
            return '/cms/mycards'
          }
        },
        // Card Issuer Routes
        {
          path: 'mycards',
          name: 'mycards',
          component: () => import('@/views/Dashboard/CardIssuer/MyCards.vue'),
          meta: { requiredRole: 'cardIssuer' }
        },
        {
          path: 'issuedcards',
          name: 'issuedcards',
          component: () => import('@/views/Dashboard/CardIssuer/IssuedCards.vue'),
          meta: { requiredRole: 'cardIssuer' }
        },
        {
          path: 'profile',
          name: 'profile',
          component: () => import('@/views/Dashboard/CardIssuer/Profile.vue'),
          meta: { requiredRole: 'cardIssuer' }
        },
        
        // Admin Routes (now using the same DashboardLayout)
        {
          path: 'dashboard',
          name: 'admindashboard',
          component: () => import('@/views/Dashboard/Admin/AdminDashboard.vue'),
          meta: { requiredRole: 'admin' }
        },
        {
          path: 'verifications',
          name: 'adminverifications',
          component: () => import('@/views/Dashboard/Admin/VerificationManagement.vue'),
          meta: { requiredRole: 'admin' }
        },
        {
          path: 'print-requests',
          name: 'adminprintrequests',
          component: () => import('@/views/Dashboard/Admin/PrintRequestManagement.vue'),
          meta: { requiredRole: 'admin' }
        },
        {
          path: 'users',
          name: 'adminusers',
          component: () => import('@/views/Dashboard/Admin/UserManagement.vue'),
          meta: { requiredRole: 'admin' }
        },
        {
          path: 'batches',
          name: 'adminbatches',
          component: () => import('@/views/Dashboard/Admin/BatchManagement.vue'),
          meta: { requiredRole: 'admin' }
        },
        {
          path: 'admin',
          name: 'admin',
          component: () => import('@/views/Dashboard/Admin/AdminDashboard.vue'),
          meta: { requiredRole: 'admin' }
        },
        {
          path: 'admin/history',
          name: 'adminhistorylogs',
          component: () => import('@/views/Dashboard/Admin/HistoryLogs.vue'),
          meta: { requiredRole: 'admin' }
        },
      ]
    },
    {
      path: '/login',
      name: 'login',
      component: AppLayout,
      children: [
        {
          path: '',
          component: () => import('@/views/Dashboard/SignIn.vue')
        }
      ]
    },
    {
      path: '/signup',
      name: 'signup',
      component: AppLayout,
      children: [
        {
          path: '',
          component: () => import('@/views/Dashboard/SignUp.vue')
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
      component: AppLayout,
      children: [
        {
          path: '',
          component: () => import('@/views/Public/LandingPage.vue')
        }
      ]
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
  console.log('getUserRole - user object:', user);
  console.log('getUserRole - app_metadata:', user?.app_metadata);
  console.log('getUserRole - user_metadata:', user?.user_metadata);
  
  let role = user?.app_metadata?.role || user?.user_metadata?.role || user?.raw_user_meta_data?.role;
  console.log('getUserRole - detected role from session:', role);
  console.log('getUserRole - raw_user_meta_data:', user?.raw_user_meta_data);
  
  // REMOVED: Hard-coded admin email override that was causing incorrect role assignment
  // Now properly uses database role from raw_user_meta_data
  
  // Handle both cardIssuer and card_issuer formats for backward compatibility
  if (role === 'card_issuer') return 'cardIssuer';
  
  // If no role is found and user is logged in, assume cardIssuer (default role)
  if (!role && user) {
    console.warn('No role found for logged in user, defaulting to cardIssuer');
    return 'cardIssuer';
  }
  
  return role;
};

const hasRequiredRole = (userRole: string | undefined, requiredRole: string | undefined): boolean => {
  if (!requiredRole) return true; // No role required
  return userRole === requiredRole;
};

const getDefaultRouteForRole = (userRole: string | undefined): { name: string } => {
  console.log('getDefaultRouteForRole - userRole:', userRole);
  if (userRole === 'admin') {
    return { name: 'admindashboard' };
  }
  if (userRole === 'cardIssuer') {
    return { name: 'mycards' };
  }
  // If no role is found, default to mycards (most users are cardIssuer)
  return { name: 'mycards' };
};

router.beforeEach(async (to, from, next) => {
  const authStore = useAuthStore();
  const toast = useToast(); 

  // Initialize auth store only if not already initialized
  if (authStore.loading) {
    await authStore.initialize();
  }

  const isLoggedIn = !!authStore.session?.user;
  const userRole = getUserRole(authStore);
  const requiredRole = to.meta.requiredRole as string | undefined;

  // Debug logging
  console.log('Router guard:', { 
    to: to.name, 
    from: from.name, 
    isLoggedIn, 
    userRole, 
    requiredRole 
  });

  // Check if route requires authentication
  if (to.matched.some(record => record.meta.requiresAuth)) {
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
        console.warn('User is logged in but no role found, allowing access to login page');
        next();
      }
    } else {
      // Allow navigation to public routes (landing, login, signup, public card view)
      next();
    }
  }
});

export default router;
