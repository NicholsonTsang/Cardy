<template>
  <div 
    class="upload-zone"
    :class="{ 
      'dragover': isDragover, 
      'has-file': selectedFile,
      'has-error': fileError 
    }"
    @dragover.prevent="isDragover = true"
    @dragleave.prevent="isDragover = false"
    @drop.prevent="handleFileDrop"
    @click="triggerFileInput"
  >
    <!-- Hidden File Input -->
    <input 
      ref="fileInputRef"
      type="file"
      :accept="accept"
      :multiple="multiple"
      @change="handleFileSelect"
      class="hidden"
    />

    <!-- Empty State -->
    <div v-if="!hasFiles" class="drop-content">
      <i :class="dropIcon" class="drop-icon"></i>
      <h4>{{ dropTitle || $t('common.drop_file_here') }}</h4>
      <p>{{ dropSubtitle || $t('common.or_click_to_browse') }}</p>
      <div v-if="requirements.length > 0" class="file-requirements">
        <span v-for="(req, index) in requirements" :key="index" class="requirement">
          • {{ req }}
        </span>
      </div>
    </div>
    
    <!-- Single File Selected -->
    <div v-else-if="selectedFile && !multiple" class="file-selected">
      <i :class="fileIcon" class="file-icon"></i>
      <div class="file-details">
        <span class="file-name">{{ selectedFile.name }}</span>
        <span class="file-size">{{ formatFileSize(selectedFile.size) }}</span>
        <span v-if="statusText" class="file-status">{{ statusText }}</span>
      </div>
      <Button 
        icon="pi pi-times"
        @click.stop="removeFile"
        text
        rounded
        severity="danger"
        v-tooltip="$t('common.delete')"
      />
    </div>
    
    <!-- Multiple Files Selected -->
    <div v-else-if="selectedFiles.length > 0" class="files-selected">
      <div class="files-header">
        <i :class="fileIcon" class="file-icon"></i>
        <div class="file-details">
          <span class="file-name">{{ selectedFiles.length }} files selected</span>
          <span class="file-size">{{ formatFileSize(totalSize) }}</span>
          <span v-if="statusText" class="file-status">{{ statusText }}</span>
        </div>
        <Button 
          icon="pi pi-times"
          @click.stop="removeFile"
          text
          rounded
          severity="danger"
          v-tooltip="$t('common.clear_all')"
        />
      </div>
      <div class="files-list">
        <div v-for="(file, index) in selectedFiles" :key="index" class="file-item">
          <i class="pi pi-file-excel text-emerald-600"></i>
          <span class="file-item-name">{{ file.name }}</span>
          <span class="file-item-size">{{ formatFileSize(file.size) }}</span>
        </div>
      </div>
    </div>

    <!-- Error Message -->
    <div v-if="fileError" class="file-error">
      <i class="pi pi-exclamation-triangle"></i>
      {{ fileError }}
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import Button from 'primevue/button'

const props = withDefaults(defineProps<{
  // File config
  accept?: string
  maxSizeMB?: number
  multiple?: boolean
  
  // Customization
  dropIcon?: string
  dropTitle?: string
  dropSubtitle?: string
  fileIcon?: string
  requirements?: string[]
  statusText?: string
}>(), {
  accept: '.xlsx,.xls',
  maxSizeMB: 25,
  multiple: false,
  dropIcon: 'pi pi-cloud-upload',
  fileIcon: 'pi pi-file-excel',
  requirements: () => []
})

const emit = defineEmits<{
  'file-selected': [file: File]
  'files-selected': [files: File[]]
  'file-removed': []
  'error': [message: string]
}>()

// State
const selectedFile = ref<File | null>(null)
const selectedFiles = ref<File[]>([])
const isDragover = ref(false)
const fileError = ref<string | null>(null)
const fileInputRef = ref<HTMLInputElement | null>(null)

// Computed
const hasFiles = computed(() => {
  return props.multiple ? selectedFiles.value.length > 0 : selectedFile.value !== null
})

const totalSize = computed(() => {
  return selectedFiles.value.reduce((sum, file) => sum + file.size, 0)
})

