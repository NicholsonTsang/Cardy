<template>
    <div class="space-y-6">
        <!-- Action Buttons - Only show in standalone edit mode -->
        <div class="flex justify-end gap-3 mb-6" v-if="isEditMode && !isInDialog">
            <Button 
                :label="$t('common.cancel')" 
                icon="pi pi-times" 
                severity="secondary" 
                outlined
                class="px-4 py-2"
                @click="handleCancel" 
            />
            <Button 
                :label="$t('dashboard.save_changes')" 
                icon="pi pi-save" 
                class="px-4 py-2 shadow-lg hover:shadow-xl transition-shadow bg-blue-600 hover:bg-blue-700 text-white border-0"
                :disabled="!isFormValid"
                :loading="loading"
                @click="handleSave" 
            />
        </div>

        <!-- Access Mode Selector - First Step (Only for new cards) -->
        <div class="bg-white rounded-xl shadow-lg border border-slate-200 p-6 mb-6">
            <h3 class="text-lg font-semibold text-slate-900 mb-4 flex items-center gap-2">
                <i class="pi pi-sliders-h text-blue-600"></i>
                {{ $t('dashboard.access_mode') }}
                <span v-if="!isEditMode" class="text-xs font-normal text-slate-500 ml-2">{{ $t('dashboard.select_first') }}</span>
                <span v-else class="text-xs font-normal text-amber-600 ml-2">
                    <i class="pi pi-lock mr-1"></i>{{ $t('dashboard.access_mode_locked') }}
                </span>
            </h3>
            
            <!-- Edit Mode: Show locked access mode -->
            <div v-if="isEditMode" class="p-5 rounded-xl border-2 text-left"
                 :class="formData.billing_type === 'physical' 
                     ? 'border-purple-500 bg-purple-50' 
                     : 'border-cyan-500 bg-cyan-50'">
                <div class="flex items-start gap-4">
                    <div class="w-12 h-12 rounded-xl flex items-center justify-center flex-shrink-0" 
                         :class="formData.billing_type === 'physical' ? 'bg-purple-100' : 'bg-cyan-100'">
                        <i :class="['text-xl', formData.billing_type === 'physical' ? 'pi pi-credit-card text-purple-600' : 'pi pi-qrcode text-cyan-600']"></i>
                    </div>
                    <div class="flex-1">
                        <div class="flex items-center gap-2 mb-1">
                            <span class="font-bold text-base" :class="formData.billing_type === 'physical' ? 'text-purple-900' : 'text-cyan-900'">
                                {{ formData.billing_type === 'physical' ? $t('dashboard.physical_card') : $t('dashboard.digital_access') }}
                            </span>
                            <span class="px-2 py-0.5 text-xs font-medium rounded-full"
                                  :class="formData.billing_type === 'physical' ? 'bg-purple-200 text-purple-800' : 'bg-cyan-200 text-cyan-800'">
                                <i class="pi pi-lock mr-1"></i>{{ $t('dashboard.locked') }}
                            </span>
                        </div>
                        <p class="text-sm" :class="formData.billing_type === 'physical' ? 'text-purple-700' : 'text-cyan-700'">
                            {{ $t('dashboard.access_mode_cannot_change') }}
                        </p>
                    </div>
                </div>
            </div>
            
            <!-- Create Mode: Allow selection -->
            <div v-else class="grid grid-cols-1 md:grid-cols-2 gap-4">
                <!-- Physical Card Option -->
                <button
                    type="button"
                    @click="formData.billing_type = 'physical'"
                    class="p-5 rounded-xl border-2 transition-all text-left"
                    :class="formData.billing_type === 'physical' 
                        ? 'border-purple-500 bg-purple-50 ring-2 ring-purple-200' 
                        : 'border-slate-200 hover:border-slate-300 bg-white'"
                >
                    <div class="flex items-start gap-4">
                        <div class="w-12 h-12 rounded-xl flex items-center justify-center flex-shrink-0" 
                             :class="formData.billing_type === 'physical' ? 'bg-purple-100' : 'bg-slate-100'">
                            <i class="pi pi-credit-card text-xl" :class="formData.billing_type === 'physical' ? 'text-purple-600' : 'text-slate-500'"></i>
                        </div>
                        <div class="flex-1">
                            <div class="flex items-center gap-2 mb-1">
                                <span class="font-bold text-base" :class="formData.billing_type === 'physical' ? 'text-purple-900' : 'text-slate-800'">
                                    {{ $t('dashboard.physical_card') }}
                                </span>
                                <span v-if="formData.billing_type === 'physical'" class="px-2 py-0.5 bg-purple-200 text-purple-800 text-xs font-medium rounded-full">
                                    {{ $t('common.selected') }}
                                </span>
                            </div>
                            <p class="text-sm text-slate-600 mb-3">{{ $t('dashboard.physical_card_full_desc') }}</p>
                            <div class="flex flex-wrap gap-2 text-xs">
                                <span class="inline-flex items-center gap-1 px-2 py-1 bg-green-100 text-green-700 rounded-full">
                                    <i class="pi pi-check"></i> {{ $t('dashboard.unlimited_scans') }}
                                </span>
                                <span class="inline-flex items-center gap-1 px-2 py-1 bg-blue-100 text-blue-700 rounded-full">
                                    <i class="pi pi-image"></i> {{ $t('dashboard.card_image_required') }}
                                </span>
                            </div>
                        </div>
                    </div>
                </button>
                
                <!-- Digital Access Option -->
                <button
                    type="button"
                    @click="formData.billing_type = 'digital'"
                    class="p-5 rounded-xl border-2 transition-all text-left"
                    :class="formData.billing_type === 'digital' 
                        ? 'border-cyan-500 bg-cyan-50 ring-2 ring-cyan-200' 
                        : 'border-slate-200 hover:border-slate-300 bg-white'"
                >
                    <div class="flex items-start gap-4">
                        <div class="w-12 h-12 rounded-xl flex items-center justify-center flex-shrink-0" 
                             :class="formData.billing_type === 'digital' ? 'bg-cyan-100' : 'bg-slate-100'">
                            <i class="pi pi-qrcode text-xl" :class="formData.billing_type === 'digital' ? 'text-cyan-600' : 'text-slate-500'"></i>
                        </div>
                        <div class="flex-1">
                            <div class="flex items-center gap-2 mb-1">
                                <span class="font-bold text-base" :class="formData.billing_type === 'digital' ? 'text-cyan-900' : 'text-slate-800'">
                                    {{ $t('dashboard.digital_access') }}
                                </span>
                                <span v-if="formData.billing_type === 'digital'" class="px-2 py-0.5 bg-cyan-200 text-cyan-800 text-xs font-medium rounded-full">
                                    {{ $t('common.selected') }}
                                </span>
                            </div>
                            <p class="text-sm text-slate-600 mb-3">{{ $t('dashboard.digital_access_full_desc') }}</p>
                            <div class="flex flex-wrap gap-2 text-xs">
                                <span class="inline-flex items-center gap-1 px-2 py-1 bg-amber-100 text-amber-700 rounded-full">
                                    <i class="pi pi-bolt"></i> {{ $t('dashboard.pay_per_scan') }}
                                </span>
                                <span class="inline-flex items-center gap-1 px-2 py-1 bg-slate-100 text-slate-600 rounded-full">
                                    <i class="pi pi-eye-slash"></i> {{ $t('dashboard.no_card_image') }}
                                </span>
                            </div>
                        </div>
                    </div>
                </button>
            </div>
            
            <!-- Access Mode Info Banner (only show in create mode) -->
            <div v-if="!isEditMode" class="mt-4 p-4 rounded-lg" :class="formData.billing_type === 'physical' ? 'bg-purple-50 border border-purple-200' : 'bg-cyan-50 border border-cyan-200'">
                <div class="flex items-start gap-3">
                    <i :class="['pi text-lg', formData.billing_type === 'physical' ? 'pi-credit-card text-purple-600' : 'pi-qrcode text-cyan-600']"></i>
                    <div>
                        <p class="text-sm font-semibold" :class="formData.billing_type === 'physical' ? 'text-purple-800' : 'text-cyan-800'">
                            {{ formData.billing_type === 'physical' ? $t('dashboard.physical_mode_title') : $t('dashboard.digital_mode_title') }}
                        </p>
                        <p class="text-sm mt-1" :class="formData.billing_type === 'physical' ? 'text-purple-700' : 'text-cyan-700'">
                            {{ formData.billing_type === 'physical' ? $t('dashboard.physical_mode_hint') : $t('dashboard.digital_mode_hint') }}
                        </p>
                    </div>
                </div>
            </div>
            
            <!-- Daily Scan Limit (only for Digital Access) -->
            <div v-if="formData.billing_type === 'digital'" class="mt-4 p-4 rounded-lg bg-white border border-cyan-200">
                <div class="flex items-start gap-3">
                    <div class="w-10 h-10 rounded-lg bg-cyan-100 flex items-center justify-center flex-shrink-0">
                        <i class="pi pi-clock text-cyan-600"></i>
                    </div>
                    <div class="flex-1">
                        <label class="text-sm font-semibold text-slate-800 block mb-2">
                            {{ $t('digital_access.daily_limit') }}
                        </label>
                        <div class="flex items-center gap-3 flex-wrap">
                            <InputNumber 
                                v-model="formData.default_daily_session_limit"
                                :disabled="isDailyLimitUnlimited"
                                :min="1"
                                :max="100000"
                                :step="100"
                                showButtons
                                buttonLayout="horizontal"
                                incrementButtonIcon="pi pi-plus"
                                decrementButtonIcon="pi pi-minus"
                                class="daily-limit-input"
                            />
                            <span class="text-sm text-slate-600">{{ $t('digital_access.scans_per_day') }}</span>
                            <div class="flex items-center gap-2 ml-auto">
                                <ToggleSwitch v-model="isDailyLimitUnlimited" />
                                <span class="text-sm text-slate-600">{{ $t('digital_access.unlimited') }}</span>
                            </div>
                        </div>
                        <p class="text-xs text-slate-500 mt-2">
                            {{ $t('digital_access.set_daily_limit_hint') }}
                        </p>
                    </div>
                </div>
            </div>
        </div>
            
        <div class="grid grid-cols-1 gap-6" :class="{ 'xl:grid-cols-3': formData.billing_type === 'physical' }">
            <!-- Artwork Section - Only for Physical Cards -->
            <div v-if="formData.billing_type === 'physical'" class="xl:col-span-1">
                <div class="bg-white rounded-xl shadow-lg border border-slate-200 p-6">
                    <h3 class="text-lg font-semibold text-slate-900 mb-6 flex items-center gap-2">
                        <i class="pi pi-image text-blue-600"></i>
                        {{ $t('dashboard.card_artwork') }}
                    </h3>
                    
                    <!-- Physical Card Image Upload -->
                    <div class="space-y-6">
                        <!-- Image Preview Section (Only when image exists) -->
                        <div v-if="previewImage">
                            <div
                                class="card-artwork-container border-2 border-solid border-blue-400 bg-blue-50/30 rounded-xl transition-all duration-200"
                            >
                                <!-- Image with QR Overlay Container -->
                                <div class="relative w-full h-full">
                                    <img
                                        :src="previewImage"
                                        alt="Card Artwork Preview"
                                        class="object-contain h-full w-full rounded-lg shadow-md" 
                                    />
                                    
                                    <!-- Mock QR Code Overlay -->
                                    <div 
                                        v-if="formData.qr_code_position"
                                        class="absolute w-12 h-12 bg-white border-2 border-slate-300 rounded-lg shadow-lg flex items-center justify-center transition-all duration-300"
                                        :class="getQrCodePositionClass(formData.qr_code_position)"
                                    >
                                        <div class="w-8 h-8 bg-slate-800 rounded-sm flex items-center justify-center">
                                            <i class="pi pi-qrcode text-white text-xs"></i>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                        
                        <!-- Upload/Actions Section -->
                        <div class="space-y-4">
                            <!-- Image Requirements Info -->
                            <div v-if="!previewImage" class="p-3 bg-blue-100 rounded-lg">
                                <p class="text-xs text-blue-800 flex items-start gap-2">
                                    <i class="pi pi-info-circle mt-0.5 flex-shrink-0"></i>
                                    <span><strong>{{ $t('dashboard.image_requirements') }}</strong> {{ $t('dashboard.image_requirements_text') }}</span>
                                </p>
                            </div>
                            
                            <!-- Upload Interface or Action Buttons -->
                            <div>
                                <!-- Upload Drop Zone (LinkedIn Style) - Only when no image -->
                                <div 
                                    v-if="!previewImage"
                                    class="upload-drop-zone"
                                    @dragover.prevent="handleDragOver"
                                    @dragleave.prevent="handleDragLeave"
                                    @drop.prevent="handleDrop"
                                    :class="{ 'drag-active': isDragActive }"
                                >
                                    <div class="upload-content">
                                        <div class="upload-icon-container">
                                            <i class="pi pi-camera upload-icon"></i>
                                        </div>
                                        <h4 class="upload-title">{{ $t('dashboard.add_photo') }}</h4>
                                        <p class="upload-subtitle">{{ $t('dashboard.drag_drop_upload') }}</p>
                                        
                                        <!-- Hidden File Input -->
                                        <input 
                                            ref="fileInputRef"
                                            type="file" 
                                            accept="image/*"
                                            @change="handleFileSelect"
                                            class="hidden"
                                        />
                                        
                                        <Button 
                                            :label="$t('dashboard.upload_photo')"
                                            icon="pi pi-upload"
                                            @click="triggerFileInput"
                                            class="upload-trigger-button"
                                            severity="info"
                                        />
                                    </div>
                                </div>
                                
                                <!-- Action Buttons - Only when image exists -->
                                <div v-else class="image-actions-only">
                                <div class="image-actions">
                                    <Button 
                                        :label="$t('dashboard.change_photo')"
                                        icon="pi pi-image"
                                        @click="triggerFileInput"
                                        severity="secondary"
                                        outlined
                                        size="small"
                                        class="action-button"
                                    />
                                    <Button 
                                        :label="$t('dashboard.crop_image')"
                                        icon="pi pi-expand"
                                        @click="handleCropImage"
                                        severity="info"
                                        outlined
                                        size="small"
                                        class="action-button"
                                    />
                                    <Button 
                                        v-if="isCropped"
                                        :label="$t('dashboard.undo_crop')"
                                        icon="pi pi-undo"
                                        @click="handleUndoCrop"
                                        severity="warning"
                                        outlined
                                        size="small"
                                        class="action-button"
                                    />
                                    </div>
                                    
                                    <!-- Hidden File Input for Change Photo -->
                                    <input 
                                        ref="fileInputRef"
                                        type="file" 
                                        accept="image/*"
                                        @change="handleFileSelect"
                                        class="hidden"
                                    />
                                </div>
                            </div>
                            
                            <!-- QR Code Position -->
                            <div class="p-4 bg-slate-50 border border-slate-200 rounded-lg">
                                <h4 class="font-medium text-slate-900 mb-3 flex items-center gap-2">
                                    <i class="pi pi-qrcode text-slate-600"></i>
                                    {{ $t('dashboard.qr_code_settings') }}
                                </h4>
                                <div>
                                    <label for="qr_code_position" class="block text-sm font-medium text-slate-700 mb-2">{{ $t('dashboard.position_on_card') }}</label>
                                    <Dropdown 
                                        id="qr_code_position"
                                        v-model="formData.qr_code_position" 
                                        :options="qrCodePositions" 
                                        optionLabel="name" 
                                        optionValue="code" 
                                        :placeholder="$t('dashboard.select_position')" 
                                        class="w-full"
                                    />
                                    <p class="text-xs text-slate-500 mt-2">
                                        {{ $t('dashboard.preview_updates_realtime') }}
                                    </p>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
            
            <!-- Digital Access - No Artwork Section, show info instead -->
            <div v-else class="col-span-full mb-0">
                <!-- This space intentionally left empty - digital access doesn't need artwork -->
            </div>
            
            <!-- Form Fields Section -->
            <div :class="formData.billing_type === 'physical' ? 'xl:col-span-2' : 'col-span-full'">
                <div class="bg-white rounded-xl shadow-lg border border-slate-200 p-6 space-y-6">
                    <div>
                        <h3 class="text-lg font-semibold text-slate-900 mb-4 flex items-center gap-2">
                            <i class="pi pi-cog text-blue-600"></i>
                            {{ formData.billing_type === 'digital' ? $t('dashboard.qr_content_settings') : $t('dashboard.card_details') }}
                        </h3>
                        
                        <div class="space-y-4">
                            <!-- Content Mode Selector -->
                            <div>
                                <label class="block text-sm font-medium text-slate-700 mb-2">
                                    {{ $t('dashboard.content_mode') }}
                                    <i class="pi pi-info-circle text-slate-400 text-xs ml-1 cursor-help" 
                                       v-tooltip.right="{
                                           value: $t('dashboard.content_mode_tooltip'),
                                           class: 'max-w-sm'
                                       }"></i>
                                </label>
                                <!-- Filter content modes based on access mode -->
                                <div class="grid grid-cols-2 gap-2" :class="{ 'md:grid-cols-4': formData.billing_type === 'digital' }">
                                    <button
                                        v-for="mode in filteredContentModeOptions"
                                        :key="mode.value"
                                        type="button"
                                        @click="formData.content_mode = mode.value"
                                        class="p-3 rounded-lg border-2 transition-all text-left"
                                        :class="formData.content_mode === mode.value 
                                            ? 'border-blue-500 bg-blue-50' 
                                            : 'border-slate-200 hover:border-slate-300 bg-white'"
                                    >
                                        <div class="flex items-center gap-2 mb-1">
                                            <i :class="['pi', mode.icon, formData.content_mode === mode.value ? 'text-blue-600' : 'text-slate-500']"></i>
                                            <span class="font-medium text-sm" :class="formData.content_mode === mode.value ? 'text-blue-900' : 'text-slate-700'">{{ mode.label }}</span>
                                        </div>
                                        <p class="text-xs text-slate-500 line-clamp-2">{{ mode.description }}</p>
                                    </button>
                                </div>
                                <!-- Mode Requirements Checklist - Only for physical cards -->
                                <div v-if="formData.billing_type === 'physical'" class="mt-3 p-3 rounded-lg" :class="modeRequirementsClass">
                                    <div class="flex items-start gap-2 mb-2">
                                        <i :class="['pi', currentModeDetails.icon, modeRequirementsMet ? 'text-green-600' : 'text-amber-600', 'mt-0.5']"></i>
                                        <div class="flex-1">
                                            <p class="text-sm font-medium" :class="modeRequirementsMet ? 'text-green-800' : 'text-amber-800'">
                                                {{ currentModeDetails.label }}
                                            </p>
                                            <p class="text-xs mt-1" :class="modeRequirementsMet ? 'text-green-700' : 'text-amber-700'">
                                                {{ currentModeDetails.guidance }}
                                            </p>
                                        </div>
                                    </div>
                                    <!-- Requirements List -->
                                    <div class="mt-2 pt-2 border-t" :class="modeRequirementsMet ? 'border-green-200' : 'border-amber-200'">
                                        <p class="text-xs font-medium mb-1" :class="modeRequirementsMet ? 'text-green-700' : 'text-amber-700'">
                                            {{ $t('dashboard.mode_requirements') }}:
                                        </p>
                                        <ul class="space-y-1">
                                            <li v-for="req in currentModeRequirements" :key="req.key" 
                                                class="flex items-center gap-1.5 text-xs"
                                                :class="req.met ? 'text-green-600' : 'text-amber-600'">
                                                <i :class="req.met ? 'pi pi-check-circle' : 'pi pi-circle'" class="text-xs"></i>
                                                {{ req.label }}
                                            </li>
                                        </ul>
                                    </div>
                                </div>
                                <!-- Digital Mode Guidance - Simpler for digital -->
                                <div v-else class="mt-3 p-3 rounded-lg bg-cyan-50 border border-cyan-200">
                                    <div class="flex items-start gap-2">
                                        <i :class="['pi', currentModeDetails.icon, 'text-cyan-600 mt-0.5']"></i>
                                        <div class="flex-1">
                                            <p class="text-sm font-medium text-cyan-800">{{ currentModeDetails.label }}</p>
                                            <p class="text-xs mt-1 text-cyan-700">{{ currentModeDetails.guidance }}</p>
                                        </div>
                                    </div>
                                </div>
                            </div>
                            
                            <!-- Grouping Options (only for modes that support it) -->
                            <div v-if="currentModeSupportsGrouping" class="p-4 rounded-lg border border-slate-200 bg-slate-50">
                                <div class="flex items-center justify-between mb-3">
                                    <div class="flex items-center gap-2">
                                        <i class="pi pi-folder text-amber-600"></i>
                                        <span class="text-sm font-medium text-slate-700">{{ $t('dashboard.grouping_title') }}</span>
                                    </div>
                                    <ToggleSwitch v-model="formData.is_grouped" />
                                </div>
                                <p class="text-xs text-slate-500 mb-3">{{ $t('dashboard.grouping_description') }}</p>
                                
                                <!-- Group Display Options (only shown when grouped is enabled) -->
                                <div v-if="formData.is_grouped" class="mt-4 pt-4 border-t border-slate-200">
                                    <label class="block text-sm font-medium text-slate-700 mb-2">
                                        {{ $t('dashboard.group_display_title') }}
                                    </label>
                                    <div class="grid grid-cols-2 gap-2">
                                        <button
                                            type="button"
                                            @click="formData.group_display = 'expanded'"
                                            class="p-3 rounded-lg border-2 transition-all text-left"
                                            :class="formData.group_display === 'expanded' 
                                                ? 'border-amber-500 bg-amber-50' 
                                                : 'border-slate-200 hover:border-slate-300 bg-white'"
                                        >
                                            <div class="flex items-center gap-2 mb-1">
                                                <i :class="['pi pi-list', formData.group_display === 'expanded' ? 'text-amber-600' : 'text-slate-500']"></i>
                                                <span class="font-medium text-sm" :class="formData.group_display === 'expanded' ? 'text-amber-900' : 'text-slate-700'">
                                                    {{ $t('dashboard.group_display_expanded') }}
                                                </span>
                                            </div>
                                            <p class="text-xs text-slate-500">{{ $t('dashboard.group_display_expanded_desc') }}</p>
                                        </button>
                                        <button
                                            type="button"
                                            @click="formData.group_display = 'collapsed'"
                                            class="p-3 rounded-lg border-2 transition-all text-left"
                                            :class="formData.group_display === 'collapsed' 
                                                ? 'border-amber-500 bg-amber-50' 
                                                : 'border-slate-200 hover:border-slate-300 bg-white'"
                                        >
                                            <div class="flex items-center gap-2 mb-1">
                                                <i :class="['pi pi-folder', formData.group_display === 'collapsed' ? 'text-amber-600' : 'text-slate-500']"></i>
                                                <span class="font-medium text-sm" :class="formData.group_display === 'collapsed' ? 'text-amber-900' : 'text-slate-700'">
                                                    {{ $t('dashboard.group_display_collapsed') }}
                                                </span>
                                            </div>
                                            <p class="text-xs text-slate-500">{{ $t('dashboard.group_display_collapsed_desc') }}</p>
                                        </button>
                                    </div>
                                </div>
                            </div>

                            <!-- Card/QR Name -->
                            <div>
                                <label for="cardName" class="block text-sm font-medium text-slate-700 mb-2">
                                    {{ formData.billing_type === 'digital' ? $t('dashboard.qr_name') : $t('dashboard.card_name') }} *
                                </label>
                                <InputText 
                                    id="cardName" 
                                    type="text" 
                                    v-model="formData.name" 
                                    class="w-full px-4 py-3 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-colors"
                                    :class="{ 'border-red-300 focus:ring-red-500 focus:border-red-500': !formData.name.trim() && showValidation }"
                                    :placeholder="formData.billing_type === 'digital' ? $t('dashboard.enter_qr_name') : $t('dashboard.enter_card_name')"
                                />
                                <p v-if="!formData.name.trim() && showValidation" class="text-sm text-red-600 mt-1">{{ $t('dashboard.card_name_required') }}</p>
                            </div>

                            <!-- Card Description - Available for all modes -->
                            <div>
                                <label for="cardDescription" class="block text-sm font-medium text-slate-700 mb-2">
                                    {{ formData.billing_type === 'digital' ? $t('dashboard.welcome_description') : $t('dashboard.card_description') }} 
                                    <span class="text-xs text-slate-500 font-normal">({{ $t('dashboard.markdown_supported') }})</span>
                                </label>
                                <p v-if="formData.billing_type === 'digital'" class="text-xs text-cyan-600 mb-2">
                                    {{ $t('dashboard.digital_description_hint') }}
                                </p>
                                <div class="border border-slate-300 rounded-lg overflow-hidden">
                                    <MdEditor 
                                        v-model="formData.description"
                                        :toolbars="markdownToolbars"
                                        :preview="true"
                                        :htmlPreview="true"
                                        :codeTheme="'atom'"
                                        :previewTheme="'default'"
                                        :onHtmlChanged="handleMarkdownHtmlChanged"
                                        :placeholder="getDescriptionPlaceholder()"
                                        :style="{ height: '200px' }"
                                    />
                                </div>
                            </div>

                            <!-- Original Language Selector -->
                            <div>
                                <label for="originalLanguage" class="block text-sm font-medium text-slate-700 mb-2">
                                    {{ $t('dashboard.originalLanguage') }} *
                                    <i class="pi pi-info-circle text-slate-400 text-xs ml-1 cursor-help" 
                                       v-tooltip.right="{
                                           value: $t('dashboard.originalLanguageTooltip'),
                                           class: 'max-w-sm'
                                       }"></i>
                                </label>
                                <Dropdown
                                    id="originalLanguage"
                                    v-model="formData.original_language"
                                    :options="languageOptions"
                                    optionLabel="label"
                                    optionValue="value"
                                    :placeholder="$t('dashboard.selectLanguage')"
                                    class="w-full"
                                >
                                    <template #value="slotProps">
                                        <div v-if="slotProps.value" class="flex items-center gap-2">
                                            <span>{{ getLanguageFlag(slotProps.value) }}</span>
                                            <span>{{ SUPPORTED_LANGUAGES[slotProps.value] }}</span>
                                        </div>
                                        <span v-else>{{ slotProps.placeholder }}</span>
                                    </template>
                                    <template #option="slotProps">
                                        <div class="flex items-center gap-2">
                                            <span>{{ slotProps.option.flag }}</span>
                                            <span>{{ slotProps.option.label }}</span>
                                        </div>
                                    </template>
                                </Dropdown>
                            </div>

                        </div>
                    </div>
                    
                    <!-- AI Configuration Section -->
                    <div class="p-4 border border-slate-200 rounded-lg">
                        <h4 class="font-medium text-slate-900 mb-3 flex items-center gap-2">
                            <i class="pi pi-brain text-blue-600"></i>
                            {{ $t('dashboard.ai_assistant_configuration') }}
                        </h4>
                        
                        <!-- AI Toggle -->
                        <div class="p-4 rounded-lg border mb-4 transition-all duration-300"
                             :class="formData.conversation_ai_enabled 
                               ? 'bg-gradient-to-r from-blue-50 to-indigo-50 border-blue-300' 
                               : 'bg-slate-50 border-slate-200'">
                            <div class="flex items-center gap-3">
                                <ToggleSwitch v-model="formData.conversation_ai_enabled" inputId="ai_enabled" />
                                <div class="flex-1">
                                    <label for="ai_enabled" class="block text-sm font-medium" 
                                           :class="formData.conversation_ai_enabled ? 'text-blue-900' : 'text-slate-700'">
                                        {{ $t('dashboard.enable_ai_assistant') }}
                                    </label>
                                    <p class="text-xs" :class="formData.conversation_ai_enabled ? 'text-blue-600' : 'text-slate-500'">
                                        {{ $t('dashboard.allow_visitors_ask') }}
                                    </p>
                                </div>
                                <i class="pi pi-info-circle cursor-help" 
                                   :class="formData.conversation_ai_enabled ? 'text-blue-400' : 'text-slate-400'"
                                   v-tooltip="$t('dashboard.ai_assistant_tooltip')"></i>
                            </div>
                            
                            <!-- AI Enabled Cost Notice -->
                            <div v-if="formData.conversation_ai_enabled" 
                                 class="mt-3 p-3 bg-amber-50 border border-amber-200 rounded-lg flex items-start gap-2">
                                <i class="pi pi-bolt text-amber-500 mt-0.5 flex-shrink-0"></i>
                                <div class="text-xs text-amber-800">
                                    <strong>{{ $t('dashboard.ai_cost_notice_title') }}</strong>
                                    <p class="mt-1">{{ $t('dashboard.ai_cost_notice_message', pricingVars) }}</p>
                                </div>
                            </div>
                        </div>
                        
                        <!-- AI Disabled Notice (shows saved data info) -->
                        <div v-if="!formData.conversation_ai_enabled && hasAiData" 
                             class="mb-4 p-3 bg-slate-100 border border-slate-200 rounded-lg flex items-start gap-2">
                            <i class="pi pi-info-circle text-slate-500 mt-0.5 flex-shrink-0"></i>
                            <div class="text-xs text-slate-600">
                                <strong>{{ $t('dashboard.ai_data_preserved_title') }}</strong>
                                <p class="mt-1">{{ $t('dashboard.ai_data_preserved_message') }}</p>
                            </div>
                        </div>

                        <!-- AI Instruction Field (shown when AI is enabled) -->
                        <div v-if="formData.conversation_ai_enabled" class="space-y-4">
                            <!-- AI Instruction (Role & Guidelines) -->
                            <div class="bg-gradient-to-r from-blue-50 to-indigo-50 border border-blue-200 rounded-lg p-4">
                                <label class="block text-sm font-medium text-blue-900 mb-2 flex items-center gap-2">
                                    <i class="pi pi-user"></i>
                                    {{ $t('dashboard.ai_instruction_role_guidelines') }}
                                    <span class="text-xs text-blue-600 ml-auto">{{ aiInstructionWordCount }}/100 {{ $t('dashboard.words') }}</span>
                                </label>
                                <Textarea 
                                    v-model="formData.ai_instruction" 
                                    rows="3" 
                                    class="w-full px-4 py-3 border border-blue-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-colors resize-none bg-white" 
                                    :class="{ 'border-red-500': aiInstructionWordCount > 100 }"
                                    :placeholder="$t('dashboard.enter_ai_role_guidelines')"
                                    autoResize
                                />
                                <div class="mt-3 p-3 bg-blue-50 border border-blue-200 rounded-lg">
                                    <div class="text-xs text-blue-800 flex items-start gap-2">
                                        <i class="pi pi-info-circle mt-0.5 flex-shrink-0"></i>
                                        <div class="space-y-2">
                                            <p>{{ $t('dashboard.purpose_define_ai') }}</p>
                                            <p class="text-blue-700">
                                                <strong>{{ $t('dashboard.example') }}:</strong> <em>"{{ DEFAULT_AI_INSTRUCTION }}"</em>
                                            </p>
                                        </div>
                                    </div>
                                </div>
                            </div>

                            <!-- AI Knowledge Base -->
                            <div class="bg-gradient-to-r from-blue-50 to-indigo-50 border border-blue-200 rounded-lg p-4">
                                <label class="block text-sm font-medium text-blue-900 mb-2 flex items-center gap-2">
                                    <i class="pi pi-database"></i>
                                    {{ $t('dashboard.ai_knowledge_base_label') }}
                                    <span class="text-xs text-blue-600 ml-auto">{{ aiKnowledgeBaseWordCount }}/2000 {{ $t('dashboard.words') }}</span>
                                </label>
                                <Textarea 
                                    v-model="formData.ai_knowledge_base" 
                                    rows="6" 
                                    class="w-full px-4 py-3 border border-blue-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-colors resize-none bg-white" 
                                    :class="{ 'border-red-500': aiKnowledgeBaseWordCount > 2000 }"
                                    :placeholder="$t('dashboard.knowledge_base_placeholder')"
                                    autoResize
                                />
                                <div class="mt-3 p-3 bg-blue-50 border border-blue-200 rounded-lg">
                                    <div class="text-xs text-blue-800 flex items-start gap-2">
                                        <i class="pi pi-info-circle mt-0.5 flex-shrink-0"></i>
                                        <span>{{ $t('dashboard.knowledge_purpose') }}</span>
                                    </div>
                                </div>
                            </div>

                            <!-- AI Welcome Messages Section -->
                            <div class="border-t border-blue-200 pt-4 mt-4">
                                <h5 class="text-sm font-medium text-blue-900 mb-3 flex items-center gap-2">
                                    <i class="pi pi-comment"></i>
                                    {{ $t('dashboard.ai_welcome_messages') }}
                                </h5>
                                
                                <!-- General Assistant Welcome -->
                                <div class="bg-white border border-blue-200 rounded-lg p-4 mb-3">
                                    <label class="block text-sm font-medium text-slate-700 mb-2 flex items-center gap-2">
                                        <i class="pi pi-comments text-blue-500"></i>
                                        {{ $t('dashboard.ai_welcome_general_label') }}
                                        <span class="text-xs text-slate-500 ml-auto">{{ aiWelcomeGeneralWordCount }}/100 {{ $t('dashboard.words') }}</span>
                                    </label>
                                    <Textarea 
                                        v-model="formData.ai_welcome_general" 
                                        rows="2" 
                                        class="w-full px-3 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-colors resize-none text-sm" 
                                        :class="{ 'border-red-500': aiWelcomeGeneralWordCount > 100 }"
                                        :placeholder="$t('dashboard.ai_welcome_general_placeholder')"
                                        autoResize
                                    />
                                    <p class="text-xs text-slate-500 mt-1">{{ $t('dashboard.ai_welcome_general_hint') }}</p>
                                </div>
                                
                                <!-- Item Assistant Welcome -->
                                <div class="bg-white border border-blue-200 rounded-lg p-4">
                                    <label class="block text-sm font-medium text-slate-700 mb-2 flex items-center gap-2">
                                        <i class="pi pi-info-circle text-emerald-500"></i>
                                        {{ $t('dashboard.ai_welcome_item_label') }}
                                        <span class="text-xs text-slate-500 ml-auto">{{ aiWelcomeItemWordCount }}/100 {{ $t('dashboard.words') }}</span>
                                    </label>
                                    <Textarea 
                                        v-model="formData.ai_welcome_item" 
                                        rows="2" 
                                        class="w-full px-3 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-colors resize-none text-sm" 
                                        :class="{ 'border-red-500': aiWelcomeItemWordCount > 100 }"
                                        :placeholder="$t('dashboard.ai_welcome_item_placeholder')"
                                        autoResize
                                    />
                                    <p class="text-xs text-slate-500 mt-1">{{ $t('dashboard.ai_welcome_item_hint') }}</p>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <!-- Image Crop Dialog -->
        <MyDialog
            v-model="showCropDialog"
            :header="$t('dashboard.crop_image_dialog')"
            :style="{ width: '90vw', maxWidth: '900px' }"
            :closable="false"
            :showConfirm="true"
            :showCancel="true"
            :confirmLabel="$t('dashboard.apply')"
            :cancelLabel="$t('common.cancel')"
            :confirmHandle="handleCropConfirm"
            @cancel="handleCropCancelled"
        >
            <ImageCropper
                v-if="imageToCrop"
                :imageSrc="imageToCrop"
                :aspectRatio="getCardAspectRatioNumber()"
                :aspectRatioDisplay="getCardAspectRatioDisplay()"
                :cropParameters="cropParameters"
                ref="imageCropperRef"
            />
        </MyDialog>
    </div>
