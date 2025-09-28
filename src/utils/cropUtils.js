/**
 * Crop utilities for handling dynamic image cropping
 */

/**
 * Generate a cropped image from stored crop parameters
 * @param {HTMLImageElement} imageElement - The original image element
 * @param {Object} cropParams - The stored crop parameters
 * @param {number} outputSize - The desired output size (default: 800)
 * @returns {string} Data URL of the cropped image
 */
export const generateCroppedImage = (imageElement, cropParams, outputSize = 800) => {
    if (!imageElement || !cropParams) {
        console.error('Missing image element or crop parameters');
        return null;
    }

    const canvas = document.createElement('canvas');
    const ctx = canvas.getContext('2d');
    
    // Set canvas size to target aspect ratio
    let canvasWidth, canvasHeight;
    if (cropParams.targetAspectRatio >= 1) {
        canvasWidth = outputSize;
        canvasHeight = outputSize / cropParams.targetAspectRatio;
    } else {
        canvasHeight = outputSize;
        canvasWidth = outputSize * cropParams.targetAspectRatio;
    }
    
    canvas.width = canvasWidth;
    canvas.height = canvasHeight;
    
    // Validate crop parameters
    if (!cropParams.naturalWidth || !cropParams.naturalHeight || 
        cropParams.naturalWidth <= 0 || cropParams.naturalHeight <= 0) {
        console.error('Invalid natural image dimensions:', cropParams.naturalWidth, cropParams.naturalHeight);
        return null;
    }
    
    try {
        // First, draw white background for final rendering
        ctx.fillStyle = '#ffffff';
        ctx.fillRect(0, 0, canvasWidth, canvasHeight);
        
        
        // Use the exact positioning data from the cropper
        const containerSize = cropParams.containerSize || 400;
        const zoom = cropParams.zoom || 1;
        
        // Get the already calculated positioning from crop parameters
        const displayedImageWidth = cropParams.displayedImageWidth;
        const displayedImageHeight = cropParams.displayedImageHeight;
        const scaledDisplayWidth = displayedImageWidth * zoom;
        const scaledDisplayHeight = displayedImageHeight * zoom;
        
        // Use the final image position calculated by the cropper
        const finalImageLeft = cropParams.finalImageLeft;
        const finalImageTop = cropParams.finalImageTop;
        
        // Validate that we have the required positioning data
        if (finalImageLeft === undefined || finalImageTop === undefined) {
            console.error('Missing finalImageLeft or finalImageTop in crop parameters:', cropParams);
            // Fallback to recalculating if missing
            const imageAspectRatio = cropParams.naturalWidth / cropParams.naturalHeight;
            let displayedImageWidth, displayedImageHeight;
            let imageDisplayLeft, imageDisplayTop;
            
            if (imageAspectRatio > 1) {
                displayedImageWidth = containerSize;
                displayedImageHeight = containerSize / imageAspectRatio;
                imageDisplayLeft = 0;
                imageDisplayTop = (containerSize - displayedImageHeight) / 2;
            } else {
                displayedImageHeight = containerSize;
                displayedImageWidth = containerSize * imageAspectRatio;
                imageDisplayLeft = (containerSize - displayedImageWidth) / 2;
                imageDisplayTop = 0;
            }
            
            const position = cropParams.position || { x: 0, y: 0 };
            const scaledDisplayWidth = displayedImageWidth * zoom;
            const scaledDisplayHeight = displayedImageHeight * zoom;
            
            const calculatedFinalImageLeft = imageDisplayLeft + (displayedImageWidth - scaledDisplayWidth) / 2 + position.x;
            const calculatedFinalImageTop = imageDisplayTop + (displayedImageHeight - scaledDisplayHeight) / 2 + position.y;
            
            console.log('Using calculated positions:', { calculatedFinalImageLeft, calculatedFinalImageTop });
            
            return generateCroppedImageWithPositions(
                imageElement, cropParams, canvasWidth, canvasHeight, 
                calculatedFinalImageLeft, calculatedFinalImageTop, 
                displayedImageWidth, displayedImageHeight, zoom, ctx
            );
        }
        
        return generateCroppedImageWithPositions(
            imageElement, cropParams, canvasWidth, canvasHeight, 
            finalImageLeft, finalImageTop, 
            displayedImageWidth, displayedImageHeight, zoom, ctx
        );
    } catch (error) {
        console.error('Error creating cropped image:', error);
        return null;
    }
};

