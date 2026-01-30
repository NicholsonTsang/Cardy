<template>
  <div class="markdown-content" v-html="renderedContent"></div>
</template>

<script setup lang="ts">
import { computed, ref, watch, onMounted } from 'vue'
import { marked } from 'marked'
import { useI18n } from 'vue-i18n'

const props = defineProps<{
  contentPath: string // e.g., 'getting-started/overview'
}>()

const { locale } = useI18n()
const rawContent = ref('')

// Dynamic import of markdown content based on locale and path
const loadContent = async () => {
  try {
    // Try to load the localized version first
    const modules = import.meta.glob('../content/**/*.md', { query: '?raw', import: 'default', eager: false })
    const localePath = `../content/${locale.value}/${props.contentPath}.md`
    const fallbackPath = `../content/en/${props.contentPath}.md`
    
    if (modules[localePath]) {
      rawContent.value = await modules[localePath]() as string
    } else if (modules[fallbackPath]) {
      // Fallback to English if locale not available
      rawContent.value = await modules[fallbackPath]() as string
    } else {
      rawContent.value = '# Content not found\n\nThe requested documentation content could not be loaded.'
    }
  } catch (error) {
    console.error('Failed to load markdown content:', error)
    rawContent.value = '# Error\n\nFailed to load content.'
  }
}

// Configure marked options
marked.use({
  gfm: true,
  breaks: true
})

// Process :::features directive into styled feature cards
const processFeatures = (innerContent: string): string => {
  const lines = innerContent.trim().split('\n')
  const features: Array<{icon: string, title: string, desc: string, color: string}> = []
  
  for (const line of lines) {
    // Parse: - icon: "pi pi-xxx" title: "Title" desc: "Description" color: "color"
    const iconMatch = line.match(/icon:\s*"([^"]+)"/)
    const titleMatch = line.match(/title:\s*"([^"]+)"/)
    const descMatch = line.match(/desc:\s*"([^"]+)"/)
    const colorMatch = line.match(/color:\s*"([^"]+)"/)
    
    if (iconMatch && titleMatch && descMatch) {
      features.push({
        icon: iconMatch[1],
        title: titleMatch[1],
        desc: descMatch[1],
        color: colorMatch ? colorMatch[1] : 'blue'
      })
    }
  }
  
  const colorStyles: Record<string, { bg: string, icon: string, border: string }> = {
    blue: { bg: 'bg-blue-50', icon: 'text-blue-600 bg-blue-100', border: 'border-blue-100' },
    green: { bg: 'bg-green-50', icon: 'text-green-600 bg-green-100', border: 'border-green-100' },
    purple: { bg: 'bg-purple-50', icon: 'text-purple-600 bg-purple-100', border: 'border-purple-100' },
    amber: { bg: 'bg-amber-50', icon: 'text-amber-600 bg-amber-100', border: 'border-amber-100' },
    red: { bg: 'bg-red-50', icon: 'text-red-600 bg-red-100', border: 'border-red-100' }
  }
  
  const featureCards = features.map(f => {
    const style = colorStyles[f.color] || colorStyles.blue
    return `<div class="rounded-lg sm:rounded-xl p-4 sm:p-5 ${style.bg} border ${style.border}"><div class="w-10 h-10 sm:w-12 sm:h-12 rounded-lg ${style.icon} flex items-center justify-center mb-2 sm:mb-3"><i class="${f.icon} text-lg sm:text-xl"></i></div><h4 class="font-semibold text-slate-900 mb-1 text-sm sm:text-base">${f.title}</h4><p class="text-slate-600 text-xs sm:text-sm">${f.desc}</p></div>`
  }).join('')
  
  return `<div class="grid grid-cols-1 sm:grid-cols-2 gap-3 sm:gap-4 my-4 sm:my-6">${featureCards}</div>`
}

