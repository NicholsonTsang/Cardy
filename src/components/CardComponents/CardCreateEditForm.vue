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
        <div v-if="sections.includes('accessMode')" class="form-section" :class="{ 'section-locked': isEditMode }">
            <div class="section-header" @click="toggleSection('accessMode')">
                <div class="section-header-left">
                    <div v-if="!isSingleSection" class="section-number" :class="{ 'number-complete': isEditMode }">
                        <span v-if="!isEditMode">1</span>
                        <i v-else class="pi pi-lock text-xs"></i>
                    </div>
                    <div class="section-title-group">
                        <h3 class="section-title">{{ $t('dashboard.access_mode') }}</h3>
                        <p class="section-subtitle">
                            <template v-if="isEditMode">
                                {{ $t('dashboard.digital_access') }}
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
                    <div v-if="isEditMode" class="p-3 sm:p-4 rounded-lg border-2 text-left border-cyan-400 bg-cyan-50/50">
                        <div class="flex items-center gap-3">
                            <div class="w-10 h-10 rounded-lg flex items-center justify-center flex-shrink-0 bg-cyan-100">
                                <i class="pi pi-qrcode text-cyan-600 text-lg"></i>
                            </div>
                            <div class="flex-1 min-w-0">
                                <div class="flex items-center gap-2 flex-wrap">
                                    <span class="font-semibold text-sm text-cyan-900">
                                        {{ $t('dashboard.digital_access') }}
                                    </span>
                                    <span class="px-2 py-0.5 text-xs font-medium rounded-full bg-cyan-200 text-cyan-700">
                                        <i class="pi pi-lock text-xs mr-1"></i>{{ $t('dashboard.locked') }}
                                    </span>
                                </div>
                                <p class="text-xs mt-1 text-cyan-600">
                                    {{ $t('dashboard.access_mode_cannot_change') }}
                                </p>
                            </div>
                        </div>
                    </div>

                    <!-- Create Mode: Digital Access info -->
                    <div v-else class="p-3 sm:p-4 rounded-lg border-2 text-left border-cyan-400 bg-cyan-50/50">
                        <div class="flex items-start gap-3">
                            <div class="w-10 h-10 rounded-lg flex items-center justify-center flex-shrink-0 bg-cyan-100">
                                <i class="pi pi-qrcode text-cyan-600"></i>
                            </div>
                            <div class="flex-1 min-w-0 text-left">
                                <div class="flex items-center gap-2 flex-wrap">
                                    <span class="font-semibold text-sm text-cyan-900">
                                        {{ $t('dashboard.digital_access') }}
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
                    </div>

                    <!-- Daily Scan Limit - Collapsible Advanced Option -->
                    <div class="mt-4">
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
            
        <!-- Section 2: Project Details -->
        <div v-if="sections.includes('details')" class="form-section">
            <div v-if="!isDirectContent" class="section-header" @click="toggleSection('details')">
                <div class="section-header-left">
                    <div v-if="!isSingleSection" class="section-number" :class="{ 'number-complete': formData.name.trim() }">
                        <span v-if="!formData.name.trim()">2</span>
                        <i v-else class="pi pi-check text-xs"></i>
                    </div>
                    <div class="section-title-group">
                        <h3 class="section-title">{{ $t('dashboard.qr_content_settings') }}</h3>
                        <p class="section-subtitle">
                            {{ formData.name.trim() ? formData.name : $t('dashboard.configure_basic_info') }}
                        </p>
                    </div>
                </div>
                <i class="pi section-chevron" :class="expandedSections.details ? 'pi-chevron-up' : 'pi-chevron-down'"></i>
            </div>

            <Transition name="slide">
                <div v-show="isDirectContent || expandedSections.details" class="section-content">
                    <div class="space-y-4">
                        <!-- Card/QR Name -->
                        <div>
                            <label for="cardName" class="block text-sm font-medium text-slate-700 mb-1.5">
                                {{ $t('dashboard.qr_name') }}
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
                                :placeholder="$t('dashboard.enter_qr_name')"
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
                            <Select
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
                            </Select>
                        </div>

                        <!-- Card Description -->
                        <div>
                            <div class="flex items-center justify-between mb-1.5">
                                <label for="cardDescription" class="text-sm font-medium text-slate-700">
                                    {{ $t('dashboard.welcome_description') }}
                                    <span class="text-xs text-slate-400 font-normal ml-1">({{ $t('dashboard.markdown_supported') }})</span>
                                </label>
                                <Button
                                    v-if="descriptionWordCount >= 5"
                                    :label="isOptimizingDescription ? $t('dashboard.ai_generating') : $t('dashboard.ai_optimize')"
                                    icon="pi pi-sparkles"
                                    severity="secondary"
                                    text
                                    size="small"
                                    :loading="isOptimizingDescription"
                                    :disabled="isOptimizingDescription"
                                    @click="optimizeDescription"
                                />
                            </div>
                            <p class="text-xs text-cyan-600 mb-2">
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

        <!-- Section 3: AI Assistant Configuration -->
        <div v-if="sections.includes('ai')" :class="isDirectContent ? '' : ['form-section', { 'section-ai-enabled': formData.conversation_ai_enabled }]">
            <div v-if="!isDirectContent" class="section-header" @click="toggleSection('ai')">
                <div class="section-header-left">
                    <div v-if="!isSingleSection" class="section-number" :class="{ 'number-ai': formData.conversation_ai_enabled }">
                        <i v-if="formData.conversation_ai_enabled" class="pi pi-sparkles text-xs"></i>
                        <span v-else>3</span>
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
                <div v-show="isDirectContent || expandedSections.ai" class="section-content">
                    <!-- Toggle status card (dialog mode) -->
                    <div v-if="isDirectContent" class="flex items-center gap-3 p-3 rounded-xl border mb-4"
                         :class="formData.conversation_ai_enabled ? 'bg-violet-50 border-violet-200' : 'bg-slate-50 border-slate-200'">
                        <div class="w-9 h-9 rounded-lg flex items-center justify-center shrink-0"
                             :class="formData.conversation_ai_enabled ? 'bg-violet-100' : 'bg-slate-200'">
                            <i :class="['pi pi-sparkles', formData.conversation_ai_enabled ? 'text-violet-600' : 'text-slate-400']"></i>
                        </div>
                        <div class="flex-1 min-w-0">
                            <p class="text-sm font-medium text-slate-800 m-0">{{ $t('dashboard.ai_voice_assistant') }}</p>
                            <p class="text-xs text-slate-500 m-0">{{ $t('dashboard.ai_voice_description') }}</p>
                        </div>
                        <ToggleSwitch v-model="formData.conversation_ai_enabled" />
                    </div>

                    <!-- AI Disabled Notice -->
                    <div v-if="!formData.conversation_ai_enabled && hasAiData" class="mb-4 p-3 bg-slate-50 border border-slate-200 rounded-lg flex items-start gap-2">
                        <i class="pi pi-info-circle text-slate-400 mt-0.5 flex-shrink-0"></i>
                        <div class="text-xs text-slate-600">
                            <strong>{{ $t('dashboard.ai_data_preserved_title') }}</strong>
                            <p class="mt-0.5">{{ $t('dashboard.ai_data_preserved_message') }}</p>
                        </div>
                    </div>

                    <!-- Cost + Auto-generate bar (when enabled) -->
                    <div v-if="formData.conversation_ai_enabled" class="flex items-center gap-2 mb-4 flex-wrap">
                        <span class="inline-flex items-center gap-1 px-2 py-1 rounded-md bg-amber-50 border border-amber-200 text-[0.6875rem] text-amber-700">
                            <i class="pi pi-bolt text-amber-500 text-[0.625rem]"></i>
                            {{ $t('dashboard.ai_cost_inline', pricingVars) }}
                        </span>
                        <div class="flex-1"></div>
                        <Button
                            :label="isGeneratingAi ? $t('dashboard.ai_generating') : $t('dashboard.ai_auto_generate')"
                            icon="pi pi-sparkles"
                            severity="secondary"
                            text
                            size="small"
                            :loading="isGeneratingAi"
                            :disabled="isGeneratingAi || !formData.name.trim()"
                            @click="generateAiSettings"
                        />
                    </div>

                    <!-- Voice Conversation Toggle (only shown when AI is enabled) -->
                    <div v-if="formData.conversation_ai_enabled" class="flex items-center gap-3 p-3 rounded-xl border mb-4"
                         :class="formData.realtime_voice_enabled ? 'bg-indigo-50 border-indigo-200' : 'bg-slate-50 border-slate-200'">
                        <div class="w-9 h-9 rounded-lg flex items-center justify-center shrink-0"
                             :class="formData.realtime_voice_enabled ? 'bg-indigo-100' : 'bg-slate-200'">
                            <i :class="['pi pi-phone', formData.realtime_voice_enabled ? 'text-indigo-600' : 'text-slate-400']"></i>
                        </div>
                        <div class="flex-1 min-w-0">
                            <p class="text-sm font-medium text-slate-800 m-0">{{ $t('dashboard.realtime_voice_label') }}</p>
                            <p class="text-xs text-slate-500 m-0">{{ $t('dashboard.realtime_voice_description') }}</p>
                        </div>
                        <ToggleSwitch v-model="formData.realtime_voice_enabled" />
                    </div>

                    <!-- AI Configuration Fields (always visible, disabled when AI off) -->
                    <div :class="{ 'opacity-40 pointer-events-none select-none': !formData.conversation_ai_enabled }">
                        <!-- Instructions section -->
                        <div class="flex items-center gap-2 mb-3">
                            <span class="text-[0.6875rem] font-semibold uppercase tracking-wider text-slate-400">{{ $t('dashboard.ai_section_instructions') }}</span>
                            <div class="flex-1 border-t border-slate-200"></div>
                        </div>

                        <!-- AI Instruction -->
                        <div class="mb-4">
                            <label class="flex items-center justify-between mb-1.5">
                                <span class="text-sm font-medium text-slate-700">{{ $t('dashboard.ai_instruction_role_guidelines') }}</span>
                                <span class="text-xs" :class="aiInstructionWordCount > 100 ? 'text-red-500' : 'text-slate-400'">
                                    {{ aiInstructionWordCount }}/100
                                </span>
                            </label>
                            <Textarea
                                v-model="formData.ai_instruction"
                                rows="2"
                                class="w-full"
                                :class="{ 'p-invalid': aiInstructionWordCount > 100 }"
                                :placeholder="$t('dashboard.enter_ai_role_guidelines')"
                                :disabled="!formData.conversation_ai_enabled"
                                autoResize
                            />
                            <p class="text-xs text-slate-400 mt-1">{{ $t('dashboard.purpose_define_ai') }}</p>
                        </div>

                        <!-- AI Knowledge Base -->
                        <div class="mb-4">
                            <label class="flex items-center justify-between mb-1.5">
                                <span class="text-sm font-medium text-slate-700">{{ $t('dashboard.ai_knowledge_base_label') }}</span>
                                <span class="text-xs" :class="aiKnowledgeBaseWordCount > 2000 ? 'text-red-500' : 'text-slate-400'">
                                    {{ aiKnowledgeBaseWordCount }}/2000
                                </span>
                            </label>
                            <Textarea
                                v-model="formData.ai_knowledge_base"
                                rows="4"
                                class="w-full"
                                :class="{ 'p-invalid': aiKnowledgeBaseWordCount > 2000 }"
                                :placeholder="$t('dashboard.knowledge_base_placeholder')"
                                :disabled="!formData.conversation_ai_enabled"
                                autoResize
                            />
                            <p class="text-xs text-slate-400 mt-1">{{ $t('dashboard.knowledge_purpose') }}</p>
                        </div>

                        <!-- Welcome Messages section -->
                        <div class="flex items-center gap-2 mb-3 mt-5">
                            <span class="text-[0.6875rem] font-semibold uppercase tracking-wider text-slate-400">{{ $t('dashboard.ai_section_welcome') }}</span>
                            <span class="text-[0.625rem] text-slate-300">&middot; {{ $t('dashboard.ai_welcome_optional') }}</span>
                            <div class="flex-1 border-t border-slate-200"></div>
                        </div>

                        <!-- General Assistant Welcome -->
                        <div class="mb-4">
                            <label class="flex items-center justify-between mb-1.5">
                                <span class="text-sm font-medium text-slate-700">{{ $t('dashboard.ai_welcome_general_label') }}</span>
                                <span class="text-xs" :class="aiWelcomeGeneralWordCount > 100 ? 'text-red-500' : 'text-slate-400'">
                                    {{ aiWelcomeGeneralWordCount }}/100
                                </span>
                            </label>
                            <Textarea
                                v-model="formData.ai_welcome_general"
                                rows="2"
                                class="w-full"
                                :class="{ 'p-invalid': aiWelcomeGeneralWordCount > 100 }"
                                :placeholder="$t('dashboard.ai_welcome_general_placeholder')"
                                :disabled="!formData.conversation_ai_enabled"
                                autoResize
                            />
                            <p class="text-xs text-slate-400 mt-1">{{ $t('dashboard.ai_welcome_general_hint') }}</p>
                        </div>

                        <!-- Item Assistant Welcome -->
                        <div>
                            <label class="flex items-center justify-between mb-1.5">
                                <span class="text-sm font-medium text-slate-700">{{ $t('dashboard.ai_welcome_item_label') }}</span>
                                <span class="text-xs" :class="aiWelcomeItemWordCount > 100 ? 'text-red-500' : 'text-slate-400'">
                                    {{ aiWelcomeItemWordCount }}/100
                                </span>
                            </label>
                            <Textarea
                                v-model="formData.ai_welcome_item"
                                rows="2"
                                class="w-full"
                                :class="{ 'p-invalid': aiWelcomeItemWordCount > 100 }"
                                :placeholder="$t('dashboard.ai_welcome_item_placeholder')"
                                :disabled="!formData.conversation_ai_enabled"
                                autoResize
                            />
                            <p class="text-xs text-slate-400 mt-1">{{ $t('dashboard.ai_welcome_item_hint') }}</p>
                        </div>
                    </div>


                </div>
            </Transition>
        </div>

        <!-- Section 4: Theme & Appearance -->
        <div v-if="sections.includes('theme')" class="form-section">
            <div class="section-header" @click="toggleSection('theme')">
                <div class="section-header-left">
                    <div v-if="!isSingleSection" class="section-number">4</div>
                    <div class="section-title-group">
                        <h3 class="section-title">{{ $t('dashboard.theme_appearance') }}</h3>
                        <p class="section-subtitle">{{ $t('dashboard.customize_theme') }}</p>
                    </div>
                </div>
                <div class="flex items-center gap-3">
                    <i class="pi section-chevron" :class="expandedSections.theme ? 'pi-chevron-up' : 'pi-chevron-down'"></i>
                </div>
            </div>

            <Transition name="slide">
                <div v-show="expandedSections.theme" class="section-content">
                    <!-- Upgrade Hint for Free/Starter -->
                    <div v-if="!canCustomizeTheme" class="p-3 bg-amber-50 border border-amber-200 rounded-lg flex items-start gap-2 mb-4">
                        <i class="pi pi-lock text-amber-500 mt-0.5 flex-shrink-0"></i>
                        <p class="text-xs text-amber-700 m-0">{{ $t('dashboard.theme_upgrade_hint') }}</p>
                    </div>

                    <!-- Theme Color Pickers -->
                    <div :class="{ 'opacity-40 pointer-events-none select-none': !canCustomizeTheme }">
                        <p class="text-xs text-slate-400 mb-4">{{ $t('dashboard.theme_default_hint') }}</p>

                        <!-- Color Pickers Grid -->
                        <div class="grid grid-cols-1 sm:grid-cols-2 gap-4 mb-4">
                            <!-- Primary Color -->
                            <div>
                                <label class="text-sm font-medium text-slate-700 mb-1 block">{{ $t('dashboard.theme_primary_color') }}</label>
                                <div class="flex items-center gap-2">
                                    <input
                                        type="color"
                                        :value="formData.metadata?.theme?.primaryColor || DEFAULT_THEME.primaryColor"
                                        @input="updateThemeColor('primaryColor', $event.target.value)"
                                        class="w-10 h-10 rounded-lg border border-slate-300 cursor-pointer p-0.5"
                                    />
                                    <span class="text-xs text-slate-500 font-mono">{{ formData.metadata?.theme?.primaryColor || DEFAULT_THEME.primaryColor }}</span>
                                </div>
                                <p class="text-xs text-slate-400 mt-1">{{ $t('dashboard.theme_primary_color_hint') }}</p>
                            </div>

                            <!-- Background Color -->
                            <div>
                                <label class="text-sm font-medium text-slate-700 mb-1 block">{{ $t('dashboard.theme_background_color') }}</label>
                                <div class="flex items-center gap-2">
                                    <input
                                        type="color"
                                        :value="formData.metadata?.theme?.backgroundColor || DEFAULT_THEME.backgroundColor"
                                        @input="updateThemeColor('backgroundColor', $event.target.value)"
                                        class="w-10 h-10 rounded-lg border border-slate-300 cursor-pointer p-0.5"
                                    />
                                    <span class="text-xs text-slate-500 font-mono">{{ formData.metadata?.theme?.backgroundColor || DEFAULT_THEME.backgroundColor }}</span>
                                </div>
                                <p class="text-xs text-slate-400 mt-1">{{ $t('dashboard.theme_background_color_hint') }}</p>
                            </div>

                            <!-- Gradient End Color -->
                            <div>
                                <label class="text-sm font-medium text-slate-700 mb-1 block">{{ $t('dashboard.theme_gradient_end_color') }}</label>
                                <div class="flex items-center gap-2">
                                    <input
                                        type="color"
                                        :value="formData.metadata?.theme?.gradientEndColor || DEFAULT_THEME.gradientEndColor"
                                        @input="updateThemeColor('gradientEndColor', $event.target.value)"
                                        class="w-10 h-10 rounded-lg border border-slate-300 cursor-pointer p-0.5"
                                    />
                                    <span class="text-xs text-slate-500 font-mono">{{ formData.metadata?.theme?.gradientEndColor || DEFAULT_THEME.gradientEndColor }}</span>
                                </div>
                                <p class="text-xs text-slate-400 mt-1">{{ $t('dashboard.theme_gradient_end_color_hint') }}</p>
                            </div>

                            <!-- Text Color -->
                            <div>
                                <label class="text-sm font-medium text-slate-700 mb-1 block">{{ $t('dashboard.theme_text_color') }}</label>
                                <div class="flex items-center gap-2">
                                    <input
                                        type="color"
                                        :value="formData.metadata?.theme?.textColor || DEFAULT_THEME.textColor"
                                        @input="updateThemeColor('textColor', $event.target.value)"
                                        class="w-10 h-10 rounded-lg border border-slate-300 cursor-pointer p-0.5"
                                    />
                                    <span class="text-xs text-slate-500 font-mono">{{ formData.metadata?.theme?.textColor || DEFAULT_THEME.textColor }}</span>
                                </div>
                                <p class="text-xs text-slate-400 mt-1">{{ $t('dashboard.theme_text_color_hint') }}</p>
                            </div>
                        </div>

                        <!-- Live Preview Strip -->
                        <div class="mb-4">
                            <label class="text-xs font-semibold uppercase tracking-wider text-slate-400 mb-2 block">{{ $t('dashboard.theme_preview') }}</label>
                            <div class="rounded-xl overflow-hidden h-16 flex items-center px-4 gap-3"
                                 :style="themePreviewStyle">
                                <div class="w-8 h-8 rounded-full flex items-center justify-center flex-shrink-0"
                                     :style="{ background: formData.metadata?.theme?.primaryColor || DEFAULT_THEME.primaryColor }">
                                    <i class="pi pi-star text-xs" :style="{ color: formData.metadata?.theme?.textColor || DEFAULT_THEME.textColor }"></i>
                                </div>
                                <div>
                                    <p class="text-sm font-semibold m-0" :style="{ color: formData.metadata?.theme?.textColor || DEFAULT_THEME.textColor }">Sample Title</p>
                                    <p class="text-xs m-0 opacity-70" :style="{ color: formData.metadata?.theme?.textColor || DEFAULT_THEME.textColor }">Preview text</p>
                                </div>
                            </div>
                        </div>

                        <!-- Reset Button -->
                        <Button
                            :label="$t('dashboard.theme_reset_default')"
                            icon="pi pi-refresh"
                            severity="secondary"
                            outlined
                            size="small"
                            @click="resetThemeColors"
                        />
                    </div>
                </div>
            </Transition>
        </div>

    </div>