</template>

<script setup>
import { ref, reactive, onMounted, watch, computed, nextTick } from 'vue';
import { useI18n } from 'vue-i18n';
import { SubscriptionConfig } from '@/config/subscription';
import Button from 'primevue/button';
import InputText from 'primevue/inputtext';
import InputNumber from 'primevue/inputnumber';
import Textarea from 'primevue/textarea';
import Dropdown from 'primevue/dropdown';
import ToggleSwitch from 'primevue/toggleswitch';
import { processImage } from '@/utils/imageUtils.js';
import { 
    getCardAspectRatio, 
    getCardAspectRatioNumber, 
    getCardAspectRatioDisplay, 
    imageNeedsCropping, 
    getImageDimensions 
} from '@/utils/cardConfig';
import { generateCropPreview } from '@/utils/cropUtils';
import ImageCropper from '@/components/ImageCropper.vue';
import MyDialog from '@/components/MyDialog.vue';
import { MdEditor } from 'md-editor-v3';
import 'md-editor-v3/lib/style.css';
import { SUPPORTED_LANGUAGES } from '@/stores/translation';

const props = defineProps({
    cardProp: {
        type: Object,
        default: null
    },
    isEditMode: {
        type: Boolean,
        default: false
    },
    isInDialog: {
        type: Boolean,
        default: false
    },
    loading: {
        type: Boolean,
        default: false
    }
});

