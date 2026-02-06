<template>
    <div class="project-form">
        <!-- Action Buttons - Only show in standalone edit mode -->
        <div class="flex justify-end gap-3 mb-4" v-if="isEditMode && !isInDialog">
            <Button
                :label="$t('common.cancel')"
                icon="pi pi-times"
                severity="secondary"
                outlined
                size="small"
                @click="handleCancel"
            />
            <Button
                :label="$t('dashboard.save_changes')"
                icon="pi pi-save"
                severity="primary"
                size="small"
                :disabled="!isFormValid"
                :loading="loading"
                @click="handleSave"
            />
        </div>

        <!-- Quick Start Guide - Only show in create mode -->
        <div v-if="!isEditMode" class="mb-5 p-3 sm:p-4 bg-gradient-to-r from-blue-50 to-indigo-50 border border-blue-200 rounded-lg">
            <div class="flex items-start gap-3">
                <div class="w-8 h-8 sm:w-10 sm:h-10 rounded-full bg-blue-100 flex items-center justify-center flex-shrink-0">
                    <i class="pi pi-sparkles text-blue-600 text-sm sm:text-base"></i>
                </div>
                <div class="min-w-0">
                    <h4 class="font-semibold text-blue-900 text-sm mb-0.5">{{ $t('dashboard.create_project_intro_title') }}</h4>
                    <p class="text-xs text-blue-700 leading-relaxed">{{ $t('dashboard.create_project_intro_description') }}</p>
                </div>
            </div>
        </div>

        <!-- Section 1: Access Mode -->
        <div class="form-section" :class="{ 'section-locked': isEditMode }">
            <div class="section-header" @click="toggleSection('accessMode')">
                <div class="section-header-left">
                    <div class="section-number" :class="{ 'number-complete': isEditMode }">
                        <span v-if="!isEditMode">1</span>
                        <i v-else class="pi pi-lock text-xs"></i>
                    </div>
                    <div class="section-title-group">
                        <h3 class="section-title">{{ $t('dashboard.access_mode') }}</h3>
                        <p class="section-subtitle">
                            <template v-if="isEditMode">
                                {{ formData.billing_type === 'physical' ? $t('dashboard.physical_card') : $t('dashboard.digital_access') }}
                                <span class="text-amber-600 ml-1">{{ $t('dashboard.access_mode_locked') }}</span>
                            </template>
                            <template v-else>{{ $t('dashboard.select_first') }}</template>
                        </p>
                    </div>
                </div>
                <i class="pi section-chevron" :class="expandedSections.accessMode ? 'pi-chevron-up' : 'pi-chevron-down'"></i>
            </div>

            <Transition name="slide">
                <div v-show="expandedSections.accessMode" class="section-content">
                    <!-- Edit Mode: Show locked access mode (compact) -->
                    <div v-if="isEditMode" class="p-3 sm:p-4 rounded-lg border-2 text-left"
                         :class="formData.billing_type === 'physical'
                             ? 'border-purple-400 bg-purple-50/50'
                             : 'border-cyan-400 bg-cyan-50/50'">
                        <div class="flex items-center gap-3">
                            <div class="w-10 h-10 rounded-lg flex items-center justify-center flex-shrink-0"
                                 :class="formData.billing_type === 'physical' ? 'bg-purple-100' : 'bg-cyan-100'">
                                <i :class="['text-lg', formData.billing_type === 'physical' ? 'pi pi-credit-card text-purple-600' : 'pi pi-qrcode text-cyan-600']"></i>
                            </div>
                            <div class="flex-1 min-w-0">
                                <div class="flex items-center gap-2 flex-wrap">
                                    <span class="font-semibold text-sm" :class="formData.billing_type === 'physical' ? 'text-purple-900' : 'text-cyan-900'">
                                        {{ formData.billing_type === 'physical' ? $t('dashboard.physical_card') : $t('dashboard.digital_access') }}
                                    </span>
                                    <span class="px-2 py-0.5 text-xs font-medium rounded-full"
                                          :class="formData.billing_type === 'physical' ? 'bg-purple-200 text-purple-700' : 'bg-cyan-200 text-cyan-700'">
                                        <i class="pi pi-lock text-xs mr-1"></i>{{ $t('dashboard.locked') }}
                                    </span>
                                </div>
                                <p class="text-xs mt-1" :class="formData.billing_type === 'physical' ? 'text-purple-600' : 'text-cyan-600'">
                                    {{ $t('dashboard.access_mode_cannot_change') }}
                                </p>
                            </div>
                        </div>
                    </div>

                    <!-- Create Mode: Allow selection -->
                    <div v-else :class="['grid gap-3', isPhysicalCardsEnabled ? 'grid-cols-1 sm:grid-cols-2' : 'grid-cols-1']">
                        <!-- Physical Card Option -->
                        <button
                            v-if="isPhysicalCardsEnabled"
                            type="button"
                            @click="formData.billing_type = 'physical'"
                            class="access-mode-card"
                            :class="formData.billing_type === 'physical' ? 'access-mode-card--physical--selected' : 'access-mode-card--unselected'"
                        >
                            <div class="flex items-start gap-3">
                                <div class="w-10 h-10 rounded-lg flex items-center justify-center flex-shrink-0 transition-colors"
                                     :class="formData.billing_type === 'physical' ? 'bg-purple-100' : 'bg-slate-100'">
                                    <i class="pi pi-credit-card" :class="formData.billing_type === 'physical' ? 'text-purple-600' : 'text-slate-400'"></i>
                                </div>
                                <div class="flex-1 min-w-0 text-left">
                                    <div class="flex items-center gap-2 flex-wrap">
                                        <span class="font-semibold text-sm" :class="formData.billing_type === 'physical' ? 'text-purple-900' : 'text-slate-700'">
                                            {{ $t('dashboard.physical_card') }}
                                        </span>
                                        <span v-if="formData.billing_type === 'physical'" class="px-1.5 py-0.5 bg-purple-200 text-purple-700 text-xs font-medium rounded">
                                            {{ $t('common.selected') }}
                                        </span>
                                    </div>
                                    <p class="text-xs text-slate-500 mt-1 line-clamp-2">{{ $t('dashboard.physical_card_full_desc') }}</p>
                                    <div class="flex flex-wrap gap-1.5 mt-2">
                                        <span class="inline-flex items-center gap-1 px-1.5 py-0.5 bg-green-100 text-green-700 rounded text-xs">
                                            <i class="pi pi-check text-xs"></i> {{ $t('dashboard.unlimited_scans') }}
                                        </span>
                                    </div>
                                </div>
                            </div>
                        </button>

                        <!-- Digital Access Option -->
                        <button
                            type="button"
                            @click="formData.billing_type = 'digital'"
                            class="access-mode-card"
                            :class="formData.billing_type === 'digital' ? 'access-mode-card--digital--selected' : 'access-mode-card--unselected'"
                        >
                            <div class="flex items-start gap-3">
                                <div class="w-10 h-10 rounded-lg flex items-center justify-center flex-shrink-0 transition-colors"
                                     :class="formData.billing_type === 'digital' ? 'bg-cyan-100' : 'bg-slate-100'">
                                    <i class="pi pi-qrcode" :class="formData.billing_type === 'digital' ? 'text-cyan-600' : 'text-slate-400'"></i>
                                </div>
                                <div class="flex-1 min-w-0 text-left">
                                    <div class="flex items-center gap-2 flex-wrap">
                                        <span class="font-semibold text-sm" :class="formData.billing_type === 'digital' ? 'text-cyan-900' : 'text-slate-700'">
                                            {{ $t('dashboard.digital_access') }}
                                        </span>
                                        <span v-if="formData.billing_type === 'digital'" class="px-1.5 py-0.5 bg-cyan-200 text-cyan-700 text-xs font-medium rounded">
                                            {{ $t('common.selected') }}
                                        </span>
                                    </div>
                                    <p class="text-xs text-slate-500 mt-1 line-clamp-2">{{ $t('dashboard.digital_access_full_desc') }}</p>
                                    <div class="flex flex-wrap gap-1.5 mt-2">
                                        <span class="inline-flex items-center gap-1 px-1.5 py-0.5 bg-amber-100 text-amber-700 rounded text-xs">
                                            <i class="pi pi-bolt text-xs"></i> {{ $t('dashboard.pay_per_scan') }}
                                        </span>
                                    </div>
                                </div>
                            </div>
                        </button>
                    </div>

                    <!-- Daily Scan Limit (only for Digital Access) - Collapsible Advanced Option -->
                    <div v-if="formData.billing_type === 'digital'" class="mt-4">
                        <button
                            type="button"
                            @click="showAdvancedAccess = !showAdvancedAccess"
                            class="flex items-center gap-2 text-sm text-slate-600 hover:text-slate-800 transition-colors"
                        >
                            <i class="pi text-xs" :class="showAdvancedAccess ? 'pi-chevron-down' : 'pi-chevron-right'"></i>
                            <span>{{ $t('dashboard.advanced_options') }}</span>
                        </button>

                        <Transition name="slide">
                            <div v-show="showAdvancedAccess" class="mt-3 p-3 rounded-lg bg-slate-50 border border-slate-200">
                                <label class="text-sm font-medium text-slate-700 block mb-2">
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
                                        size="small"
                                    />
                                    <span class="text-xs text-slate-500">{{ $t('digital_access.scans_per_day') }}</span>
                                    <div class="flex items-center gap-2 ml-auto">
                                        <ToggleSwitch v-model="isDailyLimitUnlimited" />
                                        <span class="text-xs text-slate-600">{{ $t('digital_access.unlimited') }}</span>
                                    </div>
                                </div>
                                <p class="text-xs text-slate-400 mt-2">
                                    {{ $t('digital_access.set_daily_limit_hint') }}
                                </p>
                            </div>
                        </Transition>
                    </div>
                </div>
            </Transition>
        </div>
            
        <!-- Section 2: Card Artwork (Physical Cards Only) -->
        <div v-if="formData.billing_type === 'physical'" class="form-section">
            <div class="section-header" @click="toggleSection('artwork')">
                <div class="section-header-left">
                    <div class="section-number" :class="{ 'number-complete': previewImage }">
                        <span v-if="!previewImage">2</span>
                        <i v-else class="pi pi-check text-xs"></i>
                    </div>
                    <div class="section-title-group">
                        <h3 class="section-title">{{ $t('dashboard.card_artwork') }}</h3>
                        <p class="section-subtitle">
                            {{ previewImage ? $t('dashboard.image_uploaded') : $t('dashboard.upload_card_image') }}
                        </p>
                    </div>
                </div>
                <i class="pi section-chevron" :class="expandedSections.artwork ? 'pi-chevron-up' : 'pi-chevron-down'"></i>
            </div>

            <Transition name="slide">
                <div v-show="expandedSections.artwork" class="section-content">
                    <div class="grid grid-cols-1 lg:grid-cols-2 gap-4">
                        <!-- Image Preview/Upload -->
                        <div>
                            <div v-if="previewImage" class="card-artwork-container mx-auto border-2 border-blue-300 bg-blue-50/30 rounded-lg">
                                <div class="relative w-full h-full">
                                    <img :src="previewImage" alt="Card Artwork Preview" class="object-contain h-full w-full rounded-lg" />
                                    <div
                                        v-if="formData.qr_code_position"
                                        class="absolute w-10 h-10 bg-white border-2 border-slate-300 rounded-lg shadow-md flex items-center justify-center"
                                        :class="getQrCodePositionClass(formData.qr_code_position)"
                                    >
                                        <i class="pi pi-qrcode text-slate-700 text-xs"></i>
                                    </div>
                                </div>
                            </div>

                            <div
                                v-else
                                class="upload-drop-zone-compact"
                                @dragover.prevent="handleDragOver"
                                @dragleave.prevent="handleDragLeave"
                                @drop.prevent="handleDrop"
                                :class="{ 'drag-active': isDragActive }"
                            >
                                <div class="text-center">
                                    <div class="w-12 h-12 mx-auto mb-3 rounded-full bg-blue-100 flex items-center justify-center">
                                        <i class="pi pi-camera text-blue-600"></i>
                                    </div>
                                    <p class="text-sm font-medium text-slate-700 mb-1">{{ $t('dashboard.add_photo') }}</p>
                                    <p class="text-xs text-slate-500 mb-3">{{ $t('dashboard.drag_drop_upload') }}</p>
                                    <input ref="fileInputRef" type="file" accept="image/*" @change="handleFileSelect" class="hidden" />
                                    <Button :label="$t('dashboard.upload_photo')" icon="pi pi-upload" @click="triggerFileInput" severity="info" size="small" />
                                </div>
                            </div>

                            <!-- Image Actions -->
                            <div v-if="previewImage" class="flex flex-wrap gap-2 mt-3 justify-center">
                                <input ref="fileInputRef" type="file" accept="image/*" @change="handleFileSelect" class="hidden" />
                                <Button :label="$t('dashboard.change_photo')" icon="pi pi-image" @click="triggerFileInput" severity="secondary" outlined size="small" />
                                <Button :label="$t('dashboard.crop_image')" icon="pi pi-expand" @click="handleCropImage" severity="info" outlined size="small" />
                                <Button v-if="isCropped" :label="$t('dashboard.undo_crop')" icon="pi pi-undo" @click="handleUndoCrop" severity="warning" outlined size="small" />
                            </div>
                        </div>

                        <!-- QR Code Position & Requirements -->
                        <div class="space-y-4">
                            <div class="p-3 bg-slate-50 border border-slate-200 rounded-lg">
                                <label for="qr_code_position" class="block text-sm font-medium text-slate-700 mb-2">
                                    <i class="pi pi-qrcode text-slate-500 mr-1"></i>
                                    {{ $t('dashboard.position_on_card') }}
                                </label>
                                <Dropdown
                                    id="qr_code_position"
                                    v-model="formData.qr_code_position"
                                    :options="qrCodePositions"
                                    optionLabel="name"
                                    optionValue="code"
                                    :placeholder="$t('dashboard.select_position')"
                                    class="w-full"
                                    size="small"
                                />
                                <p class="text-xs text-slate-400 mt-2">{{ $t('dashboard.preview_updates_realtime') }}</p>
                            </div>

                            <div v-if="!previewImage" class="p-3 bg-blue-50 border border-blue-200 rounded-lg">
                                <p class="text-xs text-blue-700 flex items-start gap-2">
                                    <i class="pi pi-info-circle mt-0.5 flex-shrink-0"></i>
                                    <span><strong>{{ $t('dashboard.image_requirements') }}</strong> {{ $t('dashboard.image_requirements_text') }}</span>
                                </p>
                            </div>
                        </div>
                    </div>
                </div>
            </Transition>
        </div>

        <!-- Section 3: Project Details (Section 2 for Digital) -->
        <div class="form-section">
            <div class="section-header" @click="toggleSection('details')">
                <div class="section-header-left">
                    <div class="section-number" :class="{ 'number-complete': formData.name.trim() }">
                        <span v-if="!formData.name.trim()">{{ formData.billing_type === 'physical' ? '3' : '2' }}</span>
                        <i v-else class="pi pi-check text-xs"></i>
                    </div>
                    <div class="section-title-group">
                        <h3 class="section-title">{{ formData.billing_type === 'digital' ? $t('dashboard.qr_content_settings') : $t('dashboard.card_details') }}</h3>
                        <p class="section-subtitle">
                            {{ formData.name.trim() ? formData.name : $t('dashboard.configure_basic_info') }}
                        </p>
                    </div>
                </div>
                <i class="pi section-chevron" :class="expandedSections.details ? 'pi-chevron-up' : 'pi-chevron-down'"></i>
            </div>

            <Transition name="slide">
                <div v-show="expandedSections.details" class="section-content">
                    <div class="space-y-4">
                        <!-- Card/QR Name -->
                        <div>
                            <label for="cardName" class="block text-sm font-medium text-slate-700 mb-1.5">
                                {{ formData.billing_type === 'digital' ? $t('dashboard.qr_name') : $t('dashboard.card_name') }}
                                <span class="text-red-500">*</span>
                                <i class="pi pi-info-circle text-slate-400 text-xs ml-1 cursor-help"
                                   v-tooltip.right="{ value: $t('dashboard.project_name_tooltip'), class: 'max-w-xs' }"></i>
                            </label>
                            <InputText
                                id="cardName"
                                type="text"
                                v-model="formData.name"
                                class="w-full"
                                :class="{ 'p-invalid': !formData.name.trim() && showValidation }"
                                :placeholder="formData.billing_type === 'digital' ? $t('dashboard.enter_qr_name') : $t('dashboard.enter_card_name')"
                            />
                            <p v-if="!formData.name.trim() && showValidation" class="text-xs text-red-500 mt-1">{{ $t('dashboard.card_name_required') }}</p>
                        </div>

                        <!-- Original Language Selector -->
                        <div>
                            <label for="originalLanguage" class="block text-sm font-medium text-slate-700 mb-1.5">
                                {{ $t('dashboard.originalLanguage') }}
                                <span class="text-red-500">*</span>
                                <i class="pi pi-info-circle text-slate-400 text-xs ml-1 cursor-help"
                                   v-tooltip.right="{ value: $t('dashboard.originalLanguageTooltip'), class: 'max-w-xs' }"></i>
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

                        <!-- Card Description -->
                        <div>
                            <label for="cardDescription" class="block text-sm font-medium text-slate-700 mb-1.5">
                                {{ formData.billing_type === 'digital' ? $t('dashboard.welcome_description') : $t('dashboard.card_description') }}
                                <span class="text-xs text-slate-400 font-normal ml-1">({{ $t('dashboard.markdown_supported') }})</span>
                            </label>
                            <p v-if="formData.billing_type === 'digital'" class="text-xs text-cyan-600 mb-2">
                                {{ $t('dashboard.digital_description_hint') }}
                            </p>
                            <div class="border border-slate-200 rounded-lg overflow-hidden">
                                <MdEditor
                                    v-model="formData.description"
                                    :toolbars="markdownToolbars"
                                    :preview="true"
                                    :htmlPreview="true"
                                    :codeTheme="'atom'"
                                    :previewTheme="'default'"
                                    :onHtmlChanged="handleMarkdownHtmlChanged"
                                    :placeholder="getDescriptionPlaceholder()"
                                    :style="{ height: '180px' }"
                                />
                            </div>
                        </div>
                    </div>
                </div>
            </Transition>
        </div>

        <!-- Section 4: Content Display Mode -->
        <div class="form-section">
            <div class="section-header" @click="toggleSection('contentMode')">
                <div class="section-header-left">
                    <div class="section-number">
                        <span>{{ formData.billing_type === 'physical' ? '4' : '3' }}</span>
                    </div>
                    <div class="section-title-group">
                        <h3 class="section-title">{{ $t('dashboard.content_mode') }}</h3>
                        <p class="section-subtitle">{{ getContentModeLabel(formData.content_mode) }}</p>
                    </div>
                </div>
                <i class="pi section-chevron" :class="expandedSections.contentMode ? 'pi-chevron-up' : 'pi-chevron-down'"></i>
            </div>

            <Transition name="slide">
                <div v-show="expandedSections.contentMode" class="section-content">
                    <!-- Content Mode Selector -->
                    <div class="grid grid-cols-2 sm:grid-cols-4 gap-2 mb-4">
                        <button
                            v-for="mode in filteredContentModeOptions"
                            :key="mode.value"
                            type="button"
                            @click="formData.content_mode = mode.value"
                            class="content-mode-card"
                            :class="formData.content_mode === mode.value ? 'content-mode-card--selected' : 'content-mode-card--unselected'"
                        >
                            <i :class="['pi', mode.icon, 'text-lg mb-1', formData.content_mode === mode.value ? 'text-blue-600' : 'text-slate-400']"></i>
                            <span class="text-xs font-medium" :class="formData.content_mode === mode.value ? 'text-blue-900' : 'text-slate-600'">{{ mode.label }}</span>
                        </button>
                    </div>

                    <!-- Mode Description -->
                    <div class="p-3 rounded-lg mb-4" :class="formData.billing_type === 'physical' ? 'bg-slate-50 border border-slate-200' : 'bg-cyan-50 border border-cyan-200'">
                        <div class="flex items-start gap-2">
                            <i :class="['pi', currentModeDetails.icon, formData.billing_type === 'physical' ? 'text-slate-500' : 'text-cyan-600', 'mt-0.5']"></i>
                            <div class="flex-1">
                                <p class="text-sm font-medium" :class="formData.billing_type === 'physical' ? 'text-slate-700' : 'text-cyan-800'">{{ currentModeDetails.label }}</p>
                                <p class="text-xs mt-0.5" :class="formData.billing_type === 'physical' ? 'text-slate-500' : 'text-cyan-600'">{{ currentModeDetails.guidance }}</p>
                            </div>
                        </div>
                    </div>

                    <!-- Grouping Options -->
                    <div v-if="currentModeSupportsGrouping" class="p-3 rounded-lg border border-slate-200 bg-slate-50">
                        <div class="flex items-center justify-between">
                            <div class="flex items-center gap-2">
                                <i class="pi pi-folder text-amber-500"></i>
                                <span class="text-sm font-medium text-slate-700">{{ $t('dashboard.grouping_title') }}</span>
                                <i class="pi pi-info-circle text-slate-400 text-xs cursor-help"
                                   v-tooltip.right="{ value: $t('dashboard.grouping_tooltip'), class: 'max-w-xs' }"></i>
                            </div>
                            <ToggleSwitch v-model="formData.is_grouped" />
                        </div>
                        <p class="text-xs text-slate-500 mt-2">{{ $t('dashboard.grouping_description') }}</p>

                        <!-- Group Display Options -->
                        <Transition name="slide">
                            <div v-if="formData.is_grouped" class="mt-3 pt-3 border-t border-slate-200">
                                <label class="block text-xs font-medium text-slate-600 mb-2">{{ $t('dashboard.group_display_title') }}</label>
                                <div class="grid grid-cols-2 gap-2">
                                    <button
                                        type="button"
                                        @click="formData.group_display = 'expanded'"
                                        class="p-2 rounded-lg border transition-all text-center"
                                        :class="formData.group_display === 'expanded' ? 'border-amber-400 bg-amber-50' : 'border-slate-200 bg-white hover:border-slate-300'"
                                    >
                                        <i :class="['pi pi-list text-sm', formData.group_display === 'expanded' ? 'text-amber-600' : 'text-slate-400']"></i>
                                        <span class="block text-xs mt-1" :class="formData.group_display === 'expanded' ? 'text-amber-800 font-medium' : 'text-slate-600'">
                                            {{ $t('dashboard.group_display_expanded') }}
                                        </span>
                                    </button>
                                    <button
                                        type="button"
                                        @click="formData.group_display = 'collapsed'"
                                        class="p-2 rounded-lg border transition-all text-center"
                                        :class="formData.group_display === 'collapsed' ? 'border-amber-400 bg-amber-50' : 'border-slate-200 bg-white hover:border-slate-300'"
                                    >
                                        <i :class="['pi pi-folder text-sm', formData.group_display === 'collapsed' ? 'text-amber-600' : 'text-slate-400']"></i>
                                        <span class="block text-xs mt-1" :class="formData.group_display === 'collapsed' ? 'text-amber-800 font-medium' : 'text-slate-600'">
                                            {{ $t('dashboard.group_display_collapsed') }}
                                        </span>
                                    </button>
                                </div>
                            </div>
                        </Transition>
                    </div>
                </div>
            </Transition>
        </div>
                    
        <!-- Section 5: AI Assistant Configuration -->
        <div class="form-section" :class="{ 'section-ai-enabled': formData.conversation_ai_enabled }">
            <div class="section-header" @click="toggleSection('ai')">
                <div class="section-header-left">
                    <div class="section-number" :class="{ 'number-ai': formData.conversation_ai_enabled }">
                        <i v-if="formData.conversation_ai_enabled" class="pi pi-sparkles text-xs"></i>
                        <span v-else>{{ formData.billing_type === 'physical' ? '5' : '4' }}</span>
                    </div>
                    <div class="section-title-group">
                        <h3 class="section-title">{{ $t('dashboard.ai_assistant_configuration') }}</h3>
                        <p class="section-subtitle">
                            {{ formData.conversation_ai_enabled ? $t('common.enabled') : $t('common.disabled') }}
                            <span v-if="!formData.conversation_ai_enabled && hasAiData" class="text-slate-400 ml-1">({{ $t('dashboard.data_preserved') }})</span>
                        </p>
                    </div>
                </div>
                <div class="flex items-center gap-3">
                    <ToggleSwitch v-model="formData.conversation_ai_enabled" @click.stop />
                    <i class="pi section-chevron" :class="expandedSections.ai ? 'pi-chevron-up' : 'pi-chevron-down'"></i>
                </div>
            </div>

            <Transition name="slide">
                <div v-show="expandedSections.ai" class="section-content">
                    <!-- AI Cost Notice (when enabled) -->
                    <div v-if="formData.conversation_ai_enabled" class="mb-4 p-3 bg-amber-50 border border-amber-200 rounded-lg flex items-start gap-2">
                        <i class="pi pi-bolt text-amber-500 mt-0.5 flex-shrink-0"></i>
                        <div class="text-xs text-amber-800">
                            <strong>{{ $t('dashboard.ai_cost_notice_title') }}</strong>
                            <p class="mt-0.5">{{ $t('dashboard.ai_cost_notice_message', pricingVars) }}</p>
                        </div>
                    </div>

                    <!-- AI Disabled Notice -->
                    <div v-if="!formData.conversation_ai_enabled && hasAiData" class="mb-4 p-3 bg-slate-50 border border-slate-200 rounded-lg flex items-start gap-2">
                        <i class="pi pi-info-circle text-slate-400 mt-0.5 flex-shrink-0"></i>
                        <div class="text-xs text-slate-600">
                            <strong>{{ $t('dashboard.ai_data_preserved_title') }}</strong>
                            <p class="mt-0.5">{{ $t('dashboard.ai_data_preserved_message') }}</p>
                        </div>
                    </div>

                    <!-- AI Auto-Generate Button (when enabled) -->
                    <div v-if="formData.conversation_ai_enabled" class="mb-4">
                        <Button
                            :label="isGeneratingAi ? $t('dashboard.ai_generating') : $t('dashboard.ai_auto_generate')"
                            icon="pi pi-sparkles"
                            severity="info"
                            outlined
                            size="small"
                            class="w-full"
                            :loading="isGeneratingAi"
                            :disabled="isGeneratingAi || !formData.name.trim()"
                            @click="generateAiSettings"
                        />
                        <p class="text-xs text-slate-400 mt-1.5 text-center">
                            {{ $t('dashboard.ai_auto_generate_hint') }}
                        </p>
                    </div>

                    <!-- AI Configuration Fields (shown when enabled) -->
                    <div v-if="formData.conversation_ai_enabled" class="space-y-4">
                        <!-- AI Instruction -->
                        <div class="p-3 bg-blue-50/50 border border-blue-200 rounded-lg">
                            <label class="block text-sm font-medium text-slate-700 mb-1.5 flex items-center justify-between">
                                <span class="flex items-center gap-1.5">
                                    <i class="pi pi-user text-blue-500"></i>
                                    {{ $t('dashboard.ai_instruction_role_guidelines') }}
                                </span>
                                <span class="text-xs font-normal" :class="aiInstructionWordCount > 100 ? 'text-red-500' : 'text-slate-400'">
                                    {{ aiInstructionWordCount }}/100
                                </span>
                            </label>
                            <Textarea
                                v-model="formData.ai_instruction"
                                rows="2"
                                class="w-full"
                                :class="{ 'p-invalid': aiInstructionWordCount > 100 }"
                                :placeholder="$t('dashboard.enter_ai_role_guidelines')"
                                autoResize
                            />
                            <p class="text-xs text-slate-500 mt-1.5">{{ $t('dashboard.purpose_define_ai') }}</p>
                        </div>

                        <!-- AI Knowledge Base -->
                        <div class="p-3 bg-blue-50/50 border border-blue-200 rounded-lg">
                            <label class="block text-sm font-medium text-slate-700 mb-1.5 flex items-center justify-between">
                                <span class="flex items-center gap-1.5">
                                    <i class="pi pi-database text-blue-500"></i>
                                    {{ $t('dashboard.ai_knowledge_base_label') }}
                                </span>
                                <span class="text-xs font-normal" :class="aiKnowledgeBaseWordCount > 2000 ? 'text-red-500' : 'text-slate-400'">
                                    {{ aiKnowledgeBaseWordCount }}/2000
                                </span>
                            </label>
                            <Textarea
                                v-model="formData.ai_knowledge_base"
                                rows="4"
                                class="w-full"
                                :class="{ 'p-invalid': aiKnowledgeBaseWordCount > 2000 }"
                                :placeholder="$t('dashboard.knowledge_base_placeholder')"
                                autoResize
                            />
                            <p class="text-xs text-slate-500 mt-1.5">{{ $t('dashboard.knowledge_purpose') }}</p>
                        </div>

                        <!-- Advanced AI Options (Collapsible) -->
                        <button
                            type="button"
                            @click="showAdvancedAi = !showAdvancedAi"
                            class="flex items-center gap-2 text-sm text-slate-600 hover:text-slate-800 transition-colors"
                        >
                            <i class="pi text-xs" :class="showAdvancedAi ? 'pi-chevron-down' : 'pi-chevron-right'"></i>
                            <span>{{ $t('dashboard.ai_welcome_messages') }}</span>
                        </button>

                        <Transition name="slide">
                            <div v-show="showAdvancedAi" class="space-y-3 pl-4 border-l-2 border-blue-200">
                                <!-- General Assistant Welcome -->
                                <div>
                                    <label class="block text-xs font-medium text-slate-600 mb-1 flex items-center justify-between">
                                        <span class="flex items-center gap-1">
                                            <i class="pi pi-comments text-blue-400"></i>
                                            {{ $t('dashboard.ai_welcome_general_label') }}
                                        </span>
                                        <span :class="aiWelcomeGeneralWordCount > 100 ? 'text-red-500' : 'text-slate-400'">
                                            {{ aiWelcomeGeneralWordCount }}/100
                                        </span>
                                    </label>
                                    <Textarea
                                        v-model="formData.ai_welcome_general"
                                        rows="2"
                                        class="w-full text-sm"
                                        :class="{ 'p-invalid': aiWelcomeGeneralWordCount > 100 }"
                                        :placeholder="$t('dashboard.ai_welcome_general_placeholder')"
                                        autoResize
                                    />
                                    <p class="text-xs text-slate-400 mt-1">{{ $t('dashboard.ai_welcome_general_hint') }}</p>
                                </div>

                                <!-- Item Assistant Welcome -->
                                <div>
                                    <label class="block text-xs font-medium text-slate-600 mb-1 flex items-center justify-between">
                                        <span class="flex items-center gap-1">
                                            <i class="pi pi-info-circle text-emerald-400"></i>
                                            {{ $t('dashboard.ai_welcome_item_label') }}
                                        </span>
                                        <span :class="aiWelcomeItemWordCount > 100 ? 'text-red-500' : 'text-slate-400'">
                                            {{ aiWelcomeItemWordCount }}/100
                                        </span>
                                    </label>
                                    <Textarea
                                        v-model="formData.ai_welcome_item"
                                        rows="2"
                                        class="w-full text-sm"
                                        :class="{ 'p-invalid': aiWelcomeItemWordCount > 100 }"
                                        :placeholder="$t('dashboard.ai_welcome_item_placeholder')"
                                        autoResize
                                    />
                                    <p class="text-xs text-slate-400 mt-1">{{ $t('dashboard.ai_welcome_item_hint') }}</p>
                                </div>
                            </div>
                        </Transition>
                    </div>

                    <!-- Placeholder when AI is disabled -->
                    <div v-if="!formData.conversation_ai_enabled && !hasAiData" class="text-center py-6">
                        <div class="w-12 h-12 mx-auto mb-3 rounded-full bg-slate-100 flex items-center justify-center">
                            <i class="pi pi-sparkles text-slate-400"></i>
                        </div>
                        <p class="text-sm text-slate-500">{{ $t('dashboard.enable_ai_to_configure') }}</p>
                    </div>
                </div>
            </Transition>
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
import { usePhysicalCards } from '@/composables/usePhysicalCards';
import { supabase } from '@/lib/supabase';
import { useToast } from 'primevue/usetoast';

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

