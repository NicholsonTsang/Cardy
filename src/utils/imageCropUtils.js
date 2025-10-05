/**
 * Utility functions for applying crop parameters to images
 * Used during Excel import to regenerate cropped images from original images + crop parameters
 */

/**
 * Apply crop parameters to an image file and generate a cropped image
 * @param {File} imageFile - Original image file
 * @param {Object} cropParams - Crop parameters {x, y, zoom, width, height, etc.}
 * @param {number} aspectRatio - Target aspect ratio (width/height)
 * @returns {Promise<File>} Cropped image file
 */
export async function applyCropParametersToImage(imageFile, cropParams, aspectRatio = 2/3) {
  return new Promise((resolve, reject) => {
    // Load the image
    const img = new Image();
    const reader = new FileReader();
    
    reader.onload = (e) => {
      img.onload = () => {
        try {
          // Create canvas for cropping
          const canvas = document.createElement('canvas');
          const ctx = canvas.getContext('2d');
          
          const naturalWidth = img.naturalWidth;
          const naturalHeight = img.naturalHeight;
          
          // Extract crop parameters
          const zoom = cropParams.zoom || 1;
          const x = cropParams.x || 0;
          const y = cropParams.y || 0;
          
          // Calculate crop frame dimensions based on aspect ratio
          // The cropParameters should contain the actual crop area from the original cropper
          const cropWidth = cropParams.width || naturalWidth;
          const cropHeight = cropParams.height || naturalHeight;
          
          // Calculate source coordinates (what part of the original image to crop)
          const sourceX = x;
          const sourceY = y;
          const sourceWidth = cropWidth;
          const sourceHeight = cropHeight;
          
          // Clamp to image bounds
          const actualSourceX = Math.max(0, sourceX);
          const actualSourceY = Math.max(0, sourceY);
          const actualSourceRight = Math.min(sourceX + sourceWidth, naturalWidth);
          const actualSourceBottom = Math.min(sourceY + sourceHeight, naturalHeight);
          const actualSourceWidth = Math.max(0, actualSourceRight - actualSourceX);
          const actualSourceHeight = Math.max(0, actualSourceBottom - actualSourceY);
          
          // Set canvas size based on aspect ratio
          const outputSize = 800;
          let canvasWidth, canvasHeight;
          if (aspectRatio >= 1) {
            canvasWidth = outputSize;
            canvasHeight = outputSize / aspectRatio;
          } else {
            canvasHeight = outputSize;
            canvasWidth = outputSize * aspectRatio;
          }
          
          canvas.width = canvasWidth;
          canvas.height = canvasHeight;
          
          // Calculate destination coordinates
          const destOffsetX = Math.max(0, -sourceX) / sourceWidth;
          const destOffsetY = Math.max(0, -sourceY) / sourceHeight;
          const destScaleX = actualSourceWidth / sourceWidth;
          const destScaleY = actualSourceHeight / sourceHeight;
          
          const destX = destOffsetX * canvasWidth;
          const destY = destOffsetY * canvasHeight;
          const destWidth = destScaleX * canvasWidth;
          const destHeight = destScaleY * canvasHeight;
          
          // Fill with white background
          ctx.fillStyle = '#ffffff';
          ctx.fillRect(0, 0, canvasWidth, canvasHeight);
          
          // Draw cropped image
          if (actualSourceWidth > 0 && actualSourceHeight > 0) {
            ctx.drawImage(
              img,
              actualSourceX,
              actualSourceY,
              actualSourceWidth,
              actualSourceHeight,
              destX,
              destY,
              destWidth,
              destHeight
            );
          }
          
          // Convert canvas to blob then to File
          canvas.toBlob((blob) => {
            if (!blob) {
              reject(new Error('Failed to create cropped image blob'));
              return;
            }
            
            const croppedFile = new File(
              [blob],
              imageFile.name.replace(/\.(jpg|jpeg|png|webp)$/i, '-cropped.jpg'),
              { type: 'image/jpeg' }
            );
            
            resolve(croppedFile);
          }, 'image/jpeg', 0.9);
          
        } catch (error) {
          reject(error);
        }
      };
      
      img.onerror = () => {
        reject(new Error('Failed to load image'));
      };
      
      img.src = e.target.result;
    };
    
    reader.onerror = () => {
      reject(new Error('Failed to read image file'));
    };
    
    reader.readAsDataURL(imageFile);
  });
}

/**
 * Check if crop parameters are valid and non-empty
 * @param {Object} cropParams - Crop parameters object
 * @returns {boolean} True if valid
 */
export function isValidCropParameters(cropParams) {
  if (!cropParams || typeof cropParams !== 'object') {
    return false;
  }
  
  // Must have at least some crop information
  return cropParams.width !== undefined || 
         cropParams.height !== undefined || 
         cropParams.x !== undefined || 
         cropParams.y !== undefined;
}

/**
 * Parse crop parameters from JSON string
 * @param {string} cropParamsString - JSON string of crop parameters
 * @returns {Object|null} Parsed crop parameters or null if invalid
 */
export function parseCropParameters(cropParamsString) {
  if (!cropParamsString || typeof cropParamsString !== 'string') {
    return null;
  }
  
  try {
    const params = JSON.parse(cropParamsString);
    return isValidCropParameters(params) ? params : null;
  } catch (error) {
    console.error('Failed to parse crop parameters:', error);
    return null;
  }
}

