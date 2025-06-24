<template>
    <form @submit.prevent="handleSubmit" class="space-y-4">
        <!-- Address Label -->
        <div>
            <label class="block text-sm font-medium text-slate-700 mb-2">
                Address Label <span class="text-red-500">*</span>
            </label>
            <InputText
                v-model="form.label"
                placeholder="e.g., Home, Office, Work"
                class="w-full"
                :class="{ 'border-red-300': submitted && !form.label.trim() }"
                required
            />
            <small v-if="submitted && !form.label.trim()" class="text-red-500">
                Address label is required.
            </small>
        </div>

        <!-- Recipient Name -->
        <div>
            <label class="block text-sm font-medium text-slate-700 mb-2">
                Recipient Name <span class="text-red-500">*</span>
            </label>
            <InputText
                v-model="form.recipient_name"
                placeholder="Full name of recipient"
                class="w-full"
                :class="{ 'border-red-300': submitted && !form.recipient_name.trim() }"
                required
            />
            <small v-if="submitted && !form.recipient_name.trim()" class="text-red-500">
                Recipient name is required.
            </small>
        </div>

        <!-- Address Line 1 -->
        <div>
            <label class="block text-sm font-medium text-slate-700 mb-2">
                Address Line 1 <span class="text-red-500">*</span>
            </label>
            <InputText
                v-model="form.address_line1"
                placeholder="Street address, P.O. box, company name"
                class="w-full"
                :class="{ 'border-red-300': submitted && !form.address_line1.trim() }"
                required
            />
            <small v-if="submitted && !form.address_line1.trim()" class="text-red-500">
                Address line 1 is required.
            </small>
        </div>

        <!-- Address Line 2 -->
        <div>
            <label class="block text-sm font-medium text-slate-700 mb-2">
                Address Line 2 <span class="text-slate-500">(Optional)</span>
            </label>
            <InputText
                v-model="form.address_line2"
                placeholder="Apartment, suite, unit, building, floor, etc."
                class="w-full"
            />
        </div>

        <!-- City, State, Postal Code -->
        <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div>
                <label class="block text-sm font-medium text-slate-700 mb-2">
                    City <span class="text-red-500">*</span>
                </label>
                <InputText
                    v-model="form.city"
                    placeholder="City"
                    class="w-full"
                    :class="{ 'border-red-300': submitted && !form.city.trim() }"
                    required
                />
                <small v-if="submitted && !form.city.trim()" class="text-red-500">
                    City is required.
                </small>
            </div>
            <div>
                <label class="block text-sm font-medium text-slate-700 mb-2">
                    State/Province <span class="text-red-500">*</span>
                </label>
                <InputText
                    v-model="form.state_province"
                    placeholder="State or Province"
                    class="w-full"
                    :class="{ 'border-red-300': submitted && !form.state_province.trim() }"
                    required
                />
                <small v-if="submitted && !form.state_province.trim()" class="text-red-500">
                    State/Province is required.
                </small>
            </div>
            <div>
                <label class="block text-sm font-medium text-slate-700 mb-2">
                    Postal Code <span class="text-red-500">*</span>
                </label>
                <InputText
                    v-model="form.postal_code"
                    placeholder="Postal Code"
                    class="w-full"
                    :class="{ 'border-red-300': submitted && !form.postal_code.trim() }"
                    required
                />
                <small v-if="submitted && !form.postal_code.trim()" class="text-red-500">
                    Postal code is required.
                </small>
            </div>
        </div>

        <!-- Country -->
        <div>
            <label class="block text-sm font-medium text-slate-700 mb-2">
                Country <span class="text-red-500">*</span>
            </label>
            <Select
                v-model="form.country"
                :options="countries"
                optionLabel="name"
                optionValue="code"
                placeholder="Select country"
                class="w-full"
                :class="{ 'border-red-300': submitted && !form.country }"
                filter
                required
            />
            <small v-if="submitted && !form.country" class="text-red-500">
                Country is required.
            </small>
        </div>

        <!-- Phone -->
        <div>
            <label class="block text-sm font-medium text-slate-700 mb-2">
                Phone Number <span class="text-slate-500">(Optional)</span>
            </label>
            <InputText
                v-model="form.phone"
                placeholder="Phone number for delivery contact"
                class="w-full"
            />
        </div>

        <!-- Default Address -->
        <div class="flex items-center gap-2">
            <Checkbox
                v-model="form.is_default"
                inputId="is_default"
                binary
            />
            <label for="is_default" class="text-sm font-medium text-slate-700">
                Set as default shipping address
            </label>
        </div>

        <!-- Form Actions -->
        <div class="flex justify-end gap-3 pt-4">
            <Button
                label="Cancel"
                severity="secondary"
                outlined
                @click="$emit('cancelled')"
                :disabled="loading"
            />
            <Button
                type="submit"
                :label="isEditing ? 'Update Address' : 'Add Address'"
                :loading="loading"
                :disabled="loading"
            />
        </div>
    </form>