// Helper function to render the cropped image with given positions
const generateCroppedImageWithPositions = (
    imageElement, cropParams, canvasWidth, canvasHeight, 
    finalImageLeft, finalImageTop, displayedImageWidth, displayedImageHeight, zoom, ctx
) => {
    const containerSize = cropParams.containerSize || 400;
    const scaledDisplayWidth = displayedImageWidth * zoom;
    const scaledDisplayHeight = displayedImageHeight * zoom;
    
    // Calculate crop frame position
    const frameWidth = cropParams.frameWidth;
    const frameHeight = cropParams.frameHeight;
    const frameLeft = (containerSize - frameWidth) / 2;
    const frameTop = (containerSize - frameHeight) / 2;
    
    // Calculate what part of the image is visible in the crop frame
    const cropLeft = frameLeft - finalImageLeft;
    const cropTop = frameTop - finalImageTop;
    
    // Scale factors for drawing
    const scaleX = canvasWidth / frameWidth;
    const scaleY = canvasHeight / frameHeight;
    
    // Calculate source coordinates in natural image space
    const scaleToNatural = cropParams.naturalWidth / scaledDisplayWidth;
    const sourceX = cropLeft * scaleToNatural;
    const sourceY = cropTop * scaleToNatural;
    const sourceWidth = frameWidth * scaleToNatural;
    const sourceHeight = frameHeight * scaleToNatural;
    
    
    // Calculate what part of the crop area intersects with the actual image
    // Handle negative source coordinates (crop extends beyond image)
    
    // Calculate the actual source rectangle (clamped to image bounds)
    const actualSourceX = Math.max(0, sourceX);
    const actualSourceY = Math.max(0, sourceY);
    const actualSourceRight = Math.min(sourceX + sourceWidth, cropParams.naturalWidth);
    const actualSourceBottom = Math.min(sourceY + sourceHeight, cropParams.naturalHeight);
    const actualSourceWidth = Math.max(0, actualSourceRight - actualSourceX);
    const actualSourceHeight = Math.max(0, actualSourceBottom - actualSourceY);
    
    // Calculate where this maps to in the destination canvas
    // If sourceX is negative, the image starts partway into the crop frame
    const destOffsetX = Math.max(0, -sourceX) / sourceWidth;
    const destOffsetY = Math.max(0, -sourceY) / sourceHeight;
    const destScaleX = actualSourceWidth / sourceWidth;
    const destScaleY = actualSourceHeight / sourceHeight;
    
    const destX = destOffsetX * canvasWidth;
    const destY = destOffsetY * canvasHeight;
    const destWidth = destScaleX * canvasWidth;
    const destHeight = destScaleY * canvasHeight;
    
    // Only draw the image if there's an intersection
    if (actualSourceWidth > 0 && actualSourceHeight > 0) {
        ctx.drawImage(
            imageElement,
            actualSourceX,
            actualSourceY,
            actualSourceWidth,
            actualSourceHeight,
            destX, destY, destWidth, destHeight
        );
    }
    
    return ctx.canvas.toDataURL('image/jpeg', 0.9);
};


/**
 * Generate a preview image from crop parameters
 * @param {string} imageSrc - The source image URL
 * @param {Object} cropParams - The stored crop parameters
 * @param {number} previewSize - The desired preview size (default: 300)
 * @returns {Promise<string>} Promise resolving to preview data URL
 */
export const generateCropPreview = (imageSrc, cropParams, previewSize = 300) => {
    return new Promise((resolve, reject) => {
        const img = new Image();
        img.crossOrigin = 'anonymous';
        
        img.onload = () => {
            const preview = generateCroppedImage(img, cropParams, previewSize);
            resolve(preview);
        };
        
        img.onerror = (error) => {
            console.error('Error loading image for preview:', error);
            reject(error);
        };
        
        img.src = imageSrc;
    });
};

/**
 * Validate crop parameters
 * @param {Object} cropParams - The crop parameters to validate
 * @returns {boolean} True if valid, false otherwise
 */
export const validateCropParameters = (cropParams) => {
    if (!cropParams || typeof cropParams !== 'object') {
        return false;
    }
    
    const requiredFields = [
        'naturalWidth', 'naturalHeight', 'sourceX', 'sourceY', 
        'sourceWidth', 'sourceHeight', 'targetAspectRatio'
    ];
    
    return requiredFields.every(field => 
        typeof cropParams[field] === 'number' && cropParams[field] >= 0
    );
};

/**
 * Get crop parameters for a specific aspect ratio
 * @param {Object} cropParams - The original crop parameters
 * @param {number} newAspectRatio - The new target aspect ratio
 * @returns {Object} Adjusted crop parameters
 */
export const adjustCropForAspectRatio = (cropParams, newAspectRatio) => {
    if (!cropParams || !newAspectRatio) {
        return cropParams;
    }
    
    // Calculate the center of the current crop
    const centerX = cropParams.sourceX + cropParams.sourceWidth / 2;
    const centerY = cropParams.sourceY + cropParams.sourceHeight / 2;
    
    // Calculate new dimensions maintaining the same area
    const currentArea = cropParams.sourceWidth * cropParams.sourceHeight;
    let newWidth, newHeight;
    
    if (newAspectRatio >= 1) {
        // Landscape or square
        newWidth = Math.sqrt(currentArea * newAspectRatio);
        newHeight = newWidth / newAspectRatio;
    } else {
        // Portrait
        newHeight = Math.sqrt(currentArea / newAspectRatio);
        newWidth = newHeight * newAspectRatio;
    }
    
    // Ensure the new crop fits within the image bounds
    const maxWidth = cropParams.naturalWidth;
    const maxHeight = cropParams.naturalHeight;
    
    if (newWidth > maxWidth) {
        newWidth = maxWidth;
        newHeight = newWidth / newAspectRatio;
    }
    
    if (newHeight > maxHeight) {
        newHeight = maxHeight;
        newWidth = newHeight * newAspectRatio;
    }
    
    // Calculate new position centered on the original crop center
    const newSourceX = Math.max(0, Math.min(centerX - newWidth / 2, maxWidth - newWidth));
    const newSourceY = Math.max(0, Math.min(centerY - newHeight / 2, maxHeight - newHeight));
    
    return {
        ...cropParams,
        sourceX: newSourceX,
        sourceY: newSourceY,
        sourceWidth: newWidth,
        sourceHeight: newHeight,
        targetAspectRatio: newAspectRatio
    };
};
