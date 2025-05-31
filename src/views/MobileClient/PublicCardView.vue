<template>
    <div class="min-h-screen bg-slate-100 text-slate-800 font-sans antialiased">
        <!-- Loading State -->
        <div v-if="isLoading" class="fixed inset-0 flex flex-col items-center justify-center bg-slate-100 z-50">
            <ProgressSpinner strokeWidth="3" animationDuration=".8s" class="w-12 h-12 text-blue-600"/>
            <p class="mt-4 text-lg font-semibold text-slate-700">Loading Card...</p>
        </div>

        <!-- Error State -->
        <div v-else-if="error" class="fixed inset-0 flex flex-col items-center justify-center bg-slate-100 p-6 text-center z-50">
            <div class="w-16 h-16 bg-red-100 rounded-full flex items-center justify-center mb-4">
                <i class="pi pi-exclamation-triangle text-3xl text-red-500"></i>
            </div>
            <h2 class="text-xl font-semibold text-red-600 mb-2">Oops!</h2>
            <p class="text-slate-600 mb-6 max-w-sm">{{ error }}</p>
            <Button label="Go to Homepage" icon="pi pi-home" @click="goToHome" severity="secondary" outlined />
        </div>

        <!-- Card Content Display -->
        <div v-else-if="cardData" class="max-w-3xl mx-auto">
            <!-- Activation Message (fixed at top) -->
            <div v-if="showActivationMessage && cardData.is_activated" 
                 class="sticky top-0 left-0 right-0 z-40 bg-green-500 text-white p-3 text-center text-sm shadow-md flex items-center justify-center gap-2">
                <i class="pi pi-check-circle"></i>
                <span>Card Activated!</span>
            </div>

            <!-- Parent Item List View -->
            <div v-if="currentView === 'parent_list'">
                <header class="bg-white shadow-sm sticky top-0 z-30">
                    <div v-if="cardData.card_image_urls && cardData.card_image_urls.length > 0" 
                         class="w-full h-48 sm:h-56 bg-slate-200">
                        <img :src="cardData.card_image_urls[0]" :alt="cardData.card_name" class="w-full h-full object-cover" />
                    </div>
                    <div class="p-5">
                        <h1 class="text-2xl sm:text-3xl font-bold text-slate-900 tracking-tight">{{ cardData.card_name }}</h1>
                        <p v-if="cardData.card_description" class="text-sm text-slate-600 mt-1 leading-relaxed">{{ cardData.card_description }}</p>
                    </div>
                </header>
                
                <main class="p-3 space-y-3 pb-16">
                    <div v-if="parentItems.length === 0" class="text-center py-10 px-4">
                        <div class="w-16 h-16 bg-slate-200 rounded-full flex items-center justify-center mx-auto mb-4">
                            <i class="pi pi-file text-3xl text-slate-400"></i>
                        </div>
                        <h3 class="text-lg font-medium text-slate-700">No Content Available</h3>
                        <p class="text-sm text-slate-500">This card doesn't have any primary content items yet.</p>
                    </div>

                    <div v-for="item in parentItems" :key="item.content_item_id"
                        @click="item.childrenCount > 0 ? selectParentItem(item) : null"
                        :class="[
                            'bg-white rounded-xl shadow-lg border border-slate-200 overflow-hidden flex flex-col p-4 gap-3',
                            item.childrenCount > 0 ? 'active:shadow-xl active:translate-y-px transition-all duration-150 cursor-pointer' : ''
                        ]">
                        <div class="flex items-start gap-4">
                            <div v-if="item.content_item_image_urls && item.content_item_image_urls.length > 0" 
                                 class="w-16 h-16 bg-slate-100 rounded-lg overflow-hidden flex-shrink-0 border border-slate-200">
                                <img :src="item.content_item_image_urls[0]" :alt="item.content_item_name" class="w-full h-full object-cover" />
                            </div>
                            <div v-else class="w-16 h-16 bg-slate-100 rounded-lg flex items-center justify-center flex-shrink-0 border border-slate-200">
                                <i class="pi pi-image text-2xl text-slate-400"></i>
                            </div> 
                            <div class="flex-grow min-w-0">
                                <h2 class="text-lg font-semibold text-blue-700 truncate">
                                    {{ item.content_item_name }}
                                </h2>
                                <div class="mt-1 text-xs">
                                    <span v-if="item.childrenCount > 0" 
                                          class="px-2 py-0.5 bg-blue-100 text-blue-700 font-semibold rounded-full">
                                        {{ item.childrenCount }} {{ item.childrenCount === 1 ? 'sub-item' : 'sub-items' }}
                                    </span>
                                    <span v-else class="px-2 py-0.5 bg-slate-200 text-slate-600 font-semibold rounded-full">
                                        No sub-items
                                    </span>
                                </div>
                            </div>
                            <i v-if="item.childrenCount > 0" class="pi pi-chevron-right text-slate-400 text-xl ml-auto self-center"></i>
                        </div>
                        <div v-if="item.content_item_content && item.content_item_content.trim() !== ''" class="mt-2 pt-2 border-t border-slate-100">
                            <div class="prose prose-sm max-w-none text-slate-700 leading-relaxed"
                                 :class="{ 'line-clamp-5': !expandedDescriptions[item.content_item_id] }"
                                 v-html="item.content_item_content"></div>
                            <button v-if="item.content_item_content.length > 150" 
                                    @click.stop="toggleDescription(item.content_item_id)" 
                                    class="text-xs text-blue-600 hover:text-blue-800 font-medium mt-2 focus:outline-none">
                                {{ expandedDescriptions[item.content_item_id] ? 'Show less' : 'Read more' }}
                            </button>
                        </div>
                    </div>
                </main>
            </div>

            <!-- Child Item List View -->
            <div v-if="currentView === 'child_list' && selectedParentItem" class="pb-16">
                <header class="bg-white shadow-sm sticky top-0 z-30 p-4 flex items-center gap-3">
                    <Button icon="pi pi-arrow-left" @click="goBackToParentList" text rounded severity="secondary" class="p-button-lg -ml-2" />
                    <div class="min-w-0">
                        <h1 class="text-xl font-bold text-slate-900 truncate">{{ selectedParentItem.content_item_name }}</h1>
                    </div>
                </header>
                
                <main class="p-3 space-y-3">
                     <div v-if="childItems.length === 0" class="text-center py-10 px-4">
                        <div class="w-16 h-16 bg-slate-200 rounded-full flex items-center justify-center mx-auto mb-4">
                            <i class="pi pi-folder-open text-3xl text-slate-400"></i>
                        </div>
                        <h3 class="text-lg font-medium text-slate-700">No Sub-Items</h3>
                        <p class="text-sm text-slate-500">There are no sub-items available for this section.</p>
                    </div>
                    <article v-for="item in childItems" :key="item.content_item_id"
                        class="bg-white p-5 rounded-xl shadow-lg border border-slate-200 overflow-hidden">
                        <h2 class="text-xl font-semibold text-blue-700 mb-3">{{ item.content_item_name }}</h2>
                        <div v-if="item.content_item_image_urls && item.content_item_image_urls.length > 0" 
                             class="mb-4 rounded-lg overflow-hidden bg-slate-100 border border-slate-200">
                            <img :src="item.content_item_image_urls[0]" :alt="item.content_item_name" class="w-full h-auto object-contain max-h-80" />
                        </div>
                        <div class="prose prose-sm sm:prose-base max-w-none text-slate-700 leading-relaxed" v-html="item.content_item_content"></div>
                    </article>
                </main>
            </div>

            <!-- Footer Branding (common for both views) -->
            <footer v-if="currentView !== ''" class="text-center py-6 mt-4 border-t border-slate-200 bg-slate-50 fixed bottom-0 left-0 right-0 z-20">
                <p class="text-xs text-slate-500">Powered by <a href="https://app.cardy.com" target="_blank" class="text-blue-600 hover:underline font-medium">Cardy CMS</a></p>
            </footer>
        </div>
    </div>
