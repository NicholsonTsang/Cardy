<template>
    <div class="grid grid-cols-1 xl:grid-cols-5 gap-4 lg:gap-6">
        <!-- Content Items List -->
        <div class="xl:col-span-2 bg-white rounded-xl shadow-lg border border-slate-200 flex flex-col overflow-hidden">
            <div class="p-3 sm:p-4 border-b border-slate-200" :class="headerConfig.bgClass">
                <div class="flex justify-between items-center gap-2">
                    <div class="flex items-center gap-2 min-w-0">
                        <div class="p-2 rounded-lg" :class="headerConfig.iconBgClass">
                            <i :class="['pi', headerConfig.icon, 'text-sm', headerConfig.iconClass]"></i>
                        </div>
                        <div class="min-w-0">
                            <h2 class="text-base sm:text-lg font-semibold text-slate-900 truncate">{{ headerConfig.title }}</h2>
                            <div class="flex items-center gap-2 flex-wrap">
                                <p v-if="displayItemsCount > 0" class="text-xs text-slate-500">
                                    <template v-if="effectiveIsGrouped">
                                        {{ contentItems.length }} {{ contentItems.length === 1 ? $t('content.category') : $t('content.categories') }}
                                        <span v-if="totalChildItems > 0" class="text-slate-400">
                                            · {{ totalChildItems }} {{ $t('content.items') }}
                                        </span>
                                    </template>
                                    <template v-else>
                                        {{ displayItemsCount }} {{ displayItemsCount === 1 ? $t('content.item') : $t('content.items') }}
                                    </template>
                                </p>
                                <!-- Mode & Grouping indicator -->
                                <div class="flex items-center gap-1">
                                    <span class="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[10px] font-medium bg-slate-100 text-slate-600">
                                        <i :class="['pi', modeIndicator.icon, 'text-[8px]']"></i>
                                        {{ modeIndicator.label }}
                                    </span>
                                    <span v-if="effectiveIsGrouped" class="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[10px] font-medium bg-amber-100 text-amber-700">
                                        <i class="pi pi-folder text-[8px]"></i>
                                        {{ props.groupDisplay === 'collapsed' ? $t('dashboard.group_display_collapsed') : $t('dashboard.group_display_expanded') }}
                                    </span>
                                </div>
                            </div>
                        </div>
                    </div>
                    <Button 
                        v-if="normalizedMode !== 'single' || contentItems.length === 0"
                        :icon="headerConfig.addIcon" 
                        :label="headerConfig.addLabel" 
                        @click="showAddSerieDialog = true" 
                        size="small"
                        class="shadow-md hover:shadow-lg transition-shadow flex-shrink-0"
                        :class="headerConfig.buttonClass"
                    />
                </div>
                <!-- Mode hint for Single mode -->
                <p v-if="normalizedMode === 'single' && contentItems.length >= 1" class="text-xs text-purple-600 mt-2 flex items-center gap-1">
                    <i class="pi pi-info-circle text-xs"></i>
                    {{ $t('content.single_mode_hint') }}
                </p>
            </div>

            <!-- Content Items List -->
            <div class="flex-1 overflow-y-auto p-2 sm:p-3">
                <!-- Empty State - Mode Specific -->
                <div v-if="(effectiveIsGrouped ? contentItems.length : displayItems.length) === 0" class="flex flex-col items-center justify-center py-8 sm:py-12 text-center">
                    <div class="w-14 h-14 sm:w-16 sm:h-16 rounded-full flex items-center justify-center mb-3 sm:mb-4" :class="emptyStateConfig.bgClass">
                        <i :class="['pi', emptyStateConfig.icon, 'text-xl sm:text-2xl', emptyStateConfig.iconClass]"></i>
                    </div>
                    <h3 class="text-base sm:text-lg font-medium text-slate-900 mb-2 px-2">{{ emptyStateConfig.title }}</h3>
                    <p class="text-sm sm:text-base text-slate-500 mb-4 px-2">{{ emptyStateConfig.description }}</p>
                    <Button 
                        :icon="emptyStateConfig.buttonIcon" 
                        :label="emptyStateConfig.buttonLabel" 
                        @click="showAddSerieDialog = true"
                        :class="emptyStateConfig.buttonClass"
                    />
                </div>

                <!-- Drag Hint (dismissible, shown when items exist) -->
                <div v-if="contentItems.length > 0 && !dragHintDismissed" class="flex items-start gap-2 sm:gap-2.5 px-2.5 sm:px-3 py-2 sm:py-2.5 mb-2 sm:mb-3 bg-blue-50 border border-blue-200 rounded-lg text-xs sm:text-sm text-blue-700">
                    <i class="pi pi-info-circle text-blue-600 mt-0.5 flex-shrink-0 text-xs sm:text-sm"></i>
                    <span class="leading-relaxed flex-1">
                        {{ $t('content.drag_tip') }}
                    </span>
                    <button 
                        @click="dragHintDismissed = true"
                        class="flex-shrink-0 text-blue-600 hover:text-blue-800 transition-colors"
                        :title="$t('common.close')"
                    >
                        <i class="pi pi-times text-xs"></i>
                    </button>
                </div>

                <!-- Content Items - Grouped Mode (show categories) -->
                <draggable 
                    v-if="effectiveIsGrouped"
                    v-model="contentItems" 
                    @end="onParentDragEnd"
                    item-key="id"
                    handle=".parent-drag-handle"
                    class="space-y-2 sm:space-y-3"
                >
                    <template #item="{ element: item, index }">
                        <div class="group">
                            <!-- ========== SINGLE MODE: Full Page Content ========== -->
                            <div 
                                v-if="normalizedMode === 'single'"
                                class="relative rounded-lg border transition-all duration-200 overflow-hidden bg-white hover:shadow-md"
                                :class="selectedContentItem === item.id 
                                    ? 'border-purple-500 border-l-4 shadow-md' 
                                    : 'border-slate-200 hover:border-purple-300'"
                            >
                                <div class="flex items-start gap-3 p-3">
                                    <!-- Page Icon -->
                                    <div 
                                        class="flex-shrink-0 w-12 h-12 bg-purple-100 rounded-lg flex items-center justify-center cursor-pointer"
                                        @click="selectedContentItem = item.id"
                                    >
                                        <i class="pi pi-file text-purple-600 text-lg"></i>
                                    </div>
                                    
                                    <!-- Page Info -->
                                    <div 
                                        class="flex-1 min-w-0 cursor-pointer"
                                        @click="selectedContentItem = item.id"
                                    >
                                        <div class="font-medium text-slate-900 truncate">{{ item.name }}</div>
                                        <div v-if="item.content" class="text-xs text-slate-500 line-clamp-2 mt-0.5">
                                            {{ stripMarkdown(item.content) }}
                                            </div>
                                        </div>
                                </div>
                                        </div>
                                        
                            <!-- ========== GROUPED MODE: Category Header ========== -->
                            <div 
                                v-else-if="effectiveIsGrouped"
                                class="relative rounded-lg border transition-all duration-200 overflow-hidden bg-white hover:shadow-md"
                                :class="selectedContentItem === item.id 
                                    ? 'border-orange-500 border-l-4 shadow-md' 
                                    : 'border-slate-200 hover:border-orange-300'"
                            >
                                <div class="flex items-start gap-3 p-3">
                                    <!-- Drag Handle -->
                                    <div 
                                        class="flex-shrink-0 flex items-center justify-center w-6 h-6 mt-1 rounded hover:bg-slate-100 cursor-move parent-drag-handle"
                                        @click.stop
                                    >
                                        <i class="pi pi-bars text-slate-400 text-xs"></i>
                                            </div>
                                    
                                    <!-- Category Icon -->
                                    <div 
                                        class="flex-shrink-0 w-10 h-10 bg-orange-100 rounded-lg flex items-center justify-center cursor-pointer"
                                        @click="selectedContentItem = item.id"
                                    >
                                        <i class="pi pi-folder text-orange-600"></i>
                                            </div>
                                    
                                    <!-- Category Info -->
                                    <div 
                                        class="flex-1 min-w-0 cursor-pointer"
                                        @click="() => { selectedContentItem = item.id; expandContentItems[index] = !expandContentItems[index]; }"
                                    >
                                        <div class="font-semibold text-slate-900 truncate">{{ item.name }}</div>
                                        <div class="text-xs text-slate-500 mt-0.5">
                                            <span v-if="item.children && item.children.length > 0">
                                                {{ item.children.length }} {{ $t('content.items_count') }}
                                            </span>
                                            <span v-else class="text-amber-600">
                                                {{ $t('content.no_items_yet') }}
                                            </span>
                                        </div>
                                    </div>
                                    
                                    <!-- Expand/Collapse -->
                                    <button
                                        v-if="item.children && item.children.length > 0"
                                        class="flex-shrink-0 w-6 h-6 mt-1 flex items-center justify-center rounded hover:bg-slate-100"
                                        @click.stop="expandContentItems[index] = !expandContentItems[index]"
                                    >
                                        <i :class="expandContentItems[index] ? 'pi pi-chevron-up' : 'pi pi-chevron-down'" class="text-slate-500 text-xs"></i>
                                    </button>
                                </div>
                                
                                <!-- Add Item Button -->
                                <div class="px-3 pb-3 border-t border-slate-100">
                                    <Button 
                                        icon="pi pi-plus" 
                                        :label="$t('content.add_item')"
                                        severity="secondary" 
                                        outlined
                                        size="small"
                                        class="w-full mt-2 text-xs"
                                        @click.stop="() => { showAddItemDialog = true; parentItemId = item.id; }" 
                                    />
                                </div>
                            </div>

                            <!-- ========== LIST MODE: Simple List Item ========== -->
                            <div 
                                v-else-if="normalizedMode === 'list' && !effectiveIsGrouped"
                                class="relative rounded-lg border transition-all duration-200 overflow-hidden bg-white hover:shadow-md"
                                :class="selectedContentItem === item.id 
                                    ? 'border-blue-500 border-l-4 shadow-md bg-blue-50/30' 
                                    : 'border-slate-200 hover:border-blue-300'"
                            >
                                <div class="flex items-center gap-3 p-3">
                                    <!-- Drag Handle -->
                                    <div 
                                        class="flex-shrink-0 flex items-center justify-center w-6 h-6 rounded hover:bg-slate-100 cursor-move parent-drag-handle"
                                        @click.stop
                                    >
                                        <i class="pi pi-bars text-slate-400 text-xs"></i>
                                    </div>
                                    
                                    <!-- List Icon -->
                                    <div class="flex-shrink-0 w-10 h-10 bg-blue-100 rounded-lg flex items-center justify-center">
                                        <i :class="['pi', getLinkIcon(item.content), 'text-blue-600']"></i>
                                    </div>
                                    
                                    <!-- Item Info -->
                                    <div 
                                        class="flex-1 min-w-0 cursor-pointer"
                                        @click="selectedContentItem = item.id"
                                    >
                                        <div class="font-medium text-slate-900 truncate">{{ item.name }}</div>
                                        <div v-if="item.content" class="text-xs text-slate-500 truncate mt-0.5">
                                            {{ item.content }}
                                        </div>
                                    </div>
                                </div>
                            </div>

                            <!-- ========== GRID MODE: Gallery Item ========== -->
                            <div 
                                v-else-if="normalizedMode === 'grid' && !effectiveIsGrouped"
                                class="relative rounded-lg border transition-all duration-200 overflow-hidden bg-white hover:shadow-md"
                                :class="selectedContentItem === item.id 
                                    ? 'border-green-500 border-l-4 shadow-md' 
                                    : 'border-slate-200 hover:border-green-300'"
                            >
                                <div class="flex items-start gap-3 p-3">
                                    <!-- Drag Handle -->
                                    <div 
                                        class="flex-shrink-0 flex items-center justify-center w-6 h-6 mt-1 rounded hover:bg-slate-100 cursor-move parent-drag-handle"
                                        @click.stop
                                    >
                                        <i class="pi pi-bars text-slate-400 text-xs"></i>
                                    </div>
                                    
                                    <!-- Thumbnail (Square) -->
                                    <div 
                                        class="flex-shrink-0 cursor-pointer"
                                        @click="selectedContentItem = item.id"
                                    >
                                        <div v-if="item.image_url" class="w-14 h-14 rounded-lg overflow-hidden border border-slate-200">
                                            <img :src="item.image_url" :alt="item.name" class="w-full h-full object-cover" />
                                        </div>
                                        <div v-else class="w-14 h-14 bg-green-50 rounded-lg border border-green-200 border-dashed flex items-center justify-center">
                                            <i class="pi pi-image text-green-400"></i>
                                        </div>
                                    </div>
                                    
                                    <!-- Item Info -->
                                    <div 
                                        class="flex-1 min-w-0 cursor-pointer pt-0.5"
                                        @click="selectedContentItem = item.id"
                                    >
                                        <div class="font-medium text-slate-900 truncate">{{ item.name }}</div>
                                        <div v-if="item.content" class="text-xs text-slate-500 line-clamp-2 mt-0.5">
                                            {{ stripMarkdown(item.content) }}
                                        </div>
                                        <div v-if="!item.image_url" class="text-xs text-amber-600 mt-1">
                                            {{ $t('content.needs_photo') }}
                                        </div>
                                    </div>
                                </div>
                            </div>

                            <!-- ========== CARDS MODE: Full Card Item ========== -->
                            <div 
                                v-else-if="normalizedMode === 'cards' && !effectiveIsGrouped"
                                class="relative rounded-lg border transition-all duration-200 overflow-hidden bg-white hover:shadow-md"
                                :class="selectedContentItem === item.id 
                                    ? 'border-cyan-500 border-l-4 shadow-md' 
                                    : 'border-slate-200 hover:border-cyan-300'"
                            >
                                <div class="flex items-start gap-3 p-3">
                                    <!-- Drag Handle -->
                                    <div 
                                        class="flex-shrink-0 flex items-center justify-center w-6 h-6 mt-1 rounded hover:bg-slate-100 cursor-move parent-drag-handle"
                                        @click.stop
                                    >
                                        <i class="pi pi-bars text-slate-400 text-xs"></i>
                                    </div>
                                    
                                    <!-- Thumbnail (16:9) -->
                                    <div 
                                        class="flex-shrink-0 cursor-pointer"
                                        @click="selectedContentItem = item.id"
                                    >
                                        <div v-if="item.image_url" class="w-20 rounded-lg overflow-hidden border border-slate-200" style="aspect-ratio: 16/9">
                                            <img :src="item.image_url" :alt="item.name" class="w-full h-full object-cover" />
                                        </div>
                                        <div v-else class="w-20 bg-cyan-50 rounded-lg border border-cyan-200 border-dashed flex items-center justify-center" style="aspect-ratio: 16/9">
                                            <i class="pi pi-image text-cyan-400"></i>
                                        </div>
                                    </div>
                                    
                                    <!-- Item Info -->
                                    <div 
                                        class="flex-1 min-w-0 cursor-pointer pt-0.5"
                                        @click="selectedContentItem = item.id"
                                    >
                                        <div class="font-medium text-slate-900 truncate">{{ item.name }}</div>
                                        <div v-if="item.content" class="text-xs text-slate-500 line-clamp-2 mt-0.5">
                                            {{ stripMarkdown(item.content) }}
                                        </div>
                                    </div>
                                </div>
                            </div>

                            <!-- ========== DEFAULT MODE: Generic Item ========== -->
                            <div 
                                v-else
                                class="relative rounded-lg border border-slate-200 transition-all duration-200 overflow-hidden bg-white hover:shadow-md hover:border-blue-300"
                                :class="{ 'border-l-4 border-l-blue-500 shadow-md': selectedContentItem === item.id }"
                            >
                                <div class="flex items-start gap-3 p-3">
                                    <div class="flex-shrink-0 flex items-center justify-center w-6 h-6 mt-1 rounded hover:bg-slate-100 cursor-move parent-drag-handle" @click.stop>
                                        <i class="pi pi-bars text-slate-400 text-xs"></i>
                                    </div>
                                    <div v-if="item.image_url" class="flex-shrink-0">
                                        <div class="w-16 rounded-lg overflow-hidden border border-slate-200" style="aspect-ratio: 4/3">
                                            <img :src="item.image_url" :alt="item.name" class="w-full h-full object-cover" />
                                        </div>
                                    </div>
                                    <div v-else class="w-16 bg-slate-100 rounded-lg border border-slate-200 flex items-center justify-center flex-shrink-0" style="aspect-ratio: 4/3">
                                        <i class="pi pi-image text-slate-400"></i>
                                    </div>
                                    <div class="flex-1 min-w-0 pt-0.5 cursor-pointer" @click="() => { selectedContentItem = item.id; expandContentItems[index] = !expandContentItems[index]; }">
                                        <div class="font-medium text-slate-900 truncate">{{ item.name }}</div>
                                        <div v-if="item.children && item.children.length > 0" class="text-xs text-slate-500 mt-1">
                                            {{ $t('content.sub_items_count', { count: item.children.length }) }}
                                        </div>
                                    </div>
                                    <button v-if="item.children && item.children.length > 0" class="flex-shrink-0 w-6 h-6 mt-1 flex items-center justify-center rounded hover:bg-slate-100" @click.stop="expandContentItems[index] = !expandContentItems[index]">
                                        <i :class="expandContentItems[index] ? 'pi pi-chevron-up' : 'pi pi-chevron-down'" class="text-slate-500 text-xs"></i>
                                    </button>
                                </div>
                            </div>

                            <!-- Sub-items (for Grouped mode - Category Items) -->
                            <Transition name="expand">
                                <div v-if="expandContentItems[index] && effectiveIsGrouped" class="ml-8 mt-2 space-y-2">
                                    <draggable 
                                        v-model="item.children" 
                                        :group="{ name: 'content-items', pull: true, put: true }"
                                        @start="isDragging = true"
                                        @end="(evt) => { onChildDragEnd(evt, item.id); isDragging = false; }"
                                        @change="(evt) => onCrossParentChange(evt, item.id)"
                                        item-key="id"
                                        handle=".child-drag-handle"
                                        class="space-y-2 min-h-[40px] rounded-lg transition-colors"
                                        :class="{ 'bg-amber-50/50 border-2 border-dashed border-amber-200': isDragging }"
                                    >
                                        <template #item="{ element: child, index: childIndex }">
                                            <div 
                                                class="group relative rounded-lg border bg-white transition-all duration-200 hover:shadow-sm"
                                                :class="selectedContentItem === child.id 
                                                    ? 'border-amber-500 border-l-4 shadow-sm' 
                                                    : 'border-slate-200 hover:border-amber-300'"
                                            >
                                                <div class="flex items-center gap-2.5 p-2.5">
                                                    <!-- Drag Handle -->
                                                    <div class="flex-shrink-0 flex items-center justify-center w-5 h-5 rounded hover:bg-slate-100 cursor-move child-drag-handle" @click.stop>
                                                        <i class="pi pi-bars text-slate-400 text-[10px]"></i>
                                                    </div>
                                                    
                                                    <!-- Item Thumbnail -->
                                                    <div v-if="child.image_url" class="flex-shrink-0 w-10 h-10 rounded overflow-hidden border border-slate-200">
                                                        <img :src="child.image_url" :alt="child.name" class="w-full h-full object-cover" />
                                                    </div>
                                                    <div v-else class="flex-shrink-0 w-10 h-10 bg-amber-50 rounded flex items-center justify-center">
                                                        <i class="pi pi-box text-amber-400 text-xs"></i>
                                                    </div>
                                                    
                                                    <!-- Item Info -->
                                                    <div class="flex-1 min-w-0 cursor-pointer" @click="selectedContentItem = child.id">
                                                        <div class="font-medium text-slate-900 text-sm truncate">{{ child.name }}</div>
                                                        <div v-if="child.content" class="text-xs text-slate-500 truncate mt-0.5">
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
                                <div v-if="expandContentItems[index] && !['single', 'list', 'grid', 'cards'].includes(contentMode)" class="ml-8 mt-2 space-y-2">
                                    <draggable 
                                        v-model="item.children" 
                                        @end="(evt) => onChildDragEnd(evt, item.id)"
                                        item-key="id"
                                        handle=".child-drag-handle"
                                        class="space-y-2"
                                    >
                                        <template #item="{ element: child, index: childIndex }">
                                            <div 
                                                class="group relative rounded-lg border border-slate-200 bg-white transition-all duration-200 hover:shadow-sm hover:border-blue-300"
                                                :class="{ 'border-l-4 border-l-blue-500 shadow-sm': selectedContentItem === child.id }"
                                            >
                                                <div class="flex items-center gap-2.5 p-2.5">
                                                    <div class="flex-shrink-0 flex items-center justify-center w-5 h-5 rounded hover:bg-slate-100 cursor-move child-drag-handle" @click.stop>
                                                        <i class="pi pi-bars text-slate-400 text-[10px]"></i>
                                                    </div>
                                                    <div class="flex-shrink-0 cursor-pointer" @click="selectedContentItem = child.id">
                                                        <div v-if="child.image_url" class="w-12 rounded-md overflow-hidden border border-slate-200" style="aspect-ratio: 4/3">
                                                            <img :src="child.image_url" :alt="child.name" class="w-full h-full object-cover" />
                                                        </div>
                                                        <div v-else class="w-12 bg-slate-100 rounded-md border border-slate-200 flex items-center justify-center" style="aspect-ratio: 4/3">
                                                            <i class="pi pi-image text-slate-400 text-xs"></i>
                                                        </div>
                                                    </div>
                                                    <div class="flex-1 min-w-0 cursor-pointer" @click="selectedContentItem = child.id">
                                                        <div class="font-medium text-sm text-slate-800 truncate group-hover:text-blue-600 transition-colors">
                                                            {{ child.name }}
                                                        </div>
                                                        <div class="text-xs text-slate-500 mt-0.5">
                                                            {{ $t('content.sub_item_index', { index: childIndex + 1 }) }}
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
                    class="space-y-2 sm:space-y-3"
                >
                    <template #item="{ element: item }">
                        <div 
                            class="group relative rounded-lg border transition-all duration-200 overflow-hidden bg-white hover:shadow-md cursor-pointer"
                            :class="selectedContentItem === item.id 
                                ? 'border-blue-500 border-l-4 shadow-md' 
                                : 'border-slate-200 hover:border-blue-300'"
                            @click="selectedContentItem = item.id"
                        >
                            <div class="flex items-start gap-3 p-3">
                                <!-- Drag Handle -->
                                <div 
                                    class="flex-shrink-0 flex items-center justify-center w-6 h-6 mt-1 rounded hover:bg-slate-100 cursor-move flat-drag-handle"
                                    @click.stop
                                >
                                    <i class="pi pi-bars text-slate-400 text-xs"></i>
                                </div>
                                
                                <!-- Thumbnail based on mode -->
                                <div v-if="normalizedMode === 'grid' && item.image_url" class="flex-shrink-0 w-14 h-14 rounded-lg overflow-hidden border border-slate-200">
                                    <img :src="item.image_url" :alt="item.name" class="w-full h-full object-cover" />
                                </div>
                                <div v-else-if="normalizedMode === 'grid'" class="flex-shrink-0 w-14 h-14 bg-green-50 rounded-lg border border-green-200 border-dashed flex items-center justify-center">
                                    <i class="pi pi-image text-green-400 text-lg"></i>
                                </div>
                                <div v-else-if="normalizedMode === 'cards' && item.image_url" class="flex-shrink-0 w-20 rounded-lg overflow-hidden border border-slate-200" style="aspect-ratio: 16/9">
                                    <img :src="item.image_url" :alt="item.name" class="w-full h-full object-cover" />
                                </div>
                                <div v-else-if="normalizedMode === 'cards'" class="flex-shrink-0 w-20 bg-cyan-50 rounded-lg border border-cyan-200 border-dashed flex items-center justify-center" style="aspect-ratio: 16/9">
                                    <i class="pi pi-image text-cyan-400"></i>
                                </div>
                                <div v-else class="flex-shrink-0 w-10 h-10 bg-blue-50 rounded-lg flex items-center justify-center">
                                    <i class="pi pi-file text-blue-400"></i>
                                </div>
                                
                                <!-- Item Info -->
                                <div class="flex-1 min-w-0">
                                    <div class="font-medium text-slate-900 truncate">{{ item.name }}</div>
                                    <div v-if="item.content" class="text-xs text-slate-500 line-clamp-2 mt-0.5">
                                        {{ stripMarkdown(item.content) }}
                                    </div>
                                </div>
                            </div>
                        </div>
                    </template>
                </draggable>
                
                <!-- Empty state for flat mode with no items -->
                <div v-if="!effectiveIsGrouped && displayItems.length === 0" class="text-center py-8 text-slate-500">
                    <i class="pi pi-inbox text-3xl text-slate-300 mb-2"></i>
                    <p class="text-sm">{{ $t('content.no_content_items') }}</p>
                    <p class="text-xs text-slate-400 mt-1">{{ $t('content.add_content_hint') }}</p>
                </div>
            </div>
        </div>
    
        <!-- Content Item Details View -->
        <div class="xl:col-span-3 bg-white rounded-xl shadow-lg border border-slate-200 flex flex-col overflow-hidden">
            <div class="p-3 sm:p-4 border-b border-slate-200 bg-gradient-to-r from-slate-50 to-slate-100">
                <div class="flex items-center justify-between gap-2">
                    <div class="flex items-center gap-2 min-w-0">
                        <div class="p-2 bg-slate-200 rounded-lg">
                            <i class="pi pi-file-edit text-slate-600 text-sm"></i>
                        </div>
                        <div class="min-w-0">
                            <h3 class="text-base sm:text-lg font-semibold text-slate-900 truncate">
                                {{ currentSelectedItemData ? currentSelectedItemData.name : $t('content.content_details') }}
                            </h3>
                            <p v-if="currentSelectedItemData" class="text-xs text-slate-500">
                                {{ currentSelectedItemData.parent_id ? $t('content.sub_item') : $t('content.parent_item') }}
                            </p>
                        </div>
                    </div>
                    <div v-if="currentSelectedItemData" class="flex gap-2 flex-shrink-0">
                        <Button 
                            icon="pi pi-pencil" 
                            :label="$t('common.edit')"
                            size="small"
                            @click="() => openEditDialog(currentSelectedItemData)"
                        />
                        <Button 
                            icon="pi pi-trash" 
                            severity="danger" 
                            outlined
                            size="small"
                            @click="() => confirmDeleteContentItem(currentSelectedItemData.id, currentSelectedItemData.name, currentSelectedItemData.parent_id ? 'sub-item' : 'content item')"
                            v-tooltip.top="$t('common.delete')"
                        />
                    </div>
                </div>
            </div>
            <div class="flex-1 p-4">
                <!-- Empty State (when no item ID is selected) -->
                <div v-if="!selectedContentItem" class="flex flex-col items-center justify-center h-full text-center">
                    <div class="w-20 h-20 bg-slate-100 rounded-full flex items-center justify-center mb-4">
                        <i class="pi pi-file-edit text-3xl text-slate-400"></i>
                    </div>
                    <h3 class="text-xl font-medium text-slate-900 mb-2">{{ $t('content.select_content_item') }}</h3>
                    <p class="text-slate-500">{{ $t('content.choose_item_to_view') }}</p>
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
                         <div class="w-20 h-20 bg-slate-100 rounded-full flex items-center justify-center mb-4">
                            <i class="pi pi-ghost text-3xl text-slate-400"></i>
                         </div>
                         <h3 class="text-xl font-medium text-slate-900 mb-2">{{ $t('content.item_not_found') }}</h3>
                         <p class="text-slate-500">{{ $t('content.item_not_found_description') }}</p>
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
import Divider from 'primevue/divider';
import ConfirmDialog from 'primevue/confirmdialog';
import { useConfirm } from "primevue/useconfirm";
import draggable from 'vuedraggable';
import MyDialog from '../MyDialog.vue';
import CardContentView from './CardContentView.vue';
import CardContentCreateEditForm from './CardContentCreateEditForm.vue';
import CroppedImageDisplay from '@/components/CroppedImageDisplay.vue';
import { getContentAspectRatio } from '@/utils/cardConfig';
import { useContentItemStore } from '@/stores/contentItem';
import { useTranslationStore } from '@/stores/translation';
import { useToast } from 'primevue/usetoast';
import { useI18n } from 'vue-i18n';

