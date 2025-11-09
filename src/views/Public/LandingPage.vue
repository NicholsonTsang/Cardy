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
              class="w-full bg-slate-100 text-slate-700 hover:bg-slate-200 border-0 py-4 text-base font-semibold rounded-xl min-h-[52px]"
            >
              {{ $t('landing.nav.sign_in') }}
            </Button>
            <Button 
              @click="router.push('/signup'); mobileMenuOpen = false"
              class="w-full bg-gradient-to-r from-blue-600 to-purple-600 hover:from-blue-700 hover:to-purple-700 text-white border-0 py-4 text-base font-bold shadow-lg rounded-xl min-h-[52px]"
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
              class="bg-gradient-to-r from-blue-600 to-purple-600 hover:from-blue-700 hover:to-purple-700 border-0 px-8 sm:px-10 py-4 sm:py-5 text-base sm:text-lg font-bold text-white shadow-2xl hover:shadow-blue-500/25 transition-all transform hover:scale-105 rounded-xl min-h-[56px]"
            >
              {{ $t('landing.hero.cta_pilot') }}
            </Button>
            <Button 
              @click="scrollToSection('about')"
              class="group border-2 border-white/30 bg-white/5 hover:bg-white/10 backdrop-blur-sm px-8 sm:px-10 py-4 sm:py-5 text-base sm:text-lg font-semibold text-white hover:border-white/50 transition-all transform hover:scale-105 rounded-xl min-h-[56px]"
            >
              {{ $t('landing.hero.cta_learn') }}
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
            class="border-2 border-blue-600 text-blue-600 hover:bg-blue-600 hover:text-white bg-transparent px-6 sm:px-8 py-3 sm:py-4 text-base font-semibold rounded-xl transition-all min-h-[48px]"
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
          <div class="grid md:grid-cols-5 gap-12 lg:gap-16 mt-16 items-center">
            <!-- Left Column: Demo Card (2/5 width) -->
            <div class="md:col-span-2 relative w-full animate-on-scroll">
              <!-- Ambient glow -->
              <div class="absolute inset-0 bg-gradient-to-r from-blue-600 to-purple-600 rounded-3xl blur-3xl opacity-50"></div>
              
              <!-- Card container -->
              <div class="relative bg-white rounded-3xl p-4 shadow-2xl hover:shadow-[0_20px_60px_rgba(59,130,246,0.3)] transition-all duration-500">
                <div :style="{ aspectRatio: cardAspectRatio }" class="bg-gradient-to-br from-blue-600 via-purple-600 to-pink-600 rounded-2xl overflow-hidden relative group">
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
                  
                  <!-- QR Code with Visual Guide -->
                  <div class="absolute top-4 right-4">
                    <div class="relative group/qr">
                      <!-- Glow effect -->
                      <div class="absolute inset-0 bg-white/60 rounded-lg blur-md"></div>
                      <!-- QR Code container with frosted glass effect -->
                      <div class="relative bg-white/95 backdrop-blur-sm rounded-lg p-1.5 shadow-lg ring-1 ring-white/20 transition-all duration-300 group-hover/qr:scale-105 group-hover/qr:shadow-xl">
                        <QrCode :value="sampleQrUrl" :size="52" />
                      </div>
                    </div>
                  </div>
                </div>
                
                <!-- Try Demo Button - Mobile Only -->
                <div class="mt-6 text-center lg:hidden">
                  <Button 
                    @click="openDemoCard"
                    class="w-full bg-gradient-to-r from-blue-600 to-purple-600 hover:from-blue-700 hover:to-purple-700 text-white border-0 py-4 text-base font-bold shadow-lg hover:shadow-xl transition-all rounded-xl min-h-[52px]"
                  >
                    {{ $t('landing.demo.try_live_demo') }}
                  </Button>
                </div>
              </div>
            </div>

            <!-- Right Column: Features & Guide (3/5 width) -->
            <div class="md:col-span-3 space-y-8 animate-on-scroll" style="animation-delay: 200ms">
              <!-- Visual Guide - Desktop Only -->
              <div class="hidden lg:block">
                <div class="bg-white/5 backdrop-blur-sm border border-white/10 rounded-2xl p-6">
                  <div class="flex items-start gap-4 mb-6">
                    <div class="flex-shrink-0 w-12 h-12 rounded-xl bg-gradient-to-br from-blue-500 to-purple-600 flex items-center justify-center shadow-lg">
                      <i class="pi pi-mobile text-white text-xl"></i>
                    </div>
                    <div>
                      <h4 class="text-lg font-bold text-white mb-1">{{ $t('landing.demo.scan_with_phone') }}</h4>
                      <p class="text-sm text-white/70">{{ $t('landing.demo.instant_demo') }}</p>
                    </div>
                  </div>
                  <div class="flex items-center gap-3 text-white/60 text-sm">
                    <i class="pi pi-arrow-left animate-pulse"></i>
                    <span>{{ $t('landing.demo.scan_qr_code') }}</span>
                  </div>
                </div>
              </div>
              
              <h3 class="text-3xl font-bold text-white">{{ $t('landing.demo.experience_features') }}</h3>
              
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
            {{ $t('landing.how_it_works.title') }} <span class="bg-gradient-to-r from-violet-600 to-purple-600 bg-clip-text text-transparent">{{ $t('landing.how_it_works.title_highlight') }}</span>
          </h2>
          <p class="text-lg sm:text-xl text-slate-600 max-w-3xl mx-auto px-2">
            {{ $t('landing.how_it_works.subtitle') }}
          </p>
        </div>
        
        <!-- Steps with connecting line -->
        <div class="relative">
          <div class="hidden lg:block absolute top-1/2 left-0 right-0 h-0.5 bg-gradient-to-r from-blue-200 via-purple-200 to-pink-200"></div>
          
          <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-8">
            <div v-for="(step, index) in howItWorksSteps" :key="index" class="relative group">
              <!-- Card Content -->
              <div class="relative bg-white rounded-3xl p-8 shadow-lg hover:shadow-xl transition-all duration-500 border-2 border-slate-200 hover:border-purple-300 h-full">
                <!-- Step Number Badge - Inside Top Left -->
                <div class="absolute top-4 left-4 w-10 h-10 bg-gradient-to-br from-purple-600 to-pink-600 rounded-full flex items-center justify-center text-white font-bold text-base shadow-lg">
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
    <section class="py-20 sm:py-32 bg-gradient-to-b from-slate-50 to-white">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div class="text-center mb-20">
          <h2 class="text-4xl sm:text-5xl lg:text-6xl font-black text-slate-900 mb-6">
            {{ $t('landing.features.title') }} <span class="bg-gradient-to-r from-amber-600 to-orange-600 bg-clip-text text-transparent">{{ $t('landing.features.title_highlight') }}</span>
          </h2>
        </div>
        
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
          <div v-for="(feature, index) in keyFeatures" :key="feature.title" 
               class="group relative animate-on-scroll"
               :style="{ animationDelay: (index * 100) + 'ms' }">
            <div class="absolute inset-0 bg-gradient-to-r from-blue-600 to-purple-600 rounded-3xl opacity-0 group-hover:opacity-100 transition-opacity duration-300 blur-xl"></div>
            <div class="relative bg-white rounded-3xl p-8 shadow-lg hover:shadow-xl transition-all duration-300 border border-slate-200 h-full">
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
    <section class="py-20 sm:py-32 bg-white">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div class="text-center mb-20">
          <h2 class="text-4xl sm:text-5xl lg:text-6xl font-black text-slate-900 mb-6">
            {{ $t('landing.applications.title') }} <span class="bg-gradient-to-r from-emerald-600 to-teal-600 bg-clip-text text-transparent">{{ $t('landing.applications.title_highlight') }}</span>
          </h2>
          <p class="text-xl text-slate-600 max-w-3xl mx-auto">
            {{ $t('landing.applications.subtitle') }}
          </p>
        </div>

        <Carousel :value="applications" :numVisible="3" :numScroll="1" :responsiveOptions="carouselResponsiveOptions" 
                  :circular="true" :autoplayInterval="5000" class="custom-carousel">
          <template #item="slotProps">
            <div class="p-4">
              <div class="bg-gradient-to-br from-white to-slate-50 rounded-3xl overflow-hidden shadow-lg hover:shadow-xl transition-all duration-500 transform hover:-translate-y-2 border border-slate-200 h-full">
                <div class="p-8">
                  <div class="w-20 h-20 bg-gradient-to-br from-emerald-100 to-teal-100 rounded-2xl flex items-center justify-center mb-6 mx-auto">
                    <i :class="`pi ${slotProps.data.icon} text-emerald-600 text-3xl`"></i>
                  </div>
                  <h3 class="text-2xl font-bold text-slate-900 mb-2 text-center">{{ slotProps.data.name }}</h3>
                  <p class="text-sm font-semibold text-emerald-600 mb-4 text-center">{{ slotProps.data.role }}</p>
                  <div class="mb-4">
                    <p class="text-xs text-slate-500 font-semibold mb-2">{{ $t('landing.applications.alternatives_for') }}</p>
                    <p class="text-sm text-slate-600 italic">{{ slotProps.data.alternatives }}</p>
                  </div>
                  <ul class="space-y-3">
                    <li v-for="(benefit, idx) in slotProps.data.benefits" :key="idx" 
                        class="flex items-start gap-2 text-sm text-slate-600">
                      <i class="pi pi-check-circle text-emerald-500 text-lg mt-0.5 flex-shrink-0"></i>
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
            class="border-2 border-blue-600 text-blue-600 hover:bg-blue-600 hover:text-white bg-transparent px-6 sm:px-8 py-3 sm:py-4 text-base font-semibold rounded-xl transition-all min-h-[48px]"
          >
            {{ $t('landing.applications.cta') }}
          </Button>
        </div>
      </div>
    </section>

    <!-- Benefits Section -->
    <section class="py-20 sm:py-32 bg-gradient-to-b from-slate-50 to-white">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div class="text-center mb-20">
          <h2 class="text-4xl sm:text-5xl lg:text-6xl font-black text-slate-900 mb-6">
            {{ $t('landing.benefits.title') }} <span class="bg-gradient-to-r from-blue-600 to-purple-600 bg-clip-text text-transparent">{{ $t('landing.benefits.title_highlight') }}</span>
          </h2>
        </div>

        <div class="grid lg:grid-cols-2 gap-12">
          <!-- For Venues -->
          <div class="bg-white rounded-3xl p-10 shadow-lg border border-slate-200">
            <h3 class="text-3xl font-bold text-slate-900 mb-8 text-center">{{ $t('landing.benefits.venue_title') }}</h3>
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
          <div class="bg-white rounded-3xl p-10 shadow-lg border border-slate-200">
            <h3 class="text-3xl font-bold text-slate-900 mb-8 text-center">{{ $t('landing.benefits.visitor_title') }}</h3>
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
    <section class="py-20 sm:py-32 bg-gradient-to-br from-emerald-50 to-teal-50">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div class="text-center mb-20">
          <h2 class="text-4xl sm:text-5xl lg:text-6xl font-black text-slate-900 mb-6">
            {{ $t('landing.sustainability.title') }} <span class="bg-gradient-to-r from-emerald-600 to-teal-600 bg-clip-text text-transparent">{{ $t('landing.sustainability.title_highlight') }}</span>
          </h2>
        </div>

        <div class="grid lg:grid-cols-2 gap-12 max-w-6xl mx-auto">
          <!-- Traditional Way -->
          <div class="bg-white rounded-3xl p-10 shadow-lg border-2 border-slate-200">
            <h3 class="text-2xl font-bold text-slate-900 mb-8 text-center">{{ $t('landing.sustainability.traditional_title') }}</h3>
            <div class="space-y-6">
              <div class="flex items-center gap-4">
                <div class="text-4xl">📄</div>
                <div>
                  <p class="font-semibold text-slate-900">{{ $t('landing.sustainability.traditional_brochures') }}</p>
                  <p class="text-sm text-slate-600">{{ $t('landing.sustainability.traditional_visitors') }}</p>
                </div>
              </div>
              <div class="flex items-center gap-4">
                <div class="text-4xl">🗑️</div>
                <div>
                  <p class="font-semibold text-slate-900">{{ $t('landing.sustainability.traditional_discarded') }}</p>
                </div>
              </div>
              <div class="flex items-center gap-4">
                <div class="text-4xl">🌳</div>
                <div>
                  <p class="font-semibold text-red-600">{{ $t('landing.sustainability.traditional_waste') }}</p>
                </div>
              </div>
            </div>
          </div>

          <!-- CardStudio Way -->
          <div class="bg-gradient-to-br from-emerald-600 to-teal-600 rounded-3xl p-10 shadow-2xl text-white">
            <h3 class="text-2xl font-bold mb-8 text-center">{{ $t('landing.sustainability.cardstudio_title') }}</h3>
            <div class="space-y-6">
              <div class="flex items-center gap-4">
                <div class="text-4xl">🎴</div>
                <div>
                  <p class="font-semibold">{{ $t('landing.sustainability.cardstudio_cards') }}</p>
                </div>
              </div>
              <div class="flex items-center gap-4">
                <div class="text-4xl">💚</div>
                <div>
                  <p class="font-semibold">{{ $t('landing.sustainability.cardstudio_kept') }}</p>
                </div>
              </div>
              <div class="flex items-center gap-4">
                <div class="text-4xl">♻️</div>
                <div>
                  <p class="font-semibold text-yellow-300">{{ $t('landing.sustainability.cardstudio_reduction') }}</p>
                </div>
              </div>
              <div class="flex items-center gap-4">
                <div class="text-4xl">📱</div>
                <div>
                  <p class="font-semibold">{{ $t('landing.sustainability.cardstudio_digital') }}</p>
                </div>
              </div>
            </div>
          </div>
        </div>

        <div class="mt-16 bg-white rounded-3xl p-10 shadow-lg border border-emerald-200 max-w-4xl mx-auto">
          <h3 class="text-2xl font-bold text-slate-900 mb-6 text-center">{{ $t('landing.sustainability.impact_title') }}</h3>
          <div class="grid md:grid-cols-2 gap-6">
            <div class="flex items-start gap-3">
              <i class="pi pi-check-circle text-emerald-600 text-xl mt-1"></i>
              <p class="text-slate-700">{{ $t('landing.sustainability.impact_esg') }}</p>
            </div>
            <div class="flex items-start gap-3">
              <i class="pi pi-check-circle text-emerald-600 text-xl mt-1"></i>
              <p class="text-slate-700">{{ $t('landing.sustainability.impact_cost') }}</p>
            </div>
            <div class="flex items-start gap-3">
              <i class="pi pi-check-circle text-emerald-600 text-xl mt-1"></i>
              <p class="text-slate-700">{{ $t('landing.sustainability.impact_leader') }}</p>
            </div>
            <div class="flex items-start gap-3">
              <i class="pi pi-check-circle text-emerald-600 text-xl mt-1"></i>
              <p class="text-slate-700">{{ $t('landing.sustainability.impact_appeal') }}</p>
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
            {{ $t('landing.pricing.title') }} <span class="bg-gradient-to-r from-blue-400 via-cyan-400 to-emerald-400 bg-clip-text text-transparent">{{ $t('landing.pricing.title_highlight') }}</span>
          </h2>
          <p class="text-lg sm:text-xl text-blue-100/80 max-w-3xl mx-auto px-2">
            {{ $t('landing.pricing.subtitle') }}
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
                <h3 class="text-2xl font-bold text-white mb-6">{{ $t('landing.pricing.details_title') }}</h3>
                <div class="space-y-4 text-blue-100">
                  <div class="bg-white/5 rounded-xl p-4">
                    <div class="flex justify-between items-center">
                      <span>{{ $t('landing.pricing.cost_to_you') }}</span>
                      <span class="font-bold text-white">{{ $t('landing.pricing.cost_value') }}</span>
                    </div>
                  </div>
                  <div class="bg-white/5 rounded-xl p-4">
                    <div class="flex justify-between items-center">
                      <span>{{ $t('landing.pricing.suggested_retail') }}</span>
                      <span class="font-bold text-white">{{ $t('landing.pricing.retail_value') }}</span>
                    </div>
                  </div>
                  <div class="bg-emerald-500/10 rounded-xl p-4 border border-emerald-500/20">
                    <div class="flex justify-between items-center">
                      <span>{{ $t('landing.pricing.profit_margin') }}</span>
                      <span class="font-bold text-emerald-400">{{ $t('landing.pricing.profit_value') }}</span>
                    </div>
                  </div>
                  <div class="text-sm text-blue-300 pt-4">
                    <i class="pi pi-info-circle mr-2"></i>
                    {{ $t('landing.pricing.alternative_note') }}
                  </div>
                </div>
              </div>

              <div>
                <h3 class="text-2xl font-bold text-white mb-6">{{ $t('landing.pricing.included_title') }}</h3>
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
                  <p class="text-white font-semibold mb-1">{{ $t('landing.pricing.minimum_order') }}</p>
                  <p class="text-blue-200 text-sm">{{ $t('landing.pricing.minimum_cards', { count: minBatchQuantity }) }}</p>
                </div>
                <div class="text-4xl">📦</div>
              </div>
            </div>

            <div class="text-center px-4">
              <Button 
                @click="scrollToContact"
                class="bg-gradient-to-r from-blue-600 to-purple-600 hover:from-blue-700 hover:to-purple-700 text-white border-0 px-8 sm:px-10 py-4 sm:py-5 text-base sm:text-lg font-bold shadow-2xl hover:shadow-blue-500/25 transition-all transform hover:scale-105 rounded-xl min-h-[56px]"
              >
                {{ $t('landing.pricing.cta') }}
              </Button>
              <p class="text-blue-300 text-sm mt-4">{{ $t('landing.pricing.footer_text') }}</p>
            </div>
          </div>
        </div>
      </div>
    </section>

    <!-- Collaboration Models -->
    <section class="py-20 sm:py-32 bg-white">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div class="text-center mb-20">
          <h2 class="text-4xl sm:text-5xl lg:text-6xl font-black text-slate-900 mb-6">
            {{ $t('landing.collaboration.title') }} <span class="bg-gradient-to-r from-blue-600 to-purple-600 bg-clip-text text-transparent">{{ $t('landing.collaboration.title_highlight') }}</span>
          </h2>
          <p class="text-xl text-slate-600 max-w-3xl mx-auto">
            {{ $t('landing.collaboration.subtitle') }}
          </p>
        </div>

        <div class="grid lg:grid-cols-3 gap-8">
          <!-- Become a Client -->
          <div class="bg-gradient-to-br from-blue-50 to-purple-50 rounded-3xl p-8 shadow-lg hover:shadow-xl transition-all duration-300 border-2 border-blue-200 hover:border-blue-400">
            <div class="w-16 h-16 bg-gradient-to-br from-blue-600 to-purple-600 rounded-2xl flex items-center justify-center mb-6 mx-auto">
              <i class="pi pi-shopping-cart text-white text-2xl"></i>
            </div>
            <h3 class="text-2xl font-bold text-slate-900 mb-4 text-center">{{ $t('landing.collaboration.client.title') }}</h3>
            <p class="text-sm text-slate-600 mb-6 text-center">{{ $t('landing.collaboration.client.for') }}</p>
            
            <div class="mb-6">
              <p class="font-semibold text-slate-900 mb-3">{{ $t('landing.collaboration.client.you_get') }}</p>
              <ul class="space-y-2">
                <li class="flex items-start gap-2 text-sm text-slate-700">
                  <i class="pi pi-check text-blue-600 text-lg mt-0.5"></i>
                  <span>{{ $t('landing.collaboration.client.benefit1') }}</span>
                </li>
                <li class="flex items-start gap-2 text-sm text-slate-700">
                  <i class="pi pi-check text-blue-600 text-lg mt-0.5"></i>
                  <span>{{ $t('landing.collaboration.client.benefit2') }}</span>
                </li>
                <li class="flex items-start gap-2 text-sm text-slate-700">
                  <i class="pi pi-check text-blue-600 text-lg mt-0.5"></i>
                  <span>{{ $t('landing.collaboration.client.benefit3') }}</span>
                </li>
                <li class="flex items-start gap-2 text-sm text-slate-700">
                  <i class="pi pi-check text-blue-600 text-lg mt-0.5"></i>
                  <span>{{ $t('landing.collaboration.client.benefit4') }}</span>
                </li>
              </ul>
            </div>

            <p class="text-sm font-semibold text-blue-600 mb-6 text-center">{{ $t('landing.collaboration.client.best_if') }}</p>

            <Button 
              @click="scrollToContact"
              class="w-full bg-gradient-to-r from-blue-600 to-purple-600 hover:from-blue-700 hover:to-purple-700 text-white border-0 py-4 text-base font-bold rounded-xl shadow-lg min-h-[52px]"
            >
              {{ $t('landing.collaboration.client.cta') }}
            </Button>
          </div>

          <!-- Regional Partner -->
          <div class="bg-gradient-to-br from-emerald-50 to-teal-50 rounded-3xl p-8 shadow-lg hover:shadow-xl transition-all duration-300 border-2 border-emerald-200 hover:border-emerald-400">
            <div class="w-16 h-16 bg-gradient-to-br from-emerald-600 to-teal-600 rounded-2xl flex items-center justify-center mb-6 mx-auto">
              <i class="pi pi-globe text-white text-2xl"></i>
            </div>
            <h3 class="text-2xl font-bold text-slate-900 mb-4 text-center">{{ $t('landing.collaboration.partner.title') }}</h3>
            <p class="text-sm text-slate-600 mb-6 text-center">{{ $t('landing.collaboration.partner.for') }}</p>
            
            <div class="mb-6">
              <p class="font-semibold text-slate-900 mb-3">{{ $t('landing.collaboration.partner.you_get') }}</p>
              <ul class="space-y-2">
                <li class="flex items-start gap-2 text-sm text-slate-700">
                  <i class="pi pi-check text-emerald-600 text-lg mt-0.5"></i>
                  <span>{{ $t('landing.collaboration.partner.benefit1') }}</span>
                </li>
                <li class="flex items-start gap-2 text-sm text-slate-700">
                  <i class="pi pi-check text-emerald-600 text-lg mt-0.5"></i>
                  <span>{{ $t('landing.collaboration.partner.benefit2') }}</span>
                </li>
                <li class="flex items-start gap-2 text-sm text-slate-700">
                  <i class="pi pi-check text-emerald-600 text-lg mt-0.5"></i>
                  <span>{{ $t('landing.collaboration.partner.benefit3') }}</span>
                </li>
                <li class="flex items-start gap-2 text-sm text-slate-700">
                  <i class="pi pi-check text-emerald-600 text-lg mt-0.5"></i>
                  <span>{{ $t('landing.collaboration.partner.benefit4') }}</span>
                </li>
              </ul>
            </div>

            <p class="text-sm font-semibold text-emerald-600 mb-6 text-center">{{ $t('landing.collaboration.partner.best_if') }}</p>

            <Button 
              @click="scrollToContact"
              class="w-full bg-gradient-to-r from-blue-600 to-purple-600 hover:from-blue-700 hover:to-purple-700 text-white border-0 py-4 text-base font-bold rounded-xl shadow-lg min-h-[52px]"
            >
              {{ $t('landing.collaboration.partner.cta') }}
            </Button>
          </div>

          <!-- Software License -->
          <div class="bg-gradient-to-br from-orange-50 to-pink-50 rounded-3xl p-8 shadow-lg hover:shadow-xl transition-all duration-300 border-2 border-orange-200 hover:border-orange-400">
            <div class="w-16 h-16 bg-gradient-to-br from-orange-600 to-pink-600 rounded-2xl flex items-center justify-center mb-6 mx-auto">
              <i class="pi pi-code text-white text-2xl"></i>
            </div>
            <h3 class="text-2xl font-bold text-slate-900 mb-4 text-center">{{ $t('landing.collaboration.license.title') }}</h3>
            <p class="text-sm text-slate-600 mb-6 text-center">{{ $t('landing.collaboration.license.for') }}</p>
            
            <div class="mb-6">
              <p class="font-semibold text-slate-900 mb-3">{{ $t('landing.collaboration.license.you_get') }}</p>
              <ul class="space-y-2">
                <li class="flex items-start gap-2 text-sm text-slate-700">
                  <i class="pi pi-check text-orange-600 text-lg mt-0.5"></i>
                  <span>{{ $t('landing.collaboration.license.benefit1') }}</span>
                </li>
                <li class="flex items-start gap-2 text-sm text-slate-700">
                  <i class="pi pi-check text-orange-600 text-lg mt-0.5"></i>
                  <span>{{ $t('landing.collaboration.license.benefit2') }}</span>
                </li>
                <li class="flex items-start gap-2 text-sm text-slate-700">
                  <i class="pi pi-check text-orange-600 text-lg mt-0.5"></i>
                  <span>{{ $t('landing.collaboration.license.benefit3') }}</span>
                </li>
                <li class="flex items-start gap-2 text-sm text-slate-700">
                  <i class="pi pi-check text-orange-600 text-lg mt-0.5"></i>
                  <span>{{ $t('landing.collaboration.license.benefit4') }}</span>
                </li>
                <li class="flex items-start gap-2 text-sm text-slate-700">
                  <i class="pi pi-check text-orange-600 text-lg mt-0.5"></i>
                  <span>{{ $t('landing.collaboration.license.benefit5') }}</span>
                </li>
              </ul>
            </div>

            <p class="text-sm font-semibold text-orange-600 mb-6 text-center">{{ $t('landing.collaboration.license.best_if') }}</p>

            <Button 
              @click="scrollToContact"
              class="w-full bg-gradient-to-r from-blue-600 to-purple-600 hover:from-blue-700 hover:to-purple-700 text-white border-0 py-4 text-base font-bold rounded-xl shadow-lg min-h-[52px]"
            >
              {{ $t('landing.collaboration.license.cta') }}
            </Button>
          </div>
        </div>

        <div class="text-center mt-12 px-4">
          <p class="text-base sm:text-lg text-slate-600 mb-6">
            {{ $t('landing.collaboration.not_sure') }}
          </p>
          <Button 
            @click="scrollToContact"
            class="bg-gradient-to-r from-blue-600 to-purple-600 hover:from-blue-700 hover:to-purple-700 text-white border-0 px-8 sm:px-10 py-4 text-base sm:text-lg font-bold shadow-lg rounded-xl min-h-[52px]"
          >
            {{ $t('landing.collaboration.schedule_call') }}
          </Button>
        </div>
      </div>
    </section>

    <!-- FAQ Section -->
    <section class="py-20 sm:py-32 bg-gradient-to-b from-slate-50 to-white">
      <div class="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8">
        <div class="text-center mb-16">
          <h2 class="text-4xl sm:text-5xl font-black text-slate-900">
            {{ $t('landing.faq.title') }} <span class="bg-gradient-to-r from-blue-600 to-purple-600 bg-clip-text text-transparent">{{ $t('landing.faq.title_highlight') }}</span>
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
            {{ $t('landing.faq.still_have_questions') }}
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
            {{ $t('landing.contact.title_line1') }}<br />
            <span class="text-yellow-300">{{ $t('landing.contact.title_line2') }}</span>
          </h2>
          <p class="text-lg sm:text-xl text-white/90 max-w-3xl mx-auto px-2">
            {{ $t('landing.contact.subtitle') }}
          </p>
        </div>
        
        <div class="bg-white rounded-3xl p-8 lg:p-12 shadow-2xl">
          <!-- What You Can Do -->
          <div class="mb-10">
            <h3 class="text-2xl font-bold text-slate-900 mb-6">{{ $t('landing.contact.what_you_can_do') }}</h3>
            <div class="grid md:grid-cols-2 gap-4">
              <div class="flex items-start gap-3">
                <div class="text-2xl">🚀</div>
                <div>
                  <p class="font-semibold text-slate-900">{{ $t('landing.contact.actions.pilot_title') }}</p>
                  <p class="text-sm text-slate-600">{{ $t('landing.contact.actions.pilot_desc') }}</p>
                </div>
              </div>
              <div class="flex items-start gap-3">
                <div class="text-2xl">💡</div>
                <div>
                  <p class="font-semibold text-slate-900">{{ $t('landing.contact.actions.info_title') }}</p>
                  <p class="text-sm text-slate-600">{{ $t('landing.contact.actions.info_desc') }}</p>
                </div>
              </div>
              <div class="flex items-start gap-3">
                <div class="text-2xl">🤝</div>
                <div>
                  <p class="font-semibold text-slate-900">{{ $t('landing.contact.actions.partnership_title') }}</p>
                  <p class="text-sm text-slate-600">{{ $t('landing.contact.actions.partnership_desc') }}</p>
                </div>
              </div>
              <div class="flex items-start gap-3">
                <div class="text-2xl">❓</div>
                <div>
                  <p class="font-semibold text-slate-900">{{ $t('landing.contact.actions.questions_title') }}</p>
                  <p class="text-sm text-slate-600">{{ $t('landing.contact.actions.questions_desc') }}</p>
                </div>
              </div>
            </div>
          </div>

          <!-- Contact Form -->
          <form @submit.prevent="handleSubmit" class="space-y-6">
            <div class="grid md:grid-cols-2 gap-6">
              <div>
                <label class="block text-sm font-semibold text-slate-900 mb-2">{{ $t('landing.contact.form.full_name') }}</label>
                <InputText 
                  v-model="contactForm.fullName" 
                  required 
                  class="w-full"
                  :placeholder="$t('landing.contact.form.full_name_placeholder')"
                />
              </div>
              <div>
                <label class="block text-sm font-semibold text-slate-900 mb-2">{{ $t('landing.contact.form.organization') }}</label>
                <InputText 
                  v-model="contactForm.organizationName" 
                  required 
                  class="w-full"
                  :placeholder="$t('landing.contact.form.organization_placeholder')"
                />
              </div>
            </div>

            <div class="grid md:grid-cols-2 gap-6">
              <div>
                <label class="block text-sm font-semibold text-slate-900 mb-2">{{ $t('landing.contact.form.email') }}</label>
                <InputText 
                  v-model="contactForm.email" 
                  type="email" 
                  required 
                  class="w-full"
                  :placeholder="$t('landing.contact.form.email_placeholder')"
                />
              </div>
              <div>
                <label class="block text-sm font-semibold text-slate-900 mb-2">{{ $t('landing.contact.form.phone') }}</label>
                <InputText 
                  v-model="contactForm.phone" 
                  class="w-full"
                  :placeholder="$t('landing.contact.form.phone_placeholder')"
                />
              </div>
            </div>

            <div class="grid md:grid-cols-2 gap-6">
              <div>
                <label class="block text-sm font-semibold text-slate-900 mb-2">{{ $t('landing.contact.form.org_type') }}</label>
                <Dropdown 
                  v-model="contactForm.organizationType" 
                  :options="organizationTypes.value" 
                  required 
                  class="w-full"
                  :placeholder="$t('landing.contact.form.org_type_placeholder')"
                />
              </div>
              <div>
                <label class="block text-sm font-semibold text-slate-900 mb-2">{{ $t('landing.contact.form.visitor_count') }}</label>
                <Dropdown 
                  v-model="contactForm.visitorCount" 
                  :options="visitorCountOptions.value" 
                  required 
                  class="w-full"
                  :placeholder="$t('landing.contact.form.visitor_count_placeholder')"
                />
              </div>
            </div>

            <div>
              <label class="block text-sm font-semibold text-slate-900 mb-2">{{ $t('landing.contact.form.inquiry_type') }}</label>
              <Dropdown 
                v-model="contactForm.inquiryType" 
                :options="inquiryTypes.value" 
                required 
                class="w-full"
                :placeholder="$t('landing.contact.form.inquiry_type_placeholder')"
              />
            </div>

            <div>
              <label class="block text-sm font-semibold text-slate-900 mb-2">{{ $t('landing.contact.form.message') }}</label>
              <Textarea 
                v-model="contactForm.message" 
                rows="5" 
                class="w-full"
                :placeholder="$t('landing.contact.form.message_placeholder')"
              />
            </div>

            <div class="text-center">
              <Button 
                type="submit"
                :loading="submitting"
                class="bg-gradient-to-r from-blue-600 to-purple-600 hover:from-blue-700 hover:to-purple-700 text-white border-0 px-8 sm:px-10 py-4 sm:py-5 text-base sm:text-lg font-bold shadow-xl hover:shadow-2xl transition-all transform hover:scale-105 rounded-xl min-h-[56px]"
              >
                Submit Inquiry
              </Button>
            </div>
          </form>

          <!-- Alternative Contact Methods -->
          <div class="mt-12 pt-12 border-t border-slate-200">
            <h3 class="text-xl font-bold text-slate-900 mb-6 text-center">{{ $t('landing.contact.alternative_title') }}</h3>
            <div class="grid md:grid-cols-2 gap-6">
              <a :href="`mailto:${contactEmail}`" 
                 class="flex items-center gap-4 p-6 bg-gradient-to-br from-blue-50 to-purple-50 rounded-2xl hover:shadow-lg transition-all border border-blue-200">
                <div class="w-12 h-12 bg-gradient-to-br from-blue-600 to-purple-600 rounded-xl flex items-center justify-center flex-shrink-0">
                  <i class="pi pi-envelope text-white text-lg"></i>
                </div>
                <div>
                  <p class="font-semibold text-slate-900">{{ $t('landing.contact.email_label') }}</p>
                  <p class="text-blue-600 text-sm">{{ contactEmail }}</p>
                </div>
              </a>
              
              <a :href="contactWhatsApp" target="_blank"
                 class="flex items-center gap-4 p-6 bg-gradient-to-br from-emerald-50 to-teal-50 rounded-2xl hover:shadow-lg transition-all border border-emerald-200">
                <div class="w-12 h-12 bg-gradient-to-br from-emerald-600 to-teal-600 rounded-xl flex items-center justify-center flex-shrink-0">
                  <i class="pi pi-comments text-white text-lg"></i>
                </div>
                <div>
                  <p class="font-semibold text-slate-900">{{ $t('landing.contact.whatsapp_label') }}</p>
                  <p class="text-emerald-600 text-sm">{{ contactWhatsAppDisplay }}</p>
                </div>
              </a>
            </div>
          </div>

          <div class="mt-8 text-center">
            <p class="text-sm text-slate-500">
              <i class="pi pi-shield mr-2"></i>
              {{ $t('landing.contact.security_note') }}
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
              {{ $t('landing.footer.description') }}
            </p>
          </div>

          <!-- Quick Links -->
          <div>
            <h4 class="font-bold text-lg mb-4">{{ $t('landing.footer.quick_links') }}</h4>
            <ul class="space-y-2">
              <li><a @click="scrollToSection('about')" class="text-slate-400 hover:text-white transition-colors cursor-pointer">{{ $t('landing.footer.about') }}</a></li>
              <li><a @click="scrollToSection('demo')" class="text-slate-400 hover:text-white transition-colors cursor-pointer">{{ $t('landing.footer.demo') }}</a></li>
              <li><a @click="scrollToSection('pricing')" class="text-slate-400 hover:text-white transition-colors cursor-pointer">{{ $t('landing.footer.pricing') }}</a></li>
              <li><a @click="scrollToSection('contact')" class="text-slate-400 hover:text-white transition-colors cursor-pointer">{{ $t('landing.footer.contact') }}</a></li>
            </ul>
          </div>

          <!-- Contact Info -->
          <div>
            <h4 class="font-bold text-lg mb-4">{{ $t('landing.footer.contact_title') }}</h4>
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
                <i class="pi pi-comments"></i>
                <a :href="contactWhatsApp" target="_blank" class="hover:text-white transition-colors">{{ $t('landing.footer.whatsapp_chat') }}</a>
              </li>
            </ul>
          </div>
        </div>

        <div class="pt-8 border-t border-slate-800">
          <div class="flex flex-col md:flex-row justify-between items-center gap-4">
            <p class="text-slate-500 text-sm">{{ $t('landing.footer.copyright') }}</p>
            <div class="flex gap-6 text-sm">
              <a href="#" class="text-slate-400 hover:text-white transition-colors">{{ $t('landing.footer.privacy') }}</a>
              <a href="#" class="text-slate-400 hover:text-white transition-colors">{{ $t('landing.footer.terms') }}</a>
              <a :href="`mailto:${contactEmail}`" class="text-slate-400 hover:text-white transition-colors">{{ $t('landing.footer.contact_link') }}</a>
            </div>
          </div>
        </div>
      </div>
    </footer>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useI18n } from 'vue-i18n'
