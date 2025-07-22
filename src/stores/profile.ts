import { defineStore } from 'pinia';
import { ref, computed } from 'vue';
import { supabase } from '@/lib/supabase';
import { useToast } from 'primevue/usetoast';

// Get storage bucket name from environment variable
const USER_FILES_BUCKET = import.meta.env.VITE_SUPABASE_USER_FILES_BUCKET as string;

if (!USER_FILES_BUCKET) {
  console.warn('Supabase user files bucket name (VITE_SUPABASE_USER_FILES_BUCKET) not provided in .env. Uploads may fail.');
}

export type ProfileStatus = 'NOT_SUBMITTED' | 'PENDING_REVIEW' | 'APPROVED' | 'REJECTED';

export interface UserProfile {
    user_id: string;
    public_name: string | null;
    bio: string | null;
    company_name: string | null;
    full_name: string | null;
    verification_status: ProfileStatus;
    supporting_documents: string[] | null;
    verified_at: string | null;
    created_at: string;
    updated_at: string;
}

export interface BasicProfileForm {
    public_name: string;
    bio: string;
    company_name: string;
}

export interface VerificationForm {
    full_name: string;
    supporting_documents: (File | string)[];
    isEdit?: boolean;
}


export const useProfileStore = defineStore('profile', () => {
    const toast = useToast();

    // STATE
    const loading = ref(false);
    const profile = ref<UserProfile | null>(null);
    const isEditMode = ref(false);
    const isVerificationMode = ref(false);
    
    
    // Computed properties
    const hasBasicProfile = computed(() => {
        return profile.value && profile.value.public_name && profile.value.bio;
    });

    const isVerified = computed(() => {
        return profile.value?.verification_status === 'APPROVED' && profile.value?.verified_at;
    });

    const canVerify = computed(() => {
        return hasBasicProfile.value && 
               profile.value?.verification_status === 'NOT_SUBMITTED';
    });

    const verificationPending = computed(() => {
        return profile.value?.verification_status === 'PENDING_REVIEW';
    });

    const verificationRejected = computed(() => {
        return profile.value?.verification_status === 'REJECTED';
    });

    const canEditVerification = computed(() => {
        return profile.value?.verification_status === 'PENDING_REVIEW' || 
               profile.value?.verification_status === 'REJECTED'
    })

    const hasVerificationData = computed(() => {
        return profile.value && 
               (profile.value.full_name || 
                (profile.value.supporting_documents && profile.value.supporting_documents.length > 0))
    })


    // ACTIONS

    /**
     * Fetches the current user's profile from the database.
     */
    const fetchProfile = async () => {
        loading.value = true;
        profile.value = null;
        try {
            const { data, error } = await supabase.rpc('get_user_profile');
            
            if (error) throw error;
            
            if (data && data.length > 0) {
                profile.value = data[0];
            } else {
                profile.value = null;
            }
        } catch (error: any) {
            console.error('Error fetching profile:', error);
            toast.add({
                severity: 'error',
                summary: 'Error',
                detail: 'Failed to load profile',
                life: 3000
            });
        } finally {
            loading.value = false;
        }
    };

    /**
     * Creates or updates the basic profile.
     * @param {BasicProfileForm} formData - The form data to save.
     */
    const saveBasicProfile = async (formData: BasicProfileForm) => {
        loading.value = true;
        try {
            const { data, error } = await supabase.rpc('create_or_update_basic_profile', {
                p_public_name: formData.public_name,
                p_bio: formData.bio,
                p_company_name: formData.company_name || null
            });

            if (error) throw error;

            await fetchProfile(); // Refresh profile data
            isEditMode.value = false;
            // Success feedback provided by exiting edit mode and updated display

            return data;
        } catch (error: any) {
            console.error('Error saving profile:', error);
            toast.add({
                severity: 'error',
                summary: 'Error',
                detail: error.message || 'Failed to save profile',
                life: 3000
            });
            throw error;
        } finally {
            loading.value = false;
        }
    };

    /**
     * Submits the verification form.
     * @param {VerificationForm} formData - The form data to submit.
     */
    const submitVerification = async (formData: VerificationForm) => {
        try {
            loading.value = true

            const { data: { user } } = await supabase.auth.getUser()
            if (!user) throw new Error('User not authenticated')

            // Separate files from URLs
            const newFiles: File[] = []
            const existingUrls: string[] = []

            for (const item of formData.supporting_documents) {
                if (item instanceof File) {
                    newFiles.push(item)
                } else if (typeof item === 'string') {
                    existingUrls.push(item)
                }
            }

            // Upload new files if any
            let uploadedUrls: string[] = []
            if (newFiles.length > 0) {
                const uploadPromises = newFiles.map(async (file) => {
                    const fileName = `${Date.now()}-${file.name}`
                    const filePath = `${user.id}/verification-documents/${fileName}`
                    
                    const { error: uploadError } = await supabase.storage
                        .from(USER_FILES_BUCKET)
                        .upload(filePath, file)

                    if (uploadError) throw uploadError

                    const { data: { publicUrl } } = supabase.storage
                        .from(USER_FILES_BUCKET)
                        .getPublicUrl(filePath)

                    return publicUrl
                })

                uploadedUrls = await Promise.all(uploadPromises)
            }

            // Combine existing URLs with newly uploaded ones
            const allDocumentUrls = [...existingUrls, ...uploadedUrls]

            // Submit verification with all documents
            const { error: submitError } = await supabase.rpc('submit_verification', {
                p_full_name: formData.full_name,
                p_supporting_documents: allDocumentUrls
            })

            if (submitError) throw submitError

            toast.add({
                severity: 'success',
                summary: formData.isEdit ? 'Verification Updated' : 'Verification Submitted',
                detail: formData.isEdit 
                    ? 'Your verification has been updated and will be reviewed again.'
                    : 'Your verification has been submitted and will be reviewed within 1-2 business days.',
                life: 5000
            })

            // Refresh profile data
            await fetchProfile()
            
            // Reset UI state
            isVerificationMode.value = false

        } catch (err) {
            console.error('Error submitting verification:', err)
            const errorMessage = err instanceof Error ? err.message : 'Failed to submit verification'
            toast.add({
                severity: 'error',
                summary: 'Submission Failed',
                detail: errorMessage,
                life: 5000
            })
            throw err
        } finally {
            loading.value = false
        }
    }

    /**
     * Withdraws the verification, resetting status to NOT_SUBMITTED.
     * Only allowed when status is PENDING_REVIEW.
     */
    const withdrawVerification = async () => {
        loading.value = true;
        try {
            const { data, error } = await supabase.rpc('withdraw_verification');

            if (error) throw error;

            await fetchProfile(); // Refresh profile data

            toast.add({
                severity: 'info',
                summary: 'Verification Withdrawn',
                detail: 'Your verification has been withdrawn',
                life: 3000
            });

            return data;
        } catch (error: any) {
            console.error('Error withdrawing verification:', error);
            toast.add({
                severity: 'error',
                summary: 'Error',
                detail: error.message || 'Failed to withdraw verification',
                life: 3000
            });
            throw error;
        } finally {
            loading.value = false;
        }
    };

    // UI state management
    const startEdit = () => {
        isEditMode.value = true;
    };

    const startVerification = () => {
        isVerificationMode.value = true;
    };

    const cancelEdit = () => {
        isEditMode.value = false;
        isVerificationMode.value = false;
    };

    return {
        // State
        profile,
        loading,
        isEditMode,
        isVerificationMode,
        // Computed
        hasBasicProfile,
        isVerified,
        canVerify,
        verificationPending,
        verificationRejected,
        canEditVerification,
        hasVerificationData,
        // Actions
        fetchProfile,
        saveBasicProfile,
        submitVerification,
        withdrawVerification,
        startEdit,
        startVerification,
        cancelEdit,
    };
}); 