<template>
  <!-- Dashboard Mode: Clean, simple header -->
  <header 
    v-if="mode === 'dashboard'"
    class="app-header border-b border-slate-200 bg-white shadow-sm"
  >
    <div class="max-w-7xl mx-auto px-3 sm:px-6 lg:px-8">
      <div class="flex justify-between items-center h-14 sm:h-16">
        <!-- Logo -->
        <div class="flex items-center">
          <router-link to="/" class="flex items-center gap-2 sm:gap-2.5 hover:opacity-90 transition-opacity group">
            <LogoAnimation size="md" />
            <span class="hidden sm:inline text-lg sm:text-xl font-bold bg-gradient-to-r from-blue-600 to-purple-600 bg-clip-text text-transparent">
              {{ $t('common.app_name') }}
            </span>
          </router-link>
        </div>

        <!-- Center: Clean space -->
        <div class="flex-1"></div>

        <!-- Right Side: Dashboard Controls -->
        <div class="flex items-center space-x-2 sm:space-x-4">
          <!-- Credit Balance Display (for Card Issuers) -->
          <div v-if="isAuthenticated && userRole === 'cardIssuer'" class="flex items-center gap-1 sm:gap-2 px-2 sm:px-3 py-1 sm:py-1.5 bg-gray-100 rounded-lg">
            <i class="pi pi-wallet text-blue-600 text-xs sm:text-sm"></i>
            <span class="hidden sm:inline text-sm font-medium text-gray-700">{{ $t('credits.balance') }}:</span>
            <span class="text-xs sm:text-sm font-bold text-blue-600">{{ creditBalance }}</span>
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
              class="main-menu-button !p-1.5 sm:!p-3"
              text
              :aria-label="$t('common.main_menu')"
            >
              <div class="flex items-center gap-1.5 sm:gap-3">
                <div class="w-8 h-8 sm:w-10 sm:h-10 bg-gradient-to-r from-blue-600 to-indigo-600 rounded-full flex items-center justify-center text-white text-xs sm:text-sm font-medium shadow-md">
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
                <i class="pi pi-chevron-down text-slate-400 transition-transform duration-200 text-xs sm:text-sm"></i>
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
    <div class="max-w-7xl mx-auto px-3 sm:px-6 lg:px-8">
      <div class="flex items-center h-14 sm:h-16">
        <!-- Logo (Left) -->
        <div class="flex items-center">
          <router-link to="/" class="flex items-center gap-2 sm:gap-2.5 hover:opacity-90 transition-opacity group">
            <LogoAnimation size="md" />
            <span class="hidden sm:inline text-lg sm:text-xl font-bold bg-gradient-to-r from-blue-600 to-purple-600 bg-clip-text text-transparent">
              {{ $t('common.app_name') }}
            </span>
          </router-link>
        </div>

        <!-- Spacer to push navigation to center -->
        <div class="flex-1"></div>
        
        <!-- Desktop Navigation - Centered for lg and above (ordered by user journey) -->
        <div class="hidden lg:flex items-center gap-8">
          <a @click="handleScrollTo('features')" class="text-slate-600 hover:text-blue-600 font-medium cursor-pointer transition-colors">
            {{ $t('landing.nav.features') }}
          </a>
          <a @click="handleScrollTo('how-it-works')" class="text-slate-600 hover:text-blue-600 font-medium cursor-pointer transition-colors">
            {{ $t('landing.nav.how_it_works') }}
          </a>
          <a @click="handleScrollTo('demo-templates')" class="text-slate-600 hover:text-blue-600 font-medium cursor-pointer transition-colors">
            {{ $t('landing.nav.demo') }}
          </a>
          <a @click="handleScrollTo('pricing')" class="text-slate-600 hover:text-blue-600 font-medium cursor-pointer transition-colors">
            {{ $t('landing.nav.pricing') }}
          </a>
          <router-link to="/docs" class="text-slate-600 hover:text-blue-600 font-medium transition-colors">
            {{ $t('landing.nav.docs') }}
          </router-link>
        </div>

        <!-- Spacer to balance and keep navigation centered -->
        <div class="flex-1"></div>

        <!-- Right Side: Dashboard Controls -->
        <div class="flex items-center space-x-2 sm:space-x-4">
          <!-- Language Selector (10 languages for landing page) -->
          <LandingLanguageSelector />

          <!-- Get Started Button - Desktop Only -->
          <div class="hidden lg:flex items-center">
            <button 
              @click="handleGetStarted"
              class="flex items-center gap-2 px-6 py-2.5 bg-gradient-to-r from-blue-600 to-purple-600 hover:from-blue-700 hover:to-purple-700 text-white font-bold rounded-lg shadow-lg hover:shadow-xl transition-all duration-300 transform hover:scale-105 cursor-pointer"
            >
              <span>{{ $t('landing.nav.get_started') }}</span>
              <i class="pi pi-arrow-right text-sm"></i>
            </button>
          </div>

          <!-- Mobile Menu Button - Shows ONLY when nav links are hidden (below lg/1024px) -->
          <Button 
            icon="pi pi-bars"
            @click="toggleMobileMenu"
            class="p-button-text text-slate-700 hover:text-blue-600 block lg:!hidden !p-2"
          />
        </div>
      </div>
    </div>

    <!-- Mobile Menu Dropdown (Landing Mode) -->
    <transition name="slide-down">
      <div v-if="mobileMenuOpen" class="lg:hidden bg-white border-b border-slate-200 shadow-lg">
        <div class="max-w-7xl mx-auto px-4 py-4 space-y-3">
          <a @click="handleMobileNavClick('features')" class="block text-slate-700 hover:text-blue-600 font-medium py-2 cursor-pointer transition-colors">
            {{ $t('landing.nav.features') }}
          </a>
          <a @click="handleMobileNavClick('how-it-works')" class="block text-slate-700 hover:text-blue-600 font-medium py-2 cursor-pointer transition-colors">
            {{ $t('landing.nav.how_it_works') }}
          </a>
          <a @click="handleMobileNavClick('demo-templates')" class="block text-slate-700 hover:text-blue-600 font-medium py-2 cursor-pointer transition-colors">
            {{ $t('landing.nav.demo') }}
          </a>
          <a @click="handleMobileNavClick('pricing')" class="block text-slate-700 hover:text-blue-600 font-medium py-2 cursor-pointer transition-colors">
            {{ $t('landing.nav.pricing') }}
          </a>
          <router-link to="/docs" @click="mobileMenuOpen = false" class="block text-slate-700 hover:text-blue-600 font-medium py-2 transition-colors">
            {{ $t('landing.nav.docs') }}
          </router-link>
          <div class="pt-3 border-t border-slate-200">
            <button 
              @click="handleMobileGetStarted"
              class="w-full flex items-center justify-center gap-2 px-6 py-3 bg-gradient-to-r from-blue-600 to-purple-600 hover:from-blue-700 hover:to-purple-700 text-white font-bold rounded-xl shadow-lg transition-all duration-300"
            >
              <span>{{ $t('landing.nav.get_started') }}</span>
              <i class="pi pi-arrow-right text-sm"></i>
            </button>
          </div>
        </div>
      </div>
    </transition>
  </header>