const emit = defineEmits(['save', 'cancel']);

// i18n
const { t } = useI18n();

// Session costs from config (environment variables)
const pricingVars = {
    aiCost: SubscriptionConfig.premium.aiEnabledSessionCostUsd,
    nonAiCost: SubscriptionConfig.premium.aiDisabledSessionCostUsd
};

// Get default AI instruction from environment
const DEFAULT_AI_INSTRUCTION = import.meta.env.VITE_DEFAULT_AI_INSTRUCTION || "You are a knowledgeable and friendly AI assistant for museum and exhibition visitors. Provide accurate, engaging, and educational explanations about exhibits and artifacts. Keep responses conversational and easy to understand. If you don't know something, politely say so rather than making up information.";

const formData = reactive({
    id: null,
    name: '',
    description: '',
    original_language: 'en', // Default to English
    qr_code_position: 'BR',
    ai_instruction: '',
    ai_knowledge_base: '',
    ai_welcome_general: '', // Custom welcome message for General AI Assistant
    ai_welcome_item: '', // Custom welcome message for Content Item AI Assistant
    conversation_ai_enabled: false,
    cropParameters: null,
    content_mode: 'list', // Default mode: list (vertical rows)
    is_grouped: false, // Whether content is organized into categories
    group_display: 'expanded', // How grouped items display: expanded or collapsed
    billing_type: 'physical', // Default: physical card (per-card billing)
    max_sessions: null, // NULL for physical (unlimited), Integer for digital (total limit)
    default_daily_session_limit: 500 // Default daily limit for new QR codes
});

