<template>
  <div class="min-h-screen bg-white">
    <!-- Scroll Progress Bar -->
    <div class="fixed top-0 left-0 right-0 h-1 bg-gray-200 z-[60]">
      <div class="h-full bg-gradient-to-r from-blue-600 to-purple-600 transition-all duration-300 ease-out"
           :style="{ width: scrollProgress + '%' }"></div>
          </div>
          
    <!-- Premium Navigation Bar -->
    <nav class="fixed top-0 left-0 right-0 z-50 transition-all duration-300"
         :class="scrolled ? 'bg-white/95 backdrop-blur-xl shadow-lg border-b border-slate-200' : 'bg-white/80 backdrop-blur-md border-b border-white/20'">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div class="flex justify-between items-center h-20">
          <!-- Logo -->
          <div class="flex items-center gap-3 cursor-pointer" @click="router.push('/')">
            <div class="w-11 h-11 bg-gradient-to-br from-blue-600 to-purple-600 rounded-xl flex items-center justify-center shadow-lg transform hover:scale-105 transition-transform">
              <i class="pi pi-id-card text-white text-xl"></i>
              </div>
            <div>
              <div class="text-xl font-bold bg-gradient-to-r from-blue-600 to-purple-600 bg-clip-text text-transparent">CardStudio</div>
              <div class="text-[10px] text-slate-500 -mt-1 hidden sm:block">AI-Powered Souvenirs</div>
              </div>
            </div>

          <!-- Desktop Navigation - Shows at lg (1024px) and above -->
          <div class="hidden lg:flex items-center gap-10">
            <a @click="scrollToAbout" class="text-slate-600 hover:text-blue-600 font-medium cursor-pointer transition-all hover:scale-105">
              About
            </a>
            <a @click="scrollToDemo" class="text-slate-600 hover:text-blue-600 font-medium cursor-pointer transition-all hover:scale-105">
              Demo
            </a>
            <a @click="scrollToPricing" class="text-slate-600 hover:text-blue-600 font-medium cursor-pointer transition-all hover:scale-105">
              Pricing
            </a>
            <a @click="scrollToContact" class="text-slate-600 hover:text-blue-600 font-medium cursor-pointer transition-all hover:scale-105">
              Contact
            </a>
              </div>

          <!-- CTA Buttons & Mobile Menu Toggle -->
          <div class="flex items-center gap-3">
            <!-- Sign In - Shows at lg (1024px) and above -->
            <Button 
              @click="router.push('/login')"
              class="hidden lg:inline-flex text-slate-700 hover:text-blue-600 border-0 bg-transparent font-semibold transition-colors"
            >
              Sign In
            </Button>
            
            <!-- Start Free Trial - Always visible -->
            <Button 
              @click="router.push('/signup')"
              class="bg-gradient-to-r from-blue-600 to-purple-600 hover:from-blue-700 hover:to-purple-700 text-white border-0 px-6 py-2.5 font-semibold shadow-lg hover:shadow-xl transition-all transform hover:scale-105"
            >
              <span class="hidden sm:inline">Start Free Trial</span>
              <span class="sm:hidden">Start Free</span>
            </Button>

            <!-- Mobile Menu Button - Shows ONLY when nav links are hidden (below lg/1024px) -->
            <Button 
              icon="pi pi-bars"
              @click="mobileMenuOpen = !mobileMenuOpen"
              class="p-button-text text-slate-700 hover:text-blue-600 block lg:!hidden"
            />
              </div>
            </div>
              </div>
    </nav>

    <!-- Mobile Menu -->
    <transition name="slide-down">
      <div v-if="mobileMenuOpen" class="fixed top-20 left-0 right-0 bg-white backdrop-blur-xl border-b border-slate-200 shadow-xl z-40 lg:hidden">
        <div class="px-6 py-6 space-y-1">
          <a @click="scrollToAbout; mobileMenuOpen = false" 
             class="block text-slate-700 hover:text-white hover:bg-gradient-to-r hover:from-blue-600 hover:to-purple-600 font-medium py-3 px-4 rounded-xl transition-all cursor-pointer">
            About
          </a>
          <a @click="scrollToDemo; mobileMenuOpen = false" 
             class="block text-slate-700 hover:text-white hover:bg-gradient-to-r hover:from-blue-600 hover:to-purple-600 font-medium py-3 px-4 rounded-xl transition-all cursor-pointer">
            Demo
          </a>
          <a @click="scrollToPricing; mobileMenuOpen = false" 
             class="block text-slate-700 hover:text-white hover:bg-gradient-to-r hover:from-blue-600 hover:to-purple-600 font-medium py-3 px-4 rounded-xl transition-all cursor-pointer">
            Pricing
          </a>
          <a @click="scrollToContact; mobileMenuOpen = false" 
             class="block text-slate-700 hover:text-white hover:bg-gradient-to-r hover:from-blue-600 hover:to-purple-600 font-medium py-3 px-4 rounded-xl transition-all cursor-pointer">
            Contact
          </a>
          
          <div class="pt-4 space-y-3">
            <Button 
              @click="router.push('/login'); mobileMenuOpen = false"
              class="w-full bg-slate-100 text-slate-700 hover:bg-slate-200 border-0 py-3 font-semibold rounded-xl"
            >
              Sign In
            </Button>
            <Button 
              @click="router.push('/signup'); mobileMenuOpen = false"
              class="w-full bg-gradient-to-r from-blue-600 to-purple-600 hover:from-blue-700 hover:to-purple-700 text-white border-0 py-3 font-semibold shadow-lg rounded-xl"
            >
              Start Free Trial
            </Button>
              </div>
            </div>
          </div>
    </transition>
    
    <!-- Hero Section - Premium Design -->
    <section class="relative min-h-screen flex items-center justify-center overflow-hidden bg-gradient-to-br from-slate-950 via-blue-950 to-purple-950 pt-20">
      <!-- Animated gradient mesh background -->
      <div class="absolute inset-0">
        <div class="absolute inset-0 bg-[radial-gradient(ellipse_at_top,rgba(120,180,255,0.15),transparent_50%)]"></div>
        <div class="absolute inset-0 bg-[radial-gradient(ellipse_at_bottom_right,rgba(180,120,255,0.15),transparent_50%)]"></div>
        <div class="absolute inset-0 bg-[radial-gradient(ellipse_at_bottom_left,rgba(255,120,180,0.1),transparent_50%)]"></div>
        </div>

      <!-- Floating orbs with better animation -->
      <div class="absolute inset-0 overflow-hidden">
        <div class="floating-orb absolute top-20 left-10 w-72 h-72 bg-blue-500/20 rounded-full blur-3xl"></div>
        <div class="floating-orb-delayed absolute bottom-20 right-10 w-96 h-96 bg-purple-500/20 rounded-full blur-3xl"></div>
        <div class="floating-orb-slow absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[40rem] h-[40rem] bg-cyan-500/10 rounded-full blur-3xl"></div>
          </div>
          
      <!-- Grid pattern overlay -->
      <div class="absolute inset-0 bg-[url('/grid.svg')] bg-center opacity-20"></div>
      
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-20 relative z-10">
        <div class="text-center">
          <!-- Premium badge -->
          <div class="inline-flex items-center gap-2 bg-white/10 backdrop-blur-xl border border-white/20 text-white px-4 py-2 rounded-full text-sm font-medium mb-8 animate-fade-in">
            <div class="w-2 h-2 bg-gradient-to-r from-green-400 to-emerald-400 rounded-full animate-pulse"></div>
            <span>Trusted by 500+ Museums Worldwide</span>
              </div>
              
          <h1 class="text-5xl sm:text-6xl lg:text-7xl xl:text-8xl font-black mb-8 leading-tight tracking-tight text-white animate-fade-in-up">
            Transform Visits Into
            <br class="hidden sm:block" />
            <span class="relative">
              <span class="bg-gradient-to-r from-yellow-400 via-orange-500 to-pink-500 bg-clip-text text-transparent animate-gradient bg-300%">
                Unforgettable Experiences
                </span>
              <svg class="absolute -bottom-2 left-0 w-full" height="8" viewBox="0 0 100 8" preserveAspectRatio="none">
                <path d="M0,7 Q25,0 50,7 T100,7" stroke="url(#gradient)" strokeWidth="2" fill="none" opacity="0.5"/>
                <defs>
                  <linearGradient id="gradient" x1="0%" y1="0%" x2="100%" y2="0%">
                    <stop offset="0%" stopColor="#facc15" />
                    <stop offset="50%" stopColor="#f97316" />
                    <stop offset="100%" stopColor="#ec4899" />
                  </linearGradient>
                </defs>
              </svg>
            </span>
          </h1>
          
          <p class="text-xl sm:text-2xl lg:text-3xl text-blue-100/90 max-w-4xl mx-auto mb-12 leading-relaxed font-light animate-fade-in-up animation-delay-200">
            AI-powered souvenir cards with 
            <span class="font-semibold text-white">10+ language support</span> that create 
            <span class="font-semibold text-white">personalized digital adventures</span> for visitors worldwide.
            No apps. No friction. Just magic.
          </p>
          
          <div class="flex flex-col sm:flex-row gap-6 justify-center items-center mb-16 animate-fade-in-up animation-delay-400">
                <Button 
              @click="scrollToContact"
              class="bg-gradient-to-r from-orange-500 to-pink-600 hover:from-orange-600 hover:to-pink-700 border-0 px-10 py-5 text-lg font-bold text-white shadow-2xl hover:shadow-orange-500/25 transition-all transform hover:scale-105"
            >
              <i class="pi pi-rocket mr-2"></i>
              <span>Start Your Pilot Program</span>
            </Button>
                <Button 
              @click="scrollToDemo"
              class="group border-2 border-white/30 bg-white/5 hover:bg-white/10 backdrop-blur-sm px-10 py-5 text-lg font-semibold text-white hover:border-white/50 transition-all transform hover:scale-105"
            >
              <i class="pi pi-play-circle mr-2"></i>
              <span>Watch 2-Min Demo</span>
            </Button>
              </div>
              
          <!-- Trust indicators -->
          <div class="flex flex-wrap justify-center gap-8 items-center text-sm text-white/70 animate-fade-in animation-delay-600">
                <div class="flex items-center gap-2">
              <i class="pi pi-shield text-emerald-400 text-base"></i>
              <span>Enterprise Security</span>
                </div>
                <div class="flex items-center gap-2 px-4 py-2 bg-white/10 backdrop-blur-sm rounded-full border border-white/20">
              <i class="pi pi-globe text-blue-400 text-base"></i>
              <span class="font-semibold text-white">10+ Languages | AI + Content</span>
                </div>
                <div class="flex items-center gap-2">
              <i class="pi pi-bolt text-yellow-400 text-base"></i>
              <span>Setup in Minutes</span>
                </div>
                <div class="flex items-center gap-2">
              <i class="pi pi-chart-line text-purple-400 text-base"></i>
              <span>Real-time Analytics</span>
                </div>
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

    <!-- Stats Bar - Social Proof with Animation -->
    <section id="stats-section" class="bg-white border-y border-slate-200 py-8">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div class="grid grid-cols-2 md:grid-cols-4 gap-8">
          <div class="text-center animate-on-scroll">
            <div class="text-4xl font-black bg-gradient-to-r from-blue-600 to-purple-600 bg-clip-text text-transparent">
              {{ animatedStats.venues }}+
                    </div>
            <div class="text-sm text-slate-600 mt-1">Museums & Venues</div>
                  </div>
          <div class="text-center animate-on-scroll" style="animation-delay: 100ms">
            <div class="text-4xl font-black bg-gradient-to-r from-purple-600 to-pink-600 bg-clip-text text-transparent">
              {{ (animatedStats.cards / 1000000).toFixed(1) }}M+
                </div>
            <div class="text-sm text-slate-600 mt-1">Cards Issued</div>
                  </div>
          <div class="text-center animate-on-scroll" style="animation-delay: 200ms">
            <div class="text-4xl font-black bg-gradient-to-r from-emerald-600 to-teal-600 bg-clip-text text-transparent">
              {{ animatedStats.satisfaction }}%
                </div>
            <div class="text-sm text-slate-600 mt-1">Visitor Satisfaction</div>
              </div>
          <div class="text-center animate-on-scroll" style="animation-delay: 300ms">
            <div class="text-4xl font-black bg-gradient-to-r from-orange-600 to-red-600 bg-clip-text text-transparent">
              {{ animatedStats.support }}/7
            </div>
            <div class="text-sm text-slate-600 mt-1">Global Support</div>
          </div>
        </div>
      </div>
    </section>

    <!-- About Section - Refined Design -->
    <section id="about" class="py-32 bg-gradient-to-b from-slate-50 to-white relative overflow-hidden">
      <!-- Background decoration -->
      <div class="absolute top-0 right-0 w-96 h-96 bg-gradient-to-br from-blue-100/50 to-purple-100/50 rounded-full blur-3xl"></div>
      <div class="absolute bottom-0 left-0 w-96 h-96 bg-gradient-to-br from-emerald-100/50 to-cyan-100/50 rounded-full blur-3xl"></div>
      
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 relative">
        <div class="text-center mb-20">
          <div class="inline-flex items-center gap-2 bg-gradient-to-r from-blue-50 to-purple-50 border border-blue-200 text-blue-700 px-5 py-2.5 rounded-full text-sm font-semibold mb-6">
            <i class="pi pi-sparkles"></i>
            <span>Revolutionary Platform</span>
            </div>
          <h2 class="text-4xl sm:text-5xl lg:text-6xl font-black text-slate-900 mb-6 leading-tight">
            The Bridge Between
            <br />
            <span class="bg-gradient-to-r from-blue-600 via-purple-600 to-pink-600 bg-clip-text text-transparent">
              Physical & Digital Worlds
            </span>
            </h2>
          <p class="text-xl text-slate-600 max-w-3xl mx-auto">
            Combine collectible cards with 
            <span class="font-semibold text-slate-900">AI-powered multilingual experiences</span> 
            to reach global audiences and create memories that last forever
          </p>
        </div>
        
        <!-- Bento Grid Layout with Animation -->
        <div class="grid grid-cols-1 lg:grid-cols-3 gap-8">
          <!-- Main Feature Card -->
          <div class="lg:col-span-2 group animate-on-scroll">
            <div class="bg-gradient-to-br from-blue-600 to-purple-600 rounded-3xl p-10 h-full text-white relative overflow-hidden transform transition-all duration-500 hover:scale-[1.02] hover:shadow-2xl">
              <div class="absolute top-0 right-0 w-64 h-64 bg-white/10 rounded-full blur-3xl"></div>
              <div class="relative">
                <div class="w-16 h-16 bg-white/20 backdrop-blur-xl rounded-2xl flex items-center justify-center mb-6">
                  <i class="pi pi-microchip-ai text-3xl"></i>
                </div>
                <h3 class="text-3xl font-bold mb-4">Global Reach in 10+ Languages</h3>
                <p class="text-lg text-white/90 mb-6 leading-relaxed">
                  <span class="font-semibold">AI Voice Assistant</span> in 10+ languages for natural conversations. 
                  <span class="font-semibold">One-click content translation</span> to adapt your digital content for global audiences. 
                  Your visitors can ask questions, explore stories, and discover hidden details—all in their native language.
                </p>
                <div class="flex flex-wrap gap-4">
                  <div class="flex items-center gap-2 bg-white/20 backdrop-blur-sm px-4 py-2 rounded-full">
                    <i class="pi pi-microphone text-sm"></i>
                    <span class="text-sm font-medium">AI Voice (10+ Languages)</span>
              </div>
                  <div class="flex items-center gap-2 bg-white/20 backdrop-blur-sm px-4 py-2 rounded-full">
                    <i class="pi pi-language text-sm"></i>
                    <span class="text-sm font-medium">Content Translation</span>
                </div>
                  <div class="flex items-center gap-2 bg-white/20 backdrop-blur-sm px-4 py-2 rounded-full">
                    <i class="pi pi-globe text-sm"></i>
                    <span class="text-sm font-medium">Global Audiences</span>
                </div>
              </div>
              </div>
            </div>
              </div>
              
          <!-- Side Features -->
          <div class="space-y-8">
            <div class="bg-white rounded-3xl p-8 shadow-xl hover:shadow-2xl transition-all duration-300 border border-slate-200 group hover:-translate-y-1 animate-on-scroll" style="animation-delay: 100ms">
              <div class="w-14 h-14 bg-gradient-to-br from-emerald-100 to-teal-100 rounded-2xl flex items-center justify-center mb-4 group-hover:scale-110 transition-transform">
                <i class="pi pi-qrcode text-emerald-600 text-2xl"></i>
                </div>
              <h3 class="text-xl font-bold text-slate-900 mb-3">Instant Access</h3>
              <p class="text-slate-600 leading-relaxed">
                No app downloads. No sign-ups. Visitors scan and instantly access rich content.
              </p>
              </div>
              
            <div class="bg-white rounded-3xl p-8 shadow-xl hover:shadow-2xl transition-all duration-300 border border-slate-200 group hover:-translate-y-1 animate-on-scroll" style="animation-delay: 200ms">
              <div class="w-14 h-14 bg-gradient-to-br from-orange-100 to-pink-100 rounded-2xl flex items-center justify-center mb-4 group-hover:scale-110 transition-transform">
                <i class="pi pi-heart text-orange-600 text-2xl"></i>
            </div>
              <h3 class="text-xl font-bold text-slate-900 mb-3">Collectible Keepsakes</h3>
              <p class="text-slate-600 leading-relaxed">
                Beautiful physical cards that visitors treasure, driving repeat visits and word-of-mouth.
              </p>
          </div>
        </div>
        </div>

      </div>
    </section>

    <!-- Demo Section - Interactive Showcase -->
    <section id="demo" class="py-32 bg-gradient-to-br from-slate-950 via-blue-950 to-purple-950 relative overflow-hidden">
      <!-- Animated background -->
      <div class="absolute inset-0">
        <div class="absolute inset-0 bg-[radial-gradient(ellipse_at_center,rgba(120,180,255,0.1),transparent_70%)]"></div>
          </div>
      
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 relative">
        <div class="text-center mb-20">
          <div class="inline-flex items-center gap-2 bg-emerald-500/20 backdrop-blur-xl border border-emerald-400/30 text-emerald-300 px-5 py-2.5 rounded-full text-sm font-semibold mb-6">
            <div class="w-2 h-2 bg-emerald-400 rounded-full animate-pulse"></div>
            <span>Live Demo Available</span>
          </div>
          <h2 class="text-4xl sm:text-5xl lg:text-6xl font-black text-white mb-6">
            Experience the
            <span class="bg-gradient-to-r from-emerald-400 via-cyan-400 to-blue-400 bg-clip-text text-transparent">
              Magic
            </span>
          </h2>
          <p class="text-xl text-blue-100/80 max-w-3xl mx-auto">
            See how CardStudio transforms a simple card scan into an unforgettable journey
          </p>
        </div>
        
        <div class="grid grid-cols-1 lg:grid-cols-2 gap-12 items-center">
          <!-- Demo Card - Enhanced Design -->
          <div class="relative mx-auto lg:mx-0 animate-on-scroll">
            <div class="absolute inset-0 bg-gradient-to-r from-blue-600 to-purple-600 rounded-3xl blur-3xl opacity-50"></div>
            <div class="relative bg-white rounded-3xl p-6 shadow-2xl max-w-sm transform hover:scale-105 transition-all duration-500">
              <div class="aspect-[2/3] bg-gradient-to-br from-blue-600 via-purple-600 to-pink-600 rounded-2xl overflow-hidden relative group">
                <img 
                  :src="demoCardImageUrl" 
                  alt="Interactive Experience Demo" 
                  class="w-full h-full object-cover group-hover:scale-110 transition-transform duration-700"
                />
                <div class="absolute inset-0 bg-gradient-to-t from-black/80 via-black/20 to-transparent"></div>
                
                <!-- Card Content -->
                <div class="absolute bottom-4 left-4 right-4 text-white">
                  <h3 class="text-2xl font-bold mb-2">{{ demoCardTitle }}</h3>
                  <p class="text-sm opacity-90">{{ demoCardSubtitle }}</p>
              </div>
              
                <!-- QR Code with glow effect -->
                <div class="absolute top-4 right-4">
                  <div class="relative">
                    <div class="absolute inset-0 bg-white rounded-xl blur-xl opacity-50"></div>
                    <div class="relative bg-white rounded-xl p-2 shadow-2xl">
                      <QrCode :value="sampleQrUrl" :size="48" />
            </div>
            </div>
          </div>

                <!-- Scan indicator -->
                <div class="absolute inset-0 flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity duration-300">
                  <div class="bg-black/60 backdrop-blur-sm rounded-full px-6 py-3 flex items-center gap-2">
                    <i class="pi pi-qrcode text-white"></i>
                    <span class="text-white font-semibold">Scan to Try</span>
                </div>
                </div>
              </div>
              
              <div class="mt-6 text-center">
                <Button 
                  label="Try Live Demo" 
                  icon="pi pi-external-link"
                  @click="openDemoCard"
                  class="w-full bg-gradient-to-r from-blue-600 to-purple-600 hover:from-blue-700 hover:to-purple-700 text-white border-0 py-3 font-semibold shadow-lg hover:shadow-xl transition-all"
                />
            </div>
            </div>
          </div>

          <!-- Features List -->
          <div class="space-y-6 animate-on-scroll" style="animation-delay: 200ms">
            <h3 class="text-3xl font-bold text-white mb-8">What Visitors Experience</h3>
            
            <div v-for="(feature, index) in demoFeatures" :key="index" 
                 class="flex gap-4 group">
              <div class="w-12 h-12 bg-gradient-to-br from-blue-600/20 to-purple-600/20 backdrop-blur-sm rounded-xl flex items-center justify-center flex-shrink-0 group-hover:scale-110 transition-transform">
                <i :class="`pi ${feature.icon} text-blue-400 text-xl`"></i>
                </div>
              <div>
                <h4 class="text-lg font-semibold text-white mb-1">{{ feature.title }}</h4>
                <p class="text-blue-100/70 leading-relaxed">{{ feature.description }}</p>
              </div>
              </div>
              
            <div class="pt-8">
              <Button 
                label="Create Your First Card" 
                icon="pi pi-arrow-right"
                iconPos="right"
                @click="handleOrganizerDemo"
                class="bg-white text-blue-900 hover:bg-blue-50 border-0 px-8 py-4 font-bold shadow-xl hover:shadow-2xl transition-all transform hover:scale-105"
              />
            </div>
          </div>
        </div>
      </div>
    </section>

    <!-- How It Works - Visual Journey -->
    <section class="py-32 bg-white relative overflow-hidden">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div class="text-center mb-20">
          <div class="inline-flex items-center gap-2 bg-gradient-to-r from-violet-50 to-purple-50 border border-violet-200 text-violet-700 px-5 py-2.5 rounded-full text-sm font-semibold mb-6">
            <i class="pi pi-route"></i>
            <span>Visitor Journey</span>
          </div>
          <h2 class="text-4xl sm:text-5xl lg:text-6xl font-black text-slate-900 mb-6">
            Four Simple Steps to
            <span class="bg-gradient-to-r from-violet-600 to-purple-600 bg-clip-text text-transparent">
              Delight
            </span>
          </h2>
        </div>
        
        <!-- Steps with connecting line -->
        <div class="relative">
          <!-- Connecting line for desktop -->
          <div class="hidden lg:block absolute top-1/2 left-0 right-0 h-0.5 bg-gradient-to-r from-blue-200 via-purple-200 to-pink-200"></div>
          
          <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-8">
            <div v-for="(step, index) in howItWorksSteps" :key="index" 
                 class="relative group">
              <div class="bg-white rounded-3xl p-8 shadow-xl hover:shadow-2xl transition-all duration-500 border-2 border-slate-200 hover:border-purple-300 h-full">
                <!-- Step number -->
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

    <!-- Key Features - Premium Cards -->
    <section class="py-32 bg-gradient-to-b from-slate-50 to-white">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div class="text-center mb-20">
          <div class="inline-flex items-center gap-2 bg-gradient-to-r from-amber-50 to-orange-50 border border-amber-200 text-amber-700 px-5 py-2.5 rounded-full text-sm font-semibold mb-6">
            <i class="pi pi-star-fill"></i>
            <span>Platform Features</span>
          </div>
          <h2 class="text-4xl sm:text-5xl lg:text-6xl font-black text-slate-900 mb-6">
            Everything You Need to
            <span class="bg-gradient-to-r from-amber-600 to-orange-600 bg-clip-text text-transparent">
              Succeed
            </span>
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

    <!-- Applications Carousel - Modern Design -->
    <section class="py-32 bg-white">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div class="text-center mb-20">
          <div class="inline-flex items-center gap-2 bg-gradient-to-r from-emerald-50 to-teal-50 border border-emerald-200 text-emerald-700 px-5 py-2.5 rounded-full text-sm font-semibold mb-6">
            <i class="pi pi-globe"></i>
            <span>Use Cases</span>
                </div>
          <h2 class="text-4xl sm:text-5xl lg:text-6xl font-black text-slate-900 mb-6">
            Trusted Across
            <span class="bg-gradient-to-r from-emerald-600 to-teal-600 bg-clip-text text-transparent">
              Industries
            </span>
          </h2>
          </div>

        <Carousel :value="applications" :numVisible="3" :numScroll="1" :responsiveOptions="carouselResponsiveOptions" 
                  :circular="true" :autoplayInterval="4000" class="custom-carousel">
          <template #item="slotProps">
            <div class="p-4">
              <div class="bg-gradient-to-br from-white to-slate-50 rounded-3xl overflow-hidden shadow-xl hover:shadow-2xl transition-all duration-500 transform hover:-translate-y-2 border border-slate-200">
                <div class="p-8">
                  <div class="w-20 h-20 bg-gradient-to-br from-emerald-100 to-teal-100 rounded-2xl flex items-center justify-center mb-6 mx-auto">
                    <i :class="`pi ${slotProps.data.icon} text-emerald-600 text-3xl`"></i>
                </div>
                  <h3 class="text-2xl font-bold text-slate-900 mb-2 text-center">{{ slotProps.data.name }}</h3>
                  <p class="text-sm font-semibold text-emerald-600 mb-4 text-center">{{ slotProps.data.role }}</p>
                  <ul class="space-y-3">
                    <li v-for="(benefit, idx) in slotProps.data.benefits.slice(0, 2)" :key="idx" 
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
      </div>
    </section>

    <!-- Pricing Section - Premium Design -->
    <section id="pricing" class="py-32 bg-gradient-to-br from-slate-950 via-blue-950 to-purple-950 relative overflow-hidden">
      <div class="absolute inset-0">
        <div class="absolute inset-0 bg-[radial-gradient(ellipse_at_top_left,rgba(120,180,255,0.15),transparent_50%)]"></div>
        <div class="absolute inset-0 bg-[radial-gradient(ellipse_at_bottom_right,rgba(180,120,255,0.15),transparent_50%)]"></div>
      </div>
      
      <div class="max-w-5xl mx-auto px-4 sm:px-6 lg:px-8 relative">
        <div class="text-center mb-20">
          <div class="inline-flex items-center gap-2 bg-blue-500/20 backdrop-blur-xl border border-blue-400/30 text-blue-300 px-5 py-2.5 rounded-full text-sm font-semibold mb-6">
            <i class="pi pi-dollar"></i>
            <span>Simple, Transparent Pricing</span>
          </div>
          <h2 class="text-4xl sm:text-5xl lg:text-6xl font-black text-white mb-6">
            Pay Only for What You
            <span class="bg-gradient-to-r from-blue-400 via-cyan-400 to-emerald-400 bg-clip-text text-transparent">
              Create
            </span>
          </h2>
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
            <div class="grid lg:grid-cols-2 gap-12">
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

              <div>
                <h3 class="text-2xl font-bold text-white mb-6">Pricing Details</h3>
                <div class="space-y-4 text-blue-100">
                  <div class="bg-white/5 rounded-xl p-4">
                    <div class="flex justify-between items-center">
                      <span>Your cost</span>
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
                      <span>Your profit</span>
                      <span class="font-bold text-emerald-400">$1-5 per card</span>
                  </div>
                  </div>
                  <div class="text-sm text-blue-300 pt-4">
                    <i class="pi pi-info-circle mr-2"></i>
                    Minimum order: 100 cards
                  </div>
                </div>
              </div>
            </div>

            <div class="mt-12 text-center">
                  <Button 
                label="Start Your Pilot Program" 
                    icon="pi pi-arrow-right"
                    iconPos="right"
                @click="scrollToContact"
                class="bg-gradient-to-r from-orange-500 to-pink-600 hover:from-orange-600 hover:to-pink-700 text-white border-0 px-10 py-5 text-lg font-bold shadow-2xl hover:shadow-orange-500/25 transition-all transform hover:scale-105"
              />
              <p class="text-blue-300 text-sm mt-4">No monthly fees • No setup costs • Pay as you grow</p>
            </div>
          </div>
        </div>
      </div>
    </section>

    <!-- FAQ Section - Clean Design -->
    <section class="py-32 bg-gradient-to-b from-slate-50 to-white">
      <div class="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8">
        <div class="text-center mb-16">
          <div class="inline-flex items-center gap-2 bg-gradient-to-r from-blue-50 to-purple-50 border border-blue-200 text-blue-700 px-5 py-2.5 rounded-full text-sm font-semibold mb-6">
            <i class="pi pi-question-circle"></i>
            <span>FAQs</span>
          </div>
          <h2 class="text-4xl sm:text-5xl font-black text-slate-900">
            Got <span class="bg-gradient-to-r from-blue-600 to-purple-600 bg-clip-text text-transparent">Questions?</span>
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
                <p class="text-slate-600 leading-relaxed">{{ faq.answer }}</p>
              </div>
            </transition>
          </div>
        </div>
      </div>
    </section>

    <!-- Contact Section - Premium CTA -->
    <section id="contact" class="py-32 bg-gradient-to-br from-blue-600 via-purple-600 to-pink-600 relative overflow-hidden">
      <div class="absolute inset-0">
        <div class="absolute inset-0 bg-[url('/grid.svg')] bg-center opacity-10"></div>
      </div>
      
      <div class="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 relative">
        <div class="text-center mb-16">
          <h2 class="text-4xl sm:text-5xl lg:text-6xl font-black text-white mb-6">
            Ready to Transform Your
            <br />
            <span class="text-yellow-300">Visitor Experience?</span>
          </h2>
          <p class="text-xl text-white/90 max-w-2xl mx-auto">
            Join 500+ venues already creating unforgettable digital experiences with CardStudio
          </p>
        </div>
        
        <div class="bg-white rounded-3xl p-8 lg:p-12 shadow-2xl">
          <div class="grid md:grid-cols-2 gap-8 mb-8">
            <a :href="`mailto:${contactEmail}`" 
               class="group flex items-center gap-4 p-6 bg-gradient-to-br from-blue-50 to-purple-50 rounded-2xl hover:shadow-lg transition-all duration-300 border border-blue-200">
              <div class="w-14 h-14 bg-gradient-to-br from-blue-600 to-purple-600 rounded-xl flex items-center justify-center flex-shrink-0 group-hover:scale-110 transition-transform">
                <i class="pi pi-envelope text-white text-xl"></i>
        </div>
              <div>
                <h4 class="font-semibold text-slate-900">Email Us</h4>
                <p class="text-blue-600">{{ contactEmail }}</p>
          </div>
            </a>
            
            <a :href="contactWhatsApp" 
               class="group flex items-center gap-4 p-6 bg-gradient-to-br from-emerald-50 to-teal-50 rounded-2xl hover:shadow-lg transition-all duration-300 border border-emerald-200">
              <div class="w-14 h-14 bg-gradient-to-br from-emerald-600 to-teal-600 rounded-xl flex items-center justify-center flex-shrink-0 group-hover:scale-110 transition-transform">
                <i class="pi pi-whatsapp text-white text-xl"></i>
            </div>
          <div>
                <h4 class="font-semibold text-slate-900">WhatsApp</h4>
                <p class="text-emerald-600">{{ contactWhatsAppDisplay }}</p>
              </div>
            </a>
        </div>

          <div class="text-center">
            <Button 
              label="Start Your Free Pilot" 
              icon="pi pi-rocket"
              iconPos="right"
              @click="router.push('/signup')"
              class="bg-gradient-to-r from-blue-600 to-purple-600 hover:from-blue-700 hover:to-purple-700 text-white border-0 px-10 py-5 text-lg font-bold shadow-xl hover:shadow-2xl transition-all transform hover:scale-105"
            />
            <p class="text-slate-500 text-sm mt-6">
              <i class="pi pi-shield mr-2"></i>
              Your information is secure and will only be used to respond to your inquiry
            </p>
          </div>
        </div>
      </div>
    </section>

    <!-- Floating CTA Button -->
    <transition name="slide-up">
      <div v-if="showFloatingCTA" class="fixed bottom-8 right-8 z-50">
        <Button
          @click="router.push('/signup')"
          class="bg-gradient-to-r from-blue-600 to-purple-600 hover:from-blue-700 hover:to-purple-700 text-white border-0 px-6 py-3 font-semibold shadow-2xl hover:shadow-3xl transition-all transform hover:scale-110 pulse-glow rounded-full"
        >
          <i class="pi pi-rocket mr-2"></i>
          <span>Get Started</span>
        </Button>
            </div>
    </transition>

    <!-- Footer - Minimal & Clean -->
    <footer class="bg-slate-900 text-white py-16">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div class="text-center">
          <div class="flex justify-center mb-6">
            <div class="flex items-center gap-3">
              <div class="w-10 h-10 bg-gradient-to-br from-blue-600 to-purple-600 rounded-xl flex items-center justify-center">
                <i class="pi pi-id-card text-white text-xl"></i>
            </div>
              <span class="text-xl font-bold">CardStudio</span>
          </div>
            </div>
          <p class="text-slate-400 mb-8">Transforming visitor experiences through AI-powered digital souvenirs</p>
          <div class="flex justify-center gap-6 text-sm">
            <a href="#" class="text-slate-400 hover:text-white transition-colors">Privacy</a>
            <a href="#" class="text-slate-400 hover:text-white transition-colors">Terms</a>
            <a :href="`mailto:${contactEmail}`" class="text-slate-400 hover:text-white transition-colors">Contact</a>
          </div>
          <div class="mt-8 pt-8 border-t border-slate-800">
            <p class="text-slate-500 text-sm">© 2025 CardStudio. All rights reserved.</p>
        </div>
        </div>
      </div>
    </footer>
  </div>
