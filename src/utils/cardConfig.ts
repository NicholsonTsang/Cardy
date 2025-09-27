/**
 * Card configuration utilities
 */

/**
 * Get the card aspect ratio from environment variables
 * @returns {string} The aspect ratio in CSS format (e.g., "2/3")
 */
export const getCardAspectRatio = (): string => {
  const width = import.meta.env.VITE_CARD_ASPECT_RATIO_WIDTH || '2';
  const height = import.meta.env.VITE_CARD_ASPECT_RATIO_HEIGHT || '3';
  return `${width}/${height}`;
};

/**
 * Get the card aspect ratio as CSS custom property value
 * @returns {string} The aspect ratio for use in CSS custom properties
 */
export const getCardAspectRatioValue = (): string => {
  return getCardAspectRatio();
};

/**
 * Get the card aspect ratio as a numeric value for cropping calculations
 * @returns {number} The aspect ratio as a decimal number
 */
export const getCardAspectRatioNumber = (): number => {
  const width = parseFloat(import.meta.env.VITE_CARD_ASPECT_RATIO_WIDTH || '2');
  const height = parseFloat(import.meta.env.VITE_CARD_ASPECT_RATIO_HEIGHT || '3');
  return width / height;
};

/**
 * Get the card aspect ratio display string
 * @returns {string} The aspect ratio in display format (e.g., "2:3")
 */
export const getCardAspectRatioDisplay = (): string => {
  const width = import.meta.env.VITE_CARD_ASPECT_RATIO_WIDTH || '2';
  const height = import.meta.env.VITE_CARD_ASPECT_RATIO_HEIGHT || '3';
  return `${width}:${height}`;
};

/**
 * Check if an image needs cropping based on its dimensions and the target aspect ratio
 * @param {number} imageWidth - The width of the image
 * @param {number} imageHeight - The height of the image
 * @param {number} tolerance - The tolerance for aspect ratio comparison (default: 0.01)
 * @returns {boolean} True if the image needs cropping, false otherwise
 */
export const imageNeedsCropping = (imageWidth: number, imageHeight: number, tolerance: number = 0.01): boolean => {
  const imageAspectRatio = imageWidth / imageHeight;
  const targetAspectRatio = getCardAspectRatioNumber();
  return Math.abs(imageAspectRatio - targetAspectRatio) > tolerance;
};

/**
 * Load image dimensions from a file
 * @param {File} file - The image file
 * @returns {Promise<{width: number, height: number}>} Promise resolving to image dimensions
 */
export const getImageDimensions = (file: File): Promise<{width: number, height: number}> => {
  return new Promise((resolve, reject) => {
    const img = new Image();
    img.onload = () => {
      resolve({ width: img.width, height: img.height });
    };
    img.onerror = reject;
    img.src = URL.createObjectURL(file);
  });
};