// Content Mode Options with descriptions and guidance
// 4 base layouts, with grouping as a separate option
const contentModeOptions = computed(() => [
    {
        value: 'single',
        label: t('dashboard.mode_single'),
        icon: 'pi-file',
        description: t('dashboard.mode_single_desc'),
        guidance: t('dashboard.mode_single_guidance'),
        color: 'purple',
        supportsGrouping: false
    },
    {
        value: 'grid',
        label: t('dashboard.mode_grid'),
        icon: 'pi-th-large',
        description: t('dashboard.mode_grid_desc'),
        guidance: t('dashboard.mode_grid_guidance'),
        color: 'amber',
        supportsGrouping: true
    },
    {
        value: 'list',
        label: t('dashboard.mode_list'),
        icon: 'pi-list',
        description: t('dashboard.mode_list_desc'),
        guidance: t('dashboard.mode_list_guidance'),
        color: 'blue',
        supportsGrouping: true
    },
    {
        value: 'cards',
        label: t('dashboard.mode_cards'),
        icon: 'pi-clone',
        description: t('dashboard.mode_cards_desc'),
        guidance: t('dashboard.mode_cards_guidance'),
        color: 'cyan',
        supportsGrouping: true
    }
]);

// Check if current mode supports grouping
const currentModeSupportsGrouping = computed(() => {
    const mode = contentModeOptions.value.find(m => m.value === formData.content_mode);
    return mode?.supportsGrouping ?? false;
});

