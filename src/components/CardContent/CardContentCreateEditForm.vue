<template>
    <div class="space-y-6">
        <!-- ============================================== -->
        <!-- SINGLE MODE: Full Page Content -->
        <!-- ============================================== -->
        <div v-if="contentMode === 'single'" class="grid grid-cols-1 xl:grid-cols-3 gap-6">
            <!-- Image Section -->
            <div class="xl:col-span-1">
                <div class="bg-white rounded-xl shadow-lg border border-purple-200 p-6">
                    <div class="flex items-center gap-3 mb-4">
                        <div class="w-8 h-8 bg-purple-100 rounded-full flex items-center justify-center">
                            <i class="pi pi-image text-purple-600 text-sm"></i>
                        </div>
                        <div>
                            <h3 class="text-base font-semibold text-slate-900">{{ $t('form.single_image') }}</h3>
                            <span class="text-xs text-slate-400">{{ $t('common.optional') }}</span>
                        </div>
                    </div>
                    
                    <ImageUploadSection 
                        :previewImage="previewImage"
                        :isDragActive="isDragActive"
                        @dragover="handleDragOver"
                        @dragleave="handleDragLeave"
                        @drop="handleDrop"
                        @upload="triggerFileInput"
                        @crop="handleCropImage"
                        @undo-crop="handleUndoCrop"
                        :isCropped="isCropped"
                        :uploadTitle="$t('form.add_single_image')"
                        :aspectRatioDisplay="'16:9'"
                    />
                    <input ref="fileInputRef" type="file" accept="image/*" @change="handleFileSelect" class="hidden" />
                </div>
            </div>
            
            <!-- Content Section -->
            <div class="xl:col-span-2">
                <div class="bg-white rounded-xl shadow-lg border border-purple-200 p-6">
                    <div class="flex items-center gap-3 mb-6">
                        <div class="w-10 h-10 bg-purple-100 rounded-full flex items-center justify-center">
                            <i class="pi pi-file text-purple-600"></i>
                        </div>
                        <div>
                            <h3 class="text-lg font-semibold text-slate-900">{{ $t('form.single_content_title') }}</h3>
                            <p class="text-xs text-slate-500">{{ $t('form.single_content_subtitle') }}</p>
                        </div>
                    </div>
                    
                    <div class="space-y-4">
                        <!-- Title -->
                        <div>
                            <label class="block text-sm font-medium text-slate-700 mb-2">{{ $t('form.single_title') }} *</label>
                            <InputText 
                                v-model="formData.name" 
                                class="w-full" 
                                :placeholder="$t('form.single_title_placeholder')"
                                :class="{ 'p-invalid': !formData.name.trim() }"
                            />
                        </div>

                        <!-- Full Content -->
                        <div>
                            <label class="block text-sm font-medium text-slate-700 mb-2">{{ $t('form.single_content') }}</label>
                            <MdEditor 
                                v-model="formData.description"
                                language="en-US"
                                :toolbars="markdownToolbars"
                                :placeholder="$t('form.single_content_placeholder')"
                                :onHtmlChanged="handleMarkdownHtmlChanged"
                                style="height: 350px;"
                            />
                        </div>
                    </div>

                    <!-- AI Context -->
                    <div v-if="cardAiEnabled" class="mt-6 pt-6 border-t border-slate-200">
                        <AIContextSection 
                            v-model="formData.aiKnowledgeBase"
                            :label="$t('form.single_ai_context')"
                            :placeholder="$t('form.single_ai_placeholder')"
                            :hint="$t('form.single_ai_hint')"
                        />
                    </div>
                </div>
            </div>
        </div>

        <!-- ============================================== -->
        <!-- GROUPED MODE: Category Header or Sub-Item -->
        <!-- ============================================== -->
        <div v-else-if="contentMode === 'grouped'">
            <!-- CATEGORY (no parent) -->
            <div v-if="!parentId" class="bg-white rounded-xl shadow-lg border border-orange-200 p-6">
                <div class="flex items-center gap-3 mb-6">
                    <div class="w-10 h-10 bg-orange-100 rounded-full flex items-center justify-center">
                        <i class="pi pi-folder text-orange-600"></i>
                    </div>
                    <div>
                        <h3 class="text-lg font-semibold text-slate-900">{{ $t('form.category_title') }}</h3>
                        <p class="text-xs text-slate-500">{{ $t('form.category_subtitle') }}</p>
                    </div>
                </div>
                
                <div class="space-y-4">
                    <!-- Category Name -->
                    <div>
                        <label class="block text-sm font-medium text-slate-700 mb-2">{{ $t('form.category_name') }} *</label>
                        <InputText 
                            v-model="formData.name" 
                            class="w-full" 
                            :placeholder="$t('form.category_name_placeholder')"
                            :class="{ 'p-invalid': !formData.name.trim() }"
                        />
                        <small class="text-slate-500 mt-1 block">{{ $t('form.category_name_hint') }}</small>
                    </div>
                </div>

                <!-- AI Context -->
                <div v-if="cardAiEnabled" class="mt-6 pt-6 border-t border-slate-200">
                    <AIContextSection 
                        v-model="formData.aiKnowledgeBase"
                        :label="$t('form.category_ai_context')"
                        :placeholder="$t('form.category_ai_placeholder')"
                        :hint="$t('form.category_ai_hint')"
                    />
                </div>
            </div>

            <!-- SUB-ITEM (has parent) -->
            <div v-else class="grid grid-cols-1 xl:grid-cols-3 gap-6">
                <!-- Image -->
                <div class="xl:col-span-1">
                    <div class="bg-white rounded-xl shadow-lg border border-amber-200 p-6">
                        <div class="flex items-center gap-3 mb-4">
                            <div class="w-8 h-8 bg-amber-100 rounded-full flex items-center justify-center">
                                <i class="pi pi-image text-amber-600 text-sm"></i>
                            </div>
                            <div>
                                <h3 class="text-base font-semibold text-slate-900">{{ $t('form.grouped_item_image') }}</h3>
                                <span class="text-xs text-slate-400">{{ $t('common.optional') }}</span>
                            </div>
                        </div>
                        
                        <ImageUploadSection 
                            :previewImage="previewImage"
                            :isDragActive="isDragActive"
                            @dragover="handleDragOver"
                            @dragleave="handleDragLeave"
                            @drop="handleDrop"
                            @upload="triggerFileInput"
                            @crop="handleCropImage"
                            @undo-crop="handleUndoCrop"
                            :isCropped="isCropped"
                            :uploadTitle="$t('form.add_item_image')"
                            :aspectRatioDisplay="getContentAspectRatioDisplay()"
                        />
                        <input ref="fileInputRef" type="file" accept="image/*" @change="handleFileSelect" class="hidden" />
                    </div>
                </div>
                
                <!-- Details -->
                <div class="xl:col-span-2">
                    <div class="bg-white rounded-xl shadow-lg border border-amber-200 p-6">
                        <div class="flex items-center gap-3 mb-6">
                            <div class="w-10 h-10 bg-amber-100 rounded-full flex items-center justify-center">
                                <i class="pi pi-list text-amber-600"></i>
                            </div>
                            <div>
                                <h3 class="text-lg font-semibold text-slate-900">{{ $t('form.grouped_item_title') }}</h3>
                                <p class="text-xs text-slate-500">{{ $t('form.grouped_item_subtitle') }}</p>
                            </div>
                        </div>
                        
                        <div class="space-y-4">
                            <!-- Item Name -->
                            <div>
                                <label class="block text-sm font-medium text-slate-700 mb-2">{{ $t('form.grouped_item_name') }} *</label>
                                <InputText 
                                    v-model="formData.name" 
                                    class="w-full" 
                                    :placeholder="$t('form.grouped_item_name_placeholder')"
                                    :class="{ 'p-invalid': !formData.name.trim() }"
                                />
                            </div>

                            <!-- Item Description -->
                            <div>
                                <label class="block text-sm font-medium text-slate-700 mb-2">{{ $t('form.grouped_item_desc') }}</label>
                                <MdEditor 
                                    v-model="formData.description"
                                    language="en-US"
                                    :toolbars="markdownToolbars"
                                    :placeholder="$t('form.grouped_item_desc_placeholder')"
                                    :onHtmlChanged="handleMarkdownHtmlChanged"
                                    style="height: 200px;"
                                />
                            </div>
                        </div>

                        <!-- AI Context -->
                        <div v-if="cardAiEnabled" class="mt-6 pt-6 border-t border-slate-200">
                            <AIContextSection 
                                v-model="formData.aiKnowledgeBase"
                                :label="$t('form.grouped_item_ai')"
                                :placeholder="$t('form.grouped_item_ai_placeholder')"
                                :hint="$t('form.grouped_item_ai_hint')"
                            />
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <!-- ============================================== -->
        <!-- LIST MODE: Simple List Item -->
        <!-- ============================================== -->
        <div v-else-if="contentMode === 'list'" class="bg-white rounded-xl shadow-lg border border-blue-200 p-6">
            <div class="flex items-center gap-3 mb-6">
                <div class="w-10 h-10 bg-blue-100 rounded-full flex items-center justify-center">
                    <i class="pi pi-list text-blue-600"></i>
                </div>
                <div>
                    <h3 class="text-lg font-semibold text-slate-900">{{ $t('form.list_item_title') }}</h3>
                    <p class="text-xs text-slate-500">{{ $t('form.list_item_subtitle') }}</p>
                </div>
            </div>
            
            <div class="space-y-4">
                <!-- Item Title -->
                <div>
                    <label class="block text-sm font-medium text-slate-700 mb-2">
                        {{ $t('form.list_item_name') }} *
                    </label>
                    <InputText 
                        v-model="formData.name" 
                        class="w-full" 
                        :placeholder="$t('form.list_item_name_placeholder')"
                        :class="{ 'p-invalid': !formData.name.trim() }"
                    />
                </div>

                <!-- URL or Content -->
                <div>
                    <label class="block text-sm font-medium text-slate-700 mb-2">
                        {{ $t('form.list_item_content') }}
                    </label>
                    <div class="relative">
                        <i class="pi pi-link absolute left-3 top-1/2 -translate-y-1/2 text-slate-400"></i>
                        <InputText 
                            v-model="formData.description" 
                            class="w-full pl-10" 
                            :placeholder="$t('form.list_item_content_placeholder')"
                        />
                    </div>
                    <small class="text-slate-500 mt-1 block">{{ $t('form.list_item_content_hint') }}</small>
                </div>
            </div>

            <!-- AI Context -->
            <div v-if="cardAiEnabled" class="mt-6 pt-6 border-t border-slate-200">
                <AIContextSection 
                    v-model="formData.aiKnowledgeBase"
                    :label="$t('form.list_item_ai')"
                    :placeholder="$t('form.list_item_ai_placeholder')"
                    :hint="$t('form.list_item_ai_hint')"
                />
            </div>
        </div>

        <!-- ============================================== -->
        <!-- GRID MODE: Visual Gallery Item -->
        <!-- ============================================== -->
        <div v-else-if="contentMode === 'grid'" class="grid grid-cols-1 xl:grid-cols-3 gap-6">
            <!-- Image Section -->
            <div class="xl:col-span-1">
                <div class="bg-white rounded-xl shadow-lg border border-green-200 p-6">
                    <div class="flex items-center gap-3 mb-4">
                        <div class="w-8 h-8 bg-green-100 rounded-full flex items-center justify-center">
                            <i class="pi pi-image text-green-600 text-sm"></i>
                        </div>
                        <h3 class="text-base font-semibold text-slate-900">{{ $t('form.grid_image') }} *</h3>
                    </div>
                    
                    <ImageUploadSection 
                        :previewImage="previewImage"
                        :isDragActive="isDragActive"
                        @dragover="handleDragOver"
                        @dragleave="handleDragLeave"
                        @drop="handleDrop"
                        @upload="triggerFileInput"
                        @crop="handleCropImage"
                        @undo-crop="handleUndoCrop"
                        :isCropped="isCropped"
                        :uploadTitle="$t('form.add_grid_image')"
                        :aspectRatioDisplay="'1:1'"
                    />
                    <input ref="fileInputRef" type="file" accept="image/*" @change="handleFileSelect" class="hidden" />
                    <p class="text-xs text-slate-500 mt-3 text-center">{{ $t('form.grid_image_hint') }}</p>
                </div>
            </div>
            
            <!-- Details Section -->
            <div class="xl:col-span-2">
                <div class="bg-white rounded-xl shadow-lg border border-green-200 p-6">
                    <div class="flex items-center gap-3 mb-6">
                        <div class="w-10 h-10 bg-green-100 rounded-full flex items-center justify-center">
                            <i class="pi pi-th-large text-green-600"></i>
                        </div>
                        <div>
                            <h3 class="text-lg font-semibold text-slate-900">{{ $t('form.grid_item_title') }}</h3>
                            <p class="text-xs text-slate-500">{{ $t('form.grid_item_subtitle') }}</p>
                        </div>
                    </div>
                    
                    <div class="space-y-4">
                        <!-- Item Name -->
                        <div>
                            <label class="block text-sm font-medium text-slate-700 mb-2">{{ $t('form.grid_item_name') }} *</label>
                            <InputText 
                                v-model="formData.name" 
                                class="w-full" 
                                :placeholder="$t('form.grid_item_name_placeholder')"
                                :class="{ 'p-invalid': !formData.name.trim() }"
                            />
                        </div>

                        <!-- Item Description -->
                        <div>
                            <label class="block text-sm font-medium text-slate-700 mb-2">{{ $t('form.grid_item_desc') }}</label>
                            <MdEditor 
                                v-model="formData.description"
                                language="en-US"
                                :toolbars="markdownToolbars"
                                :placeholder="$t('form.grid_item_desc_placeholder')"
                                :onHtmlChanged="handleMarkdownHtmlChanged"
                                style="height: 200px;"
                            />
                        </div>
                    </div>

                    <!-- AI Context -->
                    <div v-if="cardAiEnabled" class="mt-6 pt-6 border-t border-slate-200">
                        <AIContextSection 
                            v-model="formData.aiKnowledgeBase"
                            :label="$t('form.grid_item_ai')"
                            :placeholder="$t('form.grid_item_ai_placeholder')"
                            :hint="$t('form.grid_item_ai_hint')"
                        />
                    </div>
                </div>
            </div>
        </div>

        <!-- ============================================== -->
        <!-- INLINE MODE: Full-Width Card Item -->
        <!-- ============================================== -->
        <div v-else-if="contentMode === 'inline'" class="grid grid-cols-1 xl:grid-cols-3 gap-6">
            <!-- Image Section -->
            <div class="xl:col-span-1">
                <div class="bg-white rounded-xl shadow-lg border border-cyan-200 p-6">
                    <div class="flex items-center gap-3 mb-4">
                        <div class="w-8 h-8 bg-cyan-100 rounded-full flex items-center justify-center">
                            <i class="pi pi-image text-cyan-600 text-sm"></i>
                        </div>
                        <div>
                            <h3 class="text-base font-semibold text-slate-900">{{ $t('form.inline_image') }}</h3>
                            <span class="text-xs text-slate-400">{{ $t('form.inline_image_recommended') }}</span>
                        </div>
                    </div>
                    
                    <ImageUploadSection 
                        :previewImage="previewImage"
                        :isDragActive="isDragActive"
                        @dragover="handleDragOver"
                        @dragleave="handleDragLeave"
                        @drop="handleDrop"
                        @upload="triggerFileInput"
                        @crop="handleCropImage"
                        @undo-crop="handleUndoCrop"
                        :isCropped="isCropped"
                        :uploadTitle="$t('form.add_inline_image')"
                        :aspectRatioDisplay="'16:9'"
                    />
                    <input ref="fileInputRef" type="file" accept="image/*" @change="handleFileSelect" class="hidden" />
                    <p class="text-xs text-slate-500 mt-3 text-center">{{ $t('form.inline_image_hint') }}</p>
                </div>
            </div>
            
            <!-- Details Section -->
            <div class="xl:col-span-2">
                <div class="bg-white rounded-xl shadow-lg border border-cyan-200 p-6">
                    <div class="flex items-center gap-3 mb-6">
                        <div class="w-10 h-10 bg-cyan-100 rounded-full flex items-center justify-center">
                            <i class="pi pi-clone text-cyan-600"></i>
                        </div>
                        <div>
                            <h3 class="text-lg font-semibold text-slate-900">{{ $t('form.inline_item_title') }}</h3>
                            <p class="text-xs text-slate-500">{{ $t('form.inline_item_subtitle') }}</p>
                        </div>
                    </div>
                    
                    <div class="space-y-4">
                        <!-- Item Title -->
                        <div>
                            <label class="block text-sm font-medium text-slate-700 mb-2">{{ $t('form.inline_item_name') }} *</label>
                            <InputText 
                                v-model="formData.name" 
                                class="w-full" 
                                :placeholder="$t('form.inline_item_name_placeholder')"
                                :class="{ 'p-invalid': !formData.name.trim() }"
                            />
                        </div>

                        <!-- Item Description -->
                        <div>
                            <label class="block text-sm font-medium text-slate-700 mb-2">{{ $t('form.inline_item_desc') }}</label>
                            <MdEditor 
                                v-model="formData.description"
                                language="en-US"
                                :toolbars="markdownToolbars"
                                :placeholder="$t('form.inline_item_desc_placeholder')"
                                :onHtmlChanged="handleMarkdownHtmlChanged"
                                style="height: 200px;"
                            />
                        </div>
                    </div>

                    <!-- AI Context -->
                    <div v-if="cardAiEnabled" class="mt-6 pt-6 border-t border-slate-200">
                        <AIContextSection 
                            v-model="formData.aiKnowledgeBase"
                            :label="$t('form.inline_item_ai')"
                            :placeholder="$t('form.inline_item_ai_placeholder')"
                            :hint="$t('form.inline_item_ai_hint')"
                        />
                    </div>
                </div>
            </div>
        </div>

        <!-- ============================================== -->
        <!-- DEFAULT/FALLBACK: Generic Content Item -->
        <!-- ============================================== -->
        <div v-else class="grid grid-cols-1 xl:grid-cols-3 gap-6">
            <!-- Image Section -->
            <div class="xl:col-span-1">
                <div class="bg-white rounded-xl shadow-lg border border-slate-200 p-6">
                    <h3 class="text-lg font-semibold text-slate-900 mb-6 flex items-center gap-2">
                        <i class="pi pi-image text-blue-600"></i>
                        {{ parentId ? $t('dashboard.sub_item_image_label') : $t('dashboard.content_item_image') }}
                    </h3>
                    
                    <ImageUploadSection 
                        :previewImage="previewImage"
                        :isDragActive="isDragActive"
                        @dragover="handleDragOver"
                        @dragleave="handleDragLeave"
                        @drop="handleDrop"
                        @upload="triggerFileInput"
                        @crop="handleCropImage"
                        @undo-crop="handleUndoCrop"
                        :isCropped="isCropped"
                        :uploadTitle="parentId ? $t('dashboard.add_sub_item_image') : $t('dashboard.add_content_image')"
                        :aspectRatioDisplay="getContentAspectRatioDisplay()"
                    />
                    <input ref="fileInputRef" type="file" accept="image/*" @change="handleFileSelect" class="hidden" />
                </div>
            </div>
            
            <!-- Form Fields Section -->
            <div class="xl:col-span-2">
                <div class="bg-white rounded-xl shadow-lg border border-slate-200 p-6 space-y-6">
                    <div>
                        <h3 class="text-lg font-semibold text-slate-900 mb-4 flex items-center gap-2">
                            <i class="pi pi-file-edit text-blue-600"></i>
                            {{ parentId ? $t('dashboard.sub_item_details') : $t('dashboard.content_item_details') }}
                        </h3>
                        
                        <div class="space-y-4">
                            <div>
                                <label class="block text-sm font-medium text-slate-700 mb-2">{{ $t('dashboard.name_label') }} *</label>
                                <InputText 
                                    v-model="formData.name" 
                                    class="w-full" 
                                    :placeholder="$t('dashboard.enter_content_name', { type: itemTypeLabelLower })"
                                    :class="{ 'p-invalid': !formData.name.trim() }"
                                />
                            </div>

                            <div>
                                <label class="block text-sm font-medium text-slate-700 mb-2">{{ $t('dashboard.description_markdown') }}</label>
                                <MdEditor 
                                    v-model="formData.description"
                                    language="en-US"
                                    :toolbars="markdownToolbars"
                                    :placeholder="getDescriptionPlaceholder()"
                                    :onHtmlChanged="handleMarkdownHtmlChanged"
                                    style="height: 300px;"
                                />
                            </div>
                        </div>
                    </div>

                    <!-- AI Knowledge Base Section -->
                    <div v-if="cardAiEnabled" class="border-t border-slate-200 pt-6">
                        <AIContextSection 
                            v-model="formData.aiKnowledgeBase"
                            :label="$t('dashboard.ai_knowledge_base_content')"
                            :placeholder="getAiKnowledgePlaceholder()"
                            :hint="$t('dashboard.ai_knowledge_purpose_content', { type: itemTypeLabelLower })"
                        />
                    </div>
                </div>
            </div>
        </div>
    </div>

    <!-- Image Cropping Dialog -->
    <MyDialog 
        v-model="showCropDialog"
        modal
        :header="$t('dashboard.crop_content_image', { type: itemTypeLabel })"
        :style="{ width: '90vw', maxWidth: '800px' }"
        :closable="false"
        :showConfirm="true"
        :showCancel="true"
        :confirmLabel="$t('dashboard.apply')"
        :cancelLabel="$t('common.cancel')"
        :confirmHandle="handleCropConfirm"
        @cancel="handleCropCancelled"
    >
        <ImageCropper
            v-if="showCropDialog && cropImageSrc"
            :imageSrc="cropImageSrc"
            :aspectRatio="getCropAspectRatio()"
            :aspectRatioDisplay="getCropAspectRatioDisplay()"
            :cropParameters="cropParameters"
            ref="imageCropperRef"
        />
    </MyDialog>
