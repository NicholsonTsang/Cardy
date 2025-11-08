<template>
  <!-- Dashboard Mode: Clean, simple header -->
  <header 
    v-if="mode === 'dashboard'"
    class="app-header border-b border-slate-200 bg-white shadow-sm"
  >
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
      <div class="flex justify-between items-center h-16">
        <!-- Logo -->
        <div class="flex items-center">
          <router-link to="/" class="flex items-center hover:opacity-80 transition-opacity">
            <img 
              src="@/assets/fullLogo.png" 
              alt="CardStudio Logo" 
              class="h-16 sm:h-24 w-auto"
            />
          </router-link>
        </div>

        <!-- Center: Clean space -->
        <div class="flex-1"></div>

        <!-- Right Side: Dashboard Controls -->
        <div class="flex items-center space-x-4">
          <!-- Credit Balance Display (for Card Issuers) -->
          <div v-if="isAuthenticated && userRole === 'cardIssuer'" class="hidden sm:flex items-center gap-2 px-3 py-1.5 bg-gray-100 rounded-lg">
            <i class="pi pi-wallet text-blue-600"></i>
            <span class="text-sm font-medium text-gray-700">{{ $t('credits.balance') }}:</span>
            <span class="text-sm font-bold text-blue-600">{{ creditBalance }}</span>
          </div>
          
          <!-- Language Selector -->
          <DashboardLanguageSelector />
          
          <!-- User Dropdown Menu -->
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
                    {{ userRole === 'admin' ? $t('common.admin') : $t('common.card_issuer') }}
                  </div>
                </div>
                <i class="pi pi-chevron-down text-slate-400 transition-transform duration-200"></i>
              </div>
            </Button>
          </div>
        </div>
      </div>
    </div>
  </header>
  
  <!-- Landing Mode: Clean header with same design as dashboard -->
  <header 
    v-else
    class="fixed top-0 left-0 right-0 z-50 bg-white border-b border-slate-200 shadow-sm"
  >
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
      <div class="flex items-center h-16">
        <!-- Logo (Left) -->
        <div class="flex items-center">
          <router-link to="/" class="flex items-center hover:opacity-80 transition-opacity">
            <img 
              src="@/assets/fullLogo.png" 
              alt="CardStudio Logo" 
              class="h-16 sm:h-24 w-auto"
            />
          </router-link>
        </div>

        <!-- Spacer to push navigation to center -->
        <div class="flex-1"></div>
        
        <!-- Desktop Navigation - Centered for lg and above -->
        <div class="hidden lg:flex items-center gap-8">
          <a @click="emit('scroll-to', 'about')" class="text-slate-600 hover:text-blue-600 font-medium cursor-pointer transition-colors">
            {{ $t('landing.nav.about') }}
          </a>
          <a @click="emit('scroll-to', 'demo')" class="text-slate-600 hover:text-blue-600 font-medium cursor-pointer transition-colors">
            {{ $t('landing.nav.demo') }}
          </a>
          <a @click="emit('scroll-to', 'pricing')" class="text-slate-600 hover:text-blue-600 font-medium cursor-pointer transition-colors">
            {{ $t('landing.nav.pricing') }}
          </a>
          <a @click="emit('scroll-to', 'contact')" class="text-slate-600 hover:text-blue-600 font-medium cursor-pointer transition-colors">
            {{ $t('landing.nav.contact') }}
          </a>
        </div>

        <!-- Spacer to balance and keep navigation centered -->
        <div class="flex-1"></div>

        <!-- Right Side: Dashboard Controls -->
        <div class="flex items-center space-x-4">
          <!-- Language Selector -->
          <DashboardLanguageSelector />

          <!-- Sign In / Dashboard Button - Desktop Only -->
          <Button 
            :label="isAuthenticated ? $t('dashboard.dashboard') : $t('auth.sign_in')"
            @click="handleAuthButtonClick"
            class="!hidden lg:!inline-flex p-button-outlined"
            :icon="isAuthenticated ? 'pi pi-th-large' : 'pi pi-sign-in'"
          />

          <!-- Mobile Menu Button - Shows ONLY when nav links are hidden (below lg/1024px) -->
          <Button 
            icon="pi pi-bars"
            @click="emit('toggle-mobile-menu')"
            class="p-button-text text-slate-700 hover:text-blue-600 block lg:!hidden"
          />
        </div>
      </div>
    </div>
  </header>
</template>

<script setup>
import { ref, computed, watch } from 'vue'
import { useI18n } from 'vue-i18n'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { useCreditStore } from '@/stores/credits'
import Button from 'primevue/button'
import Menu from 'primevue/menu'
import { useToast } from 'primevue/usetoast'
import DashboardLanguageSelector from '@/components/DashboardLanguageSelector.vue'

const props = defineProps({
  mode: {
    type: String,
    default: 'dashboard', // 'landing' or 'dashboard'
    validator: (value) => ['landing', 'dashboard'].includes(value)
  }
})

const emit = defineEmits(['scroll-to', 'toggle-mobile-menu'])

const { t } = useI18n()
const router = useRouter()
const authStore = useAuthStore()
const creditStore = useCreditStore()
const toast = useToast()

