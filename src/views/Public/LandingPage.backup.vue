<template>
  <div class="min-h-screen bg-gradient-to-br from-blue-50 via-white to-purple-50">

    <!-- Hero Section -->
    <section class="relative overflow-hidden bg-gradient-to-b from-white via-blue-50/20 to-purple-50/20">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12 sm:py-16 lg:py-24">
        <!-- Platform Description First -->
        <div class="text-center mb-12 sm:mb-16">
          <div class="inline-flex items-center gap-2 bg-gradient-to-r from-blue-600 to-purple-600 text-white px-4 sm:px-6 py-2 rounded-full text-sm font-semibold mb-6 sm:mb-8 shadow-lg">
            <i class="pi pi-verified"></i>
            <span class="hidden sm:inline">The Future of Digital Souvenirs</span>
            <span class="sm:hidden">Digital Souvenirs</span>
          </div>
          
          <h1 class="text-3xl sm:text-4xl md:text-5xl lg:text-7xl font-black text-slate-900 mb-4 sm:mb-6 leading-tight tracking-tight px-2">
            Turn Any Experience Into
            <br class="hidden sm:block" />
            <span class="bg-gradient-to-r from-blue-600 via-purple-600 to-pink-600 bg-clip-text text-transparent">
              Interactive Digital Magic
            </span>
          </h1>
          
          <p class="text-lg sm:text-xl lg:text-2xl text-slate-600 max-w-4xl mx-auto mb-6 sm:mb-8 leading-relaxed font-light px-2">
            CardStudio empowers <span class="font-semibold text-slate-800">any venue or event</span> to create premium digital souvenirs. 
            <span class="block sm:inline mt-2 sm:mt-0">From museums to theme parks, conferences to tourist attractions — give your visitors 
            <span class="font-semibold text-slate-800">AI-powered memories</span> they'll treasure forever.</span>
          </p>
          
          <!-- Core Benefits - Mobile Optimized -->
          <div class="grid grid-cols-1 sm:grid-cols-3 gap-4 sm:gap-8 max-w-4xl mx-auto">
            <div class="flex items-center gap-3 bg-white/50 backdrop-blur-sm rounded-xl p-3 sm:p-4 shadow-sm">
              <div class="w-10 sm:w-12 h-10 sm:h-12 bg-gradient-to-br from-blue-500 to-blue-600 rounded-full flex items-center justify-center shadow-lg flex-shrink-0">
                <i class="pi pi-mobile text-white text-lg sm:text-xl"></i>
              </div>
              <div class="text-left min-w-0">
                <p class="text-base sm:text-lg font-semibold text-slate-900">No App Required</p>
                <p class="text-xs sm:text-sm text-slate-600">Instant QR code access</p>
              </div>
            </div>
            <div class="flex items-center gap-3 bg-white/50 backdrop-blur-sm rounded-xl p-3 sm:p-4 shadow-sm">
              <div class="w-10 sm:w-12 h-10 sm:h-12 bg-gradient-to-br from-blue-500 to-cyan-600 rounded-full flex items-center justify-center shadow-lg flex-shrink-0">
                <i class="pi pi-bolt text-white text-lg sm:text-xl"></i>
              </div>
              <div class="text-left min-w-0">
                <p class="text-base sm:text-lg font-semibold text-slate-900">Launch in Minutes</p>
                <p class="text-xs sm:text-sm text-slate-600">Self-service platform</p>
              </div>
            </div>
            <div class="flex items-center gap-3 bg-white/50 backdrop-blur-sm rounded-xl p-3 sm:p-4 shadow-sm">
              <div class="w-10 sm:w-12 h-10 sm:h-12 bg-gradient-to-br from-purple-500 to-pink-600 rounded-full flex items-center justify-center shadow-lg flex-shrink-0">
                <i class="pi pi-globe text-white text-lg sm:text-xl"></i>
              </div>
              <div class="text-left min-w-0">
                <p class="text-base sm:text-lg font-semibold text-slate-900">Works Globally</p>
                <p class="text-xs sm:text-sm text-slate-600">5 languages supported</p>
              </div>
            </div>
          </div>
        </div>

        <!-- Demo Section -->
        <div class="bg-gradient-to-br from-slate-900 via-slate-800 to-blue-900 rounded-2xl sm:rounded-3xl p-6 sm:p-8 lg:p-12 shadow-2xl relative overflow-hidden">
          <!-- Background pattern -->
          <div class="absolute inset-0 opacity-10">
            <div class="absolute top-0 left-0 w-full h-full bg-gradient-to-br from-blue-600/20 via-purple-600/20 to-pink-600/20"></div>
          </div>
          
          <div class="grid grid-cols-1 lg:grid-cols-5 gap-6 sm:gap-8 lg:gap-12 items-center relative">
            <!-- Left: Call to Action -->
            <div class="lg:col-span-3 text-center lg:text-left">
              <div class="inline-flex items-center gap-2 bg-gradient-to-r from-emerald-500 to-cyan-500 text-white px-3 sm:px-4 py-2 rounded-full text-xs sm:text-sm font-semibold mb-4 sm:mb-6 shadow-lg">
                <div class="w-2 h-2 bg-white rounded-full animate-pulse"></div>
                <span>Live Demo Available</span>
              </div>
              
              <h2 class="text-2xl sm:text-3xl lg:text-5xl font-bold text-white mb-4 sm:mb-6 leading-tight">
                {{ $t('landing.see_magic') }}
                <br class="hidden lg:block" />
                <span class="bg-gradient-to-r from-yellow-400 to-orange-500 bg-clip-text text-transparent">
                  {{ $t('landing.in_action') }}
                </span>
              </h2>
              
              <p class="text-sm sm:text-base lg:text-lg text-slate-300 mb-6 sm:mb-8 leading-relaxed">
                {{ $t('landing.demo_experience') }}
              </p>
              
              <!-- CTA Buttons -->
              <div class="flex flex-col sm:flex-row gap-3 sm:gap-4 mb-6 sm:mb-8">
                <Button 
                  :label="$t('landing.start_creating')" 
                  icon="pi pi-arrow-right"
                  iconPos="right"
                  @click="handleOrganizerDemo"
                  class="bg-gradient-to-r from-blue-600 to-purple-600 hover:from-blue-700 hover:to-purple-700 border-0 px-6 sm:px-8 py-3 sm:py-4 font-bold shadow-xl text-sm sm:text-base"
                />
                <Button 
                  :label="$t('landing.watch_demo')" 
                  icon="pi pi-play"
                  outlined
                  class="border-2 border-white/30 text-white hover:bg-white/10 px-6 sm:px-8 py-3 sm:py-4 font-semibold text-sm sm:text-base"
                />
              </div>
              
              <!-- Key Features -->
              <div class="flex flex-wrap gap-4 sm:gap-6 text-xs sm:text-sm text-slate-400 justify-center lg:justify-start">
                <div class="flex items-center gap-2">
                  <i class="pi pi-microphone text-cyan-400"></i>
                  <span>AI voice conversations</span>
                </div>
                <div class="flex items-center gap-2">
                  <i class="pi pi-id-card text-purple-400"></i>
                  <span>Physical & digital cards</span>
                </div>
                <div class="flex items-center gap-2">
                  <i class="pi pi-chart-line text-emerald-400"></i>
                  <span>Real-time analytics</span>
                </div>
              </div>
            </div>

            <!-- Right: Compact Demo Card -->
            <div class="lg:col-span-2 relative mt-6 lg:mt-0">
              <!-- Demo Card with correct 2:3 ratio -->
              <div class="bg-white rounded-xl sm:rounded-2xl shadow-2xl p-3 sm:p-4 relative max-w-xs sm:max-w-sm mx-auto">
                <div class="aspect-[2/3] bg-gradient-to-br from-blue-500 to-purple-600 rounded-lg sm:rounded-xl overflow-hidden relative">
                  <img 
                    :src="demoCardImageUrl" 
                    alt="Interactive Experience Demo" 
                    class="w-full h-full object-cover"
                  />
                  <div class="absolute inset-0 bg-gradient-to-t from-black/70 via-transparent to-transparent"></div>
                  
                  <!-- Card Content -->
                  <div class="absolute bottom-2 sm:bottom-3 left-2 sm:left-3 right-2 sm:right-3 text-white">
                    <h3 class="text-sm sm:text-lg font-bold mb-1">{{ demoCardTitle }}</h3>
                    <p class="text-xs opacity-90">{{ demoCardSubtitle }}</p>
                  </div>
                  
                  <!-- QR Code -->
                  <div class="absolute top-2 sm:top-3 right-2 sm:right-3">
                    <div class="bg-white rounded-md sm:rounded-lg p-1 sm:p-1.5 shadow-lg">
                      <QrCode :value="sampleQrUrl" :size="40" />
                    </div>
                  </div>
                </div>
                
                <!-- Scan Instructions -->
                <div class="mt-2 sm:mt-3 text-center">
                  <p class="text-xs font-medium text-slate-700 mb-2">
                    <i class="pi pi-qrcode text-blue-600 mr-1"></i>
                    Scan to experience AI guide
                  </p>
                  
                  <!-- Mobile Quick Access -->
                  <div class="block sm:hidden mt-2">
                    <Button 
                      label="Try Now" 
                      icon="pi pi-external-link"
                      @click="openDemoCard"
                      class="w-full bg-gradient-to-r from-blue-600 to-blue-700 hover:from-blue-700 hover:to-blue-800 border-0 text-xs py-2"
                    />
                  </div>
                </div>
              </div>
              
              <!-- Floating Elements (hidden on mobile) -->
              <div class="hidden sm:block absolute -top-6 -left-6 w-32 h-32 bg-gradient-to-br from-blue-400/30 to-purple-400/30 rounded-full blur-2xl"></div>
              <div class="hidden sm:block absolute -bottom-6 -right-6 w-24 h-24 bg-gradient-to-br from-purple-400/30 to-pink-400/30 rounded-full blur-2xl"></div>
            </div>
          </div>
        </div>
      </div>
    </section>

    <!-- Brand Hero Section -->
    <section class="py-16 sm:py-20 lg:py-24 bg-gradient-to-br from-slate-50 via-blue-50 to-purple-50 relative overflow-hidden">
      <!-- Subtle pattern background (hidden on mobile) -->
      <div class="absolute inset-0 opacity-30 hidden sm:block">
        <div class="absolute top-20 left-20 w-32 h-32 bg-gradient-to-br from-blue-200 to-purple-200 rounded-2xl rotate-12 opacity-50"></div>
        <div class="absolute bottom-20 right-20 w-24 h-24 bg-gradient-to-br from-purple-200 to-blue-200 rounded-xl -rotate-12 opacity-50"></div>
        <div class="absolute top-1/2 left-1/3 w-16 h-16 bg-blue-100 rounded-lg rotate-45 opacity-40"></div>
      </div>
      
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 relative">
        <div class="text-center">
          <!-- Large, prominent logo display -->
          <div class="flex justify-center mb-8 sm:mb-12">
            <div class="relative">
              <img 
                src="/CardStudioLogo.png" 
                alt="CardStudio" 
                class="h-24 sm:h-32 md:h-48 lg:h-60 w-auto drop-shadow-2xl"
              />
              <!-- Subtle glow effect -->
              <div class="absolute inset-0 bg-gradient-to-r from-blue-400/20 to-purple-400/20 rounded-lg blur-2xl -z-10 scale-110"></div>
            </div>
          </div>
          
          <div class="max-w-4xl mx-auto">
            <h2 class="text-2xl sm:text-3xl md:text-4xl lg:text-5xl font-bold text-slate-900 mb-4 sm:mb-6 px-4">
              Revolutionizing Visitor Experiences
            </h2>
            <p class="text-base sm:text-lg md:text-xl lg:text-2xl text-slate-600 mb-8 sm:mb-12 leading-relaxed px-4">
              CardStudio combines the charm of physical souvenirs with cutting-edge AI technology, 
              creating unforgettable digital experiences for museums, attractions, and cultural sites worldwide.
            </p>
            
            <!-- Feature highlights -->
            <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4 sm:gap-6 lg:gap-8 px-4">
              <div class="bg-white/70 backdrop-blur-sm rounded-xl sm:rounded-2xl p-4 sm:p-6 border border-white/50 shadow-lg">
                <div class="w-10 sm:w-12 h-10 sm:h-12 bg-gradient-to-r from-blue-500 to-blue-600 rounded-lg sm:rounded-xl flex items-center justify-center mb-3 sm:mb-4 mx-auto">
                  <i class="pi pi-qrcode text-white text-lg sm:text-xl"></i>
                </div>
                <h3 class="text-base sm:text-lg font-semibold text-slate-900 mb-1 sm:mb-2">Smart QR Integration</h3>
                <p class="text-slate-600 text-xs sm:text-sm">Seamless card-to-digital experience</p>
              </div>
              
              <div class="bg-white/70 backdrop-blur-sm rounded-xl sm:rounded-2xl p-4 sm:p-6 border border-white/50 shadow-lg">
                <div class="w-10 sm:w-12 h-10 sm:h-12 bg-gradient-to-r from-purple-500 to-purple-600 rounded-lg sm:rounded-xl flex items-center justify-center mb-3 sm:mb-4 mx-auto">
                  <i class="pi pi-microphone text-white text-lg sm:text-xl"></i>
                </div>
                <h3 class="text-base sm:text-lg font-semibold text-slate-900 mb-1 sm:mb-2">AI Voice Guide</h3>
                <p class="text-slate-600 text-xs sm:text-sm">Natural conversations in 5 languages</p>
              </div>
              
              <div class="bg-white/70 backdrop-blur-sm rounded-xl sm:rounded-2xl p-4 sm:p-6 border border-white/50 shadow-lg sm:col-span-2 lg:col-span-1">
                <div class="w-10 sm:w-12 h-10 sm:h-12 bg-gradient-to-r from-emerald-500 to-emerald-600 rounded-lg sm:rounded-xl flex items-center justify-center mb-3 sm:mb-4 mx-auto">
                  <i class="pi pi-chart-line text-white text-lg sm:text-xl"></i>
                </div>
                <h3 class="text-base sm:text-lg font-semibold text-slate-900 mb-1 sm:mb-2">Rich Analytics</h3>
                <p class="text-slate-600 text-xs sm:text-sm">Deep insights into visitor engagement</p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>


    <!-- How It Works Section -->
    <section id="how-it-works" class="py-16 sm:py-20 lg:py-24 bg-gradient-to-b from-white to-slate-50">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div class="text-center mb-12 sm:mb-16 lg:mb-20">
          <div class="inline-flex items-center gap-2 bg-gradient-to-r from-emerald-100 to-cyan-100 text-emerald-800 px-4 sm:px-6 py-2 sm:py-3 rounded-full text-xs sm:text-sm font-semibold mb-6 sm:mb-8">
            <i class="pi pi-bolt"></i>
            <span>Launch in 3 Simple Steps</span>
          </div>
          <h2 class="text-2xl sm:text-3xl md:text-4xl lg:text-5xl xl:text-6xl font-black text-slate-900 mb-4 sm:mb-6 tracking-tight px-4">
            From Idea to 
            <span class="bg-gradient-to-r from-emerald-600 to-cyan-600 bg-clip-text text-transparent">
              Live Experience
            </span>
          </h2>
          <p class="text-base sm:text-lg lg:text-xl text-slate-600 max-w-3xl mx-auto font-light px-4">
            Transform any venue into an interactive experience destination with our enterprise-grade platform
          </p>
        </div>
        
        <div class="grid grid-cols-1 md:grid-cols-3 gap-6 sm:gap-8 lg:gap-12">
          <!-- Step 1 -->
          <div class="relative group">
            <div class="bg-white rounded-2xl sm:rounded-3xl p-6 sm:p-8 shadow-lg hover:shadow-2xl transition-all duration-500 border border-slate-100 relative overflow-hidden">
              <div class="absolute top-0 left-0 w-full h-1 bg-gradient-to-r from-blue-600 to-purple-600"></div>
              
              <div class="flex items-center justify-between mb-4 sm:mb-6">
                <div class="w-12 sm:w-16 h-12 sm:h-16 bg-gradient-to-br from-blue-100 to-purple-100 rounded-xl sm:rounded-2xl flex items-center justify-center group-hover:scale-110 transition-transform duration-300">
                  <i class="pi pi-palette text-blue-600 text-xl sm:text-2xl"></i>
                </div>
                <div class="w-7 sm:w-8 h-7 sm:h-8 bg-gradient-to-br from-blue-600 to-purple-600 rounded-full flex items-center justify-center text-white font-bold text-sm">1</div>
              </div>
              
              <h3 class="text-lg sm:text-xl lg:text-2xl font-bold text-slate-900 mb-3 sm:mb-4">Design & Configure</h3>
              <p class="text-sm sm:text-base text-slate-600 leading-relaxed">
                Create stunning digital cards with our intuitive design tools. Upload content, configure AI personalities, 
                and customize experiences for your specific venue or event.
              </p>
            </div>
          </div>

          <!-- Step 2 -->
          <div class="relative group">
            <div class="bg-white rounded-3xl p-8 shadow-lg hover:shadow-2xl transition-all duration-500 border border-slate-100 relative overflow-hidden">
              <div class="absolute top-0 left-0 w-full h-1 bg-gradient-to-r from-purple-600 to-pink-600"></div>
              
              <div class="flex items-center justify-between mb-6">
                <div class="w-16 h-16 bg-gradient-to-br from-purple-100 to-pink-100 rounded-2xl flex items-center justify-center group-hover:scale-110 transition-transform duration-300">
                  <i class="pi pi-qrcode text-purple-600 text-2xl"></i>
                </div>
                <div class="w-8 h-8 bg-gradient-to-br from-purple-600 to-pink-600 rounded-full flex items-center justify-center text-white font-bold text-sm">2</div>
              </div>
              
              <h3 class="text-2xl font-bold text-slate-900 mb-4">Deploy & Distribute</h3>
              <p class="text-slate-600 leading-relaxed">
                Generate unique QR codes for each card batch. Order professional physical cards or go fully digital. 
                Your experiences are instantly accessible worldwide.
              </p>
            </div>
          </div>

          <!-- Step 3 -->
          <div class="relative group">
            <div class="bg-white rounded-3xl p-8 shadow-lg hover:shadow-2xl transition-all duration-500 border border-slate-100 relative overflow-hidden">
              <div class="absolute top-0 left-0 w-full h-1 bg-gradient-to-r from-pink-600 to-red-600"></div>
              
              <div class="flex items-center justify-between mb-6">
                <div class="w-16 h-16 bg-gradient-to-br from-pink-100 to-red-100 rounded-2xl flex items-center justify-center group-hover:scale-110 transition-transform duration-300">
                  <i class="pi pi-chart-line text-pink-600 text-2xl"></i>
                </div>
                <div class="w-8 h-8 bg-gradient-to-br from-pink-600 to-red-600 rounded-full flex items-center justify-center text-white font-bold text-sm">3</div>
              </div>
              
              <h3 class="text-2xl font-bold text-slate-900 mb-4">Analyze & Optimize</h3>
              <p class="text-slate-600 leading-relaxed">
                Monitor engagement in real-time with advanced analytics. Track visitor interactions, optimize content performance, 
                and scale your digital souvenir program effortlessly.
              </p>
            </div>
          </div>
        </div>
      </div>
    </section>

    <!-- Key Features Section -->
    <section class="py-20 bg-gradient-to-b from-slate-50 to-white">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div class="text-center mb-16">
          <div class="inline-flex items-center gap-2 bg-gradient-to-r from-violet-100 to-purple-100 text-violet-800 px-6 py-3 rounded-full text-sm font-semibold mb-8">
            <i class="pi pi-shield-check"></i>
            <span>Enterprise-Grade Platform</span>
          </div>
          <h2 class="text-4xl sm:text-5xl lg:text-6xl font-black text-slate-900 mb-6 tracking-tight">
            <span class="bg-gradient-to-r from-violet-600 to-purple-600 bg-clip-text text-transparent">
              Powerful Features
            </span>
            <br />
            Built for Scale
          </h2>
          <p class="text-xl text-slate-600 max-w-3xl mx-auto font-light">
            Everything you need to create, deploy, and manage world-class digital experiences
          </p>
        </div>
        
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
          <!-- Feature 1 -->
          <div class="bg-white rounded-2xl p-8 shadow-sm hover:shadow-lg transition-all duration-300 border border-slate-100 group">
            <div class="w-14 h-14 bg-gradient-to-br from-blue-100 to-blue-200 rounded-xl flex items-center justify-center mb-6 group-hover:scale-110 transition-transform">
              <i class="pi pi-id-card text-blue-600 text-2xl"></i>
            </div>
            <h3 class="text-xl font-semibold text-slate-900 mb-3">Premium Collectible Souvenirs</h3>
            <p class="text-slate-600 leading-relaxed">
              Offer beautifully designed, QR-enabled physical cards that link directly to digital content. 
              These lasting souvenirs drive revenue and encourage repeat visits.
            </p>
          </div>

          <!-- Feature 2 -->
          <div class="bg-white rounded-2xl p-8 shadow-sm hover:shadow-lg transition-all duration-300 border border-slate-100 group">
            <div class="w-14 h-14 bg-gradient-to-br from-purple-100 to-purple-200 rounded-xl flex items-center justify-center mb-6 group-hover:scale-110 transition-transform">
              <i class="pi pi-microphone text-purple-600 text-2xl"></i>
            </div>
            <h3 class="text-xl font-semibold text-slate-900 mb-3">Conversational AI Guide</h3>
            <p class="text-slate-600 leading-relaxed">
              Engage visitors with a real-time, voice-based AI guide. Powered by the latest OpenAI technology, 
              it offers natural, low-latency conversations in multiple languages.
            </p>
          </div>

          <!-- Feature 3 -->
          <div class="bg-white rounded-2xl p-8 shadow-sm hover:shadow-lg transition-all duration-300 border border-slate-100 group">
            <div class="w-14 h-14 bg-gradient-to-br from-blue-100 to-blue-200 rounded-xl flex items-center justify-center mb-6 group-hover:scale-110 transition-transform">
              <i class="pi pi-mobile text-blue-600 text-2xl"></i>
            </div>
            <h3 class="text-xl font-semibold text-slate-900 mb-3">Instant, No-App Access</h3>
            <p class="text-slate-600 leading-relaxed">
              Visitors scan a simple QR code to begin their journey immediately. By removing the friction of app downloads, 
              you maximize adoption and ensure a smooth user experience.
            </p>
          </div>

          <!-- Feature 4 -->
          <div class="bg-white rounded-2xl p-8 shadow-sm hover:shadow-lg transition-all duration-300 border border-slate-100 group">
            <div class="w-14 h-14 bg-gradient-to-br from-orange-100 to-orange-200 rounded-xl flex items-center justify-center mb-6 group-hover:scale-110 transition-transform">
              <i class="pi pi-globe text-orange-600 text-2xl"></i>
            </div>
            <h3 class="text-xl font-semibold text-slate-900 mb-3">Multilingual Support</h3>
            <p class="text-slate-600 leading-relaxed">
              Break down language barriers instantly. Our AI currently supports natural conversations in English, 
              Cantonese, Mandarin, Spanish, and French.
            </p>
          </div>

          <!-- Feature 5 -->
          <div class="bg-white rounded-2xl p-8 shadow-sm hover:shadow-lg transition-all duration-300 border border-slate-100 group">
            <div class="w-14 h-14 bg-gradient-to-br from-red-100 to-red-200 rounded-xl flex items-center justify-center mb-6 group-hover:scale-110 transition-transform">
              <i class="pi pi-cog text-red-600 text-2xl"></i>
            </div>
            <h3 class="text-xl font-semibold text-slate-900 mb-3">Zero Hardware Required</h3>
            <p class="text-slate-600 leading-relaxed">
              CardStudio leverages the smartphones your visitors already carry. No need for expensive, high-maintenance 
              audio guide hardware or complex venue infrastructure.
            </p>
          </div>

          <!-- Feature 6 -->
          <div class="bg-white rounded-2xl p-8 shadow-sm hover:shadow-lg transition-all duration-300 border border-slate-100 group">
            <div class="w-14 h-14 bg-gradient-to-br from-indigo-100 to-indigo-200 rounded-xl flex items-center justify-center mb-6 group-hover:scale-110 transition-transform">
              <i class="pi pi-chart-bar text-indigo-600 text-2xl"></i>
            </div>
            <h3 class="text-xl font-semibold text-slate-900 mb-3">Powerful Analytics</h3>
            <p class="text-slate-600 leading-relaxed">
              Manage your content, view real-time analytics, issue new card batches, and request printing all from 
              one intuitive, self-service platform.
            </p>
          </div>
        </div>
      </div>
    </section>

    <!-- Use Cases Section -->
    <section class="py-24 bg-gradient-to-b from-white to-slate-50">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div class="text-center mb-20">
          <div class="inline-flex items-center gap-2 bg-gradient-to-r from-amber-100 to-orange-100 text-amber-800 px-6 py-3 rounded-full text-sm font-semibold mb-8">
            <i class="pi pi-globe"></i>
            <span>Versatile Applications</span>
          </div>
          <h2 class="text-4xl sm:text-5xl lg:text-6xl font-black text-slate-900 mb-6 tracking-tight">
            Perfect for
            <span class="bg-gradient-to-r from-amber-600 to-orange-600 bg-clip-text text-transparent">
              Any Experience
            </span>
          </h2>
          <p class="text-xl text-slate-600 max-w-4xl mx-auto font-light">
            From cultural institutions to corporate events, theme parks to conferences — CardStudio transforms 
            any venue into an interactive destination that visitors remember
          </p>
        </div>
        
        <!-- First Row: 3 Cards -->
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8 mb-8">
          <!-- Use Case 1 -->
          <div class="group cursor-pointer">
            <div class="bg-white rounded-xl overflow-hidden shadow-lg hover:shadow-xl transition-all duration-300 group-hover:-translate-y-1">
              <div class="h-48 bg-gradient-to-br from-blue-500 to-purple-600 relative overflow-hidden">
                <img 
                  :src="featureImage1Url" 
                  alt="Museums & Art Galleries" 
                  class="w-full h-full object-cover group-hover:scale-110 transition-transform duration-300"
                />
                <div class="absolute inset-0 bg-gradient-to-t from-black/50 to-transparent"></div>
                <div class="absolute bottom-4 left-4 text-white">
                  <i class="pi pi-building text-2xl"></i>
                </div>
              </div>
              <div class="p-6">
                <h3 class="text-xl font-bold text-slate-900 mb-3">Museums & Art Galleries</h3>
                <p class="text-slate-600">
                  Bring artifacts and collections to life with AI-powered explanations and detailed multimedia content.
                </p>
              </div>
            </div>
          </div>

          <!-- Use Case 2 -->
          <div class="group cursor-pointer">
            <div class="bg-white rounded-xl overflow-hidden shadow-lg hover:shadow-xl transition-all duration-300 group-hover:-translate-y-1">
              <div class="h-48 bg-gradient-to-br from-blue-500 to-blue-600 relative overflow-hidden">
                <img 
                  :src="featureImage2Url" 
                  alt="Tourist Attractions" 
                  class="w-full h-full object-cover group-hover:scale-110 transition-transform duration-300"
                />
                <div class="absolute inset-0 bg-gradient-to-t from-black/50 to-transparent"></div>
                <div class="absolute bottom-4 left-4 text-white">
                  <i class="pi pi-map-marker text-2xl"></i>
                </div>
              </div>
              <div class="p-4 sm:p-6">
                <h3 class="text-lg sm:text-xl font-bold text-slate-900 mb-2 sm:mb-3">Tourist Attractions & Landmarks</h3>
                <p class="text-sm sm:text-base text-slate-600">
                  Offer rich historical context and multi-language AI guidance for scenic spots and historical narratives.
                </p>
              </div>
            </div>
          </div>

          <!-- Use Case 3 -->
          <div class="group cursor-pointer">
            <div class="bg-white rounded-lg sm:rounded-xl overflow-hidden shadow-lg hover:shadow-xl transition-all duration-300 group-hover:-translate-y-1">
              <div class="h-40 sm:h-48 bg-gradient-to-br from-purple-500 to-pink-600 relative overflow-hidden">
                <img 
                  :src="featureImage3Url" 
                  alt="Cultural Heritage" 
                  class="w-full h-full object-cover group-hover:scale-110 transition-transform duration-300"
                />
                <div class="absolute inset-0 bg-gradient-to-t from-black/50 to-transparent"></div>
                <div class="absolute bottom-3 sm:bottom-4 left-3 sm:left-4 text-white">
                  <i class="pi pi-star text-xl sm:text-2xl"></i>
                </div>
              </div>
              <div class="p-4 sm:p-6">
                <h3 class="text-lg sm:text-xl font-bold text-slate-900 mb-2 sm:mb-3">Cultural Heritage Sites</h3>
                <p class="text-sm sm:text-base text-slate-600">
                  Preserve and interpret cultural significance through immersive, AI-driven storytelling.
                </p>
              </div>
            </div>
          </div>
        </div>

        <!-- Second Row: 3 Cards -->
        <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6 sm:gap-8">
          <!-- Use Case 4 -->
          <div class="group cursor-pointer">
            <div class="bg-white rounded-lg sm:rounded-xl overflow-hidden shadow-lg hover:shadow-xl transition-all duration-300 group-hover:-translate-y-1">
              <div class="h-40 sm:h-48 bg-gradient-to-br from-orange-500 to-red-600 relative overflow-hidden">
                <img 
                  :src="featureImage4Url" 
                  alt="Exhibition Centers" 
                  class="w-full h-full object-cover group-hover:scale-110 transition-transform duration-300"
                />
                <div class="absolute inset-0 bg-gradient-to-t from-black/50 to-transparent"></div>
                <div class="absolute bottom-3 sm:bottom-4 left-3 sm:left-4 text-white">
                  <i class="pi pi-calendar text-xl sm:text-2xl"></i>
                </div>
              </div>
              <div class="p-4 sm:p-6">
                <h3 class="text-lg sm:text-xl font-bold text-slate-900 mb-2 sm:mb-3">Exhibition Centers & Trade Shows</h3>
                <p class="text-sm sm:text-base text-slate-600">
                  Provide attendees with interactive schedules, speaker bios, and exhibitor information on a collectible card.
                </p>
              </div>
            </div>
          </div>

          <!-- Use Case 5 -->
          <div class="group cursor-pointer">
            <div class="bg-white rounded-lg sm:rounded-xl overflow-hidden shadow-lg hover:shadow-xl transition-all duration-300 group-hover:-translate-y-1">
              <div class="h-40 sm:h-48 bg-gradient-to-br from-pink-500 to-purple-600 relative overflow-hidden">
                <img 
                  :src="featureImage5Url" 
                  alt="Theme Parks" 
                  class="w-full h-full object-cover group-hover:scale-110 transition-transform duration-300"
                />
                <div class="absolute inset-0 bg-gradient-to-t from-black/50 to-transparent"></div>
                <div class="absolute bottom-3 sm:bottom-4 left-3 sm:left-4 text-white">
                  <i class="pi pi-sparkles text-xl sm:text-2xl"></i>
                </div>
              </div>
              <div class="p-4 sm:p-6">
                <h3 class="text-lg sm:text-xl font-bold text-slate-900 mb-2 sm:mb-3">Theme Parks & Entertainment Venues</h3>
                <p class="text-sm sm:text-base text-slate-600">
                  Create collectible digital souvenirs with behind-the-scenes content and AI character interactions.
                </p>
              </div>
            </div>
          </div>

          <!-- Use Case 6 -->
          <div class="group cursor-pointer">
            <div class="bg-white rounded-lg sm:rounded-xl overflow-hidden shadow-lg hover:shadow-xl transition-all duration-300 group-hover:-translate-y-1">
              <div class="h-40 sm:h-48 bg-gradient-to-br from-indigo-500 to-blue-600 relative overflow-hidden">
                <img 
                  :src="featureImage6Url" 
                  alt="Events" 
                  class="w-full h-full object-cover group-hover:scale-110 transition-transform duration-300"
                />
                <div class="absolute inset-0 bg-gradient-to-t from-black/50 to-transparent"></div>
                <div class="absolute bottom-3 sm:bottom-4 left-3 sm:left-4 text-white">
                  <i class="pi pi-users text-xl sm:text-2xl"></i>
                </div>
              </div>
              <div class="p-4 sm:p-6">
                <h3 class="text-lg sm:text-xl font-bold text-slate-900 mb-2 sm:mb-3">Event Organizers</h3>
                <p class="text-sm sm:text-base text-slate-600">
                  Provide attendees with interactive schedules, speaker bios, and exhibitor information on a collectible card.
                </p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>

    <!-- Pricing Section -->
    <section class="py-16 sm:py-20 lg:py-24 bg-gradient-to-br from-slate-900 via-blue-900 to-slate-900 text-white relative overflow-hidden">
      <!-- Background decoration (reduced on mobile) -->
      <div class="absolute inset-0 hidden sm:block">
        <div class="absolute top-0 left-1/4 w-96 h-96 bg-blue-500/10 rounded-full blur-3xl"></div>
        <div class="absolute bottom-0 right-1/4 w-96 h-96 bg-purple-500/10 rounded-full blur-3xl"></div>
        <div class="absolute top-1/2 left-1/2 transform -translate-x-1/2 -translate-y-1/2 w-[800px] h-[800px] bg-gradient-to-r from-blue-600/5 to-purple-600/5 rounded-full blur-3xl"></div>
      </div>
      
      <div class="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8 relative">
        <div class="text-center mb-12 sm:mb-16 lg:mb-20">
          <div class="inline-flex items-center gap-2 bg-gradient-to-r from-blue-600 to-blue-700 text-white px-4 sm:px-6 py-2 sm:py-3 rounded-full text-xs sm:text-sm font-semibold mb-6 sm:mb-8 shadow-lg">
            <i class="pi pi-dollar"></i>
            <span>Transparent Pricing</span>
          </div>
          <h2 class="text-2xl sm:text-3xl md:text-4xl lg:text-5xl xl:text-6xl font-black mb-4 sm:mb-6 tracking-tight px-4">
            <span class="bg-gradient-to-r from-blue-400 to-blue-500 bg-clip-text text-transparent">
              Simple Pricing
            </span>
            <br />
            That Scales With You
          </h2>
          <p class="text-base sm:text-lg lg:text-xl text-slate-300 max-w-4xl mx-auto font-light px-4">
            No complex contracts or hidden costs. Pay only for what you use as you grow your digital souvenir program.
          </p>
        </div>

        <!-- Main Pricing Card -->
        <div class="max-w-4xl mx-auto">
          <div class="bg-white/10 backdrop-blur-md rounded-2xl sm:rounded-3xl p-6 sm:p-8 md:p-12 border border-white/20 shadow-2xl">
            <div class="grid grid-cols-1 lg:grid-cols-2 gap-8 sm:gap-12 items-center">
              
              <!-- Pricing Info -->
              <div class="text-center lg:text-left">
                <div class="inline-flex items-center gap-2 bg-blue-500/20 text-blue-300 px-3 sm:px-4 py-2 rounded-full text-xs sm:text-sm font-medium mb-4 sm:mb-6">
                  <i class="pi pi-check-circle"></i>
                  Pay-per-card pricing
                </div>
                
                <div class="mb-4 sm:mb-6">
                  <div class="flex items-baseline justify-center lg:justify-start gap-2">
                    <span class="text-4xl sm:text-5xl md:text-6xl lg:text-7xl font-bold bg-gradient-to-r from-blue-400 to-purple-400 bg-clip-text text-transparent">
                      $2
                    </span>
                    <span class="text-lg sm:text-xl md:text-2xl text-slate-400">USD</span>
                  </div>
                  <p class="text-base sm:text-lg lg:text-xl text-slate-300 mt-1 sm:mt-2">per card, per batch</p>
                </div>

                <div class="space-y-3 sm:space-y-4 text-slate-300">
                  <div class="flex items-center gap-3 justify-center lg:justify-start">
                    <div class="w-2 h-2 bg-blue-400 rounded-full"></div>
                    <span class="text-sm sm:text-base">No monthly subscriptions</span>
                  </div>
                  <div class="flex items-center gap-3 justify-center lg:justify-start">
                    <div class="w-2 h-2 bg-purple-400 rounded-full"></div>
                    <span class="text-sm sm:text-base">No setup or platform fees</span>
                  </div>
                  <div class="flex items-center gap-3 justify-center lg:justify-start">
                    <div class="w-2 h-2 bg-blue-400 rounded-full"></div>
                    <span class="text-sm sm:text-base">Pay only when you issue cards</span>
                  </div>
                </div>
              </div>

              <!-- Features -->
              <div class="space-y-4 sm:space-y-6">
                <h3 class="text-xl sm:text-2xl font-bold mb-4 sm:mb-6 text-center lg:text-left">Everything Included</h3>
                
                <div class="grid grid-cols-1 gap-3 sm:gap-4">
                  <div class="flex items-center gap-3">
                    <i class="pi pi-check text-blue-400 text-lg"></i>
                    <span class="text-slate-300 text-sm sm:text-base">AI voice conversations</span>
                  </div>
                  <div class="flex items-center gap-3">
                    <i class="pi pi-check text-blue-400 text-lg"></i>
                    <span class="text-slate-300 text-sm sm:text-base">Multi-language support</span>
                  </div>
                  <div class="flex items-center gap-3">
                    <i class="pi pi-check text-blue-400 text-lg"></i>
                    <span class="text-slate-300 text-sm sm:text-base">Design dashboard</span>
                  </div>
                  <div class="flex items-center gap-3">
                    <i class="pi pi-check text-blue-400 text-lg"></i>
                    <span class="text-slate-300 text-sm sm:text-base">Real-time analytics</span>
                  </div>
                  <div class="flex items-center gap-3">
                    <i class="pi pi-check text-blue-400 text-lg"></i>
                    <span class="text-slate-300 text-sm sm:text-base">QR code generation</span>
                  </div>
                  <div class="flex items-center gap-3">
                    <i class="pi pi-check text-blue-400 text-lg"></i>
                    <span class="text-slate-300 text-sm sm:text-base">Print management</span>
                  </div>
                  <div class="flex items-center gap-3">
                    <i class="pi pi-check text-blue-400 text-lg"></i>
                    <span class="text-slate-300 text-sm sm:text-base">Cloud hosting</span>
                  </div>
                  <div class="flex items-center gap-3">
                    <i class="pi pi-check text-blue-400 text-lg"></i>
                    <span class="text-slate-300 text-sm sm:text-base">24/7 support</span>
                  </div>
                </div>
              </div>
            </div>

            <!-- CTA Section -->
            <div class="mt-8 sm:mt-12 pt-6 sm:pt-8 border-t border-white/20">
              <div class="text-center">
                <p class="text-slate-300 mb-4 sm:mb-6 text-sm sm:text-base">Ready to create your first AI-powered souvenir experience?</p>
                <div class="flex flex-col sm:flex-row gap-3 sm:gap-4 justify-center">
                  <Button 
                    label="Start Free Pilot" 
                    icon="pi pi-arrow-right"
                    iconPos="right"
                    @click="router.push('/signup')"
                    class="bg-gradient-to-r from-blue-600 to-purple-600 hover:from-blue-700 hover:to-purple-700 border-0 px-6 sm:px-8 py-3 sm:py-4 text-base sm:text-lg font-bold shadow-xl hover:shadow-2xl transition-all"
                  />
                  <Button 
                    label="Schedule Demo" 
                    icon="pi pi-calendar"
                    outlined
                    @click="openContactModal"
                    class="border-2 border-white/30 text-white hover:bg-white/10 px-6 sm:px-8 py-3 sm:py-4 text-base sm:text-lg transition-all"
                  />
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- Additional Info -->
        <div class="mt-12 sm:mt-16 text-center">
          <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6 sm:gap-8">
            <div class="flex flex-col items-center">
              <div class="w-14 sm:w-16 h-14 sm:h-16 bg-blue-500/20 rounded-full flex items-center justify-center mb-3 sm:mb-4">
                <i class="pi pi-shield-check text-blue-400 text-xl sm:text-2xl"></i>
              </div>
              <h4 class="text-base sm:text-lg font-semibold mb-1 sm:mb-2">Secure & Reliable</h4>
              <p class="text-slate-400 text-xs sm:text-sm">Enterprise-grade security with cloud infrastructure</p>
            </div>
            
            <div class="flex flex-col items-center">
              <div class="w-14 sm:w-16 h-14 sm:h-16 bg-purple-500/20 rounded-full flex items-center justify-center mb-3 sm:mb-4">
                <i class="pi pi-users text-purple-400 text-xl sm:text-2xl"></i>
              </div>
              <h4 class="text-base sm:text-lg font-semibold mb-1 sm:mb-2">Dedicated Support</h4>
              <p class="text-slate-400 text-xs sm:text-sm">Expert team available to help you succeed</p>
            </div>
            
            <div class="flex flex-col items-center sm:col-span-2 lg:col-span-1">
              <div class="w-14 sm:w-16 h-14 sm:h-16 bg-blue-500/20 rounded-full flex items-center justify-center mb-3 sm:mb-4">
                <i class="pi pi-bolt text-blue-400 text-xl sm:text-2xl"></i>
              </div>
              <h4 class="text-base sm:text-lg font-semibold mb-1 sm:mb-2">Quick Setup</h4>
              <p class="text-slate-400 text-xs sm:text-sm">Launch your first card experience in minutes</p>
            </div>
          </div>
        </div>
      </div>
    </section>

    <!-- FAQ Section -->
    <section class="py-16 sm:py-20 bg-slate-50">
      <div class="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8">
        <div class="text-center mb-12 sm:mb-16">
          <h2 class="text-2xl sm:text-3xl lg:text-4xl font-bold text-slate-900 mb-4 px-4">
            Your Questions Answered
          </h2>
          <div class="w-24 h-1 bg-gradient-to-r from-blue-600 to-purple-600 mx-auto"></div>
        </div>
        
        <div class="space-y-4">
          <div 
            v-for="(faq, index) in faqs" 
            :key="index"
            class="bg-white rounded-xl shadow-lg overflow-hidden"
          >
            <button
              @click="toggleFaq(index)"
              class="w-full p-6 text-left flex items-center justify-between hover:bg-slate-50 transition-colors duration-200"
            >
              <h3 class="text-lg font-semibold text-slate-900 pr-4">{{ faq.question }}</h3>
              <i 
                :class="['pi', openFaqIndex === index ? 'pi-chevron-up' : 'pi-chevron-down', 'text-slate-500 transition-transform duration-200']"
              ></i>
            </button>
            <div 
              v-show="openFaqIndex === index"
              class="px-6 pb-6 text-slate-600 leading-relaxed"
              v-html="faq.answer"
            ></div>
          </div>
        </div>
      </div>
    </section>

    <!-- CTA Section -->
    <section class="py-24 bg-gradient-to-br from-blue-600 via-purple-600 to-pink-600 text-white relative overflow-hidden">
      <!-- Background effects -->
      <div class="absolute inset-0">
        <div class="absolute top-0 left-0 w-full h-full bg-gradient-to-br from-blue-600/20 via-purple-600/20 to-pink-600/20"></div>
        <div class="absolute top-1/4 left-1/4 w-96 h-96 bg-white/5 rounded-full blur-3xl"></div>
        <div class="absolute bottom-1/4 right-1/4 w-96 h-96 bg-white/5 rounded-full blur-3xl"></div>
      </div>
      
      <div class="max-w-5xl mx-auto px-4 sm:px-6 lg:px-8 text-center relative">
        <div class="mb-12">
          <div class="inline-flex items-center gap-2 bg-white/20 backdrop-blur-md text-white px-6 py-3 rounded-full text-sm font-semibold mb-8">
            <i class="pi pi-rocket"></i>
            <span>Ready to Launch?</span>
          </div>
          
          <h2 class="text-4xl sm:text-5xl lg:text-6xl font-black mb-6 tracking-tight">
            Transform Your
            <br />
            <span class="bg-gradient-to-r from-yellow-300 to-orange-300 bg-clip-text text-transparent">
              Experience Today
            </span>
          </h2>
          
          <p class="text-xl text-white/90 mb-12 max-w-3xl mx-auto font-light">
            Join the digital revolution. Create AI-powered souvenirs that your visitors will treasure forever.
          </p>
        </div>
        
        <div class="flex flex-col sm:flex-row gap-6 justify-center mb-12">
          <Button 
            label="Launch Your Platform" 
            icon="pi pi-arrow-right"
            iconPos="right"
            @click="router.push('/signup')"
            class="bg-white text-blue-600 hover:bg-blue-50 border-0 px-10 py-5 text-lg font-bold shadow-2xl hover:shadow-3xl transition-all rounded-xl"
          />
          <Button 
            label="Schedule Enterprise Demo" 
            icon="pi pi-calendar"
            outlined
            @click="openContactModal"
            class="border-2 border-white/50 text-white hover:bg-white/10 backdrop-blur-sm px-10 py-5 text-lg font-semibold transition-all rounded-xl"
          />
        </div>
        
        <!-- Enterprise trust indicators -->
        <div class="flex flex-wrap justify-center gap-8 items-center text-sm text-white/80">
          <div class="flex items-center gap-2">
            <i class="pi pi-shield-check text-blue-300"></i>
            <span>Enterprise Security</span>
          </div>
          <div class="flex items-center gap-2">
            <i class="pi pi-users text-blue-300"></i>
            <span>24/7 Support</span>
          </div>
          <div class="flex items-center gap-2">
            <i class="pi pi-verified text-purple-300"></i>
            <span>99.9% Uptime</span>
          </div>
        </div>
      </div>
    </section>

    <!-- Footer -->
    <footer class="bg-slate-900 text-white py-16">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div class="grid grid-cols-1 md:grid-cols-2 gap-8">
          <!-- Brand -->
          <div class="space-y-4">
            <div class="flex items-center">
              <img 
                src="/CardStudioLogo.png" 
                alt="CardStudio" 
                class="h-12 w-auto opacity-90 hover:opacity-100 transition-opacity"
                style="filter: brightness(0) invert(1);"
              />
            </div>
            <p class="text-slate-400 max-w-sm">
              Transforming visitor experiences through AI-powered digital souvenirs and interactive cultural engagement.
            </p>
          </div>

          <!-- Contact -->
          <div>
            <h4 class="font-bold text-lg mb-4">Contact Us</h4>
            <div class="space-y-3">
              <div class="flex items-center">
                <i class="pi pi-envelope text-blue-400 mr-3"></i>
                <a :href="`mailto:${contactEmail}`" class="text-slate-400 hover:text-white transition-colors">{{ contactEmail }}</a>
              </div>
              <div class="flex items-center">
                <i class="pi pi-phone text-purple-400 mr-3"></i>
                <a :href="`tel:${contactPhone}`" class="text-slate-400 hover:text-white transition-colors">{{ contactPhone }}</a>
              </div>
              <div class="flex items-center">
                <i class="pi pi-whatsapp text-green-400 mr-3"></i>
                <a :href="contactWhatsApp" class="text-slate-400 hover:text-white transition-colors">WhatsApp Chat</a>
              </div>
            </div>
          </div>
        </div>

        <div class="border-t border-slate-700 mt-12 pt-8 flex flex-col md:flex-row justify-between items-center">
          <p class="text-slate-400 text-sm">
            © 2025 CardStudio. All rights reserved.
          </p>
          <div class="flex space-x-6 mt-4 md:mt-0">
            <a @click="scrollToSection('features')" class="text-slate-400 hover:text-white text-sm transition-colors cursor-pointer">Features</a>
            <a @click="scrollToSection('pricing')" class="text-slate-400 hover:text-white text-sm transition-colors cursor-pointer">Pricing</a>
            <a @click="openContactModal" class="text-slate-400 hover:text-white text-sm transition-colors cursor-pointer">Contact</a>
          </div>
        </div>
      </div>
    </footer>

    <!-- Contact Modal -->
    <Dialog 
      v-model:visible="showContactModal" 
      header="Contact Our Team" 
      :modal="true" 
      :closable="true"
      style="width: 90vw; max-width: 500px;"
    >
      <div class="space-y-6">
        <p class="text-slate-600">
          Ready to learn more about how CardStudio can transform your visitor experience? 
          Get in touch with our team today.
        </p>
        
        <div class="space-y-4">
          <div class="flex items-center p-4 bg-blue-50 rounded-lg">
            <i class="pi pi-envelope text-blue-600 text-xl mr-4"></i>
            <div>
              <h4 class="font-semibold text-slate-900">Email</h4>
              <a :href="`mailto:${contactEmail}`" class="text-blue-600 hover:underline">{{ contactEmail }}</a>
            </div>
          </div>
          
          <div class="flex items-center p-4 bg-green-50 rounded-lg">
            <i class="pi pi-whatsapp text-green-600 text-xl mr-4"></i>
            <div>
              <h4 class="font-semibold text-slate-900">WhatsApp</h4>
              <a :href="contactWhatsApp" class="text-green-600 hover:underline">{{ contactWhatsAppDisplay }}</a>
            </div>
          </div>
          
          <div class="flex items-center p-4 bg-purple-50 rounded-lg">
            <i class="pi pi-phone text-purple-600 text-xl mr-4"></i>
            <div>
              <h4 class="font-semibold text-slate-900">Phone</h4>
              <a :href="`tel:${contactPhone}`" class="text-purple-600 hover:underline">{{ contactPhone }}</a>
            </div>
          </div>
        </div>

        <div class="flex gap-3">
          <Button 
            label="Start Free Pilot" 
            @click="() => { showContactModal = false; router.push('/signup'); }"
            class="flex-1 bg-gradient-to-r from-blue-600 to-purple-600 hover:from-blue-700 hover:to-purple-700 border-0"
          />
          <Button 
            label="Close" 
            outlined 
            @click="showContactModal = false"
            class="flex-1"
          />
        </div>
      </div>
    </Dialog>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'
