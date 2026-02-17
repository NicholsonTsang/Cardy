<template>
  <div class="min-h-screen bg-gradient-to-b from-slate-50 to-white overflow-x-hidden">
    <!-- Header -->
    <UnifiedHeader mode="landing" />

    <div class="flex pt-14 sm:pt-16">
      <!-- Sidebar Navigation -->
      <aside 
        :class="[
          'fixed left-0 top-14 sm:top-16 h-[calc(100vh-3.5rem)] sm:h-[calc(100vh-4rem)] bg-white/95 backdrop-blur-sm border-r border-slate-200/80 overflow-y-auto transition-transform duration-300 z-30 w-72',
          sidebarOpen ? 'translate-x-0' : '-translate-x-full lg:translate-x-0'
        ]"
      >
        <!-- Mobile Close Button -->
        <button 
          @click="sidebarOpen = false"
          class="lg:hidden absolute top-4 right-4 p-2 text-slate-500 hover:text-slate-700 rounded-lg hover:bg-slate-100 transition-colors"
        >
          <i class="pi pi-times text-xl"></i>
        </button>

        <!-- Search -->
        <div class="p-5 border-b border-slate-100">
          <div class="relative">
            <i class="pi pi-search absolute left-3.5 top-1/2 -translate-y-1/2 text-slate-400"></i>
            <input
              v-model="searchQuery"
              type="text"
              :placeholder="$t('docs.search_placeholder')"
              class="w-full pl-10 pr-4 py-3 bg-slate-50 border border-slate-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-blue-500/50 focus:border-blue-400 transition-all placeholder:text-slate-400"
            />
          </div>
        </div>

        <!-- Navigation Tree -->
        <nav class="p-4">
          <div v-for="category in filteredCategories" :key="category.id" class="mb-2">
            <!-- Category Header -->
            <button
              @click="toggleCategory(category.id)"
              class="flex items-center justify-between w-full px-3 py-2.5 text-left text-sm font-semibold text-slate-700 hover:bg-slate-50 rounded-xl transition-all group"
            >
              <span class="flex items-center gap-2.5">
                <div class="w-8 h-8 rounded-lg bg-gradient-to-br from-blue-500/10 to-purple-500/10 flex items-center justify-center group-hover:from-blue-500/20 group-hover:to-purple-500/20 transition-all">
                  <i :class="[category.icon, 'text-blue-600']"></i>
                </div>
                {{ $t(`docs.categories.${category.id}.title`) }}
              </span>
              <i :class="['pi transition-transform duration-200', expandedCategories.includes(category.id) ? 'pi-chevron-down' : 'pi-chevron-right']" class="text-xs text-slate-400"></i>
            </button>

            <!-- Category Articles -->
            <transition name="expand">
              <ul v-if="expandedCategories.includes(category.id)" class="mt-1 ml-4 space-y-0.5">
                <li v-for="article in category.articles" :key="article.id">
                  <button
                    @click="selectArticle(category.id, article.id)"
                    :class="[
                      'flex items-center gap-2.5 w-full px-3 py-2.5 text-sm rounded-xl transition-all duration-200',
                      activeArticle === article.id
                        ? 'bg-gradient-to-r from-blue-50 to-purple-50 text-blue-700 font-medium border border-blue-100/50'
                        : 'text-slate-600 hover:bg-slate-50 hover:text-slate-900'
                    ]"
                  >
                    <span class="w-1.5 h-1.5 rounded-full transition-all" :class="activeArticle === article.id ? 'bg-blue-600 scale-125' : 'bg-slate-300'"></span>
                    {{ $t(`docs.categories.${category.id}.articles.${article.id}.title`) }}
                  </button>
                </li>
              </ul>
            </transition>
          </div>
        </nav>
      </aside>

      <!-- Mobile Sidebar Toggle -->
      <button
        @click="sidebarOpen = true"
        class="lg:hidden fixed bottom-6 right-6 z-40 w-14 h-14 bg-gradient-to-br from-blue-600 to-purple-600 text-white rounded-2xl shadow-lg shadow-blue-500/30 hover:shadow-xl hover:shadow-blue-500/40 transition-all flex items-center justify-center"
      >
        <i class="pi pi-bars text-xl"></i>
      </button>

      <!-- Sidebar Overlay (Mobile) -->
      <transition name="fade">
        <div 
          v-if="sidebarOpen"
          @click="sidebarOpen = false"
          class="lg:hidden fixed inset-0 bg-slate-900/50 backdrop-blur-sm z-20"
        ></div>
      </transition>

      <!-- Main Content -->
      <main class="flex-1 lg:ml-72 min-h-[calc(100vh-3.5rem)] sm:min-h-[calc(100vh-4rem)] overflow-x-hidden">
        <div class="max-w-3xl mx-auto px-4 sm:px-6 py-8 sm:py-10 lg:py-14 pb-24 lg:pb-14 overflow-x-hidden">
          <!-- Breadcrumb -->
          <nav class="flex items-center gap-1.5 sm:gap-2 text-xs sm:text-sm text-slate-500 mb-6 sm:mb-8 flex-wrap">
            <router-link to="/docs" class="hover:text-blue-600 transition-colors flex items-center gap-1 sm:gap-1.5 shrink-0">
              <i class="pi pi-book text-[10px] sm:text-xs"></i>
              {{ $t('docs.title') }}
            </router-link>
            <i class="pi pi-chevron-right text-[8px] sm:text-[10px] text-slate-300 shrink-0"></i>
            <span class="text-slate-400 hidden sm:inline">{{ $t(`docs.categories.${activeCategory}.title`) }}</span>
            <i class="pi pi-chevron-right text-[8px] sm:text-[10px] text-slate-300 hidden sm:inline shrink-0"></i>
            <span class="text-slate-700 font-medium truncate max-w-[200px] sm:max-w-none">{{ $t(`docs.categories.${activeCategory}.articles.${activeArticle}.title`) }}</span>
          </nav>

          <!-- Article Content -->
          <article class="docs-prose">
            <!-- Article Header -->
            <header class="mb-8 sm:mb-10 pb-6 sm:pb-8 border-b border-slate-200/80">
              <h1 class="text-2xl sm:text-3xl lg:text-4xl font-bold text-slate-900 mb-3 sm:mb-4 tracking-tight">
                {{ $t(`docs.categories.${activeCategory}.articles.${activeArticle}.title`) }}
              </h1>
              <p class="text-base sm:text-lg text-slate-600 leading-relaxed">
                {{ $t(`docs.categories.${activeCategory}.articles.${activeArticle}.description`) }}
              </p>
            </header>

            <!-- Dynamic Article Content -->
            <component :is="currentArticleComponent" />
          </article>

          <!-- Navigation Footer -->
          <div class="mt-10 sm:mt-16 pt-8 sm:pt-10 border-t border-slate-200/80">
            <div class="flex flex-col sm:flex-row justify-between gap-3 sm:gap-4">
              <!-- Previous Article -->
              <button
                v-if="previousArticle"
                @click="selectArticle(previousArticle.categoryId, previousArticle.articleId)"
                class="flex items-center gap-3 sm:gap-4 px-4 sm:px-5 py-3 sm:py-4 bg-white border border-slate-200 rounded-xl sm:rounded-2xl hover:border-blue-200 hover:bg-gradient-to-r hover:from-blue-50/50 hover:to-transparent transition-all group text-left flex-1"
              >
                <div class="w-9 h-9 sm:w-10 sm:h-10 rounded-lg sm:rounded-xl bg-slate-100 flex items-center justify-center group-hover:bg-blue-100 transition-colors shrink-0">
                  <i class="pi pi-arrow-left text-sm sm:text-base text-slate-500 group-hover:text-blue-600 transition-colors"></i>
                </div>
                <div class="min-w-0">
                  <div class="text-[10px] sm:text-xs text-slate-400 uppercase tracking-wider font-medium mb-0.5">{{ $t('docs.previous') }}</div>
                  <div class="text-xs sm:text-sm font-semibold text-slate-700 group-hover:text-blue-600 transition-colors truncate">
                    {{ $t(`docs.categories.${previousArticle.categoryId}.articles.${previousArticle.articleId}.title`) }}
                  </div>
                </div>
              </button>
              <div v-else class="hidden sm:block flex-1"></div>

              <!-- Next Article -->
              <button
                v-if="nextArticle"
                @click="selectArticle(nextArticle.categoryId, nextArticle.articleId)"
                class="flex items-center gap-3 sm:gap-4 px-4 sm:px-5 py-3 sm:py-4 bg-white border border-slate-200 rounded-xl sm:rounded-2xl hover:border-blue-200 hover:bg-gradient-to-l hover:from-blue-50/50 hover:to-transparent transition-all group text-right flex-1"
              >
                <div class="flex-1 min-w-0">
                  <div class="text-[10px] sm:text-xs text-slate-400 uppercase tracking-wider font-medium mb-0.5">{{ $t('docs.next') }}</div>
                  <div class="text-xs sm:text-sm font-semibold text-slate-700 group-hover:text-blue-600 transition-colors truncate">
                    {{ $t(`docs.categories.${nextArticle.categoryId}.articles.${nextArticle.articleId}.title`) }}
                  </div>
                </div>
                <div class="w-9 h-9 sm:w-10 sm:h-10 rounded-lg sm:rounded-xl bg-slate-100 flex items-center justify-center group-hover:bg-blue-100 transition-colors shrink-0">
                  <i class="pi pi-arrow-right text-sm sm:text-base text-slate-500 group-hover:text-blue-600 transition-colors"></i>
                </div>
              </button>
              <div v-else class="hidden sm:block flex-1"></div>
            </div>
          </div>

          <!-- Feedback Section -->
          <div class="mt-8 sm:mt-10 p-4 sm:p-6 bg-gradient-to-br from-slate-50 to-slate-100/50 rounded-xl sm:rounded-2xl border border-slate-200/50">
            <div class="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-3 sm:gap-4">
              <div>
                <h3 class="font-semibold text-slate-900 text-base sm:text-lg">{{ $t('docs.feedback.title') }}</h3>
                <p class="text-xs sm:text-sm text-slate-600 mt-0.5">{{ $t('docs.feedback.subtitle') }}</p>
              </div>
              <div class="flex gap-2 sm:gap-3 w-full sm:w-auto">
                <button 
                  @click="submitFeedback(true)"
                  :class="[
                    'flex items-center justify-center gap-1.5 sm:gap-2 px-3 sm:px-5 py-2 sm:py-2.5 rounded-lg sm:rounded-xl transition-all font-medium text-sm flex-1 sm:flex-auto',
                    feedbackGiven === true 
                      ? 'bg-green-100 text-green-700 border-2 border-green-300 shadow-sm' 
                      : 'bg-white border-2 border-slate-200 text-slate-600 hover:border-green-300 hover:text-green-600 hover:bg-green-50'
                  ]"
                >
                  <i class="pi pi-thumbs-up text-sm"></i>
                  <span>{{ $t('docs.feedback.yes') }}</span>
                </button>
                <button 
                  @click="submitFeedback(false)"
                  :class="[
                    'flex items-center justify-center gap-1.5 sm:gap-2 px-3 sm:px-5 py-2 sm:py-2.5 rounded-lg sm:rounded-xl transition-all font-medium text-sm flex-1 sm:flex-auto',
                    feedbackGiven === false 
                      ? 'bg-red-100 text-red-700 border-2 border-red-300 shadow-sm' 
                      : 'bg-white border-2 border-slate-200 text-slate-600 hover:border-red-300 hover:text-red-600 hover:bg-red-50'
                  ]"
                >
                  <i class="pi pi-thumbs-down text-sm"></i>
                  <span>{{ $t('docs.feedback.no') }}</span>
                </button>
              </div>
            </div>
            <transition name="fade">
              <p v-if="feedbackGiven !== null" class="mt-3 sm:mt-4 text-xs sm:text-sm text-slate-600 bg-white/80 px-3 sm:px-4 py-2 sm:py-2.5 rounded-lg inline-block">
                ✨ {{ $t('docs.feedback.thanks') }}
              </p>
            </transition>
          </div>
        </div>
      </main>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, watch, defineAsyncComponent, h, type Component } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useI18n } from 'vue-i18n'
