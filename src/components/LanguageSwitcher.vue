<template>
  <Select 
    v-model="currentLocale" 
    :options="languages" 
    optionLabel="name"
    optionValue="code"
    @change="handleLocaleChange"
    class="language-switcher"
  >
    <template #value="{ value }">
      <div class="flex items-center gap-2">
        <span class="text-lg">{{ getLanguageFlag(value) }}</span>
        <span class="hidden sm:inline">{{ getLanguageName(value) }}</span>
      </div>
    </template>
    <template #option="{ option }">
      <div class="flex items-center gap-2 py-1">
        <span class="text-lg">{{ option.flag }}</span>
        <span>{{ option.name }}</span>
      </div>
    </template>
  </Select>
</template>

<script setup lang="ts">
import { ref, watch } from 'vue'
import { useI18n } from 'vue-i18n'
import { setLocale } from '@/i18n'
import Select from 'primevue/select'

const { locale } = useI18n()
const currentLocale = ref(locale.value)

const languages = [
  { code: 'en', name: 'English', flag: '🇺🇸' },
  { code: 'zh-Hant', name: '繁體中文', flag: '🇭🇰' },
  { code: 'zh-Hans', name: '简体中文', flag: '🇨🇳' },
  { code: 'ja', name: '日本語', flag: '🇯🇵' },
  { code: 'ko', name: '한국어', flag: '🇰🇷' },
  { code: 'es', name: 'Español', flag: '🇪🇸' },
  { code: 'fr', name: 'Français', flag: '🇫🇷' },
  { code: 'ru', name: 'Русский', flag: '🇷🇺' },
  { code: 'ar', name: 'العربية', flag: '🇸🇦' },
  { code: 'th', name: 'ไทย', flag: '🇹🇭' }
]

function getLanguageFlag(code: string): string {
  return languages.find(l => l.code === code)?.flag || '🌐'
}

function getLanguageName(code: string): string {
  return languages.find(l => l.code === code)?.name || 'Language'
}

function handleLocaleChange(event: any) {
  setLocale(event.value)
  currentLocale.value = event.value
}

// Watch for external locale changes
watch(locale, (newLocale) => {
  currentLocale.value = newLocale
})
</script>

<style scoped>
.language-switcher {
  min-width: 140px;
}

@media (max-width: 640px) {
  .language-switcher {
    min-width: 80px;
  }
}
</style>

