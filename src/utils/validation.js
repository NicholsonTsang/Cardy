/**
 * Standardized form validation utilities for the Cardy application
 * Provides consistent validation rules, error handling, and user feedback
 */

import { ref, reactive, computed } from 'vue';
import { useErrorHandler } from './errorHandler.js';

/**
 * Validation rules library
 */
export const ValidationRules = {
    required: (message = 'This field is required') => ({
        validate: (value) => {
            if (value === null || value === undefined) return false;
            if (typeof value === 'string') return value.trim().length > 0;
            if (Array.isArray(value)) return value.length > 0;
            return !!value;
        },
        message
    }),
    
    minLength: (min, message) => ({
        validate: (value) => {
            if (!value) return true; // Only validate if value exists
            return value.toString().length >= min;
        },
        message: message || `Must be at least ${min} characters`
    }),
    
    maxLength: (max, message) => ({
        validate: (value) => {
            if (!value) return true; // Only validate if value exists
            return value.toString().length <= max;
        },
        message: message || `Must not exceed ${max} characters`
    }),
    
    email: (message = 'Please enter a valid email address') => ({
        validate: (value) => {
            if (!value) return true; // Only validate if value exists
            const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
            return emailRegex.test(value);
        },
        message
    }),
    
    url: (message = 'Please enter a valid URL') => ({
        validate: (value) => {
            if (!value) return true; // Only validate if value exists
            try {
                new URL(value);
                return true;
            } catch {
                return false;
            }
        },
        message
    }),
    
    pattern: (regex, message = 'Invalid format') => ({
        validate: (value) => {
            if (!value) return true; // Only validate if value exists
            return regex.test(value);
        },
        message
    }),
    
    fileSize: (maxSizeInMB, message) => ({
        validate: (file) => {
            if (!file) return true; // Only validate if file exists
            const maxBytes = maxSizeInMB * 1024 * 1024;
            return file.size <= maxBytes;
        },
        message: message || `File size must not exceed ${maxSizeInMB}MB`
    }),
    
    fileType: (allowedTypes, message) => ({
        validate: (file) => {
            if (!file) return true; // Only validate if file exists
            return allowedTypes.includes(file.type);
        },
        message: message || `File type must be one of: ${allowedTypes.join(', ')}`
    }),
    
    custom: (validateFn, message = 'Invalid value') => ({
        validate: validateFn,
        message
    })
};

/**
 * Create a validation schema for forms
 * @param {Object} schema - Object defining validation rules for each field
 * @returns {Object} Validation functions and state
 */
export function useFormValidation(schema) {
    const errors = reactive({});
    const touched = reactive({});
    const isSubmitting = ref(false);
    const { handleValidationError } = useErrorHandler();
    
    // Initialize errors and touched state
    Object.keys(schema).forEach(field => {
        errors[field] = [];
        touched[field] = false;
    });
    
    const validateField = (field, value) => {
        const rules = schema[field];
        if (!rules) return true;
        
        const fieldErrors = [];
        
        for (const rule of rules) {
            if (!rule.validate(value)) {
                fieldErrors.push(rule.message);
            }
        }
        
        errors[field] = fieldErrors;
        return fieldErrors.length === 0;
    };
    
    const validateForm = (formData) => {
        let isValid = true;
        const allErrors = [];
        
        Object.keys(schema).forEach(field => {
            const fieldValid = validateField(field, formData[field]);
            if (!fieldValid) {
                isValid = false;
                allErrors.push(...errors[field]);
            }
            touched[field] = true;
        });
        
        return {
            isValid,
            errors: allErrors,
            fieldErrors: { ...errors }
        };
    };
    
    const touchField = (field) => {
        touched[field] = true;
    };
    
    const resetValidation = () => {
        Object.keys(schema).forEach(field => {
            errors[field] = [];
            touched[field] = false;
        });
        isSubmitting.value = false;
    };
    
    const getFieldError = (field) => {
        return touched[field] && errors[field].length > 0 ? errors[field][0] : null;
    };
    
    const hasFieldError = (field) => {
        return touched[field] && errors[field].length > 0;
    };
    
    const isFormValid = computed(() => {
        return Object.values(errors).every(fieldErrors => fieldErrors.length === 0);
    });
    
    const hasAnyErrors = computed(() => {
        return Object.values(errors).some(fieldErrors => fieldErrors.length > 0);
    });
    
    const submitForm = async (formData, submitFn) => {
        isSubmitting.value = true;
        
        try {
            const validation = validateForm(formData);
            
            if (!validation.isValid) {
                handleValidationError(validation.errors, 'form validation');
                return { success: false, errors: validation.errors };
            }
            
            const result = await submitFn(formData);
            return { success: true, result };
            
        } catch (error) {
            handleValidationError(error, 'form submission');
            return { success: false, error };
        } finally {
            isSubmitting.value = false;
        }
    };
    
    return {
        errors,
        touched,
        isSubmitting,
        validateField,
        validateForm,
        touchField,
        resetValidation,
        getFieldError,
        hasFieldError,
        isFormValid,
        hasAnyErrors,
        submitForm
    };
}

/**
 * Pre-defined validation schemas for common forms
 */
