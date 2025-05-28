<template>
    <div class="h-screen flex bg-gradient-to-br from-slate-50 to-blue-50">
        <!-- Sidebar -->
        <div id="app-sidebar-15" class="bg-white shadow-xl border-r border-slate-200 h-full hidden lg:block flex-shrink-0 absolute lg:static left-0 top-0 z-20 lg:w-20 w-72 select-none">
            <div class="flex flex-col h-full">
                <!-- Logo Section -->
                <div class="flex items-center justify-center flex-shrink-0 bg-gradient-to-r from-blue-600 to-indigo-600 p-4 lg:p-3">
                    <div class="relative">
                        <svg class="fill-white w-8 h-8 lg:w-6 lg:h-6" viewBox="0 0 28 29" fill="none" xmlns="http://www.w3.org/2000/svg">
                            <path
                                fill-rule="evenodd"
                                clip-rule="evenodd"
                                d="M14 28.5C21.732 28.5 28 22.232 28 14.5C28 6.76802 21.732 0.5 14 0.5C6.26801 0.5 0 6.76802 0 14.5C0 22.232 6.26801 28.5 14 28.5ZM18.3675 7.02179C18.5801 6.26664 17.8473 5.82009 17.178 6.29691L7.83519 12.9527C7.10936 13.4698 7.22353 14.5 8.00669 14.5H10.4669V14.4809H15.2618L11.3549 15.8595L9.63251 21.9782C9.41992 22.7334 10.1527 23.1799 10.822 22.7031L20.1649 16.0473C20.8907 15.5302 20.7764 14.5 19.9934 14.5H16.2625L18.3675 7.02179Z"
                            />
                        </svg>
                        <div class="absolute -top-1 -right-1 w-3 h-3 bg-green-400 rounded-full border-2 border-white"></div>
                    </div>
                    <span class="ml-3 lg:hidden text-white font-semibold text-lg">Cardy CMS</span>
                </div>

                <!-- Navigation Items -->
                <div class="flex-1 p-3 lg:p-2 flex flex-col gap-2">
                    <template v-for="(item, index) of navs" :key="index">
                        <router-link :to="{ name: item.routeName }" v-slot="{ navigate, isActive }" custom>
                            <a
                                @click="navigate"
                                class="group relative flex items-center cursor-pointer p-3 lg:p-2 lg:justify-center rounded-xl transition-all duration-200 hover:scale-105"
                                :class="[
                                    isActive 
                                        ? 'bg-gradient-to-r from-blue-500 to-indigo-500 text-white shadow-lg' 
                                        : 'text-slate-600 hover:bg-slate-100 hover:text-slate-900'
                                ]"
                            >
                                <i :class="[item.icon, 'text-lg lg:text-base', isActive ? 'text-white' : 'text-slate-500 group-hover:text-slate-700']" />
                                <span class="ml-3 lg:hidden font-medium">{{ item.label }}</span>
                                
                                <!-- Tooltip for collapsed sidebar -->
                                <div class="hidden lg:block absolute left-full ml-2 px-2 py-1 bg-slate-800 text-white text-xs rounded opacity-0 group-hover:opacity-100 transition-opacity duration-200 pointer-events-none whitespace-nowrap z-30">
                                    {{ item.label }}
                                </div>
                                
                                <!-- Active indicator -->
                                <div v-if="isActive" class="absolute left-0 top-1/2 transform -translate-y-1/2 w-1 h-6 bg-white rounded-r-full lg:hidden"></div>
                            </a>
                        </router-link>
                    </template>
                </div>

                <!-- Bottom Navigation -->
                <div class="mt-auto p-3 lg:p-2 border-t border-slate-200">
                    <template v-for="(item, index) of bottomNavs" :key="index">
                        <a
                            v-if="item.action"
                            @click="handleBottomNavClick(item)"
                            class="group relative flex items-center cursor-pointer p-3 lg:p-2 lg:justify-center rounded-xl text-slate-600 hover:bg-red-50 hover:text-red-600 transition-all duration-200 hover:scale-105"
                        >
                            <i :class="[item.icon, 'text-lg lg:text-base text-slate-500 group-hover:text-red-600']" />
                            <span class="ml-3 lg:hidden font-medium">{{ item.label }}</span>
                            
                            <!-- Tooltip for collapsed sidebar -->
                            <div class="hidden lg:block absolute left-full ml-2 px-2 py-1 bg-slate-800 text-white text-xs rounded opacity-0 group-hover:opacity-100 transition-opacity duration-200 pointer-events-none whitespace-nowrap z-30">
                                {{ item.label }}
                            </div>
                        </a>
                    </template>
                </div>
            </div>
        </div>

        <!-- Main Content Area -->
        <div class="h-full flex flex-col relative flex-auto overflow-hidden">
            <!-- Header -->
            <div class="flex justify-between items-center py-4 px-6 bg-white/80 backdrop-blur-sm border-b border-slate-200 flex-shrink-0 shadow-sm">
                <div class="flex items-center gap-4">
                    <!-- Mobile menu button -->
                    <button
                        v-styleclass="{
                            selector: '#app-sidebar-15',
                            enterFromClass: 'hidden',
                            enterActiveClass: 'animate-fadeinleft',
                            leaveToClass: 'hidden',
                            leaveActiveClass: 'animate-fadeoutleft',
                            hideOnOutsideClick: true
                        }"
                        class="lg:hidden p-2 rounded-lg hover:bg-slate-100 transition-colors"
                    >
                        <i class="pi pi-bars text-slate-700 text-lg" />
                    </button>
                    
                    <!-- Page title and breadcrumb -->
                    <div>
                        <h1 class="text-xl font-semibold text-slate-900">{{ getCurrentPageTitle() }}</h1>
                        <p class="text-sm text-slate-500">{{ getCurrentPageDescription() }}</p>
                    </div>
                </div>

                <!-- Header actions -->
                <div class="flex items-center gap-3">
                    <!-- Notifications -->
                    <button class="relative p-2 rounded-lg hover:bg-slate-100 transition-colors">
                        <i class="pi pi-bell text-slate-600 text-lg" />
                        <span class="absolute -top-1 -right-1 w-3 h-3 bg-red-500 rounded-full"></span>
                    </button>
                    
                    <!-- User profile -->
                    <div class="flex items-center gap-3 pl-3 border-l border-slate-200">
                        <div class="w-8 h-8 bg-gradient-to-r from-blue-500 to-indigo-500 rounded-full flex items-center justify-center">
                            <i class="pi pi-user text-white text-sm" />
                        </div>
                        <div class="hidden sm:block">
                            <p class="text-sm font-medium text-slate-900">John Doe</p>
                            <p class="text-xs text-slate-500">Administrator</p>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Main Content -->
            <div class="flex-1 overflow-hidden">
                <div class="h-full p-6 overflow-y-auto">
                    <div class="max-w-7xl mx-auto">
                        <router-view />
                    </div>
                </div>
            </div>
        </div>
    </div>
