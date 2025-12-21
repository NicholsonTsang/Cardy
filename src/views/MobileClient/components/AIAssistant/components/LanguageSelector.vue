<template>
  <div class="language-selection">
    <!-- Header -->
    <div class="selection-header">
      <button @click="$emit('close')" class="close-button">
        <i class="pi pi-times" />
      </button>
      
      <div class="header-icon">
        <i class="pi pi-globe" />
      </div>
      
      <h2 class="header-title">{{ $t('mobile.choose_language') }}</h2>
      <p class="header-subtitle">{{ $t('mobile.select_language_to_chat') }}</p>
    </div>
    
    <!-- Language Grid -->
    <div class="language-grid">
      <button
        v-for="lang in languages"
        :key="lang.code"
        @click="$emit('select', lang)"
        class="language-card"
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
.language-selection {
  display: flex;
  flex-direction: column;
  height: 100%;
  padding: 1.5rem;
  overflow-y: auto;
  background: linear-gradient(180deg, #1e293b 0%, #0f172a 100%);
}

/* Header */
.selection-header {
  text-align: center;
  margin-bottom: 2rem;
  position: relative;
  padding-top: 0.5rem;
}

.close-button {
  position: absolute;
  top: 0;
  right: 0;
  width: 36px;
  height: 36px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: rgba(255, 255, 255, 0.06);
  border: 1px solid rgba(255, 255, 255, 0.1);
  border-radius: 10px;
  color: rgba(255, 255, 255, 0.6);
  font-size: 1rem;
  cursor: pointer;
  transition: all 0.2s;
}

.close-button:hover {
  background: rgba(255, 255, 255, 0.1);
  color: white;
}

.header-icon {
  width: 64px;
  height: 64px;
  margin: 0 auto 1rem;
  display: flex;
  align-items: center;
  justify-content: center;
  background: linear-gradient(135deg, rgba(99, 102, 241, 0.2) 0%, rgba(139, 92, 246, 0.2) 100%);
  border: 1px solid rgba(139, 92, 246, 0.3);
  border-radius: 20px;
  animation: iconFloat 3s ease-in-out infinite;
}

@keyframes iconFloat {
  0%, 100% { transform: translateY(0); }
  50% { transform: translateY(-4px); }
}

.header-icon i {
  font-size: 1.75rem;
  color: #a78bfa;
}

.header-title {
  font-size: 1.5rem;
  font-weight: 700;
  color: white;
  margin: 0 0 0.5rem 0;
}

.header-subtitle {
  font-size: 0.9375rem;
  color: rgba(255, 255, 255, 0.5);
  margin: 0;
}

/* Language Grid */
.language-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 0.75rem;
  padding-bottom: 1.5rem;
}

.language-card {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 0.5rem;
  padding: 1rem 0.875rem;
  background: linear-gradient(
    135deg,
    rgba(255, 255, 255, 0.06) 0%,
    rgba(255, 255, 255, 0.02) 100%
  );
  border: 1px solid rgba(255, 255, 255, 0.08);
  border-radius: 14px;
  cursor: pointer;
  transition: all 0.25s cubic-bezier(0.4, 0, 0.2, 1);
  position: relative;
  overflow: hidden;
}

.language-card::before {
  content: '';
  position: absolute;
  inset: 0;
  background: linear-gradient(
    135deg,
    rgba(99, 102, 241, 0.15) 0%,
    rgba(139, 92, 246, 0.15) 100%
  );
  opacity: 0;
  transition: opacity 0.25s;
}

.language-card:hover {
  background: linear-gradient(
    135deg,
    rgba(255, 255, 255, 0.08) 0%,
    rgba(255, 255, 255, 0.04) 100%
  );
  border-color: rgba(99, 102, 241, 0.35);
  transform: translateY(-3px) scale(1.02);
  box-shadow: 
    0 12px 32px rgba(0, 0, 0, 0.25),
    0 0 24px rgba(99, 102, 241, 0.15);
}

.language-card:hover::before {
  opacity: 1;
}

.language-card:active {
  transform: translateY(0) scale(0.98);
}

.language-flag {
  font-size: 2.25rem;
  line-height: 1;
  filter: drop-shadow(0 2px 4px rgba(0, 0, 0, 0.2));
}

.language-name {
  font-size: 0.9375rem;
  font-weight: 600;
  color: rgba(255, 255, 255, 0.9);
  text-align: center;
}

/* Mobile Adjustments */
@media (max-width: 640px) {
  .language-selection {
    padding: 1rem;
    padding-top: max(1rem, env(safe-area-inset-top));
  }
  
  .language-grid {
    gap: 0.5rem;
  }
  
  .language-card {
    padding: 0.875rem 0.625rem;
  }
  
  .language-flag {
    font-size: 1.75rem;
  }
  
  .language-name {
    font-size: 0.8125rem;
  }
}

/* Small height screens - more compact */
@media (max-height: 600px) {
  .selection-header {
    margin-bottom: 1.25rem;
  }
  
  .header-icon {
    width: 48px;
    height: 48px;
    margin-bottom: 0.75rem;
  }
  
  .header-icon i {
    font-size: 1.25rem;
  }
  
  .header-title {
    font-size: 1.25rem;
  }
  
  .language-card {
    padding: 0.875rem 0.625rem;
    gap: 0.5rem;
  }
  
  .language-flag {
    font-size: 1.75rem;
  }
}
</style>
