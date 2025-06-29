/**
 * Theme configuration and utilities for the Cardy application
 * Provides consistent styling, component theming, and responsive design utilities
 */

/**
 * Design system configuration
 */
export const DesignSystem = {
    colors: {
        primary: {
            50: '#eff6ff',
            100: '#dbeafe',
            200: '#bfdbfe',
            300: '#93c5fd',
            400: '#60a5fa',
            500: '#3b82f6',
            600: '#2563eb',
            700: '#1d4ed8',
            800: '#1e40af',
            900: '#1e3a8a',
        },
        slate: {
            50: '#f8fafc',
            100: '#f1f5f9',
            200: '#e2e8f0',
            300: '#cbd5e1',
            400: '#94a3b8',
            500: '#64748b',
            600: '#475569',
            700: '#334155',
            800: '#1e293b',
            900: '#0f172a',
        },
        success: {
            50: '#f0fdf4',
            500: '#22c55e',
            600: '#16a34a',
        },
        warning: {
            50: '#fffbeb',
            500: '#f59e0b',
            600: '#d97706',
        },
        error: {
            50: '#fef2f2',
            500: '#ef4444',
            600: '#dc2626',
        }
    },
    
    typography: {
        fontFamily: {
            primary: ['Inter', '-apple-system', 'BlinkMacSystemFont', 'Segoe UI', 'Roboto', 'sans-serif']
        },
        fontSize: {
            xs: '0.75rem',      // 12px
            sm: '0.875rem',     // 14px
            base: '1rem',       // 16px
            lg: '1.125rem',     // 18px
            xl: '1.25rem',      // 20px
            '2xl': '1.5rem',    // 24px
            '3xl': '1.875rem',  // 30px
        },
        lineHeight: {
            tight: 1.2,
            normal: 1.5,
            relaxed: 1.75
        },
        fontWeight: {
            normal: 400,
            medium: 500,
            semibold: 600,
            bold: 700
        }
    },
    
    spacing: {
        xs: '0.25rem',    // 4px
        sm: '0.5rem',     // 8px
        md: '1rem',       // 16px
        lg: '1.5rem',     // 24px
        xl: '2rem',       // 32px
        '2xl': '3rem',    // 48px
        '3xl': '4rem',    // 64px
    },
    
    borderRadius: {
        sm: '0.375rem',   // 6px
        md: '0.5rem',     // 8px
        lg: '0.75rem',    // 12px
        xl: '1rem',       // 16px
        '2xl': '1.5rem',  // 24px
    },
    
    shadows: {
        sm: '0 1px 2px 0 rgba(0, 0, 0, 0.05)',
        md: '0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -1px rgba(0, 0, 0, 0.06)',
        lg: '0 10px 15px -3px rgba(0, 0, 0, 0.1), 0 4px 6px -2px rgba(0, 0, 0, 0.05)',
        soft: '0 2px 15px -3px rgba(0, 0, 0, 0.07), 0 10px 20px -2px rgba(0, 0, 0, 0.04)',
        medium: '0 4px 25px -5px rgba(0, 0, 0, 0.1), 0 10px 10px -5px rgba(0, 0, 0, 0.04)',
        large: '0 10px 40px -10px rgba(0, 0, 0, 0.1), 0 2px 4px -1px rgba(0, 0, 0, 0.06)'
    },
    
    aspectRatios: {
        card: '2/3',        // Standard card ratio (width/height)
        content: '16/9',    // Content items (video-like)
        square: '1/1',      // Square images
        wide: '4/3'         // Wide format
    }
};

/**
 * PrimeVue component theme overrides
 * These provide consistent styling across all PrimeVue components
 */
