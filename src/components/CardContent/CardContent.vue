<template>
    <div class="grid grid-cols-1 xl:grid-cols-5 gap-4 lg:gap-6">
        <!-- Content Items List -->
        <div class="xl:col-span-2 bg-white rounded-xl shadow-lg border border-slate-200 flex flex-col overflow-hidden">
            <!-- Header -->
            <div class="px-3 sm:px-4 py-2.5 border-b border-slate-200 bg-slate-50/80">
                <!-- Normal header row: status + actions -->
                <div v-if="!selectMode" class="flex items-center gap-2">
                    <i :class="[headerIcon, 'text-sm text-slate-500']"></i>
                    <span class="text-sm font-medium text-slate-700 truncate">{{ headerLabel }}</span>
                    <span v-if="headerCountText" class="text-xs text-slate-400 whitespace-nowrap">{{ headerCountText }}</span>
                    <div class="flex-1"></div>
                    <!-- Select mode toggle (only show when items exist) -->
                    <button
                        v-if="allSelectableItemIds.length > 1"
                        type="button"
                        @click="enterSelectMode"
                        class="flex items-center justify-center w-8 h-7 rounded-md text-slate-400 hover:text-slate-700 hover:bg-slate-100 transition-all"
                        v-tooltip.bottom="$t('content.select_items')"
                    >
                        <i class="pi pi-check-square text-xs"></i>
                    </button>
                    <!-- Mode selector button -->
                    <button
                        type="button"
                        @click="toggleModePopover"
                        class="relative flex items-center gap-1.5 px-2 h-7 rounded-md text-xs font-medium transition-all text-slate-500 hover:text-slate-700 hover:bg-slate-100"
                    >
                        <i :class="['pi', currentModeIcon, 'text-xs']"></i>
                        <span class="hidden sm:inline">{{ $t('dashboard.mode_' + localContentMode) }}</span>
                        <i class="pi pi-chevron-down text-[10px]"></i>
                        <span v-if="hasUnsavedModeChanges" class="absolute -top-0.5 -right-0.5 w-1.5 h-1.5 bg-amber-500 rounded-full"></span>
                    </button>
                    <!-- Add button -->
                    <button
                        v-if="normalizedMode !== 'single' || contentItems.length === 0"
                        type="button"
                        @click="showAddSerieDialog = true"
                        class="flex items-center justify-center w-8 h-7 rounded-md text-slate-400 hover:text-blue-600 hover:bg-blue-50 transition-all"
                        v-tooltip.bottom="addDialogHeader"
                    >
                        <i class="pi pi-plus text-sm"></i>
                    </button>
                </div>

                <!-- Multi-select header row -->
                <div v-else class="flex items-center gap-2">
                    <button
                        @click="exitSelectMode"
                        class="flex items-center justify-center w-7 h-7 rounded-md hover:bg-slate-100 transition-colors"
                    >
                        <i class="pi pi-arrow-left text-slate-600 text-sm"></i>
                    </button>
                    <span class="text-sm font-medium text-slate-700 truncate">
                        {{ selectedItemIds.size > 0 ? $t('content.n_items_selected', { count: selectedItemIds.size }) : $t('content.select_items') }}
                    </span>
                    <div class="flex-1"></div>
                    <button
                        @click="toggleSelectAll"
                        class="text-xs font-medium text-blue-600 hover:text-blue-700 px-2 py-1 rounded-md hover:bg-blue-50 transition-colors"
                    >
                        {{ allSelectableSelected ? $t('dashboard.deselect_all') : $t('dashboard.select_all') }}
                    </button>
                    <button
                        v-if="selectedItemIds.size > 0"
                        @click="confirmBulkDelete"
                        class="flex items-center gap-1.5 px-2.5 py-1 rounded-md text-xs font-medium text-red-600 hover:text-red-700 hover:bg-red-50 transition-colors"
                    >
                        <i class="pi pi-trash text-xs"></i>
                        {{ $t('common.delete') }}
                    </button>
                </div>

                <!-- Single mode hint -->
                <p v-if="!selectMode && normalizedMode === 'single' && contentItems.length >= 1" class="text-xs text-slate-500 mt-1.5 flex items-center gap-1">
                    <i class="pi pi-info-circle text-xs"></i>
                    {{ $t('content.single_mode_hint') }}
                </p>

                <!-- Bulk delete progress bar -->
                <div v-if="contentItemStore.isBulkDeleting" class="mt-2">
                    <ProgressBar :value="contentItemStore.bulkDeleteProgress" :showValue="false" class="h-1.5" />
                </div>
            </div>

            <!-- Mode Configuration Popover -->
            <Popover ref="modePopover">
                <div class="w-64 p-3">
                    <!-- Section 1: Layout -->
                    <div class="text-[11px] uppercase tracking-wide text-slate-400 font-medium mb-2">
                        {{ $t('content.layout') }}
                    </div>
                    <div class="grid grid-cols-4 gap-1.5">
                        <button
                            v-for="mode in contentModeOptions"
                            :key="mode.value"
                            type="button"
                            @click="localContentMode = mode.value"
                            class="flex flex-col items-center gap-1 px-1 py-2 rounded-lg border transition-all text-center"
                            :class="localContentMode === mode.value
                                ? 'border-blue-500 bg-blue-50 text-blue-700'
                                : 'border-slate-200 text-slate-500 hover:border-slate-300 hover:bg-slate-50'"
                        >
                            <i :class="['pi', mode.icon, 'text-base']"></i>
                            <span class="text-[11px] font-medium leading-tight">{{ $t('dashboard.mode_' + mode.value) }}</span>
                        </button>
                    </div>

                    <!-- Section 2: Organization (if mode supports grouping) -->
                    <template v-if="currentModeSupportsGrouping">
                        <div class="border-t border-slate-100 pt-3 mt-3">
                            <div class="text-[11px] uppercase tracking-wide text-slate-400 font-medium mb-2">
                                {{ $t('content.organization') }}
                            </div>
                            <label class="flex items-center gap-2.5 cursor-pointer">
                                <ToggleSwitch v-model="localIsGrouped" />
                                <div>
                                    <span class="text-sm font-medium text-slate-700">{{ $t('content.enable_categories') }}</span>
                                    <p class="text-xs text-slate-400 mt-0.5">{{ $t('content.enable_categories_desc') }}</p>
                                </div>
                            </label>
                        </div>
                    </template>

                    <!-- Section 3: Category Display (if grouped) -->
                    <template v-if="localIsGrouped && currentModeSupportsGrouping">
                        <div class="border-t border-slate-100 pt-3 mt-3">
                            <div class="text-[11px] uppercase tracking-wide text-slate-400 font-medium mb-2">
                                {{ $t('dashboard.group_display_title') }}
                            </div>
                            <div class="space-y-1.5">
                                <label
                                    class="flex items-center gap-2.5 px-2.5 py-2 rounded-lg border cursor-pointer transition-all"
                                    :class="localGroupDisplay === 'expanded'
                                        ? 'border-blue-500 bg-blue-50/50'
                                        : 'border-slate-200 hover:border-slate-300'"
                                >
                                    <RadioButton v-model="localGroupDisplay" value="expanded" />
                                    <div>
                                        <span class="text-sm font-medium text-slate-700">{{ $t('dashboard.group_display_expanded') }}</span>
                                        <p class="text-xs text-slate-400 mt-0.5">{{ $t('dashboard.group_display_expanded_desc') }}</p>
                                    </div>
                                </label>
                                <label
                                    class="flex items-center gap-2.5 px-2.5 py-2 rounded-lg border cursor-pointer transition-all"
                                    :class="localGroupDisplay === 'collapsed'
                                        ? 'border-blue-500 bg-blue-50/50'
                                        : 'border-slate-200 hover:border-slate-300'"
                                >
                                    <RadioButton v-model="localGroupDisplay" value="collapsed" />
                                    <div>
                                        <span class="text-sm font-medium text-slate-700">{{ $t('dashboard.group_display_collapsed') }}</span>
                                        <p class="text-xs text-slate-400 mt-0.5">{{ $t('dashboard.group_display_collapsed_desc') }}</p>
                                    </div>
                                </label>
                            </div>
                        </div>
                    </template>

                    <!-- Save/Cancel footer (only when changes exist) -->
                    <div v-if="hasUnsavedModeChanges" class="border-t border-slate-100 pt-3 mt-3 flex justify-end gap-2">
                        <Button :label="$t('common.cancel')" size="small" severity="secondary" text @click="resetModeConfig" />
                        <Button :label="$t('common.save')" icon="pi pi-check" size="small" :loading="isSavingMode" @click="saveModeConfig" />
                    </div>
                </div>
            </Popover>

            <!-- Content Items List -->
            <div class="flex-1 overflow-y-auto p-3">
                <!-- Empty State -->
                <div v-if="(effectiveIsGrouped ? contentItems.length : displayItems.length) === 0" class="flex flex-col items-center py-8 text-center px-4">
                    <i class="pi pi-inbox text-3xl text-slate-300 mb-3"></i>
                    <p class="text-sm text-slate-500 mb-3">{{ emptyStateMessage }}</p>
                    <Button icon="pi pi-plus" :label="addDialogHeader" size="small" @click="showAddSerieDialog = true" />
                </div>

                <!-- Drag Hint - compact inline design -->
                <div v-if="contentItems.length > 1 && !dragHintDismissed" class="flex items-center gap-2 px-3 py-2 mb-2 bg-slate-50 rounded-lg text-xs text-slate-500">
                    <i class="pi pi-arrows-v text-slate-400 text-xs"></i>
                    <span class="flex-1">{{ $t('content.drag_tip_short') }}</span>
                    <button
                        @click="dragHintDismissed = true"
                        class="text-slate-400 hover:text-slate-600 transition-colors p-0.5"
                    >
                        <i class="pi pi-times text-[10px]"></i>
                    </button>
                </div>

                <!-- Content Items - Grouped Mode (show categories) -->
                <draggable 
                    v-if="effectiveIsGrouped"
                    v-model="contentItems" 
                    @end="onParentDragEnd"
                    item-key="id"
                    handle=".parent-drag-handle"
                    class="space-y-2"
                >
                    <template #item="{ element: item, index }">
                        <div class="group">
                            <!-- ========== SINGLE MODE: Full Page Content ========== -->
                            <div 
                                v-if="normalizedMode === 'single'"
                                class="relative rounded-lg border transition-all duration-200 overflow-hidden bg-white hover:shadow-sm cursor-pointer"
                                :class="selectedContentItem === item.id 
                                    ? 'border-blue-500 border-l-[3px] shadow-sm bg-blue-50/30'
                                    : 'border-slate-200 hover:border-slate-300'"
                                @click="selectedContentItem = item.id"
                            >
                                <div class="flex items-center gap-2.5 p-3">
                                    <!-- Page Icon -->
                                    <div class="flex-shrink-0 w-9 h-9 bg-purple-100 rounded-md flex items-center justify-center">
                                        <i class="pi pi-file text-purple-500 text-sm"></i>
                                    </div>
                                    
                                    <!-- Page Info -->
                                    <div class="flex-1 min-w-0">
                                        <div class="font-medium text-slate-900 text-sm truncate">{{ item.name }}</div>
                                        <div v-if="item.content" class="text-xs text-slate-500 line-clamp-1">
                                            {{ stripMarkdown(item.content) }}
                                        </div>
                                    </div>
                                </div>
                            </div>
                                        
                            <!-- ========== GROUPED MODE: Category Header ========== -->
                            <div 
                                v-else-if="effectiveIsGrouped"
                                class="category-card group/card relative rounded-lg border transition-all duration-200 overflow-hidden bg-white hover:shadow-sm"
                                :class="selectedContentItem === item.id 
                                    ? 'border-blue-500 border-l-[3px] shadow-sm bg-blue-50/30'
                                    : 'border-slate-200 hover:border-slate-300'"
                            >
                                <div class="flex items-center gap-2.5 p-3">
                                    <!-- Drag Handle -->
                                    <div
                                        class="flex-shrink-0 flex items-center justify-center w-5 h-5 rounded hover:bg-slate-100 cursor-move parent-drag-handle opacity-40 group-hover/card:opacity-100 transition-opacity"
                                        @click.stop
                                    >
                                        <i class="pi pi-bars text-slate-400 text-xs"></i>
                                    </div>

                                    <!-- Category Icon -->
                                    <div
                                        class="flex-shrink-0 w-9 h-9 bg-orange-100 rounded-md flex items-center justify-center cursor-pointer"
                                        @click="selectedContentItem = item.id"
                                    >
                                        <i class="pi pi-folder text-orange-500 text-sm"></i>
                                    </div>
                                    
                                    <!-- Category Info -->
                                    <div 
                                        class="flex-1 min-w-0 cursor-pointer"
                                        @click="() => { selectedContentItem = item.id; expandContentItems[index] = !expandContentItems[index]; }"
                                    >
                                        <div class="font-medium text-slate-900 text-sm truncate">{{ item.name }}</div>
                                        <div class="text-xs text-slate-500">
                                            <span v-if="item.children && item.children.length > 0">
                                                {{ item.children.length }} {{ $t('content.items_count') }}
                                            </span>
                                            <span v-else class="text-amber-500">
                                                {{ $t('content.no_items_yet') }}
                                            </span>
                                        </div>
                                    </div>

                                    <!-- Add Item Button (visible on hover) -->
                                    <button
                                        class="flex-shrink-0 w-7 h-7 flex items-center justify-center rounded-md bg-orange-100 text-orange-600 hover:bg-orange-200 opacity-0 group-hover/card:opacity-100 transition-all"
                                        @click.stop="() => { showAddItemDialog = true; parentItemId = item.id; }"
                                        v-tooltip.top="$t('content.add_item')"
                                    >
                                        <i class="pi pi-plus text-xs"></i>
                                    </button>

                                    <!-- Expand/Collapse -->
                                    <button
                                        class="flex-shrink-0 w-7 h-7 flex items-center justify-center rounded-md hover:bg-slate-100 transition-colors"
                                        :class="item.children && item.children.length > 0 ? '' : 'invisible'"
                                        @click.stop="expandContentItems[index] = !expandContentItems[index]"
                                    >
                                        <i :class="expandContentItems[index] ? 'pi pi-chevron-up' : 'pi pi-chevron-down'" class="text-slate-400 text-xs"></i>
                                    </button>
                                </div>
                            </div>

                            <!-- ========== LIST MODE: Simple List Item ========== -->
                            <div 
                                v-else-if="normalizedMode === 'list' && !effectiveIsGrouped"
                                class="group/list relative rounded-lg border transition-all duration-200 overflow-hidden bg-white hover:shadow-sm"
                                :class="selectedContentItem === item.id 
                                    ? 'border-blue-500 border-l-[3px] shadow-sm bg-blue-50/30'
                                    : 'border-slate-200 hover:border-slate-300'"
                            >
                                <div class="flex items-center gap-2.5 p-3">
                                    <!-- Drag Handle -->
                                    <div
                                        class="flex-shrink-0 flex items-center justify-center w-5 h-5 rounded hover:bg-slate-100 cursor-move parent-drag-handle opacity-40 group-hover/list:opacity-100 transition-opacity"
                                        @click.stop
                                    >
                                        <i class="pi pi-bars text-slate-400 text-xs"></i>
                                    </div>

                                    <!-- List Icon -->
                                    <div class="flex-shrink-0 w-9 h-9 bg-blue-100 rounded-md flex items-center justify-center">
                                        <i :class="['pi', getLinkIcon(item.content), 'text-blue-500 text-sm']"></i>
                                    </div>
                                    
                                    <!-- Item Info -->
                                    <div 
                                        class="flex-1 min-w-0 cursor-pointer"
                                        @click="selectedContentItem = item.id"
                                    >
                                        <div class="font-medium text-slate-900 text-sm truncate">{{ item.name }}</div>
                                        <div v-if="item.content" class="text-xs text-slate-500 truncate">
                                            {{ item.content }}
                                        </div>
                                    </div>
                                </div>
                            </div>

                            <!-- ========== GRID MODE: Gallery Item ========== -->
                            <div 
                                v-else-if="normalizedMode === 'grid' && !effectiveIsGrouped"
                                class="group/grid relative rounded-lg border transition-all duration-200 overflow-hidden bg-white hover:shadow-sm"
                                :class="selectedContentItem === item.id 
                                    ? 'border-blue-500 border-l-[3px] shadow-sm bg-blue-50/30'
                                    : 'border-slate-200 hover:border-slate-300'"
                            >
                                <div class="flex items-center gap-2.5 p-3">
                                    <!-- Drag Handle -->
                                    <div
                                        class="flex-shrink-0 flex items-center justify-center w-5 h-5 rounded hover:bg-slate-100 cursor-move parent-drag-handle opacity-40 group-hover/grid:opacity-100 transition-opacity"
                                        @click.stop
                                    >
                                        <i class="pi pi-bars text-slate-400 text-xs"></i>
                                    </div>
                                    
                                    <!-- Thumbnail (Square) -->
                                    <div 
                                        class="flex-shrink-0 cursor-pointer"
                                        @click="selectedContentItem = item.id"
                                    >
                                        <div v-if="item.image_url" class="w-10 h-10 rounded-md overflow-hidden border border-slate-200">
                                            <img :src="item.image_url" :alt="item.name" class="w-full h-full object-cover" />
                                        </div>
                                        <div v-else class="w-10 h-10 bg-green-50 rounded-md border border-green-200 border-dashed flex items-center justify-center">
                                            <i class="pi pi-image text-green-300 text-xs"></i>
                                        </div>
                                    </div>
                                    
                                    <!-- Item Info -->
                                    <div 
                                        class="flex-1 min-w-0 cursor-pointer"
                                        @click="selectedContentItem = item.id"
                                    >
                                        <div class="font-medium text-slate-900 text-sm truncate">{{ item.name }}</div>
                                        <div v-if="!item.image_url" class="text-xs text-amber-500">
                                            {{ $t('content.needs_photo') }}
                                        </div>
                                        <div v-else-if="item.content" class="text-xs text-slate-500 truncate">
                                            {{ stripMarkdown(item.content) }}
                                        </div>
                                    </div>
                                </div>
                            </div>

                            <!-- ========== CARDS MODE: Full Card Item ========== -->
                            <div 
                                v-else-if="normalizedMode === 'cards' && !effectiveIsGrouped"
                                class="group/cards relative rounded-lg border transition-all duration-200 overflow-hidden bg-white hover:shadow-sm"
                                :class="selectedContentItem === item.id 
                                    ? 'border-blue-500 border-l-[3px] shadow-sm bg-blue-50/30'
                                    : 'border-slate-200 hover:border-slate-300'"
                            >
                                <div class="flex items-center gap-2.5 p-3">
                                    <!-- Drag Handle -->
                                    <div
                                        class="flex-shrink-0 flex items-center justify-center w-5 h-5 rounded hover:bg-slate-100 cursor-move parent-drag-handle opacity-40 group-hover/cards:opacity-100 transition-opacity"
                                        @click.stop
                                    >
                                        <i class="pi pi-bars text-slate-400 text-xs"></i>
                                    </div>
                                    
                                    <!-- Thumbnail (16:9) -->
                                    <div 
                                        class="flex-shrink-0 cursor-pointer"
                                        @click="selectedContentItem = item.id"
                                    >
                                        <div v-if="item.image_url" class="w-14 rounded-md overflow-hidden border border-slate-200" style="aspect-ratio: 16/9">
                                            <img :src="item.image_url" :alt="item.name" class="w-full h-full object-cover" />
                                        </div>
                                        <div v-else class="w-14 bg-cyan-50 rounded-md border border-cyan-200 border-dashed flex items-center justify-center" style="aspect-ratio: 16/9">
                                            <i class="pi pi-image text-cyan-300 text-xs"></i>
                                        </div>
                                    </div>
                                    
                                    <!-- Item Info -->
                                    <div 
                                        class="flex-1 min-w-0 cursor-pointer"
                                        @click="selectedContentItem = item.id"
                                    >
                                        <div class="font-medium text-slate-900 text-sm truncate">{{ item.name }}</div>
                                        <div v-if="item.content" class="text-xs text-slate-500 truncate">
                                            {{ stripMarkdown(item.content) }}
                                        </div>
                                    </div>
                                </div>
                            </div>

                            <!-- ========== DEFAULT MODE: Generic Item ========== -->
                            <div 
                                v-else
                                class="group/default relative rounded-lg border border-slate-200 transition-all duration-200 overflow-hidden bg-white hover:shadow-sm hover:border-slate-300"
                                :class="{ 'border-l-[3px] border-l-blue-500 shadow-sm bg-blue-50/30': selectedContentItem === item.id }"
                            >
                                <div class="flex items-center gap-2.5 p-3">
                                    <div class="flex-shrink-0 flex items-center justify-center w-5 h-5 rounded hover:bg-slate-100 cursor-move parent-drag-handle opacity-40 group-hover/default:opacity-100 transition-opacity" @click.stop>
                                        <i class="pi pi-bars text-slate-400 text-xs"></i>
                                    </div>
                                    <div v-if="item.image_url" class="flex-shrink-0">
                                        <div class="w-10 rounded-md overflow-hidden border border-slate-200" style="aspect-ratio: 4/3">
                                            <img :src="item.image_url" :alt="item.name" class="w-full h-full object-cover" />
                                        </div>
                                    </div>
                                    <div v-else class="w-10 bg-slate-100 rounded-md border border-slate-200 flex items-center justify-center flex-shrink-0" style="aspect-ratio: 4/3">
                                        <i class="pi pi-image text-slate-400 text-xs"></i>
                                    </div>
                                    <div class="flex-1 min-w-0 cursor-pointer" @click="() => { selectedContentItem = item.id; expandContentItems[index] = !expandContentItems[index]; }">
                                        <div class="font-medium text-slate-900 text-sm truncate">{{ item.name }}</div>
                                        <div v-if="item.children && item.children.length > 0" class="text-xs text-slate-500">
                                            {{ $t('content.sub_items_count', { count: item.children.length }) }}
                                        </div>
                                    </div>
                                    <button v-if="item.children && item.children.length > 0" class="flex-shrink-0 w-7 h-7 flex items-center justify-center rounded-md hover:bg-slate-100 transition-colors" @click.stop="expandContentItems[index] = !expandContentItems[index]">
                                        <i :class="expandContentItems[index] ? 'pi pi-chevron-up' : 'pi pi-chevron-down'" class="text-slate-400 text-xs"></i>
                                    </button>
                                </div>
                            </div>

                            <!-- Sub-items (for Grouped mode - Category Items) -->
                            <Transition name="expand">
                                <div v-if="expandContentItems[index] && effectiveIsGrouped" class="ml-6 mt-2 space-y-1.5 border-l-2 border-slate-100 pl-2">
                                    <draggable
                                        v-model="item.children"
                                        :group="{ name: 'content-items', pull: true, put: true }"
                                        @start="isDragging = true"
                                        @end="(evt) => { onChildDragEnd(evt, item.id); isDragging = false; }"
                                        @change="(evt) => onCrossParentChange(evt, item.id)"
                                        item-key="id"
                                        handle=".child-drag-handle"
                                        class="space-y-1.5 min-h-[36px] rounded transition-colors"
                                        :class="{ 'bg-amber-50/50 border border-dashed border-amber-200': isDragging }"
                                    >
                                        <template #item="{ element: child, index: childIndex }">
                                            <div
                                                class="group/child relative rounded-md border bg-white transition-all duration-150 hover:shadow-sm"
                                                :class="[
                                                    selectMode && selectedItemIds.has(child.id) ? 'border-indigo-400 bg-indigo-50/30' :
                                                    selectedContentItem === child.id ? 'border-blue-500 border-l-2 shadow-sm bg-blue-50/30' :
                                                    'border-slate-200 hover:border-slate-300'
                                                ]"
                                                @click="selectMode ? toggleItemSelection(child.id) : null"
                                            >
                                                <div class="flex items-center gap-2 p-2">
                                                    <!-- Selection checkbox (select mode) -->
                                                    <div
                                                        v-if="selectMode"
                                                        class="flex-shrink-0 w-[16px] h-[16px] rounded-full border-2 flex items-center justify-center transition-all"
                                                        :class="selectedItemIds.has(child.id)
                                                            ? 'bg-indigo-600 border-indigo-600'
                                                            : 'border-slate-300 hover:border-slate-400'"
                                                        @click.stop="toggleItemSelection(child.id)"
                                                    >
                                                        <i v-if="selectedItemIds.has(child.id)" class="pi pi-check text-white text-[7px]"></i>
                                                    </div>
                                                    <!-- Drag Handle -->
                                                    <div v-else class="flex-shrink-0 flex items-center justify-center w-5 h-5 rounded hover:bg-slate-100 cursor-move child-drag-handle opacity-30 group-hover/child:opacity-100 transition-opacity" @click.stop>
                                                        <i class="pi pi-bars text-slate-400 text-[10px]"></i>
                                                    </div>

                                                    <!-- Item Thumbnail -->
                                                    <div v-if="child.image_url" class="flex-shrink-0 w-8 h-8 rounded overflow-hidden border border-slate-200">
                                                        <img :src="child.image_url" :alt="child.name" class="w-full h-full object-cover" />
                                                    </div>
                                                    <div v-else class="flex-shrink-0 w-8 h-8 bg-amber-50 rounded flex items-center justify-center">
                                                        <i class="pi pi-box text-amber-300 text-xs"></i>
                                                    </div>

                                                    <!-- Item Info -->
                                                    <div class="flex-1 min-w-0 cursor-pointer" @click="selectMode ? null : (selectedContentItem = child.id)">
                                                        <div class="font-medium text-slate-800 text-sm truncate">{{ child.name }}</div>
                                                        <div v-if="child.content" class="text-xs text-slate-400 truncate">
                                                            {{ stripMarkdown(child.content) }}
                                                        </div>
                                                    </div>
                                                </div>
                                            </div>
                                        </template>
                                    </draggable>
                                </div>
                            </Transition>

                            <!-- Sub-items (for Default mode) -->
                            <Transition name="expand">
                                <div v-if="expandContentItems[index] && !['single', 'list', 'grid', 'cards'].includes(contentMode)" class="ml-6 mt-2 space-y-1.5 border-l-2 border-slate-100 pl-2">
                                    <draggable
                                        v-model="item.children"
                                        @end="(evt) => onChildDragEnd(evt, item.id)"
                                        item-key="id"
                                        handle=".child-drag-handle"
                                        class="space-y-1.5"
                                    >
                                        <template #item="{ element: child, index: childIndex }">
                                            <div
                                                class="group/subitem relative rounded-md border border-slate-200 bg-white transition-all duration-150 hover:shadow-sm hover:border-slate-300"
                                                :class="{ 'border-l-2 border-l-blue-500 shadow-sm bg-blue-50/30': selectedContentItem === child.id }"
                                            >
                                                <div class="flex items-center gap-2 p-2">
                                                    <div class="flex-shrink-0 flex items-center justify-center w-5 h-5 rounded hover:bg-slate-100 cursor-move child-drag-handle opacity-30 group-hover/subitem:opacity-100 transition-opacity" @click.stop>
                                                        <i class="pi pi-bars text-slate-400 text-[10px]"></i>
                                                    </div>
                                                    <div class="flex-shrink-0 cursor-pointer" @click="selectedContentItem = child.id">
                                                        <div v-if="child.image_url" class="w-8 rounded overflow-hidden border border-slate-200" style="aspect-ratio: 4/3">
                                                            <img :src="child.image_url" :alt="child.name" class="w-full h-full object-cover" />
                                                        </div>
                                                        <div v-else class="w-8 bg-slate-100 rounded border border-slate-200 flex items-center justify-center" style="aspect-ratio: 4/3">
                                                            <i class="pi pi-image text-slate-400 text-[10px]"></i>
                                                        </div>
                                                    </div>
                                                    <div class="flex-1 min-w-0 cursor-pointer" @click="selectedContentItem = child.id">
                                                        <div class="font-medium text-sm text-slate-800 truncate group-hover/subitem:text-blue-600 transition-colors">
                                                            {{ child.name }}
                                                        </div>
                                                    </div>
                                                </div>
                                            </div>
                                        </template>
                                    </draggable>
                                </div>
                            </Transition>
                        </div>
                    </template>
                </draggable>

                <!-- Content Items - Flat Mode (show all layer 2 items directly) -->
                <draggable
                    v-else
                    v-model="flatDisplayItems"
                    @end="onFlatItemDragEnd"
                    item-key="id"
                    handle=".flat-drag-handle"
                    :disabled="selectMode"
                    class="space-y-2"
                >
                    <template #item="{ element: item }">
                        <div
                            class="group/flat relative rounded-lg border transition-all duration-200 overflow-hidden bg-white hover:shadow-sm cursor-pointer"
                            :class="[
                                selectMode && selectedItemIds.has(item.id) ? 'border-indigo-400 bg-indigo-50/30' :
                                selectedContentItem === item.id ? 'border-blue-500 border-l-[3px] shadow-sm bg-blue-50/30' :
                                'border-slate-200 hover:border-slate-300'
                            ]"
                            @click="selectMode ? toggleItemSelection(item.id) : (selectedContentItem = item.id)"
                        >
                            <div class="flex items-center gap-2.5 p-3">
                                <!-- Selection checkbox (select mode) -->
                                <div
                                    v-if="selectMode"
                                    class="flex-shrink-0 w-[18px] h-[18px] rounded-full border-2 flex items-center justify-center transition-all"
                                    :class="selectedItemIds.has(item.id)
                                        ? 'bg-indigo-600 border-indigo-600'
                                        : 'border-slate-300 hover:border-slate-400'"
                                    @click.stop="toggleItemSelection(item.id)"
                                >
                                    <i v-if="selectedItemIds.has(item.id)" class="pi pi-check text-white text-[8px]"></i>
                                </div>
                                <!-- Drag Handle (normal mode) -->
                                <div
                                    v-else
                                    class="flex-shrink-0 flex items-center justify-center w-5 h-5 rounded hover:bg-slate-100 cursor-move flat-drag-handle opacity-40 group-hover/flat:opacity-100 transition-opacity"
                                    @click.stop
                                >
                                    <i class="pi pi-bars text-slate-400 text-xs"></i>
                                </div>
                                
                                <!-- Thumbnail based on mode -->
                                <div v-if="normalizedMode === 'grid' && item.image_url" class="flex-shrink-0 w-10 h-10 rounded-md overflow-hidden border border-slate-200">
                                    <img :src="item.image_url" :alt="item.name" class="w-full h-full object-cover" />
                                </div>
                                <div v-else-if="normalizedMode === 'grid'" class="flex-shrink-0 w-10 h-10 bg-green-50 rounded-md border border-green-200 border-dashed flex items-center justify-center">
                                    <i class="pi pi-image text-green-300 text-xs"></i>
                                </div>
                                <div v-else-if="normalizedMode === 'cards' && item.image_url" class="flex-shrink-0 w-14 rounded-md overflow-hidden border border-slate-200" style="aspect-ratio: 16/9">
                                    <img :src="item.image_url" :alt="item.name" class="w-full h-full object-cover" />
                                </div>
                                <div v-else-if="normalizedMode === 'cards'" class="flex-shrink-0 w-14 bg-cyan-50 rounded-md border border-cyan-200 border-dashed flex items-center justify-center" style="aspect-ratio: 16/9">
                                    <i class="pi pi-image text-cyan-300 text-xs"></i>
                                </div>
                                <div v-else class="flex-shrink-0 w-9 h-9 bg-blue-50 rounded-md flex items-center justify-center">
                                    <i class="pi pi-file text-blue-400 text-sm"></i>
                                </div>

                                <!-- Item Info -->
                                <div class="flex-1 min-w-0">
                                    <div class="font-medium text-slate-900 text-sm truncate">{{ item.name }}</div>
                                    <div v-if="item.content" class="text-xs text-slate-500 truncate">
                                        {{ stripMarkdown(item.content) }}
                                    </div>
                                </div>
                            </div>
                        </div>
                    </template>
                </draggable>
            </div>
        </div>
    
        <!-- Content Item Details View -->
        <div class="xl:col-span-3 bg-white rounded-xl shadow-lg border border-slate-200 flex flex-col overflow-hidden">
            <div class="p-3 sm:p-4 border-b border-slate-200">
                <div class="flex items-center justify-between gap-2">
                    <div class="min-w-0">
                        <h3 class="text-base font-semibold text-slate-900 truncate">
                            {{ currentSelectedItemData ? currentSelectedItemData.name : $t('content.content_details') }}
                        </h3>
                        <p v-if="currentSelectedItemData" class="text-xs text-slate-400">
                            {{ currentSelectedItemData.parent_id ? $t('content.sub_item') : $t('content.parent_item') }}
                        </p>
                    </div>
                    <div v-if="currentSelectedItemData" class="flex gap-1 flex-shrink-0">
                        <Button icon="pi pi-pencil" size="small" text rounded @click="() => openEditDialog(currentSelectedItemData)" v-tooltip.top="$t('common.edit')" />
                        <Button icon="pi pi-trash" severity="danger" size="small" text rounded @click="() => confirmDeleteContentItem(currentSelectedItemData.id, currentSelectedItemData.name, currentSelectedItemData.parent_id ? 'sub-item' : 'content item')" v-tooltip.top="$t('common.delete')" />
                    </div>
                </div>
            </div>
            <div class="flex-1 p-4">
                <!-- Empty State (when no item ID is selected) -->
                <div v-if="!selectedContentItem" class="flex flex-col items-center justify-center h-full text-center">
                    <i class="pi pi-file-edit text-3xl text-slate-300 mb-3"></i>
                    <p class="text-sm text-slate-500">{{ $t('content.select_content_item') }}</p>
                    <p class="text-xs text-slate-400 mt-1">{{ $t('content.choose_item_to_view') }}</p>
                </div>
                
                <!-- Content Details (when an item ID is selected) -->
                <template v-else>
                    <div v-if="currentSelectedItemData" class="h-full">
                         <CardContentView 
                            :contentItem="currentSelectedItemData" 
                            :cardAiEnabled="props.cardAiEnabled"
                            :contentMode="contentMode"
                            :isGrouped="effectiveIsGrouped"
                         />
                    </div>
                    <!-- Empty state if selectedContentItem ID is set, but data not found -->
                    <div v-else class="flex flex-col items-center justify-center h-full text-center">
                        <i class="pi pi-ghost text-3xl text-slate-300 mb-3"></i>
                        <p class="text-sm text-slate-500">{{ $t('content.item_not_found') }}</p>
                        <p class="text-xs text-slate-400 mt-1">{{ $t('content.item_not_found_description') }}</p>
                    </div>
                </template>
            </div>
        </div>

        <!-- Add Content Dialog -->
        <MyDialog 
            v-model="showAddSerieDialog"
            modal
            :header="addDialogHeader"
            :confirmHandle="handleAddContentItem"
            :confirmLabel="addDialogConfirmLabel"
            :confirmClass="addDialogButtonClass"
            successMessage="Content item added successfully!"
            :errorMessage="$t('messages.operation_failed')"
            @hide="onAddDialogHide"
        >
            <CardContentCreateEditForm ref="cardContentCreateFormRef" mode="create" :cardId="cardId" :cardAiEnabled="cardAiEnabled" :contentMode="contentMode" :isGrouped="effectiveIsGrouped" />
        </MyDialog>

        <!-- Add Sub-item Dialog (Items in Grouped mode) -->
        <MyDialog 
            v-model="showAddItemDialog"
            modal
            :header="effectiveIsGrouped ? $t('content.add_item') : $t('content.add_sub_item')"
            :confirmHandle="handleAddSubItem"
            :confirmLabel="effectiveIsGrouped ? $t('content.add_item') : $t('content.add_sub_item')"
            :confirmClass="effectiveIsGrouped ? 'bg-amber-600 hover:bg-amber-700 text-white border-0' : 'bg-blue-600 hover:bg-blue-700 text-white border-0'"
            successMessage="Sub-item added successfully!"
            :errorMessage="$t('messages.operation_failed')"
            @hide="onAddSubItemDialogHide"
        >
            <CardContentCreateEditForm ref="cardContentSubItemCreateFormRef" mode="create" :cardId="cardId" :parentId="parentItemId" :cardAiEnabled="cardAiEnabled" :contentMode="contentMode" :isGrouped="effectiveIsGrouped" />
        </MyDialog>

        <!-- Edit Content Dialog -->
        <MyDialog 
            v-model="showEditDialog"
            modal
            :header="$t('content.edit_content_item')"
            :confirmHandle="handleEditContentItem"
            :confirmLabel="$t('content.update_content')"
            confirmClass="bg-blue-600 hover:bg-blue-700 text-white border-0"
            successMessage="Content item updated successfully!"
            :errorMessage="$t('messages.operation_failed')"
            @hide="onEditDialogHide"
        >
            <CardContentCreateEditForm ref="cardContentEditFormRef" mode="edit" :cardId="cardId" :contentItem="editingContentItem" :cardAiEnabled="cardAiEnabled" :contentMode="contentMode" :isGrouped="effectiveIsGrouped" />
        </MyDialog>

        <!-- Confirm Dialog -->
        <ConfirmDialog group="deleteContentConfirmation"></ConfirmDialog>
    </div>
