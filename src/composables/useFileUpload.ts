/**
 * Shared composable for file upload functionality
 * Used by CardBulkImport and other file upload components
 */
import { ref, type Ref } from 'vue'

export interface FileUploadOptions {
  acceptedTypes?: string[] // e.g., ['.xlsx', '.xls']
  maxSizeMB?: number
  onFileSelected?: (file: File) => Promise<void>
}

export interface FileUploadReturn {
  // State
  selectedFile: Ref<File | null>
  isDragover: Ref<boolean>
  isProcessing: Ref<boolean>
  fileError: Ref<string | null>
  
  // Methods
  triggerFileInput: () => void
  handleFileSelect: (event: Event) => void
  handleFileDrop: (event: DragEvent) => void
  removeFile: () => void
  validateFile: (file: File) => boolean
  
  // Utilities
  formatFileSize: (bytes: number) => string
  
  // Refs
  fileInputRef: Ref<HTMLInputElement | null>
}

export function useFileUpload(options: FileUploadOptions = {}): FileUploadReturn {
  const {
    acceptedTypes = ['.xlsx', '.xls'],
    maxSizeMB = 25,
    onFileSelected
  } = options

  // State
  const selectedFile = ref<File | null>(null)
  const isDragover = ref(false)
  const isProcessing = ref(false)
  const fileError = ref<string | null>(null)
  const fileInputRef = ref<HTMLInputElement | null>(null)

  // Validate file type and size
  function validateFile(file: File): boolean {
    fileError.value = null

    // Check file type
    const extension = '.' + file.name.split('.').pop()?.toLowerCase()
    if (!acceptedTypes.some(type => extension === type.toLowerCase())) {
      fileError.value = `Invalid file type. Accepted: ${acceptedTypes.join(', ')}`
      return false
    }

    // Check file size
    const maxBytes = maxSizeMB * 1024 * 1024
    if (file.size > maxBytes) {
      fileError.value = `File too large. Maximum size: ${maxSizeMB}MB`
      return false
    }

    return true
  }

  // Process file after validation
  async function processFile(file: File) {
    if (!validateFile(file)) {
      return
    }

    selectedFile.value = file
    
    if (onFileSelected) {
      isProcessing.value = true
      try {
        await onFileSelected(file)
      } finally {
        isProcessing.value = false
      }
    }
  }

  // Trigger hidden file input
  function triggerFileInput() {
    fileInputRef.value?.click()
  }

  // Handle file selection from input
  function handleFileSelect(event: Event) {
    const target = event.target as HTMLInputElement
    const file = target.files?.[0]
    if (file) {
      processFile(file)
    }
  }

  // Handle file drop
  function handleFileDrop(event: DragEvent) {
    isDragover.value = false
    const file = event.dataTransfer?.files[0]
    if (file) {
      processFile(file)
    }
  }

  // Remove selected file
  function removeFile() {
    selectedFile.value = null
    fileError.value = null
    if (fileInputRef.value) {
      fileInputRef.value.value = ''
    }
  }

  // Format file size for display
  function formatFileSize(bytes: number): string {
    if (bytes === 0) return '0 Bytes'
    const k = 1024
    const sizes = ['Bytes', 'KB', 'MB', 'GB']
    const i = Math.floor(Math.log(bytes) / Math.log(k))
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i]
  }

  return {
    // State
    selectedFile,
    isDragover,
    isProcessing,
    fileError,
    
    // Methods
    triggerFileInput,
    handleFileSelect,
    handleFileDrop,
    removeFile,
    validateFile,
    
    // Utilities
    formatFileSize,
    
    // Refs
    fileInputRef
  }
}

