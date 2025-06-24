<template>
    <div class="bg-white rounded-xl shadow-lg border border-slate-200 overflow-hidden">
        <div class="p-6 border-b border-slate-200">
            <div class="flex items-center gap-3 mb-4">
                <div class="w-10 h-10 bg-gradient-to-r from-blue-500 to-indigo-500 rounded-full flex items-center justify-center">
                    <i class="pi pi-shield text-white"></i>
                </div>
                <div>
                    <h2 class="text-2xl font-bold text-slate-900">
                        {{ isEdit ? 'Edit Verification' : 'Identity Verification' }}
                    </h2>
                    <p class="text-slate-600">
                        {{ isEdit ? 'Update your verification information' : 'Verify your identity to get a blue checkmark' }}
                    </p>
                </div>
            </div>

            <div v-if="!isEdit" class="bg-blue-50 border border-blue-200 rounded-lg p-4">
                <div class="flex items-start gap-3">
                    <i class="pi pi-info-circle text-blue-600 mt-0.5"></i>
                    <div class="text-sm text-blue-800">
                        <p class="font-medium mb-1">Why verify your identity?</p>
                        <ul class="space-y-1 text-blue-700">
                            <li>• Get a blue checkmark on your profile</li>
                            <li>• Build trust with your audience</li>
                            <li>• Access premium features</li>
                        </ul>
                    </div>
                </div>
            </div>

            <!-- Edit Mode Info -->
            <div v-if="isEdit" class="bg-amber-50 border border-amber-200 rounded-lg p-4">
                <div class="flex items-start gap-3">
                    <i class="pi pi-exclamation-triangle text-amber-600 mt-0.5"></i>
                    <div class="text-sm text-amber-800">
                        <p class="font-medium mb-1">{{ store.verificationRejected ? 'Resubmitting Verification' : 'Updating Verification' }}</p>
                        <p class="text-amber-700">
                            {{ store.verificationRejected 
                                ? 'Please address the feedback and update your information below.' 
                                : 'Updating will reset your verification status to pending review.' }}
                        </p>
                    </div>
                </div>
            </div>
        </div>

        <form @submit.prevent="handleSubmit" class="p-6 space-y-6">
            <!-- Legal Name -->
            <div>
                <label for="full_name" class="block text-sm font-medium text-slate-700 mb-2">
                    Legal Name <span class="text-red-500">*</span>
                </label>
                <InputText
                    id="full_name"
                    v-model="form.full_name"
                    placeholder="Your full legal name as it appears on official documents"
                    class="w-full"
                    :class="{ 'p-invalid': errors.full_name }"
                />
                <small class="text-slate-500 mt-1 block">This is used for verification purposes only and will not be shown publicly</small>
                <small v-if="errors.full_name" class="p-error">{{ errors.full_name }}</small>
            </div>

            <!-- Supporting Documents -->
            <div>
                <label class="block text-sm font-medium text-slate-700 mb-2">
                    Supporting Documents <span class="text-red-500">*</span>
                </label>

                <!-- Existing Documents (in edit mode) -->
                <div v-if="isEdit && existingDocuments.length > 0" class="mb-4">
                    <h4 class="text-sm font-medium text-slate-700 mb-2">Current Documents:</h4>
                    <div class="space-y-2">
                        <div 
                            v-for="(doc, index) in existingDocuments" 
                            :key="index"
                            class="flex items-center justify-between bg-slate-50 rounded-lg p-3"
                        >
                            <div class="flex items-center gap-3">
                                <i class="pi pi-file text-slate-500"></i>
                                <div>
                                    <p class="text-sm font-medium text-slate-900">{{ getDocumentName(doc) }}</p>
                                    <p class="text-xs text-slate-500">Previously uploaded</p>
                                </div>
                            </div>
                            <div class="flex gap-2">
                                <Button
                                    icon="pi pi-eye"
                                    size="small"
                                    outlined
                                    @click="viewDocument(doc)"
                                    title="View document"
                                    type="button"
                                />
                                <Button
                                    icon="pi pi-times"
                                    size="small"
                                    outlined
                                    severity="danger"
                                    @click="removeExistingDocument(index)"
                                    title="Remove document"
                                    type="button"
                                />
                            </div>
                        </div>
                    </div>
                </div>
                
                <div class="border-2 border-dashed border-slate-300 rounded-lg p-6 text-center">
                    <input
                        ref="fileInput"
                        type="file"
                        multiple
                        @change="handleFileSelect"
                        class="hidden"
                        accept="*/*"
                    />
                    
                    <div class="mb-4">
                        <i class="pi pi-cloud-upload text-4xl text-slate-400 mb-2"></i>
                        <p class="text-slate-600 mb-2">
                            {{ isEdit && existingDocuments.length > 0 ? 'Add more documents' : 'Upload verification documents' }}
                        </p>
                        <p class="text-sm text-slate-500">Government ID, passport, business license, etc.</p>
                    </div>

                    <Button
                        :label="isEdit && existingDocuments.length > 0 ? 'Add More Files' : 'Choose Files'"
                        icon="pi pi-upload"
                        @click="fileInput?.click()"
                        outlined
                        type="button"
                    />
                </div>

                <!-- New File List -->
                <div v-if="selectedFiles.length > 0" class="mt-4 space-y-2">
                    <h4 class="text-sm font-medium text-slate-700">New Files:</h4>
                    <div 
                        v-for="(file, index) in selectedFiles" 
                        :key="index"
                        class="flex items-center justify-between bg-slate-50 rounded-lg p-3"
                    >
                        <div class="flex items-center gap-3">
                            <i :class="getFileIcon(file)" class="text-slate-500"></i>
                            <div>
                                <p class="text-sm font-medium text-slate-900">{{ getFileName(file) }}</p>
                                <p class="text-xs text-slate-500">{{ getFileSize(file) }}</p>
                            </div>
                        </div>
                        <Button
                            icon="pi pi-times"
                            size="small"
                            outlined
                            severity="danger"
                            @click="removeFile(index)"
                            type="button"
                        />
                    </div>
                </div>

                <small v-if="errors.supporting_documents" class="p-error">{{ errors.supporting_documents }}</small>
                <small class="text-slate-500 mt-1 block">All file formats accepted. Maximum 5MB per file.</small>
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
                    :label="isEdit ? 'Update Verification' : 'Submit for Review'"
                    :icon="isEdit ? 'pi pi-refresh' : 'pi pi-send'"
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
import Button from 'primevue/button'
import { getFileSize, getFileName, isImage } from '@/utils/fileTypes'
import { useProfileStore } from '@/stores/profile'

