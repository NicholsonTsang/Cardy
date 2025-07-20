<template>
    <div class="grid grid-cols-1 xl:grid-cols-5 gap-6">
        <!-- Content Items List -->
        <div class="xl:col-span-2 bg-white rounded-xl shadow-lg border border-slate-200 flex flex-col overflow-hidden">
            <div class="p-4 border-b border-slate-200 bg-gradient-to-r from-slate-50 to-slate-100">
                <div class="flex justify-between items-center">
                    <h2 class="text-lg font-semibold text-slate-900">Card Content</h2>
                    <Button 
                        icon="pi pi-plus" 
                        label="Add Content" 
                        @click="showAddSerieDialog = true" 
                        class="shadow-md hover:shadow-lg transition-shadow"
                    />
                </div>
            </div>

            <!-- Content Items List -->
            <div class="flex-1 overflow-y-auto p-3">
                <!-- Empty State -->
                <div v-if="contentItems.length === 0" class="flex flex-col items-center justify-center py-12 text-center">
                    <div class="w-16 h-16 bg-slate-100 rounded-full flex items-center justify-center mb-4">
                        <i class="pi pi-file-edit text-2xl text-slate-400"></i>
                    </div>
                    <h3 class="text-lg font-medium text-slate-900 mb-2">No Content Items</h3>
                    <p class="text-slate-500 mb-4">Create your first content item to get started</p>
                    <Button 
                        icon="pi pi-plus" 
                        label="Add Content" 
                        @click="showAddSerieDialog = true"
                    />
                </div>

                <!-- Content Items -->
                <draggable 
                    v-model="contentItems" 
                    @end="onParentDragEnd"
                    item-key="id"
                    handle=".parent-drag-handle"
                    class="space-y-3"
                >
                    <template #item="{ element: item, index }">
                        <div class="group">
                            <!-- Parent Content Item -->
                            <div 
                                class="p-4 cursor-pointer hover:bg-slate-50 flex items-center rounded-lg border border-slate-200 transition-all duration-200 hover:shadow-md hover:border-blue-300"
                                :class="{ 
                                    'bg-blue-50 border-blue-300 shadow-md': selectedContentItem === item.id,
                                    'bg-white': selectedContentItem !== item.id
                                }"
                                @click="() => {
                                    selectedContentItem = item.id;
                                    expandContentItems[index] = !expandContentItems[index];
                                }"
                            >
                                <!-- Drag Handle -->
                                <i class="pi pi-bars text-slate-400 mr-3 cursor-move parent-drag-handle hover:text-slate-600 transition-colors" 
                                   title="Drag to reorder"></i>
                                
                                <!-- Expand/Collapse Icon -->
                                <i 
                                    :class="expandContentItems[index] ? 'pi pi-angle-down' : 'pi pi-angle-right'"
                                    class="mr-3 text-slate-600 transition-transform" 
                                    v-if="item.children && item.children.length > 0"
                                ></i>
                                <div v-else class="w-4 mr-3"></div>
                                
                                <!-- Thumbnail -->
                                <div v-if="item.image_url" class="mr-3 flex-shrink-0">
                                    <img 
                                        :src="item.image_url" 
                                        :alt="item.name"
                                        class="w-10 h-10 object-cover rounded-lg border border-slate-200"
                                    />
                                </div>
                                <div v-else class="w-10 h-10 bg-slate-100 rounded-lg border border-slate-200 mr-3 flex items-center justify-center">
                                    <i class="pi pi-image text-slate-400"></i>
                                </div>
                                
                                <!-- Content Info -->
                                <div class="flex-1 min-w-0">
                                    <div class="font-medium text-slate-900 truncate group-hover:text-blue-600 transition-colors">{{ item.name }}</div>
                                    <div class="text-sm text-slate-500 flex items-center gap-2 mt-1">
                                        <span v-if="item.children && item.children.length > 0">
                                            {{ item.children.length }} sub-item{{ item.children.length !== 1 ? 's' : '' }}
                                        </span>
                                        <span v-else class="text-slate-400">No sub-items</span>
                                    </div>
                                </div>
                                
                                <!-- Action Buttons -->
                                <div class="flex gap-1 ml-2 opacity-0 group-hover:opacity-100 transition-opacity">
                                    <Button 
                                        icon="pi pi-plus" 
                                        severity="secondary" 
                                        title="Add Sub-item"
                                        class="w-8 h-8 p-0"
                                        @click.stop="() => {
                                            showAddItemDialog = true;
                                            parentItemId = item.id;
                                        }" 
                                    />
                                </div>
                            </div>

                            <!-- Sub-items -->
                            <Transition name="expand">
                                <div v-if="expandContentItems[index]" class="ml-8 mt-2 space-y-2">
                                    <draggable 
                                        v-model="item.children" 
                                        @end="(evt) => onChildDragEnd(evt, item.id)"
                                        item-key="id"
                                        handle=".child-drag-handle"
                                        class="space-y-2"
                                    >
                                        <template #item="{ element: child, index: childIndex }">
                                            <div 
                                                class="group p-3 cursor-pointer hover:bg-slate-50 flex items-center rounded-lg border border-slate-200 transition-all duration-200 hover:shadow-sm hover:border-blue-300"
                                                :class="{ 
                                                    'bg-blue-50 border-blue-300 shadow-sm': selectedContentItem === child.id,
                                                    'bg-white': selectedContentItem !== child.id
                                                }"
                                                @click="selectedContentItem = child.id"
                                            >
                                                <!-- Drag Handle -->
                                                <i class="pi pi-bars text-slate-400 mr-3 cursor-move child-drag-handle hover:text-slate-600 transition-colors"
                                                   title="Drag to reorder"></i>
                                                
                                                <!-- Thumbnail -->
                                                <div v-if="child.image_url" class="mr-3 flex-shrink-0">
                                                    <img 
                                                        :src="child.image_url" 
                                                        :alt="child.name"
                                                        class="w-8 h-8 object-cover rounded-lg border border-slate-200"
                                                    />
                                                </div>
                                                <div v-else class="w-8 h-8 bg-slate-100 rounded-lg border border-slate-200 mr-3 flex items-center justify-center">
                                                    <i class="pi pi-image text-slate-400 text-sm"></i>
                                                </div>
                                                
                                                <!-- Sub-item Info -->
                                                <div class="flex-1 min-w-0">
                                                    <div class="font-medium text-slate-800 truncate group-hover:text-blue-600 transition-colors">{{ child.name }}</div>
                                                    <div class="text-sm text-slate-500 flex items-center gap-2 mt-1">
                                                        <span>Sub-item {{ childIndex + 1 }}</span>
                                                    </div>
                                                </div>
                                                
                                                <!-- Action Buttons -->
                                                <div class="flex gap-1 ml-2 opacity-0 group-hover:opacity-100 transition-opacity">
                                                    <Button 
                                                        icon="pi pi-trash" 
                                                        severity="danger" 
                                                        title="Delete"
                                                        class="w-7 h-7 p-0"
                                                        @click.stop="() => confirmDeleteContentItem(child.id, child.name, 'sub-item')" 
                                                    />
                                                </div>
                                            </div>
                                        </template>
                                    </draggable>
                                </div>
                            </Transition>
                        </div>
                    </template>
                </draggable>
            </div>
        </div>
    
        <!-- Content Item Details View -->
        <div class="xl:col-span-3 bg-white rounded-xl shadow-lg border border-slate-200 flex flex-col overflow-hidden">
            <div class="p-4 border-b border-slate-200 bg-gradient-to-r from-slate-50 to-slate-100">
                <div class="flex items-center justify-between">
                    <h3 class="text-lg font-semibold text-slate-900">Content Details</h3>
                    <div v-if="currentSelectedItemData" class="flex gap-2">
                        <Button 
                            icon="pi pi-pencil" 
                            label="Edit"
                            severity="info" 
                            class="px-3 py-2"
                            @click="() => openEditDialog(currentSelectedItemData)"
                        />
                        <Button 
                            icon="pi pi-trash" 
                            label="Delete"
                            severity="danger" 
                            outlined
                            class="px-3 py-2"
                            @click="() => confirmDeleteContentItem(currentSelectedItemData.id, currentSelectedItemData.name, currentSelectedItemData.parent_id ? 'sub-item' : 'content item')"
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
                    <h3 class="text-xl font-medium text-slate-900 mb-2">Select a Content Item</h3>
                    <p class="text-slate-500">Choose an item from the list to view and edit its details</p>
                </div>
                
                <!-- Content Details (when an item ID is selected) -->
                <template v-else>
                    <div v-if="currentSelectedItemData" class="h-full">
                         <CardContentView :contentItem="currentSelectedItemData" />
                    </div>
                    <!-- Empty state if selectedContentItem ID is set, but data not found -->
                    <div v-else class="flex flex-col items-center justify-center h-full text-center">
                         <div class="w-20 h-20 bg-slate-100 rounded-full flex items-center justify-center mb-4">
                            <i class="pi pi-ghost text-3xl text-slate-400"></i>
                         </div>
                         <h3 class="text-xl font-medium text-slate-900 mb-2">Item Not Found</h3>
                         <p class="text-slate-500">The selected content item could not be loaded. It may have been removed.</p>
                    </div>
                </template>
            </div>
        </div>

        <!-- Add Content Dialog -->
        <MyDialog 
            v-model="showAddSerieDialog"
            modal
            header="Add Content Item"
            :confirmHandle="handleAddContentItem"
            confirmLabel="Add Content"
            confirmClass="bg-blue-600 hover:bg-blue-700 text-white border-0"
            successMessage="Content item added successfully!"
            errorMessage="Failed to add content item"
            @hide="onAddDialogHide"
        >
            <CardContentCreateEditForm ref="cardContentCreateFormRef" mode="create" :cardId="cardId" :cardAiEnabled="cardAiEnabled" />
        </MyDialog>

        <!-- Add Sub-item Dialog -->
        <MyDialog 
            v-model="showAddItemDialog"
            modal
            header="Add Sub-item"
            :confirmHandle="handleAddSubItem"
            confirmLabel="Add Sub-item"
            confirmClass="bg-blue-600 hover:bg-blue-700 text-white border-0"
            successMessage="Sub-item added successfully!"
            errorMessage="Failed to add sub-item"
            @hide="onAddSubItemDialogHide"
        >
            <CardContentCreateEditForm ref="cardContentSubItemCreateFormRef" mode="create" :cardId="cardId" :parentId="parentItemId" :cardAiEnabled="cardAiEnabled" />
        </MyDialog>

        <!-- Edit Content Dialog -->
        <MyDialog 
            v-model="showEditDialog"
            modal
            header="Edit Content Item"
            :confirmHandle="handleEditContentItem"
            confirmLabel="Update Content"
            confirmClass="bg-blue-600 hover:bg-blue-700 text-white border-0"
            successMessage="Content item updated successfully!"
            errorMessage="Failed to update content item"
            @hide="onEditDialogHide"
        >
            <CardContentCreateEditForm ref="cardContentEditFormRef" mode="edit" :cardId="cardId" :contentItem="editingContentItem" :cardAiEnabled="cardAiEnabled" />
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
import { useContentItemStore } from '@/stores/contentItem';
import { useToast } from 'primevue/usetoast';