import { useRouter } from 'vue-router'
import { useI18n } from 'vue-i18n'
import Button from 'primevue/button'
import Dialog from 'primevue/dialog'
import QrCode from 'qrcode.vue'
import { useAuthStore } from '@/stores/auth'
import { useToast } from 'primevue/usetoast'

const { t } = useI18n()

const router = useRouter()
const authStore = useAuthStore()
const toast = useToast()

// Sample QR code URL for demonstration
const sampleQrUrl = ref(import.meta.env.VITE_SAMPLE_QR_URL || `${window.location.origin}/c/demo-ancient-artifacts`)

// Contact modal
const showContactModal = ref(false)

// Contact information from environment variables
const contactEmail = import.meta.env.VITE_CONTACT_EMAIL || 'support@cardstudio.com'
const contactWhatsApp = import.meta.env.VITE_CONTACT_WHATSAPP_URL || 'https://wa.me/852xxxxxx'
const contactPhone = import.meta.env.VITE_CONTACT_PHONE || '+852 xxxxxx'
const contactWhatsAppDisplay = import.meta.env.VITE_CONTACT_WHATSAPP_DISPLAY || contactPhone


// Demo card configuration from environment variables
const demoCardTitle = import.meta.env.VITE_DEMO_CARD_TITLE || 'Ancient Artifacts'
const demoCardSubtitle = import.meta.env.VITE_DEMO_CARD_SUBTITLE || 'Interactive Museum Guide'
const demoCardDescription = import.meta.env.VITE_DEMO_CARD_DESCRIPTION || 'Scan the QR code to experience our AI guide'

