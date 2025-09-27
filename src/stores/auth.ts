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

    console.log('Auth state change:', event, newSession?.user)

    if (event === 'SIGNED_OUT') {
      router.push('/login')
    }
    // Remove automatic redirect - let router guard handle it
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
    
    // Check if user was created successfully
    if (data.user) {
      // Fallback: Ensure user has cardIssuer role if trigger didn't work
      if (data.user.email_confirmed_at) {
        // User is already confirmed, check if they have a role
        const hasRole = data.user.user_metadata?.role
        if (!hasRole) {
          console.warn('New user created without role, trigger may not be working')
          // Try to set the role manually (this might not work due to RLS)
          try {
            await supabase.auth.updateUser({
              data: { role: 'cardIssuer' }
            })
            console.log('Manually set role to cardIssuer for new user')
          } catch (roleError) {
            console.error('Failed to set role manually:', roleError)
          }
        }
        toast.add({ severity: 'success', summary: 'Sign Up Successful', detail: 'Your account is already verified. Redirecting...', group: 'br', life: 3000 })
        
        // Force session refresh to get updated user metadata
        await refreshSession()
        // Redirect to appropriate default page based on user role
        redirectToDefaultPage()
      } else {
        toast.add({ severity: 'success', summary: 'Sign Up Successful', detail: 'Please check your email to verify your account.', group: 'br', life: 5000 })
      }
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
      // Force session refresh to get updated user metadata
      await refreshSession()
      toast.add({ severity: 'success', summary: 'Sign In Successful', detail: 'Welcome back!', group: 'br', life: 3000 })
      
      // Redirect to appropriate default page based on user role
      redirectToDefaultPage()
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
        redirectTo: `${window.location.origin}/login?oauth=success` // Redirect back to login with success flag
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
    return !!session.value?.user
  }

  const isEmailVerified = () => {
    console.log('isEmailVerified', session.value?.user?.email_confirmed_at)
    return !!session.value?.user?.email_confirmed_at
  }

  async function refreshSession() {
    console.log('Refreshing session to get updated user metadata...')
    const { data, error } = await supabase.auth.refreshSession()
    if (error) {
      console.error('Error refreshing session:', error)
      throw error
    }
    session.value = data.session
    user.value = data.session?.user ?? null
    console.log('Session refreshed, new user metadata:', data.session?.user?.user_metadata)
    return data.session
  }

  async function getUserRoleFromDatabase() {
    if (!session.value?.user?.id) return null
    
    try {
      const { data, error } = await supabase.rpc('get_user_role', { 
        user_id: session.value.user.id 
      })
      if (error) {
        console.error('Error getting user role from database:', error)
        return null
      }
      console.log('User role from database:', data)
      return data
    } catch (err) {
      console.error('Error calling get_user_role:', err)
      return null
    }
  }

  function getUserRole(): string | undefined {
    const user = session.value?.user
    if (!user) return undefined
    
    // Check both app_metadata and user_metadata for role
    let role = user.app_metadata?.role || user.user_metadata?.role
    
    // Handle both cardIssuer and card_issuer formats for backward compatibility
    if (role === 'card_issuer') return 'cardIssuer'
    
    // If no role is found and user is logged in, assume cardIssuer (default role)
    if (!role && user) {
      console.warn('No role found for logged in user, defaulting to cardIssuer')
      return 'cardIssuer'
    }
    
    return role
  }

  function redirectToDefaultPage() {
    const userRole = getUserRole()
    console.log('Redirecting user with role:', userRole)
    
    if (userRole === 'admin') {
      router.push({ name: 'admin-dashboard' })
    } else if (userRole === 'cardIssuer') {
      router.push({ name: 'mycards' })
    } else {
      // Default fallback to mycards for most users
      router.push({ name: 'mycards' })
    }
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
    initialize,
    refreshSession,
    getUserRoleFromDatabase
  }
}) 