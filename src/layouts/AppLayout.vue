<template>
  <div class="app-layout min-h-screen bg-slate-50">
    <UnifiedHeader mode="dashboard" />
    
    <main class="main-content">
      <router-view />
    </main>
  </div>
</template>

<script setup>
import UnifiedHeader from '@/components/Layout/UnifiedHeader.vue'
</script>

<style scoped>
.app-layout {
  display: flex;
  flex-direction: column;
}

.main-content {
  flex: 1;
  padding: 0;
}
</style>