// QR code configuration
const qrCodeSize = parseInt(import.meta.env.VITE_QR_CODE_SIZE) || 56
const qrCodePosition = import.meta.env.VITE_QR_CODE_POSITION || 'bottom-right' // bottom-left, bottom-right, top-left, top-right

// Computed QR code position classes
const qrPositionClasses = computed(() => {
  const positions = {
    'bottom-right': 'bottom-4 right-4',
    'bottom-left': 'bottom-4 left-4',
    'top-right': 'top-4 right-4',
    'top-left': 'top-4 left-4'
  }
  return positions[qrCodePosition] || positions['bottom-right']
})

// Computed QR container styles
const qrContainerStyle = computed(() => {
  const containerSize = qrCodeSize + 8 // 4px padding on each side
  return {
    width: `${containerSize}px`,
    height: `${containerSize}px`
  }
})

// Computed animation ring styles
const qrRingStyle = computed(() => {
  const ringSize = qrCodeSize + 8
  return {
    width: `${ringSize}px`,
    height: `${ringSize}px`
  }
})

// Image URLs from environment variables
const demoCardImageUrl = import.meta.env.VITE_DEFAULT_CARD_IMAGE_URL || 'https://images.unsplash.com/photo-1564399580075-5dfe19c205f3?w=400&h=600&fit=crop&crop=center'
const featureImage1Url = import.meta.env.VITE_FEATURE_IMAGE_1_URL || 'https://images.unsplash.com/photo-1564399580075-5dfe19c205f3?w=400&h=300&fit=crop'
const featureImage2Url = import.meta.env.VITE_FEATURE_IMAGE_2_URL || 'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=400&h=300&fit=crop'
const featureImage3Url = import.meta.env.VITE_FEATURE_IMAGE_3_URL || 'https://images.unsplash.com/photo-1578662996442-48f60103fc96?w=400&h=300&fit=crop'
const featureImage4Url = import.meta.env.VITE_FEATURE_IMAGE_4_URL || 'https://images.unsplash.com/photo-1540575467063-178a50c2df87?w=400&h=300&fit=crop'
const featureImage5Url = import.meta.env.VITE_FEATURE_IMAGE_5_URL || 'https://images.unsplash.com/photo-1557804506-669a67965ba0?w=400&h=300&fit=crop'
const featureImage6Url = import.meta.env.VITE_FEATURE_IMAGE_6_URL || 'https://images.unsplash.com/photo-1529156069898-49953e39b3ac?w=400&h=300&fit=crop'