</template>

<script setup>
import { ref, computed } from 'vue';
import { RouterLink, RouterView, useRouter, useRoute } from 'vue-router';
import { useAuthStore } from '@/stores/auth';

const authStore = useAuthStore();
const router = useRouter();
const route = useRoute();

const navs = ref([
    { 
        icon: 'pi pi-id-card', 
        label: 'My Cards', 
        routeName: 'mycards',
        description: 'Manage your card designs and templates'
    },
    { 
        icon: 'pi pi-send', 
        label: 'Issued Cards', 
        routeName: 'issuedcards',
        description: 'View and manage issued cards'
    },
    { 
        icon: 'pi pi-user', 
        label: 'Profile', 
        routeName: 'profile',
        description: 'Manage your account settings'
    },
]);

const bottomNavs = ref([
    { icon: 'pi pi-power-off', label: 'Logout', action: 'logout' }
]);

const getCurrentPageTitle = () => {
    const currentNav = navs.value.find(nav => nav.routeName === route.name);
    return currentNav?.label || 'Dashboard';
};

const getCurrentPageDescription = () => {
    const currentNav = navs.value.find(nav => nav.routeName === route.name);
    return currentNav?.description || 'Welcome to your dashboard';
};

async function handleLogout() {
  try {
    await authStore.signOut();
  } catch (error) {
    console.error('Failed to log out:', error);
  }
}

function handleBottomNavClick(item) {
  if (item.action === 'logout') {
    handleLogout();
  } else if (item.routeName) {
    router.push({ name: item.routeName });
  }
}
</script>

<style scoped>
/* Custom animations for sidebar */
@keyframes fadeinleft {
  from {
    opacity: 0;
    transform: translateX(-100%);
  }
  to {
    opacity: 1;
    transform: translateX(0);
  }
}

@keyframes fadeoutleft {
  from {
    opacity: 1;
    transform: translateX(0);
  }
  to {
    opacity: 0;
    transform: translateX(-100%);
  }
}

.animate-fadeinleft {
  animation: fadeinleft 0.3s ease-out;
}

.animate-fadeoutleft {
  animation: fadeoutleft 0.3s ease-out;
}

/* Backdrop blur support */
@supports (backdrop-filter: blur(8px)) {
  .backdrop-blur-sm {
    backdrop-filter: blur(8px);
  }
}
</style>