import UnifiedHeader from '@/components/Layout/UnifiedHeader.vue'

// Article Content Components
import GettingStartedOverview from './docs/GettingStartedOverview.vue'
import CreateFirstProject from './docs/CreateFirstProject.vue'
import AddContentItems from './docs/AddContentItems.vue'
import ProjectSettings from './docs/ProjectSettings.vue'
import ContentModes from './docs/ContentModes.vue'
import AIConfiguration from './docs/AIConfiguration.vue'
import TranslationGuide from './docs/TranslationGuide.vue'
import QRCodeSharing from './docs/QRCodeSharing.vue'
import SubscriptionPlans from './docs/SubscriptionPlans.vue'
import CreditManagement from './docs/CreditManagement.vue'
import BulkImport from './docs/BulkImport.vue'
import TemplateLibrary from './docs/TemplateLibrary.vue'
import MCPProjectSetup from './docs/MCPProjectSetup.vue'

const { t } = useI18n()
const route = useRoute()
const router = useRouter()

// State
const sidebarOpen = ref(false)
const searchQuery = ref('')
const expandedCategories = ref<string[]>(['getting_started'])
const activeCategory = ref('getting_started')
const activeArticle = ref('overview')
const feedbackGiven = ref<boolean | null>(null)

// Documentation Structure
interface Article {
  id: string
  component: Component
}