const props = defineProps({
    loading: {
        type: Boolean,
        default: false
    }
})

const emit = defineEmits(['submit', 'cancel'])
const store = useProfileStore()

const fileInput = ref(null)
const selectedFiles = ref([])
const existingDocuments = ref([])
const isEdit = ref(false)

const form = reactive({
    full_name: '',
    supporting_documents: []
})

const errors = reactive({
    full_name: '',
    supporting_documents: ''
})

onMounted(() => {
    // Check if we're editing existing verification
    if (store.hasVerificationData && store.canEditVerification) {
        isEdit.value = true
        form.full_name = store.profile?.full_name || ''
        existingDocuments.value = [...(store.profile?.supporting_documents || [])]
    }
})

const getDocumentName = (url) => {
    try {
        const urlParts = url.split('/')
        return urlParts[urlParts.length - 1] || 'Document'
    } catch {
        return 'Document'
    }
}

const viewDocument = (url) => {
    window.open(url, '_blank')
}

const removeExistingDocument = (index) => {
    existingDocuments.value.splice(index, 1)
}

const handleFileSelect = (event) => {
    const files = Array.from(event.target.files || [])
    
    for (const file of files) {
        // Check file size (5MB limit)
        if (file.size > 5 * 1024 * 1024) {
            // Show error for individual files that are too large
            continue
        }
        
        // Check for duplicates
        const isDuplicate = selectedFiles.value.some(f => 
            f.name === file.name && f.size === file.size && f.lastModified === file.lastModified
        )
        
        if (!isDuplicate) {
            selectedFiles.value.push(file)
        }
    }
    
    // Clear the input
    if (fileInput.value) {
        fileInput.value.value = ''
    }
}

const removeFile = (index) => {
    selectedFiles.value.splice(index, 1)
}

const getFileIcon = (file) => {
    if (isImage(file)) {
        return 'pi pi-image'
    }
    return 'pi pi-file'
}

const validateForm = () => {
    errors.full_name = ''
    errors.supporting_documents = ''

    if (!form.full_name?.trim()) {
        errors.full_name = 'Legal name is required'
    }

    const totalDocuments = existingDocuments.value.length + selectedFiles.value.length
    if (totalDocuments === 0) {
        errors.supporting_documents = 'Please upload at least one supporting document'
    }

    return !errors.full_name && !errors.supporting_documents
}

const handleSubmit = () => {
    if (validateForm()) {
        // Combine existing documents with new files
        const allDocuments = [...existingDocuments.value, ...selectedFiles.value]
        
        emit('submit', {
            full_name: form.full_name.trim(),
            supporting_documents: allDocuments,
            isEdit: isEdit.value
        })
    }
}
</script> 