import Button from 'primevue/button'
import Carousel from 'primevue/carousel'
import InputText from 'primevue/inputtext'
import Textarea from 'primevue/textarea'
import Dropdown from 'primevue/dropdown'
import QrCode from 'qrcode.vue'
import { getCardAspectRatio } from '@/utils/cardConfig'
import { useToast } from 'primevue/usetoast'
import UnifiedHeader from '@/components/Layout/UnifiedHeader.vue'

const router = useRouter()
const toast = useToast()

// Navigation state
const mobileMenuOpen = ref(false)

// Sample QR code URL
const sampleQrUrl = ref(import.meta.env.VITE_SAMPLE_QR_URL || `${window.location.origin}/c/demo-ancient-artifacts`)

// Demo card configuration
const demoCardTitle = import.meta.env.VITE_DEMO_CARD_TITLE || 'Museum'
const demoCardSubtitle = import.meta.env.VITE_DEMO_CARD_SUBTITLE || 'Scan to explore the exhibits\nActivate your interactive AI guide\nAvailable in multiple languages'
const demoCardImageUrl = import.meta.env.VITE_DEFAULT_CARD_IMAGE_URL || '/Image/DemoCard.jpg'
const cardAspectRatio = computed(() => getCardAspectRatio())

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
      summary: t('landing.contact.toast.missing_info_title'),
      detail: t('landing.contact.toast.missing_info_detail'),
      life: 5000
    })
    return
  }

  submitting.value = true
  
  // Simulate form submission (replace with actual API call)
  setTimeout(() => {
    toast.add({
      severity: 'success',
      summary: t('landing.contact.toast.inquiry_sent_title'),
      detail: t('landing.contact.toast.inquiry_sent_detail'),
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

// Scroll handling (reserved for future use)

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
  setTimeout(() => {
    observeElements()
  }, 100)
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

const demoFeatures = computed(() => [
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

const howItWorksSteps = computed(() => [
  {
    icon: 'pi-shopping-cart',
    title: t('landing.how_it_works.steps.purchase_title'),
    description: t('landing.how_it_works.steps.purchase_desc')
  },
  {
    icon: 'pi-qrcode',
    title: t('landing.how_it_works.steps.scan_title'),
    description: t('landing.how_it_works.steps.scan_desc')
  },
  {
    icon: 'pi-comments',
    title: t('landing.how_it_works.steps.explore_title'),
    description: t('landing.how_it_works.steps.explore_desc')
  },
  {
    icon: 'pi-heart',
    title: t('landing.how_it_works.steps.collect_title'),
    description: t('landing.how_it_works.steps.collect_desc')
  }
])

const keyFeatures = computed(() => [
  {
    icon: 'pi-id-card',
    title: t('landing.features.features.collectible_title'),
    description: t('landing.features.features.collectible_desc')
  },
  {
    icon: 'pi-microphone',
    title: t('landing.features.features.ai_guide_title'),
    description: t('landing.features.features.ai_guide_desc')
  },
  {
    icon: 'pi-mobile',
    title: t('landing.features.features.no_app_title'),
    description: t('landing.features.features.no_app_desc')
  },
  {
    icon: 'pi-globe',
    title: t('landing.features.features.multilingual_title'),
    description: t('landing.features.features.multilingual_desc')
  },
  {
    icon: 'pi-bolt',
    title: t('landing.features.features.no_hardware_title'),
    description: t('landing.features.features.no_hardware_desc')
  },
  {
    icon: 'pi-chart-bar',
    title: t('landing.features.features.dashboard_title'),
    description: t('landing.features.features.dashboard_desc')
  }
])

const applications = computed(() => [
  {
    icon: 'pi-building',
    name: t('landing.applications.apps.museums.name'),
    role: t('landing.applications.apps.museums.role'),
    alternatives: t('landing.applications.apps.museums.alternatives'),
    benefits: [
      t('landing.applications.apps.museums.benefit1'),
      t('landing.applications.apps.museums.benefit2'),
      t('landing.applications.apps.museums.benefit3')
    ]
  },
  {
    icon: 'pi-map-marker',
    name: t('landing.applications.apps.tourist.name'),
    role: t('landing.applications.apps.tourist.role'),
    alternatives: t('landing.applications.apps.tourist.alternatives'),
    benefits: [
      t('landing.applications.apps.tourist.benefit1'),
      t('landing.applications.apps.tourist.benefit2'),
      t('landing.applications.apps.tourist.benefit3')
    ]
  },
  {
    icon: 'pi-star',
    name: t('landing.applications.apps.zoos.name'),
    role: t('landing.applications.apps.zoos.role'),
    alternatives: t('landing.applications.apps.zoos.alternatives'),
    benefits: [
      t('landing.applications.apps.zoos.benefit1'),
      t('landing.applications.apps.zoos.benefit2'),
      t('landing.applications.apps.zoos.benefit3')
    ]
  },
  {
    icon: 'pi-briefcase',
    name: t('landing.applications.apps.trade_shows.name'),
    role: t('landing.applications.apps.trade_shows.role'),
    alternatives: t('landing.applications.apps.trade_shows.alternatives'),
    benefits: [
      t('landing.applications.apps.trade_shows.benefit1'),
      t('landing.applications.apps.trade_shows.benefit2'),
      t('landing.applications.apps.trade_shows.benefit3')
    ]
  },
  {
    icon: 'pi-calendar',
    name: t('landing.applications.apps.conferences.name'),
    role: t('landing.applications.apps.conferences.role'),
    alternatives: t('landing.applications.apps.conferences.alternatives'),
    benefits: [
      t('landing.applications.apps.conferences.benefit1'),
      t('landing.applications.apps.conferences.benefit2'),
      t('landing.applications.apps.conferences.benefit3')
    ]
  },
  {
    icon: 'pi-users',
    name: t('landing.applications.apps.training.name'),
    role: t('landing.applications.apps.training.role'),
    alternatives: t('landing.applications.apps.training.alternatives'),
    benefits: [
      t('landing.applications.apps.training.benefit1'),
      t('landing.applications.apps.training.benefit2'),
      t('landing.applications.apps.training.benefit3')
    ]
  },
  {
    icon: 'pi-home',
    name: t('landing.applications.apps.hotels.name'),
    role: t('landing.applications.apps.hotels.role'),
    alternatives: t('landing.applications.apps.hotels.alternatives'),
    benefits: [
      t('landing.applications.apps.hotels.benefit1'),
      t('landing.applications.apps.hotels.benefit2'),
      t('landing.applications.apps.hotels.benefit3')
    ]
  },
  {
    icon: 'pi-server',
    name: t('landing.applications.apps.restaurants.name'),
    role: t('landing.applications.apps.restaurants.role'),
    alternatives: t('landing.applications.apps.restaurants.alternatives'),
    benefits: [
      t('landing.applications.apps.restaurants.benefit1'),
      t('landing.applications.apps.restaurants.benefit2'),
      t('landing.applications.apps.restaurants.benefit3')
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

const venueBenefits = computed(() => [
  t('landing.benefits.venue_benefits.engagement'),
  t('landing.benefits.venue_benefits.global'),
  t('landing.benefits.venue_benefits.reputation'),
  t('landing.benefits.venue_benefits.sustainability'),
  t('landing.benefits.venue_benefits.revenue'),
  t('landing.benefits.venue_benefits.rollout')
])

const visitorBenefits = computed(() => [
  t('landing.benefits.visitor_benefits.personalized'),
  t('landing.benefits.visitor_benefits.educational'),
  t('landing.benefits.visitor_benefits.language'),
  t('landing.benefits.visitor_benefits.souvenir'),
  t('landing.benefits.visitor_benefits.access')
])

const pricingFeatures = computed(() => [
  t('landing.pricing.features.ai_voice'),
  t('landing.pricing.features.multilingual'),
  t('landing.pricing.features.design_dashboard'),
  t('landing.pricing.features.content_management'),
  t('landing.pricing.features.analytics'),
  t('landing.pricing.features.qr_generation'),
  t('landing.pricing.features.print_management'),
  t('landing.pricing.features.cloud_hosting'),
  t('landing.pricing.features.support')
])

const faqs = computed(() => [
  {
    question: t('landing.faq.q1'),
    answer: t('landing.faq.a1')
  },
  {
    question: t('landing.faq.q2'),
    answer: t('landing.faq.a2')
  },
  {
    question: t('landing.faq.q3'),
    answer: t('landing.faq.a3')
  },
  {
    question: t('landing.faq.q4'),
    answer: t('landing.faq.a4')
  },
  {
    question: t('landing.faq.q5'),
    answer: t('landing.faq.a5')
  },
  {
    question: t('landing.faq.q6'),
    answer: t('landing.faq.a6')
  },
  {
    question: t('landing.faq.q7'),
    answer: t('landing.faq.a7')
  },
  {
    question: t('landing.faq.q8'),
    answer: t('landing.faq.a8')
  },
  {
    question: t('landing.faq.q9'),
    answer: t('landing.faq.a9', { min: minBatchQuantity })
  }
])

const organizationTypes = computed(() => [
  t('landing.contact.organization_types.museum'),
  t('landing.contact.organization_types.gallery'),
  t('landing.contact.organization_types.exhibition'),
  t('landing.contact.organization_types.conference'),
  t('landing.contact.organization_types.tourist'),
  t('landing.contact.organization_types.zoo'),
  t('landing.contact.organization_types.trade_show'),
  t('landing.contact.organization_types.hotel'),
  t('landing.contact.organization_types.restaurant'),
  t('landing.contact.organization_types.theme_park'),
  t('landing.contact.organization_types.training'),
  t('landing.contact.organization_types.agency'),
  t('landing.contact.organization_types.other')
])

const visitorCountOptions = computed(() => [
  t('landing.contact.visitor_counts.under_1k'),
  t('landing.contact.visitor_counts.1k_5k'),
  t('landing.contact.visitor_counts.5k_10k'),
  t('landing.contact.visitor_counts.10k_50k'),
  t('landing.contact.visitor_counts.50k_100k'),
  t('landing.contact.visitor_counts.over_100k')
])

const inquiryTypes = computed(() => [
  t('landing.contact.inquiry_types.pilot'),
  t('landing.contact.inquiry_types.info'),
  t('landing.contact.inquiry_types.pricing'),
  t('landing.contact.inquiry_types.partnership'),
  t('landing.contact.inquiry_types.licensing'),
  t('landing.contact.inquiry_types.technical'),
  t('landing.contact.inquiry_types.other')
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

@keyframes pulse {
  0%, 100% { 
    opacity: 1;
  }
  50% { 
    opacity: 0.6;
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

.animate-float {
  animation: float 3s ease-in-out infinite;
}

.animate-pulse-slow {
  animation: pulse 3s cubic-bezier(0.4, 0, 0.6, 1) infinite;
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
