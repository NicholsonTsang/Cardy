<template>
  <div class="card-bulk-import">
    <!-- Header Section -->
    <div class="import-header">
      <div class="header-content">
        <div class="icon-section">
          <div class="import-icon">
            <i class="pi pi-upload"></i>
          </div>
        </div>
        <div class="text-section">
          <h3 class="import-title">Bulk Import Cards</h3>
          <p class="import-description">
            Import cards with embedded images from Excel files. Images are automatically extracted and processed.
          </p>
        </div>
      </div>
    </div>

    <!-- Quick Actions -->
    <div class="quick-actions">
      <div class="action-grid">
        <div class="action-item template-action">
          <Button 
            label="Download Template"
            icon="pi pi-download"
            @click="downloadTemplate"
            class="template-button bg-blue-600 hover:bg-blue-700 text-white border-0"
          />
          <span class="action-desc">Excel template with formulas and examples</span>
        </div>
        
        <div class="action-item import-action">
          <Button 
            label="Choose Excel File"
            icon="pi pi-file-excel"
            @click="triggerFileInput"
            :disabled="importing"
            class="import-button bg-blue-600 hover:bg-blue-700 text-white border-0"
          />
          <span class="action-desc">Upload .xlsx file with embedded images</span>
        </div>
      </div>
    </div>

    <!-- File Upload Area -->
    <div class="upload-zone" :class="{ 'dragover': isDragover, 'has-file': selectedFile }">
      <input 
        ref="fileInput"
        type="file"
        accept=".xlsx,.xls"
        @change="handleFileSelect"
        class="hidden"
      />
      
      <div 
        class="drop-area"
        @dragover.prevent="isDragover = true"
        @dragleave.prevent="isDragover = false"
        @drop.prevent="handleFileDrop"
        @click="triggerFileInput"
      >
        <div v-if="!selectedFile" class="drop-content">
          <i class="pi pi-cloud-upload drop-icon"></i>
          <div class="drop-text">
            <h4>Drop your Excel file here</h4>
            <p>or click to browse files</p>
          </div>
          <div class="file-requirements">
            <span class="requirement">• Excel files (.xlsx) with embedded images</span>
            <span class="requirement">• Maximum 25MB file size</span>
            <span class="requirement">• Images are automatically extracted</span>
          </div>
        </div>
        
        <div v-else class="file-selected">
          <i class="pi pi-file-excel file-icon"></i>
          <div class="file-details">
            <span class="file-name">{{ selectedFile.name }}</span>
            <span class="file-size">{{ formatFileSize(selectedFile.size) }}</span>
            <div class="file-meta">
              <span v-if="importPreview" class="meta-item">
                <i class="pi pi-check-circle text-blue-600"></i>
                Analysis complete
              </span>
            </div>
          </div>
          <Button 
            icon="pi pi-times"
            @click.stop="removeFile"
            class="p-button-text p-button-sm remove-button"
            v-tooltip="'Remove file'"
          />
        </div>
      </div>
    </div>

    <!-- Import Preview -->
    <div v-if="importPreview" class="import-preview">
      <div class="preview-header">
        <h4 class="preview-title">
          <i class="pi pi-eye preview-icon"></i>
          Import Preview
        </h4>
        <div class="preview-stats">
          <span class="stat-item">
            <i class="pi pi-id-card text-blue-600"></i>
            {{ importPreview.cardData ? 1 : 0 }} card
          </span>
          <span class="stat-item">
            <i class="pi pi-list text-blue-600"></i>
            {{ importPreview.contentItems.length }} content items
          </span>
          <span class="stat-item">
            <i class="pi pi-image text-purple-600"></i>
            {{ extractedImageCount }} embedded images
          </span>
        </div>
      </div>
      
      <!-- Validation Issues -->
      <div v-if="importPreview.errors.length > 0" class="validation-errors">
        <h5 class="errors-title">
          <i class="pi pi-times-circle"></i>
          Validation Errors
        </h5>
        <div class="errors-list">
          <div 
            v-for="(error, index) in importPreview.errors.slice(0, 5)" 
            :key="index"
            class="error-item"
          >
            <i class="pi pi-times-circle error-icon"></i>
            <span class="error-text">{{ error }}</span>
          </div>
          <div v-if="importPreview.errors.length > 5" class="more-errors">
            +{{ importPreview.errors.length - 5 }} more errors
          </div>
        </div>
      </div>
      
      <div v-if="importPreview.warnings.length > 0" class="validation-warnings">
        <h5 class="warnings-title">
          <i class="pi pi-exclamation-triangle"></i>
          Validation Warnings
        </h5>
        <div class="warnings-list">
          <div 
            v-for="(warning, index) in importPreview.warnings.slice(0, 3)" 
            :key="index"
            class="warning-item"
          >
            <i class="pi pi-exclamation-circle warning-icon"></i>
            <span class="warning-text">{{ warning }}</span>
          </div>
          <div v-if="importPreview.warnings.length > 3" class="more-warnings">
            +{{ importPreview.warnings.length - 3 }} more warnings
          </div>
        </div>
      </div>
      
      <!-- Card Preview -->
      <div v-if="importPreview.cardData" class="card-preview">
        <h5 class="preview-section-title">
          <i class="pi pi-id-card"></i>
          Import Preview - Card Information
        </h5>
        <div class="card-preview-content">
          <div class="card-preview-header">
            <!-- Card Image -->
            <div class="card-image-preview">
              <img 
                v-if="getCardImageUrl()"
                :src="getCardImageUrl()"
                :alt="importPreview.cardData.name || 'Card Image'"
                class="card-preview-image"
              />
              <div v-else class="card-image-placeholder">
                <i class="pi pi-id-card text-2xl text-slate-400"></i>
              </div>
            </div>
            
            <!-- Card Details -->
            <div class="card-details">
              <div class="preview-field">
                <span class="field-label">Name:</span>
                <span class="field-value">{{ importPreview.cardData.name || 'Unnamed Card' }}</span>
              </div>
              <div class="preview-field">
                <span class="field-label">Description:</span>
                <span class="field-value">{{ truncateText(importPreview.cardData.description, 100) }}</span>
              </div>
              <div class="preview-field">
                <span class="field-label">AI Enabled:</span>
                <span class="field-value">{{ importPreview.cardData.conversation_ai_enabled ? 'Yes' : 'No' }}</span>
              </div>
            </div>
          </div>
        </div>
      </div>
      
      <!-- Content Preview -->
      <div v-if="importPreview.contentItems.length > 0" class="content-preview">
        <h5 class="preview-section-title">
          <i class="pi pi-list"></i>
          Import Preview - Content Structure ({{ importPreview.contentItems.length }} items)
        </h5>
        
        <!-- Hierarchical Content Preview -->
        <div class="hierarchical-content-preview">
          <div 
            v-for="(item, index) in organizedContentItems" 
            :key="item.name"
            class="preview-content-group"
          >
            <!-- Layer 1 Item -->
            <div class="preview-parent-item">
              <div class="preview-item-header">
                <!-- Expand/Collapse Icon -->
                <i 
                  :class="expandedItems[index] ? 'pi pi-angle-down' : 'pi pi-angle-right'"
                  class="expand-icon"
                  @click="expandedItems[index] = !expandedItems[index]"
                  v-if="item.children && item.children.length > 0"
                ></i>
                <div v-else class="expand-icon-placeholder"></div>
                
                <!-- Thumbnail -->
                <div class="preview-thumbnail">
                  <img 
                    v-if="getItemImageUrl(item, index)"
                    :src="getItemImageUrl(item, index)"
                    :alt="item.name"
                    class="preview-image"
                  />
                  <i class="pi pi-image text-slate-400" v-else-if="item.has_images"></i>
                  <i class="pi pi-file text-slate-400" v-else></i>
                </div>
                
                <!-- Item Info -->
                <div class="preview-item-info">
                  <div class="preview-item-name">{{ item.name }}</div>
                  <div class="preview-item-meta">
                    <span class="layer-badge layer-1">Layer 1</span>
                    <span v-if="item.children && item.children.length > 0" class="children-count">
                      {{ item.children.length }} sub-item{{ item.children.length !== 1 ? 's' : '' }}
                    </span>
                    <span v-if="item.has_images" class="image-badge">
                      <i class="pi pi-image"></i>
                      {{ item.image_count }}
                    </span>
                  </div>
                </div>
              </div>
              
              <!-- Content preview -->
              <div class="preview-item-content">{{ truncateText(item.content, 100) }}</div>
            </div>
            
            <!-- Layer 2 Items (Sub-items) -->
            <Transition name="expand">
              <div v-if="expandedItems[index] && item.children && item.children.length > 0" class="preview-children">
                <div 
                  v-for="(child, childIndex) in item.children.slice(0, 5)" 
                  :key="child.name"
                  class="preview-child-item"
                >
                  <div class="preview-item-header">
                    <!-- Indent indicator -->
                    <div class="child-indent"></div>
                    
                    <!-- Thumbnail -->
                    <div class="preview-thumbnail preview-thumbnail-small">
                      <img 
                        v-if="getChildImageUrl(child, index, childIndex)"
                        :src="getChildImageUrl(child, index, childIndex)"
                        :alt="child.name"
                        class="preview-image"
                      />
                      <i class="pi pi-image text-slate-400" v-else-if="child.has_images"></i>
                      <i class="pi pi-file text-slate-400" v-else></i>
                    </div>
                    
                    <!-- Item Info -->
                    <div class="preview-item-info">
                      <div class="preview-item-name">{{ child.name }}</div>
                      <div class="preview-item-meta">
                        <span class="layer-badge layer-2">Layer 2</span>
                        <span class="sub-item-index">Sub-item {{ childIndex + 1 }}</span>
                        <span v-if="child.has_images" class="image-badge">
                          <i class="pi pi-image"></i>
                          {{ child.image_count }}
                        </span>
                      </div>
                    </div>
                  </div>
                  
                  <!-- Content preview -->
                  <div class="preview-item-content preview-child-content">{{ truncateText(child.content, 80) }}</div>
                </div>
                
                <!-- Show more indicator if there are more children -->
                <div v-if="item.children.length > 5" class="more-children">
                  <i class="pi pi-ellipsis-h"></i>
                  +{{ item.children.length - 5 }} more sub-items
                </div>
              </div>
            </Transition>
          </div>
        </div>
      </div>
      
      <!-- Preview Actions -->
      <div class="preview-actions">
        <Button 
          label="Cancel"
          icon="pi pi-times"
          @click="cancelImport"
          class="cancel-button text-blue-600 hover:text-blue-800 border-0 bg-transparent"
        />
        <Button 
          :label="confirmButtonLabel"
          icon="pi pi-check"
          @click="executeImport"
          :disabled="!canExecuteImport"
          :loading="importing"
          class="confirm-button bg-blue-600 hover:bg-blue-700 text-white border-0 disabled:bg-slate-400"
        />
      </div>
    </div>

    <!-- Import Progress -->
    <div v-if="importing" class="import-progress">
      <div class="progress-header">
        <h4 class="progress-title">Importing Data...</h4>
        <span class="progress-percent">{{ importProgressPercent }}%</span>
      </div>
      <ProgressBar :value="importProgressPercent" class="progress-bar" />
      <div class="progress-status">
        <span class="status-text">{{ importStatus }}</span>
      </div>
    </div>

    <!-- Import Results -->
    <div v-if="importResults" class="import-results">
      <div class="results-header">
        <div class="results-icon" :class="{ 
          'success': importResults.success, 
          'error': !importResults.success 
        }">
          <i :class="importResults.success ? 'pi pi-check-circle' : 'pi pi-times-circle'"></i>
        </div>
        <div class="results-content">
          <h4 class="results-title">
            {{ importResults.success ? 'Import Completed' : 'Import Failed' }}
          </h4>
          <p class="results-summary">{{ importResults.message }}</p>
        </div>
      </div>
      
      <div v-if="importResults.success && importResults.details" class="results-details">
        <div class="detail-grid">
          <div class="detail-item">
            <span class="detail-label">Cards Created</span>
            <span class="detail-value success">{{ importResults.details.cardsCreated || 0 }}</span>
          </div>
          <div class="detail-item">
            <span class="detail-label">Content Items</span>
            <span class="detail-value success">{{ importResults.details.contentCreated || 0 }}</span>
          </div>
          <div class="detail-item">
            <span class="detail-label">Images Processed</span>
            <span class="detail-value info">{{ importResults.details.imagesProcessed || 0 }}</span>
          </div>
          <div class="detail-item" v-if="importResults.details.warnings">
            <span class="detail-label">Warnings</span>
            <span class="detail-value warning">{{ importResults.details.warnings }}</span>
          </div>
        </div>
      </div>
      
      <div class="results-actions">
        <Button 
          label="Import Another File"
          icon="pi pi-plus"
          @click="resetImport"
          class="reset-button text-blue-600 hover:text-blue-800 border-0 bg-transparent"
        />
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onUnmounted } from 'vue'
import { useToast } from 'primevue/usetoast'
import { generateImportTemplate, importExcelToCardData } from '@/utils/excelHandler'
import { supabase } from '@/lib/supabase'
import Button from 'primevue/button'
import ProgressBar from 'primevue/progressbar'
import { Transition } from 'vue'