</template>

<script setup>
import { ref, onMounted, watch, computed } from 'vue';
import Button from 'primevue/button';
import Popover from 'primevue/popover';
import ProgressBar from 'primevue/progressbar';
import ToggleSwitch from 'primevue/toggleswitch';
import RadioButton from 'primevue/radiobutton';
import ConfirmDialog from 'primevue/confirmdialog';
import { useConfirm } from "primevue/useconfirm";
import draggable from 'vuedraggable';
import MyDialog from '../MyDialog.vue';
import CardContentView from './CardContentView.vue';
import CardContentCreateEditForm from './CardContentCreateEditForm.vue';
import { getContentAspectRatio } from '@/utils/cardConfig';
import { useContentItemStore } from '@/stores/contentItem';
import { useTranslationStore } from '@/stores/translation';
import { useCardStore } from '@/stores/card';
import { useToast } from 'primevue/usetoast';
import { useI18n } from 'vue-i18n';

const props = defineProps({
    cardId: {
        type: String,
        required: true
    },
    card: {
        type: Object,
        default: null
    },
    cardAiEnabled: {
        type: Boolean,
        default: false
    },
    contentMode: {
        type: String,
        default: 'list',
        validator: (value) => ['single', 'list', 'grid', 'cards'].includes(value)
    },
    isGrouped: {
        type: Boolean,
        default: false
    },
    groupDisplay: {
        type: String,
        default: 'expanded',
        validator: (value) => ['expanded', 'collapsed'].includes(value)
    }
});