interface Category {
  id: string
  icon: string
  articles: Article[]
}

const categories: Category[] = [
  {
    id: 'getting_started',
    icon: 'pi pi-play',
    articles: [
      { id: 'overview', component: GettingStartedOverview },
      { id: 'create_project', component: CreateFirstProject },
      { id: 'add_content', component: AddContentItems },
    ]
  },
  {
    id: 'project_management',
    icon: 'pi pi-folder',
    articles: [
      { id: 'settings', component: ProjectSettings },
      { id: 'content_modes', component: ContentModes },
      { id: 'ai_config', component: AIConfiguration },
    ]
  },
  {
    id: 'features',
    icon: 'pi pi-star',
    articles: [
      { id: 'translations', component: TranslationGuide },
      { id: 'qr_sharing', component: QRCodeSharing },
      { id: 'bulk_import', component: BulkImport },
      { id: 'templates', component: TemplateLibrary },
    ]
  },
  {
    id: 'billing',
    icon: 'pi pi-credit-card',
    articles: [
      { id: 'subscription', component: SubscriptionPlans },
      { id: 'credits', component: CreditManagement },
    ]
  },
  {
    id: 'automation',
    icon: 'pi pi-bolt',
    articles: [
      { id: 'mcp_setup', component: MCPProjectSetup },
    ]
  }
]

