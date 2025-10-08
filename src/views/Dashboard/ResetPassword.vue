<template>
    <div class="min-h-screen bg-gradient-to-br from-slate-50 via-blue-50 to-indigo-100 flex items-center justify-center p-4">
        <div class="w-full max-w-md">
            <!-- Main Card -->
            <main class="bg-white rounded-2xl shadow-xl border border-slate-200 overflow-hidden" role="main" aria-labelledby="reset-title">
                <!-- Header Section -->
                <div class="px-8 pt-8 pb-6 text-center">
                    <div class="inline-flex items-center justify-center w-16 h-16 bg-gradient-to-r from-blue-600 to-indigo-600 rounded-2xl mb-6 shadow-lg">
                        <i class="pi pi-lock text-white text-3xl"></i>
                    </div>
                    <h1 id="reset-title" class="text-2xl font-bold text-slate-900 mb-2">{{ $t('auth.reset_password') }}</h1>
                    <p class="text-slate-600">{{ $t('auth.enter_new_password') }}</p>
                </div>

                <!-- Form Section -->
                <div class="px-8 pb-8">
                    <form @submit.prevent="handleResetPassword" class="space-y-5">
                        <!-- New Password Field -->
                        <div class="space-y-2">
                            <label for="new-password" class="block text-sm font-medium text-slate-700">{{ $t('auth.new_password') }}</label>
                            <InputText 
                                id="new-password" 
                                v-model="newPassword" 
                                type="password" 
                                :placeholder="$t('auth.new_password')" 
                                class="w-full px-4 py-3 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-colors"
                                :class="{ 'border-red-300 focus:ring-red-500 focus:border-red-500': newPasswordError }"
                                required 
                            />
                            <p v-if="newPasswordError" class="text-sm text-red-600">{{ newPasswordError }}</p>
                            <p class="text-xs text-slate-500">{{ $t('auth.password_requirements') }}</p>
                        </div>

                        <!-- Confirm Password Field -->
                        <div class="space-y-2">
                            <label for="confirm-password" class="block text-sm font-medium text-slate-700">{{ $t('auth.confirm_password') }}</label>
                            <InputText 
                                id="confirm-password" 
                                v-model="confirmPassword" 
                                type="password" 
                                :placeholder="$t('auth.confirm_password')" 
                                class="w-full px-4 py-3 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-colors"
                                :class="{ 'border-red-300 focus:ring-red-500 focus:border-red-500': confirmPasswordError }"
                                required 
                            />
                            <p v-if="confirmPasswordError" class="text-sm text-red-600">{{ confirmPasswordError }}</p>
                        </div>

                        <!-- Success Message -->
                        <Message v-if="successMessage" severity="success" :closable="false" class="mb-4">
                            {{ successMessage }}
                        </Message>

                        <!-- Error Message -->
                        <Message v-if="errorMessage" severity="error" :closable="false" class="mb-4">
                            {{ errorMessage }}
                        </Message>

                        <!-- Submit Button -->
                        <Button 
                            type="submit" 
                            :label="$t('auth.reset_password')" 
                            severity="primary"
                            class="w-full py-3 border-0 shadow-lg hover:shadow-xl transition-all duration-200" 
                            :style="{
                                background: 'linear-gradient(to right, #2563eb, #4f46e5)',
                                borderColor: 'transparent'
                            }"
                            :loading="isLoading"
                            :disabled="!!newPasswordError || !!confirmPasswordError"
                        />
                    </form>

                    <!-- Back to Sign In -->
                    <div class="mt-6 text-center">
                        <a @click="goToSignIn" class="text-blue-600 hover:text-blue-800 font-medium cursor-pointer transition-colors">
                            ← Back to Sign In
                        </a>
                    </div>
                </div>
            </main>
        </div>
    </div>
</template>

<script setup>
import Button from 'primevue/button';
import InputText from 'primevue/inputtext';
import Message from 'primevue/message';
import { ref, computed, onMounted } from 'vue';
import { useAuthStore } from '@/stores/auth.js';
import { useRouter, useRoute } from 'vue-router';
import { useI18n } from 'vue-i18n';

const { t } = useI18n();

const newPassword = ref('');
const confirmPassword = ref('');

const authStore = useAuthStore();
const router = useRouter();
const route = useRoute();

const isLoading = ref(false);
const errorMessage = ref('');
const successMessage = ref('');

// Form validation
const newPasswordError = computed(() => {
    if (!newPassword.value) return '';
    return newPassword.value.length < 6 ? t('auth.password_requirements') : '';
});

const confirmPasswordError = computed(() => {
    if (!confirmPassword.value) return '';
    return confirmPassword.value !== newPassword.value ? t('auth.passwords_must_match') : '';
});

async function handleResetPassword() {
    // Clear previous messages
    errorMessage.value = '';
    successMessage.value = '';
    
    // Validate form
    if (newPasswordError.value || confirmPasswordError.value) {
        errorMessage.value = t('validation.required_field');
        return;
    }

    isLoading.value = true;
    try {
        await authStore.updatePassword(newPassword.value);
        successMessage.value = t('auth.password_update_success');
        
        // Redirect to sign in after 2 seconds
        setTimeout(() => {
            router.push('/login');
        }, 2000);
    } catch (error) {
        errorMessage.value = error.message || t('messages.network_error');
        console.error('Reset password error:', error);
    } finally {
        isLoading.value = false;
    }
}

function goToSignIn() {
    router.push('/login');
}

// Check if user has a valid reset token
onMounted(() => {
    const hashParams = new URLSearchParams(window.location.hash.substring(1));
    const accessToken = hashParams.get('access_token');
    
    if (!accessToken) {
        errorMessage.value = 'Invalid or expired reset link. Please request a new one.';
    }
});
</script>

<style scoped>
/* Custom input styling */
:deep(.p-inputtext) {
    transition: all 0.2s ease-in-out;
}

:deep(.p-inputtext:focus) {
    transform: translateY(-1px);
    box-shadow: 0 4px 12px rgba(59, 130, 246, 0.15);
}

/* Custom button styling */
:deep(.p-button) {
    transition: all 0.2s ease-in-out;
}

:deep(.p-button:hover) {
    transform: translateY(-1px);
}

:deep(.p-button:disabled) {
    transform: none;
    opacity: 0.6;
    cursor: not-allowed;
}

/* Reduced motion support */
@media (prefers-reduced-motion: reduce) {
    :deep(.p-inputtext),
    :deep(.p-button) {
        transition: none;
    }
    
    :deep(.p-inputtext:focus),
    :deep(.p-button:hover) {
        transform: none;
    }
}
</style>