const emit = defineEmits(['update-card']);

// Effective grouped state - uses local state when editing, props otherwise
const effectiveIsGrouped = computed(() => {
    return localIsGrouped.value;
});

// Content mode - uses local state
const normalizedMode = computed(() => {
    return localContentMode.value;
});

// --- Content Mode Config ---
const cardStore = useCardStore();
const isSavingMode = ref(false);
const modePopover = ref(null);

const toggleModePopover = (event) => {
    modePopover.value.toggle(event);
};

const currentModeIcon = computed(() => {
    const icons = { single: 'pi-file', list: 'pi-list', grid: 'pi-th-large', cards: 'pi-clone' };
    return icons[localContentMode.value] || 'pi-list';
});

// Header computeds
const headerIcon = computed(() => {
    if (effectiveIsGrouped.value) return 'pi pi-folder';
    const icons = { single: 'pi pi-file', list: 'pi pi-list', grid: 'pi pi-th-large', cards: 'pi pi-clone' };
    return icons[normalizedMode.value] || 'pi pi-list';
});

const headerLabel = computed(() => {
    if (effectiveIsGrouped.value) return t('content.categories_list');
    return t('dashboard.mode_' + normalizedMode.value);
});

const headerCountText = computed(() => {
    if (displayItemsCount.value === 0) return '';
    if (effectiveIsGrouped.value) return `(${contentItems.value.length} / ${totalChildItems.value})`;
    return `(${displayItemsCount.value})`;
});

