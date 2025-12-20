<template>
  <div class="min-h-screen bg-white">
    <!-- Unified Header Component -->
    <UnifiedHeader 
      mode="landing"
      @scroll-to="scrollToSection"
    />
    
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
          <!-- Brand Badge -->
          <div class="inline-flex items-center gap-2 px-4 py-2 bg-white/10 backdrop-blur-sm rounded-full border border-white/20 mb-6 animate-fade-in-up">
            <div class="w-6 h-6 bg-gradient-to-br from-blue-500 to-purple-600 rounded-lg flex items-center justify-center">
              <i class="pi pi-qrcode text-white text-xs"></i>
            </div>
            <span class="text-white font-semibold text-sm">ExperienceQR</span>
          </div>
          
          <h1 class="text-4xl sm:text-5xl md:text-6xl lg:text-7xl font-black mb-6 sm:mb-8 leading-tight text-white animate-fade-in-up">
            {{ $t('landing.hero.title_line1') }} <br class="hidden sm:block" />
            <span class="bg-gradient-to-r from-yellow-400 via-orange-500 to-pink-500 bg-clip-text text-transparent">
              {{ $t('landing.hero.title_line2') }}
            </span> <br class="hidden sm:block" />
            {{ $t('landing.hero.title_line3') }}
          </h1>
          
          <p class="text-lg sm:text-xl md:text-2xl text-blue-100/90 max-w-4xl mx-auto mb-10 sm:mb-12 leading-relaxed font-light animate-fade-in-up animation-delay-200 px-2">
            {{ $t('landing.hero.subtitle_part1') }}
            <span class="font-semibold text-white">{{ $t('landing.hero.subtitle_highlight') }}</span> {{ $t('landing.hero.subtitle_part2') }}
          </p>
          
          <div class="flex flex-col sm:flex-row gap-4 sm:gap-6 justify-center items-center mb-16 animate-fade-in-up animation-delay-400 px-4 sm:px-0">
            <button 
              @click="scrollToSection('demo-templates')"
              class="flex items-center justify-center gap-3 bg-white hover:bg-blue-50 border-0 px-8 sm:px-10 py-4 sm:py-5 text-base sm:text-lg font-bold text-slate-900 shadow-2xl hover:shadow-white/50 transition-all duration-300 transform hover:scale-105 rounded-xl cursor-pointer w-full sm:w-auto"
            >
              <span>{{ $t('landing.hero.cta_demo') }}</span>
              <i class="pi pi-play-circle text-xl"></i>
            </button>
            <button 
              @click="handleGetStarted"
              class="flex items-center justify-center gap-3 border-2 border-white/40 bg-white/10 hover:bg-white/20 backdrop-blur-sm px-8 sm:px-10 py-4 sm:py-5 text-base sm:text-lg font-bold text-white hover:border-white/60 shadow-lg hover:shadow-white/25 transition-all duration-300 transform hover:scale-105 rounded-xl cursor-pointer w-full sm:w-auto"
            >
              <span>{{ $t('landing.hero.cta_start') }}</span>
              <i class="pi pi-arrow-right text-xl"></i>
            </button>
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

    <!-- Key Features -->
    <section id="features" class="py-20 sm:py-32 bg-gradient-to-b from-slate-50 to-white">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div class="text-center mb-20">
          <h2 class="text-4xl sm:text-5xl lg:text-6xl font-black text-slate-900 mb-6">
            {{ $t('landing.features.title') }} <span class="bg-gradient-to-r from-amber-600 to-orange-600 bg-clip-text text-transparent">{{ $t('landing.features.title_highlight') }}</span>
          </h2>
        </div>
        
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-2 gap-8 max-w-5xl mx-auto">
          <div v-for="(feature, index) in keyFeatures" :key="feature.title" 
               class="group relative animate-on-scroll"
               :style="{ animationDelay: (index * 100) + 'ms' }">
            <div class="absolute inset-0 bg-gradient-to-r from-blue-600 to-purple-600 rounded-3xl opacity-0 group-hover:opacity-100 transition-opacity duration-300 blur-xl"></div>
            <div class="relative bg-white rounded-3xl p-8 shadow-lg hover:shadow-2xl transition-all duration-300 border border-slate-200 hover:border-blue-300 hover:-translate-y-1 h-full">
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

    <!-- How ExperienceQR Works -->
    <section id="how-it-works" class="py-20 sm:py-32 bg-gradient-to-b from-white to-slate-50 relative overflow-hidden">
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
          
          <div class="grid grid-cols-1 md:grid-cols-3 gap-8">
            <div v-for="(step, index) in howItWorksSteps.slice(0, 3)" :key="index" class="relative group">
              <!-- Card Content -->
              <div class="relative bg-white rounded-3xl p-8 shadow-lg hover:shadow-2xl transition-all duration-500 border-2 border-slate-200 hover:border-purple-400 hover:-translate-y-2 h-full">
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

    <!-- Demo & Solution Showcase Section -->
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
          <!-- Demo Mode Toggle -->
          <div class="flex justify-center mt-12 mb-4">
            <div class="bg-white/10 backdrop-blur-sm rounded-2xl p-1.5 inline-flex gap-1">
              <button
                @click="demoMode = 'digital'"
                :class="[
                  'flex items-center gap-2 px-5 py-3 rounded-xl font-semibold transition-all duration-300',
                  demoMode === 'digital'
                    ? 'bg-gradient-to-r from-emerald-600 to-cyan-600 text-white shadow-lg'
                    : 'text-white/70 hover:text-white hover:bg-white/10'
                ]"
              >
                <i class="pi pi-qrcode"></i>
                <span>{{ $t('landing.demo.mode_toggle.digital_access') }}</span>
              </button>
              <button
                @click="demoMode = 'physical'"
                :class="[
                  'flex items-center gap-2 px-5 py-3 rounded-xl font-semibold transition-all duration-300',
                  demoMode === 'physical'
                    ? 'bg-gradient-to-r from-blue-600 to-purple-600 text-white shadow-lg'
                    : 'text-white/70 hover:text-white hover:bg-white/10'
                ]"
              >
                <i class="pi pi-id-card"></i>
                <span>{{ $t('landing.demo.mode_toggle.physical_card') }}</span>
              </button>
            </div>
          </div>
          
          <!-- Access Mode Description -->
          <div class="text-center mb-8 max-w-2xl mx-auto">
            <p v-if="demoMode === 'physical'" class="text-blue-100/80 text-sm sm:text-base">
              {{ $t('landing.demo.physical_card.full_desc') }}
            </p>
            <p v-else class="text-emerald-100/80 text-sm sm:text-base">
              {{ $t('landing.demo.digital_access.full_desc') }}
            </p>
          </div>

          <!-- Demo Card Preview -->
          <div class="grid md:grid-cols-5 gap-12 lg:gap-16 items-center">
            <!-- Left Column: Demo Card (2/5 width) -->
            <div class="md:col-span-2 relative w-full animate-on-scroll">
              <!-- Ambient glow -->
              <div :class="[
                'absolute inset-0 rounded-3xl blur-3xl opacity-50 transition-all duration-500',
                demoMode === 'physical' ? 'bg-gradient-to-r from-blue-600 to-purple-600' : 'bg-gradient-to-r from-emerald-600 to-cyan-600'
              ]"></div>
              
              <!-- Physical Card Demo -->
              <div v-if="demoMode === 'physical'" class="relative bg-white rounded-3xl p-4 shadow-2xl hover:shadow-[0_20px_60px_rgba(59,130,246,0.3)] transition-all duration-500">
                <div :style="{ aspectRatio: cardAspectRatio }" class="bg-gradient-to-br from-blue-600 via-purple-600 to-pink-600 rounded-2xl overflow-hidden relative group">
                  <img 
                    :src="demoCardImageUrl" 
                    :alt="$t('landing.demo.card_title')"
                    class="w-full h-full object-cover group-hover:scale-110 transition-transform duration-700"
                  />
                  <div class="absolute inset-0 bg-gradient-to-t from-black/80 via-black/20 to-transparent"></div>
                  
                  <div class="absolute bottom-4 left-4 right-4 text-white">
                    <h3 class="text-2xl font-bold mb-2">{{ demoCardTitle }}</h3>
                    <p class="text-sm opacity-90 whitespace-pre-line">{{ demoCardSubtitle }}</p>
                  </div>
                  
                  <!-- QR Code -->
                  <div class="absolute top-4 right-4">
                    <div class="relative group/qr">
                      <div class="absolute inset-0 bg-white/60 rounded-lg blur-md"></div>
                      <div 
                        class="relative bg-white/95 backdrop-blur-sm rounded-lg p-2 shadow-lg ring-1 ring-white/20 transition-all duration-300 group-hover/qr:scale-105 group-hover/qr:shadow-xl"
                        :class="{ 'cursor-pointer': demoCardUrl }"
                        @click="openDemoUrl(demoCardUrl)"
                        :title="demoCardUrl ? $t('landing.demo_templates.scan_or_click') : ''"
                      >
                        <QrCode v-if="demoCardUrl" :value="demoCardUrl" :size="56" />
                        <!-- Fallback decorative pattern if no URL configured -->
                        <div v-else class="w-14 h-14 grid grid-cols-5 gap-0.5">
                          <div class="col-span-2 row-span-2 bg-slate-800 rounded-sm relative">
                            <div class="absolute inset-1 bg-white rounded-sm">
                              <div class="absolute inset-1 bg-slate-800 rounded-sm"></div>
                            </div>
                          </div>
                          <div class="bg-slate-800 rounded-sm"></div>
                          <div class="col-span-2 row-span-2 bg-slate-800 rounded-sm relative">
                            <div class="absolute inset-1 bg-white rounded-sm">
                              <div class="absolute inset-1 bg-slate-800 rounded-sm"></div>
                            </div>
                          </div>
                          <div class="bg-white"></div>
                          <div class="bg-slate-800 rounded-sm"></div>
                          <div class="bg-slate-800 rounded-sm"></div>
                          <div class="bg-white"></div>
                          <div class="bg-slate-800 rounded-sm"></div>
                          <div class="bg-white"></div>
                          <div class="bg-slate-800 rounded-sm"></div>
                          <div class="col-span-2 row-span-2 bg-slate-800 rounded-sm relative">
                            <div class="absolute inset-1 bg-white rounded-sm">
                              <div class="absolute inset-1 bg-slate-800 rounded-sm"></div>
                            </div>
                          </div>
                          <div class="bg-white"></div>
                          <div class="bg-slate-800 rounded-sm"></div>
                          <div class="bg-white"></div>
                          <div class="bg-slate-800 rounded-sm"></div>
                          <div class="bg-white"></div>
                          <div class="bg-slate-800 rounded-sm"></div>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
                
                <!-- Physical Card Info Caption -->
                <div class="mt-4 text-center">
                  <p class="text-sm text-slate-500 italic">{{ $t('landing.demo.physical_card.caption') }}</p>
                </div>
              </div>

              <!-- Digital Access Demo -->
              <div v-else class="relative bg-gradient-to-br from-slate-800 to-slate-900 rounded-3xl p-6 shadow-2xl hover:shadow-[0_20px_60px_rgba(16,185,129,0.3)] transition-all duration-500 border border-emerald-500/20">
                <div class="text-center">
                  <!-- Title -->
                  <div class="mb-6">
                    <h3 class="text-2xl font-bold text-white mb-2">{{ digitalAccessDemoTitle }}</h3>
                    <p class="text-emerald-200/80 text-sm">{{ digitalAccessDemoSubtitle }}</p>
                  </div>
                  
                  <!-- QR Code -->
                  <div class="flex justify-center mb-6">
                    <div class="relative group/qr">
                      <div class="absolute inset-0 bg-emerald-400/30 rounded-2xl blur-xl"></div>
                      <div 
                        class="relative bg-white rounded-2xl p-5 shadow-xl transition-all duration-300 group-hover/qr:scale-105"
                        :class="{ 'cursor-pointer': digitalAccessDemoUrl }"
                        @click="openDemoUrl(digitalAccessDemoUrl)"
                        :title="digitalAccessDemoUrl ? $t('landing.demo_templates.scan_or_click') : ''"
                      >
                        <QrCode v-if="digitalAccessDemoUrl" :value="digitalAccessDemoUrl" :size="140" />
                        <!-- Fallback decorative pattern if no URL configured -->
                        <div v-else class="w-32 h-32 grid grid-cols-7 gap-1">
                          <div class="col-span-3 row-span-3 bg-emerald-700 rounded relative">
                            <div class="absolute inset-1.5 bg-white rounded">
                              <div class="absolute inset-1.5 bg-emerald-700 rounded"></div>
                            </div>
                          </div>
                          <div class="bg-white"></div>
                          <div class="col-span-3 row-span-3 bg-emerald-700 rounded relative">
                            <div class="absolute inset-1.5 bg-white rounded">
                              <div class="absolute inset-1.5 bg-emerald-700 rounded"></div>
                            </div>
                          </div>
                          <div class="bg-emerald-700 rounded"></div>
                          <div class="bg-white"></div>
                          <div class="bg-emerald-700 rounded"></div>
                          <div class="bg-white"></div>
                          <div class="bg-emerald-700 rounded"></div>
                          <div class="bg-white"></div>
                          <div class="bg-emerald-700 rounded"></div>
                          <div class="bg-white"></div>
                          <div class="bg-emerald-700 rounded"></div>
                          <div class="bg-white"></div>
                          <div class="bg-emerald-700 rounded"></div>
                          <div class="bg-white"></div>
                          <div class="bg-emerald-700 rounded"></div>
                          <div class="bg-white"></div>
                          <div class="col-span-3 row-span-3 bg-emerald-700 rounded relative">
                            <div class="absolute inset-1.5 bg-white rounded">
                              <div class="absolute inset-1.5 bg-emerald-700 rounded"></div>
                            </div>
                          </div>
                          <div class="bg-emerald-700 rounded"></div>
                          <div class="bg-white"></div>
                          <div class="bg-emerald-700 rounded"></div>
                          <div class="bg-white"></div>
                        </div>
                      </div>
                    </div>
                  </div>
                  
                  <!-- Digital Access Caption -->
                  <p class="text-slate-400 text-sm">{{ $t('landing.demo.digital_access.caption') }}</p>
                </div>
              </div>
            </div>

            <!-- Right Column: Features & Guide (3/5 width) -->
            <div class="md:col-span-3 space-y-8 animate-on-scroll" style="animation-delay: 200ms">
              <!-- Visual Guide - Desktop Only -->
              <div class="hidden lg:block">
                <div :class="[
                  'backdrop-blur-sm border rounded-2xl p-6 transition-all duration-300',
                  demoMode === 'physical' 
                    ? 'bg-white/5 border-white/10' 
                    : 'bg-emerald-500/5 border-emerald-500/20'
                ]">
                  <div class="flex items-start gap-4">
                    <div :class="[
                      'flex-shrink-0 w-12 h-12 rounded-xl flex items-center justify-center shadow-lg transition-all duration-300',
                      demoMode === 'physical'
                        ? 'bg-gradient-to-br from-blue-500 to-purple-600'
                        : 'bg-gradient-to-br from-emerald-500 to-cyan-600'
                    ]">
                      <i :class="['pi text-white text-xl', demoMode === 'physical' ? 'pi-id-card' : 'pi-qrcode']"></i>
                    </div>
                    <div>
                      <h4 class="text-lg font-bold text-white mb-1">
                        {{ demoMode === 'physical' ? $t('landing.demo.physical_card.title') : $t('landing.demo.digital_access.title') }}
                      </h4>
                      <p class="text-sm text-white/70">
                        {{ demoMode === 'physical' ? $t('landing.demo.physical_card.desc') : $t('landing.demo.digital_access.desc') }}
                      </p>
                    </div>
                  </div>
                </div>
              </div>
              
              <h3 class="text-3xl font-bold text-white">{{ $t('landing.demo.experience_features') }}</h3>
              
              <div v-for="(feature, index) in demoFeatures" :key="index" class="flex gap-4">
                <div :class="[
                  'w-12 h-12 backdrop-blur-sm rounded-xl flex items-center justify-center flex-shrink-0 transition-all duration-300',
                  demoMode === 'physical'
                    ? 'bg-gradient-to-br from-blue-600/20 to-purple-600/20'
                    : 'bg-gradient-to-br from-emerald-600/20 to-cyan-600/20'
                ]">
                  <i :class="[
                    `pi ${feature.icon} text-xl`,
                    demoMode === 'physical' ? 'text-blue-400' : 'text-emerald-400'
                  ]"></i>
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

    <!-- Demo Templates - Clean & Modern -->
    <section id="demo-templates" v-if="demoTemplates.length > 0" class="py-12 sm:py-20 lg:py-28 bg-gradient-to-b from-white via-blue-50/30 to-purple-50/30 relative overflow-hidden">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        
        <!-- Section Header -->
        <div class="text-center mb-8 sm:mb-12 lg:mb-16">
          <h2 class="text-2xl sm:text-3xl md:text-4xl lg:text-5xl font-bold text-slate-900 mb-3 sm:mb-4">
            {{ $t('landing.demo_templates.title') }}
          </h2>
          <p class="text-base sm:text-lg text-slate-600 max-w-2xl mx-auto px-2">
            {{ $t('landing.demo_templates.subtitle') }}
          </p>
        </div>

        <!-- Main Demo Area -->
        <div class="grid grid-cols-1 lg:grid-cols-2 gap-6 sm:gap-8 lg:gap-16 items-start lg:items-center">
          
          <!-- Left: Phone Preview -->
          <div class="flex justify-center order-1">
            <div class="relative">
              <!-- Decorative gradient blob - hidden on mobile to prevent overflow -->
              <div class="hidden sm:block absolute -inset-4 bg-gradient-to-tr from-blue-100 via-purple-50 to-pink-100 rounded-[2.5rem] blur-xl opacity-70"></div>
              
              <div class="relative">
                <PhoneSimulator :width="phoneSimulatorWidth" class="shadow-2xl">
                  <div class="simulator-content">
                    <!-- Placeholder State (no template selected) -->
                    <div v-if="!selectedTemplate" class="simulator-placeholder light">
                      <div class="w-12 h-12 sm:w-16 sm:h-16 rounded-xl sm:rounded-2xl bg-slate-100 flex items-center justify-center mb-3 sm:mb-4">
                        <i class="pi pi-mobile text-xl sm:text-2xl text-slate-400"></i>
                      </div>
                      <p class="text-slate-500 font-medium text-sm sm:text-base text-center px-4">{{ $t('landing.demo_templates.select_template') }}</p>
                    </div>
                    
                    <!-- Live Preview iframe (renders behind loading if loading) -->
                    <div v-if="selectedTemplate?.access_url" class="simulator-iframe-wrapper">
                      <iframe 
                        :src="getTemplateUrl(selectedTemplate)"
                        class="simulator-iframe"
                        :style="{ transform: `translate(-50%, -50%) scale(${phoneSimulatorWidth / 375})` }"
                        :title="selectedTemplate.name"
                        loading="lazy"
                        @load="handleIframeLoad"
                        @error="handleIframeError"
                      ></iframe>
                    </div>
                    
                    <!-- Loading Spinner (overlays iframe while loading) -->
                    <div v-if="selectedTemplate && iframeLoading && !iframeError" class="simulator-loading light">
                      <ProgressSpinner strokeWidth="3" animationDuration=".8s" class="w-8 h-8 sm:w-10 sm:h-10"/>
                      <p class="text-slate-500 mt-2 sm:mt-3 text-sm sm:text-base">{{ $t('common.loading') }}</p>
                    </div>
                    
                    <!-- Error State -->
                    <div v-if="selectedTemplate && iframeError" class="simulator-placeholder light">
                      <div class="w-12 h-12 sm:w-16 sm:h-16 rounded-xl sm:rounded-2xl bg-red-50 flex items-center justify-center mb-3 sm:mb-4">
                        <i class="pi pi-exclamation-triangle text-xl sm:text-2xl text-red-400"></i>
                      </div>
                      <p class="text-slate-500 font-medium text-sm sm:text-base text-center px-4 mb-3">{{ $t('common.load_error') }}</p>
                      <button 
                        @click="retryIframeLoad"
                        class="px-4 py-2 bg-blue-500 hover:bg-blue-600 text-white text-sm font-medium rounded-lg transition-colors"
                      >
                        {{ $t('common.retry') }}
                      </button>
                    </div>
                  </div>
                </PhoneSimulator>
              </div>
            </div>
          </div>

          <!-- Right: Template Selector -->
          <div class="order-2 w-full">
            <!-- Currently Selected with QR Code -->
            <div v-if="selectedTemplate" class="mb-4 sm:mb-6 p-3 sm:p-4 bg-gradient-to-br from-blue-50 to-purple-50 rounded-xl sm:rounded-2xl border border-blue-100">
              <div class="flex items-center gap-3 sm:gap-4">
                <!-- Template Info -->
                <div class="flex-1 min-w-0">
                  <div class="flex items-center gap-2 sm:gap-3">
                    <div class="w-8 h-8 sm:w-10 sm:h-10 rounded-lg bg-gradient-to-br from-blue-500 to-purple-600 flex items-center justify-center flex-shrink-0 shadow-sm">
                      <i :class="getVenueIcon(selectedTemplate.venue_type)" class="text-white text-xs sm:text-sm"></i>
                    </div>
                    <div class="min-w-0 flex-1">
                      <h3 class="font-semibold text-slate-900 text-sm sm:text-base leading-tight mb-1">{{ selectedTemplate.name }}</h3>
                      <div class="flex items-center gap-2">
                        <p class="text-xs text-slate-500">{{ formatVenueType(selectedTemplate.venue_type) }}</p>
                        <span class="inline-flex items-center gap-1 px-1.5 py-0.5 bg-green-100 text-green-700 text-[9px] sm:text-[10px] font-medium rounded">
                          <span class="w-1 h-1 bg-green-500 rounded-full animate-pulse"></span>
                          Live
                        </span>
                      </div>
                    </div>
                  </div>
                </div>
                
                <!-- QR Code (md+ screens) -->
                <div class="hidden md:flex flex-col items-center flex-shrink-0 w-[138px]">
                  <div class="p-1.5 bg-white rounded-lg shadow-sm border border-slate-100">
                    <QrCode 
                      :value="getTemplateUrl(selectedTemplate)" 
                      :size="72"
                      level="M"
                    />
                  </div>
                  <p class="text-[9px] text-slate-400 mt-1.5 text-center leading-tight">{{ $t('landing.demo_templates.scan_hint') }}</p>
                </div>
                
                <!-- Open button (Mobile only) -->
                <button
                  @click="openTemplate(selectedTemplate)"
                  class="md:hidden flex-shrink-0 inline-flex items-center gap-1.5 px-3 py-1.5 bg-white hover:bg-slate-50 text-slate-700 text-xs font-medium rounded-lg border border-slate-200 shadow-sm transition-colors"
                >
                  <i class="pi pi-external-link text-[10px]"></i>
                  Open
                </button>
              </div>
            </div>

            <!-- Filter Tabs -->
            <div class="mb-3 sm:mb-4 -mx-1">
              <div ref="venueFilterScroll" class="flex gap-1.5 sm:gap-2 overflow-x-auto pb-2 px-1 scrollbar-hide">
                <button 
                  class="flex-shrink-0 px-2.5 sm:px-3 py-1 sm:py-1.5 text-xs sm:text-sm font-medium rounded-lg transition-all"
                  :class="selectedVenueType === null 
                    ? 'bg-gradient-to-r from-blue-600 to-purple-600 text-white shadow-sm' 
                    : 'text-slate-600 hover:bg-white hover:shadow-sm'"
                  @click="selectVenueType(null)"
                >
                  {{ $t('landing.demo_templates.all_types') }}
                </button>
                <button 
                  v-for="venueType in availableVenueTypes"
                  :key="venueType"
                  class="flex-shrink-0 px-2.5 sm:px-3 py-1 sm:py-1.5 text-xs sm:text-sm font-medium rounded-lg transition-all whitespace-nowrap"
                  :class="selectedVenueType === venueType 
                    ? 'bg-gradient-to-r from-blue-600 to-purple-600 text-white shadow-sm' 
                    : 'text-slate-600 hover:bg-white hover:shadow-sm'"
                  @click="selectVenueType(venueType)"
                >
                  {{ formatVenueType(venueType) }}
                </button>
              </div>
            </div>

            <!-- Template List -->
            <div class="space-y-1.5 sm:space-y-2 max-h-[280px] sm:max-h-[320px] lg:max-h-[360px] overflow-y-auto pr-1 sm:pr-2 demo-template-list">
              <button 
                v-for="template in filteredTemplates" 
                :key="template.id"
                @click="selectTemplateForPreview(template)"
                class="w-full text-left p-2 sm:p-3 rounded-lg sm:rounded-xl transition-all duration-200 group"
                :class="selectedTemplate?.id === template.id 
                  ? 'bg-gradient-to-r from-blue-50 to-purple-50 border-2 border-blue-400 shadow-sm' 
                  : 'bg-white/80 border-2 border-transparent hover:bg-white hover:border-slate-200 hover:shadow-sm'"
              >
                <div class="flex items-center gap-2 sm:gap-3">
                  <div 
                    class="w-7 h-7 sm:w-9 sm:h-9 rounded-md sm:rounded-lg flex items-center justify-center flex-shrink-0 transition-colors"
                    :class="selectedTemplate?.id === template.id 
                      ? 'bg-gradient-to-br from-blue-500 to-purple-600 text-white' 
                      : 'bg-slate-100 text-slate-500 group-hover:bg-slate-200'"
                  >
                    <i :class="getVenueIcon(template.venue_type)" class="text-xs sm:text-sm"></i>
                  </div>
                  <div class="min-w-0 flex-1">
                    <h4 
                      class="font-medium text-sm sm:text-base truncate transition-colors"
                      :class="selectedTemplate?.id === template.id ? 'text-blue-900' : 'text-slate-900'"
                    >
                      {{ template.name }}
                    </h4>
                    <p class="text-[10px] sm:text-xs text-slate-500 truncate">{{ formatVenueType(template.venue_type) }}</p>
                  </div>
                  <i 
                    v-if="selectedTemplate?.id === template.id" 
                    class="pi pi-check-circle text-purple-500 flex-shrink-0 text-sm sm:text-base"
                  ></i>
                  <i 
                    v-else 
                    class="pi pi-chevron-right text-slate-300 group-hover:text-slate-400 flex-shrink-0 text-xs sm:text-sm"
                  ></i>
                </div>
              </button>
              
              <!-- Empty State -->
              <div v-if="filteredTemplates.length === 0" class="py-8 text-center">
                <p class="text-slate-500">{{ $t('landing.demo_templates.no_templates') }}</p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>

    <!-- Content Modes Showcase -->
    <section class="py-20 sm:py-32 bg-white relative overflow-hidden">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div class="text-center mb-12 sm:mb-16">
          <h2 class="text-3xl sm:text-4xl md:text-5xl lg:text-6xl font-black text-slate-900 mb-4 sm:mb-6">
            {{ $t('landing.content_modes.title') }} <span class="bg-gradient-to-r from-blue-600 to-purple-600 bg-clip-text text-transparent">{{ $t('landing.content_modes.title_highlight') }}</span>
          </h2>
          <p class="text-lg sm:text-xl text-slate-600 max-w-3xl mx-auto px-2">
            {{ $t('landing.content_modes.subtitle') }}
          </p>
        </div>

        <!-- Mode Tabs - Responsive -->
        <div class="mb-6 sm:mb-8">
          <!-- Mobile: Horizontal scroll tabs -->
          <div class="flex gap-2 overflow-x-auto pb-2 sm:hidden scrollbar-hide px-1">
            <button 
              v-for="mode in contentModes" 
              :key="mode.key"
              @click="selectMode(mode.key)"
              :class="[
                'flex-shrink-0 flex items-center gap-2 px-4 py-3 rounded-xl font-semibold text-sm transition-all whitespace-nowrap',
                selectedMode === mode.key 
                  ? 'bg-gradient-to-r from-blue-600 to-purple-600 text-white shadow-lg' 
                  : 'bg-slate-100 text-slate-600 hover:bg-slate-200'
              ]"
            >
              <i :class="`pi ${mode.icon}`"></i>
              <span>{{ $t(`landing.content_modes.${mode.key}.name`) }}</span>
            </button>
          </div>
          
          <!-- Desktop: Centered tabs -->
          <div class="hidden sm:flex justify-center gap-3 flex-wrap">
            <button 
              v-for="mode in contentModes" 
              :key="mode.key"
              @click="selectMode(mode.key)"
              :class="[
                'flex items-center gap-2 px-5 py-3 rounded-xl font-semibold transition-all duration-300',
                selectedMode === mode.key 
                  ? 'bg-gradient-to-r from-blue-600 to-purple-600 text-white shadow-lg scale-105' 
                  : 'bg-slate-100 text-slate-600 hover:bg-slate-200 hover:scale-102'
              ]"
            >
              <i :class="`pi ${mode.icon} text-lg`"></i>
              <span>{{ $t(`landing.content_modes.${mode.key}.name`) }}</span>
            </button>
          </div>
        </div>
        
        <!-- Grouping Options (only for modes that support grouping) -->
        <div v-if="currentModeSupportsGrouping" class="mb-8 sm:mb-12">
          <div class="flex justify-center">
            <div class="inline-flex items-center gap-1 p-1 bg-slate-100 rounded-xl">
              <button 
                @click="selectedGrouping = 'none'"
                :class="[
                  'px-4 py-2 rounded-lg text-sm font-medium transition-all',
                  selectedGrouping === 'none'
                    ? 'bg-white text-slate-900 shadow-sm'
                    : 'text-slate-500 hover:text-slate-700'
                ]"
              >
                {{ $t('landing.content_modes.grouping_flat') }}
              </button>
              <button 
                @click="selectedGrouping = 'expanded'"
                :class="[
                  'px-4 py-2 rounded-lg text-sm font-medium transition-all',
                  selectedGrouping === 'expanded'
                    ? 'bg-white text-slate-900 shadow-sm'
                    : 'text-slate-500 hover:text-slate-700'
                ]"
              >
                {{ $t('landing.content_modes.grouping_expanded') }}
              </button>
              <button 
                @click="selectedGrouping = 'collapsed'"
                :class="[
                  'px-4 py-2 rounded-lg text-sm font-medium transition-all',
                  selectedGrouping === 'collapsed'
                    ? 'bg-white text-slate-900 shadow-sm'
                    : 'text-slate-500 hover:text-slate-700'
                ]"
              >
                {{ $t('landing.content_modes.grouping_collapsed') }}
              </button>
            </div>
          </div>
          <p class="text-center text-sm text-slate-500 mt-3">
            {{ selectedGrouping === 'none' ? $t('landing.content_modes.grouping_flat_desc') : 
               selectedGrouping === 'expanded' ? $t('landing.content_modes.grouping_expanded_desc') : 
               $t('landing.content_modes.grouping_collapsed_desc') }}
          </p>
        </div>

        <!-- Mode Display -->
        <div class="grid lg:grid-cols-2 gap-8 lg:gap-16 items-center">
          <!-- Left: Phone Mockup with Schematic -->
          <div class="relative flex justify-center animate-on-scroll">
            <div class="relative">
              <!-- Phone Frame -->
              <div class="relative w-[280px] sm:w-[320px] bg-slate-900 rounded-[2.5rem] p-3 shadow-2xl">
                <!-- Notch -->
                <div class="absolute top-0 left-1/2 -translate-x-1/2 w-32 h-6 bg-slate-900 rounded-b-2xl z-10"></div>
                
                <!-- Screen Content -->
                <div class="bg-gradient-to-br from-slate-800 to-slate-900 rounded-[2rem] overflow-hidden aspect-[9/19.5]">
                  <!-- Header Bar -->
                  <div class="h-12 bg-slate-800/80 backdrop-blur flex items-center justify-between px-4">
                    <i class="pi pi-arrow-left text-white/60 text-sm"></i>
                    <span class="text-white/90 text-sm font-medium">{{ $t(`landing.content_modes.${selectedMode}.name`) }}</span>
                    <i class="pi pi-globe text-white/60 text-sm"></i>
                  </div>
                  
                  <!-- Dynamic Schematic Content -->
                  <div class="p-4 h-full">
                    <!-- Single Mode -->
                    <div v-if="selectedMode === 'single'" class="space-y-4 animate-fade-in">
                      <div class="w-full h-32 bg-gradient-to-br from-blue-500/30 to-purple-500/30 rounded-xl flex items-center justify-center">
                        <i class="pi pi-image text-white/40 text-4xl"></i>
                      </div>
                      <div class="h-6 bg-white/20 rounded-lg w-3/4"></div>
                      <div class="space-y-2">
                        <div class="h-3 bg-white/10 rounded w-full"></div>
                        <div class="h-3 bg-white/10 rounded w-full"></div>
                        <div class="h-3 bg-white/10 rounded w-5/6"></div>
                        <div class="h-3 bg-white/10 rounded w-full"></div>
                        <div class="h-3 bg-white/10 rounded w-4/5"></div>
                      </div>
                    </div>
                    
                    <!-- Grid Mode -->
                    <div v-else-if="selectedMode === 'grid'" class="animate-fade-in">
                      <div class="h-5 bg-white/20 rounded w-1/2 mb-4"></div>
                      
                      <!-- Flat Grid -->
                      <div v-if="selectedGrouping === 'none'" class="grid grid-cols-2 gap-3">
                        <div v-for="i in 4" :key="i" class="bg-white/10 rounded-xl overflow-hidden">
                          <div class="aspect-square bg-gradient-to-br from-blue-500/20 to-purple-500/20 flex items-center justify-center">
                            <i class="pi pi-image text-white/30 text-2xl"></i>
                          </div>
                          <div class="p-2">
                            <div class="h-3 bg-white/20 rounded w-3/4 mx-auto"></div>
                          </div>
                        </div>
                      </div>
                      
                      <!-- Grouped Expanded Grid -->
                      <div v-else-if="selectedGrouping === 'expanded'" class="space-y-4">
                        <div class="space-y-2">
                          <div class="h-3 bg-amber-400/50 rounded w-1/3"></div>
                          <div class="grid grid-cols-2 gap-2">
                            <div v-for="i in 2" :key="i" class="bg-white/10 rounded-lg overflow-hidden">
                              <div class="aspect-square bg-gradient-to-br from-blue-500/20 to-purple-500/20 flex items-center justify-center">
                                <i class="pi pi-image text-white/30 text-lg"></i>
                              </div>
                            </div>
                          </div>
                        </div>
                        <div class="space-y-2">
                          <div class="h-3 bg-amber-400/50 rounded w-1/4"></div>
                          <div class="grid grid-cols-2 gap-2">
                            <div v-for="i in 2" :key="i" class="bg-white/10 rounded-lg overflow-hidden">
                              <div class="aspect-square bg-gradient-to-br from-purple-500/20 to-pink-500/20 flex items-center justify-center">
                                <i class="pi pi-image text-white/30 text-lg"></i>
                              </div>
                            </div>
                          </div>
                        </div>
                      </div>
                      
                      <!-- Grouped Collapsed Grid (Categories only) -->
                      <div v-else class="space-y-3">
                        <div v-for="i in 3" :key="i" class="bg-white/10 rounded-xl p-4 flex items-center gap-3">
                          <div class="w-12 h-12 bg-gradient-to-br from-amber-500/30 to-orange-500/30 rounded-lg flex items-center justify-center">
                            <i class="pi pi-folder text-white/50"></i>
                          </div>
                          <div class="flex-1">
                            <div class="h-4 bg-white/20 rounded w-2/3 mb-1"></div>
                            <div class="h-2 bg-white/10 rounded w-1/3"></div>
                          </div>
                          <i class="pi pi-chevron-right text-white/30"></i>
                        </div>
                      </div>
                    </div>
                    
                    <!-- List Mode -->
                    <div v-else-if="selectedMode === 'list'" class="animate-fade-in">
                      <div class="h-5 bg-white/20 rounded w-2/3 mb-4"></div>
                      
                      <!-- Flat List -->
                      <div v-if="selectedGrouping === 'none'" class="space-y-3">
                        <div v-for="i in 5" :key="i" class="flex items-center gap-3 bg-white/10 rounded-xl p-3">
                          <div class="w-10 h-10 bg-gradient-to-br from-blue-500/30 to-purple-500/30 rounded-lg flex items-center justify-center">
                            <i class="pi pi-file text-white/50 text-sm"></i>
                          </div>
                          <div class="flex-1">
                            <div class="h-3 bg-white/20 rounded w-3/4 mb-1"></div>
                            <div class="h-2 bg-white/10 rounded w-1/2"></div>
                          </div>
                        </div>
                      </div>
                      
                      <!-- Grouped Expanded List -->
                      <div v-else-if="selectedGrouping === 'expanded'" class="space-y-4">
                        <div class="space-y-2">
                          <div class="h-3 bg-amber-400/50 rounded w-1/3"></div>
                          <div v-for="i in 2" :key="i" class="flex items-center gap-3 bg-white/10 rounded-lg p-2.5 ml-2">
                            <div class="w-8 h-8 bg-white/20 rounded-lg"></div>
                            <div class="flex-1">
                              <div class="h-3 bg-white/20 rounded w-3/4"></div>
                            </div>
                          </div>
                        </div>
                        <div class="space-y-2">
                          <div class="h-3 bg-amber-400/50 rounded w-1/4"></div>
                          <div v-for="i in 2" :key="i" class="flex items-center gap-3 bg-white/10 rounded-lg p-2.5 ml-2">
                            <div class="w-8 h-8 bg-white/20 rounded-lg"></div>
                            <div class="flex-1">
                              <div class="h-3 bg-white/20 rounded w-2/3"></div>
                            </div>
                          </div>
                        </div>
                      </div>
                      
                      <!-- Grouped Collapsed List (Categories only) -->
                      <div v-else class="space-y-3">
                        <div v-for="i in 4" :key="i" class="bg-white/10 rounded-xl p-4 flex items-center gap-3">
                          <div class="w-10 h-10 bg-gradient-to-br from-amber-500/30 to-orange-500/30 rounded-lg flex items-center justify-center">
                            <i class="pi pi-folder text-white/50 text-sm"></i>
                          </div>
                          <div class="flex-1">
                            <div class="h-4 bg-white/20 rounded w-1/2 mb-1"></div>
                            <div class="h-2 bg-white/10 rounded w-1/4"></div>
                          </div>
                          <i class="pi pi-chevron-right text-white/30 text-sm"></i>
                        </div>
                      </div>
                    </div>
                    
                    <!-- Cards Mode -->
                    <div v-else-if="selectedMode === 'cards'" class="animate-fade-in">
                      <div class="h-5 bg-white/20 rounded w-2/3 mb-4"></div>
                      
                      <!-- Flat Cards -->
                      <div v-if="selectedGrouping === 'none'" class="space-y-3">
                        <div v-for="i in 2" :key="i" class="bg-white/10 rounded-xl overflow-hidden">
                          <div class="aspect-[16/9] bg-gradient-to-br from-blue-500/20 to-purple-500/20 flex items-center justify-center">
                            <i class="pi pi-image text-white/30 text-2xl"></i>
                          </div>
                          <div class="p-3 space-y-2">
                            <div class="h-4 bg-white/20 rounded w-3/4"></div>
                            <div class="h-2 bg-white/10 rounded w-full"></div>
                          </div>
                        </div>
                      </div>
                      
                      <!-- Grouped Expanded Cards -->
                      <div v-else-if="selectedGrouping === 'expanded'" class="space-y-4">
                        <div class="space-y-2">
                          <div class="h-3 bg-amber-400/50 rounded w-1/3"></div>
                          <div class="bg-white/10 rounded-lg overflow-hidden">
                            <div class="aspect-[2/1] bg-gradient-to-br from-blue-500/20 to-purple-500/20 flex items-center justify-center">
                              <i class="pi pi-image text-white/30 text-xl"></i>
                            </div>
                            <div class="p-2">
                              <div class="h-3 bg-white/20 rounded w-2/3"></div>
                            </div>
                          </div>
                        </div>
                        <div class="space-y-2">
                          <div class="h-3 bg-amber-400/50 rounded w-1/4"></div>
                          <div class="bg-white/10 rounded-lg overflow-hidden">
                            <div class="aspect-[2/1] bg-gradient-to-br from-purple-500/20 to-pink-500/20 flex items-center justify-center">
                              <i class="pi pi-image text-white/30 text-xl"></i>
                            </div>
                            <div class="p-2">
                              <div class="h-3 bg-white/20 rounded w-1/2"></div>
                            </div>
                          </div>
                        </div>
                      </div>
                      
                      <!-- Grouped Collapsed Cards (Categories only) -->
                      <div v-else class="space-y-3">
                        <div v-for="i in 3" :key="i" class="bg-white/10 rounded-xl p-4 flex items-center gap-3">
                          <div class="w-14 h-14 bg-gradient-to-br from-amber-500/30 to-orange-500/30 rounded-lg flex items-center justify-center">
                            <i class="pi pi-folder text-white/50 text-lg"></i>
                          </div>
                          <div class="flex-1">
                            <div class="h-4 bg-white/20 rounded w-2/3 mb-1"></div>
                            <div class="h-2 bg-white/10 rounded w-1/2"></div>
                          </div>
                          <i class="pi pi-chevron-right text-white/30"></i>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
              
              <!-- Decorative glow -->
              <div class="absolute -inset-4 bg-gradient-to-r from-blue-500/20 to-purple-500/20 rounded-[3rem] blur-2xl -z-10"></div>
            </div>
          </div>
          
          <!-- Right: Mode Description -->
          <div class="animate-on-scroll" style="animation-delay: 200ms">
            <div class="bg-gradient-to-br from-slate-50 to-slate-100 rounded-3xl p-8 sm:p-10 border border-slate-200">
              <div class="flex items-center gap-4 mb-6">
                <div class="w-14 h-14 bg-gradient-to-br from-blue-600 to-purple-600 rounded-2xl flex items-center justify-center shadow-lg">
                  <i :class="`pi ${contentModes.find(m => m.key === selectedMode)?.icon} text-white text-2xl`"></i>
                </div>
                <div>
                  <h3 class="text-2xl font-bold text-slate-900">{{ $t(`landing.content_modes.${selectedMode}.name`) }}</h3>
                  <p class="text-slate-500">{{ $t(`landing.content_modes.${selectedMode}.desc`) }}</p>
                </div>
              </div>
              
              <div class="space-y-4">
                <div class="flex items-start gap-3">
                  <div class="w-8 h-8 bg-green-100 rounded-lg flex items-center justify-center flex-shrink-0 mt-0.5">
                    <i class="pi pi-check text-green-600"></i>
                  </div>
                  <div>
                    <h4 class="font-semibold text-slate-900 mb-1">{{ $t('landing.content_modes.best_for') || 'Best For' }}</h4>
                    <p class="text-slate-600">{{ $t(`landing.content_modes.${selectedMode}.use_case`) }}</p>
                  </div>
                </div>
                
                <div class="flex items-start gap-3">
                  <div class="w-8 h-8 bg-blue-100 rounded-lg flex items-center justify-center flex-shrink-0 mt-0.5">
                    <i class="pi pi-cog text-blue-600"></i>
                  </div>
                  <div>
                    <h4 class="font-semibold text-slate-900 mb-1">{{ $t('landing.content_modes.easy_setup') || 'Easy Setup' }}</h4>
                    <p class="text-slate-600">{{ $t('landing.content_modes.setup_desc') || 'Configure in seconds from the CMS dashboard. No coding required.' }}</p>
                  </div>
                </div>
                
                <div class="flex items-start gap-3">
                  <div class="w-8 h-8 bg-purple-100 rounded-lg flex items-center justify-center flex-shrink-0 mt-0.5">
                    <i class="pi pi-mobile text-purple-600"></i>
                  </div>
                  <div>
                    <h4 class="font-semibold text-slate-900 mb-1">{{ $t('landing.content_modes.mobile_optimized') || 'Mobile Optimized' }}</h4>
                    <p class="text-slate-600">{{ $t('landing.content_modes.mobile_desc') || 'Responsive design that looks perfect on any device.' }}</p>
                  </div>
                </div>
                
                <!-- Grouping Option (for Grid, List, Cards) -->
                <div v-if="currentModeSupportsGrouping" class="flex items-start gap-3">
                  <div class="w-8 h-8 rounded-lg flex items-center justify-center flex-shrink-0 mt-0.5"
                       :class="selectedGrouping !== 'none' ? 'bg-amber-100' : 'bg-slate-100'">
                    <i :class="selectedGrouping !== 'none' ? 'pi pi-folder text-amber-600' : 'pi pi-minus text-slate-400'"></i>
                  </div>
                  <div>
                    <h4 class="font-semibold text-slate-900 mb-1">
                      {{ selectedGrouping === 'none' ? $t('landing.content_modes.grouping_flat') : 
                         selectedGrouping === 'expanded' ? $t('landing.content_modes.grouping_expanded') : 
                         $t('landing.content_modes.grouping_collapsed') }}
                    </h4>
                    <p class="text-slate-600">
                      {{ selectedGrouping === 'none' ? $t('landing.content_modes.grouping_flat_desc') : 
                         selectedGrouping === 'expanded' ? $t('landing.content_modes.grouping_expanded_desc') : 
                         $t('landing.content_modes.grouping_collapsed_desc') }}
                    </p>
                  </div>
                </div>
                
                <!-- AI Assistant Context -->
                <div class="mt-6 pt-6 border-t border-slate-200">
                  <h4 class="font-semibold text-slate-900 mb-3 flex items-center gap-2">
                    <i class="pi pi-sparkles text-blue-600"></i>
                    {{ $t('landing.content_modes.ai_context_label') || 'AI Assistant Context' }}
                  </h4>
                  
                  <!-- Single Mode: One unified AI assistant -->
                  <div v-if="selectedMode === 'single'" class="space-y-2">
                    <div class="bg-gradient-to-r from-blue-50 to-purple-50 rounded-lg p-4 border border-blue-200">
                      <div class="flex items-center gap-2 mb-2">
                        <div class="w-6 h-6 bg-gradient-to-br from-blue-600 to-purple-600 rounded-lg flex items-center justify-center">
                          <i class="pi pi-sparkles text-white text-xs"></i>
                        </div>
                        <span class="text-sm font-semibold text-slate-800">{{ $t('landing.content_modes.ai_assistant') || 'AI Assistant' }}</span>
                      </div>
                      <p class="text-sm text-slate-600">{{ $t(`landing.content_modes.${selectedMode}.ai_single`) }}</p>
                      <p class="text-xs text-slate-500 mt-2 italic">{{ $t(`landing.content_modes.${selectedMode}.ai_note`) }}</p>
                    </div>
                  </div>
                  
                  <!-- Other Modes: Dual AI assistants -->
                  <div v-else class="space-y-3">
                    <div class="bg-white rounded-lg p-3 border border-blue-100">
                      <div class="flex items-center gap-2 mb-1">
                        <div class="w-5 h-5 bg-gradient-to-br from-blue-600 to-purple-600 rounded flex items-center justify-center">
                          <i class="pi pi-comments text-white text-xs"></i>
                        </div>
                        <span class="text-sm font-medium text-blue-800">{{ $t('landing.content_modes.ai_general_label') || 'General Assistant' }}</span>
                      </div>
                      <p class="text-xs text-slate-600 ml-7">{{ $t(`landing.content_modes.${selectedMode}.ai_general`) }}</p>
                    </div>
                    <div class="bg-white rounded-lg p-3 border border-emerald-100">
                      <div class="flex items-center gap-2 mb-1">
                        <div class="w-5 h-5 bg-gradient-to-br from-emerald-500 to-teal-500 rounded flex items-center justify-center">
                          <i class="pi pi-info-circle text-white text-xs"></i>
                        </div>
                        <span class="text-sm font-medium text-emerald-800">{{ $t('landing.content_modes.ai_item_label') || 'Item Assistant' }}</span>
                      </div>
                      <p class="text-xs text-slate-600 ml-7">{{ $t(`landing.content_modes.${selectedMode}.ai_item`) }}</p>
                    </div>
                  </div>
                </div>
              </div>
              
              <button 
                @click="handleGetStarted"
                class="mt-8 w-full flex items-center justify-center gap-2 bg-gradient-to-r from-blue-600 to-purple-600 hover:from-blue-700 hover:to-purple-700 text-white py-4 text-base font-bold rounded-xl shadow-lg hover:shadow-xl transition-all duration-300 cursor-pointer"
              >
                <span>{{ $t('landing.hero.cta_start') }}</span>
                <i class="pi pi-arrow-right"></i>
              </button>
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
      
      <div class="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8 relative">
        <div class="text-center mb-12 sm:mb-16">
          <h2 class="text-3xl sm:text-4xl md:text-5xl lg:text-6xl font-black text-white mb-4 sm:mb-6">
            {{ $t('landing.pricing.title') }} <span class="bg-gradient-to-r from-blue-400 via-cyan-400 to-emerald-400 bg-clip-text text-transparent">{{ $t('landing.pricing.title_highlight') }}</span>
          </h2>
          <p class="text-lg sm:text-xl text-blue-100/80 max-w-3xl mx-auto px-2">
            {{ $t('landing.pricing.subtitle') }}
          </p>
        </div>

        <!-- Subscription Tiers -->
        <div class="grid lg:grid-cols-2 gap-6 lg:gap-8 mb-12 max-w-4xl mx-auto">
          <!-- Free Tier -->
          <div class="bg-gradient-to-br from-slate-500/10 to-slate-600/10 backdrop-blur-xl rounded-3xl border border-slate-400/30 overflow-hidden hover:border-slate-400/50 transition-all duration-300">
            <div class="bg-gradient-to-r from-slate-600/20 to-slate-700/20 p-6 border-b border-white/10">
              <div class="flex items-center gap-3 mb-4">
                <div class="w-10 h-10 bg-gradient-to-br from-slate-500 to-slate-600 rounded-xl flex items-center justify-center">
                  <i class="pi pi-user text-white text-lg"></i>
                </div>
                <h3 class="text-xl font-bold text-white">{{ $t('landing.pricing.free_tier.title') }}</h3>
              </div>
              <div class="flex items-baseline gap-2">
                <span class="text-5xl font-black text-white">{{ $t('landing.pricing.free_tier.price') }}</span>
                <span class="text-xl text-slate-300">{{ $t('landing.pricing.free_tier.per') }}</span>
              </div>
              <p class="text-slate-300 mt-2 text-sm">{{ $t('landing.pricing.free_tier.desc') }}</p>
            </div>
            <div class="p-6">
              <ul class="space-y-3 mb-6">
                <li v-for="(feature, idx) in freeTierFeatures" :key="idx" class="flex items-center gap-3 text-slate-100">
                  <div class="w-5 h-5 bg-slate-500/20 rounded-full flex items-center justify-center flex-shrink-0">
                    <i class="pi pi-check text-slate-400 text-xs"></i>
                  </div>
                  <span class="text-sm">{{ feature }}</span>
                </li>
              </ul>
              <button
                @click="handleGetStarted"
                class="w-full py-3 px-6 bg-white/10 hover:bg-white/20 border border-white/20 text-white font-semibold rounded-xl transition-all duration-300"
              >
                {{ $t('landing.pricing.free_tier.cta') }}
              </button>
            </div>
          </div>

          <!-- Premium Tier -->
          <div class="bg-gradient-to-br from-blue-500/10 to-purple-500/10 backdrop-blur-xl rounded-3xl border-2 border-blue-400/50 overflow-hidden hover:border-blue-400/70 transition-all duration-300 relative">
            <!-- Popular Badge -->
            <div class="absolute top-4 right-4 bg-gradient-to-r from-blue-500 to-purple-500 text-white text-xs font-bold px-3 py-1 rounded-full shadow-lg">
              {{ $t('landing.pricing.premium_tier.popular') }}
            </div>
            <div class="bg-gradient-to-r from-blue-600/20 to-purple-600/20 p-6 border-b border-white/10">
              <div class="flex items-center gap-3 mb-4">
                <div class="w-10 h-10 bg-gradient-to-br from-blue-500 to-purple-500 rounded-xl flex items-center justify-center">
                  <i class="pi pi-star text-white text-lg"></i>
                </div>
                <h3 class="text-xl font-bold text-white">{{ $t('landing.pricing.premium_tier.title') }}</h3>
              </div>
              <div class="flex items-baseline gap-2">
                <span class="text-5xl font-black text-white">{{ $t('landing.pricing.premium_tier.price') }}</span>
                <span class="text-xl text-blue-200">{{ $t('landing.pricing.premium_tier.per') }}</span>
              </div>
              <p class="text-blue-200 mt-2 text-sm">{{ $t('landing.pricing.premium_tier.desc') }}</p>
            </div>
            <div class="p-6">
              <ul class="space-y-3 mb-6">
                <li v-for="(feature, idx) in premiumTierFeatures" :key="idx" class="flex items-center gap-3 text-blue-100">
                  <div class="w-5 h-5 bg-blue-500/20 rounded-full flex items-center justify-center flex-shrink-0">
                    <i class="pi pi-check text-blue-400 text-xs"></i>
                  </div>
                  <span class="text-sm">{{ feature }}</span>
                </li>
              </ul>
              <button
                @click="handleGetStarted"
                class="w-full py-3 px-6 bg-gradient-to-r from-blue-600 to-purple-600 hover:from-blue-700 hover:to-purple-700 text-white font-semibold rounded-xl shadow-lg hover:shadow-xl transition-all duration-300"
              >
                {{ $t('landing.pricing.premium_tier.cta') }}
              </button>
            </div>
          </div>
        </div>

        <!-- Physical Cards Add-on -->
        <div class="bg-gradient-to-br from-amber-500/10 to-orange-500/10 backdrop-blur-xl rounded-3xl border border-amber-400/30 p-6 sm:p-8 mb-8 max-w-4xl mx-auto">
          <div class="flex flex-col sm:flex-row items-start sm:items-center gap-6">
            <div class="flex items-center gap-4">
              <div class="w-14 h-14 bg-gradient-to-br from-amber-500 to-orange-500 rounded-2xl flex items-center justify-center shadow-lg">
                <i class="pi pi-id-card text-white text-2xl"></i>
              </div>
              <div>
                <div class="flex items-center gap-2">
                  <h3 class="text-xl font-bold text-white">{{ $t('landing.pricing.physical_cards.title') }}</h3>
                  <span class="text-xs bg-amber-500/20 text-amber-300 px-2 py-0.5 rounded-full">{{ $t('landing.pricing.physical_cards.subtitle') }}</span>
                </div>
                <p class="text-amber-200 text-sm mt-1">{{ $t('landing.pricing.physical_cards.desc') }}</p>
              </div>
            </div>
            <div class="flex items-baseline gap-2 sm:ml-auto">
              <span class="text-4xl font-black text-white">{{ $t('landing.pricing.physical_cards.price') }}</span>
              <span class="text-lg text-amber-200">{{ $t('landing.pricing.physical_cards.per') }}</span>
            </div>
          </div>
          <div class="grid sm:grid-cols-2 lg:grid-cols-4 gap-3 mt-6">
            <div v-for="(feature, idx) in physicalCardFeatures" :key="idx" class="flex items-center gap-2 text-amber-100 text-sm">
              <i class="pi pi-check text-amber-400 text-xs"></i>
              <span>{{ feature }}</span>
            </div>
          </div>
        </div>

        <!-- Everything Included Section -->
        <div class="bg-white/5 backdrop-blur-xl rounded-3xl border border-white/10 p-6 sm:p-8 mb-8 max-w-4xl mx-auto">
          <h3 class="text-2xl font-bold text-white mb-6 text-center">{{ $t('landing.pricing.included_title') }}</h3>
          <div class="grid sm:grid-cols-2 lg:grid-cols-4 gap-4">
            <div v-for="feature in pricingFeatures" :key="feature" class="flex items-center gap-3 text-blue-100">
              <div class="w-6 h-6 bg-emerald-500/20 rounded-full flex items-center justify-center flex-shrink-0">
                <i class="pi pi-check text-emerald-400 text-sm"></i>
              </div>
              <span class="text-sm">{{ feature }}</span>
            </div>
          </div>
        </div>

        <div class="text-center px-4">
          <Button 
            @click="handleGetStarted"
            class="bg-gradient-to-r from-blue-600 to-purple-600 hover:from-blue-700 hover:to-purple-700 text-white border-0 px-8 sm:px-10 py-4 sm:py-5 text-base sm:text-lg font-bold shadow-2xl hover:shadow-blue-500/25 transition-all transform hover:scale-105 rounded-xl min-h-[56px]"
          >
            {{ $t('landing.pricing.cta') }}
          </Button>
          <p class="text-blue-300 text-sm mt-4">{{ $t('landing.pricing.footer_text') }}</p>
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
          <div v-for="(faq, index) in faqs.slice(0, 6)" :key="index"
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

    <!-- Footer -->
    <footer class="bg-slate-900 text-white py-16">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div class="grid md:grid-cols-3 gap-12 mb-12">
          <!-- Brand -->
          <div>
            <div class="flex items-center gap-3 mb-4">
              <div class="w-10 h-10 bg-gradient-to-br from-blue-600 to-purple-600 rounded-xl flex items-center justify-center">
                <i class="pi pi-qrcode text-white text-xl"></i>
              </div>
              <span class="text-xl font-bold bg-gradient-to-r from-blue-400 to-purple-400 bg-clip-text text-transparent">ExperienceQR</span>
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
              <li><a @click="scrollToSection('demo-templates')" class="text-slate-400 hover:text-white transition-colors cursor-pointer">{{ $t('landing.footer.demo') }}</a></li>
              <li><a @click="scrollToSection('pricing')" class="text-slate-400 hover:text-white transition-colors cursor-pointer">{{ $t('landing.footer.pricing') }}</a></li>
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

    <!-- Floating CTA Button -->
    <transition name="fade-up">
      <div v-if="showFloatingCta" class="fixed bottom-6 right-6 z-50 hidden sm:block lg:hidden">
        <button 
          @click="handleGetStarted"
          class="flex items-center gap-3 bg-gradient-to-r from-blue-600 to-purple-600 hover:from-blue-700 hover:to-purple-700 text-white px-6 py-4 rounded-full shadow-2xl hover:shadow-blue-500/50 transition-all duration-300 transform hover:scale-105 font-bold text-lg border border-white/20 backdrop-blur-sm"
        >
          <span>{{ $t('landing.nav.get_started') }}</span>
          <i class="pi pi-arrow-right"></i>
        </button>
      </div>
    </transition>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted, nextTick, watch } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { useI18n } from 'vue-i18n'
