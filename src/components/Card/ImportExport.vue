<template>
  <div class="import-export-container">
    <TabView>
      <TabPanel header="Export">
        <div class="p-4">
          <CardExport v-if="cardId" :card-id="cardId" :card-name="cardName" />
          <div v-else class="text-center p-4 text-gray-500">
            Please select a card to export.
          </div>
        </div>
      </TabPanel>
      <TabPanel header="Import">
        <div class="p-4">
          <CardBulkImport @imported="handleImport" />
        </div>
      </TabPanel>
    </TabView>
  </div>
</template>

<script setup>
import { computed } from 'vue';
import TabView from 'primevue/tabview';
import TabPanel from 'primevue/tabpanel';
import CardExport from '@/components/Card/Export/CardExport.vue';
import CardBulkImport from '@/components/Card/Import/CardBulkImport.vue';

const props = defineProps({
  card: {
    type: Object,
    default: null
  }
});

const emit = defineEmits(['imported']);

const cardId = computed(() => props.card?.id);
const cardName = computed(() => props.card?.name);

const handleImport = (result) => {
  emit('imported', result);
};
</script>

<style scoped>
.import-export-container {
  @apply bg-white rounded-lg shadow-sm;
}
</style> 