// Local state for mode configuration
const localContentMode = ref(props.contentMode);
const localIsGrouped = ref(props.isGrouped);
const localGroupDisplay = ref(props.groupDisplay);

// Sync local state when props change (e.g., after save, parent re-renders)
watch(() => props.contentMode, (v) => { localContentMode.value = v; });
watch(() => props.isGrouped, (v) => { localIsGrouped.value = v; });
watch(() => props.groupDisplay, (v) => { localGroupDisplay.value = v; });

// Reset grouping when switching to single mode
watch(localContentMode, (newMode) => {
    if (newMode === 'single') {
        localIsGrouped.value = false;
        localGroupDisplay.value = 'expanded';
    }
});

const hasUnsavedModeChanges = computed(() => {
    return localContentMode.value !== props.contentMode
        || localIsGrouped.value !== props.isGrouped
        || localGroupDisplay.value !== props.groupDisplay;
});

const currentModeSupportsGrouping = computed(() => {
    return localContentMode.value !== 'single';
});

const saveModeConfig = async () => {
    if (!props.card) return;
    isSavingMode.value = true;
    try {
        await cardStore.updateCard(props.card.id, {
            name: props.card.name,
            description: props.card.description,
            conversation_ai_enabled: props.card.conversation_ai_enabled,
            ai_instruction: props.card.ai_instruction,
            ai_knowledge_base: props.card.ai_knowledge_base,
            qr_code_position: props.card.qr_code_position,
            billing_type: props.card.billing_type,
            content_mode: localContentMode.value,
            is_grouped: localIsGrouped.value,
            group_display: localGroupDisplay.value,
        });
        toast.add({
            severity: 'success',
            summary: t('messages.success'),
            detail: t('messages.save_success'),
            life: 2000
        });
        emit('update-card', {
            ...props.card,
            content_mode: localContentMode.value,
            is_grouped: localIsGrouped.value,
            group_display: localGroupDisplay.value,
        });
        modePopover.value?.hide();
    } catch (err) {
        console.error('Error saving mode config:', err);
        toast.add({
            severity: 'error',
            summary: t('common.error'),
            detail: t('messages.operation_failed'),
            life: 3000
        });
    } finally {
        isSavingMode.value = false;
    }
};