import { useAuthStore } from '@/stores/auth'
import { useSEO } from '@/composables/useSEO'
import { supabase } from '@/lib/supabase'
import Button from 'primevue/button'
import ProgressSpinner from 'primevue/progressspinner'
import QrCode from 'qrcode.vue'
import { getCardAspectRatio } from '@/utils/cardConfig'
import UnifiedHeader from '@/components/Layout/UnifiedHeader.vue'
import PhoneSimulator from '@/components/common/PhoneSimulator.vue'

const router = useRouter()
const route = useRoute()
const authStore = useAuthStore()
const { updateSEO } = useSEO()

// Navigation state
const showFloatingCta = ref(false)

// Demo Templates state
const demoTemplates = ref([])
const isLoadingTemplates = ref(false)
const currentTemplatePage = ref(0)
const templatesPerPage = 6  // 3 columns x 2 rows
const selectedVenueType = ref(null)
const selectedTemplate = ref(null) // Template shown in phone preview
const iframeLoading = ref(false) // Loading state for phone preview iframe
const iframeError = ref(false) // Error state for phone preview iframe
const iframeLoadTimeout = ref(null) // Timeout ref for loading

// Responsive phone simulator width
const windowWidth = ref(typeof window !== 'undefined' ? window.innerWidth : 1024)
const phoneSimulatorWidth = computed(() => {
  if (windowWidth.value < 380) return 240
  if (windowWidth.value < 480) return 260
  if (windowWidth.value < 640) return 280
  return 320
})