</template>

<script setup lang="ts">
import { ref, onMounted, computed, reactive } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { usePublicCardStore, type PublicContentItem } from '@/stores/publicCard';
import { storeToRefs } from 'pinia';

import Button from 'primevue/button';
import ProgressSpinner from 'primevue/progressspinner';

const route = useRoute();
const router = useRouter();
const publicCardStore = usePublicCardStore();

const { cardData, isLoading, error } = storeToRefs(publicCardStore);

const issueCardId = ref<string | null>(null);
const activationCode = ref<string | null>(null);
const showActivationMessage = ref(false);

const currentView = ref<'parent_list' | 'child_list' | '' >('');
const selectedParentItem = ref<PublicContentItem | null>(null);
const expandedDescriptions = reactive<Record<string, boolean>>({});

interface DisplayablePublicContentItem extends PublicContentItem {
    childrenCount: number;
}

const parentItems = computed((): DisplayablePublicContentItem[] => {
    if (!cardData.value) return [];
    return cardData.value.content_items
        .filter(item => item.content_item_parent_id === null)
        .map(parent => ({
            ...parent,
            childrenCount: cardData.value!.content_items.filter(child => child.content_item_parent_id === parent.content_item_id).length
        }));
});

const childItems = computed(() => {
    if (!cardData.value || !selectedParentItem.value) return [];
    return cardData.value.content_items.filter(item => item.content_item_parent_id === selectedParentItem.value?.content_item_id);
});

const toggleDescription = (itemId: string) => {
    expandedDescriptions[itemId] = !expandedDescriptions[itemId];
};

onMounted(async () => {
    const idParam = route.params.issue_card_id;
    const codeParam = route.params.activation_code;

    if (Array.isArray(idParam) || Array.isArray(codeParam)) {
        error.value = 'Invalid URL parameters.';
        return;
    }

    issueCardId.value = idParam || null;
    activationCode.value = codeParam || null;

    if (issueCardId.value && activationCode.value) {
        const previouslyActivated = cardData.value?.is_activated;
        await publicCardStore.fetchPublicCard(issueCardId.value, activationCode.value);
        
        if (cardData.value) {
             currentView.value = 'parent_list';
            if (cardData.value.is_activated && !previouslyActivated) {
                showActivationMessage.value = true;
                setTimeout(() => showActivationMessage.value = false, 4000);
            }
        } else if (!error.value) {
            error.value = "Card not found or content is unavailable.";
        }
    } else {
        error.value = 'Card ID and Activation Code are required in the URL.';
    }
});

const selectParentItem = (item: DisplayablePublicContentItem) => {
    if (item.childrenCount > 0) {
        selectedParentItem.value = item;
        currentView.value = 'child_list';
        window.scrollTo(0, 0);
    }
};

const goBackToParentList = () => {
    currentView.value = 'parent_list';
    selectedParentItem.value = null;
    for (const key in expandedDescriptions) {
        delete expandedDescriptions[key];
    }
    window.scrollTo(0, 0);
};

const goToHome = () => {
    router.push('/');
};

</script>

<style>
.line-clamp-5 {
    overflow: hidden;
    display: -webkit-box;
    -webkit-box-orient: vertical;
    -webkit-line-clamp: 5;
}

.prose img {
    @apply rounded-lg shadow-md border border-slate-200;
}

html, body, #app {
    height: 100%;
}

body {
    background-color: #f1f5f9; 
}
</style> 