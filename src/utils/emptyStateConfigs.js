/**
 * Predefined empty state configurations for common DataTable scenarios
 * Provides consistent messaging and actions across the CardStudio application
 */

export const emptyStateConfigs = {
    // Admin Management Tables
    users: {
        noData: {
            icon: 'pi pi-users',
            title: 'No Users Found',
            description: 'No user accounts have been created yet.',
            buttonLabel: 'Invite Users',
            buttonIcon: 'pi pi-user-plus',
            variant: 'default'
        },
        filtered: {
            icon: 'pi pi-search-slash',
            title: 'No Users Found',
            description: 'No users match your current filter criteria. Try adjusting your search or filters.',
            buttonLabel: 'Clear Filters',
            buttonIcon: 'pi pi-filter-slash',
            variant: 'search'
        }
    },
    
    verifications: {
        noData: {
            icon: 'pi pi-check-circle',
            title: 'All Caught Up!',
            description: 'No verification requests require attention at this time.',
            showButton: false,
            variant: 'positive'
        },
        filtered: {
            icon: 'pi pi-search-slash',
            title: 'No Verifications Found',
            description: 'No verification requests match your search criteria.',
            buttonLabel: 'Clear Filters',
            buttonIcon: 'pi pi-filter-slash',
            variant: 'search'
        }
    },
    
    printRequests: {
        noData: {
            icon: 'pi pi-check-circle',
            title: 'All Orders Processed!',
            description: 'No print requests are pending at this time.',
            showButton: false,
            variant: 'positive'
        },
        filtered: {
            icon: 'pi pi-search-slash',
            title: 'No Print Requests Found',
            description: 'No print requests match your search criteria.',
            buttonLabel: 'Clear Filters',
            buttonIcon: 'pi pi-filter-slash',
            variant: 'search'
        }
    },
    
    batches: {
        noData: {
            icon: 'pi pi-check-circle',
            title: 'All Caught Up!',
            description: 'No batches require payment attention at this time.',
            showButton: false,
            variant: 'positive'
        },
        filtered: {
            icon: 'pi pi-search-slash',
            title: 'No Batches Found',
            description: 'No batches match your search criteria.',
            buttonLabel: 'Clear Filters',
            buttonIcon: 'pi pi-filter-slash',
            variant: 'search'
        }
    },
    
    // Card Management Tables
    cards: {
        noData: {
            icon: 'pi pi-id-card',
            title: 'No Cards Yet',
            description: 'Start creating your first card design to get started.',
            buttonLabel: 'Create Card',
            buttonIcon: 'pi pi-plus',
            variant: 'default'
        },
        filtered: {
            icon: 'pi pi-search-slash',
            title: 'No Cards Found',
            description: 'No cards match your search criteria. Try adjusting your search or filters.',
            buttonLabel: 'Clear Filters',
            buttonIcon: 'pi pi-filter-slash',
            variant: 'search'
        }
    },
    
    issuedCards: {
        noData: {
            icon: 'pi pi-credit-card',
            title: 'No Cards Issued',
            description: 'No cards have been issued yet. Create a batch to start issuing cards.',
            buttonLabel: 'Issue Cards',
            buttonIcon: 'pi pi-send',
            variant: 'default'
        },
        filtered: {
            icon: 'pi pi-search-slash',
            title: 'No Issued Cards Found',
            description: 'No issued cards match your search criteria.',
            buttonLabel: 'Clear Filters',
            buttonIcon: 'pi pi-filter-slash',
            variant: 'search'
        }
    },
    
    cardBatches: {
        noData: {
            icon: 'pi pi-box',
            title: 'No Batches Created',
            description: 'No batches have been created yet for this card design.',
            buttonLabel: 'Issue New Batch',
            buttonIcon: 'pi pi-send',
            variant: 'default'
        },
        filtered: {
            icon: 'pi pi-search-slash',
            title: 'No Batches Found',
            description: 'No batches match your search criteria.',
            buttonLabel: 'Clear Filters',
            buttonIcon: 'pi pi-filter-slash',
            variant: 'search'
        }
    },
    
    // Content Management
    contentItems: {
        noData: {
            icon: 'pi pi-file-edit',
            title: 'No Content Items',
            description: 'Create your first content item to get started.',
            buttonLabel: 'Add Content',
            buttonIcon: 'pi pi-plus',
            variant: 'default'
        },
        filtered: {
            icon: 'pi pi-search-slash',
            title: 'No Content Found',
            description: 'No content items match your search criteria.',
            buttonLabel: 'Clear Search',
            buttonIcon: 'pi pi-times',
            variant: 'search'
        }
    },
    
    // Generic fallbacks
    generic: {
        noData: {
            icon: 'pi pi-inbox',
            title: 'No Data Available',
            description: 'There is no data to display at this time.',
            showButton: false,
            variant: 'default'
        },
        filtered: {
            icon: 'pi pi-search-slash',
            title: 'No Results Found',
            description: 'No items match your search criteria.',
            buttonLabel: 'Clear Filters',
            buttonIcon: 'pi pi-filter-slash',
            variant: 'search'
        },
        loading: {
            icon: 'pi pi-spin pi-spinner',
            title: 'Loading...',
            description: 'Please wait while we fetch your data.',
            showButton: false,
            variant: 'default'
        },
        error: {
            icon: 'pi pi-exclamation-triangle',
            title: 'Unable to Load Data',
            description: 'There was a problem loading the data. Please try again.',
            buttonLabel: 'Retry',
            buttonIcon: 'pi pi-refresh',
            variant: 'error'
        }
    }
};

/**
 * Helper function to get empty state configuration
 * @param {string} tableType - Type of table (users, cards, etc.)
 * @param {string} scenario - Scenario (noData, filtered, loading, error)
 * @param {Object} overrides - Custom overrides for the configuration
 * @returns {Object} Empty state configuration
 */
export function getEmptyStateConfig(tableType, scenario = 'noData', overrides = {}) {
    const config = emptyStateConfigs[tableType]?.[scenario] || emptyStateConfigs.generic[scenario] || emptyStateConfigs.generic.noData;
    
    return {
        ...config,
        ...overrides
    };
}

/**
 * Helper function to determine appropriate scenario based on data state
 * @param {Array} data - The data array
 * @param {boolean} isLoading - Loading state
 * @param {boolean} hasError - Error state
 * @param {boolean} hasFilters - Whether filters are applied
 * @returns {string} Appropriate scenario key
 */
export function determineEmptyScenario(data, isLoading = false, hasError = false, hasFilters = false) {
    if (isLoading) return 'loading';
    if (hasError) return 'error';
    if (data.length === 0 && hasFilters) return 'filtered';
    if (data.length === 0) return 'noData';
    return null; // Data exists, no empty state needed
}

export default {
    emptyStateConfigs,
    getEmptyStateConfig,
    determineEmptyScenario
};