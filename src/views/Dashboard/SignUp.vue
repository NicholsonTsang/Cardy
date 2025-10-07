<template>
    <div class="min-h-screen bg-gradient-to-br from-slate-50 via-blue-50 to-indigo-100 flex items-center justify-center p-4">
        <div class="w-full max-w-md">
            <!-- Main Card -->
            <div class="bg-white rounded-2xl shadow-xl border border-slate-200 overflow-hidden">
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
                    <h1 class="text-2xl font-bold text-slate-900 mb-2">Create Your Account</h1>
                    <p class="text-slate-600">Join CardStudio CMS to start creating digital cards</p>
                </div>
                <!-- Form Section -->
                <div class="px-8 pb-8">
                    <!-- Email Form -->
                    <form @submit.prevent="handleSignUp" class="space-y-5">
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
                            <!-- Password Strength Indicator -->
                            <div v-if="password" class="space-y-1">
                                <div class="flex items-center space-x-1">
                                    <div class="h-1 flex-1 rounded-full" :class="passwordStrength.color"></div>
                                    <div class="h-1 flex-1 rounded-full" :class="passwordStrength.level >= 2 ? passwordStrength.color : 'bg-slate-200'"></div>
                                    <div class="h-1 flex-1 rounded-full" :class="passwordStrength.level >= 3 ? passwordStrength.color : 'bg-slate-200'"></div>
                                    <div class="h-1 flex-1 rounded-full" :class="passwordStrength.level >= 4 ? passwordStrength.color : 'bg-slate-200'"></div>
                                </div>
                                <p class="text-xs" :class="passwordStrength.textColor">{{ passwordStrength.text }}</p>
                            </div>
                        </div>

                        <!-- Confirm Password Field -->
                        <div class="space-y-2">
                            <label for="confirmPassword" class="block text-sm font-medium text-slate-700">Confirm Password</label>
                            <InputText 
                                id="confirmPassword" 
                                v-model="confirmPassword" 
                                type="password" 
                                placeholder="Confirm your password" 
                                class="w-full px-4 py-3 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-colors"
                                :class="{ 'border-red-300 focus:ring-red-500 focus:border-red-500': confirmPasswordError }"
                                required 
                            />
                            <p v-if="confirmPasswordError" class="text-sm text-red-600">{{ confirmPasswordError }}</p>
                        </div>

                        <!-- Error Message -->
                        <Message v-if="errorMessage" severity="error" :closable="false" class="mb-4">
                            {{ errorMessage }}
                        </Message>

                        <!-- Terms Agreement -->
                        <div class="flex items-start space-x-3">
                            <Checkbox 
                                id="terms" 
                                v-model="agreeToTerms" 
                                :binary="true" 
                                class="mt-1"
                                aria-describedby="terms-description"
                            />
                            <label for="terms" class="text-sm text-slate-600 leading-relaxed" id="terms-description">
                                I agree to the 
                                <a href="#" 
                                   class="text-blue-600 hover:text-blue-800 font-medium transition-colors"
                                   aria-label="Read our Terms of Service"
                                   @keydown.enter.prevent="$event.target.click()">Terms of Service</a> 
                                and 
                                <a href="#" 
                                   class="text-blue-600 hover:text-blue-800 font-medium transition-colors"
                                   aria-label="Read our Privacy Policy"
                                   @keydown.enter.prevent="$event.target.click()">Privacy Policy</a>
                            </label>
                        </div>

                        <!-- Submit Button -->
                        <Button 
                            type="submit" 
                            label="Create Account" 
                            severity="primary"
                            class="w-full py-3 border-0 shadow-lg hover:shadow-xl transition-all duration-200" 
                            :style="{
                                background: 'linear-gradient(to right, #2563eb, #4f46e5)',
                                borderColor: 'transparent'
                            }"
                            :loading="isLoading"
                            :disabled="!agreeToTerms || !isFormValid"
                            :aria-label="isLoading ? 'Creating your account...' : 'Create your new account'"
                            aria-describedby="submit-requirements"
                        />
                        <div id="submit-requirements" class="sr-only">Complete all fields and agree to terms to create account</div>
                    </form>

                    <!-- Sign In Link -->
                    <div class="mt-8 text-center">
                        <p class="text-slate-600">
                            Already have an account? 
                            <a @click="goToSignIn" class="text-blue-600 hover:text-blue-800 font-medium cursor-pointer transition-colors">
                                Sign in here
                            </a>
                        </p>
                    </div>
                </div>
            </div>
        </div>
    </div>