const emit = defineEmits(['imported'])
const toast = useToast()

// State
const fileInput = ref()
const selectedFile = ref(null)
const isDragover = ref(false)
const importing = ref(false)
const importPreview = ref(null)
const importResults = ref(null)
const importStatus = ref('')
const importProgress = ref(0)
const expandedItems = ref([])
const createdImageUrls = ref(new Set())

// Computed
const importProgressPercent = computed(() => Math.round(importProgress.value))

const confirmButtonLabel = computed(() => {
  if (importing.value) return 'Importing...'
  if (!importPreview.value) return 'Confirm Import'
  const errors = importPreview.value.errors.length
  const warnings = importPreview.value.warnings.length
  
  if (errors > 0) return `Cannot Import (${errors} errors)`
  if (warnings > 0) return `Import with ${warnings} warnings`
  return 'Confirm Import'
})

const canExecuteImport = computed(() => {
  return importPreview.value && 
    importPreview.value.isValid &&
    (importPreview.value.cardData || importPreview.value.contentItems.length > 0) &&
    !importing.value
})

const extractedImageCount = computed(() => {
  if (!importPreview.value || !importPreview.value.images) return 0
  let count = 0
  importPreview.value.images.forEach(images => {
    count += images.length
  })
  return count
})

const organizedContentItems = computed(() => {
  if (!importPreview.value || !importPreview.value.contentItems) return []
  
  // Group items by layer
  const layer1Items = importPreview.value.contentItems.filter(item => item.layer === 'Layer 1')
  const layer2Items = importPreview.value.contentItems.filter(item => item.layer === 'Layer 2')
  
  // Create hierarchical structure
  const organized = layer1Items.map(parent => {
    const children = layer2Items.filter(child => {
      // Match by parent_item name or parent_reference
      return child.parent_item === parent.name || 
             child.parent_reference === parent.name
    })
    
    return {
      ...parent,
      children: children
    }
  })
  
  // Initialize expanded state
  if (expandedItems.value.length !== organized.length) {
    expandedItems.value = new Array(organized.length).fill(true) // Expand all by default
  }
  
  return organized
})

