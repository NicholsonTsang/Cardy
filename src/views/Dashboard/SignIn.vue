<template>
    <div class="min-h-screen bg-gradient-to-br from-slate-50 via-blue-50 to-indigo-100 flex items-center justify-center p-4">
        <div class="w-full max-w-md">
            <!-- Main Card -->
            <main class="bg-white rounded-2xl shadow-xl border border-slate-200 overflow-hidden" role="main" aria-labelledby="signin-title">
                <!-- Header Section -->
                <div class="px-8 pt-8 pb-6 text-center">
                    <!-- Logo -->
                    <div class="flex flex-col items-center mb-6">
                        <div class="mb-2">
                            <LogoAnimation size="lg" />
                        </div>
                        <span class="text-2xl font-bold bg-gradient-to-r from-blue-600 to-purple-600 bg-clip-text text-transparent">
                            FunTell
                        </span>
                    </div>
                    <h1 id="signin-title" class="text-2xl font-bold text-slate-900 mb-2">{{ $t('auth.welcome_back') }}</h1>
                    <p class="text-slate-600" id="signin-description">{{ $t('auth.cms_account_subtitle') }}</p>
                </div>

                <!-- Form Section -->
                <div class="px-8 pb-8">
                    <!-- Email Form -->
                    <form @submit.prevent="handleSignIn" class="space-y-5">
                        <!-- Email Field -->
                        <div class="space-y-2">
                            <label for="email" class="block text-sm font-medium text-slate-700">{{ $t('auth.email_address') }}</label>
                            <InputText 
                                id="email" 
                                v-model="email" 
                                type="email" 
                                :placeholder="$t('auth.email_address')" 
                                class="w-full px-4 py-3 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-colors"
                                :class="{ 'border-red-300 focus:ring-red-500 focus:border-red-500': emailError }"
                                required 
                            />
                            <p v-if="emailError" class="text-sm text-red-600">{{ emailError }}</p>
                        </div>

                        <!-- Password Field -->
                        <div class="space-y-2">
                            <label for="password" class="block text-sm font-medium text-slate-700">{{ $t('auth.password') }}</label>
                            <InputText 
                                id="password" 
                                v-model="password" 
                                type="password" 
                                :placeholder="$t('auth.password')" 
                                class="w-full px-4 py-3 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-colors"
                                :class="{ 'border-red-300 focus:ring-red-500 focus:border-red-500': passwordError }"
                                required 
                            />
                            <p v-if="passwordError" class="text-sm text-red-600">{{ passwordError }}</p>
                        </div>

                        <!-- Error Message -->
                        <Message v-if="errorMessage" severity="error" :closable="false" class="mb-4">
                            {{ errorMessage }}
                        </Message>

                        <!-- Remember Me & Forgot Password -->
                        <div class="flex items-center justify-between">
                            <div class="flex items-center">
                                <Checkbox id="rememberme" v-model="rememberMe" :binary="true" class="mr-2" />
                                <label for="rememberme" class="text-sm text-slate-600">{{ $t('auth.remember_me') }}</label>
                            </div>
                            <a @click="showForgotPasswordDialog = true" class="text-sm text-blue-600 hover:text-blue-800 font-medium transition-colors cursor-pointer">
                                {{ $t('auth.forgot_password') }}
                            </a>
                        </div>

                        <!-- Submit Button -->
                        <Button 
                            type="submit" 
                            :label="$t('auth.sign_in')" 
                            severity="primary"
                            class="w-full py-3 border-0 shadow-lg hover:shadow-xl transition-all duration-200" 
                            :style="{
                                background: 'linear-gradient(to right, #2563eb, #4f46e5)',
                                borderColor: 'transparent'
                            }"
                            :loading="isLoading" 
                        />

                        <!-- OR Divider -->
                        <div class="relative py-4">
                            <div class="absolute inset-0 flex items-center">
                                <span class="w-full border-t border-slate-200"></span>
                            </div>
                            <div class="relative flex justify-center text-xs uppercase">
                                <span class="bg-white px-2 text-slate-500 font-medium">{{ $t('auth.or') }}</span>
                            </div>
                        </div>

                        <!-- Google Sign In Button -->
                        <button 
                            @click="handleGoogleSignIn"
                            type="button"
                            class="w-full py-3 bg-white border border-slate-300 text-slate-700 hover:bg-slate-50 hover:border-slate-400 transition-all duration-200 flex items-center justify-center gap-3 shadow-sm rounded-lg disabled:opacity-50 disabled:cursor-not-allowed"
                            :disabled="isLoading"
                        >
                            <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 48 48">
                                <path fill="#FFC107" d="M43.611,20.083H42V20H24v8h11.303c-1.649,4.657-6.08,8-11.303,8c-6.627,0-12-5.373-12-12c0-6.627,5.373-12,12-12c3.059,0,5.842,1.154,7.961,3.039l5.657-5.657C34.046,6.053,29.268,4,24,4C12.955,4,4,12.955,4,24c0,11.045,8.955,20,20,20c11.045,0,20-8.955,20-20C44,22.659,43.862,21.35,43.611,20.083z"/>
                                <path fill="#FF3D00" d="M6.306,14.691l6.571,4.819C14.655,15.108,18.961,12,24,12c3.059,0,5.842,1.154,7.961,3.039l5.657-5.657C34.046,6.053,29.268,4,24,4C16.318,4,9.656,8.337,6.306,14.691z"/>
                                <path fill="#4CAF50" d="M24,44c5.166,0,9.86-1.977,13.409-5.192l-6.19-5.238C29.211,35.091,26.715,36,24,36c-5.202,0-9.619-3.317-11.283-7.946l-6.522,5.025C9.505,39.556,16.227,44,24,44z"/>
                                <path fill="#1976D2" d="M43.611,20.083H42V20H24v8h11.303c-0.792,2.237-2.231,4.166-4.087,5.571c0.001-0.001,0.002-0.001,0.003-0.002l6.19,5.238C36.971,39.205,44,34,44,24C44,22.659,43.862,21.35,43.611,20.083z"/>
                            </svg>
                            <span class="font-medium text-slate-700">{{ $t('auth.sign_in_with_google') }}</span>
                        </button>
                    </form>

                    <!-- Sign Up Link -->
                    <div class="mt-8 text-center">
                        <p class="text-slate-600">
                            {{ $t('auth.dont_have_account') }} 
                            <a @click="goToSignUp" class="text-blue-600 hover:text-blue-800 font-medium cursor-pointer transition-colors">
                                {{ $t('auth.sign_up_here') }}
                            </a>
                        </p>
                    </div>
                </div>
            </main>

            <!-- Footer -->
            <footer class="mt-8 text-center" role="contentinfo">
                <p class="text-sm text-slate-500">
                    {{ $t('auth.by_signing_in_agree') }} 
                    <a href="#" 
                       class="text-blue-600 hover:text-blue-800 transition-colors"
                       :aria-label="$t('auth.terms_of_service')"
                       @keydown.enter.prevent="$event.target.click()">{{ $t('auth.terms_of_service') }}</a> 
                    {{ $t('auth.and') }} 
                    <a href="#" 
                       class="text-blue-600 hover:text-blue-800 transition-colors"
                       :aria-label="$t('auth.privacy_policy')"
                       @keydown.enter.prevent="$event.target.click()">{{ $t('auth.privacy_policy') }}</a>
                </p>
            </footer>
        </div>

        <!-- Forgot Password Dialog -->
        <Dialog 
            v-model:visible="showForgotPasswordDialog" 
            modal 
            :closable="true"
            :draggable="false"
            :style="{ width: '90vw', maxWidth: '32rem' }"
            :header="$t('auth.reset_password')"
        >
            <div class="space-y-4">
                <p class="text-slate-600 text-sm">
                    {{ $t('auth.enter_email_to_reset') }}
                </p>
                
                <div class="space-y-2">
                    <label for="reset-email" class="block text-sm font-medium text-slate-700">{{ $t('auth.email_address') }}</label>
                    <InputText 
                        id="reset-email" 
                        v-model="resetEmail" 
                        type="email" 
                        :placeholder="$t('auth.email_address')" 
                        class="w-full px-4 py-3 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                        :class="{ 'border-red-300 focus:ring-red-500 focus:border-red-500': resetEmailError }"
                    />
                    <p v-if="resetEmailError" class="text-sm text-red-600">{{ resetEmailError }}</p>
                </div>

                <Message v-if="resetSuccessMessage" severity="success" :closable="false" class="mb-2">
                    {{ resetSuccessMessage }}
                </Message>
                
                <Message v-if="resetErrorMessage" severity="error" :closable="false" class="mb-2">
                    {{ resetErrorMessage }}
                </Message>
            </div>

            <template #footer>
                <div class="flex gap-2 justify-end">
                    <Button 
                        :label="$t('common.cancel')" 
                        severity="secondary"
                        outlined
                        @click="closeForgotPasswordDialog" 
                        :disabled="isSendingResetEmail"
                    />
                    <Button 
                        :label="$t('auth.send_reset_link')" 
                        severity="primary"
                        @click="handleSendPasswordReset" 
                        :loading="isSendingResetEmail"
                        :disabled="!resetEmail || !!resetEmailError"
                    />
                </div>
            </template>
        </Dialog>
    </div>
