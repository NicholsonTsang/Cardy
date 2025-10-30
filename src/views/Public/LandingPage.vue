<template>
  <div class="min-h-screen bg-white">
    <!-- Unified Header Component -->
    <UnifiedHeader 
      mode="landing"
      @scroll-to="scrollToSection"
      @toggle-mobile-menu="mobileMenuOpen = !mobileMenuOpen"
    />

    <!-- Mobile Menu -->
    <transition name="slide-down">
      <div v-if="mobileMenuOpen" class="fixed top-16 left-0 right-0 bg-white backdrop-blur-xl border-b border-slate-200 shadow-xl z-40 lg:hidden">
        <div class="px-6 py-6 space-y-1">
          <a @click="scrollToSection('about')" 
             class="block text-slate-700 hover:text-white hover:bg-gradient-to-r hover:from-blue-600 hover:to-purple-600 font-medium py-3 px-4 rounded-xl transition-all cursor-pointer">
            {{ $t('landing.nav.about') }}
          </a>
          <a @click="scrollToSection('demo')" 
             class="block text-slate-700 hover:text-white hover:bg-gradient-to-r hover:from-blue-600 hover:to-purple-600 font-medium py-3 px-4 rounded-xl transition-all cursor-pointer">
            {{ $t('landing.nav.demo') }}
          </a>
          <a @click="scrollToSection('pricing')" 
             class="block text-slate-700 hover:text-white hover:bg-gradient-to-r hover:from-blue-600 hover:to-purple-600 font-medium py-3 px-4 rounded-xl transition-all cursor-pointer">
            {{ $t('landing.nav.pricing') }}
          </a>
          <a @click="scrollToSection('contact')" 
             class="block text-slate-700 hover:text-white hover:bg-gradient-to-r hover:from-blue-600 hover:to-purple-600 font-medium py-3 px-4 rounded-xl transition-all cursor-pointer">
            {{ $t('landing.nav.contact') }}
          </a>
          
          <div class="pt-4 space-y-3">
            <Button 
              @click="router.push('/login'); mobileMenuOpen = false"
              class="w-full bg-slate-100 text-slate-700 hover:bg-slate-200 border-0 py-4 font-semibold rounded-xl min-h-[52px]"
            >
              {{ $t('landing.nav.sign_in') }}
            </Button>
            <Button 
              @click="router.push('/signup'); mobileMenuOpen = false"
              class="w-full bg-gradient-to-r from-blue-600 to-purple-600 hover:from-blue-700 hover:to-purple-700 text-white border-0 py-4 font-semibold shadow-lg rounded-xl min-h-[52px]"
            >
              {{ $t('landing.nav.start_free_trial') }}
            </Button>
          </div>
        </div>
      </div>
    </transition>
    
    <!-- Hero Section -->
    <section class="relative min-h-screen flex items-center justify-center overflow-hidden bg-gradient-to-br from-slate-950 via-blue-950 to-purple-950 pt-20">
      <!-- Animated gradient mesh background -->
      <div class="absolute inset-0">
        <div class="absolute inset-0 bg-[radial-gradient(ellipse_at_top,rgba(120,180,255,0.15),transparent_50%)]"></div>
        <div class="absolute inset-0 bg-[radial-gradient(ellipse_at_bottom_right,rgba(180,120,255,0.15),transparent_50%)]"></div>
        <div class="absolute inset-0 bg-[radial-gradient(ellipse_at_bottom_left,rgba(255,120,180,0.1),transparent_50%)]"></div>
      </div>

      <!-- Floating orbs with animation -->
      <div class="absolute inset-0 overflow-hidden">
        <div class="floating-orb absolute top-20 left-10 w-72 h-72 bg-blue-500/20 rounded-full blur-3xl"></div>
        <div class="floating-orb-delayed absolute bottom-20 right-10 w-96 h-96 bg-purple-500/20 rounded-full blur-3xl"></div>
        <div class="floating-orb-slow absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[40rem] h-[40rem] bg-cyan-500/10 rounded-full blur-3xl"></div>
      </div>
      
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-16 sm:py-20 relative z-10">
        <div class="text-center">
          <h1 class="text-4xl sm:text-5xl md:text-6xl lg:text-7xl font-black mb-6 sm:mb-8 leading-tight text-white animate-fade-in-up">
            {{ $t('landing.hero.title_line1') }}<br class="hidden sm:block" />
            <span class="bg-gradient-to-r from-yellow-400 via-orange-500 to-pink-500 bg-clip-text text-transparent">
              {{ $t('landing.hero.title_line2') }}
            </span><br class="hidden sm:block" />
            {{ $t('landing.hero.title_line3') }}
          </h1>
          
          <p class="text-lg sm:text-xl md:text-2xl text-blue-100/90 max-w-4xl mx-auto mb-10 sm:mb-12 leading-relaxed font-light animate-fade-in-up animation-delay-200 px-2">
            {{ $t('landing.hero.subtitle_part1') }}
            <span class="font-semibold text-white">{{ $t('landing.hero.subtitle_highlight') }}</span> {{ $t('landing.hero.subtitle_part2') }}
          </p>
          
          <div class="flex flex-col sm:flex-row gap-4 sm:gap-6 justify-center items-stretch sm:items-center mb-16 animate-fade-in-up animation-delay-400 px-4 sm:px-0">
            <Button 
              @click="scrollToContact"
              class="bg-gradient-to-r from-blue-600 to-purple-600 hover:from-blue-700 hover:to-purple-700 border-0 px-8 sm:px-10 py-4 sm:py-5 text-base sm:text-lg font-bold text-white shadow-2xl hover:shadow-blue-500/25 transition-all transform hover:scale-105 min-h-[56px]"
            >
              <i class="pi pi-rocket mr-2"></i>
              <span>{{ $t('landing.hero.cta_pilot') }}</span>
            </Button>
            <Button 
              @click="scrollToSection('about')"
              class="group border-2 border-white/30 bg-white/5 hover:bg-white/10 backdrop-blur-sm px-8 sm:px-10 py-4 sm:py-5 text-base sm:text-lg font-semibold text-white hover:border-white/50 transition-all transform hover:scale-105 min-h-[56px]"
            >
              <span>{{ $t('landing.hero.cta_learn') }}</span>
              <i class="pi pi-arrow-down ml-2"></i>
            </Button>
          </div>
        </div>

        <!-- Scroll indicator -->
        <div class="absolute bottom-8 left-1/2 -translate-x-1/2 animate-bounce">
          <div class="w-6 h-10 border-2 border-white/30 rounded-full flex justify-center">
            <div class="w-1 h-3 bg-white/60 rounded-full mt-2 animate-scroll"></div>
          </div>
        </div>
      </div>
    </section>

    <!-- About Section -->
    <section id="about" class="py-20 sm:py-32 bg-gradient-to-b from-slate-50 to-white relative overflow-hidden">
      <div class="absolute top-0 right-0 w-96 h-96 bg-gradient-to-br from-blue-100/50 to-purple-100/50 rounded-full blur-3xl"></div>
      <div class="absolute bottom-0 left-0 w-96 h-96 bg-gradient-to-br from-emerald-100/50 to-cyan-100/50 rounded-full blur-3xl"></div>
      
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 relative">
        <div class="text-center mb-12 sm:mb-20">
          <h2 class="text-3xl sm:text-4xl md:text-5xl lg:text-6xl font-black text-slate-900 mb-4 sm:mb-6">
            {{ $t('landing.about.title') }} <span class="bg-gradient-to-r from-blue-600 via-purple-600 to-pink-600 bg-clip-text text-transparent">{{ $t('landing.about.title_highlight') }}</span>
          </h2>
          <p class="text-lg sm:text-xl text-slate-600 max-w-3xl mx-auto px-2">
            {{ $t('landing.about.intro') }}
          </p>
        </div>
        
        <div class="max-w-4xl mx-auto space-y-6 mb-12">
          <p class="text-lg text-slate-700 text-center leading-relaxed">
            {{ $t('landing.about.description1') }}
          </p>
          <p class="text-lg text-slate-700 text-center leading-relaxed">
            {{ $t('landing.about.description2') }}
          </p>
          <p class="text-lg text-slate-700 text-center leading-relaxed font-semibold">
            {{ $t('landing.about.description3') }}
          </p>
        </div>

        <div class="text-center px-4">
          <Button 
            @click="scrollToSection('demo')"
            class="border-2 border-blue-600 text-blue-600 hover:bg-blue-600 hover:text-white bg-transparent px-6 sm:px-8 py-3 sm:py-4 font-semibold rounded-xl transition-all min-h-[48px]"
          >
            {{ $t('landing.about.cta') }}
          </Button>
        </div>
      </div>
    </section>

    <!-- Promotion & Solution Showcase Video Section -->
    <section id="demo" class="py-20 sm:py-32 bg-gradient-to-br from-slate-950 via-blue-950 to-purple-950 relative overflow-hidden">
      <div class="absolute inset-0">
        <div class="absolute inset-0 bg-[radial-gradient(ellipse_at_center,rgba(120,180,255,0.1),transparent_70%)]"></div>
      </div>
      
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 relative">
        <div class="text-center mb-12 sm:mb-16">
          <h2 class="text-3xl sm:text-4xl md:text-5xl lg:text-6xl font-black text-white mb-4 sm:mb-6">
            {{ $t('landing.demo.title') }} <span class="bg-gradient-to-r from-emerald-400 via-cyan-400 to-blue-400 bg-clip-text text-transparent">{{ $t('landing.demo.title_highlight') }}</span>
          </h2>
          <p class="text-lg sm:text-xl text-blue-100/80 max-w-3xl mx-auto px-2">
            {{ $t('landing.demo.subtitle') }}
          </p>
        </div>
        
        <div class="max-w-5xl mx-auto">
          <!-- Video Placeholder -->
          <div class="relative bg-slate-900/50 backdrop-blur rounded-3xl overflow-hidden shadow-2xl border border-white/10 group">
            <div class="aspect-video flex items-center justify-center bg-gradient-to-br from-blue-600/20 to-purple-600/20">
              <div class="text-center">
                <div class="w-24 h-24 bg-white/20 backdrop-blur-xl rounded-full flex items-center justify-center mx-auto mb-6 group-hover:scale-110 transition-transform cursor-pointer">
                  <i class="pi pi-play text-white text-4xl"></i>
                </div>
                <p class="text-white text-lg font-semibold">{{ $t('landing.demo.video_coming_soon') }}</p>
                <p class="text-blue-200 text-sm mt-2">{{ $t('landing.demo.video_description') }}</p>
              </div>
            </div>
          </div>

          <!-- Demo Card Preview -->
          <div class="grid md:grid-cols-2 gap-8 mt-16">
            <div class="relative mx-auto animate-on-scroll">
              <div class="absolute inset-0 bg-gradient-to-r from-blue-600 to-purple-600 rounded-3xl blur-3xl opacity-50"></div>
              <div class="relative bg-white rounded-3xl p-6 shadow-2xl max-w-sm transform hover:scale-105 transition-all duration-500">
                <div class="aspect-[2/3] bg-gradient-to-br from-blue-600 via-purple-600 to-pink-600 rounded-2xl overflow-hidden relative group">
                  <img 
                    :src="demoCardImageUrl" 
                    :alt="$t('landing.demo.card_title')"
                    class="w-full h-full object-cover group-hover:scale-110 transition-transform duration-700"
                  />
                  <div class="absolute inset-0 bg-gradient-to-t from-black/80 via-black/20 to-transparent"></div>
                  
                  <div class="absolute bottom-4 left-4 right-4 text-white">
                    <h3 class="text-2xl font-bold mb-2">{{ demoCardTitle }}</h3>
                    <p class="text-sm opacity-90">{{ demoCardSubtitle }}</p>
                  </div>
                  
                  <div class="absolute top-4 right-4">
                    <div class="relative">
                      <div class="absolute inset-0 bg-white rounded-xl blur-xl opacity-50"></div>
                      <div class="relative bg-white rounded-xl p-2 shadow-2xl">
                        <QrCode :value="sampleQrUrl" :size="48" />
                      </div>
                    </div>
                  </div>
                </div>
                
                <div class="mt-6 text-center">
                  <Button 
                    :label="$t('landing.demo.try_live_demo')"
                    icon="pi pi-external-link"
                    @click="openDemoCard"
                    class="w-full bg-gradient-to-r from-blue-600 to-purple-600 hover:from-blue-700 hover:to-purple-700 text-white border-0 py-4 font-semibold shadow-lg hover:shadow-xl transition-all min-h-[52px]"
                  />
                </div>
              </div>
            </div>

            <div class="space-y-6 animate-on-scroll" style="animation-delay: 200ms">
              <h3 class="text-3xl font-bold text-white mb-8">{{ $t('landing.demo.experience_features') }}</h3>
              
              <div v-for="(feature, index) in demoFeatures" :key="index" class="flex gap-4">
                <div class="w-12 h-12 bg-gradient-to-br from-blue-600/20 to-purple-600/20 backdrop-blur-sm rounded-xl flex items-center justify-center flex-shrink-0">
                  <i :class="`pi ${feature.icon} text-blue-400 text-xl`"></i>
                </div>
                <div>
                  <h4 class="text-lg font-semibold text-white mb-1">{{ feature.title }}</h4>
                  <p class="text-blue-100/70 leading-relaxed">{{ feature.description }}</p>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>

    <!-- How CardStudio Works -->
    <section class="py-20 sm:py-32 bg-white relative overflow-hidden">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div class="text-center mb-12 sm:mb-20">
          <h2 class="text-3xl sm:text-4xl md:text-5xl lg:text-6xl font-black text-slate-900 mb-4 sm:mb-6">
            How CardStudio <span class="bg-gradient-to-r from-violet-600 to-purple-600 bg-clip-text text-transparent">Works</span>
          </h2>
          <p class="text-lg sm:text-xl text-slate-600 max-w-3xl mx-auto px-2">
            Simple, seamless, and engaging—follow the visitor journey in just 4 steps.
          </p>
        </div>
        
        <!-- Steps with connecting line -->
        <div class="relative">
          <div class="hidden lg:block absolute top-1/2 left-0 right-0 h-0.5 bg-gradient-to-r from-blue-200 via-purple-200 to-pink-200"></div>
          
          <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-8">
            <div v-for="(step, index) in howItWorksSteps" :key="index" class="relative group">
              <div class="bg-white rounded-3xl p-8 shadow-xl hover:shadow-2xl transition-all duration-500 border-2 border-slate-200 hover:border-purple-300 h-full">
                <div class="absolute -top-4 left-8 w-8 h-8 bg-gradient-to-br from-purple-600 to-pink-600 rounded-full flex items-center justify-center text-white font-bold text-sm shadow-lg">
                  {{ index + 1 }}
                </div>

                <div class="w-20 h-20 bg-gradient-to-br from-purple-100 to-pink-100 rounded-2xl flex items-center justify-center mb-6 mx-auto group-hover:scale-110 transition-transform">
                  <i :class="`pi ${step.icon} text-purple-600 text-3xl`"></i>
                </div>

                <h3 class="text-xl font-bold text-slate-900 mb-3 text-center">{{ step.title }}</h3>
                <p class="text-slate-600 leading-relaxed text-center">{{ step.description }}</p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>

    <!-- Key Features -->
    <section class="py-32 bg-gradient-to-b from-slate-50 to-white">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div class="text-center mb-20">
          <h2 class="text-4xl sm:text-5xl lg:text-6xl font-black text-slate-900 mb-6">
            Why Choose <span class="bg-gradient-to-r from-amber-600 to-orange-600 bg-clip-text text-transparent">CardStudio</span>
          </h2>
        </div>
        
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
          <div v-for="(feature, index) in keyFeatures" :key="feature.title" 
               class="group relative animate-on-scroll"
               :style="{ animationDelay: (index * 100) + 'ms' }">
            <div class="absolute inset-0 bg-gradient-to-r from-blue-600 to-purple-600 rounded-3xl opacity-0 group-hover:opacity-100 transition-opacity duration-300 blur-xl"></div>
            <div class="relative bg-white rounded-3xl p-8 shadow-lg hover:shadow-2xl transition-all duration-300 border border-slate-200 h-full">
              <div class="w-16 h-16 bg-gradient-to-br from-blue-100 to-purple-100 rounded-2xl flex items-center justify-center mb-6 group-hover:scale-110 transition-transform">
                <i :class="`pi ${feature.icon} text-blue-600 text-2xl`"></i>
              </div>
              <h3 class="text-xl font-bold text-slate-900 mb-3">{{ feature.title }}</h3>
              <p class="text-slate-600 leading-relaxed">{{ feature.description }}</p>
            </div>
          </div>
        </div>
      </div>
    </section>

    <!-- Versatile Applications Carousel -->
    <section class="py-32 bg-white">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div class="text-center mb-20">
          <h2 class="text-4xl sm:text-5xl lg:text-6xl font-black text-slate-900 mb-6">
            Where CardStudio <span class="bg-gradient-to-r from-emerald-600 to-teal-600 bg-clip-text text-transparent">Shines</span>
          </h2>
          <p class="text-xl text-slate-600 max-w-3xl mx-auto">
            CardStudio transforms venues into interactive destinations—driving engagement and connections. Swipe to explore:
          </p>
        </div>

        <Carousel :value="applications" :numVisible="3" :numScroll="1" :responsiveOptions="carouselResponsiveOptions" 
                  :circular="true" :autoplayInterval="5000" class="custom-carousel">
          <template #item="slotProps">
            <div class="p-4">
              <div class="bg-gradient-to-br from-white to-slate-50 rounded-3xl overflow-hidden shadow-xl hover:shadow-2xl transition-all duration-500 transform hover:-translate-y-2 border border-slate-200 h-full">
                <div class="p-8">
                  <div class="w-20 h-20 bg-gradient-to-br from-emerald-100 to-teal-100 rounded-2xl flex items-center justify-center mb-6 mx-auto">
                    <i :class="`pi ${slotProps.data.icon} text-emerald-600 text-3xl`"></i>
                  </div>
                  <h3 class="text-2xl font-bold text-slate-900 mb-2 text-center">{{ slotProps.data.name }}</h3>
                  <p class="text-sm font-semibold text-emerald-600 mb-4 text-center">{{ slotProps.data.role }}</p>
                  <div class="mb-4">
                    <p class="text-xs text-slate-500 font-semibold mb-2">Alternatives for:</p>
                    <p class="text-sm text-slate-600 italic">{{ slotProps.data.alternatives }}</p>
                  </div>
                  <ul class="space-y-3">
                    <li v-for="(benefit, idx) in slotProps.data.benefits" :key="idx" 
                        class="flex items-start gap-2 text-sm text-slate-600">
                      <i class="pi pi-check-circle text-emerald-500 mt-0.5 flex-shrink-0"></i>
                      <span>{{ benefit }}</span>
                    </li>
                  </ul>
                </div>
              </div>
            </div>
          </template>
        </Carousel>

        <div class="text-center mt-12 px-4">
          <Button 
            @click="scrollToContact"
            class="border-2 border-blue-600 text-blue-600 hover:bg-blue-600 hover:text-white bg-transparent px-6 sm:px-8 py-3 sm:py-4 font-semibold rounded-xl transition-all min-h-[48px]"
          >
            Find Your Fit – Contact Us for a Pilot
          </Button>
        </div>
      </div>
    </section>

    <!-- Benefits Section -->
    <section class="py-32 bg-gradient-to-b from-slate-50 to-white">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div class="text-center mb-20">
          <h2 class="text-4xl sm:text-5xl lg:text-6xl font-black text-slate-900 mb-6">
            Real <span class="bg-gradient-to-r from-blue-600 to-purple-600 bg-clip-text text-transparent">Benefits</span>
          </h2>
        </div>

        <div class="grid lg:grid-cols-2 gap-12">
          <!-- For Venues -->
          <div class="bg-white rounded-3xl p-10 shadow-xl border border-slate-200">
            <h3 class="text-3xl font-bold text-slate-900 mb-8 text-center">For Venues</h3>
            <ul class="space-y-6">
              <li v-for="(benefit, index) in venueBenefits" :key="index" 
                  class="flex items-start gap-4 group">
                <div class="w-10 h-10 bg-gradient-to-br from-blue-100 to-purple-100 rounded-xl flex items-center justify-center flex-shrink-0 group-hover:scale-110 transition-transform">
                  <i class="pi pi-check text-blue-600 text-lg"></i>
                </div>
                <p class="text-lg text-slate-700 leading-relaxed">{{ benefit }}</p>
              </li>
            </ul>
          </div>

          <!-- For Visitors -->
          <div class="bg-white rounded-3xl p-10 shadow-xl border border-slate-200">
            <h3 class="text-3xl font-bold text-slate-900 mb-8 text-center">For Visitors</h3>
            <ul class="space-y-6">
              <li v-for="(benefit, index) in visitorBenefits" :key="index" 
                  class="flex items-start gap-4 group">
                <div class="w-10 h-10 bg-gradient-to-br from-emerald-100 to-teal-100 rounded-xl flex items-center justify-center flex-shrink-0 group-hover:scale-110 transition-transform">
                  <i class="pi pi-check text-emerald-600 text-lg"></i>
                </div>
                <p class="text-lg text-slate-700 leading-relaxed">{{ benefit }}</p>
              </li>
            </ul>
          </div>
        </div>
      </div>
    </section>

    <!-- Sustainability Impact -->
    <section class="py-32 bg-gradient-to-br from-emerald-50 to-teal-50">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div class="text-center mb-20">
          <h2 class="text-4xl sm:text-5xl lg:text-6xl font-black text-slate-900 mb-6">
            Innovation Meets <span class="bg-gradient-to-r from-emerald-600 to-teal-600 bg-clip-text text-transparent">Responsibility</span>
          </h2>
        </div>

        <div class="grid lg:grid-cols-2 gap-12 max-w-6xl mx-auto">
          <!-- Traditional Way -->
          <div class="bg-white rounded-3xl p-10 shadow-xl border-2 border-slate-200">
            <h3 class="text-2xl font-bold text-slate-900 mb-8 text-center">Traditional Materials</h3>
            <div class="space-y-6">
              <div class="flex items-center gap-4">
                <div class="text-4xl">📄</div>
                <div>
                  <p class="font-semibold text-slate-900">10,000 brochures or leaflet printed</p>
                  <p class="text-sm text-slate-600">Per 10,000 visitors annually</p>
                </div>
              </div>
              <div class="flex items-center gap-4">
                <div class="text-4xl">🗑️</div>
                <div>
                  <p class="font-semibold text-slate-900">95% discarded within 24 hours</p>
                </div>
              </div>
              <div class="flex items-center gap-4">
                <div class="text-4xl">🌳</div>
                <div>
                  <p class="font-semibold text-red-600">500kg of paper waste</p>
                </div>
              </div>
            </div>
          </div>

          <!-- CardStudio Way -->
          <div class="bg-gradient-to-br from-emerald-600 to-teal-600 rounded-3xl p-10 shadow-2xl text-white">
            <h3 class="text-2xl font-bold mb-8 text-center">With CardStudio</h3>
            <div class="space-y-6">
              <div class="flex items-center gap-4">
                <div class="text-4xl">🎴</div>
                <div>
                  <p class="font-semibold">10,000 collectible cards</p>
                </div>
              </div>
              <div class="flex items-center gap-4">
                <div class="text-4xl">💚</div>
                <div>
                  <p class="font-semibold">80% kept as keepsakes</p>
                </div>
              </div>
              <div class="flex items-center gap-4">
                <div class="text-4xl">♻️</div>
                <div>
                  <p class="font-semibold text-yellow-300">95% reduction in paper waste</p>
                </div>
              </div>
              <div class="flex items-center gap-4">
                <div class="text-4xl">📱</div>
                <div>
                  <p class="font-semibold">Digital content = zero ongoing waste</p>
                </div>
              </div>
            </div>
          </div>
        </div>

        <div class="mt-16 bg-white rounded-3xl p-10 shadow-xl border border-emerald-200 max-w-4xl mx-auto">
          <h3 class="text-2xl font-bold text-slate-900 mb-6 text-center">Your Impact</h3>
          <div class="grid md:grid-cols-2 gap-6">
            <div class="flex items-start gap-3">
              <i class="pi pi-check-circle text-emerald-600 text-xl mt-1"></i>
              <p class="text-slate-700">Meet ESG sustainability mandates</p>
            </div>
            <div class="flex items-start gap-3">
              <i class="pi pi-check-circle text-emerald-600 text-xl mt-1"></i>
              <p class="text-slate-700">Reduce printing costs by 70-80%</p>
            </div>
            <div class="flex items-start gap-3">
              <i class="pi pi-check-circle text-emerald-600 text-xl mt-1"></i>
              <p class="text-slate-700">Position as environmental leader</p>
            </div>
            <div class="flex items-start gap-3">
              <i class="pi pi-check-circle text-emerald-600 text-xl mt-1"></i>
              <p class="text-slate-700">Appeal to eco-conscious visitors</p>
            </div>
          </div>
        </div>
      </div>
    </section>

    <!-- Simple Pricing -->
    <section id="pricing" class="py-20 sm:py-32 bg-gradient-to-br from-slate-950 via-blue-950 to-purple-950 relative overflow-hidden">
      <div class="absolute inset-0">
        <div class="absolute inset-0 bg-[radial-gradient(ellipse_at_top_left,rgba(120,180,255,0.15),transparent_50%)]"></div>
        <div class="absolute inset-0 bg-[radial-gradient(ellipse_at_bottom_right,rgba(180,120,255,0.15),transparent_50%)]"></div>
      </div>
      
      <div class="max-w-5xl mx-auto px-4 sm:px-6 lg:px-8 relative">
        <div class="text-center mb-12 sm:mb-20">
          <h2 class="text-3xl sm:text-4xl md:text-5xl lg:text-6xl font-black text-white mb-4 sm:mb-6">
            Simple <span class="bg-gradient-to-r from-blue-400 via-cyan-400 to-emerald-400 bg-clip-text text-transparent">Pricing</span>
          </h2>
          <p class="text-lg sm:text-xl text-blue-100/80 max-w-3xl mx-auto px-2">
            Transparent Pay-Per-Card Pricing
          </p>
        </div>

        <div class="bg-white/5 backdrop-blur-xl rounded-3xl border border-white/10 overflow-hidden">
          <div class="bg-gradient-to-r from-blue-600/10 to-purple-600/10 p-8 border-b border-white/10">
            <div class="text-center">
              <div class="flex items-baseline justify-center gap-2 mb-2">
                <span class="text-6xl lg:text-7xl font-black text-white">$2</span>
                <span class="text-2xl text-blue-300">USD</span>
              </div>
              <p class="text-xl text-blue-200">per card</p>
            </div>
          </div>

          <div class="p-8 lg:p-12">
            <div class="grid lg:grid-cols-2 gap-12 mb-8">
              <div>
                <h3 class="text-2xl font-bold text-white mb-6">Pricing Details</h3>
                <div class="space-y-4 text-blue-100">
                  <div class="bg-white/5 rounded-xl p-4">
                    <div class="flex justify-between items-center">
                      <span>Cost to you</span>
                      <span class="font-bold text-white">$2.00 per card</span>
                    </div>
                  </div>
                  <div class="bg-white/5 rounded-xl p-4">
                    <div class="flex justify-between items-center">
                      <span>Suggested retail</span>
                      <span class="font-bold text-white">$3-7 USD</span>
                    </div>
                  </div>
                  <div class="bg-emerald-500/10 rounded-xl p-4 border border-emerald-500/20">
                    <div class="flex justify-between items-center">
                      <span>Your profit margin</span>
                      <span class="font-bold text-emerald-400">$1-5 per card</span>
                    </div>
                  </div>
                  <div class="text-sm text-blue-300 pt-4">
                    <i class="pi pi-info-circle mr-2"></i>
                    Alternative: Complimentary model (free to visitors, $2 cost to you)
                  </div>
                </div>
              </div>

              <div>
                <h3 class="text-2xl font-bold text-white mb-6">Everything Included</h3>
                <ul class="space-y-4">
                  <li v-for="feature in pricingFeatures" :key="feature" 
                      class="flex items-center gap-3 text-blue-100">
                    <div class="w-6 h-6 bg-emerald-500/20 rounded-full flex items-center justify-center flex-shrink-0">
                      <i class="pi pi-check text-emerald-400 text-sm"></i>
                    </div>
                    <span>{{ feature }}</span>
                  </li>
                </ul>
              </div>
            </div>

            <div class="bg-white/5 rounded-xl p-6 mb-8">
              <div class="flex items-center justify-between">
                <div>
                  <p class="text-white font-semibold mb-1">Minimum Order</p>
                  <p class="text-blue-200 text-sm">{{ minBatchQuantity }} cards per order</p>
                </div>
                <div class="text-4xl">📦</div>
              </div>
            </div>

            <div class="text-center px-4">
              <Button 
                label="Contact Us for a Pilot"
                icon="pi pi-arrow-right"
                iconPos="right"
                @click="scrollToContact"
                class="bg-gradient-to-r from-blue-600 to-purple-600 hover:from-blue-700 hover:to-purple-700 text-white border-0 px-8 sm:px-10 py-4 sm:py-5 text-base sm:text-lg font-bold shadow-2xl hover:shadow-blue-500/25 transition-all transform hover:scale-105 min-h-[56px]"
              />
              <p class="text-blue-300 text-sm mt-4">No monthly subscriptions • No setup fees • No hidden costs</p>
            </div>
          </div>
        </div>
      </div>
    </section>

    <!-- Collaboration Models -->
    <section class="py-32 bg-white">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div class="text-center mb-20">
          <h2 class="text-4xl sm:text-5xl lg:text-6xl font-black text-slate-900 mb-6">
            Partner with <span class="bg-gradient-to-r from-blue-600 to-purple-600 bg-clip-text text-transparent">CardStudio</span>
          </h2>
          <p class="text-xl text-slate-600 max-w-3xl mx-auto">
            Beyond buying cards - three ways to grow with CardStudio.
          </p>
        </div>

        <div class="grid lg:grid-cols-3 gap-8">
          <!-- Become a Client -->
          <div class="bg-gradient-to-br from-blue-50 to-purple-50 rounded-3xl p-8 shadow-xl hover:shadow-2xl transition-all duration-300 border-2 border-blue-200 hover:border-blue-400">
            <div class="w-16 h-16 bg-gradient-to-br from-blue-600 to-purple-600 rounded-2xl flex items-center justify-center mb-6 mx-auto">
              <i class="pi pi-shopping-cart text-white text-2xl"></i>
            </div>
            <h3 class="text-2xl font-bold text-slate-900 mb-4 text-center">Become a Client</h3>
            <p class="text-sm text-slate-600 mb-6 text-center">For: Venues, museums, attractions, events, conferences, hotels</p>
            
            <div class="mb-6">
              <p class="font-semibold text-slate-900 mb-3">You Get:</p>
              <ul class="space-y-2">
                <li class="flex items-start gap-2 text-sm text-slate-700">
                  <i class="pi pi-check text-blue-600 mt-0.5"></i>
                  <span>Free full platform access (Card Design Management, Digital Content Management, Cloud Hosting)</span>
                </li>
                <li class="flex items-start gap-2 text-sm text-slate-700">
                  <i class="pi pi-check text-blue-600 mt-0.5"></i>
                  <span>Card printing logistic & shipping handled</span>
                </li>
                <li class="flex items-start gap-2 text-sm text-slate-700">
                  <i class="pi pi-check text-blue-600 mt-0.5"></i>
                  <span>Technical support and training</span>
                </li>
                <li class="flex items-start gap-2 text-sm text-slate-700">
                  <i class="pi pi-check text-blue-600 mt-0.5"></i>
                  <span>Focus on your contents and visitors. We handle the tech</span>
                </li>
              </ul>
            </div>

            <p class="text-sm font-semibold text-blue-600 mb-6 text-center">Best if: You want to enhance your visitor experience immediately.</p>

            <Button 
              label="Start Your Pilot"
              @click="scrollToContact"
              class="w-full bg-gradient-to-r from-blue-600 to-purple-600 hover:from-blue-700 hover:to-purple-700 text-white border-0 py-4 font-semibold rounded-xl shadow-lg min-h-[52px]"
            />
          </div>

          <!-- Regional Partner -->
          <div class="bg-gradient-to-br from-emerald-50 to-teal-50 rounded-3xl p-8 shadow-xl hover:shadow-2xl transition-all duration-300 border-2 border-emerald-200 hover:border-emerald-400">
            <div class="w-16 h-16 bg-gradient-to-br from-emerald-600 to-teal-600 rounded-2xl flex items-center justify-center mb-6 mx-auto">
              <i class="pi pi-globe text-white text-2xl"></i>
            </div>
            <h3 class="text-2xl font-bold text-slate-900 mb-4 text-center">Regional Partner</h3>
            <p class="text-sm text-slate-600 mb-6 text-center">For: Agencies, consultants with venue networks</p>
            
            <div class="mb-6">
              <p class="font-semibold text-slate-900 mb-3">You Get:</p>
              <ul class="space-y-2">
                <li class="flex items-start gap-2 text-sm text-slate-700">
                  <i class="pi pi-check text-emerald-600 mt-0.5"></i>
                  <span>Represent CardStudio in your territory</span>
                </li>
                <li class="flex items-start gap-2 text-sm text-slate-700">
                  <i class="pi pi-check text-emerald-600 mt-0.5"></i>
                  <span>Revenue share on clients you bring</span>
                </li>
                <li class="flex items-start gap-2 text-sm text-slate-700">
                  <i class="pi pi-check text-emerald-600 mt-0.5"></i>
                  <span>Exclusive territory options available</span>
                </li>
                <li class="flex items-start gap-2 text-sm text-slate-700">
                  <i class="pi pi-check text-emerald-600 mt-0.5"></i>
                  <span>Sales training, marketing support, co-branding</span>
                </li>
              </ul>
            </div>

            <p class="text-sm font-semibold text-emerald-600 mb-6 text-center">Best if: You have venue relationships and want recurring revenue.</p>

            <Button 
              label="Explore Partnership"
              @click="scrollToContact"
              class="w-full bg-gradient-to-r from-blue-600 to-purple-600 hover:from-blue-700 hover:to-purple-700 text-white border-0 py-4 font-semibold rounded-xl shadow-lg min-h-[52px]"
            />
          </div>

          <!-- Software License -->
          <div class="bg-gradient-to-br from-orange-50 to-pink-50 rounded-3xl p-8 shadow-xl hover:shadow-2xl transition-all duration-300 border-2 border-orange-200 hover:border-orange-400">
            <div class="w-16 h-16 bg-gradient-to-br from-orange-600 to-pink-600 rounded-2xl flex items-center justify-center mb-6 mx-auto">
              <i class="pi pi-code text-white text-2xl"></i>
            </div>
            <h3 class="text-2xl font-bold text-slate-900 mb-4 text-center">Software License</h3>
            <p class="text-sm text-slate-600 mb-6 text-center">For: Enterprises, large agencies, platform entrepreneurs</p>
            
            <div class="mb-6">
              <p class="font-semibold text-slate-900 mb-3">You Get:</p>
              <ul class="space-y-2">
                <li class="flex items-start gap-2 text-sm text-slate-700">
                  <i class="pi pi-check text-orange-600 mt-0.5"></i>
                  <span>Own the entire platform</span>
                </li>
                <li class="flex items-start gap-2 text-sm text-slate-700">
                  <i class="pi pi-check text-orange-600 mt-0.5"></i>
                  <span>White-label under your brand</span>
                </li>
                <li class="flex items-start gap-2 text-sm text-slate-700">
                  <i class="pi pi-check text-orange-600 mt-0.5"></i>
                  <span>Set your own pricing</span>
                </li>
                <li class="flex items-start gap-2 text-sm text-slate-700">
                  <i class="pi pi-check text-orange-600 mt-0.5"></i>
                  <span>Keep 100% of your revenue</span>
                </li>
                <li class="flex items-start gap-2 text-sm text-slate-700">
                  <i class="pi pi-check text-orange-600 mt-0.5"></i>
                  <span>Serve unlimited clients</span>
                </li>
              </ul>
            </div>

            <p class="text-sm font-semibold text-orange-600 mb-6 text-center">Best if: You're building a scalable multi-client business.</p>

            <Button 
              label="Inquire About Licensing"
              @click="scrollToContact"
              class="w-full bg-gradient-to-r from-blue-600 to-purple-600 hover:from-blue-700 hover:to-purple-700 text-white border-0 py-4 font-semibold rounded-xl shadow-lg min-h-[52px]"
            />
          </div>
        </div>

        <div class="text-center mt-12 px-4">
          <p class="text-base sm:text-lg text-slate-600 mb-6">
            Not sure which fits? Schedule a strategy call to find your best path forward.
          </p>
          <Button 
            label="Schedule a Call"
            icon="pi pi-calendar"
            @click="scrollToContact"
            class="bg-gradient-to-r from-blue-600 to-purple-600 hover:from-blue-700 hover:to-purple-700 text-white border-0 px-8 sm:px-10 py-4 text-base sm:text-lg font-bold shadow-lg min-h-[52px]"
          />
        </div>
      </div>
    </section>

    <!-- FAQ Section -->
    <section class="py-32 bg-gradient-to-b from-slate-50 to-white">
      <div class="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8">
        <div class="text-center mb-16">
          <h2 class="text-4xl sm:text-5xl font-black text-slate-900">
            Frequently Asked <span class="bg-gradient-to-r from-blue-600 to-purple-600 bg-clip-text text-transparent">Questions</span>
          </h2>
        </div>
        
        <div class="space-y-4">
          <div v-for="(faq, index) in faqs" :key="index"
               class="bg-white rounded-2xl shadow-lg overflow-hidden hover:shadow-xl transition-all duration-300 border border-slate-200">
            <button
              @click="toggleFaq(index)"
              class="w-full px-8 py-6 text-left flex items-center justify-between hover:bg-slate-50 transition-colors duration-200 group"
            >
              <h3 class="text-lg font-semibold text-slate-900 pr-4">{{ faq.question }}</h3>
              <i :class="['pi', openFaqIndex === index ? 'pi-minus' : 'pi-plus', 'text-slate-500 group-hover:text-blue-600 transition-all duration-200']"></i>
            </button>
            <transition name="collapse">
              <div v-if="openFaqIndex === index" 
                   class="px-8 pb-6">
                <p class="text-slate-600 leading-relaxed whitespace-pre-line">{{ faq.answer }}</p>
              </div>
            </transition>
          </div>
        </div>

        <div class="text-center mt-12">
          <p class="text-lg text-slate-600 mb-6">
            Still have questions? Reach out via our Contact form.
          </p>
        </div>
      </div>
    </section>

    <!-- Contact Section with Form -->
    <section id="contact" class="py-20 sm:py-32 bg-gradient-to-br from-blue-600 via-purple-600 to-pink-600 relative overflow-hidden">
      <div class="absolute inset-0">
        <div class="absolute inset-0 bg-[url('/grid.svg')] bg-center opacity-10"></div>
      </div>
      
      <div class="max-w-5xl mx-auto px-4 sm:px-6 lg:px-8 relative">
        <div class="text-center mb-12 sm:mb-16">
          <h2 class="text-3xl sm:text-4xl md:text-5xl lg:text-6xl font-black text-white mb-4 sm:mb-6">
            Get Started with<br />
            <span class="text-yellow-300">CardStudio Today</span>
          </h2>
          <p class="text-lg sm:text-xl text-white/90 max-w-3xl mx-auto px-2">
            Ready to transform your visitor experience? Whether you're planning a pilot, exploring partnerships, or have questions—we're here to help.
          </p>
        </div>
        
        <div class="bg-white rounded-3xl p-8 lg:p-12 shadow-2xl">
          <!-- What You Can Do -->
          <div class="mb-10">
            <h3 class="text-2xl font-bold text-slate-900 mb-6">What You Can Do:</h3>
            <div class="grid md:grid-cols-2 gap-4">
              <div class="flex items-start gap-3">
                <div class="text-2xl">🚀</div>
                <div>
                  <p class="font-semibold text-slate-900">Request a Pilot</p>
                  <p class="text-sm text-slate-600">Test CardStudio at your venue with a customized trial program.</p>
                </div>
              </div>
              <div class="flex items-start gap-3">
                <div class="text-2xl">💡</div>
                <div>
                  <p class="font-semibold text-slate-900">Request Information</p>
                  <p class="text-sm text-slate-600">Learn more about pricing, features, and how CardStudio fits your needs.</p>
                </div>
              </div>
              <div class="flex items-start gap-3">
                <div class="text-2xl">🤝</div>
                <div>
                  <p class="font-semibold text-slate-900">Explore Partnerships</p>
                  <p class="text-sm text-slate-600">Discover regional partner, licensing, or collaboration opportunities.</p>
                </div>
              </div>
              <div class="flex items-start gap-3">
                <div class="text-2xl">❓</div>
                <div>
                  <p class="font-semibold text-slate-900">Ask Questions</p>
                  <p class="text-sm text-slate-600">Get expert answers about implementation, customization, or technical details.</p>
                </div>
              </div>
            </div>
          </div>

          <!-- Contact Form -->
          <form @submit.prevent="handleSubmit" class="space-y-6">
            <div class="grid md:grid-cols-2 gap-6">
              <div>
                <label class="block text-sm font-semibold text-slate-900 mb-2">Full Name *</label>
                <InputText 
                  v-model="contactForm.fullName" 
                  required 
                  class="w-full"
                  placeholder="John Doe"
                />
              </div>
              <div>
                <label class="block text-sm font-semibold text-slate-900 mb-2">Organization/Venue Name *</label>
                <InputText 
                  v-model="contactForm.organizationName" 
                  required 
                  class="w-full"
                  placeholder="Museum of History"
                />
              </div>
            </div>

            <div class="grid md:grid-cols-2 gap-6">
              <div>
                <label class="block text-sm font-semibold text-slate-900 mb-2">Email *</label>
                <InputText 
                  v-model="contactForm.email" 
                  type="email" 
                  required 
                  class="w-full"
                  placeholder="john@example.com"
                />
              </div>
              <div>
                <label class="block text-sm font-semibold text-slate-900 mb-2">Phone Number</label>
                <InputText 
                  v-model="contactForm.phone" 
                  class="w-full"
                  placeholder="+1 234 567 8900"
                />
              </div>
            </div>

            <div class="grid md:grid-cols-2 gap-6">
              <div>
                <label class="block text-sm font-semibold text-slate-900 mb-2">Organization Type *</label>
                <Dropdown 
                  v-model="contactForm.organizationType" 
                  :options="organizationTypes" 
                  required 
                  class="w-full"
                  placeholder="Select type"
                />
              </div>
              <div>
                <label class="block text-sm font-semibold text-slate-900 mb-2">Monthly Visitor Count *</label>
                <Dropdown 
                  v-model="contactForm.visitorCount" 
                  :options="visitorCountOptions" 
                  required 
                  class="w-full"
                  placeholder="Select range"
                />
              </div>
            </div>

            <div>
              <label class="block text-sm font-semibold text-slate-900 mb-2">Inquiry Type *</label>
              <Dropdown 
                v-model="contactForm.inquiryType" 
                :options="inquiryTypes" 
                required 
                class="w-full"
                placeholder="Select inquiry type"
              />
            </div>

            <div>
              <label class="block text-sm font-semibold text-slate-900 mb-2">Tell Us More About Your Needs</label>
              <Textarea 
                v-model="contactForm.message" 
                rows="5" 
                class="w-full"
                placeholder="Share your goals, challenges, or specific questions. The more details you provide, the better we can assist you."
              />
            </div>

            <div class="text-center">
              <Button 
                type="submit"
                label="Submit Inquiry"
                icon="pi pi-send"
                iconPos="right"
                :loading="submitting"
                class="bg-gradient-to-r from-blue-600 to-purple-600 hover:from-blue-700 hover:to-purple-700 text-white border-0 px-8 sm:px-10 py-4 sm:py-5 text-base sm:text-lg font-bold shadow-xl hover:shadow-2xl transition-all transform hover:scale-105 min-h-[56px]"
              />
            </div>
          </form>

          <!-- Alternative Contact Methods -->
          <div class="mt-12 pt-12 border-t border-slate-200">
            <h3 class="text-xl font-bold text-slate-900 mb-6 text-center">Alternative Contact Methods</h3>
            <div class="grid md:grid-cols-2 gap-6">
              <a :href="`mailto:${contactEmail}`" 
                 class="flex items-center gap-4 p-6 bg-gradient-to-br from-blue-50 to-purple-50 rounded-2xl hover:shadow-lg transition-all border border-blue-200">
                <div class="w-12 h-12 bg-gradient-to-br from-blue-600 to-purple-600 rounded-xl flex items-center justify-center flex-shrink-0">
                  <i class="pi pi-envelope text-white text-lg"></i>
                </div>
                <div>
                  <p class="font-semibold text-slate-900">Email</p>
                  <p class="text-blue-600 text-sm">{{ contactEmail }}</p>
                </div>
              </a>
              
              <a :href="contactWhatsApp" target="_blank"
                 class="flex items-center gap-4 p-6 bg-gradient-to-br from-emerald-50 to-teal-50 rounded-2xl hover:shadow-lg transition-all border border-emerald-200">
                <div class="w-12 h-12 bg-gradient-to-br from-emerald-600 to-teal-600 rounded-xl flex items-center justify-center flex-shrink-0">
                  <i class="pi pi-whatsapp text-white text-lg"></i>
                </div>
                <div>
                  <p class="font-semibold text-slate-900">WhatsApp</p>
                  <p class="text-emerald-600 text-sm">{{ contactWhatsAppDisplay }}</p>
                </div>
              </a>
            </div>
          </div>

          <div class="mt-8 text-center">
            <p class="text-sm text-slate-500">
              <i class="pi pi-shield mr-2"></i>
              Your information is secure and will only be used to respond to your inquiry.
            </p>
          </div>
        </div>
      </div>
    </section>

    <!-- Footer -->
    <footer class="bg-slate-900 text-white py-16">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div class="grid md:grid-cols-3 gap-12 mb-12">
          <!-- Brand -->
          <div>
            <div class="flex items-center gap-3 mb-4">
              <div class="w-10 h-10 bg-gradient-to-br from-blue-600 to-purple-600 rounded-xl flex items-center justify-center">
                <i class="pi pi-id-card text-white text-xl"></i>
              </div>
              <span class="text-xl font-bold">CardStudio</span>
            </div>
            <p class="text-slate-400">
              AI-Powered Interactive Souvenir Cards for Museums, Attractions, and Events Worldwide
            </p>
          </div>

          <!-- Quick Links -->
          <div>
            <h4 class="font-bold text-lg mb-4">Quick Links</h4>
            <ul class="space-y-2">
              <li><a @click="scrollToSection('about')" class="text-slate-400 hover:text-white transition-colors cursor-pointer">About</a></li>
              <li><a @click="scrollToSection('demo')" class="text-slate-400 hover:text-white transition-colors cursor-pointer">Demo</a></li>
              <li><a @click="scrollToSection('pricing')" class="text-slate-400 hover:text-white transition-colors cursor-pointer">Pricing</a></li>
              <li><a @click="scrollToSection('contact')" class="text-slate-400 hover:text-white transition-colors cursor-pointer">Contact</a></li>
            </ul>
          </div>

          <!-- Contact Info -->
          <div>
            <h4 class="font-bold text-lg mb-4">Contact</h4>
            <ul class="space-y-2">
              <li class="flex items-center gap-2 text-slate-400">
                <i class="pi pi-envelope"></i>
                <a :href="`mailto:${contactEmail}`" class="hover:text-white transition-colors">{{ contactEmail }}</a>
              </li>
              <li class="flex items-center gap-2 text-slate-400">
                <i class="pi pi-phone"></i>
                <span>{{ contactWhatsAppDisplay }}</span>
              </li>
              <li class="flex items-center gap-2 text-slate-400">
                <i class="pi pi-whatsapp"></i>
                <a :href="contactWhatsApp" target="_blank" class="hover:text-white transition-colors">WhatsApp Chat</a>
              </li>
            </ul>
          </div>
        </div>

        <div class="pt-8 border-t border-slate-800">
          <div class="flex flex-col md:flex-row justify-between items-center gap-4">
            <p class="text-slate-500 text-sm">© 2025 CardStudio. All rights reserved.</p>
            <div class="flex gap-6 text-sm">
              <a href="#" class="text-slate-400 hover:text-white transition-colors">Privacy Policy</a>
              <a href="#" class="text-slate-400 hover:text-white transition-colors">Terms of Service</a>
              <a :href="`mailto:${contactEmail}`" class="text-slate-400 hover:text-white transition-colors">Contact</a>
            </div>
          </div>
        </div>
      </div>
    </footer>

    <!-- Floating CTA Button -->
    <transition name="slide-up">
      <div v-if="showFloatingCTA" class="fixed bottom-4 sm:bottom-8 right-4 sm:right-8 z-50">
        <Button
          @click="scrollToContact"
          class="bg-gradient-to-r from-blue-600 to-purple-600 hover:from-blue-700 hover:to-purple-700 text-white border-0 px-5 sm:px-6 py-3 sm:py-4 font-semibold shadow-2xl hover:shadow-3xl transition-all transform hover:scale-110 pulse-glow rounded-full min-h-[52px]"
        >
          <i class="pi pi-rocket mr-2"></i>
          <span class="text-sm sm:text-base">Get Started</span>
        </Button>
      </div>
    </transition>
  </div>