// Validate file
function validateFile(file: File): boolean {
  fileError.value = null
  
  // Check file type
  const acceptedTypes = props.accept.split(',').map(t => t.trim().toLowerCase())
  const extension = '.' + file.name.split('.').pop()?.toLowerCase()
  
  if (!acceptedTypes.some(type => extension === type || type === '*')) {
    fileError.value = `Invalid file type. Accepted: ${props.accept}`
    emit('error', fileError.value)
    return false
  }
  
  // Check file size
  const maxBytes = props.maxSizeMB * 1024 * 1024
  if (file.size > maxBytes) {
    fileError.value = `File too large. Maximum: ${props.maxSizeMB}MB`
    emit('error', fileError.value)
    return false
  }
  
  return true
}

// Process file(s)
function processFile(file: File) {
  if (!validateFile(file)) return
  
  selectedFile.value = file
  emit('file-selected', file)
}

function processFiles(files: FileList) {
  fileError.value = null
  const validFiles: File[] = []
  
  for (let i = 0; i < files.length; i++) {
    const file = files[i]
    if (validateFile(file)) {
      validFiles.push(file)
    }
  }
  
  if (validFiles.length > 0) {
    selectedFiles.value = validFiles
    emit('files-selected', validFiles)
  }
}

// Methods
function triggerFileInput() {
  fileInputRef.value?.click()
}

function handleFileSelect(event: Event) {
  const target = event.target as HTMLInputElement
  const files = target.files
  
  if (!files || files.length === 0) return
  
  if (props.multiple) {
    processFiles(files)
  } else {
    processFile(files[0])
  }
}

function handleFileDrop(event: DragEvent) {
  isDragover.value = false
  const files = event.dataTransfer?.files
  
  if (!files || files.length === 0) return
  
  if (props.multiple) {
    processFiles(files)
  } else {
    processFile(files[0])
  }
}

function removeFile() {
  selectedFile.value = null
  selectedFiles.value = []
  fileError.value = null
  if (fileInputRef.value) fileInputRef.value.value = ''
  emit('file-removed')
}

function formatFileSize(bytes: number): string {
  if (bytes === 0) return '0 Bytes'
  const k = 1024
  const sizes = ['Bytes', 'KB', 'MB', 'GB']
  const i = Math.floor(Math.log(bytes) / Math.log(k))
  return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i]
}

// Expose methods for parent components
defineExpose({
  removeFile,
  triggerFileInput
})
</script>

<style scoped>
.upload-zone {
  @apply border-2 border-dashed border-slate-300 rounded-xl p-8 text-center cursor-pointer transition-all;
}

.upload-zone:hover {
  @apply border-blue-400 bg-blue-50;
}

.upload-zone.dragover {
  @apply border-blue-500 bg-blue-50;
}

.upload-zone.has-file {
  @apply border-emerald-400 bg-emerald-50;
}

.upload-zone.has-error {
  @apply border-red-300 bg-red-50;
}

.hidden {
  @apply sr-only;
}

.drop-content {
  @apply space-y-2;
}

.drop-icon {
  @apply text-4xl text-slate-400;
}

.dragover .drop-icon {
  @apply text-blue-500;
}

.drop-content h4 {
  @apply font-medium text-slate-700;
}

.drop-content p {
  @apply text-sm text-slate-500;
}

.file-requirements {
  @apply flex flex-col gap-1 text-xs text-slate-500 mt-3;
}

.file-selected {
  @apply flex items-center gap-4 text-left;
}

.file-icon {
  @apply text-3xl text-emerald-600;
}

.file-details {
  @apply flex-1 min-w-0;
}

.file-name {
  @apply block font-medium text-slate-900 truncate;
}

.file-size {
  @apply block text-sm text-slate-500;
}

.file-status {
  @apply block text-xs text-emerald-600 mt-1;
}

.file-error {
  @apply flex items-center gap-2 mt-3 text-sm text-red-600 justify-center;
}

/* Multiple files */
.files-selected {
  @apply text-left;
}

.files-header {
  @apply flex items-center gap-4;
}

.files-list {
  @apply mt-3 space-y-1 max-h-32 overflow-y-auto;
}

.file-item {
  @apply flex items-center gap-2 text-sm py-1 px-2 bg-white rounded;
}

.file-item-name {
  @apply flex-1 truncate text-slate-700;
}

.file-item-size {
  @apply text-xs text-slate-500;
}

/* Mobile responsive */
@media (max-width: 640px) {
  .upload-zone {
    @apply p-4;
  }
  
  .drop-icon {
    @apply text-3xl;
  }
}
</style>