const resetModeConfig = () => {
    localContentMode.value = props.contentMode;
    localIsGrouped.value = props.isGrouped;
    localGroupDisplay.value = props.groupDisplay;
    modePopover.value?.hide();
};

const contentModeOptions = [
    { value: 'single', icon: 'pi-file' },
    { value: 'list', icon: 'pi-list' },
    { value: 'grid', icon: 'pi-th-large' },
    { value: 'cards', icon: 'pi-clone' },
];


const contentItemStore = useContentItemStore();
const translationStore = useTranslationStore();
const toast = useToast();
const confirm = useConfirm();
const { t } = useI18n();

const selectedContentItem = ref(null);
const showAddSerieDialog = ref(false);
const showAddItemDialog = ref(false);
const showEditDialog = ref(false);
const expandContentItems = ref([]);
const contentItems = ref([]);
const parentItemId = ref(null);
const editingContentItem = ref(null);
const dragHintDismissed = ref(false);
const isDragging = ref(false);

const cardContentCreateFormRef = ref(null);
const cardContentSubItemCreateFormRef = ref(null);
const cardContentEditFormRef = ref(null);

// ===== MULTI-SELECT MODE (Bulk Delete) =====
const selectMode = ref(false);
const selectedItemIds = ref(new Set());

// Get all selectable item IDs (flat list of all items including children)
const allSelectableItemIds = computed(() => {
    const ids = [];
    if (effectiveIsGrouped.value) {
        // In grouped mode, select child items (leaf items)
        contentItems.value.forEach(parent => {
            if (parent.children && parent.children.length > 0) {
                parent.children.forEach(child => ids.push(child.id));
            } else {
                // Categories with no children can also be selected
                ids.push(parent.id);
            }
        });
    } else {
        // In flat mode, select the displayed items
        displayItems.value.forEach(item => ids.push(item.id));
    }
    return ids;
});