// Update window width on resize
const updateWindowWidth = () => {
  windowWidth.value = window.innerWidth
}

// Venue filter scroll indicators (mobile)
const venueFilterScroll = ref(null)
const canScrollLeft = ref(false)
const canScrollRight = ref(true)

const updateScrollIndicators = () => {
  if (!venueFilterScroll.value) return
  const el = venueFilterScroll.value
  canScrollLeft.value = el.scrollLeft > 10
  canScrollRight.value = el.scrollLeft < el.scrollWidth - el.clientWidth - 10
}

// Extract unique venue types from templates
const availableVenueTypes = computed(() => {
  const types = new Set()
  demoTemplates.value.forEach(t => {
    if (t.venue_type) types.add(t.venue_type)
  })
  return Array.from(types).sort()
})

// Filter templates by selected venue type
const filteredTemplates = computed(() => {
  if (!selectedVenueType.value) return demoTemplates.value
  return demoTemplates.value.filter(t => t.venue_type === selectedVenueType.value)
})

// Pagination computed properties (now based on filtered templates)
const totalTemplatePages = computed(() => Math.ceil(filteredTemplates.value.length / templatesPerPage))
const paginatedTemplates = computed(() => {
  const start = currentTemplatePage.value * templatesPerPage
  return filteredTemplates.value.slice(start, start + templatesPerPage)
})

