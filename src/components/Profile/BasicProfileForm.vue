<template>
    <div class="bg-white rounded-xl shadow-lg border border-slate-200 overflow-hidden">
        <div class="p-6 border-b border-slate-200">
            <h2 class="text-2xl font-bold text-slate-900">{{ isEdit ? 'Edit Profile' : 'Create Your Profile' }}</h2>
            <p class="text-slate-600 mt-2">{{ isEdit ? 'Update your basic information' : 'Tell us a bit about yourself' }}</p>
        </div>

        <form @submit.prevent="handleSubmit" class="p-6 space-y-6">
            <!-- Public Display Name -->
            <div>
                <label for="public_name" class="block text-sm font-medium text-slate-700 mb-2">
                    Display Name <span class="text-red-500">*</span>
                </label>
                <InputText
                    id="public_name"
                    v-model="form.public_name"
                    placeholder="How should others see your name?"
                    class="w-full"
                    :class="{ 'p-invalid': errors.public_name }"
                />
                <small class="text-slate-500 mt-1 block">This is how your name will appear publicly on your cards</small>
                <small v-if="errors.public_name" class="p-error">{{ errors.public_name }}</small>
            </div>

            <!-- Bio/Description -->
            <div>
                <label for="bio" class="block text-sm font-medium text-slate-700 mb-2">
                    About You <span class="text-red-500">*</span>
                </label>
                <Textarea
                    id="bio"
                    v-model="form.bio"
                    placeholder="Tell us about yourself, your work, or your interests..."
                    rows="4"
                    class="w-full"
                    :class="{ 'p-invalid': errors.bio }"
                />
                <small class="text-slate-500 mt-1 block">This will help people understand who you are and what you do</small>
                <small v-if="errors.bio" class="p-error">{{ errors.bio }}</small>
            </div>

            <!-- Company Name (Optional) -->
            <div>
                <label for="company_name" class="block text-sm font-medium text-slate-700 mb-2">
                    Company/Organization <span class="text-slate-400">(Optional)</span>
                </label>
                <InputText
                    id="company_name"
                    v-model="form.company_name"
                    placeholder="Company or organization name"
                    class="w-full"
                />
                <small class="text-slate-500 mt-1 block">If you represent a company or organization</small>
            </div>

            <!-- Action Buttons -->
            <div class="flex justify-end gap-3 pt-4 border-t border-slate-200">
                <Button
                    label="Cancel"
                    severity="secondary"
                    outlined
                    @click="emit('cancel')"
                    type="button"
                />
                <Button
                    :label="isEdit ? 'Save Changes' : 'Create Profile'"
                    :loading="loading"
                    type="submit"
                    class="px-6"
                />
            </div>
        </form>
    </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue'
import InputText from 'primevue/inputtext'
import Textarea from 'primevue/textarea'
import Button from 'primevue/button'
import { useProfileStore } from '@/stores/profile'

const props = defineProps({
    loading: {
        type: Boolean,
        default: false
    }
})

const emit = defineEmits(['save', 'cancel'])
const store = useProfileStore()

const isEdit = ref(false)
const form = reactive({
    public_name: '',
    bio: '',
    company_name: ''
})

const errors = reactive({
    public_name: '',
    bio: ''
})

onMounted(() => {
    if (store.profile && store.hasBasicProfile) {
        isEdit.value = true
        form.public_name = store.profile.public_name || ''
        form.bio = store.profile.bio || ''
        form.company_name = store.profile.company_name || ''
    }
})

const validateForm = () => {
    errors.public_name = ''
    errors.bio = ''

    if (!form.public_name?.trim()) {
        errors.public_name = 'Display name is required'
    }

    if (!form.bio?.trim()) {
        errors.bio = 'About section is required'
    }

    return !errors.public_name && !errors.bio
}

const handleSubmit = () => {
    if (validateForm()) {
        emit('save', {
            public_name: form.public_name.trim(),
            bio: form.bio.trim(),
            company_name: form.company_name?.trim() || ''
        })
    }
}
</script> 