</template>

<script setup>
import { ref, watch, computed, onMounted, nextTick, defineProps, defineEmits, defineExpose } from 'vue';
import { useI18n } from 'vue-i18n';
import Button from 'primevue/button';
import Textarea from 'primevue/textarea';
import InputText from 'primevue/inputtext';

const { t } = useI18n();
import MyDialog from '@/components/MyDialog.vue';
import ImageCropper from '@/components/ImageCropper.vue';
import ImageUploadSection from './ImageUploadSection.vue';
import AIContextSection from './AIContextSection.vue';
import cardPlaceholder from '@/assets/images/card-placeholder.svg';
import { getContentAspectRatioNumber, getContentAspectRatioDisplay, getContentAspectRatio } from '@/utils/cardConfig';
import { MdEditor } from 'md-editor-v3';
import 'md-editor-v3/lib/style.css';
import { generateCropPreview } from '@/utils/cropUtils';

const props = defineProps({
    contentItem: {
        type: Object,
        default: null
    },
    mode: {
        type: String,
        default: 'create' // 'create' or 'edit'
    },
    loading: {
        type: Boolean,
        default: false
    },
    parentId: {
        type: String,
        default: null
    },
    cardAiEnabled: {
        type: Boolean,
        default: false
    },
    cardId: {
        type: String,
        required: true
    },
    contentMode: {
        type: String,
        default: 'list', // 'single', 'grouped', 'list', 'grid', 'inline'
        validator: (value) => ['single', 'grouped', 'list', 'grid', 'inline'].includes(value)
    }
});