</template>

<script setup>
import { ref, onMounted, onUnmounted, computed, watchEffect } from 'vue'
import { useRouter } from 'vue-router'
import Button from 'primevue/button'
import Carousel from 'primevue/carousel'
import QrCode from 'qrcode.vue'
import { useAuthStore } from '@/stores/auth'
import { useToast } from 'primevue/usetoast'

const router = useRouter()
const authStore = useAuthStore()
const toast = useToast()

// Navigation state
const scrolled = ref(false)
const mobileMenuOpen = ref(false)
const scrollProgress = ref(0)
const showFloatingCTA = ref(false)

// Stats animation state
const statsVisible = ref(false)
const animatedStats = ref({
  venues: 500,      // Default values shown immediately
  cards: 2000000,
  satisfaction: 95,
  support: 24
})

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

// FAQ functionality
const openFaqIndex = ref(-1)
const toggleFaq = (index) => {
  openFaqIndex.value = openFaqIndex.value === index ? -1 : index
}

// Optimized scroll handling with debounce
let scrollTimeout = null
const handleScroll = () => {
  // Immediate updates for critical UI
  scrolled.value = window.scrollY > 10
  showFloatingCTA.value = window.scrollY > window.innerHeight * 0.8
  
  // Calculate scroll progress
  const winScroll = document.body.scrollTop || document.documentElement.scrollTop
  const height = document.documentElement.scrollHeight - document.documentElement.clientHeight
  scrollProgress.value = (winScroll / height) * 100
  
  // Debounced operations
  if (scrollTimeout) clearTimeout(scrollTimeout)
  scrollTimeout = setTimeout(() => {
    // Additional scroll-based operations
  }, 100)
}

