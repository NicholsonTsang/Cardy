<template>
    <div class="2xl:flex">
        <div class="border border-gray-300 p-4 2xl:w-2/5">
            <div class="flex justify-between items-center">
                <h2 class="text-lg font-bold">Card Content</h2>
                <Button size="small" @click="showAddSerieDialog = true">
                    <i class="pi pi-plus mr-2"></i>
                    Add Series
                </Button>
            </div>
            <Divider />

            <div class="h-[calc(100vh-680px)] 2xl:h-[calc(100vh-360px)] overflow-y-auto">
                <div v-for="(item, index) in contentItems" >
                <!-- Parent layer content item -->
                <div 
                    class="p-2 h-14 cursor-pointer hover:bg-gray-100 flex items-center"
                    :class="{ 'bg-gray-100': selectedContentItem === item.id }"
                    @click="() => {
                        selectedContentItem = item.id;
                        expandContentItems[index] = !expandContentItems[index];
                    }">
                    
                    <i class="pi pi-ellipsis-v ml-2 mr-3 text-gray-400" style="font-size: 0.9rem;"></i>
                    <div class="flex-1 flex items-center">
                        <i class="pi pi-angle-down mr-3" 
                            style="font-size: 0.9rem;"
                            v-if="contentItems[index].children && contentItems[index].children.length > 0"></i>
                        <div class="font-medium">{{ item.name }}</div>
                    </div>
                    
                    <Button class="mr-2" icon="pi pi-plus" severity="secondary" size="small"
                    @click.stop="() => {
                        
                    }" />
                    <Button class="mr-2" icon="pi pi-trash" severity="secondary" size="small" 
                    @click.stop="() => {
                        contentItems.splice(index, 1);
                    }" />
                </div>

                <!-- Children layer content item -->
                <div 
                v-if="expandContentItems[index]">
                    <div v-for="(child, childIndex) in contentItems[index].children">
                        <div 
                            class="p-2 h-14 cursor-pointer hover:bg-gray-100 flex items-center"
                            :class="{ 'bg-gray-100': selectedContentItem === child.id }"
                            @click="selectedContentItem = child.id">
                            <i class="pi pi-ellipsis-v ml-2 ml-8 mr-3 text-gray-400" style="font-size: 0.9rem;"></i>
                            <div class="flex-1 font-medium">{{ child.name }}</div>
                            <Button class="mr-2" icon="pi pi-trash" severity="secondary" size="small" />
                        </div>
                    </div>
                </div>
            </div>    
            </div>
        </div>
    
        <!-- Content Item Details -->
        <div class="2xl:ml-4 mt-4 2xl:mt-0 border border-gray-300 p-4 2xl:w-3/5">
            <div v-if="selectedContentItem">
                <CardContentCreateEditView :contentItem="selectedContentItem" />
            </div>
        </div>
    </div>

    <!--  -->
    <MyDialog 
            v-model="showAddSerieDialog"
            modal
            header="Create New Series"
            :confirmHandle="handleAddSeries"
            confirmLabel="Create"
            confirmSeverity="success"
            successMessage="Series created successfully!"
            errorMessage="Failed to create card"
            @hide="onDialogHide"
        >
            <!-- Pass modeProp="create" to CardCreateEditView -->
            <CardContentCreateEditView 
            ref="cardContentCreateEditRef" 
            />
        </MyDialog>
</template>

<script setup>
import { ref } from 'vue';
import Button from 'primevue/button';
import Divider from 'primevue/divider';
import MyDialog from './MyDialog.vue';
import CardContentCreateEditView from './CardContentCreateEditView.vue';


const selectedContentItem = ref(null);
const showAddSerieDialog = ref(false);
const expandContentItems = ref([]);
const contentItems = ref([
    { 
        id: 1, 
        name: 'Content Item 1', 
        description: 'This is a description of the content item',
        hiddenContent: 'This is hidden content',
        imageUrl: 'https://via.placeholder.com/150',
        additionalImages: [
            'https://via.placeholder.com/150',
            'https://via.placeholder.com/150',
            'https://via.placeholder.com/150',
        ],
        children: [
            { id: 11, name: 'Content Item 1.1', description: 'This is a description of the content item', hiddenContent: 'This is hidden content', imageUrl: 'https://via.placeholder.com/150', additionalImages: [
                'https://via.placeholder.com/150',
                'https://via.placeholder.com/150',
                'https://via.placeholder.com/150',
            ]},
            { id: 12, name: 'Content Item 1.2', description: 'This is a description of the content item', hiddenContent: 'This is hidden content', imageUrl: 'https://via.placeholder.com/150', additionalImages: [
                'https://via.placeholder.com/150',
                'https://via.placeholder.com/150',
                'https://via.placeholder.com/150',
            ]},
            { id: 13, name: 'Content Item 1.1', description: 'This is a description of the content item', hiddenContent: 'This is hidden content', imageUrl: 'https://via.placeholder.com/150', additionalImages: [
                'https://via.placeholder.com/150',
                'https://via.placeholder.com/150',
                'https://via.placeholder.com/150',
            ]},
            { id: 14, name: 'Content Item 1.2', description: 'This is a description of the content item', hiddenContent: 'This is hidden content', imageUrl: 'https://via.placeholder.com/150', additionalImages: [
                'https://via.placeholder.com/150',
                'https://via.placeholder.com/150',
                'https://via.placeholder.com/150',
            ]},
            { id: 15, name: 'Content Item 1.1', description: 'This is a description of the content item', hiddenContent: 'This is hidden content', imageUrl: 'https://via.placeholder.com/150', additionalImages: [
                'https://via.placeholder.com/150',
                'https://via.placeholder.com/150',
                'https://via.placeholder.com/150',
            ]},
            { id: 16, name: 'Content Item 1.2', description: 'This is a description of the content item', hiddenContent: 'This is hidden content', imageUrl: 'https://via.placeholder.com/150', additionalImages: [
                'https://via.placeholder.com/150',
                'https://via.placeholder.com/150',
                'https://via.placeholder.com/150',
            ]},
        ] 
    },
    { id: 2, name: 'Content Item 2' },
    { id: 3, name: 'Content Item 3' },
    { id: 4, name: 'Content Item 4' },
    { id: 5, name: 'Content Item 5' },
    { id: 6, name: 'Content Item 6' },
]);

const handleAddSeries = () => {
    console.log('handleAddSeries');
}

const onDialogHide = () => {
    showAddSerieDialog.value = false;
}


</script>