<template>
    <div>
        <div class="flex justify-between items-center mb-4">
            <h1 class="text-2xl font-bold">Card Designs</h1>
            <Button icon="pi pi-plus" label="Add New Card" severity="primary" @click="showAddCardDialog = true" />
        </div>
        
        <!-- Add Card Dialog -->
        <MyDialog 
            v-model="showAddCardDialog"
            modal
            header="Create New Card"
            :confirmHandle="handleAddCard"
            confirmLabel="Create Card"
            confirmSeverity="success"
            successMessage="Card created successfully!"
            errorMessage="Failed to create card"
            @hide="onDialogHide"
        >
            <!-- Pass modeProp="create" to CardCreateEditView -->
            <CardCreateEditView ref="cardCreateEditRef" modeProp="create" />
        </MyDialog>

        <!-- PrimeVue ConfirmDialog for delete confirmation -->
        <ConfirmDialog group="deleteCardConfirmation"></ConfirmDialog>
        <!-- <Toast /> -->

        <div class="lg:flex lg:mb-0 lg:h-[calc(100vh-120px)]">
            <!-- Card Designs List -->
            <div class="border border-gray-300 rounded-lg p-4 lg:w-80 lg:mr-4 mb-4 lg:mb-0 flex flex-col h-[calc(100vh-380px)] lg:h-full"> 
                <h2 class="text-lg font-bold">Your Card Designs</h2>

                <IconField class="my-4">
                    <InputIcon class="pi pi-search" />
                    <InputText class="w-full" v-model="search" placeholder="Search" />
                </IconField>

                <div v-if="cards.length === 0"
                    class="border border-dashed border-gray-300 rounded-lg p-4 h-32 mt-4"
                >
                    <div class="flex flex-col justify-center items-center h-full">
                        <p class="text-gray-700 font-bold text-lg mb-4 text-center">No Card Design</p>
                        <p class="text-gray-500 text-center">Create your first card definition to get started.</p>
                    </div>
                </div>

                <div v-if="cards.length > 0" class="flex-1 overflow-y-auto">
                    
                    <div 
                        v-for="(card, index) in cards" 
                        :key="index" 
                        class="border border-gray-300 rounded-lg p-4 mb-4 cursor-pointer hover:bg-gray-100 relative"
                        :class="{ 'bg-gray-200 border-primary-500': selectedCard === index }"
                        @click="setSelectedCardId(index)"
                    >
                        <div class="flex items-center">
                            <div class="mr-3 rounded overflow-hidden flex-shrink-0 bg-gray-200 flex items-center justify-center">
                                <img
                                :src="card.image_urls && card.image_urls.length > 0 ? card.image_urls[0] : cardPlaceholder"
                                :alt="card.name"
                                class="w-16 h-24 object-cover"
                                />
                            </div>
                            <div class="flex-grow overflow-hidden">
                                <p class="text-gray-700 font-bold text-sm truncate" :title="card.name">{{ card.name }}</p>
                                <p class="text-gray-500 text-xs mb-4">Created on {{ new Date(card.created_at).toLocaleDateString() }}</p>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Card Designs Preview -->
            <div class="border border-gray-300 rounded-lg p-4 shadow-sm flex-1 overflow-y-auto">
                <div v-if="selectedCard === null"
                    class="text-gray-500 mb-4 flex flex-col justify-center items-center h-full">
                    Select a card design from the list or create a new one
                </div>

                <div v-else class="">
                    <h2 class="text-lg font-bold">{{ cards[selectedCard].name }}</h2>
                    <Tabs value="0">
                    <TabList>
                        <Tab v-for="(tabLabel, index) in tabs" :key="index" :value="index.toString()">{{ tabLabel }}</Tab>
                    </TabList>
                    <TabPanels>
                        <TabPanel v-for="(tabLabel, index) in tabs" :value="index.toString()">
                            <CardGeneral 
                                v-if="index === 0"
                                :cardProp="cards[selectedCard]"
                                @update-card="handleCardUpdateFromGeneral"
                                @cancel-edit="handleCardCancelFromGeneral"
                                @delete-card-requested="triggerDeleteConfirmation"
                            />
                            <CardContent v-if="index === 1" />
                            <CardIssurance v-if="index === 2" />
                        </TabPanel>
                    </TabPanels>
                </Tabs>
                </div>
            </div>
        </div>
    </div>
    
</template>