// No scroll needed - minimum height on grid prevents layout jump

// Select venue type and reset pagination
const selectVenueType = (type) => {
  selectedVenueType.value = type
  currentTemplatePage.value = 0
  // Auto-select first template of filtered results
  nextTick(() => {
    if (filteredTemplates.value.length > 0) {
      selectTemplateForPreview(filteredTemplates.value[0])
    }
  })
}

// Select template for phone preview
const selectTemplateForPreview = (template) => {
  if (selectedTemplate.value?.id !== template.id) {
    // Clear any existing timeout
    if (iframeLoadTimeout.value) {
      clearTimeout(iframeLoadTimeout.value)
    }
    iframeLoading.value = true // Show loading spinner when switching templates
    iframeError.value = false // Reset error state
    
    // Set a timeout to stop loading after 15 seconds
    iframeLoadTimeout.value = setTimeout(() => {
      if (iframeLoading.value) {
        iframeLoading.value = false
        iframeError.value = true
      }
    }, 15000)
  }
  selectedTemplate.value = template
}

// Iframe load handlers
const handleIframeLoad = () => {
  if (iframeLoadTimeout.value) {
    clearTimeout(iframeLoadTimeout.value)
  }
  iframeLoading.value = false
  iframeError.value = false
}

const handleIframeError = () => {
  if (iframeLoadTimeout.value) {
    clearTimeout(iframeLoadTimeout.value)
  }
  iframeLoading.value = false
  iframeError.value = true
}

