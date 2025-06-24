<template>
  <div class="min-h-screen bg-gradient-to-br from-slate-900 via-blue-900 to-indigo-900">
    <!-- Loading State -->
    <div v-if="loading" class="flex items-center justify-center min-h-screen">
      <div class="text-center">
        <ProgressSpinner class="w-12 h-12" stroke="3" />
        <p class="text-white mt-4 text-base">Loading card...</p>
      </div>
    </div>

    <!-- Error State -->
    <div v-else-if="error" class="flex items-center justify-center min-h-screen p-6">
      <div class="text-center">
        <i class="pi pi-exclamation-triangle text-red-400 text-5xl mb-4" />
        <h2 class="text-white text-lg font-bold mb-2">Card Not Found</h2>
        <p class="text-gray-300 mb-4 text-sm">{{ error }}</p>
        <Button 
          label="Try Again" 
          @click="fetchCardData" 
          class="p-button-outlined p-button-secondary text-sm"
        />
      </div>
    </div>

    <!-- Card Content -->
    <div v-else-if="cardData" class="relative">
      <!-- Header with Back Navigation -->
      <div v-if="currentView !== 'card'" 
           class="fixed top-0 left-0 right-0 z-50 bg-black/20 backdrop-blur-md border-b border-white/10">
        <div class="flex items-center p-4">
          <Button 
            @click="navigateBack"
            icon="pi pi-arrow-left"
            class="p-button-text p-button-rounded mr-3"
            style="color: white"
          />
          <div>
            <h3 class="text-white font-semibold text-base">{{ currentTitle }}</h3>
            <p class="text-gray-300 text-xs">{{ cardData.card_name }}</p>
          </div>
        </div>
      </div>

      <!-- Card Overview -->
      <div v-if="currentView === 'card'" class="relative">
        <!-- Card Hero Section -->
        <div class="relative h-screen flex flex-col">
          <!-- Background Image -->
          <div class="absolute inset-0">
            <img 
              v-if="cardData.card_image_urls && cardData.card_image_urls.length > 0"
              :src="cardData.card_image_urls[0]" 
              :alt="cardData.card_name"
              class="w-full h-full object-cover"
            />
            <div class="absolute inset-0 bg-gradient-to-t from-black/80 via-black/40 to-transparent" />
          </div>
          
          <!-- Card Content -->
          <div class="relative z-10 flex-1 flex flex-col justify-end p-6 pb-8">
            <div class="text-center mb-8">
              <h1 class="text-2xl font-bold text-white mb-3">{{ cardData.card_name }}</h1>
              <p class="text-gray-100 text-base leading-relaxed">{{ cardData.card_description }}</p>
              
              <!-- Activation Status -->
              <div class="mt-4">
                <span v-if="cardData.is_activated" 
                      class="inline-flex items-center px-3 py-1 rounded-full bg-green-500/20 border border-green-400/30 text-green-300 text-xs">
                  <i class="pi pi-check-circle mr-2" />
                  Card Activated
                </span>
                <span v-else 
                      class="inline-flex items-center px-3 py-1 rounded-full bg-yellow-500/20 border border-yellow-400/30 text-yellow-300 text-xs">
                  <i class="pi pi-clock mr-2" />
                  Just Activated
                </span>
              </div>
            </div>

            <!-- Explore Button -->
            <Button 
              @click="navigateToContentList"
              class="w-full p-3 text-base font-semibold bg-white/10 backdrop-blur-md border border-white/20 hover:bg-white/20 transition-all"
              style="color: white"
            >
              <i class="pi pi-compass mr-2" />
              Explore Content
            </Button>
          </div>
        </div>
      </div>

      <!-- First Layer Content List -->
      <div v-else-if="currentView === 'content-list'" class="min-h-screen" :class="{ 'pt-20': true }">
        <div class="p-6">
          <div class="grid gap-4">
            <div 
              v-for="item in firstLayerItems" 
              :key="item.content_item_id"
              @click="selectContentItem(item)"
              class="group relative bg-white/10 backdrop-blur-md rounded-xl overflow-hidden border border-white/20 hover:border-white/40 transition-all cursor-pointer"
            >
              <!-- Content Item Image -->
              <div class="aspect-video relative overflow-hidden">
                <img 
                  v-if="item.content_item_image_urls && item.content_item_image_urls.length > 0"
                  :src="item.content_item_image_urls[0]" 
                  :alt="item.content_item_name"
                  class="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300"
                />
                <div v-else class="w-full h-full bg-gradient-to-br from-blue-500/20 to-purple-500/20 flex items-center justify-center">
                  <i class="pi pi-image text-white/40 text-3xl" />
                </div>
                <div class="absolute inset-0 bg-gradient-to-t from-black/60 to-transparent" />
                
                <!-- Sub-items indicator -->
                <div v-if="getSubItemsCount(item.content_item_id) > 0" 
                     class="absolute top-3 right-3 bg-blue-500/80 backdrop-blur-sm rounded-full px-2 py-1 text-xs text-white font-medium">
                  {{ getSubItemsCount(item.content_item_id) }} items
                </div>
              </div>

              <!-- Content Info -->
              <div class="p-4">
                <h3 class="text-white font-semibold text-base mb-2">{{ item.content_item_name }}</h3>
                <p class="text-gray-300 text-sm line-clamp-2">{{ item.content_item_content }}</p>
                
                <div class="flex items-center justify-between mt-3">
                  <div class="flex items-center text-gray-400 text-xs">
                    <i class="pi pi-arrow-right mr-1" />
                    Tap to explore
                  </div>
                  <div v-if="item.content_item_conversation_ai_enabled" 
                       class="text-blue-400 text-xs">
                    <i class="pi pi-microphone mr-1" />
                    AI Chat
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Content Item Detail -->
      <div v-else-if="currentView === 'content-detail'" class="min-h-screen" :class="{ 'pt-20': true }">
        <div class="p-6">
          <!-- Selected Content Item -->
          <div v-if="selectedContentItem" class="mb-8">
            <!-- Hero Image -->
            <div class="aspect-video relative overflow-hidden rounded-xl mb-6">
              <img 
                v-if="selectedContentItem.content_item_image_urls && selectedContentItem.content_item_image_urls.length > 0"
                :src="selectedContentItem.content_item_image_urls[0]" 
                :alt="selectedContentItem.content_item_name"
                class="w-full h-full object-cover"
              />
              <div v-else class="w-full h-full bg-gradient-to-br from-blue-500/20 to-purple-500/20 flex items-center justify-center">
                <i class="pi pi-image text-white/40 text-5xl" />
              </div>
              <div class="absolute inset-0 bg-gradient-to-t from-black/40 to-transparent" />
            </div>

            <!-- Content Info -->
            <div class="bg-white/10 backdrop-blur-md rounded-xl p-6 border border-white/20 mb-6">
              <h2 class="text-sm font-bold text-white mb-3">{{ selectedContentItem.content_item_name }}</h2>
              <p class="text-gray-100 leading-relaxed mb-4 text-xs">{{ selectedContentItem.content_item_content }}</p>
              
              <!-- Content Item AI Conversation (Compact Button) -->
              <div v-if="selectedContentItem && cardData.conversation_ai_enabled" class="flex justify-start">
                <ContentItemConversationAI 
                  :content-item-name="selectedContentItem.content_item_name"
                  :content-item-content="selectedContentItem.content_item_content"
                  :ai-metadata="selectedContentItem.content_item_ai_metadata || ''"
                  :card-data="{ card_name: cardData.card_name, card_description: cardData.card_description, ai_prompt: cardData.card_ai_prompt }"
                  :is-mobile="true"
                  :compact="true"
                />
              </div>
            </div>

            <!-- Sub Items -->
            <div v-if="currentSubItems.length > 0">
              <h3 class="text-lg font-semibold text-white mb-4">Related Content</h3>
              <div class="grid gap-4">
                <div 
                  v-for="subItem in currentSubItems" 
                  :key="subItem.content_item_id"
                  @click="selectContentItem(subItem)"
                  class="group bg-white/10 backdrop-blur-md rounded-xl overflow-hidden border border-white/20 hover:border-white/40 transition-all cursor-pointer"
                >
                  <div class="flex items-center">
                    <!-- Sub Item Image -->
                    <div class="w-20 h-20 flex-shrink-0 relative ml-3">
                      <img 
                        v-if="subItem.content_item_image_urls && subItem.content_item_image_urls.length > 0"
                        :src="subItem.content_item_image_urls[0]" 
                        :alt="subItem.content_item_name"
                        class="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300 rounded-lg"
                      />
                      <div v-else class="w-full h-full bg-gradient-to-br from-gray-500/20 to-gray-600/20 flex items-center justify-center rounded-lg">
                        <i class="pi pi-file text-white/40 text-base" />
                      </div>
                    </div>
                    
                    <!-- Sub Item Info -->
                    <div class="flex-1 p-3 text-center">
                      <h4 class="text-white font-medium mb-1 text-sm">{{ subItem.content_item_name }}</h4>
                      <p class="text-gray-300 text-xs line-clamp-2">{{ subItem.content_item_content }}</p>
                      
                      <div class="flex items-center justify-center gap-4 mt-2">
                        <div class="flex items-center text-gray-400 text-xs">
                          <i class="pi pi-arrow-right mr-1" />
                          Tap to explore
                        </div>
                        
                        <div v-if="cardData.card_conversation_ai_enabled" 
                             class="text-blue-400 text-xs">
                          <i class="pi pi-microphone mr-1" />
                          AI Chat
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue';
import { useRoute } from 'vue-router';
import { supabase } from '@/lib/supabase';
import ProgressSpinner from 'primevue/progressspinner';
import Button from 'primevue/button';
import ContentItemConversationAI from '@/components/ContentItemConversationAI.vue';