// Refs
const mainMenu = ref()

// Credit balance for card issuers
const creditBalance = computed(() => {
  if (userRole.value === 'cardIssuer') {
    return creditStore.formattedBalance
  }
  return '0.00'
})

// Computed properties
const isAuthenticated = computed(() => authStore.isLoggedIn())

const userRole = ref(null)

// Function to get user role from session
const getUserRoleFromSession = () => {
  if (!authStore.isLoggedIn()) {
    userRole.value = null
    return
  }
  
  let role = authStore.session?.user?.app_metadata?.role || authStore.session?.user?.user_metadata?.role || authStore.session?.user?.raw_user_meta_data?.role
  
  // Handle both cardIssuer and card_issuer formats
  if (role === 'card_issuer') role = 'cardIssuer'
  
  // Default to cardIssuer if no role found
  if (!role && authStore.session?.user) {
    role = 'cardIssuer'
  }
  
  userRole.value = role
}

// Watch for authentication changes
watch(isAuthenticated, (newVal) => {
  if (newVal) {
    getUserRoleFromSession()
    if (userRole.value === 'cardIssuer') {
      creditStore.fetchCreditBalance()
    }
  } else {
    userRole.value = null
    creditStore.clearStore()
  }
}, { immediate: true })

watch(userRole, (newRole) => {
  if (newRole === 'cardIssuer' && isAuthenticated.value) {
    creditStore.fetchCreditBalance()
  }
})

const userEmail = computed(() => {
  if (!authStore.isLoggedIn()) return ''
  return authStore.session?.user?.email || ''
})

const userDisplayName = computed(() => {
  if (!authStore.isLoggedIn()) return 'User'
  return userEmail.value.split('@')[0] || 'User'
})

const userInitials = computed(() => {
  const name = userDisplayName.value
  return name.split(' ').map(word => word[0]).join('').toUpperCase().slice(0, 2)
})

// Menu items for different user roles
const cardIssuerMenuItems = computed(() => [
  {
    label: t('dashboard.my_cards'),
    icon: 'pi pi-folder',
    command: () => router.push('/cms/mycards')
  },
  {
    label: t('credits.title'),
    icon: 'pi pi-wallet',
    command: () => router.push('/cms/credits')
  }
])

const adminMenuItems = computed(() => [
  {
    label: t('dashboard.dashboard'),
    icon: 'pi pi-chart-line',
    command: () => router.push('/cms/admin')
  },
  {
    label: t('admin.user_management'),
    icon: 'pi pi-users',
    command: () => router.push('/cms/admin/users')
  },
  {
    label: t('header.batch_management'),
    icon: 'pi pi-box',
    command: () => router.push('/cms/admin/batches')
  },
  {
    label: t('admin.credits.title'),
    icon: 'pi pi-wallet',
    command: () => router.push('/cms/admin/credits')
  },
  {
    label: t('admin.print_requests'),
    icon: 'pi pi-print',
    command: () => router.push('/cms/admin/print-requests')
  },
  {
    label: t('admin.user_cards_viewer'),
    icon: 'pi pi-id-card',
    command: () => router.push('/cms/admin/user-cards')
  },
  {
    label: t('header.issue_free_batch'),
    icon: 'pi pi-gift',
    command: () => router.push('/cms/admin/issue-batch')
  },
  {
    label: t('header.history_logs'),
    icon: 'pi pi-history',
    command: () => router.push('/cms/admin/history')
  }
])

// Unified menu items
const unifiedMenuItems = computed(() => {
  if (!authStore.isLoggedIn() || !userRole.value) return []
  
  const navItems = userRole.value === 'cardIssuer' ? cardIssuerMenuItems.value : adminMenuItems.value
  
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
      label: userRole.value === 'admin' ? t('header.admin_panel') : t('header.card_management'),
      disabled: true,
      class: 'section-header'
    },
    ...navItems,
    
    { separator: true },
    
    // User Actions Section
    {
      label: t('auth.sign_out'),
      icon: 'pi pi-sign-out',
      command: handleLogout
    }
  ]
})

// Menu toggle
const toggleMainMenu = (event) => {
  mainMenu.value.toggle(event)
}

// Auth button handler (Sign In / Dashboard)
const handleAuthButtonClick = () => {
  if (isAuthenticated.value) {
    // If logged in, route to dashboard based on role
    if (userRole.value === 'admin') {
      router.push('/cms/admin')
    } else {
      router.push('/cms/mycards')
    }
  } else {
    // If not logged in, route to login page
    router.push('/login')
  }
}

// Logout handler
const handleLogout = async () => {
  try {
    await authStore.signOut()
    if (mainMenu.value) {
      mainMenu.value.hide()
    }
    router.push('/')
  } catch (error) {
    toast.add({
      severity: 'error',
      summary: t('auth.sign_out_failed'),
      detail: t('auth.sign_out_failed_detail'),
      life: 5000
    })
  }
}
</script>

<style scoped>
/* Dashboard Mode: Original clean styling */
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

/* Gradient text compatibility (for both modes) */
.bg-clip-text {
  -webkit-background-clip: text;
  background-clip: text;
}
</style>

