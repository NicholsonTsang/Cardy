import { createRouter, createWebHistory } from 'vue-router'
import DashboardLayout from '../layouts/Dashboard.vue'
import { useAuthStore } from '@/stores/auth'
import { useToast } from 'primevue/usetoast'; // Import useToast

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    {
      path: '/cms', // Base path for the CMS section
      component: DashboardLayout,
      meta: { requiresAuth: true }, // Add meta field to identify protected routes
      children: [
        {
          path: 'mycards',
          name: 'mycards',
          component: () => import('../views/MyCards.vue')
        },
        {
          path: 'issuedcards',
          name: 'issuedcards',
          component: () => import('../views/IssuedCards.vue')
        },
        {
          path: 'profile',
          name: 'profile',
          component: () => import('../views/Profile.vue')
        },
        {
          path: 'carddetails',
          name: 'carddetails',
          component: () => import('../views/CardDetails.vue')
        }
      ],
    },
    {
      path: '/login',
      name: 'login',
      component: () => import('../views/SignIn.vue')
    },
    {
      path: '/signup',
      name: 'signup',
      component: () => import('../views/SignUp.vue')
    }
    // You can add other top-level routes here (e.g., for login page)
    // {
    //   path: '/login',
    //   name: 'login',
    //   component: () => import('../views/Login.vue') // Example
    // }
  ],
})

router.beforeEach(async (to, from, next) => {
  const authStore = useAuthStore();
  const toast = useToast(); // Initialize useToast for the guard

  // Check if the route requires authentication
  const requiresAuth = to.matched.some(record => record.meta.requiresAuth);

  if (requiresAuth) {
    // Initialize and wait for auth state to be loaded if not already,
    // especially on initial load or page refresh.
    if (authStore.loading && !authStore.session) {
        await authStore.initialize();
    }

    if (authStore.isLoggedIn() && authStore.isEmailVerified()) {
      next(); // User is logged in and email verified, proceed
    } else if (authStore.isLoggedIn() && !authStore.isEmailVerified()) {
      // User is logged in but email is not verified
      toast.add({
        severity: 'warn',
        summary: 'Email Verification Required',
        detail: 'Please verify your email to access this section. Check your inbox for the verification link.',
        group: 'br', // Or 'tc' for top-center
        life: 7000
      });
      if (to.name !== 'login') { // Avoid redirect loop if already on login
        next({ name: 'login' });
      } else {
        next(false); // Stay on the current page (login), allowing toast to be seen
      }
    } else {
      // User not logged in
      if (to.name !== 'login') { // Avoid redirect loop
        toast.add({
          severity: 'info',
          summary: 'Authentication Required',
          detail: 'Please log in to access this page.',
          group: 'br',
          life: 3000
        });
        next({ name: 'login' });
      } else {
        next(); // Allow navigation to login page itself
      }
    }
  } else {
    // Route does not require authentication
    // If user is logged in and tries to access login/signup, redirect them to cms
    if ((to.name === 'login' || to.name === 'signup') && authStore.isLoggedIn() && authStore.isEmailVerified()) {
        // Initialize auth if not already, to ensure session is fresh
        if (authStore.loading && !authStore.session) {
            await authStore.initialize();
        }
        // Re-check after potential initialization
        if (authStore.isLoggedIn() && authStore.isEmailVerified()) {
            next({ path: '/cms/mycards' });
            return;
        }
    }
    next(); // Proceed to the route
  }
});

export default router