const route = useRoute();

// Reactive data
const loading = ref(true);
const error = ref(null);
const cardData = ref(null);
const contentItems = ref([]);
const currentView = ref('card'); // 'card', 'content-list', 'content-detail'
const selectedContentItem = ref(null);
const navigationHistory = ref([]); // Track navigation history for proper back navigation

// Computed properties
const firstLayerItems = computed(() => {
  return contentItems.value.filter(item => !item.content_item_parent_id);
});

const currentSubItems = computed(() => {
  if (!selectedContentItem.value) return [];
  return contentItems.value.filter(item => 
    item.content_item_parent_id === selectedContentItem.value.content_item_id
  );
});

const currentTitle = computed(() => {
  if (currentView.value === 'content-list') {
    return 'Explore Content';
  } else if (currentView.value === 'content-detail' && selectedContentItem.value) {
    return selectedContentItem.value.content_item_name;
  }
  return '';
});

// Methods
const fetchCardData = async () => {
  try {
    loading.value = true;
    error.value = null;

    const issueCardId = route.params.issue_card_id;
    const activationCode = route.params.activation_code;

    const { data, error: fetchError } = await supabase.rpc('get_public_card_content', {
      p_issue_card_id: issueCardId,
      p_activation_code: activationCode
    });

    if (fetchError) {
      throw fetchError;
    }

    if (!data || data.length === 0) {
      throw new Error('Card not found or invalid activation code');
    }

    // Process the data
    const cardInfo = data[0];
    cardData.value = {
      card_name: cardInfo.card_name,
      card_description: cardInfo.card_description,
      card_image_urls: cardInfo.card_image_urls,
      conversation_ai_enabled: cardInfo.card_conversation_ai_enabled,
      ai_prompt: cardInfo.card_ai_prompt,
      is_activated: cardInfo.is_activated
    };

    // Process content items (excluding the card-level row which has null content_item_id)
    contentItems.value = data
      .filter(item => item.content_item_id !== null)
      .map(item => ({
        content_item_id: item.content_item_id,
        content_item_parent_id: item.content_item_parent_id,
        content_item_name: item.content_item_name,
        content_item_content: item.content_item_content,
        content_item_image_urls: item.content_item_image_urls,
        content_item_ai_metadata: item.content_item_ai_metadata,
        content_item_sort_order: item.content_item_sort_order
      }))
      .sort((a, b) => (a.content_item_sort_order || 0) - (b.content_item_sort_order || 0));

  } catch (err) {
    console.error('Error fetching card data:', err);
    error.value = err.message || 'Failed to load card data';
  } finally {
    loading.value = false;
  }
};