// Computed
const filteredCategories = computed(() => {
  if (!searchQuery.value.trim()) return categories
  
  const query = searchQuery.value.toLowerCase()
  return categories.map(category => ({
    ...category,
    articles: category.articles.filter(article => {
      const title = t(`docs.categories.${category.id}.articles.${article.id}.title`).toLowerCase()
      const desc = t(`docs.categories.${category.id}.articles.${article.id}.description`).toLowerCase()
      return title.includes(query) || desc.includes(query)
    })
  })).filter(cat => cat.articles.length > 0)
})

const currentArticleComponent = computed(() => {
  const category = categories.find(c => c.id === activeCategory.value)
  const article = category?.articles.find(a => a.id === activeArticle.value)
  return article?.component || GettingStartedOverview
})

const flatArticles = computed(() => {
  const result: { categoryId: string; articleId: string }[] = []
  categories.forEach(cat => {
    cat.articles.forEach(article => {
      result.push({ categoryId: cat.id, articleId: article.id })
    })
  })
  return result
})

const currentIndex = computed(() => {
  return flatArticles.value.findIndex(
    a => a.categoryId === activeCategory.value && a.articleId === activeArticle.value
  )
})

const previousArticle = computed(() => {
  if (currentIndex.value <= 0) return null
  return flatArticles.value[currentIndex.value - 1]
})

const nextArticle = computed(() => {
  if (currentIndex.value >= flatArticles.value.length - 1) return null
  return flatArticles.value[currentIndex.value + 1]
})

// Methods
const toggleCategory = (categoryId: string) => {
  const index = expandedCategories.value.indexOf(categoryId)
  if (index > -1) {
    expandedCategories.value.splice(index, 1)
  } else {
    expandedCategories.value.push(categoryId)
  }
}

const selectArticle = (categoryId: string, articleId: string) => {
  activeCategory.value = categoryId
  activeArticle.value = articleId
  feedbackGiven.value = null
  sidebarOpen.value = false
  
  // Expand the category if not already
  if (!expandedCategories.value.includes(categoryId)) {
    expandedCategories.value.push(categoryId)
  }
  
  // Update URL
  router.push({ query: { category: categoryId, article: articleId } })
  
  // Scroll to top
  window.scrollTo({ top: 0, behavior: 'smooth' })
}

const submitFeedback = (helpful: boolean) => {
  feedbackGiven.value = helpful
  // Could send feedback to backend here
}

// Initialize from URL
watch(() => route.query, (query) => {
  if (query.category && typeof query.category === 'string') {
    activeCategory.value = query.category
    if (!expandedCategories.value.includes(query.category)) {
      expandedCategories.value.push(query.category)
    }
  }
  if (query.article && typeof query.article === 'string') {
    activeArticle.value = query.article
  }
}, { immediate: true })
</script>

<style scoped>
.expand-enter-active,
.expand-leave-active {
  transition: all 0.25s ease-out;
  overflow: hidden;
}

.expand-enter-from,
.expand-leave-to {
  opacity: 0;
  max-height: 0;
}

.expand-enter-to,
.expand-leave-from {
  opacity: 1;
  max-height: 500px;
}