</template>

<script setup>
import { ref, onMounted, onUnmounted } from 'vue'
import { useRouter } from 'vue-router'
import { useI18n } from 'vue-i18n'
import Button from 'primevue/button'
import Carousel from 'primevue/carousel'
import InputText from 'primevue/inputtext'
import Textarea from 'primevue/textarea'
import Dropdown from 'primevue/dropdown'
import QrCode from 'qrcode.vue'
import { useToast } from 'primevue/usetoast'
import UnifiedHeader from '@/components/Layout/UnifiedHeader.vue'

const router = useRouter()
const toast = useToast()

// Navigation state
const mobileMenuOpen = ref(false)
const showFloatingCTA = ref(false)

// Sample QR code URL
const sampleQrUrl = ref(import.meta.env.VITE_SAMPLE_QR_URL || `${window.location.origin}/c/demo-ancient-artifacts`)

// Demo card configuration
const demoCardTitle = import.meta.env.VITE_DEMO_CARD_TITLE || 'Ancient Mysteries'
const demoCardSubtitle = import.meta.env.VITE_DEMO_CARD_SUBTITLE || 'AI-Powered Museum Guide'
const demoCardImageUrl = import.meta.env.VITE_DEFAULT_CARD_IMAGE_URL || 'https://images.unsplash.com/photo-1564399580075-5dfe19c205f3?w=400&h=600&fit=crop&crop=center'

