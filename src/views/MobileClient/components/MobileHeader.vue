<template>
  <header class="mobile-header">
    <button @click="handleBack" class="back-button">
      <i class="pi pi-arrow-left" />
    </button>
    <div class="header-content">
      <h1 class="header-title">{{ title }}</h1>
      <p v-if="subtitle" class="header-subtitle">{{ subtitle }}</p>
    </div>
    <LanguageSelector />
  </header>
</template>

<script setup lang="ts">
import LanguageSelector from './LanguageSelector.vue'

interface Props {
  title: string
  subtitle?: string
}

defineProps<Props>()
const emit = defineEmits<{
  back: []
}>()

function handleBack() {
  emit('back')
}
</script>

<style scoped>
.mobile-header {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  z-index: 50;
  background: rgba(0, 0, 0, 0.3);
  backdrop-filter: blur(12px);
  -webkit-backdrop-filter: blur(12px);
  border-bottom: 1px solid rgba(255, 255, 255, 0.1);
  padding: 1rem;
  display: flex;
  align-items: center;
  gap: 0.75rem;
}

.back-button {
  width: 2.5rem;
  height: 2.5rem;
  border-radius: 50%;
  background: rgba(255, 255, 255, 0.1);
  border: none;
  color: white;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.2s;
  flex-shrink: 0;
}

.back-button:active {
  transform: scale(0.95);
  background: rgba(255, 255, 255, 0.2);
}

.header-content {
  flex: 1;
  min-width: 0;
}

.header-title {
  font-size: 1rem;
  font-weight: 600;
  color: white;
  margin: 0;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.header-subtitle {
  font-size: 0.75rem;
  color: rgba(255, 255, 255, 0.7);
  margin: 0;
  margin-top: 0.125rem;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
</style>