// Reset grouping when switching to a mode that doesn't support it
watch(() => formData.content_mode, (newMode) => {
    const mode = contentModeOptions.value.find(m => m.value === newMode);
    if (!mode?.supportsGrouping) {
        formData.is_grouped = false;
        formData.group_display = 'expanded';
    }
});

// No migration needed when switching is_grouped - just a display change
// Layer 1 = categories (shown in grouped mode, hidden in flat mode)
// Layer 2 = content items (always the actual content)

// Get current mode details
const currentModeDetails = computed(() => {
    return contentModeOptions.value.find(m => m.value === formData.content_mode) || contentModeOptions.value[2]; // Default to 'list'
});

// Filter content modes based on access mode
// All modes available for both access types
const filteredContentModeOptions = computed(() => {
    // All modes available for both access types
    // Reorder to show most relevant first for digital
    if (formData.billing_type === 'digital') {
        // For digital: List is most common, then Single, Grid, Cards
        const order = ['list', 'single', 'grid', 'cards'];
        return [...contentModeOptions.value].sort((a, b) => 
            order.indexOf(a.value) - order.indexOf(b.value)
        );
    }
    return contentModeOptions.value;
});

// Mode requirements validation
const currentModeRequirements = computed(() => {
    // If grouped mode, show grouped requirements
    if (formData.is_grouped) {
        return [
            { key: 'parents', label: t('dashboard.req_parent_items_categories'), met: true },
            { key: 'children', label: t('dashboard.req_child_items'), met: true }
        ];
    }
    
    switch (formData.content_mode) {
        case 'single':
            return [
                { key: 'one_item', label: t('dashboard.req_one_content_item'), met: true } // Validated in Content tab
            ];
        case 'list':
            return [
                { key: 'items', label: t('dashboard.req_content_items'), met: true } // Validated in Content tab
            ];
        case 'grid':
            return [
                { key: 'items', label: t('dashboard.req_content_items_with_images'), met: true } // Validated in Content tab
            ];
        case 'cards':
            return [
                { key: 'items', label: t('dashboard.req_content_items'), met: true } // Validated in Content tab
            ];
        default:
            return [];
    }
});