const retryIframeLoad = () => {
  if (selectedTemplate.value) {
    iframeError.value = false
    iframeLoading.value = true
    // Force iframe reload by temporarily clearing and re-setting the template
    const template = selectedTemplate.value
    selectedTemplate.value = null
    setTimeout(() => {
      selectTemplateForPreview(template)
    }, 100)
  }
}

// Pagination functions
const nextTemplatePage = () => {
  if (currentTemplatePage.value < totalTemplatePages.value - 1) {
    currentTemplatePage.value++
  }
}

const prevTemplatePage = () => {
  if (currentTemplatePage.value > 0) {
    currentTemplatePage.value--
  }
}

// Demo mode toggle (physical card vs digital access) - defaults to digital
const demoMode = ref('digital')

// Physical Card Demo configuration
const demoCardTitle = import.meta.env.VITE_DEMO_CARD_TITLE || 'Museum'
const demoCardSubtitle = import.meta.env.VITE_DEMO_CARD_SUBTITLE || 'Scan to explore the exhibits\nActivate your interactive AI guide\nAvailable in multiple languages'
const demoCardImageUrl = import.meta.env.VITE_DEFAULT_CARD_IMAGE_URL || '/Image/DemoCard.jpg'
const demoCardUrl = import.meta.env.VITE_SAMPLE_QR_URL || ''
const cardAspectRatio = computed(() => getCardAspectRatio())