</template>

<script setup>
import { ref, reactive, onMounted, watch, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { SubscriptionConfig } from '@/config/subscription';
import Button from 'primevue/button';
import InputText from 'primevue/inputtext';
import InputNumber from 'primevue/inputnumber';
import Textarea from 'primevue/textarea';
import Select from 'primevue/select';
import ToggleSwitch from 'primevue/toggleswitch';
import { MdEditor } from 'md-editor-v3';
import 'md-editor-v3/lib/style.css';
import { SUPPORTED_LANGUAGES } from '@/stores/translation';
import { getLanguageFlag } from '@/utils/formatters';
import { supabase } from '@/lib/supabase';
import { useToast } from 'primevue/usetoast';
import { useSubscriptionStore } from '@/stores/subscription';
import { DEFAULT_THEME, isValidHexColor } from '@/utils/themeConfig';

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
    },
    sections: {
        type: Array,
        default: () => ['accessMode', 'details', 'ai', 'theme']
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
    realtime_voice_enabled: false,
    cropParameters: null,
    content_mode: 'list', // Default mode: list (vertical rows)
    is_grouped: false, // Whether content is organized into categories
    group_display: 'expanded', // How grouped items display: expanded or collapsed
    billing_type: 'digital',
    default_daily_session_limit: 500, // Default daily limit for new QR codes
    metadata: {} // Extensible metadata (theme settings, etc.)
});