// Contact configuration
const contactEmail = import.meta.env.VITE_CONTACT_EMAIL || 'inquiry@cardstudio.org'
const contactWhatsApp = import.meta.env.VITE_CONTACT_WHATSAPP_URL || 'https://wa.me/85255992159'
const contactWhatsAppDisplay = import.meta.env.VITE_CONTACT_PHONE || '+852 5599 2159'
const minBatchQuantity = import.meta.env.VITE_BATCH_MIN_QUANTITY || 100

// FAQ functionality
const openFaqIndex = ref(-1)
const toggleFaq = (index) => {
  openFaqIndex.value = openFaqIndex.value === index ? -1 : index
}

// Contact form
const contactForm = ref({
  fullName: '',
  organizationName: '',
  email: '',
  phone: '',
  organizationType: null,
  visitorCount: null,
  inquiryType: null,
  message: ''
})

const submitting = ref(false)

const handleSubmit = async () => {
  // Form validation
  if (!contactForm.value.fullName || !contactForm.value.organizationName || !contactForm.value.email || 
      !contactForm.value.organizationType || !contactForm.value.visitorCount || !contactForm.value.inquiryType) {
    toast.add({
      severity: 'warn',
      summary: 'Missing Information',
      detail: 'Please fill in all required fields',
      life: 5000
    })
    return
  }

  submitting.value = true
  
  // Simulate form submission (replace with actual API call)
  setTimeout(() => {
    toast.add({
      severity: 'success',
      summary: 'Inquiry Sent',
      detail: 'Thank you! We will contact you shortly.',
      life: 5000
    })
    
    // Reset form
    contactForm.value = {
      fullName: '',
      organizationName: '',
      email: '',
      phone: '',
      organizationType: null,
      visitorCount: null,
      inquiryType: null,
      message: ''
    }
    
    submitting.value = false
  }, 1500)
}