.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.2s ease;
}

.fade-enter-from,
.fade-leave-to {
  opacity: 0;
}

/* Enhanced Prose Styling */
.docs-prose :deep(h2) {
  @apply text-2xl font-bold text-slate-900 mt-12 mb-5 pb-3 border-b border-slate-200/70;
  letter-spacing: -0.01em;
}

.docs-prose :deep(h2:first-child) {
  @apply mt-0;
}

.docs-prose :deep(h3) {
  @apply text-lg font-semibold text-slate-800 mt-10 mb-4;
}

.docs-prose :deep(p) {
  @apply text-slate-600 leading-[1.8] mb-5;
  font-size: 1rem;
}

.docs-prose :deep(ul) {
  @apply space-y-3 mb-6 text-slate-600;
  list-style: none;
  padding-left: 0;
}

.docs-prose :deep(ul li) {
  @apply leading-[1.7] pl-6 relative;
}

.docs-prose :deep(ul li::before) {
  content: '';
  @apply absolute left-0 top-[0.65rem] w-1.5 h-1.5 bg-blue-500 rounded-full;
}

.docs-prose :deep(ol) {
  @apply space-y-3 mb-6 text-slate-600;
  counter-reset: item;
  list-style: none;
  padding-left: 0;
}

.docs-prose :deep(ol li) {
  @apply leading-[1.7] pl-8 relative;
  counter-increment: item;
}

.docs-prose :deep(ol li::before) {
  content: counter(item);
  @apply absolute left-0 top-0 w-6 h-6 bg-blue-100 text-blue-700 rounded-lg text-xs font-semibold flex items-center justify-center;
}

.docs-prose :deep(strong) {
  @apply font-semibold text-slate-800;
}

.docs-prose :deep(code) {
  @apply bg-slate-100 px-2 py-1 rounded-md text-sm font-mono text-blue-700;
}

.docs-prose :deep(pre) {
  @apply bg-slate-900 text-slate-100 p-5 rounded-xl overflow-x-auto mb-6 text-sm leading-relaxed;
}

.docs-prose :deep(img) {
  @apply rounded-xl shadow-lg border border-slate-200 my-8;
}

.docs-prose :deep(a) {
  @apply text-blue-600 hover:text-blue-700 underline decoration-blue-300 underline-offset-2 hover:decoration-blue-500 transition-colors;
}

.docs-prose :deep(blockquote) {
  @apply border-l-4 border-blue-500 pl-5 py-1 my-6 italic text-slate-600 bg-blue-50/50 pr-4 rounded-r-lg;
}

/* Responsive Tables */
.docs-prose :deep(table) {
  @apply w-full text-sm mb-6 border-collapse rounded-lg overflow-hidden;
  display: block;
  overflow-x: auto;
  -webkit-overflow-scrolling: touch;
}

.docs-prose :deep(table th),
.docs-prose :deep(table td) {
  @apply px-3 py-2.5 border border-slate-200 text-left;
  min-width: 100px;
}

.docs-prose :deep(table th) {
  @apply bg-slate-100 font-semibold text-slate-800 whitespace-nowrap;
}

.docs-prose :deep(table td) {
  @apply text-slate-600;
}

/* Alternating row colors for better readability */
.docs-prose :deep(table tbody tr:nth-child(even) td) {
  @apply bg-slate-50/70;
}

.docs-prose :deep(table tbody tr:hover td) {
  @apply bg-blue-50/60;
}

/* First column often contains labels - make them stand out */
.docs-prose :deep(table td:first-child) {
  @apply font-medium text-slate-700;
}

/* Tipbox styles - ensure they display properly in docs */
.docs-prose :deep(.tipbox) {
  @apply my-6;
}

.docs-prose :deep(.tipbox + .tipbox) {
  @apply mt-4;
}

.docs-prose :deep(.tipbox-content p) {
  @apply mb-2 text-sm leading-relaxed;
}

.docs-prose :deep(.tipbox-content p:last-child) {
  @apply mb-0;
}

.docs-prose :deep(.tipbox-content table) {
  @apply my-3 text-sm;
  display: table;
}

.docs-prose :deep(.tipbox-content th) {
  @apply bg-white/60 py-1.5 px-2;
}

.docs-prose :deep(.tipbox-content td) {
  @apply py-1.5 px-2;
}

/* Prevent text overflow */
.docs-prose :deep(p),
.docs-prose :deep(li) {
  word-break: break-word;
  overflow-wrap: break-word;
}

/* Feature cards spacing */
.docs-prose :deep(.grid) {
  @apply my-6;
}
</style>