// Physical cards feature flag
const { isPhysicalCardsEnabled, getDefaultBillingType } = usePhysicalCards();

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
    billing_type: getDefaultBillingType.value, // Default based on feature flag: 'physical' when enabled, 'digital' when disabled
    max_sessions: null, // NULL for physical (unlimited), Integer for digital (total limit)
    default_daily_session_limit: 500 // Default daily limit for new QR codes
});

// Section expansion state - all expanded by default for create, only first section for edit
const expandedSections = reactive({
    accessMode: true,
    artwork: true,
    details: true,
    contentMode: true,
    ai: false // AI section collapsed by default for cleaner form
});

// Advanced options visibility
const showAdvancedAccess = ref(false);
const showAdvancedAi = ref(false);

// AI generation state
const toast = useToast();
const isGeneratingAi = ref(false);

const generateAiSettings = async () => {
    if (isGeneratingAi.value) return;

    isGeneratingAi.value = true;

    try {
        const { data: { session } } = await supabase.auth.getSession();
        if (!session) {
            throw new Error('Please sign in to use this feature');
        }

        const payload = {
            cardName: formData.name,
            cardDescription: formData.description,
            originalLanguage: formData.original_language,
            contentMode: formData.content_mode,
            isGrouped: formData.is_grouped,
            billingType: formData.billing_type,
        };

        // Include cardId in edit mode for content items enrichment
        if (props.isEditMode && formData.id) {
            payload.cardId = formData.id;
        }

        const backendUrl = import.meta.env.VITE_BACKEND_URL;
        const response = await fetch(`${backendUrl}/api/ai/generate-ai-settings`, {
            method: 'POST',
            headers: {
                'Authorization': `Bearer ${session.access_token}`,
                'Content-Type': 'application/json',
            },
            body: JSON.stringify(payload),
        });

        if (!response.ok) {
            const errorData = await response.json();
            throw new Error(errorData.message || 'Generation failed');
        }

        const result = await response.json();

        if (result.success && result.data) {
            formData.ai_instruction = result.data.ai_instruction || '';
            formData.ai_knowledge_base = result.data.ai_knowledge_base || '';
            formData.ai_welcome_general = result.data.ai_welcome_general || '';
            formData.ai_welcome_item = result.data.ai_welcome_item || '';

            // Auto-expand advanced section to show welcome messages
            showAdvancedAi.value = true;

            toast.add({
                severity: 'success',
                summary: t('dashboard.ai_generate_success'),
                detail: t('dashboard.ai_generate_success_detail'),
                life: 3000
            });
        }
    } catch (error) {
        console.error('AI generation failed:', error);
        toast.add({
            severity: 'error',
            summary: t('dashboard.ai_generate_error'),
            detail: error.message || t('dashboard.ai_generate_error_detail'),
            life: 5000
        });
    } finally {
        isGeneratingAi.value = false;
    }
};