// Methods
async function downloadTemplate() {
  try {
    const buffer = await generateImportTemplate()
    
    const filename = `CardStudio_Import_Template_${new Date().toISOString().split('T')[0]}.xlsx`
    const blob = new Blob([buffer], { 
      type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' 
    })
    const url = window.URL.createObjectURL(blob)
    const link = document.createElement('a')
    link.href = url
    link.download = filename
    link.click()
    window.URL.revokeObjectURL(url)
    
    toast.add({
      severity: 'success',
      summary: 'Template Downloaded',
      detail: 'Excel template with examples and formulas downloaded successfully',
      life: 3000
    })
  } catch (error) {
    console.error('Template download error:', error)
    toast.add({
      severity: 'error',
      summary: 'Download Failed',
      detail: 'Failed to generate import template',
      life: 5000
    })
  }
}

function triggerFileInput() {
  fileInput.value?.click()
}

function handleFileSelect(event) {
  const file = event.target.files[0]
  if (file) {
    processFile(file)
  }
}

function handleFileDrop(event) {
  isDragover.value = false
  const file = event.dataTransfer.files[0]
  if (file) {
    processFile(file)
  }
}

async function processFile(file) {
  // File validation
  if (!file.name.match(/\.xlsx$/i)) {
    toast.add({
      severity: 'error',
      summary: 'Invalid File Type',
      detail: 'Please select an Excel file (.xlsx) with embedded images',
      life: 5000
    })
    return
  }

  if (file.size > 25 * 1024 * 1024) { // 25MB limit
    toast.add({
      severity: 'error',
      summary: 'File Too Large',
      detail: 'File size must be less than 25MB',
      life: 5000
    })
    return
  }

  selectedFile.value = file
  
  // Analyze file
  try {
    importStatus.value = 'Analyzing Excel file and extracting images...'
    const preview = await importExcelToCardData(file)
    importPreview.value = preview
    
    if (preview.isValid) {
      toast.add({
        severity: 'success',
        summary: 'File Analyzed',
        detail: `Found ${preview.contentItems.length} content items${extractedImageCount.value > 0 ? ` with ${extractedImageCount.value} embedded images` : ''}`,
        life: 5000
      })
    } else {
      toast.add({
        severity: 'warn',
        summary: 'Validation Issues',
        detail: `File has ${preview.errors.length} errors that must be fixed`,
        life: 5000
      })
    }
  } catch (error) {
    console.error('File analysis error:', error)
    toast.add({
      severity: 'error',
      summary: 'File Analysis Failed',
      detail: error.message || 'Failed to analyze the uploaded file',
      life: 5000
    })
    removeFile()
  }
}