// Intersection Observer for animations
const observeElements = () => {
  // Add class to enable animations only when observer is ready
  document.documentElement.classList.add('js-animations-ready')
  
  const observer = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
      if (entry.isIntersecting) {
        entry.target.classList.add('animate-visible')
        
        // Trigger stats animation
        if (entry.target.id === 'stats-section' && !statsVisible.value) {
          statsVisible.value = true
          animateStats()
        }
      }
    })
  }, { 
    threshold: 0.1,
    rootMargin: '50px' // Start animation slightly before element is visible
  })
  
  // Observe elements with animation
  const animateElements = document.querySelectorAll('.animate-on-scroll')
  if (animateElements.length === 0) {
    console.warn('No elements with .animate-on-scroll class found')
  }
  
  animateElements.forEach(el => {
    observer.observe(el)
  })
  
  // Observe stats section
  const statsSection = document.getElementById('stats-section')
  if (statsSection) observer.observe(statsSection)
  
  return observer
}

// Animate stats numbers
const animateStats = () => {
  // Skip if already animated or if values are already at target
  if (statsVisible.value) return
  
  const targetValues = {
    venues: 500,
    cards: 2000000,
    satisfaction: 95,
    support: 24
  }
  
  // Start from 0 for animation
  animatedStats.value = {
    venues: 0,
    cards: 0,
    satisfaction: 0,
    support: 24 // This one doesn't animate
  }
  
  const duration = 2000
  const steps = 60
  const interval = duration / steps
  
  let currentStep = 0
  const timer = setInterval(() => {
    currentStep++
    const progress = currentStep / steps
    const easeOut = 1 - Math.pow(1 - progress, 3)
    
    animatedStats.value = {
      venues: Math.round(targetValues.venues * easeOut),
      cards: Math.round(targetValues.cards * easeOut),
      satisfaction: Math.round(targetValues.satisfaction * easeOut),
      support: targetValues.support
    }
    
    if (currentStep >= steps) {
      clearInterval(timer)
      // Ensure final values are exact
      animatedStats.value = targetValues
    }
  }, interval)
}