const emit = defineEmits(['cancel']);

// Determine the item type label based on whether it has a parent
const itemTypeLabel = computed(() => {
    return props.parentId ? t('content.sub_item') : t('content.content_item');
});

// Lowercase version for placeholders
const itemTypeLabelLower = computed(() => {
    return props.parentId ? t('dashboard.sub_item_lower') : t('dashboard.content_item_lower');
});

// Generate appropriate placeholder text for description (for fallback mode)
const getDescriptionPlaceholder = () => {
    if (props.parentId) {
        return t('content.sub_item_description_placeholder');
    } else {
        return t('content.content_item_description_placeholder');
    }
};

// Generate appropriate placeholder text for AI knowledge base (for fallback mode)
const getAiKnowledgePlaceholder = () => {
    if (props.parentId) {
        return t('content.sub_item_ai_placeholder');
    } else {
        return t('content.content_item_ai_placeholder');
    }
};

// Get crop aspect ratio based on content mode
const getCropAspectRatio = () => {
    switch (props.contentMode) {
        case 'single':
        case 'inline':
            return 16 / 9;
        case 'grid':
            return 1;
        default:
            return getContentAspectRatioNumber();
    }
};

const getCropAspectRatioDisplay = () => {
    switch (props.contentMode) {
        case 'single':
        case 'inline':
            return '16:9';
        case 'grid':
            return '1:1';
        default:
            return getContentAspectRatioDisplay();
    }
};