</template>

<script setup>
import { ref, onMounted, computed } from 'vue'
import { useShippingAddressStore } from '@/stores/shippingAddress'

// PrimeVue Components
import InputText from 'primevue/inputtext'
import Select from 'primevue/select'
import Checkbox from 'primevue/checkbox'
import Button from 'primevue/button'

const props = defineProps({
    addressId: {
        type: String,
        default: null
    }
})

const emit = defineEmits(['saved', 'cancelled'])

const addressStore = useShippingAddressStore()

// Form state
const form = ref({
    label: '',
    recipient_name: '',
    address_line1: '',
    address_line2: '',
    city: '',
    state_province: '',
    postal_code: '',
    country: '',
    phone: '',
    is_default: false
})

const submitted = ref(false)
const loading = ref(false)

// Computed
const isEditing = computed(() => !!props.addressId)

// Countries list (you can expand this or use a library)
const countries = ref([
    { name: 'United States', code: 'US' },
    { name: 'Canada', code: 'CA' },
    { name: 'United Kingdom', code: 'GB' },
    { name: 'Australia', code: 'AU' },
    { name: 'Germany', code: 'DE' },
    { name: 'France', code: 'FR' },
    { name: 'Japan', code: 'JP' },
    { name: 'South Korea', code: 'KR' },
    { name: 'China', code: 'CN' },
    { name: 'India', code: 'IN' },
    { name: 'Brazil', code: 'BR' },
    { name: 'Mexico', code: 'MX' },
    { name: 'Netherlands', code: 'NL' },
    { name: 'Sweden', code: 'SE' },
    { name: 'Norway', code: 'NO' },
    { name: 'Denmark', code: 'DK' },
    { name: 'Finland', code: 'FI' },
    { name: 'Switzerland', code: 'CH' },
    { name: 'Austria', code: 'AT' },
    { name: 'Belgium', code: 'BE' },
    { name: 'Italy', code: 'IT' },
    { name: 'Spain', code: 'ES' },
    { name: 'Portugal', code: 'PT' },
    { name: 'Poland', code: 'PL' },
    { name: 'Czech Republic', code: 'CZ' },
    { name: 'Hungary', code: 'HU' },
    { name: 'Romania', code: 'RO' },
    { name: 'Bulgaria', code: 'BG' },
    { name: 'Croatia', code: 'HR' },
    { name: 'Slovenia', code: 'SI' },
    { name: 'Slovakia', code: 'SK' },
    { name: 'Estonia', code: 'EE' },
    { name: 'Latvia', code: 'LV' },
    { name: 'Lithuania', code: 'LT' }
])

// Load existing address data if editing
const loadAddressData = async () => {
    if (props.addressId) {
        const address = addressStore.addresses.find(addr => addr.id === props.addressId)
        if (address) {
            form.value = {
                label: address.label,
                recipient_name: address.recipient_name,
                address_line1: address.address_line1,
                address_line2: address.address_line2 || '',
                city: address.city,
                state_province: address.state_province,
                postal_code: address.postal_code,
                country: address.country,
                phone: address.phone || '',
                is_default: address.is_default
            }
        }
    }
}

// Form validation
const validateForm = () => {
    return form.value.label.trim() &&
           form.value.recipient_name.trim() &&
           form.value.address_line1.trim() &&
           form.value.city.trim() &&
           form.value.state_province.trim() &&
           form.value.postal_code.trim() &&
           form.value.country
}

// Handle form submission
const handleSubmit = async () => {
    submitted.value = true
    
    if (!validateForm()) {
        return
    }
    
    loading.value = true
    
    try {
        if (isEditing.value) {
            await addressStore.updateAddress(props.addressId, form.value)
        } else {
            await addressStore.createAddress(form.value)
        }
        
        emit('saved')
    } catch (error) {
        // Error handling is done in the store
    } finally {
        loading.value = false
    }
}

onMounted(() => {
    loadAddressData()
})
</script> 