onMounted(() => {
  window.addEventListener('scroll', handleScroll, { passive: true })
  
  // Initialize intersection observer after DOM is fully ready
    setTimeout(() => {
    observeElements()
    
    // Fallback: ensure all content is visible after 3 seconds if animations didn't trigger
    setTimeout(() => {
      document.querySelectorAll('.animate-on-scroll').forEach(el => {
        if (!el.classList.contains('animate-visible')) {
          el.classList.add('animate-visible')
        }
      })
    }, 3000)
  }, 100)
  
  // Preload critical images
  const images = [
    import.meta.env.VITE_DEFAULT_CARD_IMAGE_URL || 'https://images.unsplash.com/photo-1564399580075-5dfe19c205f3?w=400&h=600&fit=crop&crop=center'
  ]
  images.forEach(src => {
    const img = new Image()
    img.src = src
  })
})

onUnmounted(() => {
  window.removeEventListener('scroll', handleScroll)
  if (scrollTimeout) clearTimeout(scrollTimeout)
})

// Navigation functions
const scrollToSection = (sectionId) => {
  const element = document.getElementById(sectionId)
  if (element) {
    const offset = 80 // Account for fixed nav
    const elementPosition = element.getBoundingClientRect().top + window.scrollY
    window.scrollTo({
      top: elementPosition - offset,
      behavior: 'smooth'
    })
  }
  mobileMenuOpen.value = false
}