// Check if all mode requirements are met
const modeRequirementsMet = computed(() => {
    return currentModeRequirements.value.every(req => req.met);
});

// Dynamic class for requirements box
const modeRequirementsClass = computed(() => {
    return modeRequirementsMet.value 
        ? 'bg-gradient-to-r from-green-50 to-emerald-50 border border-green-200'
        : 'bg-gradient-to-r from-amber-50 to-yellow-50 border border-amber-200';
});

// Language options for dropdown
const languageOptions = computed(() => {
    return Object.entries(SUPPORTED_LANGUAGES).map(([code, name]) => ({
        value: code,
        label: name,
        flag: getLanguageFlag(code)
    }));
});

// Helper function to get language flag
const getLanguageFlag = (langCode) => {
    const flagMap = {
        en: '🇬🇧',
        'zh-Hant': '🇹🇼',
        'zh-Hans': '🇨🇳',
        ja: '🇯🇵',
        ko: '🇰🇷',
        es: '🇪🇸',
        fr: '🇫🇷',
        ru: '🇷🇺',
        ar: '🇸🇦',
        th: '🇹🇭',
    };
    return flagMap[langCode] || '🌐';
};

// Word count computed properties
const aiInstructionWordCount = computed(() => {
    return formData.ai_instruction.trim().split(/\s+/).filter(word => word.length > 0).length;
});

const aiKnowledgeBaseWordCount = computed(() => {
    return formData.ai_knowledge_base.trim().split(/\s+/).filter(word => word.length > 0).length;
});

const aiWelcomeGeneralWordCount = computed(() => {
    return formData.ai_welcome_general.trim().split(/\s+/).filter(word => word.length > 0).length;
});