const formData = ref({
    id: null,
    name: '',
    description: '',
    imageUrl: null,
    originalImageUrl: null,
    aiKnowledgeBase: '',
    cropParameters: null
});

// Word count computed property
const aiKnowledgeBaseWordCount = computed(() => {
    return (formData.value.aiKnowledgeBase || '').trim().split(/\s+/).filter(word => word.length > 0).length;
});

const previewImage = ref(null);
const imageFile = ref(null);
const croppedImageFile = ref(null);
const originalData = ref(null);

// Cropping state
const showCropDialog = ref(false);
const cropImageSrc = ref(null);
const imageCropperRef = ref(null);
const cropParameters = ref(null);

// LinkedIn-style upload variables
const isDragActive = ref(false);
const fileInputRef = ref(null);

// Check if image is cropped
const isCropped = computed(() => {
    return croppedImageFile.value !== null || cropParameters.value !== null || formData.value.cropParameters !== null;
});

// Markdown editor configuration
const markdownToolbars = ref([
    'bold',
    'underline',
    'italic',
    '-',
    'title',
    'strikeThrough',
    'sub',
    'sup',
    'quote',
    'unorderedList',
    'orderedList',
    '-',
    'codeRow',
    'code',
    'link',
    'table',
    '-',
    'revoke',
    'next',
    'save',
    '=',
    'pageFullscreen',
    'fullscreen',
    'preview',
    'htmlPreview',
    'catalog'
]);