<script setup>
import Button from 'primevue/button';
import IconField from 'primevue/iconfield';
import InputIcon from 'primevue/inputicon';
import InputText from 'primevue/inputtext';
import { ref, onMounted, computed } from 'vue';
import cardPlaceholder from '@/assets/images/card-placeholder.jpg';
import Tabs from 'primevue/tabs';
import TabList from 'primevue/tablist';
import Tab from 'primevue/tab';
import TabPanels from 'primevue/tabpanels';
import TabPanel from 'primevue/tabpanel';
import CardGeneral from '@/components/CardGeneral.vue';
import CardContent from '@/components/CardContent.vue';
import CardIssurance from '@/components/CardIssurance.vue';
import MyDialog from '@/components/MyDialog.vue';
import CardCreateEditView from '@/components/CardCreateEditView.vue';
import { useCardStore } from '@/stores/card';
import { storeToRefs } from 'pinia';
import ConfirmDialog from 'primevue/confirmdialog';
import { useConfirm } from "primevue/useconfirm";
import { useToast } from "primevue/usetoast";
import Toast from 'primevue/toast';

const cardStore = useCardStore();
const { cards } = storeToRefs(cardStore);
const confirm = useConfirm();
const toast = useToast();

const search = ref('');
const selectedCard = ref(null);
const showAddCardDialog = ref(false);
const cardCreateEditRef = ref(null);

// Fetch cards when component mounts
onMounted(async () => {
    await cardStore.fetchCards();
});

const setSelectedCardId = (cardId) => {
    selectedCard.value = cardId;
}

const handleAddCard = async () => {
    if (!cardCreateEditRef.value) {
        console.error("CardCreateEditView reference is not available.");
        return Promise.reject("Form component not ready.");
    }
    try {
        // Get payload from the CardCreateEditView instance
        const payload = cardCreateEditRef.value.getPayload();
        if (!payload.name) { // Basic validation example
            toast.add({ severity: 'warn', summary: 'Validation Error', detail: 'Card name is required.', life: 3000 });
            return Promise.reject("Card name is required.");
        }
        
        await cardStore.addCard(payload);
        await cardStore.fetchCards(); // Refresh list
        // The Dialog component is expected to handle closing and success message
        return Promise.resolve(); 
    } catch (error) {
        console.error("Failed to add card:", error);
        // The Dialog component is expected to handle error message
        return Promise.reject(typeof error === 'string' ? error : (error.message || 'Failed to create card'));
    }
};

const onDialogHide = () => {
    if (cardCreateEditRef.value && typeof cardCreateEditRef.value.resetFormForCreate === 'function') {
        cardCreateEditRef.value.resetFormForCreate();
    }
};

// Handler for the update-card event from CardGeneral (which passes it from CardCreateEditView)
const handleCardUpdateFromGeneral = async (payload) => {
    try {
        await cardStore.updateCard({ ...payload, id: selectedCard.value }); // Ensure ID is correctly passed
        await cardStore.fetchCards(); // Refresh the list
        toast.add({ severity: 'success', summary: 'Updated', detail: `Card "${payload.name}" updated successfully.`, life: 3000 });
        // CardCreateEditView (inside CardGeneral) should switch to 'view' mode.
        // Since CardGeneral always passes modeProp="view", a re-render due to cardProp change
        // should ensure CardCreateEditView initializes in 'view' mode.
    } catch (error) {
        console.error('Failed to update card:', error);
        toast.add({ severity: 'error', summary: 'Error', detail: 'Failed to update card.', life: 3000 });
    }
};

// Handler for the cancel-edit event from CardGeneral
const handleCardCancelFromGeneral = () => {
    // toast.add({ severity: 'info', summary: 'Cancelled', detail: 'Editing cancelled.', life: 3000 });
    // CardCreateEditView (inside CardGeneral) handles its own mode switch back to 'view'.
    // No specific action needed here unless MyCards wants to change its own state.
};

const tabs = ref(['General', 'Content', 'Issuance']);

const triggerDeleteConfirmation = (cardId) => {
    const cardToDelete = cards.value.find(card => card.id === cardId);
    if (!cardToDelete) {
        toast.add({ severity: 'error', summary: 'Error', detail: 'Card not found for deletion.', life: 3000 });
        return;
    }

    confirm.require({
        group: 'deleteCardConfirmation',
        message: `Are you sure you want to delete the card "${cardToDelete.name}"? This action cannot be undone.`,
        header: 'Confirm Deletion',
        icon: 'pi pi-exclamation-triangle',
        acceptLabel: 'Delete',
        rejectLabel: 'Cancel',
        acceptClass: 'p-button-danger',
        accept: async () => {
            try {
                await cardStore.deleteCard(cardId);
                toast.add({ severity: 'success', summary: 'Deleted', detail: `Card "${cardToDelete.name}" deleted successfully.`, life: 3000 });
                await cardStore.fetchCards(); // Refresh the list
                if (selectedCard.value === cardId) {
                    selectedCard.value = null; // Deselect if the deleted card was selected
                }
            } catch (error) {
                console.error('Failed to delete card:', error);
                toast.add({ severity: 'error', summary: 'Error', detail: 'Failed to delete card.', life: 3000 });
            }
        },
        reject: () => {
            toast.add({ severity: 'info', summary: 'Cancelled', detail: 'Deletion cancelled.', life: 3000 });
        }
    });
};
</script>

<style scoped>
/* Add your styles here */
</style>
