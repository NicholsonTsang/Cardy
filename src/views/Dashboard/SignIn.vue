<template>
    <div class="min-h-screen bg-gradient-to-br from-slate-50 via-blue-50 to-indigo-100 flex items-center justify-center p-4">
        <div class="w-full max-w-md">
            <!-- Main Card -->
            <main class="bg-white rounded-2xl shadow-xl border border-slate-200 overflow-hidden" role="main" aria-labelledby="signin-title">
                <!-- Header Section -->
                <div class="px-8 pt-8 pb-6 text-center">
                    <div class="inline-flex items-center justify-center w-16 h-16 bg-gradient-to-r from-blue-600 to-indigo-600 rounded-2xl mb-6 shadow-lg">
                        <svg xmlns="http://www.w3.org/2000/svg" class="h-8 w-8 text-white" width="33" height="32" viewBox="0 0 33 32" fill="none">
                            <path
                                fill-rule="evenodd"
                                clip-rule="evenodd"
                                d="M7.09219 2.87829C5.94766 3.67858 4.9127 4.62478 4.01426 5.68992C7.6857 5.34906 12.3501 5.90564 17.7655 8.61335C23.5484 11.5047 28.205 11.6025 31.4458 10.9773C31.1517 10.087 30.7815 9.23135 30.343 8.41791C26.6332 8.80919 21.8772 8.29127 16.3345 5.51998C12.8148 3.76014 9.71221 3.03521 7.09219 2.87829ZM28.1759 5.33332C25.2462 2.06 20.9887 0 16.25 0C14.8584 0 13.5081 0.177686 12.2209 0.511584C13.9643 0.987269 15.8163 1.68319 17.7655 2.65781C21.8236 4.68682 25.3271 5.34013 28.1759 5.33332ZM32.1387 14.1025C28.2235 14.8756 22.817 14.7168 16.3345 11.4755C10.274 8.44527 5.45035 8.48343 2.19712 9.20639C2.0292 9.24367 1.86523 9.28287 1.70522 9.32367C1.2793 10.25 0.939308 11.2241 0.695362 12.2356C0.955909 12.166 1.22514 12.0998 1.50293 12.0381C5.44966 11.161 11.0261 11.1991 17.7655 14.5689C23.8261 17.5991 28.6497 17.561 31.9029 16.838C32.0144 16.8133 32.1242 16.7877 32.2322 16.7613C32.2441 16.509 32.25 16.2552 32.25 16C32.25 15.358 32.2122 14.7248 32.1387 14.1025ZM31.7098 20.1378C27.8326 20.8157 22.5836 20.5555 16.3345 17.431C10.274 14.4008 5.45035 14.439 2.19712 15.1619C1.475 15.3223 0.825392 15.5178 0.252344 15.7241C0.250782 15.8158 0.25 15.9078 0.25 16C0.25 24.8366 7.41344 32 16.25 32C23.6557 32 29.8862 26.9687 31.7098 20.1378Z"
                                fill="currentColor"
                            />
                        </svg>
                    </div>
                    <h1 id="signin-title" class="text-2xl font-bold text-slate-900 mb-2">Welcome Back</h1>
                    <p class="text-slate-600" id="signin-description">Sign in to your CardStudio CMS account</p>
                </div>

                <!-- Form Section -->
                <div class="px-8 pb-8">
                    <!-- Social Login -->
                    <div class="mb-6">
                        <Button 
                            @click="handleGoogleSignIn" 
                            :disabled="isLoading" 
                            outlined 
                            icon="pi pi-google" 
                            severity="secondary" 
                            class="w-full py-3 border-slate-300 hover:border-blue-400 hover:bg-blue-50 transition-all duration-200"
                            label="Continue with Google"
                            :aria-label="isLoading ? 'Signing in with Google...' : 'Sign in with Google'"
                        />
                    </div>

                    <!-- Divider -->
                    <div class="relative mb-6">
                        <div class="absolute inset-0 flex items-center">
                            <div class="w-full border-t border-slate-200"></div>
                        </div>
                        <div class="relative flex justify-center text-sm">
                            <span class="px-4 bg-white text-slate-500 font-medium">or continue with email</span>
                        </div>
                    </div>

                    <!-- Email Form -->
                    <form @submit.prevent="handleSignIn" class="space-y-5">
                        <!-- Email Field -->
                        <div class="space-y-2">
                            <label for="email" class="block text-sm font-medium text-slate-700">Email Address</label>
                            <InputText 
                                id="email" 
                                v-model="email" 
                                type="email" 
                                placeholder="Enter your email" 
                                class="w-full px-4 py-3 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-colors"
                                :class="{ 'border-red-300 focus:ring-red-500 focus:border-red-500': emailError }"
                                required 
                            />
                            <p v-if="emailError" class="text-sm text-red-600">{{ emailError }}</p>
                        </div>

                        <!-- Password Field -->
                        <div class="space-y-2">
                            <label for="password" class="block text-sm font-medium text-slate-700">Password</label>
                            <InputText 
                                id="password" 
                                v-model="password" 
                                type="password" 
                                placeholder="Enter your password" 
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
                                <label for="rememberme" class="text-sm text-slate-600">Remember me</label>
                            </div>
                            <a href="#" class="text-sm text-blue-600 hover:text-blue-800 font-medium transition-colors">
                                Forgot password?
                            </a>
                        </div>

                        <!-- Submit Button -->
                        <Button 
                            type="submit" 
                            label="Sign In" 
                            severity="primary"
                            class="w-full py-3 border-0 shadow-lg hover:shadow-xl transition-all duration-200" 
                            :style="{
                                background: 'linear-gradient(to right, #2563eb, #4f46e5)',
                                borderColor: 'transparent'
                            }"
                            :loading="isLoading" 
                        />
                    </form>

                    <!-- Sign Up Link -->
                    <div class="mt-8 text-center">
                        <p class="text-slate-600">
                            Don't have an account? 
                            <a @click="goToSignUp" class="text-blue-600 hover:text-blue-800 font-medium cursor-pointer transition-colors">
                                Create one today
                            </a>
                        </p>
                    </div>
                </div>
            </main>

            <!-- Footer -->
            <footer class="mt-8 text-center" role="contentinfo">
                <p class="text-sm text-slate-500">
                    By signing in, you agree to our 
                    <a href="#" 
                       class="text-blue-600 hover:text-blue-800 transition-colors"
                       aria-label="Read our Terms of Service"
                       @keydown.enter.prevent="$event.target.click()">Terms of Service</a> 
                    and 
                    <a href="#" 
                       class="text-blue-600 hover:text-blue-800 transition-colors"
                       aria-label="Read our Privacy Policy"
                       @keydown.enter.prevent="$event.target.click()">Privacy Policy</a>
                </p>
            </footer>
        </div>
    </div>
