import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { supabase } from '@/lib/supabase'
import { useToast } from 'primevue/usetoast'

export interface ShippingAddress {
    id: string
    user_id: string
    label: string
    recipient_name: string
    address_line1: string
    address_line2?: string
    city: string
    state_province: string
    postal_code: string
    country: string
    phone?: string
    is_default: boolean
    created_at: string
    updated_at: string
}

export interface ShippingAddressForm {
    label: string
    recipient_name: string
    address_line1: string
    address_line2?: string
    city: string
    state_province: string
    postal_code: string
    country: string
    phone?: string
    is_default: boolean
}

export const useShippingAddressStore = defineStore('shippingAddress', () => {
    // STATE
    const addresses = ref<ShippingAddress[]>([])
    const loading = ref(false)
    const isEditMode = ref(false)
    const editingAddressId = ref<string | null>(null)
    
    // Initialize toast inside the store function
    const toast = useToast()

    // COMPUTED
    const defaultAddress = computed(() => {
        return addresses.value.find(addr => addr.is_default) || null
    })

    const hasAddresses = computed(() => {
        return addresses.value.length > 0
    })

    const sortedAddresses = computed(() => {
        return [...addresses.value].sort((a, b) => {
            // Default address first, then by creation date (newest first)
            if (a.is_default && !b.is_default) return -1
            if (!a.is_default && b.is_default) return 1
            return new Date(b.created_at).getTime() - new Date(a.created_at).getTime()
        })
    })

    // ACTIONS

    /**
     * Fetches all shipping addresses for the current user.
     */
    const fetchAddresses = async () => {
        loading.value = true
        try {
            const { data, error } = await supabase.rpc('get_user_shipping_addresses')
            
            if (error) throw error
            
            addresses.value = data || []
        } catch (error: any) {
            console.error('Error fetching shipping addresses:', error)
            toast.add({
                severity: 'error',
                summary: 'Error',
                detail: 'Failed to load shipping addresses',
                life: 3000
            })
        } finally {
            loading.value = false
        }
    }

    /**
     * Creates a new shipping address.
     */
    const createAddress = async (formData: ShippingAddressForm) => {
        loading.value = true
        try {
            const { data, error } = await supabase.rpc('create_shipping_address', {
                p_label: formData.label,
                p_recipient_name: formData.recipient_name,
                p_address_line1: formData.address_line1,
                p_address_line2: formData.address_line2 || null,
                p_city: formData.city,
                p_state_province: formData.state_province,
                p_postal_code: formData.postal_code,
                p_country: formData.country,
                p_phone: formData.phone || null,
                p_is_default: formData.is_default
            })

            if (error) throw error

            await fetchAddresses() // Refresh addresses
            isEditMode.value = false
            editingAddressId.value = null

            toast.add({
                severity: 'success',
                summary: 'Success',
                detail: 'Shipping address created successfully',
                life: 3000
            })

            return data
        } catch (error: any) {
            console.error('Error creating shipping address:', error)
            toast.add({
                severity: 'error',
                summary: 'Error',
                detail: error.message || 'Failed to create shipping address',
                life: 3000
            })
            throw error
        } finally {
            loading.value = false
        }
    }

    /**
     * Updates an existing shipping address.
     */
    const updateAddress = async (addressId: string, formData: Partial<ShippingAddressForm>) => {
        loading.value = true
        try {
            const { data, error } = await supabase.rpc('update_shipping_address', {
                p_address_id: addressId,
                p_label: formData.label || null,
                p_recipient_name: formData.recipient_name || null,
                p_address_line1: formData.address_line1 || null,
                p_address_line2: formData.address_line2 || null,
                p_city: formData.city || null,
                p_state_province: formData.state_province || null,
                p_postal_code: formData.postal_code || null,
                p_country: formData.country || null,
                p_phone: formData.phone || null,
                p_is_default: formData.is_default !== undefined ? formData.is_default : null
            })

            if (error) throw error

            await fetchAddresses() // Refresh addresses
            isEditMode.value = false
            editingAddressId.value = null

            toast.add({
                severity: 'success',
                summary: 'Success',
                detail: 'Shipping address updated successfully',
                life: 3000
            })

            return data
        } catch (error: any) {
            console.error('Error updating shipping address:', error)
            toast.add({
                severity: 'error',
                summary: 'Error',
                detail: error.message || 'Failed to update shipping address',
                life: 3000
            })
            throw error
        } finally {
            loading.value = false
        }
    }

    /**
     * Deletes a shipping address.
     */
    const deleteAddress = async (addressId: string) => {
        loading.value = true
        try {
            const { data, error } = await supabase.rpc('delete_shipping_address', {
                p_address_id: addressId
            })

            if (error) throw error

            await fetchAddresses() // Refresh addresses

            toast.add({
                severity: 'success',
                summary: 'Success',
                detail: 'Shipping address deleted successfully',
                life: 3000
            })

            return data
        } catch (error: any) {
            console.error('Error deleting shipping address:', error)
            toast.add({
                severity: 'error',
                summary: 'Error',
                detail: error.message || 'Failed to delete shipping address',
                life: 3000
            })
            throw error
        } finally {
            loading.value = false
        }
    }

    /**
     * Sets an address as the default shipping address.
     */
    const setDefault = async (addressId: string) => {
        loading.value = true
        try {
            const { data, error } = await supabase.rpc('set_default_shipping_address', {
                p_address_id: addressId
            })

            if (error) throw error

            await fetchAddresses() // Refresh addresses

            toast.add({
                severity: 'success',
                summary: 'Success',
                detail: 'Default shipping address updated',
                life: 3000
            })

            return data
        } catch (error: any) {
            console.error('Error setting default address:', error)
            toast.add({
                severity: 'error',
                summary: 'Error',
                detail: error.message || 'Failed to update default address',
                life: 3000
            })
            throw error
        } finally {
            loading.value = false
        }
    }

    /**
     * Gets the formatted address string for a given address ID.
     */
    const getFormattedAddress = async (addressId: string): Promise<string> => {
        try {
            const { data, error } = await supabase.rpc('format_shipping_address', {
                p_address_id: addressId
            })

            if (error) throw error

            return data as string
        } catch (error: any) {
            console.error('Error formatting address:', error)
            throw error
        }
    }

    // UI state management
    const startEdit = (addressId?: string) => {
        isEditMode.value = true
        editingAddressId.value = addressId || null
    }

    const cancelEdit = () => {
        isEditMode.value = false
        editingAddressId.value = null
    }

    return {
        // State
        addresses,
        loading,
        isEditMode,
        editingAddressId,
        // Computed
        defaultAddress,
        hasAddresses,
        sortedAddresses,
        // Actions
        fetchAddresses,
        createAddress,
        updateAddress,
        deleteAddress,
        setDefault,
        getFormattedAddress,
        startEdit,
        cancelEdit,
    }
}) 