// Process :::steps directive into styled step cards
const processSteps = (innerContent: string): string => {
  const lines = innerContent.trim().split('\n')
  const steps: Array<{num: number, title: string, desc: string}> = []
  
  for (const line of lines) {
    // Parse: 1. **Title** - Description
    const match = line.match(/^(\d+)\.\s*\*\*([^*]+)\*\*\s*[-–]\s*(.+)$/)
    if (match) {
      steps.push({
        num: parseInt(match[1]),
        title: match[2],
        desc: match[3]
      })
    }
  }
  
  const stepCards = steps.map(s => {
    return `<div class="rounded-lg sm:rounded-xl p-3 sm:p-5 bg-slate-50 border border-slate-100 flex gap-3 sm:gap-4"><div class="w-8 h-8 sm:w-10 sm:h-10 rounded-full bg-blue-600 text-white flex items-center justify-center font-bold flex-shrink-0 text-sm sm:text-base">${s.num}</div><div><h4 class="font-semibold text-slate-900 mb-1 text-sm sm:text-base">${s.title}</h4><p class="text-slate-600 text-xs sm:text-sm">${s.desc}</p></div></div>`
  }).join('')
  
  return `<div class="space-y-2 sm:space-y-3 my-4 sm:my-6">${stepCards}</div>`
}

// Convert directives to placeholders before marked parsing (to avoid HTML escaping)
// Using %%DIRECTIVE_X%% format since __ would be interpreted as bold by markdown
const convertDirectivesToPlaceholders = (content: string): { content: string, directives: Map<string, string> } => {
  const directives = new Map<string, string>()
  let counter = 0
  
  // Process :::features directive
  let processedContent = content.replace(/:::features\n([\s\S]*?):::/g, (match, innerContent) => {
    const html = processFeatures(innerContent)
    const placeholder = `%%DIRECTIVE_${counter++}%%`
    directives.set(placeholder, html)
    return placeholder
  })
  
  // Process :::steps directive
  processedContent = processedContent.replace(/:::steps\n([\s\S]*?):::/g, (match, innerContent) => {
    const html = processSteps(innerContent)
    const placeholder = `%%DIRECTIVE_${counter++}%%`
    directives.set(placeholder, html)
    return placeholder
  })
  
  // Process tip/info/warning/important directives
  const directiveRegex = /:::(tip|info|warning|important)\s*(.*?)\n([\s\S]*?):::/g

  processedContent = processedContent.replace(directiveRegex, (match, type, title, innerContent) => {
    const icons: Record<string, string> = {
      tip: 'pi-lightbulb',
      info: 'pi-info-circle',
      warning: 'pi-exclamation-triangle',
      important: 'pi-exclamation-circle'
    }
    const colors: Record<string, string> = {
      tip: 'bg-green-50 border-green-200 text-green-800',
      info: 'bg-blue-50 border-blue-200 text-blue-800',
      warning: 'bg-amber-50 border-amber-200 text-amber-800',
      important: 'bg-red-50 border-red-200 text-red-800'
    }
    const iconColors: Record<string, string> = {
      tip: 'text-green-600',
      info: 'text-blue-600',
      warning: 'text-amber-600',
      important: 'text-red-600'
    }

    const titleHtml = title ? `<strong class="block mb-1 text-sm sm:text-base">${title.trim()}</strong>` : ''
    // Parse inner content as markdown to support tables and other formatting
    const parsedInnerContent = marked.parse(innerContent.trim()) as string
    const html = `<div class="tipbox rounded-lg sm:rounded-xl p-3 sm:p-4 my-4 sm:my-6 flex gap-2 sm:gap-3 border ${colors[type]} text-xs sm:text-sm"><i class="pi ${icons[type]} text-base sm:text-lg mt-0.5 ${iconColors[type]} shrink-0"></i><div class="tipbox-content flex-1 min-w-0">${titleHtml}${parsedInnerContent}</div></div>`

    const placeholder = `%%DIRECTIVE_${counter++}%%`
    directives.set(placeholder, html)
    return placeholder
  })
  
  return { content: processedContent, directives }
}

// Restore directives from placeholders after marked parsing
const restoreDirectives = (html: string, directives: Map<string, string>): string => {
  let result = html
  directives.forEach((value, key) => {
    // The placeholder might be wrapped in <p> tags by marked - remove them
    result = result.replace(new RegExp(`<p>${key}</p>`, 'g'), value)
    result = result.replace(new RegExp(key, 'g'), value)
  })
  return result
}

const renderedContent = computed(() => {
  const raw = rawContent.value
  if (!raw) return ''
  
  // Step 1: Convert directives to placeholders (so marked doesn't escape them)
  const { content: contentWithPlaceholders, directives } = convertDirectivesToPlaceholders(raw)
  
  // Step 2: Parse markdown
  const parsed = marked.parse(contentWithPlaceholders) as string
  
  // Step 3: Restore directives from placeholders
  return restoreDirectives(parsed, directives)
})