export const ValidationSchemas = {
    card: {
        name: [
            ValidationRules.required('Card name is required'),
            ValidationRules.minLength(2, 'Card name must be at least 2 characters'),
            ValidationRules.maxLength(100, 'Card name must not exceed 100 characters')
        ],
        description: [
            ValidationRules.maxLength(500, 'Description must not exceed 500 characters')
        ],
        qr_code_position: [
            ValidationRules.required('QR code position is required'),
            ValidationRules.pattern(/^(TL|TR|BL|BR)$/, 'Invalid QR code position')
        ]
    },
    
    content: {
        content_item_name: [
            ValidationRules.required('Content name is required'),
            ValidationRules.minLength(2, 'Content name must be at least 2 characters'),
            ValidationRules.maxLength(200, 'Content name must not exceed 200 characters')
        ],
        content_item_content: [
            ValidationRules.required('Content description is required'),
            ValidationRules.minLength(10, 'Content description must be at least 10 characters'),
            ValidationRules.maxLength(2000, 'Content description must not exceed 2000 characters')
        ]
    },
    
    profile: {
        public_name: [
            ValidationRules.required('Public name is required'),
            ValidationRules.minLength(2, 'Public name must be at least 2 characters'),
            ValidationRules.maxLength(50, 'Public name must not exceed 50 characters')
        ],
        bio: [
            ValidationRules.maxLength(300, 'Bio must not exceed 300 characters')
        ],
        website: [
            ValidationRules.url('Please enter a valid website URL')
        ]
    },
    
    address: {
        label: [
            ValidationRules.required('Address label is required'),
            ValidationRules.minLength(2, 'Label must be at least 2 characters'),
            ValidationRules.maxLength(50, 'Label must not exceed 50 characters')
        ],
        recipient_name: [
            ValidationRules.required('Recipient name is required'),
            ValidationRules.minLength(2, 'Recipient name must be at least 2 characters'),
            ValidationRules.maxLength(100, 'Recipient name must not exceed 100 characters')
        ],
        address_line_1: [
            ValidationRules.required('Address line 1 is required'),
            ValidationRules.minLength(5, 'Address must be at least 5 characters'),
            ValidationRules.maxLength(100, 'Address line 1 must not exceed 100 characters')
        ],
        address_line_2: [
            ValidationRules.maxLength(100, 'Address line 2 must not exceed 100 characters')
        ],
        city: [
            ValidationRules.required('City is required'),
            ValidationRules.minLength(2, 'City must be at least 2 characters'),
            ValidationRules.maxLength(50, 'City must not exceed 50 characters')
        ],
        state: [
            ValidationRules.required('State is required'),
            ValidationRules.minLength(2, 'State must be at least 2 characters'),
            ValidationRules.maxLength(50, 'State must not exceed 50 characters')
        ],
        postal_code: [
            ValidationRules.required('Postal code is required'),
            ValidationRules.pattern(/^\d{5}(-\d{4})?$/, 'Please enter a valid postal code (12345 or 12345-6789)')
        ],
        country: [
            ValidationRules.required('Country is required')
        ]
    },
    
    imageUpload: {
        file: [
            ValidationRules.required('Please select an image file'),
            ValidationRules.fileSize(5, 'Image file must not exceed 5MB'),
            ValidationRules.fileType(
                ['image/jpeg', 'image/jpg', 'image/png', 'image/webp'],
                'File must be an image (JPEG, PNG, or WebP)'
            )
        ]
    }
};

/**
 * Utility for real-time field validation in components
 * @param {Function} validateFn - Function to validate the field
 * @param {number} debounceMs - Debounce delay in milliseconds
 * @returns {Object} Validation state and methods
 */
export function useFieldValidation(validateFn, debounceMs = 300) {
    const isValid = ref(null);
    const error = ref(null);
    const isValidating = ref(false);
    let timeoutId = null;
    
    const validate = (value) => {
        isValidating.value = true;
        
        // Clear existing timeout
        if (timeoutId) {
            clearTimeout(timeoutId);
        }
        
        // Set new timeout for debounced validation
        timeoutId = setTimeout(() => {
            try {
                const result = validateFn(value);
                if (result === true) {
                    isValid.value = true;
                    error.value = null;
                } else {
                    isValid.value = false;
                    error.value = result || 'Invalid value';
                }
            } catch (err) {
                isValid.value = false;
                error.value = 'Validation error';
            } finally {
                isValidating.value = false;
            }
        }, debounceMs);
    };
    
    const reset = () => {
        if (timeoutId) {
            clearTimeout(timeoutId);
        }
        isValid.value = null;
        error.value = null;
        isValidating.value = false;
    };
    
    return {
        isValid,
        error,
        isValidating,
        validate,
        reset
    };
}

/**
 * Common validation patterns
 */
export const ValidationPatterns = {
    PHONE: /^\+?[\d\s\-\(\)]+$/,
    POSTAL_CODE_US: /^\d{5}(-\d{4})?$/,
    CARD_NUMBER: /^\d{4}\s?\d{4}\s?\d{4}\s?\d{4}$/,
    ACTIVATION_CODE: /^[A-Z0-9]{6,12}$/,
    QR_POSITION: /^(TL|TR|BL|BR)$/
};

/**
 * Helper function to create validation messages
 */
export function createValidationMessage(field, rule, value) {
    const fieldName = field.replace(/_/g, ' ').replace(/\b\w/g, l => l.toUpperCase());
    
    switch (rule) {
        case 'required':
            return `${fieldName} is required`;
        case 'minLength':
            return `${fieldName} must be at least ${value} characters`;
        case 'maxLength':
            return `${fieldName} must not exceed ${value} characters`;
        case 'email':
            return `Please enter a valid email address`;
        case 'url':
            return `Please enter a valid URL`;
        default:
            return `${fieldName} is invalid`;
    }
}