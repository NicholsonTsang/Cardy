/**
 * Validation utilities for card import/export functionality
 * Ensures data integrity and provides user-friendly error messages
 */

/**
 * Validate card data structure
 * @param {Object} card - Card object to validate
 * @returns {Object} Validation result with isValid flag and errors
 */
export function validateCardData(card) {
  const errors = [];
  const warnings = [];

  // Required fields
  if (!card.card_name || card.card_name.trim() === '') {
    errors.push('Card name is required');
  }

  // Length validations
  if (card.card_name && card.card_name.length > 100) {
    errors.push('Card name must be less than 100 characters');
  }

  if (card.card_description && card.card_description.length > 500) {
    errors.push('Card description must be less than 500 characters');
  }

  if (card.ai_prompt && card.ai_prompt.length > 2000) {
    warnings.push('AI prompt is very long and may affect performance');
  }

  // Email validation
  if (card.business_email && !isValidEmail(card.business_email)) {
    warnings.push('Invalid email format');
  }

  // URL validation
  if (card.business_website && !isValidUrl(card.business_website)) {
    warnings.push('Invalid website URL format');
  }

  // Phone validation
  if (card.business_phone && !isValidPhone(card.business_phone)) {
    warnings.push('Invalid phone number format');
  }

  return {
    isValid: errors.length === 0,
    errors,
    warnings
  };
}

/**
 * Validate content item data structure
 * @param {Object} content - Content item to validate
 * @returns {Object} Validation result
 */
export function validateContentData(content) {
  const errors = [];
  const warnings = [];

  // Required fields
  if (!content.title || content.title.trim() === '') {
    errors.push('Content title is required');
  }

  if (!content.type) {
    errors.push('Content type is required');
  }

  // Valid content types
  const validTypes = ['text', 'image', 'video', 'audio', 'link'];
  if (content.type && !validTypes.includes(content.type)) {
    errors.push(`Invalid content type: ${content.type}. Must be one of: ${validTypes.join(', ')}`);
  }

  // Media validation
  if (['image', 'video', 'audio'].includes(content.type)) {
    if (!content.media_url || content.media_url.trim() === '') {
      warnings.push('Media content should have a media URL');
    } else if (!isValidUrl(content.media_url)) {
      warnings.push('Invalid media URL format');
    }
  }

  // Content length validation
  if (content.content && content.content.length > 5000) {
    warnings.push('Content text is very long and may affect display');
  }

  // Order position validation
  if (content.order_position && (isNaN(content.order_position) || content.order_position < 0)) {
    errors.push('Order position must be a positive number');
  }

  return {
    isValid: errors.length === 0,
    errors,
    warnings
  };
}

/**
 * Validate batch of cards and content for import
 * @param {Array} cards - Array of card objects
 * @param {Array} content - Array of content objects
 * @returns {Object} Validation summary
 */
export function validateImportBatch(cards, content) {
  const result = {
    isValid: true,
    cards: { valid: 0, errors: 0, warnings: 0 },
    content: { valid: 0, errors: 0, warnings: 0 },
    errors: [],
    warnings: [],
    details: []
  };

  // Track card names for uniqueness
  const cardNames = new Set();

  // Validate cards
  cards.forEach((card, index) => {
    // Check for duplicate names
    if (cardNames.has(card.card_name)) {
      result.errors.push(`Duplicate card name at row ${index + 1}: ${card.card_name}`);
      result.cards.errors++;
      result.isValid = false;
      return;
    }
    cardNames.add(card.card_name);

    const validation = validateCardData(card);
    
    if (validation.isValid) {
      result.cards.valid++;
    } else {
      result.cards.errors++;
      result.isValid = false;
      validation.errors.forEach(error => {
        result.errors.push(`Card "${card.card_name}": ${error}`);
      });
    }

    if (validation.warnings.length > 0) {
      result.cards.warnings++;
      validation.warnings.forEach(warning => {
        result.warnings.push(`Card "${card.card_name}": ${warning}`);
      });
    }
  });

  // Validate content items
  content.forEach((item, index) => {
    // Check if card exists
    if (!cardNames.has(item.card_name)) {
      result.errors.push(`Content row ${index + 1}: Card "${item.card_name}" not found`);
      result.content.errors++;
      result.isValid = false;
      return;
    }

    const validation = validateContentData(item);
    
    if (validation.isValid) {
      result.content.valid++;
    } else {
      result.content.errors++;
      result.isValid = false;
      validation.errors.forEach(error => {
        result.errors.push(`Content "${item.title}": ${error}`);
      });
    }

    if (validation.warnings.length > 0) {
      result.content.warnings++;
      validation.warnings.forEach(warning => {
        result.warnings.push(`Content "${item.title}": ${warning}`);
      });
    }
  });

  return result;
}

