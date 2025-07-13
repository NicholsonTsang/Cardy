import { useToast } from 'primevue/usetoast';

/**
 * Standardized error handling utility for the CardStudio application
 * Provides consistent error logging, user notifications, and error processing
 */

/**
 * Enhanced error handler with context and user feedback
 * @param {Error|string} error - The error object or message
 * @param {string} context - Context where the error occurred (e.g., 'creating card', 'loading content')
 * @param {Object} options - Additional options for error handling
 * @param {boolean} options.showToast - Whether to show toast notification (default: true)
 * @param {string} options.severity - Toast severity level ('error', 'warn', 'info')
 * @param {number} options.life - Toast display duration in milliseconds
 * @param {boolean} options.logToConsole - Whether to log to console (default: true)
 * @param {Function} options.customHandler - Custom error handling function
 * @returns {Object} Processed error information
 */
export function useErrorHandler() {
    const toast = useToast();
    
    const handleError = (error, context = '', options = {}) => {
        const {
            showToast = true,
            severity = 'error',
            life = 5000,
            logToConsole = true,
            customHandler = null
        } = options;
        
        // Process error to extract meaningful information
        const errorInfo = processError(error, context);
        
        // Log to console if enabled
        if (logToConsole) {
            console.error(`Error ${context}:`, {
                message: errorInfo.message,
                originalError: error,
                timestamp: new Date().toISOString(),
                context
            });
        }
        
        // Show toast notification if enabled
        if (showToast && toast) {
            toast.add({
                severity,
                summary: getSummaryFromContext(context) || 'Error',
                detail: errorInfo.userMessage,
                life
            });
        }
        
        // Execute custom handler if provided
        if (customHandler && typeof customHandler === 'function') {
            try {
                customHandler(errorInfo, context);
            } catch (handlerError) {
                console.error('Error in custom error handler:', handlerError);
            }
        }
        
        return errorInfo;
    };
    
    const handleAsyncError = async (asyncFn, context = '', options = {}) => {
        try {
            return await asyncFn();
        } catch (error) {
            handleError(error, context, options);
            throw error; // Re-throw to allow caller to handle if needed
        }
    };
    
    const handleNetworkError = (error, context = '') => {
        const networkOptions = {
            showToast: true,
            severity: 'error',
            life: 6000
        };
        
        if (isNetworkError(error)) {
            return handleError(
                'Network connection failed. Please check your internet connection and try again.',
                context,
                networkOptions
            );
        }
        
        return handleError(error, context, networkOptions);
    };
    
    const handleValidationError = (errors, context = 'form validation') => {
        const validationOptions = {
            showToast: true,
            severity: 'warn',
            life: 4000
        };
        
        if (Array.isArray(errors)) {
            const message = errors.length === 1 
                ? errors[0] 
                : `${errors.length} validation errors found`;
            return handleError(message, context, validationOptions);
        }
        
        return handleError(errors, context, validationOptions);
    };
    
    return {
        handleError,
        handleAsyncError,
        handleNetworkError,
        handleValidationError
    };
}

/**
 * Process error object to extract meaningful information
 * @param {Error|string} error - The error to process
 * @param {string} context - Context information
 * @returns {Object} Processed error information
 */
function processError(error, context) {
    let message = 'An unexpected error occurred';
    let userMessage = 'Something went wrong. Please try again.';
    let code = null;
    let type = 'unknown';
    
    if (typeof error === 'string') {
        message = error;
        userMessage = error;
        type = 'string';
    } else if (error instanceof Error) {
        message = error.message;
        type = 'error_object';
        
        // Handle specific error types
        if (error.name === 'ValidationError') {
            type = 'validation';
            userMessage = message;
        } else if (error.name === 'NetworkError' || isNetworkError(error)) {
            type = 'network';
            userMessage = 'Network connection failed. Please check your internet connection.';
        } else if (error.message.includes('Unauthorized') || error.message.includes('401')) {
            type = 'auth';
            userMessage = 'Your session has expired. Please sign in again.';
        } else if (error.message.includes('Forbidden') || error.message.includes('403')) {
            type = 'permission';
            userMessage = 'You don\'t have permission to perform this action.';
        } else if (error.message.includes('Not Found') || error.message.includes('404')) {
            type = 'not_found';
            userMessage = 'The requested resource was not found.';
        } else if (error.message.includes('timeout') || error.message.includes('Timeout')) {
            type = 'timeout';
            userMessage = 'The request took too long. Please try again.';
        } else {
            // Use original message for other errors, but sanitize it
            userMessage = sanitizeErrorMessage(message);
        }
        
        // Extract error code if available
        code = error.code || error.status || null;
    } else if (typeof error === 'object' && error !== null) {
        // Handle object-like errors (e.g., from API responses)
        message = error.message || error.error || JSON.stringify(error);
        userMessage = error.message || 'An error occurred while processing your request.';
        code = error.code || error.status || null;
        type = 'object';
    }
    
    return {
        message,
        userMessage,
        code,
        type,
        context,
        timestamp: new Date().toISOString()
    };
}