</template>

<script setup>
import Button from 'primevue/button';
import Checkbox from 'primevue/checkbox';
import InputText from 'primevue/inputtext';
import Message from 'primevue/message';
import Dialog from 'primevue/dialog';
import { ref, computed } from 'vue';
import { useAuthStore } from '@/stores/auth.js';
import { useRouter } from 'vue-router';
import { useI18n } from 'vue-i18n';
import LogoAnimation from '@/components/Landing/LogoAnimation.vue';

const { t } = useI18n();

const email = ref('');
const password = ref('');
const rememberMe = ref(false);

const authStore = useAuthStore();
const router = useRouter();

const isLoading = ref(false);
const errorMessage = ref('');

// Forgot Password Dialog
const showForgotPasswordDialog = ref(false);
const resetEmail = ref('');
const isSendingResetEmail = ref(false);
const resetSuccessMessage = ref('');
const resetErrorMessage = ref('');

// Form validation
const emailError = computed(() => {
    if (!email.value) return '';
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return !emailRegex.test(email.value) ? t('auth.invalid_email') : '';
});

const passwordError = computed(() => {
    if (!password.value) return '';
    return password.value.length < 6 ? t('auth.password_requirements') : '';
});

const resetEmailError = computed(() => {
    if (!resetEmail.value) return '';
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return !emailRegex.test(resetEmail.value) ? t('auth.invalid_email') : '';
});