// FAQ functionality
const openFaqIndex = ref(-1)

const toggleFaq = (index) => {
  openFaqIndex.value = openFaqIndex.value === index ? -1 : index
}

const openContactModal = () => {
  showContactModal.value = true
}

const scrollToSection = (sectionId) => {
  const element = document.getElementById(sectionId)
  if (element) {
    element.scrollIntoView({ behavior: 'smooth' })
  }
}

const scrollToCard = () => {
  // Scroll to demo card and add attention animation
  const cardElement = document.querySelector('.card-shimmer')
  if (cardElement) {
    cardElement.scrollIntoView({ behavior: 'smooth', block: 'center' })
    // Add temporary attention effect
    cardElement.style.transform = 'scale(1.1)'
    setTimeout(() => {
      cardElement.style.transform = ''
    }, 1000)
  }
}

const openDemoCard = () => {
  // Navigate to the exact same URL as the QR code
  window.location.href = sampleQrUrl.value
}

const handleOrganizerDemo = async () => {
  // Check if user is authenticated
  if (!authStore.session?.user) {
    // Show friendly signup prompt
    toast.add({
      severity: 'info',
      summary: 'Get Started',
      detail: 'Sign up to access the card issuer portal',
      life: 5000
    })
    router.push('/signup')
    return
  }

  // Check if user has card issuer role
  const userRole = authStore.session.user.user_metadata?.role
  if (userRole !== 'cardIssuer') {
    toast.add({
      severity: 'warn',
      summary: 'Access Required',
      detail: 'Please complete your organizer profile setup to create cards',
      life: 5000
    })
    router.push('/signup')
    return
  }

  // User is authenticated and has proper role, go to card issuer portal
  router.push('/cms/mycards')
}

