import imageCompression from 'browser-image-compression';

/**
 * Checks if an image file exceeds a specified size and compresses it if necessary.
 *
 * @param {File} file The image file to process.
 * @param {number} maxSizeKB The maximum desired file size in kilobytes. Defaults to 500 KB.
 * @param {object} options Optional compression options for browser-image-compression.
 * @returns {Promise<File>} A promise that resolves with the original file or a new compressed file.
 */
export async function processImage(file, maxSizeKB = 500, options = {}) {
    if (!file || !file.type.startsWith('image/')) {
        console.error('Invalid file type. Only images are supported.');
        return Promise.reject(new Error('Invalid file type. Only images are supported.'));
    }

    const currentSizeKB = file.size / 1024;

    if (currentSizeKB <= maxSizeKB) {
        console.log(`Image size (${currentSizeKB.toFixed(2)} KB) is within the limit of ${maxSizeKB} KB. No compression needed.`);
        return Promise.resolve(file);
    }

    console.log(`Image size (${currentSizeKB.toFixed(2)} KB) exceeds ${maxSizeKB} KB. Attempting compression...`);

    const defaultCompressionOptions = {
        maxSizeMB: maxSizeKB / 1024, // Convert KB to MB for the library
        maxWidthOrHeight: 1920,      // Optional: resize to a max dimension
        useWebWorker: true,          // Optional: for better performance
        initialQuality: 0.8,         // Start with a decent quality
        // alwaysKeepResolution: false, // Allow resolution changes if needed to meet size
        ...options,                  // Allow overriding defaults with user-provided options
    };

    try {
        const compressedFile = await imageCompression(file, defaultCompressionOptions);
        console.log(`Image compressed successfully. New size: ${(compressedFile.size / 1024).toFixed(2)} KB`);
        // The library returns a File object, so we can directly return it.
        // If the compressed file is somehow larger (highly unlikely with good settings),
        // you might want to return the original, but the library aims to reduce size.
        return compressedFile;
    } catch (error) {
        console.error('Error during image compression:', error);
        // Fallback to original file if compression fails, or handle error as needed
        return Promise.reject(error);
    }
}

/**
 * Example of more specific compression options you might want to expose or use internally.
 */
export const commonCompressionOptions = {
    profilePictures: {
        maxSizeMB: 0.2, // 200KB
        maxWidthOrHeight: 800,
    },
    cardArtwork: {
        maxSizeMB: 0.5, // 500KB (default)
        maxWidthOrHeight: 1280,
    }
}; 