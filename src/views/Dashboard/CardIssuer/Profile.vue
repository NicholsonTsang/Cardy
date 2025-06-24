<template>
    <div class="container mx-auto px-4 py-6">
        <ConfirmDialog />
        
        <!-- Loading State -->
        <div v-if="store.loading" class="flex justify-center items-center min-h-screen">
            <ProgressSpinner />
        </div>

        <!-- No Profile - Create Basic Profile -->
        <div v-else-if="!store.hasBasicProfile && !store.isEditMode" class="max-w-2xl mx-auto">
            <WelcomeSection @start-profile="store.startEdit" />
                    </div>
                    
        <!-- Edit Profile Form -->
        <div v-else-if="store.isEditMode" class="max-w-2xl mx-auto">
            <BasicProfileForm @save="handleSaveProfile" @cancel="store.cancelEdit" />
                    </div>
                    
        <!-- Verification Form -->
        <div v-else-if="store.isVerificationMode" class="max-w-2xl mx-auto">
            <VerificationForm @submit="handleSubmitVerification" @cancel="store.cancelEdit" />
                    </div>
                    
        <!-- Profile Display -->
        <div v-else class="max-w-4xl mx-auto">
            <ProfileDisplay />
        </div>
    </div>
</template>

<script setup>
import { onMounted } from 'vue'
import ConfirmDialog from 'primevue/confirmdialog'
import ProgressSpinner from 'primevue/progressspinner'
import { useProfileStore } from '@/stores/profile'
import WelcomeSection from '@/components/Profile/WelcomeSection.vue'
import BasicProfileForm from '@/components/Profile/BasicProfileForm.vue'
import VerificationForm from '@/components/Profile/VerificationForm.vue'
import ProfileDisplay from '@/components/Profile/ProfileDisplay.vue'

const store = useProfileStore()

onMounted(async () => {
    await store.fetchProfile()
})

const handleSaveProfile = async (formData) => {
    await store.saveBasicProfile(formData)
}

const handleSubmitVerification = async (formData) => {
    await store.submitVerification(formData)
}
</script>