<template>
  <div class="language-selection-screen">
    <div class="language-header">
      <button @click="$emit('close')" class="close-button-top-right">
        <i class="pi pi-times" />
      </button>
      <i class="pi pi-globe language-globe-icon" />
      <h2 class="language-title">{{ $t('mobile.choose_language') }}</h2>
      <p class="language-subtitle">{{ $t('mobile.select_language_to_chat') }}</p>
    </div>
    
    <div class="language-grid">
      <button
        v-for="lang in languages"
        :key="lang.code"
        @click="$emit('select', lang)"
        class="language-option"
      >
        <span class="language-flag">{{ lang.flag }}</span>
        <span class="language-name">{{ lang.name }}</span>
      </button>
    </div>
  </div>
</template>

<script setup lang="ts">
import { useI18n } from 'vue-i18n'
import type { Language } from '../types'

const { t } = useI18n()

defineEmits<{
  (e: 'select', language: Language): void
  (e: 'close'): void
}>()

const languages: Language[] = [
  { code: 'en', name: 'English', flag: '🇺🇸' },
  { code: 'zh-HK', name: '廣東話', flag: '🇭🇰' },
  { code: 'zh-CN', name: '普通话', flag: '🇨🇳' },
  { code: 'ja', name: '日本語', flag: '🇯🇵' },
  { code: 'ko', name: '한국어', flag: '🇰🇷' },
  { code: 'es', name: 'Español', flag: '🇪🇸' },
  { code: 'fr', name: 'Français', flag: '🇫🇷' },
  { code: 'ru', name: 'Русский', flag: '🇷🇺' },
  { code: 'ar', name: 'العربية', flag: '🇸🇦' },
  { code: 'th', name: 'ไทย', flag: '🇹🇭' }
]
</script>

<style scoped>
.language-selection-screen {
  display: flex;
  flex-direction: column;
  height: 100%;
  padding: 2rem;
  overflow-y: auto;
}

.language-header {
  text-align: center;
  margin-bottom: 2rem;
  position: relative;
}

.close-button-top-right {
  position: absolute;
  top: 0;
  right: 0;
  background: none;
  border: none;
  color: #6b7280;
  font-size: 1.5rem;
  cursor: pointer;
  padding: 0.5rem;
  transition: color 0.2s;
}

.close-button-top-right:hover {
  color: #374151;
}

.language-globe-icon {
  font-size: 3rem;
  color: #3b82f6;
  margin-bottom: 1rem;
}

.language-title {
  font-size: 1.75rem;
  font-weight: 700;
  color: #1f2937;
  margin-bottom: 0.5rem;
}

.language-subtitle {
  font-size: 1rem;
  color: #6b7280;
}

.language-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(140px, 1fr));
  gap: 1rem;
  padding-bottom: 2rem;
}

.language-option {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 0.75rem;
  padding: 1.5rem 1rem;
  background: white;
  border: 2px solid #e5e7eb;
  border-radius: 12px;
  cursor: pointer;
  transition: all 0.2s;
}

.language-option:hover {
  background: #f9fafb;
  border-color: #3b82f6;
  transform: translateY(-2px);
  box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1);
}

.language-flag {
  font-size: 2.5rem;
}

.language-name {
  font-size: 0.95rem;
  font-weight: 600;
  color: #374151;
}

@media (max-width: 640px) {
  .language-grid {
    grid-template-columns: repeat(2, 1fr);
  }
  
  .language-selection-screen {
    padding: 1.5rem;
  }
}
</style>