export const PrimeVueTheme = {
    // Button overrides
    button: {
        fontSize: DesignSystem.typography.fontSize.sm,
        fontWeight: DesignSystem.typography.fontWeight.medium,
        borderRadius: DesignSystem.borderRadius.md,
        padding: {
            sm: '0.375rem 0.75rem',
            md: '0.5rem 1rem',
            lg: '0.75rem 1.25rem'
        }
    },
    
    // Input overrides
    input: {
        fontSize: DesignSystem.typography.fontSize.sm,
        borderRadius: DesignSystem.borderRadius.md,
        padding: '0.75rem 1rem',
        borderColor: DesignSystem.colors.slate[300],
        focusBorderColor: DesignSystem.colors.primary[500],
        focusRingColor: DesignSystem.colors.primary[500]
    },
    
    // Card overrides
    card: {
        borderRadius: DesignSystem.borderRadius.xl,
        shadow: DesignSystem.shadows.soft,
        padding: DesignSystem.spacing.lg
    },
    
    // Dialog overrides
    dialog: {
        borderRadius: DesignSystem.borderRadius.xl,
        shadow: DesignSystem.shadows.large
    },
    
    // Toast overrides
    toast: {
        borderRadius: DesignSystem.borderRadius.lg,
        fontSize: DesignSystem.typography.fontSize.sm
    }
};

/**
 * Generate CSS custom properties for design system
 * @returns {string} CSS custom properties
 */
export function generateCSSCustomProperties() {
    const properties = [];
    
    // Colors
    Object.entries(DesignSystem.colors).forEach(([name, shades]) => {
        if (typeof shades === 'object') {
            Object.entries(shades).forEach(([shade, value]) => {
                properties.push(`--color-${name}-${shade}: ${value};`);
            });
        } else {
            properties.push(`--color-${name}: ${shades};`);
        }
    });
    
    // Typography
    Object.entries(DesignSystem.typography.fontSize).forEach(([name, value]) => {
        properties.push(`--font-size-${name}: ${value};`);
    });
    
    // Spacing
    Object.entries(DesignSystem.spacing).forEach(([name, value]) => {
        properties.push(`--spacing-${name}: ${value};`);
    });
    
    // Border radius
    Object.entries(DesignSystem.borderRadius).forEach(([name, value]) => {
        properties.push(`--border-radius-${name}: ${value};`);
    });
    
    // Shadows
    Object.entries(DesignSystem.shadows).forEach(([name, value]) => {
        properties.push(`--shadow-${name}: ${value};`);
    });
    
    return `:root {\n  ${properties.join('\n  ')}\n}`;
}

/**
 * Utility functions for responsive design
 */
export const ResponsiveUtils = {
    breakpoints: {
        sm: '640px',
        md: '768px',
        lg: '1024px',
        xl: '1280px',
        '2xl': '1536px'
    },
    
    /**
     * Generate responsive CSS for a property
     * @param {string} property - CSS property name
     * @param {Object} values - Object with breakpoint values
     * @returns {string} CSS media queries
     */
    responsive: (property, values) => {
        const rules = [];
        
        if (values.base) {
            rules.push(`${property}: ${values.base};`);
        }
        
        Object.entries(values).forEach(([breakpoint, value]) => {
            if (breakpoint !== 'base' && ResponsiveUtils.breakpoints[breakpoint]) {
                rules.push(`@media (min-width: ${ResponsiveUtils.breakpoints[breakpoint]}) {
          ${property}: ${value};
        }`);
            }
        });
        
        return rules.join('\n        ');
    }
};

/**
 * Component-specific styling utilities
 */