const scrollToAbout = () => scrollToSection('about')
const scrollToDemo = () => scrollToSection('demo')
const scrollToPricing = () => scrollToSection('pricing')
const scrollToContact = () => scrollToSection('contact')

const openDemoCard = () => {
  window.location.href = sampleQrUrl.value
}

const handleOrganizerDemo = async () => {
  if (!authStore.session?.user) {
    toast.add({
      severity: 'info',
      summary: 'Get Started',
      detail: 'Sign up to access the card issuer portal',
      life: 5000
    })
    router.push('/signup')
    return
  }

  const userRole = authStore.session.user.user_metadata?.role
  if (userRole !== 'cardIssuer') {
    toast.add({
      severity: 'warn',
      summary: 'Access Required',
      detail: 'Please complete your organizer profile setup',
      life: 5000
    })
    router.push('/signup')
    return
  }

  router.push('/cms/mycards')
}

// Data
const scenarios = ref([
  { icon: 'pi-building', name: 'Museums' },
  { icon: 'pi-map-marker', name: 'Tourist Sites' },
  { icon: 'pi-star', name: 'Zoos' },
  { icon: 'pi-calendar', name: 'Conferences' },
  { icon: 'pi-briefcase', name: 'Trade Shows' },
  { icon: 'pi-users', name: 'Events' },
  { icon: 'pi-home', name: 'Hotels' },
  { icon: 'pi-server', name: 'Restaurants' }
])