// Handle markdown HTML preview to add target="_blank" to links
const handleMarkdownHtmlChanged = (html) => {
    return html.replace(/<a href=/g, '<a target="_blank" rel="noopener noreferrer" href=');
};

// Initialize form data when contentItem changes
watch(() => props.contentItem, (newVal) => {
    if (newVal && typeof newVal === 'object') {
        formData.value = {
            id: newVal.id,
            name: newVal.name || '',
            description: newVal.description || newVal.content || '',
            imageUrl: newVal.imageUrl || newVal.image_url || null,
            originalImageUrl: newVal.originalImageUrl || newVal.original_image_url || null,
            aiKnowledgeBase: newVal.aiKnowledgeBase || newVal.ai_knowledge_base || '',
            cropParameters: newVal.cropParameters || newVal.crop_parameters || null
        };
        originalData.value = { ...formData.value };
        
        if (formData.value.cropParameters) {
            cropParameters.value = formData.value.cropParameters;
        }
        
        previewImage.value = formData.value.imageUrl;
    }
}, { immediate: true });

const handleImageUpload = (event) => {
    const file = event.files[0];
    if (file) {
        imageFile.value = file;
        
        const reader = new FileReader();
        reader.onload = (e) => {
            previewImage.value = e.target.result;
        };
        reader.readAsDataURL(file);
        
        croppedImageFile.value = null;
        cropParameters.value = null;
        formData.value.cropParameters = null;
    }
};

