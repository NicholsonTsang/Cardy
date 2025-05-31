import { createRouter, createWebHistory } from 'vue-router'
import DashboardLayout from '../layouts/Dashboard.vue'
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
    },
    {
      path: '/issuedcard/:issue_card_id/:activation_code',
      name: 'publiccardview',
      component: () => import('../views/MobileClient/PublicCardView.vue')
    }
  ],
})

router.beforeEach(async (to, from, next) => {
  const authStore = useAuthStore();
  const toast = useToast(); 

  const requiresAuth = to.matched.some(record => record.meta.requiresAuth);

  if (requiresAuth) {
    if (authStore.loading && !authStore.session) {
        await authStore.initialize();
    }

    if (authStore.isLoggedIn() && authStore.isEmailVerified()) {
      next();
    } else if (authStore.isLoggedIn() && !authStore.isEmailVerified()) {
      toast.add({
        severity: 'warn',
        summary: 'Email Verification Required',
        detail: 'Please verify your email to access this section. Check your inbox for the verification link.',
        group: 'br',
        life: 7000
      });
      if (to.name !== 'login') { 
        next({ name: 'login' });
      } else {
        next(false); 
      }
    } else {
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
    }
  } else {
    if ((to.name === 'login' || to.name === 'signup') && authStore.isLoggedIn() && authStore.isEmailVerified()) {
        if (authStore.loading && !authStore.session) {
            await authStore.initialize();
        }
        if (authStore.isLoggedIn() && authStore.isEmailVerified()) {
            next({ path: '/cms/mycards' });
            return;
        }
    }
    next();
  }
});

export default router
