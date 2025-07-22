<template>
    <div class="space-y-6">
        <!-- Profile Header -->
        <div class="bg-white rounded-xl shadow-lg border border-slate-200 overflow-hidden">
            <div class="p-6">
                <div class="flex items-start justify-between">
                    <div class="flex items-center gap-4">
                        <div class="w-16 h-16 bg-gradient-to-r from-blue-500 to-indigo-500 rounded-full flex items-center justify-center">
                            <i class="pi pi-user text-2xl text-white"></i>
                        </div>
                        <div>
                            <div class="flex items-center gap-2 mb-1">
                                <h1 class="text-2xl font-bold text-slate-900">{{ store.profile?.public_name || 'User' }}</h1>
                                <VerificationBadge 
                                    :verification-status="store.profile?.verification_status"
                                    :verified-at="store.profile?.verified_at"
                                    size="large"
                                />
                            </div>
                            <p v-if="store.profile?.company_name" class="text-slate-600 mb-2">{{ store.profile.company_name }}</p>
                            <p class="text-slate-700">{{ store.profile?.bio || 'No bio available' }}</p>
                        </div>
                    </div>
                    
                    <Button
                        label="Edit Profile"
                        icon="pi pi-pencil"
                        @click="store.startEdit"
                        outlined
                        size="small"
                    />
                </div>
            </div>
        </div>

        <!-- Verification Actions -->
        <div v-if="!store.isVerified" class="bg-white rounded-xl shadow-lg border border-slate-200 overflow-hidden">
            <div class="p-6">
                <h2 class="text-xl font-semibold text-slate-900 mb-4 flex items-center gap-2">
                    <i class="pi pi-shield text-blue-600"></i>
                    Get Verified
                </h2>

                <!-- Pending Review -->
                <div v-if="store.verificationPending" class="bg-amber-50 border border-amber-200 rounded-lg p-4">
                    <div class="flex items-center justify-between">
                        <div class="flex items-center gap-3">
                            <i class="pi pi-clock text-amber-600 text-xl"></i>
                            <div>
                                <h3 class="font-semibold text-amber-900">Under Review</h3>
                                <p class="text-amber-700 text-sm">Your verification is being reviewed (1-2 business days)</p>
                            </div>
                        </div>
                        <div class="flex gap-2">
                            <Button
                                label="View"
                                icon="pi pi-eye"
                                @click="toggleViewVerification"
                                severity="info"
                                outlined
                                size="small"
                            />
                            <Button
                                label="Edit"
                                icon="pi pi-pencil"
                                @click="store.startVerification"
                                severity="warning"
                                outlined
                                size="small"
                            />
                            <Button
                                label="Withdraw"
                                icon="pi pi-times"
                                @click="handleWithdraw"
                                severity="warning"
                                outlined
                                size="small"
                            />
                        </div>
                    </div>

                    <!-- View Verification Details -->
                    <div v-if="showVerificationDetails" class="mt-4 pt-4 border-t border-amber-200">
                        <div class="space-y-3">
                            <div>
                                <h4 class="text-sm font-medium text-amber-800">Legal Name:</h4>
                                <p class="text-amber-700">{{ store.profile?.full_name || 'Not provided' }}</p>
                            </div>
                            <div v-if="store.profile?.supporting_documents?.length">
                                <h4 class="text-sm font-medium text-amber-800">Supporting Documents:</h4>
                                <div class="space-y-2 mt-2">
                                    <div 
                                        v-for="(doc, index) in store.profile.supporting_documents" 
                                        :key="index"
                                        class="flex items-center justify-between bg-amber-100 rounded p-2"
                                    >
                                        <div class="flex items-center gap-2">
                                            <i class="pi pi-file text-amber-600"></i>
                                            <span class="text-sm text-amber-800">{{ getDocumentName(doc) }}</span>
                                        </div>
                                        <Button
                                            icon="pi pi-external-link"
                                            size="small"
                                            text
                                            @click="viewDocument(doc)"
                                            title="Open document"
                                        />
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Rejected -->
                <div v-else-if="store.verificationRejected">
                    <div class="bg-red-50 border border-red-200 rounded-lg p-4 mb-4">
                        <div class="flex items-start gap-3">
                            <i class="pi pi-times-circle text-red-600 text-xl"></i>
                            <div class="flex-1">
                                <h3 class="font-semibold text-red-900">Verification Rejected</h3>
                                <p class="text-red-700 text-sm">Your verification needs attention</p>
                            </div>
                        </div>

                        <!-- View Verification Details -->
                        <div v-if="showVerificationDetails" class="mt-4 pt-4 border-t border-red-200">
                            <div class="space-y-3">
                                <div>
                                    <h4 class="text-sm font-medium text-red-800">Legal Name:</h4>
                                    <p class="text-red-700">{{ store.profile?.full_name || 'Not provided' }}</p>
                                </div>
                                <div v-if="store.profile?.supporting_documents?.length">
                                    <h4 class="text-sm font-medium text-red-800">Supporting Documents:</h4>
                                    <div class="space-y-2 mt-2">
                                        <div 
                                            v-for="(doc, index) in store.profile.supporting_documents" 
                                            :key="index"
                                            class="flex items-center justify-between bg-red-100 rounded p-2"
                                        >
                                            <div class="flex items-center gap-2">
                                                <i class="pi pi-file text-red-600"></i>
                                                <span class="text-sm text-red-800">{{ getDocumentName(doc) }}</span>
                                            </div>
                                            <Button
                                                icon="pi pi-external-link"
                                                size="small"
                                                text
                                                @click="viewDocument(doc)"
                                                title="Open document"
                                            />
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>

                    <div class="flex gap-3">
                        <Button
                            label="View Details"
                            icon="pi pi-eye"
                            @click="toggleViewVerification"
                            severity="info"
                            outlined
                            class="flex-1"
                        />
                        <Button
                            label="Try Again"
                            icon="pi pi-refresh"
                            @click="store.startVerification"
                            severity="danger"
                            class="flex-1"
                        />
                    </div>
                </div>

                <!-- Not Verified -->
                <div v-else-if="store.canVerify">
                    <div class="bg-blue-50 border border-blue-200 rounded-lg p-4 mb-4">
                        <div class="flex items-center gap-3">
                            <i class="pi pi-shield text-blue-600 text-xl"></i>
                            <div>
                                <h3 class="font-semibold text-blue-900">Identity Verification</h3>
                                <p class="text-blue-700 text-sm">Get a blue checkmark and build trust with your audience</p>
                                <ul class="text-blue-600 text-xs mt-2 space-y-1">
                                    <li>• Gain credibility with your audience</li>
                                    <li>• Access premium features</li>
                                    <li>• Stand out from unverified accounts</li>
                                </ul>
                            </div>
                        </div>
                    </div>
                    <Button
                        label="Start Verification"
                        icon="pi pi-arrow-right"
                        @click="store.startVerification"
                        class="w-full bg-gradient-to-r from-blue-500 to-indigo-500 hover:from-blue-600 hover:to-indigo-600 border-0"
                    />
                </div>
            </div>
        </div>

        <!-- Profile Information -->
        <div class="bg-white rounded-xl shadow-lg border border-slate-200 overflow-hidden">
            <div class="p-6">
                <h2 class="text-xl font-semibold text-slate-900 mb-4 flex items-center gap-2">
                    <i class="pi pi-info-circle text-blue-600"></i>
                    Profile Information
                </h2>

                <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                    <div>
                        <h3 class="text-sm font-medium text-slate-700 mb-2">Display Name</h3>
                        <p class="text-slate-900">{{ store.profile?.public_name || 'Not set' }}</p>
                    </div>

                    <div v-if="store.profile?.company_name">
                        <h3 class="text-sm font-medium text-slate-700 mb-2">Company/Organization</h3>
                        <p class="text-slate-900">{{ store.profile.company_name }}</p>
                    </div>

                    <div class="md:col-span-2">
                        <h3 class="text-sm font-medium text-slate-700 mb-2">About</h3>
                        <p class="text-slate-900 whitespace-pre-wrap">{{ store.profile?.bio || 'No bio available' }}</p>
                    </div>

                    <div v-if="store.profile?.created_at">
                        <h3 class="text-sm font-medium text-slate-700 mb-2">Member Since</h3>
                        <p class="text-slate-600">{{ formatDate(store.profile.created_at) }}</p>
                    </div>

                    <div v-if="store.profile?.updated_at">
                        <h3 class="text-sm font-medium text-slate-700 mb-2">Last Updated</h3>
                        <p class="text-slate-600">{{ formatDate(store.profile.updated_at) }}</p>
                    </div>
                </div>
            </div>
        </div>
    </div>
</template>

<script setup>
import { ref } from 'vue'
import Button from 'primevue/button'
import { useProfileStore } from '@/stores/profile'
import { useConfirm } from 'primevue/useconfirm'
import VerificationBadge from './VerificationBadge.vue'

const store = useProfileStore()
const confirm = useConfirm()
const showVerificationDetails = ref(false)

const formatDate = (dateString) => {
    if (!dateString) return 'N/A'
    return new Date(dateString).toLocaleDateString('en-US', {
        year: 'numeric',
        month: 'long',
        day: 'numeric'
    })
}

const toggleViewVerification = () => {
    showVerificationDetails.value = !showVerificationDetails.value
}

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

const handleWithdraw = () => {
    confirm.require({
        message: 'Are you sure you want to withdraw your verification? You can submit again anytime.',
        header: 'Withdraw Verification',
        icon: 'pi pi-exclamation-triangle',
        acceptClass: 'p-button-warning',
        acceptLabel: 'Withdraw',
        rejectLabel: 'Cancel',
        accept: () => {
            store.withdrawVerification()
        }
    })
}
</script> 