const handleCropImage = () => {
    const originalImage = imageFile.value || formData.value.originalImageUrl || formData.value.imageUrl;
    
    if (originalImage) {
        const imageSrc = imageFile.value ? URL.createObjectURL(imageFile.value) : originalImage;
        cropImageSrc.value = imageSrc;
        cropParameters.value = formData.value.cropParameters || null;
        showCropDialog.value = true;
    } else {
        console.warn('No image available for cropping');
    }
};

const handleUndoCrop = () => {
    croppedImageFile.value = null;
    cropParameters.value = null;
    formData.value.cropParameters = null;
    
    if (imageFile.value) {
        const reader = new FileReader();
        reader.onload = (e) => {
            previewImage.value = e.target.result;
        };
        reader.readAsDataURL(imageFile.value);
    } else if (formData.value.originalImageUrl) {
        previewImage.value = formData.value.originalImageUrl;
    } else if (formData.value.imageUrl) {
        previewImage.value = formData.value.imageUrl;
    }
};

const triggerFileInput = () => {
    fileInputRef.value?.click();
};

const handleFileSelect = (event) => {
    const file = event.target.files[0];
    if (file) {
        processImageFile(file);
    }
};

const handleDragOver = (event) => {
    event.preventDefault();
    isDragActive.value = true;
};