const demoFeatures = ref([
  {
    icon: 'pi-qrcode',
    title: 'Instant Access',
    description: 'One scan opens a world of content. No downloads, no sign-ups, just immediate engagement.'
  },
  {
    icon: 'pi-microphone',
    title: 'Natural Conversations',
    description: 'AI responds to voice questions in real-time, creating personalized experiences for every visitor.'
  },
  {
    icon: 'pi-globe',
    title: 'Multi-Language Support',
    description: 'Seamless switching between 10+ languages ensures every visitor feels welcomed.'
  },
  {
    icon: 'pi-heart',
    title: 'Memorable Keepsake',
    description: 'Beautiful physical cards that visitors treasure long after their visit ends.'
  }
])

const howItWorksSteps = ref([
  {
    icon: 'pi-shopping-cart',
    title: 'Purchase',
    description: 'Visitors buy premium cards as souvenirs and interactive guides'
  },
  {
    icon: 'pi-qrcode',
    title: 'Scan',
    description: 'QR code instantly unlocks digital content and AI features'
  },
  {
    icon: 'pi-comments',
    title: 'Explore',
    description: 'Engage with AI voice guide for personalized storytelling'
  },
  {
    icon: 'pi-heart',
    title: 'Collect',
    description: 'Cards become treasured keepsakes driving repeat visits'
  }
])