const allSelectableSelected = computed(() => {
    if (allSelectableItemIds.value.length === 0) return false;
    return allSelectableItemIds.value.every(id => selectedItemIds.value.has(id));
});

const enterSelectMode = () => {
    selectMode.value = true;
    selectedItemIds.value = new Set();
};

const exitSelectMode = () => {
    selectMode.value = false;
    selectedItemIds.value = new Set();
};

const toggleItemSelection = (itemId) => {
    const newSet = new Set(selectedItemIds.value);
    if (newSet.has(itemId)) {
        newSet.delete(itemId);
    } else {
        newSet.add(itemId);
    }
    selectedItemIds.value = newSet;
};

const toggleSelectAll = () => {
    if (allSelectableSelected.value) {
        selectedItemIds.value = new Set();
    } else {
        selectedItemIds.value = new Set(allSelectableItemIds.value);
    }
};

const confirmBulkDelete = () => {
    const count = selectedItemIds.value.size;
    confirm.require({
        group: 'deleteContentConfirmation',
        message: t('content.bulk_delete_confirm', { count }),
        header: t('content.bulk_delete_title'),
        icon: 'pi pi-exclamation-triangle',
        acceptLabel: t('content.delete_items', { count }),
        rejectLabel: t('common.cancel'),
        acceptClass: 'p-button-danger',
        accept: async () => {
            await executeBulkDelete();
        }
    });
};

const executeBulkDelete = async () => {
    const itemIds = Array.from(selectedItemIds.value);
    const result = await contentItemStore.bulkDeleteContentItems(itemIds, props.cardId);

    if (result.success) {
        toast.add({
            severity: 'success',
            summary: t('messages.success'),
            detail: t('content.bulk_delete_success', { count: result.deletedCount }),
            life: 3000
        });

        // Clear selection if deleted items include the currently selected item
        if (selectedContentItem.value && selectedItemIds.value.has(selectedContentItem.value)) {
            selectedContentItem.value = null;
        }

        // Reload content items
        await loadContentItems();

        // Refetch translation status
        await translationStore.fetchTranslationStatus(props.cardId);

        // Exit select mode
        exitSelectMode();
    } else {
        toast.add({
            severity: 'error',
            summary: t('common.error'),
            detail: contentItemStore.error || t('content.bulk_delete_failed'),
            life: 5000
        });
    }
};

// Computed property for the actual selected content item data object
const currentSelectedItemData = computed(() => {
    if (!selectedContentItem.value) {
        return null;
    }
    for (const parent of contentItems.value) {
        if (parent.id === selectedContentItem.value) {
            return parent;
        }
        if (parent.children) {
            const child = parent.children.find(child => child.id === selectedContentItem.value);
            if (child) return child;
        }
    }
    return null;
});

// Computed property to count total child items
const totalChildItems = computed(() => {
    return contentItems.value.reduce((total, parent) => {
        return total + (parent.children?.length || 0);
    }, 0);
});

// Computed property for display items based on mode
// Flat mode: Show only layer 2 items (children) flattened
// Grouped mode: Show layer 1 items (categories) with their children
const displayItems = computed(() => {
    if (effectiveIsGrouped.value) {
        // Grouped mode: return categories with children (normal hierarchical view)
        return contentItems.value;
    } else {
        // Flat mode: flatten all layer 2 items (children) into a single list
        const flatItems = [];
        contentItems.value.forEach(parent => {
            if (parent.children && parent.children.length > 0) {
                flatItems.push(...parent.children);
            }
        });
        
        // FALLBACK: If no children found but we have parent items,
        // display the parent items directly (legacy data or import issue)
        if (flatItems.length === 0 && contentItems.value.length > 0) {
            console.log('Flat mode fallback: displaying Layer 1 items directly (no children found)');
            return contentItems.value.sort((a, b) => (a.sort_order || 0) - (b.sort_order || 0));
        }
        
        // Sort by sort_order
        return flatItems.sort((a, b) => (a.sort_order || 0) - (b.sort_order || 0));
    }
});