const aiWelcomeItemWordCount = computed(() => {
    return formData.ai_welcome_item.trim().split(/\s+/).filter(word => word.length > 0).length;
});

const previewImage = ref(null);
const imageFile = ref(null); // Original uploaded file (raw)
const croppedImageFile = ref(null); // Cropped image file
const showCropDialog = ref(false);
const imageToCrop = ref(null);
const imageCropperRef = ref(null);
const cropParameters = ref(null);

// Daily limit unlimited toggle for digital access
const isDailyLimitUnlimited = ref(false);

// LinkedIn-style upload variables
const isDragActive = ref(false);
const fileInputRef = ref(null);

// Check if image is cropped
const isCropped = computed(() => {
    return croppedImageFile.value !== null || cropParameters.value !== null || formData.cropParameters !== null;
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
    // Post-process the HTML to add target="_blank" and rel="noopener noreferrer" to links
    return html.replace(/<a href=/g, '<a target="_blank" rel="noopener noreferrer" href=');
};

// Dynamic placeholder based on content mode
const getDescriptionPlaceholder = () => {
    return t('dashboard.placeholder_description');
};

const qrCodePositions = computed(() => [
    { name: t('dashboard.top_left'), code: 'TL' },
    { name: t('dashboard.top_right'), code: 'TR' },
    { name: t('dashboard.bottom_left'), code: 'BL' },
    { name: t('dashboard.bottom_right'), code: 'BR' }
]);

const showValidation = ref(false);

const isFormValid = computed(() => {
    return formData.name.trim().length > 0;
});

// Initialize form data from props
onMounted(() => {
    initializeForm();
    
    // Set up CSS custom property for aspect ratio
    const aspectRatio = getCardAspectRatio();
    document.documentElement.style.setProperty('--card-aspect-ratio', aspectRatio);
});

// Watch for daily limit unlimited toggle
watch(isDailyLimitUnlimited, (isUnlimited) => {
    if (isUnlimited) {
        formData.default_daily_session_limit = null;
    } else if (formData.default_daily_session_limit === null) {
        // Set default when switching from unlimited
        formData.default_daily_session_limit = 500;
    }
});

// Watch for changes in cardProp to update form
watch(() => props.cardProp, (newVal) => {
    if (newVal) {
        initializeForm();
    }
}, { deep: true });

// Check if there's existing AI data (for showing preserved data notice)
const hasAiData = computed(() => {
    return !!(formData.ai_instruction?.trim() || 
              formData.ai_knowledge_base?.trim() || 
              formData.ai_welcome_general?.trim() || 
              formData.ai_welcome_item?.trim());
});

// Note: AI data is intentionally preserved when AI is disabled
// This allows users to re-enable AI and have their data restored immediately

const initializeForm = () => {
    if (props.cardProp) {
        formData.id = props.cardProp.id;
        formData.name = props.cardProp.name || '';
        formData.description = props.cardProp.description || '';
        formData.original_language = props.cardProp.original_language || 'en';
        formData.qr_code_position = props.cardProp.qr_code_position || 'BR';
        formData.ai_instruction = props.cardProp.ai_instruction || '';
        formData.ai_knowledge_base = props.cardProp.ai_knowledge_base || '';
        formData.ai_welcome_general = props.cardProp.ai_welcome_general || '';
        formData.ai_welcome_item = props.cardProp.ai_welcome_item || '';
        formData.conversation_ai_enabled = props.cardProp.conversation_ai_enabled || false;
        formData.cropParameters = props.cardProp.cropParameters || props.cardProp.crop_parameters || null;
        formData.content_mode = props.cardProp.content_mode || 'list';
        formData.is_grouped = props.cardProp.is_grouped || false;
        formData.group_display = props.cardProp.group_display || 'expanded';
        formData.billing_type = props.cardProp.billing_type || 'physical'; // Access mode
        formData.max_sessions = props.cardProp.max_sessions || null;
        formData.default_daily_session_limit = props.cardProp.default_daily_session_limit ?? 500;
        
        // Set unlimited toggle based on default_daily_session_limit value
        isDailyLimitUnlimited.value = props.cardProp.default_daily_session_limit === null;
        
        // Set crop parameters if they exist
        if (formData.cropParameters) {
            cropParameters.value = formData.cropParameters;
        }
        
        // For edit mode: Simply display the already-cropped image_url
        // The image_url is the final cropped result, no need to re-generate preview
        if (props.cardProp.image_url) {
            previewImage.value = props.cardProp.image_url;
        } else {
            previewImage.value = null;
        }
        
        // Reset imageFile when initializing from existing card
        imageFile.value = null;
    } else {
        resetForm();
    }
};

const resetForm = () => {
    formData.id = null;
    formData.name = '';
    formData.description = '';
    formData.original_language = 'en';
    formData.qr_code_position = 'BR';
    formData.ai_instruction = '';
    formData.ai_knowledge_base = '';
    formData.ai_welcome_general = '';
    formData.ai_welcome_item = '';
    formData.conversation_ai_enabled = false;
    formData.cropParameters = null;
    formData.content_mode = 'list'; // Reset to default mode
    formData.is_grouped = false;
    formData.group_display = 'expanded';
    formData.billing_type = 'physical'; // Reset to default access mode
    formData.max_sessions = null;
    formData.default_daily_session_limit = 500; // Reset to default daily limit
    
    previewImage.value = null;
    imageFile.value = null;
    croppedImageFile.value = null;
    
    // Clean up crop-related variables
    showCropDialog.value = false;
    imageToCrop.value = null;
    cropParameters.value = null;
};

const handleImageUpload = async (event) => {
    const file = event.files[0];
    if (!file) return;

    try {
        // Store the original image file
        imageFile.value = file;
        
        // Always show the image with object-fit: contain (no auto-cropping)
        await processImageDirectly(file);
        
        // Reset crop-related state when a new image is uploaded
        croppedImageFile.value = null;
        cropParameters.value = null;
        formData.cropParameters = null;
    } catch (error) {
        console.error("Failed to process image:", error);
    }
};

const processImageDirectly = async (file) => {
    // Store the file object for later upload
    imageFile.value = file;

    // Create a preview URL
    const reader = new FileReader();
    reader.onload = (e) => {
        previewImage.value = e.target.result;
    };
    reader.readAsDataURL(file);
};

const handleCropConfirm = async () => {
    // Wait for the component to be mounted
    await nextTick();
    
    if (imageCropperRef.value) {
        try {
            // Get both crop parameters AND cropped image
            const cropParams = imageCropperRef.value.getCropParameters();
            const croppedDataURL = imageCropperRef.value.getCroppedImage();
            
            if (cropParams && croppedDataURL) {
                // Store the crop parameters
                cropParameters.value = cropParams;
                formData.cropParameters = cropParams;
                
                // Convert cropped dataURL to File
                const arr = croppedDataURL.split(',');
                const mime = arr[0].match(/:(.*?);/)[1];
                const bstr = atob(arr[1]);
                let n = bstr.length;
                const u8arr = new Uint8Array(n);
                while (n--) {
                    u8arr[n] = bstr.charCodeAt(n);
                }
                croppedImageFile.value = new File([u8arr], 'cropped-image.jpg', { type: mime });
                
                // Use cropped image for preview
                previewImage.value = croppedDataURL;
                
                console.log('Crop applied - parameters and cropped file saved');
            } else {
                console.error('Failed to get crop parameters or cropped image');
            }
        } catch (error) {
            console.error('Error generating crop:', error);
        }
    } else {
        console.error('ImageCropper ref not available');
    }
    
    // Close crop dialog
    showCropDialog.value = false;
    
    // Clean up
    imageToCrop.value = null;
};

const handleCropCancelled = () => {
    // Close crop dialog and clean up
    showCropDialog.value = false;
    imageToCrop.value = null;
    imageFile.value = null;
    croppedImageFile.value = null;
};

// Open crop dialog for existing image
const handleCropImage = () => {
    // Priority: imageFile (new upload) > original_image_url (saved) > image_url (fallback for old data)
    const originalImage = imageFile.value || props.cardProp?.original_image_url || props.cardProp?.image_url;
    
    if (originalImage) {
        // Use the original image file or URL
        const imageSrc = imageFile.value ? URL.createObjectURL(imageFile.value) : originalImage;
        imageToCrop.value = imageSrc;
        
        // Set existing crop parameters to restore previous crop state (if any)
        if (formData.cropParameters || props.cardProp?.crop_parameters) {
            cropParameters.value = formData.cropParameters || props.cardProp.crop_parameters;
        } else {
            cropParameters.value = null; // Start with fresh crop
        }
        
        showCropDialog.value = true;
    } else {
        console.warn('No image available for cropping');
    }
};

// Undo crop and revert to object-fit: contain
const handleUndoCrop = () => {
    // Clear all crop-related data
    croppedImageFile.value = null;
    cropParameters.value = null;
    formData.cropParameters = null;
    
    // Revert preview to original image with object-fit: contain
    if (imageFile.value) {
        // Use the original uploaded file
        const reader = new FileReader();
        reader.onload = (e) => {
            previewImage.value = e.target.result;
        };
        reader.readAsDataURL(imageFile.value);
    } else if (props.cardProp?.original_image_url) {
        // Use the saved original image URL
        previewImage.value = props.cardProp.original_image_url;
    } else if (props.cardProp?.image_url) {
        // Fallback to image_url if no original is available
        previewImage.value = props.cardProp.image_url;
    }
    
    console.log('Crop undone - reverted to object-fit: contain');
};

// LinkedIn-style upload functions
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

// Process image file (show with object-fit: contain by default)
const processImageFile = (file) => {
    // Validate file size (5MB)
    if (file.size > 5000000) {
        // You might want to add a toast notification here
        console.error('File size exceeds 5MB limit');
        return;
    }
    
    // Store the file
    imageFile.value = file;
    
    // Create preview URL and display with object-fit: contain
    const previewUrl = URL.createObjectURL(file);
    previewImage.value = previewUrl;
    
    // Reset crop-related state when a new image is uploaded
    croppedImageFile.value = null;
    cropParameters.value = null;
    formData.cropParameters = null;
};


const getPayload = () => {
    const payload = { ...formData };
    
    // Ensure QR code position is valid
    if (!['TL', 'TR', 'BL', 'BR'].includes(payload.qr_code_position)) {
        payload.qr_code_position = 'BR'; // Default to Bottom Right if invalid
    }
    
    // Add original image file if it exists
    if (imageFile.value) {
        payload.imageFile = imageFile.value;
    }
    
    // Add cropped image file if it exists
    if (croppedImageFile.value) {
        payload.croppedImageFile = croppedImageFile.value;
    }
    
    // Add image URLs from props if available and no new image is being uploaded
    if (!imageFile.value && props.cardProp) {
        if (props.cardProp.image_url) {
            payload.image_url = props.cardProp.image_url;
        }
        if (props.cardProp.original_image_url) {
            payload.original_image_url = props.cardProp.original_image_url;
        }
    }
    
    // Add crop parameters if they exist
    if (cropParameters.value) {
        payload.cropParameters = cropParameters.value;
    }
    
    return payload;
};

const handleSave = () => {
    showValidation.value = true;
    if (isFormValid.value) {
        emit('save', getPayload());
        showValidation.value = false;
    }
};

const handleCancel = () => {
    emit('cancel');
    initializeForm(); // Reset form to original values
};

const getQrCodePositionClass = (position) => {
    switch (position) {
        case 'TL':
            return 'qr-position-tl';
        case 'TR':
            return 'qr-position-tr';
        case 'BL':
            return 'qr-position-bl';
        case 'BR':
            return 'qr-position-br';
        default:
            return 'qr-position-br'; // Default to bottom-right
    }
};

defineExpose({
    resetForm,
    getPayload,
    initializeForm
});
</script>

<style scoped>
/* Responsive container with configurable aspect ratio */
.card-artwork-container {
    aspect-ratio: var(--card-aspect-ratio, 2/3);
    width: 100%;
    max-width: 300px; /* Increased from 240px for better preview */
    margin: 0 auto;
    position: relative;
    transition: all 0.3s ease;
}

/* Component-specific styles */
.card-artwork-container img {
    /* object-fit is set in the template (object-contain) */
    transition: all 0.2s ease-in-out;
}

.card-artwork-container:hover img {
    transform: scale(1.01); /* Reduced from 1.02 for subtler effect */
}

.qr-position-tl { top: 8px; left: 8px; }
.qr-position-tr { top: 8px; right: 8px; }
.qr-position-bl { bottom: 8px; left: 8px; }
.qr-position-br { bottom: 8px; right: 8px; }

/* LinkedIn-Style Upload Drop Zone */
.upload-drop-zone {
    border: 2px dashed #cbd5e1;
    border-radius: 12px;
    padding: 40px 20px;
    text-align: center;
    background: #fefefe;
    transition: all 0.3s ease;
    cursor: pointer;
    position: relative;
    overflow: hidden;
}

.upload-drop-zone:hover {
    border-color: #3b82f6;
    background: #f8faff;
    transform: translateY(-2px);
    box-shadow: 0 8px 25px rgba(59, 130, 246, 0.15);
}

.upload-drop-zone.drag-active {
    border-color: #2563eb;
    background: #eff6ff;
    transform: scale(1.02);
    box-shadow: 0 12px 30px rgba(59, 130, 246, 0.25);
}

.upload-content {
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 16px;
}

.upload-icon-container {
    width: 64px;
    height: 64px;
    background: linear-gradient(135deg, #e0f2fe 0%, #b3e5fc 100%);
    border-radius: 50%;
    display: flex;
    align-items: center;
    justify-content: center;
    margin-bottom: 8px;
}

.upload-icon {
    font-size: 28px;
    color: #0277bd;
}

.upload-title {
    font-size: 18px;
    font-weight: 600;
    color: #1e293b;
    margin: 0;
}

.upload-subtitle {
    font-size: 14px;
    color: #64748b;
    margin: 0;
}

.upload-trigger-button {
    margin-top: 8px;
    padding: 10px 20px;
    font-weight: 500;
}

/* Action Buttons Container (when image exists) */
.image-actions-only {
    display: flex;
    flex-direction: column;
    gap: 12px;
}

/* LinkedIn-Style Action Buttons */
.image-actions {
    display: flex;
    gap: 8px;
    flex-wrap: wrap;
    justify-content: center;
}

.action-button {
    font-weight: 500;
    border-radius: 6px;
    transition: all 0.2s ease;
    min-width: 100px;
}

.action-button:hover {
    transform: translateY(-1px);
    box-shadow: 0 4px 8px rgba(0, 0, 0, 0.1);
}

/* Markdown editor preview link styling - 2 line truncation */
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