// Scroll handling
const handleScroll = () => {
  showFloatingCTA.value = window.scrollY > window.innerHeight * 0.8
}

// Intersection Observer for animations
const observeElements = () => {
  document.documentElement.classList.add('js-animations-ready')
  
  const observer = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
      if (entry.isIntersecting) {
        entry.target.classList.add('animate-visible')
      }
    })
  }, { 
    threshold: 0.1,
    rootMargin: '50px'
  })
  
  const animateElements = document.querySelectorAll('.animate-on-scroll')
  animateElements.forEach(el => {
    observer.observe(el)
  })
  
  return observer
}

onMounted(() => {
  window.addEventListener('scroll', handleScroll, { passive: true })
  
  setTimeout(() => {
    observeElements()
  }, 100)
})

onUnmounted(() => {
  window.removeEventListener('scroll', handleScroll)
})

// Navigation functions
const scrollToSection = (sectionId) => {
  const element = document.getElementById(sectionId)
  if (element) {
    const offset = 80
    const elementPosition = element.getBoundingClientRect().top + window.scrollY
    window.scrollTo({
      top: elementPosition - offset,
      behavior: 'smooth'
    })
  }
  mobileMenuOpen.value = false
}

const scrollToContact = () => {
  scrollToSection('contact')
}

const openDemoCard = () => {
  window.location.href = sampleQrUrl.value
}