// Writable computed for flat mode draggable
// This allows v-model binding while maintaining the underlying data structure
const flatDisplayItems = computed({
    get() {
        return displayItems.value;
    },
    set(newOrder) {
        // Update the order in the underlying contentItems structure
        // For flat mode, items could be children of different parents
        // We need to update sort_order for each item
        newOrder.forEach((item, index) => {
            item.sort_order = index + 1;
        });
    }
});

// Count of items to display
const displayItemsCount = computed(() => {
    if (effectiveIsGrouped.value) {
        return contentItems.value.length; // Categories count
    } else {
        return displayItems.value.length; // Flattened items count
    }
});

// Mode-specific dialog configuration
const addDialogHeader = computed(() => {
    const mode = normalizedMode.value;
    const isGroupedContent = effectiveIsGrouped.value;
    
    // If content is grouped, add categories
    if (isGroupedContent && mode !== 'single') {
        return t('content.add_category');
    }
    
    switch (mode) {
        case 'single': return t('content.add_page_content');
        case 'list': return t('content.add_list_item');
        case 'grid': return t('content.add_gallery_item');
        case 'cards': return t('content.add_card');
        default: return t('content.add_content_item');
    }
});

const addDialogConfirmLabel = computed(() => {
    const mode = normalizedMode.value;
    const isGroupedContent = effectiveIsGrouped.value;
    
    // If content is grouped, add categories
    if (isGroupedContent && mode !== 'single') {
        return t('content.add_category');
    }
    
    switch (mode) {
        case 'single': return t('content.add_content');
        case 'list': return t('content.add_item');
        case 'grid': return t('content.add_item');
        case 'cards': return t('content.add_card');
        default: return t('content.add_content');
    }
});

const addDialogButtonClass = computed(() => {
    return 'bg-blue-600 hover:bg-blue-700 text-white border-0';
});


// Empty state message
const emptyStateMessage = computed(() => {
    const isGroupedContent = effectiveIsGrouped.value;
    if (isGroupedContent && normalizedMode.value !== 'single') {
        return t('content.grouped_mode_empty_desc');
    }
    switch (normalizedMode.value) {
        case 'single': return t('content.single_mode_empty_desc');
        case 'list': return t('content.list_mode_empty_desc');
        case 'grid': return t('content.grid_mode_empty_desc');
        case 'cards': return t('content.inline_mode_empty_desc');
        default: return t('content.empty_content_desc');
    }
});

// Helper function to detect link type and return appropriate icon
const getLinkIcon = (url) => {
    if (!url) return 'pi-link';
    const urlLower = url.toLowerCase();
    if (urlLower.includes('instagram')) return 'pi-instagram';
    if (urlLower.includes('facebook')) return 'pi-facebook';
    if (urlLower.includes('twitter') || urlLower.includes('x.com')) return 'pi-twitter';
    if (urlLower.includes('linkedin')) return 'pi-linkedin';
    if (urlLower.includes('youtube')) return 'pi-youtube';
    if (urlLower.includes('tiktok')) return 'pi-video';
    if (urlLower.includes('github')) return 'pi-github';
    if (urlLower.includes('whatsapp') || urlLower.includes('wa.me')) return 'pi-whatsapp';
    if (urlLower.includes('telegram') || urlLower.includes('t.me')) return 'pi-telegram';
    if (urlLower.includes('discord')) return 'pi-discord';
    if (urlLower.includes('spotify')) return 'pi-spotify';
    if (urlLower.includes('mailto:')) return 'pi-envelope';
    if (urlLower.includes('tel:')) return 'pi-phone';
    if (urlLower.match(/\.(pdf|doc|docx|xls|xlsx)$/)) return 'pi-file';
    return 'pi-external-link';
};