async function handleSendPasswordReset() {
    // Clear previous messages
    resetSuccessMessage.value = '';
    resetErrorMessage.value = '';
    
    // Validate email
    if (resetEmailError.value) {
        resetErrorMessage.value = t('auth.invalid_email');
        return;
    }

    isSendingResetEmail.value = true;
    try {
        await authStore.sendPasswordResetEmail(resetEmail.value);
        resetSuccessMessage.value = t('auth.password_reset_email_sent');
        
        // Close dialog after 2 seconds
        setTimeout(() => {
            closeForgotPasswordDialog();
        }, 2000);
    } catch (error) {
        resetErrorMessage.value = error.message || t('messages.network_error');
        console.error('Password reset error:', error);
    } finally {
        isSendingResetEmail.value = false;
    }
}

function closeForgotPasswordDialog() {
    showForgotPasswordDialog.value = false;
    resetEmail.value = '';
    resetSuccessMessage.value = '';
    resetErrorMessage.value = '';
}

async function handleSignIn() {
    // Clear previous errors
    errorMessage.value = '';
    
    // Validate form
    if (emailError.value || passwordError.value) {
        errorMessage.value = t('validation.required_field');
        return;
    }

    isLoading.value = true;
    try {
        await authStore.signInWithEmail(email.value, password.value);
    } catch (error) {
        errorMessage.value = error.message || t('auth.sign_in_error');
        console.error('Sign in error:', error);
    } finally {
        isLoading.value = false;
    }
}

async function handleGoogleSignIn() {
    isLoading.value = true;
    errorMessage.value = '';
    try {
        await authStore.signInWithGoogle();
    } catch (error) {
        errorMessage.value = error.message || t('auth.sign_in_error');
        console.error('Google sign in error:', error);
    } finally {
        isLoading.value = false;
    }
}

function goToSignUp() {
    router.push('/signup');
}
</script>

<style scoped>
/* Gradient text compatibility */
.bg-clip-text {
    -webkit-background-clip: text;
    background-clip: text;
}

/* Screen reader only content */
.sr-only {
    position: absolute;
    width: 1px;
    height: 1px;
    padding: 0;
    margin: -1px;
    overflow: hidden;
    clip: rect(0, 0, 0, 0);
    white-space: nowrap;
    border: 0;
}

/* Custom input styling */
:deep(.p-inputtext) {
    transition: all 0.2s ease-in-out;
}

:deep(.p-inputtext:focus) {
    transform: translateY(-1px);
    box-shadow: 0 4px 12px rgba(59, 130, 246, 0.15);
    outline: 2px solid #3b82f6;
    outline-offset: 2px;
}

/* Custom button styling */
:deep(.p-button) {
    transition: all 0.2s ease-in-out;
}

:deep(.p-button:hover) {
    transform: translateY(-1px);
}

:deep(.p-button:focus) {
    outline: 2px solid #3b82f6;
    outline-offset: 2px;
}

:deep(.p-button:disabled) {
    transform: none;
    opacity: 0.6;
    cursor: not-allowed;
}

/* Custom checkbox styling */
:deep(.p-checkbox .p-checkbox-box) {
    border-color: #cbd5e1;
    transition: all 0.2s ease-in-out;
}

:deep(.p-checkbox .p-checkbox-box:hover) {
    border-color: #3b82f6;
}

:deep(.p-checkbox .p-checkbox-box:focus) {
    outline: 2px solid #3b82f6;
    outline-offset: 2px;
}

/* Enhanced focus indicators for links */
a:focus {
    outline: 2px solid #3b82f6;
    outline-offset: 2px;
    border-radius: 4px;
}

/* High contrast mode support */
@media (prefers-contrast: high) {
    :deep(.p-inputtext) {
        border-width: 2px;
    }
    
    :deep(.p-button) {
        border-width: 2px;
    }
}

/* Reduced motion support */
@media (prefers-reduced-motion: reduce) {
    :deep(.p-inputtext),
    :deep(.p-button),
    :deep(.p-checkbox .p-checkbox-box) {
        transition: none;
    }
    
    :deep(.p-inputtext:focus),
    :deep(.p-button:hover) {
        transform: none;
    }
}
</style>