/**
 * Check if error is network-related
 * @param {Error} error - Error to check
 * @returns {boolean} True if network error
 */
function isNetworkError(error) {
    if (!error) return false;
    
    const networkIndicators = [
        'NetworkError',
        'fetch',
        'network',
        'ERR_NETWORK',
        'ERR_INTERNET_DISCONNECTED',
        'Connection failed',
        'Failed to fetch'
    ];
    
    const errorString = error.toString().toLowerCase();
    return networkIndicators.some(indicator => 
        errorString.includes(indicator.toLowerCase())
    );
}

/**
 * Generate user-friendly summary from context
 * @param {string} context - Error context
 * @returns {string} User-friendly summary
 */
function getSummaryFromContext(context) {
    if (!context) return 'Error';
    
    const contextMap = {
        'creating card': 'Card Creation Failed',
        'updating card': 'Card Update Failed',
        'deleting card': 'Card Deletion Failed',
        'loading card': 'Failed to Load Card',
        'uploading image': 'Image Upload Failed',
        'saving content': 'Content Save Failed',
        'loading content': 'Failed to Load Content',
        'processing payment': 'Payment Failed',
        'signing in': 'Sign In Failed',
        'signing up': 'Sign Up Failed',
        'loading profile': 'Profile Load Failed',
        'updating profile': 'Profile Update Failed'
    };
    
    const lowerContext = context.toLowerCase();
    return contextMap[lowerContext] || context.charAt(0).toUpperCase() + context.slice(1);
}

/**
 * Sanitize error messages for user display
 * @param {string} message - Raw error message
 * @returns {string} Sanitized message
 */
function sanitizeErrorMessage(message) {
    if (!message || typeof message !== 'string') {
        return 'An unexpected error occurred';
    }
    
    // Remove technical details that users don't need to see
    const technicalPatterns = [
        /at\s+\w+\.\w+/g, // Stack trace references
        /\w+Error:/g,     // Error type prefixes
        /line\s+\d+/gi,   // Line numbers
        /column\s+\d+/gi, // Column numbers
        /\w+\.js:\d+:\d+/g // File references
    ];
    
    let sanitized = message;
    technicalPatterns.forEach(pattern => {
        sanitized = sanitized.replace(pattern, '');
    });
    
    // Clean up extra whitespace
    sanitized = sanitized.replace(/\s+/g, ' ').trim();
    
    // Ensure first letter is capitalized
    if (sanitized.length > 0) {
        sanitized = sanitized.charAt(0).toUpperCase() + sanitized.slice(1);
    }
    
    // Ensure it ends with a period
    if (sanitized && !sanitized.endsWith('.')) {
        sanitized += '.';
    }
    
    return sanitized || 'An unexpected error occurred.';
}

/**
 * Create a validation error handler for forms
 * @param {Object} validationRules - Object containing validation rules
 * @returns {Function} Validation function
 */
export function createValidationHandler(validationRules) {
    return (formData) => {
        const errors = [];
        
        Object.entries(validationRules).forEach(([field, rules]) => {
            const value = formData[field];
            
            if (rules.required && (!value || (typeof value === 'string' && !value.trim()))) {
                errors.push(`${rules.label || field} is required`);
            }
            
            if (value && rules.minLength && value.length < rules.minLength) {
                errors.push(`${rules.label || field} must be at least ${rules.minLength} characters`);
            }
            
            if (value && rules.maxLength && value.length > rules.maxLength) {
                errors.push(`${rules.label || field} must not exceed ${rules.maxLength} characters`);
            }
            
            if (value && rules.pattern && !rules.pattern.test(value)) {
                errors.push(rules.message || `${rules.label || field} format is invalid`);
            }
            
            if (value && rules.custom && typeof rules.custom === 'function') {
                const customResult = rules.custom(value);
                if (customResult !== true) {
                    errors.push(customResult || `${rules.label || field} is invalid`);
                }
            }
        });
        
        return {
            isValid: errors.length === 0,
            errors
        };
    };
}

/**
 * Utility for handling specific error types commonly seen in the app
 */
export const ErrorTypes = {
    NETWORK: 'network',
    VALIDATION: 'validation',
    AUTH: 'auth',
    PERMISSION: 'permission',
    NOT_FOUND: 'not_found',
    TIMEOUT: 'timeout',
    UNKNOWN: 'unknown'
};

/**
 * Pre-configured error handlers for common scenarios
 */
export const CommonErrorHandlers = {
    cardOperation: (error, operation) => {
        const { handleError } = useErrorHandler();
        return handleError(error, `${operation} card`, { life: 4000 });
    },
    
    contentOperation: (error, operation) => {
        const { handleError } = useErrorHandler();
        return handleError(error, `${operation} content`, { life: 4000 });
    },
    
    authOperation: (error, operation) => {
        const { handleError } = useErrorHandler();
        return handleError(error, `${operation}`, { 
            severity: 'warn',
            life: 6000 
        });
    },
    
    fileUpload: (error) => {
        const { handleError } = useErrorHandler();
        return handleError(error, 'uploading file', { 
            severity: 'error',
            life: 5000 
        });
    }
};