/**
 * Utility functions for file type detection and handling
 */

/**
 * Extract file extension from a file path or File object
 */
export function getFileExtension(fileOrPath: string | File): string {
    let fileName: string;
    if (typeof fileOrPath === 'string') {
        fileName = fileOrPath.split('/').pop() || '';
    } else {
        fileName = fileOrPath.name;
    }
    return fileName.split('.').pop()?.toLowerCase() || '';
}

/**
 * Check if a file is an image
 */
export function isImage(fileOrPath: string | File): boolean {
    const imageTypes = ['jpg', 'jpeg', 'png', 'gif', 'webp', 'svg', 'bmp', 'tiff', 'ico'];
    const ext = getFileExtension(fileOrPath);
    
    if (typeof fileOrPath === 'string') {
        return imageTypes.includes(ext);
    }
    return fileOrPath.type.startsWith('image/') || imageTypes.includes(ext);
}

/**
 * Format file size for display
 */
export function getFileSize(fileOrPath: string | File): string {
    if (typeof fileOrPath === 'string') {
        return 'Uploaded';
    }
    
    const size = fileOrPath.size;
    if (size < 1024) return size + ' B';
    if (size < 1024 * 1024) return (size / 1024).toFixed(1) + ' KB';
    return (size / (1024 * 1024)).toFixed(1) + ' MB';
}

/**
 * Get file name from file path or File object
 */
export function getFileName(fileOrPath: string | File): string {
    if (typeof fileOrPath === 'string') {
        return fileOrPath.split('/').pop() || 'file';
    }
    return fileOrPath.name;
} 