export const ComponentStyles = {
    /**
     * Generate card container styles
     * @param {Object} options - Styling options
     * @returns {Object} CSS-in-JS styles
     */
    cardContainer: (options = {}) => ({
        backgroundColor: 'white',
        borderRadius: DesignSystem.borderRadius.xl,
        boxShadow: DesignSystem.shadows.soft,
        border: `1px solid ${DesignSystem.colors.slate[200]}`,
        padding: DesignSystem.spacing.lg,
        ...options
    }),
    
    /**
     * Generate button styles
     * @param {string} variant - Button variant (primary, secondary, etc.)
     * @param {string} size - Button size (sm, md, lg)
     * @returns {Object} CSS-in-JS styles
     */
    button: (variant = 'primary', size = 'md') => {
        const baseStyles = {
            fontSize: PrimeVueTheme.button.fontSize,
            fontWeight: PrimeVueTheme.button.fontWeight,
            borderRadius: PrimeVueTheme.button.borderRadius,
            padding: PrimeVueTheme.button.padding[size],
            border: 'none',
            cursor: 'pointer',
            transition: 'all 0.2s ease-in-out',
            display: 'inline-flex',
            alignItems: 'center',
            justifyContent: 'center',
            gap: '0.5rem'
        };
        
        const variantStyles = {
            primary: {
                backgroundColor: DesignSystem.colors.primary[500],
                color: 'white',
                '&:hover': {
                    backgroundColor: DesignSystem.colors.primary[600]
                }
            },
            secondary: {
                backgroundColor: DesignSystem.colors.slate[100],
                color: DesignSystem.colors.slate[700],
                '&:hover': {
                    backgroundColor: DesignSystem.colors.slate[200]
                }
            },
            success: {
                backgroundColor: DesignSystem.colors.success[500],
                color: 'white',
                '&:hover': {
                    backgroundColor: DesignSystem.colors.success[600]
                }
            },
            warning: {
                backgroundColor: DesignSystem.colors.warning[500],
                color: 'white',
                '&:hover': {
                    backgroundColor: DesignSystem.colors.warning[600]
                }
            },
            error: {
                backgroundColor: DesignSystem.colors.error[500],
                color: 'white',
                '&:hover': {
                    backgroundColor: DesignSystem.colors.error[600]
                }
            }
        };
        
        return {
            ...baseStyles,
            ...variantStyles[variant]
        };
    },
    
    /**
     * Generate form field styles
     * @param {boolean} hasError - Whether field has validation error
     * @returns {Object} CSS-in-JS styles
     */
    formField: (hasError = false) => ({
        fontSize: PrimeVueTheme.input.fontSize,
        borderRadius: PrimeVueTheme.input.borderRadius,
        padding: PrimeVueTheme.input.padding,
        border: `1px solid ${hasError ? DesignSystem.colors.error[500] : DesignSystem.colors.slate[300]}`,
        backgroundColor: 'white',
        transition: 'border-color 0.2s ease-in-out, box-shadow 0.2s ease-in-out',
        '&:focus': {
            outline: 'none',
            borderColor: hasError ? DesignSystem.colors.error[500] : DesignSystem.colors.primary[500],
            boxShadow: `0 0 0 3px ${hasError ? DesignSystem.colors.error[500] : DesignSystem.colors.primary[500]}20`
        }
    }),
    
    /**
     * Generate card image container styles
     * @returns {Object} CSS-in-JS styles
     */
    cardImageContainer: () => ({
        aspectRatio: DesignSystem.aspectRatios.card,
        borderRadius: DesignSystem.borderRadius.lg,
        overflow: 'hidden',
        backgroundColor: DesignSystem.colors.slate[50],
        border: `2px dashed ${DesignSystem.colors.slate[300]}`,
        position: 'relative',
        transition: 'all 0.2s ease-in-out',
        '&:hover': {
            borderColor: DesignSystem.colors.primary[400],
            backgroundColor: `${DesignSystem.colors.primary[50]}80`
        }
    })
};

/**
 * Animation utilities
 */
export const Animations = {
    fadeIn: {
        animation: 'fadeIn 0.3s ease-in-out'
    },
    slideUp: {
        animation: 'slideUp 0.3s ease-out'
    },
    scaleIn: {
        animation: 'scaleIn 0.2s ease-out'
    },
    
    // Generate keyframes CSS
    keyframes: `
        @keyframes fadeIn {
            from { opacity: 0; }
            to { opacity: 1; }
        }
        
        @keyframes slideUp {
            from { 
                opacity: 0;
                transform: translateY(10px);
            }
            to { 
                opacity: 1;
                transform: translateY(0);
            }
        }
        
        @keyframes scaleIn {
            from { 
                opacity: 0;
                transform: scale(0.95);
            }
            to { 
                opacity: 1;
                transform: scale(1);
            }
        }
    `
};