// FAQ data
const faqs = ref([
  {
    question: "How do we get started with CardStudio?",
    answer: "Instantly. Our self-service Card Issuer Portal lets you sign up and begin designing your first interactive card experience in minutes. No waiting, no setup fees."
  },
  {
    question: "Is there a long setup or deployment time?",
    answer: "Zero. CardStudio is a cloud-based platform, meaning there's no technical setup or IT integration needed. If you can use a modern web app, you can launch a CardStudio experience."
  },
  {
    question: "How does physical card printing work?",
    answer: "Seamlessly. Finalize your design in the portal and submit a print request with one click. We manage the entire process, from professional printing to global shipping, right to your door."
  },
  {
    question: "Is every card's QR code unique?",
    answer: "Yes. Each card features a unique, secure QR code. This makes every card a true one-of-a-kind collectible and ensures exclusive access to its digital content."
  },
  {
    question: "Do visitors need to download an app?",
    answer: "Never. Just scan the card's QR code with your phone's camera to instantly launch the experience. No downloads, no sign-ups, no friction."
  },
  {
    question: "How is this different from a normal audio guide?",
    answer: "It's the difference between a monologue and a conversation. Instead of a static recording, CardStudio provides a dynamic AI companion that answers your specific questions in real-time. Plus, you get a beautiful physical souvenir."
  },
  {
    question: "Which languages does the AI support?",
    answer: "Our AI engages visitors with natural, real-time voice conversations in <strong>English, Cantonese, Mandarin, Spanish, and French</strong>. We are constantly expanding our capabilities to welcome the world to your venue."
  },
  {
    question: "How do you handle visitor privacy?",
    answer: "Privacy is at our core. The visitor experience is anonymous by design, requiring no personal information. We are fully GDPR compliant and built on a foundation of minimal data collection."
  }
])
</script>

<style scoped>

/* Smooth scroll behavior */
html {
  scroll-behavior: smooth;
}

/* Custom gradient text */
.bg-clip-text {
  -webkit-background-clip: text;
  background-clip: text;
}

/* Backdrop blur support */
.backdrop-blur-md {
  backdrop-filter: blur(12px);
}

/* Custom hover effects */
.group-hover\:scale-110:hover {
  transform: scale(1.1);
}

.group-hover\:-translate-y-1:hover {
  transform: translateY(-0.25rem);
}

/* Prose styling for rich text content */
.prose {
  max-width: none;
}

.prose p {
  margin-bottom: 1rem;
}

.prose p:last-child {
  margin-bottom: 0;
}
</style>