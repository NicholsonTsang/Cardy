<template>
    <div class="px-6 py-20 md:px-12 lg:px-20 flex items-center justify-center bg-surface-50 dark:bg-surface-950 min-h-screen">
        <div class="max-w-xl w-full flex flex-col items-start gap-8 bg-surface-0 dark:bg-surface-900 p-12 rounded-3xl shadow-[0px_24px_48px_0px_rgba(0,0,0,0.04)]">
            <div class="flex flex-col items-center gap-6 w-full">
                <div class="p-3 border border-surface-200 dark:border-surface-700 rounded-full">
                     <svg xmlns="http://www.w3.org/2000/svg" class="h-10 w-10" width="33" height="32" viewBox="0 0 33 32" fill="none">
                        <path
                            fill-rule="evenodd"
                            clip-rule="evenodd"
                            d="M7.09219 2.87829C5.94766 3.67858 4.9127 4.62478 4.01426 5.68992C7.6857 5.34906 12.3501 5.90564 17.7655 8.61335C23.5484 11.5047 28.205 11.6025 31.4458 10.9773C31.1517 10.087 30.7815 9.23135 30.343 8.41791C26.6332 8.80919 21.8772 8.29127 16.3345 5.51998C12.8148 3.76014 9.71221 3.03521 7.09219 2.87829ZM28.1759 5.33332C25.2462 2.06 20.9887 0 16.25 0C14.8584 0 13.5081 0.177686 12.2209 0.511584C13.9643 0.987269 15.8163 1.68319 17.7655 2.65781C21.8236 4.68682 25.3271 5.34013 28.1759 5.33332ZM32.1387 14.1025C28.2235 14.8756 22.817 14.7168 16.3345 11.4755C10.274 8.44527 5.45035 8.48343 2.19712 9.20639C2.0292 9.24367 1.86523 9.28287 1.70522 9.32367C1.2793 10.25 0.939308 11.2241 0.695362 12.2356C0.955909 12.166 1.22514 12.0998 1.50293 12.0381C5.44966 11.161 11.0261 11.1991 17.7655 14.5689C23.8261 17.5991 28.6497 17.561 31.9029 16.838C32.0144 16.8133 32.1242 16.7877 32.2322 16.7613C32.2441 16.509 32.25 16.2552 32.25 16C32.25 15.358 32.2122 14.7248 32.1387 14.1025ZM31.7098 20.1378C27.8326 20.8157 22.5836 20.5555 16.3345 17.431C10.274 14.4008 5.45035 14.439 2.19712 15.1619C1.475 15.3223 0.825392 15.5178 0.252344 15.7241C0.250782 15.8158 0.25 15.9078 0.25 16C0.25 24.8366 7.41344 32 16.25 32C23.6557 32 29.8862 26.9687 31.7098 20.1378Z"
                            class="fill-surface-700 dark:fill-surface-200"
                        />
                    </svg>
                </div>
                <h1 class="text-center text-2xl font-medium text-surface-900 dark:text-surface-0 leading-tight w-full">Create an Account</h1>
            </div>
            <div class="flex items-center gap-4 w-full">
                 <Button @click="handleGoogleSignUp" :disabled="isLoading" outlined icon="pi pi-google !text-base !leading-none" severity="secondary" class="!flex-1 !py-2 !text-surface-900 dark:!text-surface-0" label="Sign Up with Google"/>
                <!-- Add other OAuth providers if needed -->
            </div>
            <div class="flex items-center gap-2 w-full">
                <div class="h-px flex-1 bg-surface-200 dark:bg-surface-800" />
                <div class="text-surface-700 dark:text-surface-300 font-bold">or</div>
                <div class="h-px flex-1 bg-surface-200 dark:bg-surface-800" />
            </div>
            <form @submit.prevent="handleSignUp" class="flex flex-col gap-6 w-full">
                <div class="flex flex-col gap-2">
                    <label for="email" class="text-surface-900 dark:text-surface-0 font-medium">Email Address</label>
                    <InputText id="email" v-model="email" type="email" placeholder="Email Address" class="p-3 shadow-sm dark:!bg-surface-900" required />
                </div>
                <div class="flex flex-col gap-2">
                    <label for="password" class="text-surface-900 dark:text-surface-0 font-medium">Password</label>
                    <InputText id="password" v-model="password" type="password" placeholder="Password" class="p-3 shadow-sm dark:!bg-surface-900" required />
                </div>
                <div class="flex flex-col gap-2">
                    <label for="confirmPassword" class="text-surface-900 dark:text-surface-0 font-medium">Confirm Password</label>
                    <InputText id="confirmPassword" v-model="confirmPassword" type="password" placeholder="Confirm Password" class="p-3 shadow-sm dark:!bg-surface-900" required />
                </div>
                <Message v-if="errorMessage" severity="error" :closable="false">{{ errorMessage }}</Message>
                <div class="flex flex-col gap-10 w-full">
                    <Button type="submit" label="Create Account" class="w-full" :loading="isLoading" />
                    <div class="text-center w-full">
                        <span class="text-surface-900 dark:text-surface-0 font-medium">Already have an account? </span>
                        <a @click="goToSignIn" class="text-primary font-medium cursor-pointer hover:text-primary-emphasis">Sign In!</a>
                    </div>
                </div>
            </form>
        </div>
    </div>
</template>

<script setup>
import Button from 'primevue/button';
import InputText from 'primevue/inputtext';
import Message from 'primevue/message';
import { ref } from 'vue';
import { useAuthStore } from '@/stores/auth';
import { useRouter } from 'vue-router';

const email = ref('');
const password = ref('');
const confirmPassword = ref('');

const authStore = useAuthStore();
const router = useRouter();

const isLoading = ref(false);
const errorMessage = ref('');

async function handleSignUp() {
  if (password.value !== confirmPassword.value) {
    errorMessage.value = 'Passwords do not match.';
    return;
  }
  isLoading.value = true;
  errorMessage.value = '';
  try {
    await authStore.signUpWithEmail(email.value, password.value);
    // Message is shown by the auth store
    // router.push('/login'); // Or a "check your email" page
  } catch (error) {
    errorMessage.value = error.message || 'Failed to sign up.';
    console.error('Sign up error:', error);
  } finally {
    isLoading.value = false;
  }
}

async function handleGoogleSignUp() {
  isLoading.value = true;
  errorMessage.value = '';
  try {
    await authStore.signInWithGoogle(); // Same flow for sign up and sign in with OAuth
    // Supabase handles redirect
  } catch (error) {
    errorMessage.value = error.message || 'Failed to sign up with Google.';
    console.error('Google sign up error:', error);
  } finally {
    // isLoading might not be reset here if redirect happens quickly
  }
}

function goToSignIn() {
  router.push('/login');
}
</script>
