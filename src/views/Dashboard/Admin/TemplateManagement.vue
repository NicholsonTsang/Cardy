<template>
  <div class="template-management min-h-screen bg-slate-50 pb-12">
    <PageWrapper :title="$t('templates.admin.management_title')" :description="$t('templates.admin.management_description')">
      <div class="management-content max-w-7xl mx-auto">
        <!-- Main Content Area -->
        <div class="bg-white rounded-xl shadow-sm border border-slate-200 overflow-hidden">
          <AdminTemplateList @open-import="showImportDialog = true" />
        </div>
      </div>
    </PageWrapper>

    <!-- Import Dialog -->
    <Dialog 
      v-model:visible="showImportDialog" 
      :header="$t('templates.admin.import_tab')"
      :style="{ width: '900px', maxWidth: '95vw' }"
      :modal="true"
      :dismissableMask="true"
    >
      <AdminTemplateImport @imported="handleImportComplete" />
    </Dialog>
  </div>
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
