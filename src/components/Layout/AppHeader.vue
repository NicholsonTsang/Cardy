<template>
  <header class="app-header border-b border-slate-200 bg-white shadow-sm">
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
      <div class="flex justify-between items-center h-16">
        <!-- Left Side: Logo and Brand -->
        <div class="flex items-center">
          <router-link to="/" class="flex items-center gap-3 hover:opacity-80 transition-opacity">
            <div class="w-8 h-8 bg-blue-600 rounded-lg flex items-center justify-center">
              <i class="pi pi-id-card text-white text-lg"></i>
            </div>
            <div class="hidden sm:block">
              <h1 class="text-xl font-bold text-slate-900">CardStudio</h1>
              <p class="text-xs text-slate-500 -mt-1">Digital Souvenir Platform</p>
            </div>
          </router-link>
        </div>

        <!-- Center: Clean space for better layout -->
        <div class="flex-1"></div>

        <!-- Right Side: Main Navigation Menu -->
        <div class="flex items-center space-x-4">
          <!-- Single Unified Menu for Authenticated Users -->
          <div v-if="isAuthenticated" class="relative">
            <Menu 
              ref="mainMenu"
              :model="unifiedMenuItems"
              :popup="true"
              class="main-navigation-menu"
            />
            <Button 
              @click="toggleMainMenu"
              class="main-menu-button"
              text
              aria-label="Main Menu"
            >
              <div class="flex items-center gap-3">
                <div class="w-10 h-10 bg-gradient-to-r from-blue-600 to-indigo-600 rounded-full flex items-center justify-center text-white text-sm font-medium shadow-md">
                  {{ userInitials }}
                </div>
                <div class="hidden sm:block text-left">
                  <div class="text-sm font-medium text-slate-900">{{ userDisplayName }}</div>
                  <div class="text-xs text-slate-500 flex items-center gap-1">
                    <div 
                      class="w-2 h-2 rounded-full"
                      :class="userRole === 'admin' ? 'bg-red-500' : 'bg-blue-500'"
                    ></div>
                    {{ userRole === 'admin' ? 'Admin' : 'Card Issuer' }}
                  </div>
                </div>
                <i class="pi pi-chevron-down text-slate-400 transition-transform duration-200"></i>
              </div>
            </Button>
          </div>

          <!-- Authentication Buttons (for non-authenticated users) -->
          <div v-else class="flex items-center gap-2 sm:gap-4">
            <!-- Sign In - Subtle text link -->
            <router-link 
              to="/login" 
              class="hidden sm:inline-flex items-center px-4 py-2 text-sm font-medium text-slate-600 hover:text-slate-900 transition-colors duration-200"
            >
              Sign in
            </router-link>
            
            <!-- Get Started - Primary CTA -->
            <router-link 
              to="/signup" 
              class="inline-flex items-center gap-2 px-5 py-2.5 bg-gradient-to-r from-blue-600 to-indigo-600 text-white text-sm font-semibold rounded-lg hover:from-blue-700 hover:to-indigo-700 transition-all duration-200 shadow-sm hover:shadow-md group"
            >
              <span>Get started</span>
              <i class="pi pi-arrow-right text-xs group-hover:translate-x-0.5 transition-transform duration-200"></i>
            </router-link>
          </div>
        </div>
      </div>
    </div>
  </header>
</template>

<script setup>
import { ref, computed, watch } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import Button from 'primevue/button'
import Menu from 'primevue/menu'
import { useToast } from 'primevue/usetoast'

const router = useRouter()
const authStore = useAuthStore()
const toast = useToast()

// Refs for popup menus
const mainMenu = ref()

// Computed properties
const isAuthenticated = computed(() => {
  const result = authStore.isLoggedIn()
  console.log('AppHeader isAuthenticated:', result)
  return result
})

const userRole = ref(null)

// Function to get user role from session with fallback
const getUserRoleFromSession = () => {
  // Check if user is authenticated first
  if (!authStore.isLoggedIn()) {
    userRole.value = null
    return
  }
  
  let role = authStore.session?.user?.app_metadata?.role || authStore.session?.user?.user_metadata?.role || authStore.session?.user?.raw_user_meta_data?.role
  console.log('AppHeader userRole from session:', role)
  console.log('AppHeader raw_user_meta_data:', authStore.session?.user?.raw_user_meta_data)
  
  // REMOVED: Hard-coded admin email override that was causing incorrect role assignment
  // Now properly uses database role from raw_user_meta_data
  
  // Handle both cardIssuer and card_issuer formats for backward compatibility
  if (role === 'card_issuer') role = 'cardIssuer'
  
  // If no role is found and user is logged in, assume cardIssuer (default role)
  if (!role && authStore.session?.user) {
    console.warn('AppHeader: No role found for logged in user, defaulting to cardIssuer');
    role = 'cardIssuer';
  }
  
  console.log('AppHeader final userRole:', role)
  userRole.value = role
}

// Watch for authentication changes and update role
watch(isAuthenticated, (newVal) => {
  if (newVal) {
    getUserRoleFromSession()
  } else {
    userRole.value = null
  }
}, { immediate: true })
const userEmail = computed(() => {
  if (!authStore.isLoggedIn()) {
    return ''
  }
  return authStore.session?.user?.email || ''
})

