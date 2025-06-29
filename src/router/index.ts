import { createRouter, createWebHistory } from 'vue-router'
import DashboardLayout from '../layouts/Dashboard.vue'
// AdminLayout is now merged into DashboardLayout
// import AdminLayout from '../layouts/AdminDashboard.vue' 
import { useAuthStore } from '@/stores/auth'
import { useToast } from 'primevue/usetoast';

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    {
      path: '/cms',
      component: DashboardLayout,
      meta: { requiresAuth: true },
      children: [
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
          component: () => import('@/views/Dashboard/Admin/AdminHistoryLogs.vue'),
          meta: { requiredRole: 'admin' }
        },
      ]
    },
    {
      path: '/login',
      name: 'login',
      component: () => import('@/views/Dashboard/SignIn.vue')
    },
    {
      path: '/signup',
      name: 'signup',
      component: () => import('@/views/Dashboard/SignUp.vue')
    },
    {
      path: '/issuedcard/:issue_card_id/:activation_code',
      name: 'publiccardview',
      component: () => import('@/views/MobileClient/PublicCardView.vue')
    },
    {
      path: '/',
      name: 'landing',
      component: () => import('@/views/Public/LandingPage.vue')
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

const getUserRole = (authStore) => {
  return authStore.session?.user?.user_metadata?.role;
};

const hasRequiredRole = (userRole, requiredRole) => {
  if (!requiredRole) return true; // No role required
  return userRole === requiredRole;
};

const getDefaultRouteForRole = (userRole) => {
  if (userRole === 'admin') {
    return { name: 'admindashboard' };
  }
  if (userRole === 'cardIssuer') {
    return { name: 'mycards' };
  }
  return { name: 'login' }; // Fallback
};

router.beforeEach(async (to, from, next) => {
  const authStore = useAuthStore();
  const toast = useToast(); 

  // Initialize auth store only once
  if (!authStore.session && authStore.loading) {
    await authStore.initialize();
  }

  const isLoggedIn = !!authStore.session?.user;
  const userRole = getUserRole(authStore);
  const requiredRole = to.meta.requiredRole;

  if (to.matched.some(record => record.meta.requiresAuth)) {
    if (!isLoggedIn) {
      toast.add({
        severity: 'info',
        summary: 'Authentication Required',
        detail: 'Please log in to access this page.',
        group: 'br',
        life: 3000
      });
      next({ name: 'login' });
    } else {
      if (hasRequiredRole(userRole, requiredRole)) {
        // User has the required role, proceed
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
    // For public routes
    if (isLoggedIn && (to.name === 'login' || to.name === 'signup')) {
      // If logged in, redirect from login/signup to their dashboard
      toast.add({
        severity: 'info',
        summary: 'Already Logged In',
        detail: 'You are already logged in. Redirecting to your dashboard.',
        group: 'br',
        life: 3000
      });
      next(getDefaultRouteForRole(userRole));
    } else {
      // Allow navigation to public routes (landing, login, signup, public card view)
      next();
    }
  }
});

export default router;