// Helper function to strip markdown for preview
const stripMarkdown = (text) => {
    if (!text) return '';
    return text
        .replace(/#{1,6}\s?/g, '') // headers
        .replace(/\*\*(.+?)\*\*/g, '$1') // bold
        .replace(/\*(.+?)\*/g, '$1') // italic
        .replace(/\[(.+?)\]\(.+?\)/g, '$1') // links
        .replace(/`(.+?)`/g, '$1') // code
        .replace(/>\s?/g, '') // blockquotes
        .replace(/[-*+]\s/g, '') // list items
        .replace(/\n/g, ' ') // newlines
        .trim()
        .substring(0, 100);
};

// Load content items when component mounts
onMounted(async () => {
    // Set up CSS custom property for content aspect ratio
    const aspectRatio = getContentAspectRatio();
    document.documentElement.style.setProperty('--content-aspect-ratio', aspectRatio);
    
    // Content items will be loaded by the cardId watcher
});

// Function to load content items with proper ordering
const loadContentItems = async () => {
    try {
        console.log('Loading content items for card:', props.cardId);
        const items = await contentItemStore.getContentItems(props.cardId);
        
        // Process items to create a hierarchical structure with ordering
        const parentItems = items
            .filter(item => !item.parent_id)
            .sort((a, b) => a.sort_order - b.sort_order);
        
        // Add children to parent items with ordering
        parentItems.forEach(parent => {
            parent.children = items
                .filter(item => item.parent_id === parent.id)
                .sort((a, b) => a.sort_order - b.sort_order);
        });
        
        contentItems.value = parentItems;
    } catch (error) {
        console.error('Error loading content items:', error);
        toast.add({ severity: 'error', summary: t('messages.operation_failed'), detail: t('content.failed_to_load_items'), life: 3000 });
    }
};

// Handle parent (content item) drag end
const onParentDragEnd = async (evt) => {
    const { newIndex, oldIndex } = evt;
    if (newIndex !== oldIndex) {
        const movedItem = contentItems.value[newIndex];
        await contentItemStore.updateContentItemOrder(movedItem.id, newIndex + 1);
        await loadContentItems(); // Refresh to ensure consistency
    }
};

// Handle child (sub-item) drag end (within same parent)
const onChildDragEnd = async (evt, parentId) => {
    const { newIndex, oldIndex } = evt;
    if (newIndex !== oldIndex) {
        const parent = contentItems.value.find(p => p.id === parentId);
        if (parent && parent.children) {
            const movedItem = parent.children[newIndex];
            await contentItemStore.updateContentItemOrder(movedItem.id, newIndex + 1);
            await loadContentItems(); // Refresh to ensure consistency
        }
    }
};

// Handle flat mode item drag end
const onFlatItemDragEnd = async (evt) => {
    const { newIndex, oldIndex } = evt;
    if (newIndex !== oldIndex) {
        const items = flatDisplayItems.value;
        const movedItem = items[newIndex];
        
        if (movedItem) {
            try {
                // Update the sort order for the moved item
                await contentItemStore.updateContentItemOrder(movedItem.id, newIndex + 1);
                await loadContentItems(); // Refresh to ensure consistency
                
                toast.add({
                    severity: 'success',
                    summary: t('messages.success'),
                    detail: t('content.order_updated'),
                    life: 2000
                });
            } catch (error) {
                console.error('Error updating item order:', error);
                toast.add({
                    severity: 'error',
                    summary: t('messages.operation_failed'),
                    detail: t('content.failed_to_update_order'),
                    life: 3000
                });
                // Reload to restore original order
                await loadContentItems();
            }
        }
    }
};

// Handle cross-parent drag & drop
const onCrossParentChange = async (evt, targetParentId) => {
    // Only handle 'added' events (item dropped into this container from another)
    if (evt.added) {
        const movedItem = evt.added.element;
        const newIndex = evt.added.newIndex;
        
        console.log('Cross-parent move:', {
            itemId: movedItem.id,
            itemName: movedItem.name,
            newParentId: targetParentId,
            newIndex: newIndex
        });
        
        try {
            // Update the item's parent in the database
            const result = await contentItemStore.moveItemToParent(
                movedItem.id,
                targetParentId,
                newIndex + 1, // 1-based sort order
                props.cardId
            );
            
            if (result) {
                toast.add({
                    severity: 'success',
                    summary: t('messages.success'),
                    detail: t('content.item_moved_successfully'),
                    life: 2000
                });
            }
        } catch (error) {
            console.error('Error moving item to new parent:', error);
            toast.add({
                severity: 'error',
                summary: t('messages.operation_failed'),
                detail: t('content.failed_to_move_item'),
                life: 3000
            });
            // Reload to restore original state
            await loadContentItems();
        }
    }
};

// Function to open edit dialog
const openEditDialog = (item) => {
    editingContentItem.value = { ...item }; // Create a copy to avoid direct mutation
    showEditDialog.value = true;
};

// Function to handle adding a new content item
// In flat mode: Creates at layer 2 (auto-creates default category if needed)
// In grouped mode: Creates at layer 1 (category)
const handleAddContentItem = async () => {
    if (cardContentCreateFormRef.value) {
        try {
            // Get the form data from the form component
            const { formData, imageFile, croppedImageFile } = cardContentCreateFormRef.value.getFormData();
            
            // Prepare final form data with both image files
            let finalFormData = { ...formData };
            if (imageFile) {
                finalFormData.imageFile = imageFile;
            }
            if (croppedImageFile) {
                finalFormData.croppedImageFile = croppedImageFile;
            }
            
            let targetParentId = null;
            
            // In flat mode, items go to layer 2 (need a parent category)
            if (!effectiveIsGrouped.value) {
                // Check if we have any categories
                if (contentItems.value.length === 0) {
                    // Auto-create a default category first
                    const defaultCategory = await contentItemStore.createContentItem(props.cardId, {
                        name: t('dashboard.default_category_name'),
                        description: ''
                    });
                    if (defaultCategory) {
                        await loadContentItems();
                        targetParentId = defaultCategory.id;
                    }
                } else {
                    // Use the first category as parent
                    targetParentId = contentItems.value[0].id;
                }
            }
            
            // Create the content item
            const result = await contentItemStore.createContentItem(props.cardId, finalFormData, targetParentId);
            
            if (result) {
                // Reload content items
                await loadContentItems();
                
                // Refetch translation status (content hash changed)
                await translationStore.fetchTranslationStatus(props.cardId);
                
                // Reset the form
                cardContentCreateFormRef.value.resetForm();
                return Promise.resolve();
            } else {
                return Promise.reject('Failed to create content item');
            }
        } catch (error) {
            console.error('Error in handleAddContentItem:', error);
            return Promise.reject(error);
        }
    } else {
        return Promise.reject('Form component not ready');
    }
};

// Function to handle adding a new sub-item to a content item
const handleAddSubItem = async () => {
    if (cardContentSubItemCreateFormRef.value && parentItemId.value) {
        try {
            // Get the form data from the form component
            const { formData, imageFile, croppedImageFile } = cardContentSubItemCreateFormRef.value.getFormData();
            
            // Prepare final form data with both image files
            let finalFormData = { ...formData };
            if (imageFile) {
                finalFormData.imageFile = imageFile;
            }
            if (croppedImageFile) {
                finalFormData.croppedImageFile = croppedImageFile;
            }
            
            // Create the sub-item (store will handle image uploads)
            const result = await contentItemStore.createContentItem(props.cardId, finalFormData, parentItemId.value);
            
            if (result) {
                // Reload content items
                await loadContentItems();
                
                // Refetch translation status (content hash changed)
                await translationStore.fetchTranslationStatus(props.cardId);
                
                // Reset the form
                cardContentSubItemCreateFormRef.value.resetForm();
                
                // Clear parent ID
                parentItemId.value = null;
                return Promise.resolve();
            } else {
                return Promise.reject('Failed to create sub-item');
            }
        } catch (error) {
            console.error('Error in handleAddSubItem:', error);
            return Promise.reject(error);
        }
    } else {
        return Promise.reject('Form component not ready or no parent selected');
    }
};

// Function to handle editing a content item
const handleEditContentItem = async () => {
    if (cardContentEditFormRef.value && editingContentItem.value) {
        try {
            // Get the form data from the form component
            const { formData, imageFile, croppedImageFile } = cardContentEditFormRef.value.getFormData();
            
            // Prepare final form data with both image files
            let finalFormData = { ...formData };
            if (imageFile) {
                finalFormData.imageFile = imageFile;
            }
            if (croppedImageFile) {
                finalFormData.croppedImageFile = croppedImageFile;
            }
            
            // Update the content item (store will handle image uploads)
            const result = await contentItemStore.updateContentItem(
                editingContentItem.value.id,
                finalFormData,
                props.cardId
            );
            
            if (result) {
                // Reload content items
                await loadContentItems();
                
                // Refetch translation status (content hash changed)
                await translationStore.fetchTranslationStatus(props.cardId);
                
                // Clear editing item
                editingContentItem.value = null;
                return Promise.resolve();
            } else {
                return Promise.reject('Failed to update content item');
            }
        } catch (error) {
            console.error('Error in handleEditContentItem:', error);
            return Promise.reject(error);
        }
    } else {
        return Promise.reject('Form component not ready or no item selected');
    }
};

// Function to confirm and delete a content item
const confirmDeleteContentItem = (itemId, itemName, itemType) => {
    confirm.require({
        group: 'deleteContentConfirmation',
        message: t('messages.confirm_delete_item', { itemType, itemName }),
        header: t('messages.confirm_deletion_title', { itemType }),
        icon: 'pi pi-exclamation-triangle',
        acceptLabel: t('common.delete'),
        rejectLabel: t('common.cancel'),
        acceptClass: 'p-button-danger',
        accept: async () => {
            await deleteContentItem(itemId);
        }
    });
};

// Function to delete a content item
const deleteContentItem = async (itemId) => {
    try {
        await contentItemStore.deleteContentItem(itemId, props.cardId);
        
        // If the deleted item was selected, clear selection
        if (selectedContentItem.value === itemId) {
            selectedContentItem.value = null;
        }
        
        // Reload content items
        await loadContentItems();
        
        // Refetch translation status (content hash changed)
        await translationStore.fetchTranslationStatus(props.cardId);
        
        // Success feedback provided by visual removal from list
    } catch (error) {
        console.error('Error deleting content item:', error);
        toast.add({ severity: 'error', summary: t('messages.operation_failed'), detail: t('content.failed_to_delete_item'), life: 3000 });
    }
};

// Dialog hide handlers
const onAddDialogHide = () => {
    showAddSerieDialog.value = false;
    if (cardContentCreateFormRef.value) {
        cardContentCreateFormRef.value.resetForm();
    }
};

const onAddSubItemDialogHide = () => {
    showAddItemDialog.value = false;
    parentItemId.value = null;
    if (cardContentSubItemCreateFormRef.value) {
        cardContentSubItemCreateFormRef.value.resetForm();
    }
};

const onEditDialogHide = () => {
    showEditDialog.value = false;
    editingContentItem.value = null;
    if (cardContentEditFormRef.value) {
        cardContentEditFormRef.value.resetForm();
    }
};

// Watch for changes to cardId prop
watch(() => props.cardId, async (newCardId) => {
    if (newCardId) {
        await loadContentItems();
        selectedContentItem.value = null;
    }
}, { immediate: true });
</script>

<style scoped>
.expand-enter-active,
.expand-leave-active {
    transition: all 0.3s ease;
    overflow: hidden;
}

.expand-enter-from,
.expand-leave-to {
    opacity: 0;
    max-height: 0;
}

.expand-enter-to,
.expand-leave-from {
    opacity: 1;
    max-height: 500px;
}

/* Drag and drop styling */
.sortable-ghost {
    opacity: 0.5;
}

.sortable-chosen {
    transform: scale(1.02);
}

/* Standardized button sizing to match other dialogs */
:deep(.p-button) {
    font-size: var(--font-size-sm);
    font-weight: 500;
}

:deep(.p-button-small) {
    font-size: var(--font-size-sm);
    padding: 0.5rem 0.75rem;
}

</style>