// Data
const { t } = useI18n()

const demoFeatures = ref([
  {
    icon: 'pi-qrcode',
    title: t('landing.demo.features.qr_access_title'),
    description: t('landing.demo.features.qr_access_desc')
  },
  {
    icon: 'pi-microphone',
    title: t('landing.demo.features.ai_voice_title'),
    description: t('landing.demo.features.ai_voice_desc')
  },
  {
    icon: 'pi-globe',
    title: t('landing.demo.features.multilingual_title'),
    description: t('landing.demo.features.multilingual_desc')
  },
  {
    icon: 'pi-heart',
    title: t('landing.demo.features.keepsakes_title'),
    description: t('landing.demo.features.keepsakes_desc')
  }
])

const howItWorksSteps = ref([
  {
    icon: 'pi-shopping-cart',
    title: 'Purchase',
    description: 'Visitors buy premium CardStudio cards as both souvenirs and interactive guides.'
  },
  {
    icon: 'pi-qrcode',
    title: 'Scan',
    description: 'Scan the QR code to instantly access the digital contents and AI guide—no app downloads required.'
  },
  {
    icon: 'pi-comments',
    title: 'Explore',
    description: 'Engage through AI voice conversation and personalized storytelling for a guided adventure.'
  },
  {
    icon: 'pi-heart',
    title: 'Collect',
    description: 'Cards become treasured keepsakes, promoting repeat visits and lasting memories.'
  }
])