function removeFile() {
  // Clean up object URLs
  createdImageUrls.value.forEach(url => URL.revokeObjectURL(url))
  createdImageUrls.value.clear()
  
  selectedFile.value = null
  importPreview.value = null
  importResults.value = null
  expandedItems.value = []
  if (fileInput.value) {
    fileInput.value.value = ''
  }
}

function cancelImport() {
  importPreview.value = null
  importResults.value = null
}

async function executeImport() {
  if (!selectedFile.value || !importPreview.value || !canExecuteImport.value) return
  
  importing.value = true
  importProgress.value = 0
  importStatus.value = 'Starting import...'
  
  try {
    // Simulate progress updates
    const progressInterval = setInterval(() => {
      if (importProgress.value < 90) {
        importProgress.value += Math.random() * 15
        updateImportStatus()
      }
    }, 300)
    
    // Execute the actual import
    const result = await importDataToDatabase(importPreview.value)
    
    clearInterval(progressInterval)
    importProgress.value = 100
    importStatus.value = 'Import completed'
    
    importResults.value = result
    importPreview.value = null
    
    // Emit event to refresh parent
    emit('imported', result)
    
    toast.add({
      severity: result.success ? 'success' : 'warn',
      summary: result.success ? 'Import Successful' : 'Import Completed with Issues',
      detail: result.message,
      life: 5000
    })
    
  } catch (error) {
    console.error('Import error:', error)
    importResults.value = {
      success: false,
      message: error.message || 'Import failed with unknown error',
      details: { errors: 1 }
    }
    
    toast.add({
      severity: 'error',
      summary: 'Import Failed',
      detail: error.message || 'Failed to import data',
      life: 5000
    })
  } finally {
    importing.value = false
  }
}