const handleDragLeave = (event) => {
    event.preventDefault();
    isDragActive.value = false;
};

const handleDrop = (event) => {
    event.preventDefault();
    isDragActive.value = false;
    
    const files = event.dataTransfer.files;
    if (files.length > 0) {
        const file = files[0];
        if (file.type.startsWith('image/')) {
            processImageFile(file);
        }
    }
};

const processImageFile = (file) => {
    if (file.size > 5000000) {
        console.error('File size exceeds 5MB limit');
        return;
    }
    
    imageFile.value = file;
    const previewUrl = URL.createObjectURL(file);
    previewImage.value = previewUrl;
    
    croppedImageFile.value = null;
    cropParameters.value = null;
    formData.value.cropParameters = null;
};

const handleCancel = () => {
    if (props.mode === 'edit' && originalData.value) {
        formData.value = { ...originalData.value };
        previewImage.value = originalData.value.imageUrl;
        imageFile.value = null;
    } else {
        resetForm();
    }
    emit('cancel');
};

const getFormData = () => {
    formData.value.cropParameters = cropParameters.value;
    
    return {
        formData: formData.value,
        imageFile: imageFile.value,
        croppedImageFile: croppedImageFile.value,
        cropParameters: cropParameters.value
    };
};

const resetForm = () => {
    formData.value = {
        id: null,
        name: '',
        description: '',
        imageUrl: null,
        originalImageUrl: null,
        aiKnowledgeBase: '',
        cropParameters: null
    };
    previewImage.value = null;
    imageFile.value = null;
    croppedImageFile.value = null;
    originalData.value = null;
    showCropDialog.value = false;
    cropImageSrc.value = null;
    cropParameters.value = null;
};