const props = defineProps({
    cardId: {
        type: String,
        required: true
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

// Effective grouped state
const effectiveIsGrouped = computed(() => {
    return props.isGrouped;
});

// Content mode
const normalizedMode = computed(() => {
    return props.contentMode;
});

// Mode indicator for the header badge
const modeIndicator = computed(() => {
    switch (normalizedMode.value) {
        case 'single':
            return { icon: 'pi-file', label: t('dashboard.mode_single') };
        case 'list':
            return { icon: 'pi-list', label: t('dashboard.mode_list') };
        case 'grid':
            return { icon: 'pi-th-large', label: t('dashboard.mode_grid') };
        case 'cards':
            return { icon: 'pi-clone', label: t('dashboard.mode_cards') };
        default:
            return { icon: 'pi-list', label: t('dashboard.mode_list') };
    }
});

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
    const mode = normalizedMode.value;
    const isGroupedContent = effectiveIsGrouped.value;
    
    // If content is grouped, use orange theme
    if (isGroupedContent && mode !== 'single') {
        return 'bg-orange-600 hover:bg-orange-700 text-white border-0';
    }
    
    switch (mode) {
        case 'single': return 'bg-purple-600 hover:bg-purple-700 text-white border-0';
        case 'list': return 'bg-blue-600 hover:bg-blue-700 text-white border-0';
        case 'grid': return 'bg-green-600 hover:bg-green-700 text-white border-0';
        case 'cards': return 'bg-cyan-600 hover:bg-cyan-700 text-white border-0';
        default: return 'bg-blue-600 hover:bg-blue-700 text-white border-0';
    }
});

// Mode-specific header configuration
const headerConfig = computed(() => {
    const mode = normalizedMode.value;
    const isGroupedContent = effectiveIsGrouped.value;
    
    // If content is grouped, show category-based header
    if (isGroupedContent && mode !== 'single') {
        return {
            icon: 'pi-folder',
            iconClass: 'text-orange-600',
            iconBgClass: 'bg-orange-100',
            bgClass: 'bg-gradient-to-r from-orange-50 to-slate-50',
            title: t('content.categories_list'),
            addIcon: 'pi pi-plus',
            addLabel: t('content.add_category'),
            buttonClass: 'bg-orange-600 hover:bg-orange-700 border-orange-600'
        };
    }
    
    switch (mode) {
        case 'single':
            return {
                icon: 'pi-file',
                iconClass: 'text-purple-600',
                iconBgClass: 'bg-purple-100',
                bgClass: 'bg-gradient-to-r from-purple-50 to-slate-50',
                title: t('content.single_content'),
                addIcon: 'pi pi-plus',
                addLabel: t('content.add_content'),
                buttonClass: 'bg-purple-600 hover:bg-purple-700 border-purple-600'
            };
        case 'list':
            return {
                icon: 'pi-list',
                iconClass: 'text-blue-600',
                iconBgClass: 'bg-blue-100',
                bgClass: 'bg-gradient-to-r from-blue-50 to-slate-50',
                title: t('content.list_items'),
                addIcon: 'pi pi-plus',
                addLabel: t('content.add_list_item'),
                buttonClass: 'bg-blue-600 hover:bg-blue-700 border-blue-600'
            };
        case 'grid':
            return {
                icon: 'pi-th-large',
                iconClass: 'text-green-600',
                iconBgClass: 'bg-green-100',
                bgClass: 'bg-gradient-to-r from-green-50 to-slate-50',
                title: t('content.gallery_items'),
                addIcon: 'pi pi-plus',
                addLabel: t('content.add_gallery_item'),
                buttonClass: 'bg-green-600 hover:bg-green-700 border-green-600'
            };
        case 'cards':
            return {
                icon: 'pi-clone',
                iconClass: 'text-cyan-600',
                iconBgClass: 'bg-cyan-100',
                bgClass: 'bg-gradient-to-r from-cyan-50 to-slate-50',
                title: t('content.cards_list'),
                addIcon: 'pi pi-plus',
                addLabel: t('content.add_card'),
                buttonClass: 'bg-cyan-600 hover:bg-cyan-700 border-cyan-600'
            };
        default:
            return {
                icon: 'pi-list',
                iconClass: 'text-blue-600',
                iconBgClass: 'bg-blue-100',
                bgClass: 'bg-gradient-to-r from-blue-50 to-slate-50',
                title: t('content.content_items'),
                addIcon: 'pi pi-plus',
                addLabel: t('content.add_item'),
                buttonClass: 'bg-blue-600 hover:bg-blue-700 border-blue-600'
            };
    }
});

// Mode-specific empty state configuration
const emptyStateConfig = computed(() => {
    const mode = normalizedMode.value;
    const isGroupedContent = effectiveIsGrouped.value;
    
    // If content is grouped, show category-based empty state
    if (isGroupedContent && mode !== 'single') {
        return {
            icon: 'pi-folder',
            iconClass: 'text-orange-400',
            bgClass: 'bg-orange-100',
            title: t('content.grouped_mode_empty_title'),
            description: t('content.grouped_mode_empty_desc'),
            buttonIcon: 'pi pi-plus',
            buttonLabel: t('content.add_first_category'),
            buttonClass: 'bg-orange-600 hover:bg-orange-700 border-orange-600'
        };
    }
    
    switch (mode) {
        case 'single':
            return {
                icon: 'pi-file',
                iconClass: 'text-purple-400',
                bgClass: 'bg-purple-100',
                title: t('content.single_mode_empty_title'),
                description: t('content.single_mode_empty_desc'),
                buttonIcon: 'pi pi-plus',
                buttonLabel: t('content.add_page_content'),
                buttonClass: 'bg-purple-600 hover:bg-purple-700 border-purple-600'
            };
        case 'list':
            return {
                icon: 'pi-list',
                iconClass: 'text-blue-400',
                bgClass: 'bg-blue-100',
                title: t('content.list_mode_empty_title'),
                description: t('content.list_mode_empty_desc'),
                buttonIcon: 'pi pi-plus',
                buttonLabel: t('content.add_first_list_item'),
                buttonClass: 'bg-blue-600 hover:bg-blue-700 border-blue-600'
            };
        case 'grid':
            return {
                icon: 'pi-th-large',
                iconClass: 'text-green-400',
                bgClass: 'bg-green-100',
                title: t('content.grid_mode_empty_title'),
                description: t('content.grid_mode_empty_desc'),
                buttonIcon: 'pi pi-plus',
                buttonLabel: t('content.add_first_gallery_item'),
                buttonClass: 'bg-green-600 hover:bg-green-700 border-green-600'
            };
        case 'cards':
            return {
                icon: 'pi-clone',
                iconClass: 'text-cyan-400',
                bgClass: 'bg-cyan-100',
                title: t('content.inline_mode_empty_title'),
                description: t('content.inline_mode_empty_desc'),
                buttonIcon: 'pi pi-plus',
                buttonLabel: t('content.add_first_card'),
                buttonClass: 'bg-cyan-600 hover:bg-cyan-700 border-cyan-600'
            };
        default:
            return {
                icon: 'pi-list',
                iconClass: 'text-blue-400',
                bgClass: 'bg-blue-100',
                title: t('content.empty_content_title'),
                description: t('content.empty_content_desc'),
                buttonIcon: 'pi pi-plus',
                buttonLabel: t('content.add_first_item'),
                buttonClass: 'bg-blue-600 hover:bg-blue-700 border-blue-600'
            };
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

/* Content thumbnail with proper aspect ratio */
.content-thumbnail-container {
    width: 40px;
    height: 40px;
    aspect-ratio: var(--content-aspect-ratio, 4/3);
    width: auto;
    max-width: 40px;
    max-height: 40px;
    overflow: hidden;
}
</style>