const props = defineProps({
    cardId: {
        type: String,
        required: true
    },
    cardAiEnabled: {
        type: Boolean,
        default: false
    }
});

const contentItemStore = useContentItemStore();
const toast = useToast();
const confirm = useConfirm();

const selectedContentItem = ref(null);
const showAddSerieDialog = ref(false);
const showAddItemDialog = ref(false);
const showEditDialog = ref(false);
const expandContentItems = ref([]);
const contentItems = ref([]);
const parentItemId = ref(null);
const editingContentItem = ref(null);

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

// Load content items when component mounts
onMounted(async () => {
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
        toast.add({ severity: 'error', summary: 'Error', detail: 'Failed to load content items', life: 3000 });
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

// Handle child (sub-item) drag end
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

// Function to open edit dialog
const openEditDialog = (item) => {
    editingContentItem.value = { ...item }; // Create a copy to avoid direct mutation
    showEditDialog.value = true;
};

// Function to handle adding a new content item
const handleAddContentItem = async () => {
    if (cardContentCreateFormRef.value) {
        try {
            // Get the form data from the form component
            const { formData, imageFile } = cardContentCreateFormRef.value.getFormData();
            
            // Upload image if there's one
            let finalFormData = { ...formData };
            if (imageFile) {
                const imageUrl = await contentItemStore.uploadContentItemImage(imageFile);
                if (imageUrl) {
                    finalFormData.imageUrl = imageUrl;
                }
            }
            
            // Create the content item
            const result = await contentItemStore.createContentItem(props.cardId, finalFormData);
            
            if (result) {
                // Reload content items
                await loadContentItems();
                
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
            const { formData, imageFile } = cardContentSubItemCreateFormRef.value.getFormData();
            
            // Upload image if there's one
            let finalFormData = { ...formData };
            if (imageFile) {
                const imageUrl = await contentItemStore.uploadContentItemImage(imageFile);
                if (imageUrl) {
                    finalFormData.imageUrl = imageUrl;
                }
            }
            
            // Create the sub-item
            const result = await contentItemStore.createContentItem(props.cardId, finalFormData, parentItemId.value);
            
            if (result) {
                // Reload content items
                await loadContentItems();
                
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
            const { formData, imageFile } = cardContentEditFormRef.value.getFormData();
            
            // Upload image if there's a new one
            let finalFormData = { ...formData };
            if (imageFile) {
                const imageUrl = await contentItemStore.uploadContentItemImage(imageFile);
                if (imageUrl) {
                    finalFormData.imageUrl = imageUrl;
                }
            }
            
            // Update the content item
            const result = await contentItemStore.updateContentItem(
                editingContentItem.value.id,
                finalFormData,
                props.cardId
            );
            
            if (result) {
                // Reload content items
                await loadContentItems();
                
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
        message: `Are you sure you want to delete the ${itemType} "${itemName}"? This action cannot be undone.`,
        header: `Delete ${itemType.charAt(0).toUpperCase() + itemType.slice(1)}`,
        icon: 'pi pi-exclamation-triangle',
        acceptLabel: 'Delete',
        rejectLabel: 'Cancel',
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
        
        toast.add({ severity: 'success', summary: 'Deleted', detail: 'Content item deleted successfully', life: 3000 });
    } catch (error) {
        console.error('Error deleting content item:', error);
        toast.add({ severity: 'error', summary: 'Error', detail: 'Failed to delete content item', life: 3000 });
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

/* Override PrimeVue button font sizes */
:deep(.p-button) {
    font-size: 0.75rem;
}

:deep(.p-button-small) {
    font-size: 0.75rem;
    padding: 0.25rem 0.5rem;
}
</style>