const keyFeatures = ref([
  {
    icon: 'pi-id-card',
    title: 'Premium Collectible Souvenirs',
    description: 'QR-enabled designs that link to tailored digital contents and AI guides—creating digital keepsakes that boost revenue and repeat visits.'
  },
  {
    icon: 'pi-microphone',
    title: 'Conversational AI Guide',
    description: 'Real-time, AI voice conversation—natural, low-latency chats adapted to interests, age, and knowledge. Dynamic interactions that understand context and answer follow-up questions.'
  },
  {
    icon: 'pi-mobile',
    title: 'Instant, No-App Access',
    description: 'Scan QR on any smartphone—no downloads, no hassle for maximum adoption.'
  },
  {
    icon: 'pi-language',
    title: 'True Multilingual Support',
    description: 'Natural conversations in multi languages: English, Mandarin, Cantonese, Japanese, Korean, Thai, Arabiya, Spanish, French, Russian, etc — for inclusive engagement. One content upload, serves global audiences.'
  },
  {
    icon: 'pi-bolt',
    title: 'Zero Hardware Needed',
    description: 'Leverages visitors\' devices—no venue setup or costly infrastructure required.'
  },
  {
    icon: 'pi-chart-bar',
    title: 'Powerful Admin Dashboard',
    description: 'Self-service platform for content management, real-time data, card issuance, printing, and optimization.'
  }
])