async function uploadImageToSupabase(imageData, folder) {
  try {
    const { data: { user } } = await supabase.auth.getUser()
    if (!user) {
      throw new Error('User not authenticated')
    }

    // Create a blob from the image buffer
    const blob = new Blob([imageData.buffer], { type: `image/${imageData.extension}` })
    
    // Generate unique filename
    const fileName = `${Date.now()}_${Math.random().toString(36).substring(7)}.${imageData.extension}`
    const filePath = `${user.id}/${folder}/${fileName}`
    
    // Upload to Supabase storage
    const { data, error } = await supabase.storage
      .from('userfiles')
      .upload(filePath, blob, {
        contentType: `image/${imageData.extension}`,
        upsert: false
      })
    
    if (error) {
      throw error
    }
    
    // Get public URL
    const { data: { publicUrl } } = supabase.storage
      .from('userfiles')
      .getPublicUrl(filePath)
    
    return publicUrl
  } catch (error) {
    console.error('Error uploading image:', error)
    throw error
  }
}

async function importDataToDatabase(importData) {
  const results = {
    cardsCreated: 0,
    contentCreated: 0,
    imagesProcessed: 0,
    warnings: 0,
    errors: []
  };

  try {
    // Import card data
    if (importData.cardData) {
      // Handle card image if it exists
      let cardImageUrl = null;
      if (importData.images && importData.images.has('card_image')) {
        const cardImages = importData.images.get('card_image');
        if (cardImages && cardImages.length > 0) {
          try {
            cardImageUrl = await uploadImageToSupabase(cardImages[0], 'card-images');
            results.imagesProcessed++;
          } catch (imgError) {
            results.errors.push(`Failed to upload card image: ${imgError.message}`);
          }
        }
      }

      const { data, error } = await supabase.rpc('create_card', {
        p_name: importData.cardData.name,
        p_description: importData.cardData.description,
        p_ai_prompt: importData.cardData.ai_prompt,
        p_conversation_ai_enabled: importData.cardData.conversation_ai_enabled,
        p_qr_code_position: importData.cardData.qr_code_position,
        p_content_render_mode: importData.cardData.content_render_mode,
        p_image_url: cardImageUrl
      })
      
      if (error) throw error
      
      const cardId = data; // data is directly the UUID
      results.cardsCreated = 1;
      
      // Import content items
      if (importData.contentItems.length > 0) {
        const parentMap = new Map();
        const layer1Items = importData.contentItems.filter(item => item.layer === 'Layer 1');
        const layer2Items = importData.contentItems.filter(item => item.layer === 'Layer 2');

        // Process Layer 1 items first
        for (const item of layer1Items) {
          try {
            // Handle content item image if it exists
            let contentImageUrl = null;
            if (item.has_images && importData.images) {
              const itemKey = `item_${importData.contentItems.indexOf(item) + 5}`; // Row number in Excel
              const itemImages = importData.images.get(itemKey);
              if (itemImages && itemImages.length > 0) {
                try {
                  contentImageUrl = await uploadImageToSupabase(itemImages[0], 'content-item-images');
                  results.imagesProcessed++;
                } catch (imgError) {
                  results.errors.push(`Failed to upload image for "${item.name}": ${imgError.message}`);
                }
              }
            }

            const { data: contentData, error: contentError } = await supabase.rpc('create_content_item', {
              p_card_id: cardId,
              p_parent_id: null,
              p_name: item.name,
              p_content: item.content,
              p_ai_metadata: item.ai_metadata,
              p_image_url: contentImageUrl
            });
            
            if (contentError) throw contentError;

            const newItemId = contentData; // data is directly the UUID
            parentMap.set(item.name, newItemId);
            results.contentCreated++;
            
          } catch (err) {
            results.errors.push(`Content item "${item.name}": ${err.message}`);
          }
        }

        // Process Layer 2 items
        for (const item of layer2Items) {
          try {
            const parentId = parentMap.get(item.parent_item) || null;
            if (!parentId) {
              results.warnings++;
              results.errors.push(`Parent item "${item.parent_item}" not found for "${item.name}". Skipping.`);
              continue;
            }

            // Handle content item image if it exists
            let contentImageUrl = null;
            if (item.has_images && importData.images) {
              const itemKey = `item_${importData.contentItems.indexOf(item) + 5}`; // Row number in Excel
              const itemImages = importData.images.get(itemKey);
              if (itemImages && itemImages.length > 0) {
                try {
                  contentImageUrl = await uploadImageToSupabase(itemImages[0], 'content-item-images');
                  results.imagesProcessed++;
                } catch (imgError) {
                  results.errors.push(`Failed to upload image for "${item.name}": ${imgError.message}`);
                }
              }
            }

            const { error: contentError } = await supabase.rpc('create_content_item', {
              p_card_id: cardId,
              p_parent_id: parentId,
              p_name: item.name,
              p_content: item.content,
              p_ai_metadata: item.ai_metadata,
              p_image_url: contentImageUrl
            });
            
            if (contentError) throw contentError;
            
            results.contentCreated++;

          } catch (err) {
            results.errors.push(`Content item "${item.name}": ${err.message}`);
          }
        }
      }
    }
    
    // Calculate warnings
    results.warnings = importData.warnings.length
    
    const success = results.errors.length === 0
    const message = success 
      ? `Successfully imported ${results.cardsCreated} card and ${results.contentCreated} content items${results.imagesProcessed > 0 ? ` with ${results.imagesProcessed} images` : ''}`
      : `Import completed with ${results.errors.length} errors`
    
    return {
      success,
      message,
      details: results
    }
    
  } catch (error) {
    throw new Error(`Database import failed: ${error.message}`)
  }
}