// Toggle section expansion
const toggleSection = (section) => {
    expandedSections[section] = !expandedSections[section];
};

// Helper to get content mode label
const getContentModeLabel = (mode) => {
    const modeOption = contentModeOptions.value.find(m => m.value === mode);
    return modeOption?.label || mode;
};

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
        formData.billing_type = props.cardProp.billing_type || getDefaultBillingType.value; // Access mode based on feature flag
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
    formData.billing_type = getDefaultBillingType.value; // Reset to default access mode based on feature flag
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
/* ===== Project Form Container ===== */
.project-form {
    display: flex;
    flex-direction: column;
    gap: 0.75rem;
}

/* ===== Collapsible Section Styles ===== */
.form-section {
    background: white;
    border: 1px solid #e2e8f0;
    border-radius: 0.75rem;
    overflow: hidden;
    transition: all 0.2s ease;
}

.form-section:hover {
    border-color: #cbd5e1;
}

.form-section.section-locked {
    background: #fafafa;
}

.form-section.section-ai-enabled {
    border-color: #93c5fd;
    background: linear-gradient(135deg, #fefefe 0%, #eff6ff 100%);
}

.section-header {
    display: flex;
    align-items: center;
    justify-content: space-between;
    padding: 0.875rem 1rem;
    cursor: pointer;
    user-select: none;
    transition: background 0.15s ease;
}

.section-header:hover {
    background: #f8fafc;
}

.section-header-left {
    display: flex;
    align-items: center;
    gap: 0.75rem;
    min-width: 0;
    flex: 1;
}

.section-number {
    width: 1.75rem;
    height: 1.75rem;
    border-radius: 50%;
    background: #e2e8f0;
    color: #64748b;
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 0.75rem;
    font-weight: 600;
    flex-shrink: 0;
    transition: all 0.2s ease;
}

.section-number.number-complete {
    background: #10b981;
    color: white;
}

.section-number.number-ai {
    background: linear-gradient(135deg, #3b82f6 0%, #6366f1 100%);
    color: white;
}

.section-title-group {
    min-width: 0;
    flex: 1;
}

.section-title {
    font-size: 0.9375rem;
    font-weight: 600;
    color: #1e293b;
    margin: 0;
    line-height: 1.3;
}

.section-subtitle {
    font-size: 0.75rem;
    color: #64748b;
    margin: 0;
    margin-top: 0.125rem;
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
}

.section-chevron {
    color: #94a3b8;
    transition: transform 0.2s ease;
    flex-shrink: 0;
}

.section-content {
    padding: 0 1rem 1rem;
}

/* ===== Slide Transition ===== */
.slide-enter-active,
.slide-leave-active {
    transition: all 0.25s ease;
    overflow: hidden;
}

.slide-enter-from,
.slide-leave-to {
    opacity: 0;
    max-height: 0;
    padding-top: 0;
    padding-bottom: 0;
}

.slide-enter-to,
.slide-leave-from {
    opacity: 1;
    max-height: 2000px;
}

/* ===== Access Mode Cards ===== */
.access-mode-card {
    padding: 0.875rem;
    border-radius: 0.625rem;
    border: 2px solid transparent;
    transition: all 0.2s ease;
    cursor: pointer;
    width: 100%;
}

.access-mode-card--unselected {
    border-color: #e2e8f0;
    background: white;
}

.access-mode-card--unselected:hover {
    border-color: #cbd5e1;
    background: #f8fafc;
}

.access-mode-card--physical--selected {
    border-color: #a855f7;
    background: #faf5ff;
    box-shadow: 0 0 0 3px rgba(168, 85, 247, 0.1);
}

.access-mode-card--digital--selected {
    border-color: #06b6d4;
    background: #ecfeff;
    box-shadow: 0 0 0 3px rgba(6, 182, 212, 0.1);
}

/* ===== Content Mode Cards ===== */
.content-mode-card {
    padding: 0.75rem;
    border-radius: 0.5rem;
    border: 2px solid transparent;
    transition: all 0.2s ease;
    cursor: pointer;
    display: flex;
    flex-direction: column;
    align-items: center;
    text-align: center;
}

.content-mode-card--unselected {
    border-color: #e2e8f0;
    background: white;
}

.content-mode-card--unselected:hover {
    border-color: #cbd5e1;
    background: #f8fafc;
}

.content-mode-card--selected {
    border-color: #3b82f6;
    background: #eff6ff;
}

/* ===== Card Artwork Container ===== */
.card-artwork-container {
    aspect-ratio: var(--card-aspect-ratio, 2/3);
    width: 100%;
    max-width: 200px;
    margin: 0 auto;
    position: relative;
    transition: all 0.3s ease;
}

.card-artwork-container img {
    transition: all 0.2s ease-in-out;
}

.qr-position-tl { top: 6px; left: 6px; }
.qr-position-tr { top: 6px; right: 6px; }
.qr-position-bl { bottom: 6px; left: 6px; }
.qr-position-br { bottom: 6px; right: 6px; }

/* ===== Compact Upload Drop Zone ===== */
.upload-drop-zone-compact {
    border: 2px dashed #cbd5e1;
    border-radius: 0.75rem;
    padding: 1.5rem 1rem;
    text-align: center;
    background: #fefefe;
    transition: all 0.2s ease;
    cursor: pointer;
    max-width: 200px;
    margin: 0 auto;
}

.upload-drop-zone-compact:hover {
    border-color: #3b82f6;
    background: #f8faff;
}

.upload-drop-zone-compact.drag-active {
    border-color: #2563eb;
    background: #eff6ff;
    transform: scale(1.02);
}

/* ===== Daily Limit Input ===== */
.daily-limit-input {
    width: 120px;
}

.daily-limit-input :deep(.p-inputnumber-input) {
    width: 60px;
    text-align: center;
}

/* ===== Line Clamp Utility ===== */
.line-clamp-2 {
    display: -webkit-box;
    -webkit-line-clamp: 2;
    -webkit-box-orient: vertical;
    overflow: hidden;
}

/* ===== Markdown Editor ===== */
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

/* ===== Mobile Responsive ===== */
@media (max-width: 640px) {
    .section-header {
        padding: 0.75rem;
    }

    .section-content {
        padding: 0 0.75rem 0.75rem;
    }

    .section-title {
        font-size: 0.875rem;
    }

    .section-number {
        width: 1.5rem;
        height: 1.5rem;
        font-size: 0.6875rem;
    }

    .access-mode-card {
        padding: 0.75rem;
    }

    .content-mode-card {
        padding: 0.5rem;
    }

    .card-artwork-container {
        max-width: 160px;
    }

    .upload-drop-zone-compact {
        max-width: 160px;
        padding: 1rem;
    }
}
</style>