const selectContentItem = (item) => {
  // Add current state to navigation history
  navigationHistory.value.push({
    view: currentView.value,
    selectedItem: selectedContentItem.value
  });
  
  selectedContentItem.value = item;
  currentView.value = 'content-detail';
};

const navigateBack = () => {
  if (navigationHistory.value.length > 0) {
    // Go back to previous state in history
    const previousState = navigationHistory.value.pop();
    currentView.value = previousState.view;
    selectedContentItem.value = previousState.selectedItem;
  } else {
    // Fallback to default navigation if no history
    if (currentView.value === 'content-detail') {
      currentView.value = 'content-list';
      selectedContentItem.value = null;
    } else if (currentView.value === 'content-list') {
      currentView.value = 'card';
    }
  }
};

const navigateToContentList = () => {
  // Add current state to navigation history
  navigationHistory.value.push({
    view: currentView.value,
    selectedItem: selectedContentItem.value
  });
  
  currentView.value = 'content-list';
};

const getSubItemsCount = (parentId) => {
  return contentItems.value.filter(item => item.content_item_parent_id === parentId).length;
};

// Lifecycle
onMounted(() => {
  fetchCardData();
});
</script>

<style scoped>
.line-clamp-2 {
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

/* Ensure proper spacing for mobile */
@media (max-width: 640px) {
  .min-h-screen {
    min-height: 100dvh;
  }
}

/* Custom scrollbar for webkit browsers */
::-webkit-scrollbar {
  width: 4px;
}

::-webkit-scrollbar-track {
  background: rgba(255, 255, 255, 0.1);
}

::-webkit-scrollbar-thumb {
  background: rgba(255, 255, 255, 0.3);
  border-radius: 2px;
}

::-webkit-scrollbar-thumb:hover {
  background: rgba(255, 255, 255, 0.5);
}
</style>