/**
 * Create a theme provider for components
 * @param {Object} customTheme - Custom theme overrides
 * @returns {Object} Merged theme configuration
 */
export function createTheme(customTheme = {}) {
    return {
        ...DesignSystem,
        ...customTheme,
        colors: {
            ...DesignSystem.colors,
            ...customTheme.colors
        },
        typography: {
            ...DesignSystem.typography,
            ...customTheme.typography
        }
    };
}

/**
 * Generate PrimeVue theme CSS overrides
 * @returns {string} CSS for PrimeVue component styling
 */
export function generatePrimeVueOverrides() {
    return `
        /* PrimeVue Component Overrides */
        
        /* Button Styles */
        .p-button {
            font-size: ${DesignSystem.typography.fontSize.sm};
            font-weight: ${DesignSystem.typography.fontWeight.medium};
            border-radius: ${DesignSystem.borderRadius.md};
            transition: all 0.2s ease-in-out;
        }
        
        .p-button-sm {
            padding: ${PrimeVueTheme.button.padding.sm};
        }
        
        .p-button:not(.p-button-sm):not(.p-button-lg) {
            padding: ${PrimeVueTheme.button.padding.md};
        }
        
        .p-button-lg {
            padding: ${PrimeVueTheme.button.padding.lg};
        }
        
        /* Input Styles */
        .p-inputtext, .p-textarea, .p-dropdown {
            font-size: ${DesignSystem.typography.fontSize.sm};
            border-radius: ${DesignSystem.borderRadius.md};
            border-color: ${DesignSystem.colors.slate[300]};
            transition: all 0.2s ease-in-out;
        }
        
        .p-inputtext {
            padding: ${PrimeVueTheme.input.padding};
        }
        
        .p-inputtext:focus, .p-textarea:focus, .p-dropdown:focus {
            border-color: ${DesignSystem.colors.primary[500]};
            box-shadow: 0 0 0 3px ${DesignSystem.colors.primary[500]}20;
        }
        
        /* Dropdown Styles */
        .p-dropdown-label {
            font-size: ${DesignSystem.typography.fontSize.sm};
            padding: 0.75rem 1rem;
        }
        
        /* Card Styles */
        .p-card {
            border-radius: ${DesignSystem.borderRadius.xl};
            box-shadow: ${DesignSystem.shadows.soft};
            border: 1px solid ${DesignSystem.colors.slate[200]};
        }
        
        .p-card .p-card-body {
            padding: ${DesignSystem.spacing.lg};
        }
        
        /* Dialog Styles */
        .p-dialog {
            border-radius: ${DesignSystem.borderRadius.xl};
            box-shadow: ${DesignSystem.shadows.large};
        }
        
        /* Toast Styles */
        .p-toast .p-toast-message {
            border-radius: ${DesignSystem.borderRadius.lg};
            font-size: ${DesignSystem.typography.fontSize.sm};
            box-shadow: ${DesignSystem.shadows.medium};
        }
        
        /* File Upload Styles */
        .p-fileupload-basic .p-button {
            width: 100%;
            justify-content: center;
        }
        
        /* Toggle Switch Styles */
        .p-toggleswitch {
            border-radius: ${DesignSystem.borderRadius.md};
        }
        
        /* Tag Styles */
        .p-tag {
            font-size: ${DesignSystem.typography.fontSize.xs};
            padding: 0.25rem 0.5rem;
            border-radius: ${DesignSystem.borderRadius.sm};
        }
        
        /* Progress Spinner Styles */
        .p-progress-spinner circle {
            stroke: ${DesignSystem.colors.primary[500]};
        }
    `;
}