// Digital Access Demo configuration
const digitalAccessDemoTitle = import.meta.env.VITE_DIGITAL_ACCESS_DEMO_TITLE || 'Digital Menu'
const digitalAccessDemoSubtitle = import.meta.env.VITE_DIGITAL_ACCESS_DEMO_SUBTITLE || 'Scan for instant access'
const digitalAccessDemoUrl = import.meta.env.VITE_DIGITAL_ACCESS_DEMO_URL || ''

// Open demo URLs
const openDemoUrl = (url) => {
  if (url) {
    window.open(url, '_blank', 'noopener,noreferrer')
  }
}

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

// Content Modes showcase
const selectedMode = ref('list')
const selectedGrouping = ref('none') // 'none', 'expanded', 'collapsed'
const contentModes = [
  { key: 'single', icon: 'pi-file', supportsGrouping: false },
  { key: 'grid', icon: 'pi-th-large', supportsGrouping: true },
  { key: 'list', icon: 'pi-list', supportsGrouping: true },
  { key: 'cards', icon: 'pi-clone', supportsGrouping: true }
]

// Reset grouping when switching to a mode that doesn't support it
const selectMode = (modeKey) => {
  selectedMode.value = modeKey
  const mode = contentModes.find(m => m.key === modeKey)
  if (!mode?.supportsGrouping) {
    selectedGrouping.value = 'none'
  }
}