/**
 * Clean and normalize card data for import
 * @param {Object} card - Raw card data
 * @returns {Object} Cleaned card data
 */
export function cleanCardData(card) {
  return {
    id: card.id || null,
    card_name: (card.card_name || '').trim(),
    card_description: (card.card_description || '').trim(),
    card_type: (card.card_type || 'general').trim().toLowerCase(),
    ai_prompt: (card.ai_prompt || '').trim(),
    tags: (card.tags || '').trim(),
    business_name: (card.business_name || '').trim(),
    business_address: (card.business_address || '').trim(),
    business_email: (card.business_email || '').trim().toLowerCase(),
    business_phone: (card.business_phone || '').trim(),
    business_website: cleanUrl(card.business_website || '')
  };
}

/**
 * Clean and normalize content data for import
 * @param {Object} content - Raw content data
 * @returns {Object} Cleaned content data
 */
export function cleanContentData(content) {
  return {
    id: content.id || null,
    card_name: (content.card_name || '').trim(),
    parent_id: content.parent_id || null,
    type: (content.type || 'text').trim().toLowerCase(),
    title: (content.title || '').trim(),
    content: (content.content || '').trim(),
    ai_metadata: (content.ai_metadata || '').trim(),
    order_position: parseInt(content.order_position) || 0,
    media_url: (content.media_url || '').trim(),
    media_type: (content.media_type || '').trim()
  };
}

/**
 * Generate import summary statistics
 * @param {Array} cards - Validated cards
 * @param {Array} content - Validated content
 * @returns {Object} Summary statistics
 */
export function generateImportSummary(cards, content) {
  const summary = {
    totalCards: cards.length,
    newCards: cards.filter(c => !c.id).length,
    updateCards: cards.filter(c => c.id).length,
    totalContent: content.length,
    newContent: content.filter(c => !c.id).length,
    updateContent: content.filter(c => c.id).length,
    estimatedTime: calculateEstimatedTime(cards.length, content.length)
  };

  return summary;
}

/**
 * Calculate estimated import time
 * @param {number} cardCount - Number of cards
 * @param {number} contentCount - Number of content items
 * @returns {string} Estimated time string
 */
function calculateEstimatedTime(cardCount, contentCount) {
  // Rough estimates: 0.5s per card, 0.2s per content item
  const seconds = (cardCount * 0.5) + (contentCount * 0.2);
  
  if (seconds < 60) {
    return `${Math.ceil(seconds)} seconds`;
  } else if (seconds < 3600) {
    return `${Math.ceil(seconds / 60)} minutes`;
  } else {
    return `${Math.ceil(seconds / 3600)} hours`;
  }
}

/**
 * Validate email format
 * @param {string} email - Email to validate
 * @returns {boolean} Is valid email
 */
function isValidEmail(email) {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return emailRegex.test(email);
}

/**
 * Validate URL format
 * @param {string} url - URL to validate
 * @returns {boolean} Is valid URL
 */
function isValidUrl(url) {
  try {
    new URL(url);
    return true;
  } catch {
    // Try with https:// prefix
    try {
      new URL('https://' + url);
      return true;
    } catch {
      return false;
    }
  }
}

/**
 * Validate phone number format
 * @param {string} phone - Phone to validate
 * @returns {boolean} Is valid phone
 */
function isValidPhone(phone) {
  // Basic phone validation - digits, spaces, dashes, parentheses, plus
  const phoneRegex = /^[\+]?[\d\s\-\(\)]{10,15}$/;
  return phoneRegex.test(phone);
}

/**
 * Clean URL format
 * @param {string} url - URL to clean
 * @returns {string} Cleaned URL
 */
function cleanUrl(url) {
  if (!url) return '';
  
  const cleaned = url.trim();
  
  // Add https:// if no protocol
  if (cleaned && !cleaned.match(/^https?:\/\//)) {
    return 'https://' + cleaned;
  }
  
  return cleaned;
}

export default {
  validateCardData,
  validateContentData,
  validateImportBatch,
  cleanCardData,
  cleanContentData,
  generateImportSummary
};