const userDisplayName = computed(() => {
  // For now, just use the email username part since userProfile doesn't exist in auth store
  if (!authStore.isLoggedIn()) {
    return 'User'
  }
  return userEmail.value.split('@')[0] || 'User'
})

const userInitials = computed(() => {
  const name = userDisplayName.value
  return name.split(' ').map(word => word[0]).join('').toUpperCase().slice(0, 2)
})

// Menu items for different user roles
const cardIssuerMenuItems = [
  {
    label: 'My Cards',
    icon: 'pi pi-folder',
    command: () => router.push('/cms/mycards')
  }
]

const adminMenuItems = [
  {
    label: 'Dashboard',
    icon: 'pi pi-chart-line',
    command: () => router.push('/cms/admin')
  },
  {
    label: 'Users',
    icon: 'pi pi-users',
    command: () => router.push('/cms/users')
  },
  {
    label: 'Batches',
    icon: 'pi pi-box',
    command: () => router.push('/cms/batches')
  },
  {
    label: 'Print Requests',
    icon: 'pi pi-print',
    command: () => router.push('/cms/print-requests')
  },
  {
    label: 'User Cards',
    icon: 'pi pi-id-card',
    command: () => router.push('/cms/admin/user-cards')
  },
  {
    label: 'Issue Free Batch',
    icon: 'pi pi-gift',
    command: () => router.push('/cms/admin/issue-batch')
  },
  {
    label: 'History Logs',
    icon: 'pi pi-history',
    command: () => router.push('/cms/admin/history')
  }
]

// Unified menu items that combine navigation with user actions
const unifiedMenuItems = computed(() => {
  // Don't show menu if user is not authenticated
  if (!authStore.isLoggedIn() || !userRole.value) {
    console.log('AppHeader: No menu items - not authenticated or no role')
    return []
  }
  
  const navItems = userRole.value === 'cardIssuer' ? cardIssuerMenuItems : adminMenuItems
  console.log('AppHeader: Menu items for role:', userRole.value, navItems)
  
  return [
    // User Info Section
    {
      label: userEmail.value,
      icon: 'pi pi-envelope',
      disabled: true,
      class: 'user-email-header'
    },
    { separator: true },
    
    // Navigation Section
    {
      label: userRole.value === 'admin' ? 'Admin Panel' : 'Card Management',
      disabled: true,
      class: 'section-header'
    },
    ...navItems,
    
    { separator: true },
    
    // User Actions Section
    {
      label: 'Sign Out',
      icon: 'pi pi-sign-out',
      command: handleLogout
    }
  ]
})

// Menu toggle functions
const toggleMainMenu = (event) => {
  mainMenu.value.toggle(event)
}

// Logout handler
const handleLogout = async () => {
  try {
    await authStore.signOut()
    // Close the menu immediately
    if (mainMenu.value) {
      mainMenu.value.hide()
    }
    // Silent redirect - the landing page shows user is signed out
    router.push('/')
  } catch (error) {
    // Only show error toast for failures
    toast.add({
      severity: 'error',
      summary: 'Sign Out Failed',
      detail: 'Could not sign out. Please try again.',
      life: 5000
    })
  }
}
</script>

<style scoped>
.app-header {
  position: sticky;
  top: 0;
  z-index: 50;
  backdrop-filter: blur(8px);
  background-color: rgba(255, 255, 255, 0.95);
}

.main-menu-button {
  @apply hover:bg-slate-100 rounded-lg p-3 transition-all duration-200 border border-transparent hover:border-slate-200 hover:shadow-sm;
}

.main-menu-button:hover .pi-chevron-down {
  @apply transform rotate-180;
}

/* Custom menu styles */
:deep(.main-navigation-menu .p-menu) {
  @apply mt-2 shadow-lg border border-slate-200 rounded-lg;
  min-width: 280px;
  max-width: 320px;
}

:deep(.user-info-header) {
  @apply font-semibold text-slate-900 text-base;
}

:deep(.user-email-header) {
  @apply text-slate-600 text-sm;
}

:deep(.section-header) {
  @apply font-semibold text-slate-700 text-xs uppercase tracking-wide bg-slate-50 px-4 py-3 cursor-default;
}

:deep(.section-header .p-menuitem-link) {
  @apply cursor-default;
}

:deep(.user-info-header .p-menuitem-link) {
  @apply cursor-default px-4 py-3;
}

:deep(.user-email-header .p-menuitem-link) {
  @apply cursor-default px-4 py-2;
}

:deep(.p-menuitem-text) {
  @apply text-sm font-medium;
}

:deep(.p-menuitem-icon) {
  @apply text-slate-500 mr-3;
}

:deep(.p-menuitem-link) {
  @apply px-4 py-3 hover:bg-slate-50 transition-colors duration-200 flex items-center;
}

:deep(.p-menuitem-link:focus) {
  @apply bg-blue-50 outline-none;
}

:deep(.p-menuitem-link:hover) {
  @apply bg-slate-50;
}

:deep(.p-separator) {
  @apply border-slate-200 my-2;
}

:deep(.main-navigation-menu .p-menu .p-menuitem:first-child .p-menuitem-link) {
  @apply rounded-t-lg;
}

:deep(.main-navigation-menu .p-menu .p-menuitem:last-child .p-menuitem-link) {
  @apply rounded-b-lg;
}
</style>