// Load content on mount and when locale changes
onMounted(loadContent)
watch([() => props.contentPath, locale], loadContent)
</script>

<style scoped>
/* Markdown content styling - Mobile First */
.markdown-content :deep(h2) {
  @apply text-xl sm:text-2xl font-bold text-slate-900 mt-8 sm:mt-10 mb-3 sm:mb-4 pb-2 border-b border-slate-200;
}

.markdown-content :deep(h3) {
  @apply text-lg sm:text-xl font-semibold text-slate-800 mt-6 sm:mt-8 mb-2 sm:mb-3;
}

.markdown-content :deep(h4) {
  @apply text-base sm:text-lg font-semibold text-slate-800 mt-5 sm:mt-6 mb-2;
}

.markdown-content :deep(p) {
  @apply text-sm sm:text-base text-slate-600 leading-relaxed mb-3 sm:mb-4;
}

.markdown-content :deep(ul) {
  @apply list-disc list-inside space-y-1.5 sm:space-y-2 mb-3 sm:mb-4 text-slate-600 text-sm sm:text-base;
}

.markdown-content :deep(ol) {
  @apply list-decimal list-inside space-y-1.5 sm:space-y-2 mb-3 sm:mb-4 text-slate-600 text-sm sm:text-base;
}

.markdown-content :deep(li) {
  @apply leading-relaxed;
}

.markdown-content :deep(strong) {
  @apply font-semibold text-slate-900;
}

.markdown-content :deep(code) {
  @apply bg-slate-100 px-1 sm:px-1.5 py-0.5 rounded text-xs sm:text-sm font-mono text-blue-700 break-words;
}

.markdown-content :deep(pre) {
  @apply bg-slate-900 text-slate-100 p-3 sm:p-4 rounded-lg overflow-x-auto mb-3 sm:mb-4 text-xs sm:text-sm;
}

.markdown-content :deep(pre code) {
  @apply bg-transparent text-slate-100 p-0;
}

.markdown-content :deep(a) {
  @apply text-blue-600 hover:text-blue-800 underline break-words;
}

.markdown-content :deep(blockquote) {
  @apply border-l-4 border-blue-500 pl-3 sm:pl-4 py-2 my-3 sm:my-4 bg-blue-50 rounded-r-lg italic text-slate-700 text-sm sm:text-base;
}

.markdown-content :deep(table) {
  @apply w-full border-collapse my-4 sm:my-6 text-xs sm:text-sm;
}

.markdown-content :deep(th) {
  @apply bg-slate-100 text-left p-2 sm:p-3 font-semibold text-slate-900 border border-slate-200;
}

.markdown-content :deep(td) {
  @apply p-2 sm:p-3 border border-slate-200 text-slate-600;
}

.markdown-content :deep(hr) {
  @apply my-6 sm:my-8 border-slate-200;
}

.markdown-content :deep(img) {
  @apply rounded-lg sm:rounded-xl shadow-lg border border-slate-200 my-4 sm:my-6 w-full;
}

/* Screenshot frame styling */
.markdown-content :deep(.screenshot-frame) {
  @apply rounded-lg sm:rounded-xl overflow-hidden;
}

/* Responsive table wrapper for overflow */
.markdown-content :deep(table) {
  @apply block overflow-x-auto whitespace-nowrap;
}

/* Tipbox content styling - ensure tables render properly inside info/tip boxes */
.markdown-content :deep(.tipbox-content table) {
  @apply w-full border-collapse my-2 text-xs sm:text-sm;
}

.markdown-content :deep(.tipbox-content th) {
  @apply bg-white/50 text-left p-1.5 sm:p-2 font-semibold border border-current/20;
}

.markdown-content :deep(.tipbox-content td) {
  @apply p-1.5 sm:p-2 border border-current/20;
}

.markdown-content :deep(.tipbox-content p) {
  @apply mb-2 last:mb-0;
}

.markdown-content :deep(.tipbox-content ul),
.markdown-content :deep(.tipbox-content ol) {
  @apply mb-2 last:mb-0;
}
</style>
