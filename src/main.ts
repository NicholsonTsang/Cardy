import './assets/main.css'

import { createApp } from 'vue'
import { createPinia } from 'pinia'
import App from './App.vue'
import router from './router'
import i18n from './i18n'
import PrimeVue from 'primevue/config';
import Aura from '@primevue/themes/aura';
import { definePreset } from '@primevue/themes';
import StyleClass from 'primevue/styleclass';
import ToastService from 'primevue/toastservice';
import ConfirmationService from 'primevue/confirmationservice';
import Tooltip from 'primevue/tooltip';

// Create custom preset with blue as primary color
const CustomPreset = definePreset(Aura, {
    semantic: {
        primary: {
            50: '{blue.50}',
            100: '{blue.100}',
            200: '{blue.200}',
            300: '{blue.300}',
            400: '{blue.400}',
            500: '{blue.500}',
            600: '{blue.600}',
            700: '{blue.700}',
            800: '{blue.800}',
            900: '{blue.900}',
            950: '{blue.950}'
        }
    }
});

const app = createApp(App)

app.directive('styleclass', StyleClass);
app.directive('tooltip', Tooltip);

app.use(PrimeVue, {
    theme: {
        preset: CustomPreset,
        options: {
            darkModeSelector: '.dark'
        }
    }
});
app.use(ToastService);
app.use(ConfirmationService);
app.use(createPinia())
app.use(router)
app.use(i18n)

// Initialize auth store eagerly for faster first navigation
// This must happen AFTER app.use(router) so useRouter() works in the auth store
import { useAuthStore } from '@/stores/auth'
const authStore = useAuthStore()
authStore.initialize().catch(err => {
  console.error('Failed to initialize auth:', err)
})

app.mount('#app')