const handleCropConfirm = async () => {
    await nextTick();
    
    if (imageCropperRef.value) {
        try {
            const cropParams = imageCropperRef.value.getCropParameters();
            const croppedDataURL = imageCropperRef.value.getCroppedImage();
            
            if (cropParams && croppedDataURL) {
                cropParameters.value = cropParams;
                
                const arr = croppedDataURL.split(',');
                const mime = arr[0].match(/:(.*?);/)[1];
                const bstr = atob(arr[1]);
                let n = bstr.length;
                const u8arr = new Uint8Array(n);
                while (n--) {
                    u8arr[n] = bstr.charCodeAt(n);
                }
                croppedImageFile.value = new File([u8arr], 'cropped-image.jpg', { type: mime });
                
                previewImage.value = croppedDataURL;
            }
        } catch (error) {
            console.error('Error generating crop:', error);
        }
    }
    
    showCropDialog.value = false;
    cropImageSrc.value = null;
};

const handleCropCancelled = () => {
    showCropDialog.value = false;
    cropImageSrc.value = null;
};

onMounted(() => {
    const aspectRatio = getContentAspectRatio();
    document.documentElement.style.setProperty('--content-aspect-ratio', aspectRatio);
});

defineExpose({
    getFormData,
    resetForm
});
</script>

<style scoped>
.content-image-container {
    aspect-ratio: var(--content-aspect-ratio, 4/3);
    width: 100%;
    background-color: white;
}

.content-image-container-compact {
    aspect-ratio: var(--content-aspect-ratio, 4/3);
    width: 100%;
    max-width: 300px;
    margin: 0 auto;
    background-color: white;
}

:deep(.md-editor-preview-wrapper) a {
    color: #3b82f6 !important;
    text-decoration: underline;
    display: -webkit-box;
    -webkit-line-clamp: 2;
    -webkit-box-orient: vertical;
    overflow: hidden;
    text-overflow: ellipsis;
    word-break: break-word;
}

:deep(.md-editor-preview-wrapper) a:hover {
    color: #1d4ed8 !important;
}
</style>