const currentModeSupportsGrouping = computed(() => {
  const mode = contentModes.find(m => m.key === selectedMode.value)
  return mode?.supportsGrouping ?? false
})

// Get i18n for locale watching
const { t, tm, locale } = useI18n()

// Scroll handling (reserved for future use)

// Intersection Observer for animations
let animationObserver = null

const checkElementVisibility = (element) => {
  const rect = element.getBoundingClientRect()
  return (
    rect.top >= 0 &&
    rect.left >= 0 &&
    rect.bottom <= (window.innerHeight || document.documentElement.clientHeight) + 100 &&
    rect.right <= (window.innerWidth || document.documentElement.clientWidth)
  )
}

const initAnimations = () => {
  // Disconnect existing observer if any
  if (animationObserver) {
    animationObserver.disconnect()
  }
  
  // Create new observer
  animationObserver = new IntersectionObserver((entries) => {
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
  
  // Check which elements are already in viewport and mark them visible immediately
  animateElements.forEach(el => {
    if (checkElementVisibility(el)) {
      // Element is already visible, show it immediately
      el.classList.add('animate-visible')
    }
    
    // Observe for future scroll-triggered animations
    animationObserver.observe(el)
  })
  
  // Add animation-ready class after checking initial visibility
  document.documentElement.classList.add('js-animations-ready')
}

const handleScroll = () => {
  showFloatingCta.value = window.scrollY > 600
}

onMounted(() => {
  // Initialize SEO
  updateSEO()
  
  // Fetch demo templates
  fetchDemoTemplates()
  
  // Responsive phone width listener
  window.addEventListener('resize', updateWindowWidth)
  
  // Scroll listener
  window.addEventListener('scroll', handleScroll)

  // Initialize animations on mount
  nextTick(() => {
    setTimeout(() => {
      initAnimations()
    }, 50)
  })

  // Handle hash navigation (e.g., /#demo, /#features, /#pricing)
  if (route.hash) {
    const sectionId = route.hash.replace('#', '')
    nextTick(() => {
      setTimeout(() => {
        scrollToSection(sectionId)
      }, 100)
    })
  }

  // Load Vimeo Player API
  const vimeoScript = document.createElement('script')
  vimeoScript.src = "https://player.vimeo.com/api/player.js"
  vimeoScript.async = true
  document.body.appendChild(vimeoScript)
})

onUnmounted(() => {
  window.removeEventListener('scroll', handleScroll)
  window.removeEventListener('resize', updateWindowWidth)
})

// Re-initialize animations and refetch templates when language changes
watch(locale, () => {
  // Refetch demo templates in the new language
  fetchDemoTemplates()
  
  // Wait for DOM to update with new language content
  nextTick(() => {
    setTimeout(() => {
      // Remove animate-visible from all elements to reset
      const animateElements = document.querySelectorAll('.animate-on-scroll')
      animateElements.forEach(el => {
        el.classList.remove('animate-visible')
      })
      
      // Re-initialize animations
      initAnimations()
  }, 100)
  })
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
}


const handleGetStarted = () => {
  if (authStore.isLoggedIn()) {
    router.push('/cms')
  } else {
    router.push('/login')
  }
}

// Demo Templates functions
const fetchDemoTemplates = async () => {
  isLoadingTemplates.value = true
  try {
    // Try with language parameter first for multilingual support
    let { data, error } = await supabase.rpc('get_demo_templates', { 
      p_limit: 100,
      p_language: locale.value
    })
    
    // If stored procedure doesn't support p_language yet, fall back to no language
    if (error && error.message?.includes('p_language')) {
      console.warn('get_demo_templates does not support p_language yet, falling back')
      const result = await supabase.rpc('get_demo_templates', { p_limit: 100 })
      data = result.data
      error = result.error
    }
    
    if (error) {
      console.error('Error fetching demo templates:', error)
      return
    }
    demoTemplates.value = data || []
    currentTemplatePage.value = 0  // Reset to first page
    // Auto-select first template for phone preview
    if (data && data.length > 0) {
      selectTemplateForPreview(data[0])
    }
  } catch (err) {
    console.error('Failed to fetch demo templates:', err)
  } finally {
    isLoadingTemplates.value = false
    // Initialize scroll indicators after templates load
    nextTick(() => updateScrollIndicators())
  }
}

const getTemplateUrl = (template) => {
  if (!template.access_url) return ''
  return `${window.location.origin}/c/${template.access_url}`
}

const openTemplate = (template) => {
  if (template.access_url) {
    window.location.href = getTemplateUrl(template)
  }
}

const getVenueIcon = (venueType) => {
  const icons = {
    'cultural': 'pi pi-building',
    'food': 'pi pi-star',
    'events': 'pi pi-calendar',
    'hospitality': 'pi pi-heart',
    'retail': 'pi pi-shopping-bag',
    'tours': 'pi pi-map',
    'general': 'pi pi-box'
  }
  return icons[venueType] || 'pi pi-tag'
}

const formatVenueType = (type) => {
  if (!type) return ''
  // Use i18n translations for venue types
  const key = `landing.demo_templates.venue_types.${type}`
  const translated = t(key)
  // Fall back to formatted type name if translation key doesn't exist
  if (translated === key) {
    return type.charAt(0).toUpperCase() + type.slice(1).replace(/_/g, ' ')
  }
  return translated
}

// Data (t and locale already declared above for locale watching)

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
    icon: 'pi-pencil',
    title: t('landing.how_it_works.steps.create_title'),
    description: t('landing.how_it_works.steps.create_desc')
  },
  {
    icon: 'pi-qrcode',
    title: t('landing.how_it_works.steps.share_title'),
    description: t('landing.how_it_works.steps.share_desc')
  },
  {
    icon: 'pi-comments',
    title: t('landing.how_it_works.steps.engage_title'),
    description: t('landing.how_it_works.steps.engage_desc')
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
    icon: 'pi-cog',
    title: t('landing.features.features.portal_config_title'),
    description: t('landing.features.features.portal_config_desc')
  },
  {
    icon: 'pi-globe',
    title: t('landing.features.features.multilingual_title'),
    description: t('landing.features.features.multilingual_desc')
  }
])

