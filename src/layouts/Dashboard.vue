<template>
    <div class="relative flex gap-2 h-screen bg-surface-50 dark:bg-surface-900 p-2">
        <div id="app-sidebar-15" class="h-full hidden lg:block lg:static absolute left-0 top-0 py-4 pl-4 lg:p-0 z-50">
            <div class="w-[18rem] h-full flex flex-col bg-surface-50 dark:bg-surface-900 rounded-2xl border lg:border-0 border-surface-100 dark:border-surface-800">
                <a class="inline-flex items-center gap-3 px-6 pt-5 pb-6 cursor-pointer">
                    <svg class="fill-surface-900 dark:fill-surface-0" width="28" height="29" viewBox="0 0 28 29" fill="none" xmlns="http://www.w3.org/2000/svg">
                        <path
                            fill-rule="evenodd"
                            clip-rule="evenodd"
                            d="M14 28.5C21.732 28.5 28 22.232 28 14.5C28 6.76802 21.732 0.5 14 0.5C6.26801 0.5 0 6.76802 0 14.5C0 22.232 6.26801 28.5 14 28.5ZM18.3675 7.02179C18.5801 6.26664 17.8473 5.82009 17.178 6.29691L7.83519 12.9527C7.10936 13.4698 7.22353 14.5 8.00669 14.5H10.4669V14.4809H15.2618L11.3549 15.8595L9.63251 21.9782C9.41992 22.7334 10.1527 23.1799 10.822 22.7031L20.1649 16.0473C20.8907 15.5302 20.7764 14.5 19.9934 14.5H16.2625L18.3675 7.02179Z"
                        />
                    </svg>
                    <span class="font-semibold text-surface-900 dark:text-surface-0">ZenTrailMs</span>
                </a>
                <div class="w-[calc(100%-3rem)] mx-auto h-px bg-surface-200 dark:bg-surface-700 px-6" />
                <div class="px-4 py-6 flex-1">
                    <ul class="flex flex-col gap-2 overflow-hidden">
                        <template v-for="(item, index) of navs" :key="index">
                            <li>
                                <router-link :to="{ name: item.routeName }" v-slot="{ navigate, isActive }" custom>
                                    <button
                                        :class="[
                                            'z-30 text-left w-full relative flex items-center gap-2 pl-3 pr-2 py-2 rounded-lg cursor-pointer transition-all border',
                                            isActive
                                                ? 'bg-surface-0 dark:bg-surface-950 text-surface-900 dark:text-surface-0 border-surface shadow-[0px_-1px_3px_0px_rgba(0,0,0,0.12)_inset]'
                                                : 'border-transparent hover:border-surface-200 dark:hover:border-surface-800 hover:bg-surface-0 dark:hover:bg-surface-950 text-surface-600 dark:text-surface-400'
                                        ]"
                                        @click="navigate"
                                    >
                                        <i :class="item.icon" class="!text-xl !leading-none" />
                                        <span class="flex-1 font-medium">{{ item.label }}</span>
                                    </button>
                                </router-link>
                            </li>
                        </template>
                    </ul>
                </div>
                <ul class="flex flex-col gap-2 px-4 py-3">
                    <template v-for="(item, index) of bottomNavs" :key="index">
                        <li>
                            <button
                                v-if="item.action"
                                :class="[
                                    'z-30 text-left w-full relative flex items-center gap-2 pl-3 pr-2 py-2 rounded-lg cursor-pointer transition-all border',
                                    'border-transparent hover:border-surface-200 dark:hover:border-surface-800 hover:bg-surface-0 dark:hover:bg-surface-950 text-surface-600 dark:text-surface-400'
                                ]"
                                @click="handleBottomNavClick(item)"
                            >
                                <i :class="item.icon" class="!text-xl !leading-none" />
                                <span class="flex-1 font-medium">{{ item.label }}</span>
                            </button>
                            <router-link v-else-if="item.routeName" :to="{ name: item.routeName }" v-slot="{ navigate, isActive }" custom>
                                <button
                                    :class="[
                                        'z-30 text-left w-full relative flex items-center gap-2 pl-3 pr-2 py-2 rounded-lg cursor-pointer transition-all border',
                                        isActive
                                            ? 'bg-surface-0 dark:bg-surface-950 text-surface-900 dark:text-surface-0 border-surface shadow-[0px_-1px_3px_0px_rgba(0,0,0,0.12)_inset]'
                                            : 'border-transparent hover:border-surface-200 dark:hover:border-surface-800 hover:bg-surface-0 dark:hover:bg-surface-950 text-surface-600 dark:text-surface-400'
                                    ]"
                                    @click="navigate"
                                >
                                    <i :class="item.icon" class="!text-xl !leading-none" />
                                    <span class="flex-1 font-medium">{{ item.label }}</span>
                                </button>
                            </router-link>
                        </li>
                    </template>
                </ul>
            </div>
        </div>

        <div class="flex-1 flex flex-col gap-6 p-4 rounded-2xl border border-surface bg-surface-0 dark:bg-surface-950">
            <div class="flex sm:items-center flex-wrap sm:flex-row flex-col pb-4 justify-between border-b border-dashed border-surface gap-4 lg:hidden">
                <div class="flex items-center gap-2">
                    <a
                        v-styleclass="{
                            selector: '#app-sidebar-15',
                            enterFromClass: 'hidden',
                            enterActiveClass: 'animate-fadeinleft',
                            leaveToClass: 'hidden',
                            leaveActiveClass: 'animate-fadeoutleft',
                            hideOnOutsideClick: true
                        }"
                        class="cursor-pointer block lg:hidden text-surface-700 dark:text-surface-100 ml-2"
                    >
                        <i class="pi pi-bars !text-2xl" />
                    </a>
                </div>
            </div>
            <!-- Main content will be rendered here by Vue Router -->
             <div class="px-4">
                <router-view />
             </div>
            
        </div>
    </div>
</template>

<script setup>
import Avatar from 'primevue/avatar';
import Button from 'primevue/button';
import IconField from 'primevue/iconfield';
import InputIcon from 'primevue/inputicon';
import InputText from 'primevue/inputtext';
import { ref } from 'vue';
import { RouterLink, RouterView, useRouter } from 'vue-router';
import { useAuthStore } from '@/stores/auth';

const search = ref();
const authStore = useAuthStore();
const router = useRouter();

const navs = ref([
    { icon: 'pi pi-id-card', label: 'My Cards', routeName: 'mycards' },
    { icon: 'pi pi-id-card', label: 'Issued Cards', routeName: 'issuedcards' },
    { icon: 'pi pi-user', label: 'Profile', routeName: 'profile' },
]);

const bottomNavs = ref([
    { icon: 'pi pi-power-off', label: 'Logout', action: 'logout' }
]);

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