function updateImportStatus() {
  const statuses = [
    'Validating data structure...',
    'Creating card record...',
    'Processing content items...',
    'Handling embedded images...',
    'Updating relationships...',
    'Finalizing import...'
  ]
  const statusIndex = Math.floor((importProgress.value / 100) * statuses.length)
  importStatus.value = statuses[Math.min(statusIndex, statuses.length - 1)]
}

function resetImport() {
  removeFile()
  importResults.value = null
  expandedItems.value = []
}

// Clean up object URLs when component is unmounted
onUnmounted(() => {
  createdImageUrls.value.forEach(url => URL.revokeObjectURL(url))
  createdImageUrls.value.clear()
})

function formatFileSize(bytes) {
  if (bytes === 0) return '0 Bytes'
  const k = 1024
  const sizes = ['Bytes', 'KB', 'MB', 'GB']
  const i = Math.floor(Math.log(bytes) / Math.log(k))
  return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i]
}

function truncateText(text, maxLength) {
  if (!text) return ''
  if (text.length <= maxLength) return text
  return text.substring(0, maxLength) + '...'
}

// Function to get card image URL
function getCardImageUrl() {
  if (!importPreview.value || !importPreview.value.images) return null
  
  const cardImages = importPreview.value.images.get('card_image')
  if (cardImages && cardImages.length > 0) {
    const imageData = cardImages[0]
    const blob = new Blob([imageData.buffer], { type: `image/${imageData.extension}` })
    const url = URL.createObjectURL(blob)
    createdImageUrls.value.add(url)
    return url
  }
  return null
}

// Function to get content item image URL
function getItemImageUrl(item, parentIndex) {
  if (!importPreview.value || !importPreview.value.images || !item.has_images) return null
  
  // Calculate the actual row number in Excel for this item
  const layer1Items = importPreview.value.contentItems.filter(i => i.layer === 'Layer 1')
  const itemIndex = layer1Items.findIndex(i => i.name === item.name)
  const excelRowNum = 5 + itemIndex // Excel data starts at row 5
  
  const itemKey = `item_${excelRowNum}`
  const itemImages = importPreview.value.images.get(itemKey)
  if (itemImages && itemImages.length > 0) {
    const imageData = itemImages[0]
    const blob = new Blob([imageData.buffer], { type: `image/${imageData.extension}` })
    const url = URL.createObjectURL(blob)
    createdImageUrls.value.add(url)
    return url
  }
  return null
}

// Function to get child item image URL
function getChildImageUrl(child, parentIndex, childIndex) {
  if (!importPreview.value || !importPreview.value.images || !child.has_images) return null
  
  // Find the actual index of this child in the full content items array
  const allItems = importPreview.value.contentItems
  const childItemIndex = allItems.findIndex(i => i.name === child.name)
  const excelRowNum = 5 + childItemIndex // Excel data starts at row 5
  
  const itemKey = `item_${excelRowNum}`
  const itemImages = importPreview.value.images.get(itemKey)
  if (itemImages && itemImages.length > 0) {
    const imageData = itemImages[0]
    const blob = new Blob([imageData.buffer], { type: `image/${imageData.extension}` })
    const url = URL.createObjectURL(blob)
    createdImageUrls.value.add(url)
    return url
  }
  return null
}
</script>

<style scoped>
.card-bulk-import {
  @apply space-y-6;
}

.import-header {
  @apply bg-gradient-to-r from-slate-50 to-slate-100 rounded-xl p-6 border border-slate-200;
}

.header-content {
  @apply flex items-start gap-4;
}

.import-icon {
  @apply w-12 h-12 bg-blue-600 rounded-full flex items-center justify-center text-white text-xl flex-shrink-0;
}

.import-title {
  @apply text-xl font-semibold text-slate-900 mb-1;
}

.import-description {
  @apply text-slate-600 text-sm leading-relaxed;
}

.quick-actions {
  @apply bg-white border border-slate-200 rounded-lg p-4;
}

.action-grid {
  @apply grid grid-cols-1 sm:grid-cols-2 gap-4;
}

.action-item {
  @apply text-center space-y-2;
}

