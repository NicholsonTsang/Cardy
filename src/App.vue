<template>
  <div id="app" class="min-h-screen bg-slate-50">
    <router-view />
    <Toast position="top-right" />
    <Toast position="bottom-right" group="br" />
  </div>
</template>

<script setup>
import Toast from 'primevue/toast';
</script>

<style>
/* Global font and typography improvements */
* {
  font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
}

/* Smooth transitions for better UX */
* {
  transition: all 0.2s ease-in-out;
}


</style>