const pricingFeatures = computed(() => [
  t('landing.pricing.features.ai_voice'),
  t('landing.pricing.features.qr_access'),
  t('landing.pricing.features.design_dashboard'),
  t('landing.pricing.features.content_management'),
  t('landing.pricing.features.analytics'),
  t('landing.pricing.features.qr_generation'),
  t('landing.pricing.features.cloud_hosting'),
  t('landing.pricing.features.support')
])

const freeTierFeatures = computed(() => {
  const features = tm('landing.pricing.free_tier.features')
  return Array.isArray(features) ? features : []
})

const premiumTierFeatures = computed(() => {
  const features = tm('landing.pricing.premium_tier.features')
  return Array.isArray(features) ? features : []
})

const physicalCardFeatures = computed(() => {
  const features = tm('landing.pricing.physical_cards.features')
  return Array.isArray(features) ? features : []
})

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

/* Fade Up Transition for Floating CTA */
.fade-up-enter-active,
.fade-up-leave-active {
  transition: all 0.5s cubic-bezier(0.4, 0, 0.2, 1);
}

.fade-up-enter-from,
.fade-up-leave-to {
  opacity: 0;
  transform: translateY(20px) scale(0.95);
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

/* Content Modes Section */
.scrollbar-hide {
  -ms-overflow-style: none;
  scrollbar-width: none;
}

.scrollbar-hide::-webkit-scrollbar {
  display: none;
}

/* Fade in animation for mode switching */
.animate-fade-in {
  animation: fadeIn 0.3s ease-out;
}

@keyframes fadeIn {
  from {
    opacity: 0;
    transform: translateY(10px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

/* Hover scale for tabs */
.hover\:scale-102:hover {
  transform: scale(1.02);
}

/* Phone Simulator Content Styles */
.simulator-content {
  position: relative;
  width: 100%;
  height: 100%;
  background: white;
  overflow: hidden;
  border-radius: inherit;
}

.simulator-iframe-wrapper {
  position: absolute;
  inset: 0;
  overflow: hidden;
  z-index: 1;
}

.simulator-iframe {
  position: absolute;
  top: 50%;
  left: 50%;
  width: 375px;
  height: 812px;
  border: none;
  background: white;
  transform-origin: center center;
}

.simulator-placeholder {
  position: absolute;
  inset: 0;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  background: linear-gradient(135deg, #1e293b, #0f172a);
  text-align: center;
  padding: 1rem;
}

.simulator-placeholder.light {
  background: linear-gradient(135deg, #f8fafc, #f1f5f9);
}

.simulator-loading {
  position: absolute;
  inset: 0;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  background: linear-gradient(135deg, #1e293b, #0f172a);
  z-index: 10;
}

.simulator-loading.light {
  background: linear-gradient(135deg, #f8fafc, #f1f5f9);
}

/* Demo Template List */
.demo-template-list {
  scrollbar-width: thin;
  scrollbar-color: #cbd5e1 transparent;
}

.demo-template-list::-webkit-scrollbar {
  width: 6px;
}

.demo-template-list::-webkit-scrollbar-track {
  background: transparent;
}

.demo-template-list::-webkit-scrollbar-thumb {
  background: #cbd5e1;
  border-radius: 3px;
}

.demo-template-list::-webkit-scrollbar-thumb:hover {
  background: #94a3b8;
}
</style>