</template>

<script setup>
import Button from 'primevue/button';
import Checkbox from 'primevue/checkbox';
import InputText from 'primevue/inputtext';
import Message from 'primevue/message';
import { ref, computed } from 'vue';
import { useAuthStore } from '@/stores/auth.js';
import { useRouter } from 'vue-router';

const email = ref('');
const password = ref('');
const confirmPassword = ref('');
const agreeToTerms = ref(false);

const authStore = useAuthStore();
const router = useRouter();

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
    return password.value.length < 8 ? 'Password must be at least 8 characters' : '';
});

const confirmPasswordError = computed(() => {
    if (!confirmPassword.value) return '';
    return password.value !== confirmPassword.value ? 'Passwords do not match' : '';
});

const isFormValid = computed(() => {
    return email.value && 
           password.value && 
           confirmPassword.value && 
           !emailError.value && 
           !passwordError.value && 
           !confirmPasswordError.value;
});

const passwordStrength = computed(() => {
    const pwd = password.value;
    if (!pwd) return { level: 0, text: '', color: '', textColor: '' };
    
    let score = 0;
    const checks = {
        length: pwd.length >= 8,
        lowercase: /[a-z]/.test(pwd),
        uppercase: /[A-Z]/.test(pwd),
        numbers: /\d/.test(pwd),
        special: /[!@#$%^&*(),.?":{}|<>]/.test(pwd)
    };
    
    score = Object.values(checks).filter(Boolean).length;
    
    const levels = {
        1: { text: 'Very weak', color: 'bg-red-500', textColor: 'text-red-600' },
        2: { text: 'Weak', color: 'bg-orange-500', textColor: 'text-orange-600' },
        3: { text: 'Fair', color: 'bg-yellow-500', textColor: 'text-yellow-600' },
        4: { text: 'Good', color: 'bg-blue-500', textColor: 'text-blue-600' },
        5: { text: 'Strong', color: 'bg-green-500', textColor: 'text-green-600' }
    };
    
    return { level: score, ...levels[score] || levels[1] };
});

async function handleSignUp() {
    // Clear previous errors
    errorMessage.value = '';
    
    // Validate form
    if (emailError.value || passwordError.value || confirmPasswordError.value) {
        errorMessage.value = 'Please fix the errors above';
        return;
    }
    
    if (!agreeToTerms.value) {
        errorMessage.value = 'Please agree to the Terms of Service and Privacy Policy';
        return;
    }
    
    isLoading.value = true;
    try {
        await authStore.signUpWithEmail(email.value, password.value);
        // Message is shown by the auth store
        // router.push('/login'); // Or a "check your email" page
    } catch (error) {
        errorMessage.value = error.message || 'Failed to create account. Please try again.';
        console.error('Sign up error:', error);
    } finally {
        isLoading.value = false;
    }
}

function goToSignIn() {
  router.push('/login');
}
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

:deep(.p-checkbox.p-checkbox-checked .p-checkbox-box) {
    background-color: #3b82f6;
    border-color: #3b82f6;
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
    
    :deep(.p-checkbox .p-checkbox-box) {
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

/* Password strength indicator accessibility */
[role="status"] {
    border: none;
    clip: auto;
    width: auto;
    height: auto;
    margin: 0;
    overflow: visible;
    position: static;
    white-space: normal;
}
</style>