</template>

<script setup>
import { ref, computed, watch } from 'vue'
import { useI18n } from 'vue-i18n'
import { useRouter, useRoute } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { useCreditStore } from '@/stores/credits'
import Button from 'primevue/button'
import Menu from 'primevue/menu'
import { useToast } from 'primevue/usetoast'
import DashboardLanguageSelector from '@/components/DashboardLanguageSelector.vue'
import LandingLanguageSelector from '@/components/LandingLanguageSelector.vue'
import LogoAnimation from '@/components/Landing/LogoAnimation.vue'
import { usePhysicalCards } from '@/composables/usePhysicalCards'

const props = defineProps({
  mode: {
    type: String,
    default: 'dashboard', // 'landing' or 'dashboard'
    validator: (value) => ['landing', 'dashboard'].includes(value)
  }
})

const emit = defineEmits(['scroll-to', 'toggle-mobile-menu'])

const { t, locale } = useI18n()
const router = useRouter()
const route = useRoute()
const authStore = useAuthStore()
const creditStore = useCreditStore()
const toast = useToast()
const { isPhysicalCardsEnabled } = usePhysicalCards()

// Refs
const mainMenu = ref()
const mobileMenuOpen = ref(false)

// Mobile menu methods
const toggleMobileMenu = () => {
  mobileMenuOpen.value = !mobileMenuOpen.value
  emit('toggle-mobile-menu') // Also emit for parent components that want to handle it
}