// Single-section mode (when opened from contextual edit buttons)
const isSingleSection = computed(() => props.sections.length === 1);
const isDirectContent = computed(() => isSingleSection.value && props.isInDialog);

// Section expansion state - all expanded by default for create, only first section for edit
const expandedSections = reactive({
    accessMode: true,
    details: true,
    ai: false, // AI section collapsed by default for cleaner form
    theme: false // Theme section collapsed by default
});

// Advanced options visibility
const showAdvancedAccess = ref(false);


// Subscription store for tier-gated features
const subscriptionStore = useSubscriptionStore();
const canCustomizeTheme = computed(() => {
    const tier = subscriptionStore.tier;
    return tier === 'premium' || tier === 'enterprise';
});

// AI generation state
const toast = useToast();
const isGeneratingAi = ref(false);
const isOptimizingDescription = ref(false);

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

            toast.add({
                severity: 'success',
                summary: t('dashboard.ai_generate_success'),
                detail: t('dashboard.ai_generate_success_detail'),
                life: 3000
            });
        }
    } catch (error) {
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

const descriptionWordCount = computed(() => {
    return formData.description.trim().split(/\s+/).filter(w => w.length > 0).length;
});

const optimizeDescription = async () => {
    if (isOptimizingDescription.value) return;

    isOptimizingDescription.value = true;

    try {
        const { data: { session } } = await supabase.auth.getSession();
        if (!session) {
            throw new Error('Please sign in to use this feature');
        }

        const payload = {
            cardName: formData.name,
            description: formData.description,
            originalLanguage: formData.original_language,
        };

        if (props.isEditMode && formData.id) {
            payload.cardId = formData.id;
        }

        const backendUrl = import.meta.env.VITE_BACKEND_URL;
        const response = await fetch(`${backendUrl}/api/ai/optimize-description`, {
            method: 'POST',
            headers: {
                'Authorization': `Bearer ${session.access_token}`,
                'Content-Type': 'application/json',
            },
            body: JSON.stringify(payload),
        });

        if (!response.ok) {
            const errorData = await response.json();
            throw new Error(errorData.message || 'Optimization failed');
        }

        const result = await response.json();

        if (result.success && result.data?.description) {
            formData.description = result.data.description;
            toast.add({
                severity: 'success',
                summary: t('dashboard.ai_generate_success'),
                detail: t('dashboard.description_optimized_detail'),
                life: 3000
            });
        }
    } catch (error) {
        toast.add({
            severity: 'error',
            summary: t('dashboard.ai_generate_error'),
            detail: error.message || t('dashboard.ai_generate_error_detail'),
            life: 5000
        });
    } finally {
        isOptimizingDescription.value = false;
    }
};

// Toggle section expansion
const toggleSection = (section) => {
    expandedSections[section] = !expandedSections[section];
};

// Language options for dropdown
const languageOptions = computed(() => {
    return Object.entries(SUPPORTED_LANGUAGES).map(([code, name]) => ({
        value: code,
        label: name,
        flag: getLanguageFlag(code)
    }));
});

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

// Daily limit unlimited toggle for digital access
const isDailyLimitUnlimited = ref(false);

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

const showValidation = ref(false);

const isFormValid = computed(() => {
    return formData.name.trim().length > 0;
});

// Initialize form data from props
onMounted(() => {
    initializeForm();
});

// Auto-expand visible sections when sections prop changes (e.g., single-section mode)
watch(() => props.sections, (newSections) => {
    newSections.forEach(section => {
        expandedSections[section] = true;
    });
}, { immediate: true });

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

// Auto-enable AI when opening as direct single-section dialog
// with no existing AI data (matches "Enable & Configure" intent)
if (isDirectContent.value && props.sections.includes('ai')
    && !formData.conversation_ai_enabled && !hasAiData.value) {
    formData.conversation_ai_enabled = true;
}

// Note: AI data is intentionally preserved when AI is disabled
// This allows users to re-enable AI and have their data restored immediately

// Theme helpers
const updateThemeColor = (key, value) => {
    if (!formData.metadata) formData.metadata = {};
    if (!formData.metadata.theme) formData.metadata.theme = {};
    if (isValidHexColor(value)) {
        formData.metadata.theme[key] = value;
    }
};

const resetThemeColors = () => {
    if (!formData.metadata) formData.metadata = {};
    formData.metadata.theme = {};
};

const themePreviewStyle = computed(() => {
    const theme = formData.metadata?.theme || {};
    const bg = theme.backgroundColor || DEFAULT_THEME.backgroundColor;
    const end = theme.gradientEndColor || DEFAULT_THEME.gradientEndColor;
    return {
        background: `linear-gradient(135deg, ${bg} 0%, ${end} 100%)`
    };
});

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
        formData.realtime_voice_enabled = props.cardProp.realtime_voice_enabled || false;
        formData.cropParameters = props.cardProp.cropParameters || props.cardProp.crop_parameters || null;
        formData.content_mode = props.cardProp.content_mode || 'list';
        formData.is_grouped = props.cardProp.is_grouped || false;
        formData.group_display = props.cardProp.group_display || 'expanded';
        formData.billing_type = 'digital';
        formData.default_daily_session_limit = props.cardProp.default_daily_session_limit ?? 500;
        formData.metadata = props.cardProp.metadata ? JSON.parse(JSON.stringify(props.cardProp.metadata)) : {};

        // Set unlimited toggle based on default_daily_session_limit value
        isDailyLimitUnlimited.value = props.cardProp.default_daily_session_limit === null;
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
    formData.realtime_voice_enabled = false;
    formData.cropParameters = null;
    formData.content_mode = 'list'; // Reset to default mode
    formData.is_grouped = false;
    formData.group_display = 'expanded';
    formData.billing_type = 'digital';
    formData.default_daily_session_limit = 500; // Reset to default daily limit
    formData.metadata = {};
};

const getPayload = () => {
    const payload = { ...formData };

    // Ensure QR code position is valid
    if (!['TL', 'TR', 'BL', 'BR'].includes(payload.qr_code_position)) {
        payload.qr_code_position = 'BR'; // Default to Bottom Right if invalid
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

}
</style>