.template-button {
  @apply w-full;
}

.import-button {
  @apply w-full;
}

.action-desc {
  @apply text-xs text-slate-500 block;
}

.upload-zone {
  @apply bg-white border-2 border-dashed border-slate-300 rounded-xl p-8 transition-all;
}

.upload-zone.dragover {
  @apply border-blue-400 bg-blue-50;
}

.upload-zone.has-file {
  @apply border-blue-400 bg-blue-50;
}

.drop-area {
  @apply cursor-pointer;
}

.drop-content {
  @apply text-center space-y-4;
}

.drop-icon {
  @apply text-4xl text-slate-400;
}

.drop-text h4 {
  @apply text-lg font-medium text-slate-900;
}

.drop-text p {
  @apply text-slate-500;
}

.file-requirements {
  @apply flex flex-col gap-1 text-xs text-slate-500;
}

.file-selected {
  @apply flex items-center gap-4 p-4 bg-white rounded-lg border border-slate-200;
}

.file-icon {
  @apply text-2xl text-blue-600;
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

.file-meta {
  @apply flex gap-2 mt-1;
}

.meta-item {
  @apply flex items-center gap-1 text-xs;
}

.import-preview {
  @apply bg-white border border-slate-200 rounded-lg p-6 space-y-4;
}

.preview-header {
  @apply flex items-center justify-between;
}

.preview-title {
  @apply flex items-center gap-2 text-lg font-semibold text-slate-900;
}

.preview-icon {
  @apply text-blue-500;
}

.preview-stats {
  @apply flex gap-4;
}

.stat-item {
  @apply flex items-center gap-1 text-sm font-medium;
}

.validation-errors {
  @apply bg-red-50 border border-red-200 rounded-lg p-4;
}

.errors-title {
  @apply flex items-center gap-2 text-sm font-semibold text-red-800 mb-3;
}

.errors-list {
  @apply space-y-2;
}

.error-item {
  @apply flex items-start gap-2 text-sm;
}

.error-icon {
  @apply text-red-600 mt-0.5 flex-shrink-0;
}

.error-text {
  @apply text-red-800;
}

.more-errors {
  @apply text-xs text-red-700 font-medium;
}

.validation-warnings {
  @apply bg-yellow-50 border border-yellow-200 rounded-lg p-4;
}

.warnings-title {
  @apply flex items-center gap-2 text-sm font-semibold text-yellow-800 mb-3;
}

.warnings-list {
  @apply space-y-2;
}

.warning-item {
  @apply flex items-start gap-2 text-sm;
}

.warning-icon {
  @apply text-yellow-600 mt-0.5 flex-shrink-0;
}

.warning-text {
  @apply text-yellow-800;
}

.more-warnings {
  @apply text-xs text-yellow-700 font-medium;
}

.card-preview, .content-preview {
  @apply bg-slate-50 rounded-lg p-4;
}

.card-preview-header {
  @apply flex gap-4;
}

.card-image-preview {
  @apply flex-shrink-0;
}

.card-preview-image {
  @apply w-16 h-24 object-cover rounded-lg border border-slate-200;
}

.card-image-placeholder {
  @apply w-16 h-24 bg-slate-100 rounded-lg border border-slate-200 flex items-center justify-center;
}

.card-details {
  @apply flex-1 min-w-0;
}

/* Mobile responsive styles */
@media (max-width: 768px) {
  .card-bulk-import {
    @apply space-y-4;
  }
  
  .action-grid {
    @apply grid-cols-1 gap-3;
  }
  
  .upload-zone {
    @apply p-4;
  }
  
  .drop-content {
    @apply space-y-3;
  }
  
  .drop-icon {
    @apply text-3xl;
  }
  
  .file-requirements {
    @apply text-xs;
  }
  
  .import-preview {
    @apply p-4 space-y-3;
  }
  
  .preview-header {
    @apply flex-col gap-3 items-start;
  }
  
  .preview-stats {
    @apply flex-wrap gap-2;
  }
  
  .card-preview-header {
    @apply flex-col gap-3;
  }
  
  .card-image-preview {
    @apply self-center;
  }
  
  .preview-item-header {
    @apply gap-2;
  }
  
  .preview-item-content {
    @apply ml-10 text-xs;
  }
  
  .preview-child-content {
    @apply ml-6 text-xs;
  }
  
  .preview-thumbnail {
    @apply w-8 h-8;
  }
  
  .preview-thumbnail-small {
    @apply w-6 h-6;
  }
  
  .hierarchical-content-preview {
    @apply space-y-2;
  }
  
  .preview-parent-item {
    @apply p-3;
  }
  
  .preview-child-item {
    @apply p-2;
  }
  
  .preview-actions {
    @apply flex-col gap-3;
  }
  
  .detail-grid {
    @apply grid-cols-2 gap-3;
  }
  
  .import-header {
    @apply p-4;
  }
  
  .header-content {
    @apply gap-3;
  }
  
  .import-title {
    @apply text-lg;
  }
  
  .import-description {
    @apply text-xs;
  }
}

.hierarchical-content-preview {
  @apply space-y-3;
}

.preview-content-group {
  @apply bg-white rounded-lg border border-slate-200 overflow-hidden;
}

.preview-parent-item {
  @apply p-4;
}

.preview-child-item {
  @apply p-3 bg-slate-50;
}

.preview-item-header {
  @apply flex items-center gap-3 mb-2;
}

.expand-icon {
  @apply text-slate-600 cursor-pointer hover:text-blue-600 transition-colors w-4 flex-shrink-0;
}

.expand-icon-placeholder {
  @apply w-4 flex-shrink-0;
}

.preview-thumbnail {
  @apply w-10 h-10 bg-slate-100 rounded-lg border border-slate-200 flex items-center justify-center text-slate-400 flex-shrink-0 overflow-hidden;
}

.preview-thumbnail-small {
  @apply w-8 h-8;
}

.preview-image {
  @apply w-full h-full object-cover;
}

.preview-item-info {
  @apply flex-1 min-w-0;
}

.preview-item-name {
  @apply font-medium text-slate-900 truncate;
}

.preview-item-meta {
  @apply flex items-center gap-2 mt-1 text-sm;
}

.preview-item-content {
  @apply text-sm text-slate-600 ml-16;
}

.preview-child-content {
  @apply ml-12;
}

.preview-children {
  @apply border-t border-slate-200 space-y-0;
}

.child-indent {
  @apply w-6 flex-shrink-0;
}

.children-count {
  @apply text-slate-500;
}

.sub-item-index {
  @apply text-slate-500;
}

.more-children {
  @apply p-3 text-center text-sm text-slate-500 bg-slate-50 border-t border-slate-200 flex items-center justify-center gap-2;
}

/* Expand animation */
.expand-enter-active,
.expand-leave-active {
  @apply transition-all duration-300 ease-in-out overflow-hidden;
}

.expand-enter-from,
.expand-leave-to {
  @apply opacity-0 max-h-0;
}

.expand-enter-to,
.expand-leave-from {
  @apply opacity-100 max-h-96;
}

.preview-section-title {
  @apply flex items-center gap-2 text-sm font-semibold text-slate-900 mb-3;
}

.card-preview-content {
  @apply space-y-2;
}

.preview-field {
  @apply flex gap-2 text-sm;
}

.field-label {
  @apply font-medium text-slate-600 min-w-0 flex-shrink-0;
}

.field-value {
  @apply text-slate-900;
}

.layer-badge {
  @apply px-2 py-1 rounded-full text-xs font-medium;
}

.layer-badge.layer-1 {
  @apply bg-blue-100 text-blue-700;
}

.layer-badge.layer-2 {
  @apply bg-purple-100 text-purple-700;
}

.image-badge {
  @apply px-2 py-1 bg-slate-100 text-slate-700 rounded-full text-xs font-medium flex items-center gap-1;
}

.preview-actions {
  @apply flex justify-end gap-3 pt-4 border-t border-slate-200;
}


.import-progress {
  @apply bg-blue-50 border border-blue-200 rounded-lg p-6 space-y-4;
}

.progress-header {
  @apply flex justify-between items-center;
}

.progress-title {
  @apply text-lg font-semibold text-blue-900;
}

.progress-percent {
  @apply text-sm font-medium text-blue-700;
}

.progress-bar {
  @apply h-3;
}

.progress-status {
  @apply text-center;
}

.status-text {
  @apply text-sm text-blue-700 font-medium;
}

.import-results {
  @apply bg-white border border-slate-200 rounded-lg p-6 space-y-4;
}

.results-header {
  @apply flex items-start gap-4;
}

.results-icon {
  @apply w-12 h-12 rounded-full flex items-center justify-center text-xl flex-shrink-0;
}

.results-icon.success {
  @apply bg-blue-100 text-blue-600;
}

.results-icon.error {
  @apply bg-red-100 text-red-600;
}

.results-title {
  @apply text-lg font-semibold text-slate-900 mb-1;
}

.results-summary {
  @apply text-slate-600;
}

.results-details {
  @apply bg-slate-50 rounded-lg p-4;
}

.detail-grid {
  @apply grid grid-cols-2 sm:grid-cols-4 gap-4;
}

.detail-item {
  @apply text-center;
}

.detail-label {
  @apply block text-xs text-slate-600 mb-1;
}

.detail-value {
  @apply block text-lg font-bold;
}

.detail-value.success {
  @apply text-blue-600;
}

.detail-value.info {
  @apply text-blue-600;
}

.detail-value.warning {
  @apply text-yellow-600;
}

.results-actions {
  @apply text-center pt-4 border-t border-slate-200;
}


.hidden {
  @apply sr-only;
}

/* PrimeVue overrides */
:deep(.p-progressbar) {
  @apply bg-blue-100;
}

:deep(.p-progressbar .p-progressbar-value) {
  @apply bg-blue-500;
}
</style>