const applications = ref([
  {
    icon: 'pi-building',
    name: 'Museums & Exhibitions',
    role: 'Your personalized multi-language AI museum docent',
    alternatives: 'Real person docents, audio guides, printed gallery guides, wall text translations',
    benefits: [
      'Bring artifacts and exhibits to life with deep-dive storytelling',
      'Experience multilingual tours and accessibility features',
      'Discover fascinating details based on your interests and questions'
    ]
  },
  {
    icon: 'pi-map-marker',
    name: 'Tourist Attractions & Landmarks',
    role: 'Your personal AI tour guide',
    alternatives: 'Printed brochures and static displays of landmark history',
    benefits: [
      'Transform landmark visits with rich historical context and cultural heritage insights',
      'Navigate with confidence while discovering authentic narratives',
      'Learn local stories behind iconic destinations'
    ]
  },
  {
    icon: 'pi-star',
    name: 'Zoos & Aquariums',
    role: 'Your interactive AI animal guide',
    alternatives: 'Real person zoo guides, zoo guidebooks, and educational handouts',
    benefits: [
      'Engage with species information and conservation stories',
      'Check feeding schedules and animal facts',
      'Inspire wonder and education through interactive conversations about wildlife and habitats'
    ]
  },
  {
    icon: 'pi-briefcase',
    name: 'Trade Shows & Exhibition Centers',
    role: 'Your AI product sales assistant',
    alternatives: 'Product catalogs, brochures, business cards, and company profile leaflets',
    benefits: [
      'Deliver dynamic product demonstrations and detailed company profiles',
      'Provide comprehensive spec sheets and technical information',
      'Boost exhibitor exposure and drive sales—all from a single premium card'
    ]
  },
  {
    icon: 'pi-calendar',
    name: 'Academic Conferences',
    role: 'Your personal AI research assistant',
    alternatives: 'Printed conference handouts and paper booklets',
    benefits: [
      'Get answers about research papers and speaker bios',
      'Clarify complex concepts on demand',
      'Turn conferences into interactive learning experiences'
    ]
  },
  {
    icon: 'pi-users',
    name: 'Training and Events',
    role: 'Your AI event coach',
    alternatives: 'Event programs, training notes and handouts, and speaker bios',
    benefits: [
      'Access session summaries and speaker bios',
      'Explore networking opportunities and key takeaways',
      'Get instant AI explanations of complex topics on demand'
    ]
  },
  {
    icon: 'pi-home',
    name: 'Hotels & Resorts',
    role: 'Your personal AI concierge in your language',
    alternatives: 'Welcome cards for guests, tour recommendation leaflets, in-room directories, service catalogs, restaurant menus',
    benefits: [
      'Discover personalized property amenities info and local attraction recommendations',
      'Get dining suggestions and tailored guest services',
      'Premium keepsakes that create memorable stays'
    ]
  },
  {
    icon: 'pi-server',
    name: 'Restaurants & Fine Dining',
    role: 'Your AI menu companion',
    alternatives: 'Printed menus, multilingual menu cards, server explanations, dish description cards',
    benefits: [
      'Experience instant multi-language menu translations and immersive dish introductions',
      'Learn about ingredients, preparation methods, chef stories, and wine pairings',
      'Get dietary accommodations through natural conversations—elevating the dining experience for international guests'
    ]
  }
])