</template>

<script setup>
import Button from 'primevue/button';
import Checkbox from 'primevue/checkbox';
import InputText from 'primevue/inputtext';
import Message from 'primevue/message';
import { ref, computed, onMounted } from 'vue';
import { useAuthStore } from '@/stores/auth.js';
import { useRouter, useRoute } from 'vue-router';

const email = ref('');
const password = ref('');
const rememberMe = ref(false);

const authStore = useAuthStore();
const router = useRouter();
const route = useRoute();

const isLoading = ref(false);
const errorMessage = ref('');

// Form validation
const emailError = computed(() => {
    if (!email.value) return '';
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return !emailRegex.test(email.value) ? 'Please enter a valid email address' : '';
});

const passwordError = computed(() => {
    if (!password.value) return '';
    return password.value.length < 6 ? 'Password must be at least 6 characters' : '';
});

async function handleSignIn() {
    // Clear previous errors
    errorMessage.value = '';
    
    // Validate form
    if (emailError.value || passwordError.value) {
        errorMessage.value = 'Please fix the errors above';
        return;
    }

    isLoading.value = true;
    try {
        await authStore.signInWithEmail(email.value, password.value);
    } catch (error) {
        errorMessage.value = error.message || 'Failed to sign in. Please check your credentials.';
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
        errorMessage.value = error.message || 'Failed to sign in with Google.';
        console.error('Google sign in error:', error);
    } finally {
        isLoading.value = false;
    }
}

function goToSignUp() {
    router.push('/signup');
}

// Handle OAuth callback
onMounted(async () => {
    const oauthSuccess = route.query.oauth;
    if (oauthSuccess === 'success' && authStore.isLoggedIn() && authStore.isEmailVerified()) {
        // User has successfully signed in via OAuth, redirect to their default page
        await authStore.refreshSession();
        
        // Get user role and redirect
        const user = authStore.session?.user;
        const role = user?.app_metadata?.role || user?.user_metadata?.role || user?.raw_user_meta_data?.role;
        const userRole = role === 'card_issuer' ? 'cardIssuer' : role;
        
        if (userRole === 'admin') {
            router.push({ name: 'admin-dashboard' });
        } else {
            router.push({ name: 'mycards' });
        }
    }
});
</script>

<style scoped>
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