const handleMobileNavClick = (section) => {
  mobileMenuOpen.value = false
  handleScrollTo(section)
}

const handleMobileGetStarted = () => {
  mobileMenuOpen.value = false
  handleGetStarted()
}

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
    command: () => router.push('/cms/projects')
  },
  {
    label: t('subscription.title'),
    icon: 'pi pi-star',
    command: () => router.push('/cms/subscription')
  },
  {
    label: t('credits.title'),
    icon: 'pi pi-wallet',
    command: () => router.push('/cms/credits')
  }
])

const adminMenuItems = computed(() => {
  const items = [
    {
      label: t('dashboard.dashboard'),
      icon: 'pi pi-chart-line',
      command: () => router.push('/cms/admin')
    },
    {
      label: t('dashboard.my_cards'),
      icon: 'pi pi-folder',
      command: () => router.push('/cms/projects')
    },
    {
      label: t('admin.user_management'),
      icon: 'pi pi-users',
      command: () => router.push('/cms/admin/users')
    },
    // Physical cards: batch management
    ...(isPhysicalCardsEnabled.value ? [{
      label: t('header.batch_management'),
      icon: 'pi pi-box',
      command: () => router.push('/cms/admin/batches')
    }] : []),
    {
      label: t('templates.admin.management_title'),
      icon: 'pi pi-copy',
      command: () => router.push('/cms/admin/templates')
    },
    {
      label: t('admin.credits.title'),
      icon: 'pi pi-wallet',
      command: () => router.push('/cms/admin/credits')
    },
    // Physical cards: print requests
    ...(isPhysicalCardsEnabled.value ? [{
      label: t('admin.print_requests'),
      icon: 'pi pi-print',
      command: () => router.push('/cms/admin/print-requests')
    }] : []),
    {
      label: t('admin.user_cards_viewer'),
      icon: 'pi pi-id-card',
      command: () => router.push('/cms/admin/user-projects')
    },
    // Physical cards: issue free batch
    ...(isPhysicalCardsEnabled.value ? [{
      label: t('header.issue_free_batch'),
      icon: 'pi pi-gift',
      command: () => router.push('/cms/admin/issue-batch')
    }] : []),
    {
      label: t('header.history_logs'),
      icon: 'pi pi-history',
      command: () => router.push('/cms/admin/history')
    }
  ]
  return items
})

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

// Get Started handler - navigates to login or dashboard based on auth state
const handleGetStarted = () => {
  if (isAuthenticated.value) {
    router.push('/cms')
  } else {
    router.push('/login')
  }
}

// Handle scroll to section - if on landing page, emit event; otherwise navigate to landing with hash
const handleScrollTo = (section) => {
  // Check if we are on the landing page (checking name is more reliable with language routes)
  const isLandingPage = route.name === 'landing-lang' || route.path === '/' || route.path === `/${locale.value}`;
  
  if (isLandingPage) {
    // On landing page - emit event to scroll and update URL hash
    emit('scroll-to', section)
    // Update URL with hash without triggering navigation
    router.replace({ 
      hash: `#${section}` 
    })
  } else {
    // On another page - navigate to landing page with hash and current language
    router.push({ 
      name: 'landing-lang', 
      params: { lang: locale.value },
      hash: `#${section}` 
    })
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

/* Mobile menu slide-down animation */
.slide-down-enter-active,
.slide-down-leave-active {
  transition: all 0.3s ease-out;
}

.slide-down-enter-from,
.slide-down-leave-to {
  opacity: 0;
  transform: translateY(-10px);
}
</style>

