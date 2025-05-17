import { defineStore } from 'pinia'
import { supabase } from '@/lib/supabase'
import type { Session, User } from '@supabase/supabase-js'
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { useToast } from 'primevue/usetoast'

export const useAuthStore = defineStore('auth', () => {
  const user = ref<User | null>(null)
  const session = ref<Session | null>(null)
  const loading = ref(true) // Indicates if initial auth state is being loaded
  const router = useRouter()
  const toast = useToast()

  async function initialize() {
    loading.value = true
    const { data: { session: currentSession }, error } = await supabase.auth.getSession()
    if (error) {
      console.error('Error getting session:', error.message)
    } else {
      session.value = currentSession
      user.value = currentSession?.user ?? null
    }
    loading.value = false
  }


  supabase.auth.onAuthStateChange((event, newSession) => {
    session.value = newSession
    user.value = newSession?.user ?? null
    loading.value = false // Ensure loading is false after any auth state change

    if (event === 'SIGNED_OUT') {
      router.push('/login')
    } else if (event === 'SIGNED_IN' && newSession?.user) {
      // Redirection logic is now more robustly handled in router.beforeEach
      // and within specific auth functions like signInWithEmail.
    }
  })

  async function signUpWithEmail(email_value: string, password_value: string) {
    loading.value = true
    const { data, error } = await supabase.auth.signUp({
      email: email_value,
      password: password_value,
    })
    loading.value = false
    if (error) {
      console.error('Sign up error:', error.message)
      toast.add({ severity: 'error', summary: 'Sign Up Failed', detail: error.message, group: 'br', life: 3000 })
      throw error
    }
    if (data.user && !data.user.email_confirmed_at) {
        toast.add({ severity: 'success', summary: 'Sign Up Successful', detail: 'Please check your email to verify your account.', group: 'br', life: 5000 })
    } else if (data.user && data.user.email_confirmed_at) {
        toast.add({ severity: 'success', summary: 'Sign Up Successful', detail: 'Your account is already verified. Redirecting...', group: 'br', life: 3000 })
        router.push('/cms/mycards')
    }
    return data
  }

  async function signInWithEmail(email_value: string, password_value: string) {
    loading.value = true
    const { data, error } = await supabase.auth.signInWithPassword({
      email: email_value,
      password: password_value,
    })
    loading.value = false
    if (error) {
      console.error('Sign in error:', error.message)
      toast.add({ severity: 'error', summary: 'Sign In Failed', detail: error.message || 'Invalid credentials.', group: 'br', life: 3000 })
      throw error
    }
    if (data.user && data.user.email_confirmed_at) {
      // No toast needed here, router will redirect. Or a success toast if preferred.
      // toast.add({ severity: 'success', summary: 'Sign In Successful', detail: 'Redirecting...', group: 'br', life: 3000 })
      router.push('/cms/mycards')
    } else if (data.user && !data.user.email_confirmed_at) {
      toast.add({ severity: 'warn', summary: 'Email Not Verified', detail: 'Login successful, but your email is not verified. Please check your email.', group: 'br', life: 5000 })
      // User will be redirected to /login by the router guard if they try to access /cms
    }
    return data
  }

  async function signInWithGoogle() {
    loading.value = true
    const { error } = await supabase.auth.signInWithOAuth({
      provider: 'google',
      options: {
        redirectTo: `${window.location.origin}/cms/mycards` // Or a specific callback page
      }
    })
    loading.value = false // Will be set again by onAuthStateChange
    if (error) {
      console.error('Google sign in error:', error.message)
      toast.add({ severity: 'error', summary: 'Google Sign In Failed', detail: error.message, group: 'br', life: 3000 })
      throw error
    }
  }

  async function signOut() {
    loading.value = true
    const { error } = await supabase.auth.signOut()
    loading.value = false
    if (error) {
      console.error('Sign out error:', error.message)
      toast.add({ severity: 'error', summary: 'Sign Out Failed', detail: error.message, group: 'br', life: 3000 })
      throw error
    }
    user.value = null
    session.value = null
    router.push('/login')
  }

  const isLoggedIn = () => {
    return !!user.value && !!session.value
  }

  const isEmailVerified = () => {
    console.log('isEmailVerified', user.value?.email_confirmed_at)
    return !!user.value?.email_confirmed_at
  }

  // Call initialize when the store is created
  // initialize(); // We will call this from the router guard to ensure it runs at the right time

  return {
    user,
    session,
    loading,
    signUpWithEmail,
    signInWithEmail,
    signInWithGoogle,
    signOut,
    isLoggedIn,
    isEmailVerified,
    initialize
  }
}) 