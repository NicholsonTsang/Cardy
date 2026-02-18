<template>
  <PageWrapper :title="$t('templates.admin.management_title')" :description="$t('templates.admin.management_description')">
    <!-- Main Content Area -->
    <div class="bg-white rounded-xl shadow-sm border border-slate-200 overflow-hidden">
      <AdminTemplateList @open-import="showImportDialog = true" />
    </div>

    <!-- Import Dialog -->
    <Dialog 
      v-model:visible="showImportDialog" 
      :header="$t('templates.admin.import_tab')"
      :style="{ width: '90vw', maxWidth: '84rem' }"
      :modal="true"
      :dismissableMask="true"
    >
      <AdminTemplateImport @imported="handleImportComplete" />
    </Dialog>
  </PageWrapper>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import PageWrapper from '@/components/Layout/PageWrapper.vue'
import AdminTemplateList from './components/AdminTemplateList.vue'
import AdminTemplateImport from './components/AdminTemplateImport.vue'
import Dialog from 'primevue/dialog'

const showImportDialog = ref(false)

function handleImportComplete() {
  showImportDialog.value = false
}
</script>

<style scoped>
</style>