const keyFeatures = ref([
  {
    icon: 'pi-id-card',
    title: 'Premium Collectibles',
    description: 'Beautiful QR-enabled cards that link to rich digital content, creating lasting souvenirs.'
  },
  {
    icon: 'pi-microphone',
    title: 'AI Voice in 10+ Languages',
    description: 'Natural voice conversations in English, Chinese (Traditional & Simplified), Japanese, Korean, Spanish, French, Russian, Arabic, and Thai. Every visitor feels welcomed in their native language.'
  },
  {
    icon: 'pi-language',
    title: 'One-Click Content Translation',
    description: 'Instantly translate ALL your digital content—card descriptions, exhibits, artifacts—to 10 languages with AI-powered precision. Create once, reach global audiences everywhere.'
  },
  {
    icon: 'pi-mobile',
    title: 'No App Required',
    description: 'Instant access via QR scan. No downloads, no friction, maximum adoption.'
  },
  {
    icon: 'pi-bolt',
    title: 'Zero Hardware',
    description: 'Leverage visitors\' smartphones. No expensive equipment or maintenance needed.'
  },
  {
    icon: 'pi-chart-bar',
    title: 'Rich Analytics',
    description: 'Real-time insights into visitor engagement, popular content, and usage patterns.'
  }
])

const applications = ref([
  {
    icon: 'pi-building',
    name: 'Museums',
    role: 'AI Museum Docent',
    benefits: [
      'Interactive artifact exploration',
      'Personalized tour experiences'
    ]
  },
  {
    icon: 'pi-map-marker',
    name: 'Tourist Sites',
    role: 'AI Tour Guide',
    benefits: [
      'Historical storytelling',
      'Multi-language navigation'
    ]
  },
  {
    icon: 'pi-star',
    name: 'Zoos',
    role: 'AI Wildlife Expert',
    benefits: [
      'Animal facts & conservation',
      'Interactive education'
    ]
  },
  {
    icon: 'pi-briefcase',
    name: 'Trade Shows',
    role: 'AI Product Assistant',
    benefits: [
      'Product demonstrations',
      'Lead generation'
    ]
  },
  {
    icon: 'pi-calendar',
    name: 'Conferences',
    role: 'AI Event Coach',
    benefits: [
      'Session summaries',
      'Networking assistance'
    ]
  },
  {
    icon: 'pi-home',
    name: 'Hotels',
    role: 'AI Concierge',
    benefits: [
      'Local recommendations',
      'Service information'
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

const pricingFeatures = ref([
  'AI voice conversations',
  'Multi-language support',
  'Content management dashboard',
  'Real-time analytics',
  'QR code generation',
  'Print & shipping management',
  'Cloud hosting included',
  '24/7 global support',
  'Regular platform updates'
])

const faqs = ref([
  {
    question: 'How quickly can we get started?',
    answer: 'You can launch your first CardStudio experience in minutes. Our self-service platform requires no technical setup - just sign up, design your cards, and start issuing them immediately.'
  },
  {
    question: 'Do visitors need to download an app?',
    answer: 'No! That\'s the beauty of CardStudio. Visitors simply scan the QR code with their phone camera and instantly access all features through their web browser. Zero friction, maximum engagement.'
  },
  {
    question: 'What languages are supported?',
    answer: 'CardStudio supports 10 languages with one-click AI translation: English, Traditional Chinese, Simplified Chinese, Japanese, Korean, Spanish, French, Russian, Arabic, and Thai. AI voice conversations and content automatically adapt to each visitor\'s language preference.'
  },
  {
    question: 'How does the pricing work?',
    answer: 'Simple and transparent: $2 per card with no monthly fees or hidden costs. Everything is included - AI features, hosting, analytics, and support. Most venues sell cards for $3-7, earning profit on each sale.'
  },
  {
    question: 'Can we customize the card designs?',
    answer: 'Absolutely! Use our intuitive design tools to create cards that match your brand. Upload custom artwork, add your logo, and craft unique experiences for different exhibits or events.'
  },
  {
    question: 'What kind of analytics do you provide?',
    answer: 'Real-time insights including visitor engagement, popular content, language preferences, peak usage times, and conversion metrics. Export reports for deeper analysis.'
  },
  {
    question: 'Is the platform secure?',
    answer: 'Yes. CardStudio uses enterprise-grade security with encrypted data transmission, secure cloud hosting, and GDPR compliance. Your content and visitor data are always protected.'
  },
  {
    question: 'What\'s the minimum order?',
    answer: 'The minimum order is 100 cards. This ensures cost-effective production while giving you enough inventory to test and scale your program.'
  },
  {
    question: 'How long does shipping take?',
    answer: 'Cards are printed within 4 business days and shipped globally. Typical delivery is 5-10 days total depending on your location.'
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

@keyframes gradient {
  0%, 100% { background-position: 0% 50%; }
  50% { background-position: 100% 50%; }
}

@keyframes scroll {
  0% { transform: translateY(0); }
  100% { transform: translateY(8px); }
}

@keyframes fade-in {
  from { opacity: 0; }
  to { opacity: 1; }
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

.animate-gradient {
  animation: gradient 8s ease infinite;
}

.bg-300\% {
  background-size: 300% 300%;
}

.animate-scroll {
  animation: scroll 1.5s ease-in-out infinite;
}

.animate-fade-in {
  animation: fade-in 0.6s ease-out forwards;
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

.animation-delay-600 {
  animation-delay: 600ms;
}

/* Slide up transition for floating CTA */
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

/* Transitions */
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

:deep(.custom-carousel .p-carousel-indicators) {
  padding: 1rem;
}

:deep(.custom-carousel .p-carousel-indicator button) {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  background-color: rgba(0, 0, 0, 0.2);
  transition: all 0.3s ease;
}

:deep(.custom-carousel .p-carousel-indicator.p-highlight button) {
  width: 24px;
  border-radius: 4px;
  background-color: #3b82f6;
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

/* Gradient text compatibility */
.bg-clip-text {
  -webkit-background-clip: text;
  background-clip: text;
}

/* Performance optimizations */
.animate-on-scroll {
  opacity: 1;
  transform: translateY(0);
  transition: all 0.8s cubic-bezier(0.4, 0, 0.2, 1);
}

/* Only apply animation if JS is enabled and observer is working */
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

/* Reduced motion support */
@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
  }
}
</style>