const carouselResponsiveOptions = ref([
  {
    breakpoint: '1024px',
    numVisible: 3,
    numScroll: 1
  },
  {
    breakpoint: '768px',
    numVisible: 2,
    numScroll: 1
  },
  {
    breakpoint: '560px',
    numVisible: 1,
    numScroll: 1
  }
])

const venueBenefits = ref([
  'Boost engagement with interactive AI content',
  'Attract global crowds with multilingual access',
  'Build an innovative reputation',
  'Meet ESG sustainability goals by reducing paper waste',
  'Increase revenue via collectible sales and increase repeat visits',
  'Easy rollout with enterprise-grade security and all time support'
])

const visitorBenefits = ref([
  'Tailored stories at your pace and interest',
  'Fun, educational experiences for all ages',
  'Voice interaction in your language',
  'Premium cards as memorable digital souvenirs',
  'Easy access, no apps or setup'
])

const pricingFeatures = ref([
  'AI voice conversations',
  'Multi-language support',
  'Design dashboard',
  'Exhibits content management',
  'Real-time analytics',
  'QR code generation',
  'Print management',
  'Cloud hosting',
  '24/7 support'
])

const faqs = ref([
  {
    question: 'What is CardStudio?',
    answer: 'CardStudio is an AI-powered platform that combines premium collectible cards with interactive voice guides, transforming visits into personalized digital adventures—no apps or hardware required.'
  },
  {
    question: 'How does it work for visitors?',
    answer: 'Visitors buy or receive a QR-enabled card, scan it with their smartphone, and instantly access digital contents with AI-driven storytelling and conversations in their language. It\'s seamless and app-free.'
  },
  {
    question: 'How do venues get started with CardStudio?',
    answer: `Launch in minutes—from idea to live experience in 3 simple steps:

Step 0: Register for CardStudio account.
Step 1: Design & Configure—Use intuitive tools to create cards. Upload your card design and digital contents to your CardStudio account and easy setup.
Step 2: Submit Your Card Order—Online submit the physical cards orders. Each card come with a different QR code to access the AI powered digital contents. We will handle the printing and shipping to your door.
Step 3: Analyze & Optimize—Track engagement with real-time analytics, refine content, and scale effortlessly.`
  },
  {
    question: 'What are the costs?',
    answer: 'Transparent pay-per-card pricing: $2.00 per card. Suggested retail: $3-7 USD (your profit: $1-5 per card). Alternative: Complimentary model (free to visitors, $2 cost to you). No monthly subscriptions, setup fees, or hidden costs—everything included (AI chats, multilingual support, dashboard, analytics, QR generation, print management, hosting, and 24/7 support).'
  },
  {
    question: 'Can we customize the cards and content?',
    answer: 'Absolutely. Use our self-service tools for designs, manage digital contents, and AI interactions customization to match your venue need.'
  },
  {
    question: 'How long does setup take?',
    answer: 'Minutes—cloud-based with no technical setup or IT integration. Launch instantly.'
  },
  {
    question: 'What kind of support do you offer?',
    answer: '24/7 access to our expert team, plus an intuitive dashboard for analytics and updates.'
  },
  {
    question: 'How many days it takes for card printing and delivery?',
    answer: 'Once you ordered CardStudio cards, we will get your card print within 4 working days. The shipping time depends from shipping address worldwide. Please expect around 5 – 10 days from the date of your card order to the date you receive the card.'
  },
  {
    question: 'What is the minimum order quantity?',
    answer: `The minimum order is ${minBatchQuantity} cards per order. This ensures cost-effective production. Each card comes with a unique QR code to access the digital contents and AI features.`
  }
])

const organizationTypes = ref([
  'Museum',
  'Art Gallery',
  'Exhibition Center',
  'Conference/Event Organizer',
  'Tourist Attraction/Landmark',
  'Zoo/Aquarium',
  'Trade Show Organizer',
  'Hotel/Resort',
  'Restaurant/Fine Dining',
  'Theme Park',
  'Training/Education Provider',
  'Agency/Consultant',
  'Other'
])

const visitorCountOptions = ref([
  'Under 1,000',
  '1,000 - 5,000',
  '5,000 - 10,000',
  '10,000 - 50,000',
  '50,000 - 100,000',
  'Over 100,000'
])

const inquiryTypes = ref([
  'Request a Pilot Program',
  'General Information',
  'Pricing & Plans',
  'Partnership Opportunity',
  'Software Licensing',
  'Technical Questions',
  'Other'
])
</script>

<style scoped>
/* Animations */
@keyframes float {
  0%, 100% { transform: translateY(0) rotate(0deg); }
  33% { transform: translateY(-20px) rotate(1deg); }
  66% { transform: translateY(10px) rotate(-1deg); }
}

@keyframes float-delayed {
  0%, 100% { transform: translateY(0) rotate(0deg); }
  33% { transform: translateY(15px) rotate(-1deg); }
  66% { transform: translateY(-25px) rotate(1deg); }
}

@keyframes float-slow {
  0%, 100% { transform: translateY(0) scale(1); }
  50% { transform: translateY(-30px) scale(1.05); }
}

@keyframes scroll {
  0% { transform: translateY(0); }
  100% { transform: translateY(8px); }
}

@keyframes fade-in-up {
  from { 
    opacity: 0;
    transform: translateY(20px);
  }
  to { 
    opacity: 1;
    transform: translateY(0);
  }
}

.floating-orb {
  animation: float 20s ease-in-out infinite;
}

.floating-orb-delayed {
  animation: float-delayed 25s ease-in-out infinite;
}

.floating-orb-slow {
  animation: float-slow 30s ease-in-out infinite;
}

.animate-scroll {
  animation: scroll 1.5s ease-in-out infinite;
}

.animate-fade-in-up {
  animation: fade-in-up 0.8s ease-out forwards;
}

.animation-delay-200 {
  animation-delay: 200ms;
}

.animation-delay-400 {
  animation-delay: 400ms;
}

/* Slide transitions */
.slide-down-enter-active,
.slide-down-leave-active {
  transition: all 0.3s ease;
}

.slide-down-enter-from,
.slide-down-leave-to {
  transform: translateY(-10px);
  opacity: 0;
}

.slide-up-enter-active,
.slide-up-leave-active {
  transition: all 0.5s cubic-bezier(0.4, 0, 0.2, 1);
}

.slide-up-enter-from {
  transform: translateY(100px);
  opacity: 0;
}

.slide-up-leave-to {
  transform: translateY(100px);
  opacity: 0;
}

.collapse-enter-active,
.collapse-leave-active {
  transition: all 0.3s ease;
  max-height: 500px;
}

.collapse-enter-from,
.collapse-leave-to {
  max-height: 0;
  opacity: 0;
}

/* Custom Carousel Styles */
:deep(.custom-carousel .p-carousel-content) {
  overflow: visible;
}

:deep(.custom-carousel .p-carousel-item) {
  opacity: 0.7;
  transform: scale(0.9);
  transition: all 0.3s ease;
}

:deep(.custom-carousel .p-carousel-item-active) {
  opacity: 1;
  transform: scale(1);
}

/* Performance optimizations */
.animate-on-scroll {
  opacity: 1;
  transform: translateY(0);
  transition: all 0.8s cubic-bezier(0.4, 0, 0.2, 1);
}

.js-animations-ready .animate-on-scroll {
  opacity: 0;
  transform: translateY(30px);
}

.animate-visible {
  opacity: 1 !important;
  transform: translateY(0) !important;
}

/* Optimized animations with GPU acceleration */
.floating-orb,
.floating-orb-delayed,
.floating-orb-slow {
  will-change: transform;
  transform: translateZ(0);
}

/* Pulse animation for CTAs */
@keyframes pulse-glow {
  0%, 100% {
    box-shadow: 0 0 20px rgba(59, 130, 246, 0.5);
  }
  50% {
    box-shadow: 0 0 40px rgba(59, 130, 246, 0.8);
  }
}

.pulse-glow {
  animation: pulse-glow 2s ease-in-out infinite;
}

/* Gradient text compatibility */
.bg-clip-text {
  -webkit-background-clip: text;
  background-clip: text;
}

/* Glassmorphism effect */
.backdrop-blur-sm {
  backdrop-filter: blur(8px);
  -webkit-backdrop-filter: blur(8px);
}

.backdrop-blur-xl {
  backdrop-filter: blur(20px);
  -webkit-backdrop-filter: blur(20px);
}

/* Smooth scroll */
html {
  scroll-behavior: smooth;
}

/* Reduced motion support */
@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
  }
}
</style>
