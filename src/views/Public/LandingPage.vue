<template>
  <div class="min-h-screen bg-gradient-to-br from-blue-50 via-white to-purple-50">
    <!-- Navigation Header -->
    <nav class="bg-white/80 backdrop-blur-md border-b border-slate-200 sticky top-0 z-50">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div class="flex justify-between items-center h-16">
          <div class="flex items-center">
            <div class="flex-shrink-0 flex items-center">
              <div class="w-8 h-8 bg-gradient-to-r from-blue-600 to-purple-600 rounded-lg flex items-center justify-center">
                <i class="pi pi-id-card text-white text-lg"></i>
              </div>
              <span class="ml-3 text-xl font-bold text-slate-900">Cardy</span>
            </div>
          </div>
          <div class="flex items-center space-x-4">
            <Button 
              label="Sign In" 
              text 
              @click="router.push('/login')"
              class="text-slate-700 hover:text-blue-600"
            />
            <Button 
              label="Start Free Pilot" 
              @click="router.push('/signup')"
              class="bg-gradient-to-r from-blue-600 to-purple-600 hover:from-blue-700 hover:to-purple-700 border-0 px-6"
            />
          </div>
        </div>
      </div>
    </nav>

    <!-- Hero Section -->
    <section class="relative overflow-hidden">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-20 lg:py-32">
        <div class="grid grid-cols-1 lg:grid-cols-2 gap-12 items-center">
          <div class="space-y-8">
            <div class="space-y-4">
              <h1 class="text-4xl sm:text-5xl lg:text-6xl font-bold text-slate-900 leading-tight">
                Elevate Your Visitor Experience with 
                <span class="bg-gradient-to-r from-blue-600 to-purple-600 bg-clip-text text-transparent">
                  AI-Powered Souvenirs
                </span>
              </h1>
              <p class="text-xl text-slate-600 leading-relaxed">
                Merge collectible card souvenirs with an interactive AI voice guide into one seamless journey. 
                No apps, no hardware—visitors just scan, explore, and remember.
              </p>
            </div>
            
            <div class="flex flex-col sm:flex-row gap-4">
              <Button 
                label="Start Your Free Pilot" 
                icon="pi pi-arrow-right"
                iconPos="right"
                @click="router.push('/signup')"
                class="bg-gradient-to-r from-blue-600 to-purple-600 hover:from-blue-700 hover:to-purple-700 border-0 px-8 py-4 text-lg shadow-lg hover:shadow-xl transition-all"
              />
              <Button 
                label="See How It Works" 
                icon="pi pi-play"
                outlined
                @click="scrollToSection('how-it-works')"
                class="border-2 border-slate-300 hover:border-blue-600 px-8 py-4 text-lg transition-all"
              />
            </div>

            <!-- Value Propositions -->
            <div class="pt-8">
              <div class="grid grid-cols-1 sm:grid-cols-3 gap-4">
                <div class="flex items-center space-x-2 text-slate-600">
                  <i class="pi pi-check-circle text-green-500 text-lg"></i>
                  <span class="text-sm font-medium">No App Required</span>
                </div>
                <div class="flex items-center space-x-2 text-slate-600">
                  <i class="pi pi-check-circle text-green-500 text-lg"></i>
                  <span class="text-sm font-medium">AI Voice Guide</span>
                </div>
                <div class="flex items-center space-x-2 text-slate-600">
                  <i class="pi pi-check-circle text-green-500 text-lg"></i>
                  <span class="text-sm font-medium">5 Languages</span>
                </div>
              </div>
            </div>
          </div>

          <!-- Hero Visual with Sample Card -->
          <div class="relative">
            <div class="relative z-10 mx-auto max-w-sm">
              <!-- Sample Card -->
              <div class="bg-white rounded-2xl shadow-2xl p-6 transform rotate-3 hover:rotate-0 transition-transform duration-500">
                <div class="aspect-[2/3] bg-gradient-to-br from-blue-500 to-purple-600 rounded-xl overflow-hidden relative mb-4">
                  <img 
                    :src="heroImageUrl" 
                    alt="Museum Exhibition" 
                    class="w-full h-full object-cover"
                  />
                  <div class="absolute inset-0 bg-gradient-to-t from-black/50 to-transparent"></div>
                  <div class="absolute bottom-4 left-4 right-4 text-white">
                    <h3 class="text-lg font-bold mb-1">Ancient Artifacts</h3>
                    <p class="text-sm opacity-90">Interactive Museum Guide</p>
                  </div>
                </div>
                
                <!-- QR Code -->
                <div class="text-center">
                  <div class="inline-block p-3 bg-white border-2 border-slate-200 rounded-lg">
                    <QrCode :value="sampleQrUrl" :size="80" />
                  </div>
                  <p class="text-xs text-slate-500 mt-2">Scan to experience AI guide</p>
                </div>
              </div>
            </div>
            
            <!-- Background decoration -->
            <div class="absolute -top-10 -right-10 w-72 h-72 bg-gradient-to-br from-blue-200 to-purple-200 rounded-full opacity-20 animate-pulse"></div>
            <div class="absolute -bottom-10 -left-10 w-64 h-64 bg-gradient-to-br from-purple-200 to-pink-200 rounded-full opacity-20 animate-pulse" style="animation-delay: 1s;"></div>
          </div>
        </div>
      </div>
    </section>

    <!-- About Section -->
    <section class="py-20 bg-slate-50">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div class="text-center mb-16">
          <h2 class="text-3xl sm:text-4xl font-bold text-slate-900 mb-4">
            Redefining the Visitor Journey
          </h2>
          <div class="w-24 h-1 bg-gradient-to-r from-blue-600 to-purple-600 mx-auto"></div>
        </div>
        
        <div class="grid grid-cols-1 lg:grid-cols-2 gap-12 items-center">
          <div class="space-y-6">
            <h3 class="text-2xl font-bold text-slate-900">Our Vision</h3>
            <div class="prose prose-lg text-slate-600">
              <p>
                At Cardy, we are transforming visits to museums, exhibitions, and cultural landmarks into 
                captivating journeys of discovery. We empower institutions to offer rich, AI-powered digital 
                content through beautifully designed physical souvenir cards.
              </p>
              <p>
                Our vision is to make every visitor experience more meaningful, educational, and memorable. 
                By bridging the physical and digital worlds, we help you preserve cultural heritage and create 
                new revenue streams, ensuring your stories are accessible to visitors worldwide.
              </p>
            </div>
          </div>
          
          <div class="grid grid-cols-2 gap-6">
            <div class="text-center p-6 bg-white rounded-xl shadow-lg border-l-4 border-blue-500">
              <div class="w-12 h-12 bg-blue-100 rounded-lg flex items-center justify-center mx-auto mb-4">
                <i class="pi pi-microphone text-blue-600 text-xl"></i>
              </div>
              <h4 class="font-bold text-slate-900 mb-2">AI Conversations</h4>
              <p class="text-sm text-slate-600">Natural voice interactions</p>
            </div>
            <div class="text-center p-6 bg-white rounded-xl shadow-lg border-l-4 border-purple-500">
              <div class="w-12 h-12 bg-purple-100 rounded-lg flex items-center justify-center mx-auto mb-4">
                <i class="pi pi-mobile text-purple-600 text-xl"></i>
              </div>
              <h4 class="font-bold text-slate-900 mb-2">No App Needed</h4>
              <p class="text-sm text-slate-600">Just scan QR code</p>
            </div>
            <div class="text-center p-6 bg-white rounded-xl shadow-lg border-l-4 border-green-500">
              <div class="w-12 h-12 bg-green-100 rounded-lg flex items-center justify-center mx-auto mb-4">
                <i class="pi pi-globe text-green-600 text-xl"></i>
              </div>
              <h4 class="font-bold text-slate-900 mb-2">Multi-Language</h4>
              <p class="text-sm text-slate-600">5 languages supported</p>
            </div>
            <div class="text-center p-6 bg-white rounded-xl shadow-lg border-l-4 border-orange-500">
              <div class="w-12 h-12 bg-orange-100 rounded-lg flex items-center justify-center mx-auto mb-4">
                <i class="pi pi-id-card text-orange-600 text-xl"></i>
              </div>
              <h4 class="font-bold text-slate-900 mb-2">Physical Souvenirs</h4>
              <p class="text-sm text-slate-600">Beautiful collectible cards</p>
            </div>
          </div>
        </div>
      </div>
    </section>

    <!-- How It Works Section -->
    <section id="how-it-works" class="py-20">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div class="text-center mb-16">
          <h2 class="text-3xl sm:text-4xl font-bold text-slate-900 mb-4">
            A Simple Path to Innovation
          </h2>
          <div class="w-24 h-1 bg-gradient-to-r from-blue-600 to-purple-600 mx-auto"></div>
        </div>
        
        <div class="grid grid-cols-1 md:grid-cols-3 gap-8">
          <!-- Step 1 -->
          <div class="text-center group">
            <div class="relative mb-8">
              <div class="w-20 h-20 bg-gradient-to-r from-blue-600 to-purple-600 rounded-full flex items-center justify-center mx-auto group-hover:scale-110 transition-transform duration-300">
                <i class="pi pi-palette text-white text-2xl"></i>
              </div>
              <div class="absolute -top-2 -right-2 w-8 h-8 bg-orange-500 rounded-full flex items-center justify-center text-white font-bold text-sm">1</div>
            </div>
            <h3 class="text-xl font-bold text-slate-900 mb-4">Design & Launch</h3>
            <p class="text-slate-600">
              Use our self-service platform to design beautiful souvenir cards. Add your exhibits, artifacts, 
              or points of interest, link them to our powerful AI, and issue a new batch of cards instantly.
            </p>
          </div>

          <!-- Step 2 -->
          <div class="text-center group">
            <div class="relative mb-8">
              <div class="w-20 h-20 bg-gradient-to-r from-purple-600 to-pink-600 rounded-full flex items-center justify-center mx-auto group-hover:scale-110 transition-transform duration-300">
                <i class="pi pi-qrcode text-white text-2xl"></i>
              </div>
              <div class="absolute -top-2 -right-2 w-8 h-8 bg-orange-500 rounded-full flex items-center justify-center text-white font-bold text-sm">2</div>
            </div>
            <h3 class="text-xl font-bold text-slate-900 mb-4">Visitors Scan & Explore</h3>
            <p class="text-slate-600">
              Visitors purchase or receive a card and scan its unique QR code with their smartphone. They instantly 
              access a world of premium digital content and can begin a natural voice conversation with the AI guide 
              in their native language.
            </p>
          </div>

          <!-- Step 3 -->
          <div class="text-center group">
            <div class="relative mb-8">
              <div class="w-20 h-20 bg-gradient-to-r from-pink-600 to-red-600 rounded-full flex items-center justify-center mx-auto group-hover:scale-110 transition-transform duration-300">
                <i class="pi pi-chart-line text-white text-2xl"></i>
              </div>
              <div class="absolute -top-2 -right-2 w-8 h-8 bg-orange-500 rounded-full flex items-center justify-center text-white font-bold text-sm">3</div>
            </div>
            <h3 class="text-xl font-bold text-slate-900 mb-4">Engage & Analyze</h3>
            <p class="text-slate-600">
              Delight your visitors with a personalized, memorable souvenir they can take home. Use the admin 
              dashboard to track engagement, gain insights into visitor interests, and manage your collections effortlessly.
            </p>
          </div>
        </div>
      </div>
    </section>

    <!-- Key Features Section -->
    <section class="py-20 bg-slate-50">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div class="text-center mb-16">
          <h2 class="text-3xl sm:text-4xl font-bold text-slate-900 mb-4">
            Why Institutions Love Cardy
          </h2>
          <div class="w-24 h-1 bg-gradient-to-r from-blue-600 to-purple-600 mx-auto"></div>
        </div>
        
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
          <!-- Feature 1 -->
          <div class="bg-white rounded-xl p-8 shadow-lg hover:shadow-xl transition-shadow duration-300">
            <div class="w-12 h-12 bg-blue-100 rounded-lg flex items-center justify-center mb-6">
              <i class="pi pi-id-card text-blue-600 text-xl"></i>
            </div>
            <h3 class="text-xl font-bold text-slate-900 mb-4">Premium Collectible Souvenirs</h3>
            <p class="text-slate-600">
              Offer beautifully designed, QR-enabled physical cards that link directly to digital content. 
              These lasting souvenirs drive revenue and encourage repeat visits.
            </p>
          </div>

          <!-- Feature 2 -->
          <div class="bg-white rounded-xl p-8 shadow-lg hover:shadow-xl transition-shadow duration-300">
            <div class="w-12 h-12 bg-purple-100 rounded-lg flex items-center justify-center mb-6">
              <i class="pi pi-microphone text-purple-600 text-xl"></i>
            </div>
            <h3 class="text-xl font-bold text-slate-900 mb-4">Conversational AI Guide</h3>
            <p class="text-slate-600">
              Engage visitors with a real-time, voice-based AI guide. Powered by the latest OpenAI technology, 
              it offers natural, low-latency conversations in multiple languages.
            </p>
          </div>

          <!-- Feature 3 -->
          <div class="bg-white rounded-xl p-8 shadow-lg hover:shadow-xl transition-shadow duration-300">
            <div class="w-12 h-12 bg-green-100 rounded-lg flex items-center justify-center mb-6">
              <i class="pi pi-mobile text-green-600 text-xl"></i>
            </div>
            <h3 class="text-xl font-bold text-slate-900 mb-4">Instant, No-App Access</h3>
            <p class="text-slate-600">
              Visitors scan a simple QR code to begin their journey immediately. By removing the friction of app downloads, 
              you maximize adoption and ensure a smooth user experience.
            </p>
          </div>

          <!-- Feature 4 -->
          <div class="bg-white rounded-xl p-8 shadow-lg hover:shadow-xl transition-shadow duration-300">
            <div class="w-12 h-12 bg-orange-100 rounded-lg flex items-center justify-center mb-6">
              <i class="pi pi-globe text-orange-600 text-xl"></i>
            </div>
            <h3 class="text-xl font-bold text-slate-900 mb-4">Comprehensive Multilingual Support</h3>
            <p class="text-slate-600">
              Break down language barriers instantly. Our AI currently supports natural conversations in English, 
              Cantonese, Mandarin, Spanish, and French.
            </p>
          </div>

          <!-- Feature 5 -->
          <div class="bg-white rounded-xl p-8 shadow-lg hover:shadow-xl transition-shadow duration-300">
            <div class="w-12 h-12 bg-red-100 rounded-lg flex items-center justify-center mb-6">
              <i class="pi pi-cog text-red-600 text-xl"></i>
            </div>
            <h3 class="text-xl font-bold text-slate-900 mb-4">Zero Hardware, Zero Hassle</h3>
            <p class="text-slate-600">
              Cardy leverages the smartphones your visitors already carry. No need for expensive, high-maintenance 
              audio guide hardware or complex venue infrastructure.
            </p>
          </div>

          <!-- Feature 6 -->
          <div class="bg-white rounded-xl p-8 shadow-lg hover:shadow-xl transition-shadow duration-300">
            <div class="w-12 h-12 bg-indigo-100 rounded-lg flex items-center justify-center mb-6">
              <i class="pi pi-chart-bar text-indigo-600 text-xl"></i>
            </div>
            <h3 class="text-xl font-bold text-slate-900 mb-4">Powerful Admin Dashboard</h3>
            <p class="text-slate-600">
              Manage your content, view real-time analytics, issue new card batches, and request printing all from 
              one intuitive, self-service platform.
            </p>
          </div>
        </div>
      </div>
    </section>

    <!-- Use Cases Section -->
    <section class="py-20">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div class="text-center mb-16">
          <h2 class="text-3xl sm:text-4xl font-bold text-slate-900 mb-4">
            Transforming Every Visitor Experience
          </h2>
          <p class="text-xl text-slate-600 max-w-3xl mx-auto">
            From world-class museums to local landmarks, Cardy's AI-powered digital souvenirs create memorable 
            moments for any venue that welcomes visitors.
          </p>
          <div class="w-24 h-1 bg-gradient-to-r from-blue-600 to-purple-600 mx-auto mt-4"></div>
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
              <div class="h-48 bg-gradient-to-br from-green-500 to-blue-600 relative overflow-hidden">
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
              <div class="p-6">
                <h3 class="text-xl font-bold text-slate-900 mb-3">Tourist Attractions & Landmarks</h3>
                <p class="text-slate-600">
                  Offer rich historical context and multi-language AI guidance for scenic spots and historical narratives.
                </p>
              </div>
            </div>
          </div>

          <!-- Use Case 3 -->
          <div class="group cursor-pointer">
            <div class="bg-white rounded-xl overflow-hidden shadow-lg hover:shadow-xl transition-all duration-300 group-hover:-translate-y-1">
              <div class="h-48 bg-gradient-to-br from-purple-500 to-pink-600 relative overflow-hidden">
                <img 
:src="featureImage3Url" 
                  alt="Cultural Heritage" 
                  class="w-full h-full object-cover group-hover:scale-110 transition-transform duration-300"
                />
                <div class="absolute inset-0 bg-gradient-to-t from-black/50 to-transparent"></div>
                <div class="absolute bottom-4 left-4 text-white">
                  <i class="pi pi-star text-2xl"></i>
                </div>
              </div>
              <div class="p-6">
                <h3 class="text-xl font-bold text-slate-900 mb-3">Cultural Heritage Sites</h3>
                <p class="text-slate-600">
                  Preserve and interpret cultural significance through immersive, AI-driven storytelling.
                </p>
              </div>
            </div>
          </div>
        </div>

        <!-- Second Row: 3 Cards -->
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
          <!-- Use Case 4 -->
          <div class="group cursor-pointer">
            <div class="bg-white rounded-xl overflow-hidden shadow-lg hover:shadow-xl transition-all duration-300 group-hover:-translate-y-1">
              <div class="h-48 bg-gradient-to-br from-orange-500 to-red-600 relative overflow-hidden">
                <img 
:src="featureImage4Url" 
                  alt="Exhibition Centers" 
                  class="w-full h-full object-cover group-hover:scale-110 transition-transform duration-300"
                />
                <div class="absolute inset-0 bg-gradient-to-t from-black/50 to-transparent"></div>
                <div class="absolute bottom-4 left-4 text-white">
                  <i class="pi pi-calendar text-2xl"></i>
                </div>
              </div>
              <div class="p-6">
                <h3 class="text-xl font-bold text-slate-900 mb-3">Exhibition Centers & Trade Shows</h3>
                <p class="text-slate-600">
                  Provide attendees with interactive schedules, speaker bios, and exhibitor information on a collectible card.
                </p>
              </div>
            </div>
          </div>

          <!-- Use Case 5 -->
          <div class="group cursor-pointer">
            <div class="bg-white rounded-xl overflow-hidden shadow-lg hover:shadow-xl transition-all duration-300 group-hover:-translate-y-1">
              <div class="h-48 bg-gradient-to-br from-pink-500 to-purple-600 relative overflow-hidden">
                <img 
:src="featureImage5Url" 
                  alt="Theme Parks" 
                  class="w-full h-full object-cover group-hover:scale-110 transition-transform duration-300"
                />
                <div class="absolute inset-0 bg-gradient-to-t from-black/50 to-transparent"></div>
                <div class="absolute bottom-4 left-4 text-white">
                  <i class="pi pi-sparkles text-2xl"></i>
                </div>
              </div>
              <div class="p-6">
                <h3 class="text-xl font-bold text-slate-900 mb-3">Theme Parks & Entertainment Venues</h3>
                <p class="text-slate-600">
                  Create collectible digital souvenirs with behind-the-scenes content and AI character interactions.
                </p>
              </div>
            </div>
          </div>

          <!-- Use Case 6 -->
          <div class="group cursor-pointer">
            <div class="bg-white rounded-xl overflow-hidden shadow-lg hover:shadow-xl transition-all duration-300 group-hover:-translate-y-1">
              <div class="h-48 bg-gradient-to-br from-indigo-500 to-blue-600 relative overflow-hidden">
                <img 
:src="featureImage6Url" 
                  alt="Events" 
                  class="w-full h-full object-cover group-hover:scale-110 transition-transform duration-300"
                />
                <div class="absolute inset-0 bg-gradient-to-t from-black/50 to-transparent"></div>
                <div class="absolute bottom-4 left-4 text-white">
                  <i class="pi pi-users text-2xl"></i>
                </div>
              </div>
              <div class="p-6">
                <h3 class="text-xl font-bold text-slate-900 mb-3">Event Organizers</h3>
                <p class="text-slate-600">
                  Provide attendees with interactive schedules, speaker bios, and exhibitor information on a collectible card.
                </p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>

    <!-- Pricing Section -->
    <section class="py-20 bg-slate-900 text-white relative overflow-hidden">
      <!-- Background decoration -->
      <div class="absolute inset-0">
        <div class="absolute top-0 left-1/4 w-96 h-96 bg-blue-500/10 rounded-full blur-3xl"></div>
        <div class="absolute bottom-0 right-1/4 w-96 h-96 bg-purple-500/10 rounded-full blur-3xl"></div>
      </div>
      
      <div class="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8 relative">
        <div class="text-center mb-16">
          <h2 class="text-3xl sm:text-4xl font-bold mb-6">
            Simple, Transparent Pricing
          </h2>
          <p class="text-xl text-slate-300 max-w-3xl mx-auto mb-8">
            Pay only for what you use. No hidden fees, no monthly subscriptions, no setup costs.
          </p>
        </div>

        <!-- Main Pricing Card -->
        <div class="max-w-4xl mx-auto">
          <div class="bg-white/10 backdrop-blur-md rounded-3xl p-8 md:p-12 border border-white/20 shadow-2xl">
            <div class="grid grid-cols-1 lg:grid-cols-2 gap-12 items-center">
              
              <!-- Pricing Info -->
              <div class="text-center lg:text-left">
                <div class="inline-flex items-center gap-2 bg-green-500/20 text-green-300 px-4 py-2 rounded-full text-sm font-medium mb-6">
                  <i class="pi pi-check-circle"></i>
                  Pay-per-card pricing
                </div>
                
                <div class="mb-6">
                  <div class="flex items-baseline justify-center lg:justify-start gap-2">
                    <span class="text-6xl md:text-7xl font-bold bg-gradient-to-r from-blue-400 to-purple-400 bg-clip-text text-transparent">
                      $2
                    </span>
                    <span class="text-2xl text-slate-400">USD</span>
                  </div>
                  <p class="text-xl text-slate-300 mt-2">per card, per batch</p>
                </div>

                <div class="space-y-4 text-slate-300">
                  <div class="flex items-center gap-3 justify-center lg:justify-start">
                    <div class="w-2 h-2 bg-blue-400 rounded-full"></div>
                    <span>No monthly subscriptions</span>
                  </div>
                  <div class="flex items-center gap-3 justify-center lg:justify-start">
                    <div class="w-2 h-2 bg-purple-400 rounded-full"></div>
                    <span>No setup or platform fees</span>
                  </div>
                  <div class="flex items-center gap-3 justify-center lg:justify-start">
                    <div class="w-2 h-2 bg-green-400 rounded-full"></div>
                    <span>Pay only when you issue cards</span>
                  </div>
                </div>
              </div>

              <!-- Features -->
              <div class="space-y-6">
                <h3 class="text-2xl font-bold mb-6 text-center lg:text-left">Everything Included</h3>
                
                <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                  <div class="flex items-center gap-3">
                    <i class="pi pi-check text-green-400 text-lg"></i>
                    <span class="text-slate-300">AI voice conversations</span>
                  </div>
                  <div class="flex items-center gap-3">
                    <i class="pi pi-check text-green-400 text-lg"></i>
                    <span class="text-slate-300">Multi-language support</span>
                  </div>
                  <div class="flex items-center gap-3">
                    <i class="pi pi-check text-green-400 text-lg"></i>
                    <span class="text-slate-300">Design dashboard</span>
                  </div>
                  <div class="flex items-center gap-3">
                    <i class="pi pi-check text-green-400 text-lg"></i>
                    <span class="text-slate-300">Real-time analytics</span>
                  </div>
                  <div class="flex items-center gap-3">
                    <i class="pi pi-check text-green-400 text-lg"></i>
                    <span class="text-slate-300">QR code generation</span>
                  </div>
                  <div class="flex items-center gap-3">
                    <i class="pi pi-check text-green-400 text-lg"></i>
                    <span class="text-slate-300">Print management</span>
                  </div>
                  <div class="flex items-center gap-3">
                    <i class="pi pi-check text-green-400 text-lg"></i>
                    <span class="text-slate-300">Cloud hosting</span>
                  </div>
                  <div class="flex items-center gap-3">
                    <i class="pi pi-check text-green-400 text-lg"></i>
                    <span class="text-slate-300">24/7 support</span>
                  </div>
                </div>
              </div>
            </div>

            <!-- CTA Section -->
            <div class="mt-12 pt-8 border-t border-white/20">
              <div class="text-center">
                <p class="text-slate-300 mb-6">Ready to create your first AI-powered souvenir experience?</p>
                <div class="flex flex-col sm:flex-row gap-4 justify-center">
                  <Button 
                    label="Start Free Pilot" 
                    icon="pi pi-arrow-right"
                    iconPos="right"
                    @click="router.push('/signup')"
                    class="bg-gradient-to-r from-blue-600 to-purple-600 hover:from-blue-700 hover:to-purple-700 border-0 px-8 py-4 text-lg font-bold shadow-xl hover:shadow-2xl transition-all"
                  />
                  <Button 
                    label="Schedule Demo" 
                    icon="pi pi-calendar"
                    outlined
                    @click="openContactModal"
                    class="border-2 border-white/30 text-white hover:bg-white/10 px-8 py-4 text-lg transition-all"
                  />
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- Additional Info -->
        <div class="mt-16 text-center">
          <div class="grid grid-cols-1 md:grid-cols-3 gap-8">
            <div class="flex flex-col items-center">
              <div class="w-16 h-16 bg-blue-500/20 rounded-full flex items-center justify-center mb-4">
                <i class="pi pi-shield-check text-blue-400 text-2xl"></i>
              </div>
              <h4 class="text-lg font-semibold mb-2">Secure & Reliable</h4>
              <p class="text-slate-400 text-sm">Enterprise-grade security with cloud infrastructure</p>
            </div>
            
            <div class="flex flex-col items-center">
              <div class="w-16 h-16 bg-purple-500/20 rounded-full flex items-center justify-center mb-4">
                <i class="pi pi-users text-purple-400 text-2xl"></i>
              </div>
              <h4 class="text-lg font-semibold mb-2">Dedicated Support</h4>
              <p class="text-slate-400 text-sm">Expert team available to help you succeed</p>
            </div>
            
            <div class="flex flex-col items-center">
              <div class="w-16 h-16 bg-green-500/20 rounded-full flex items-center justify-center mb-4">
                <i class="pi pi-bolt text-green-400 text-2xl"></i>
              </div>
              <h4 class="text-lg font-semibold mb-2">Quick Setup</h4>
              <p class="text-slate-400 text-sm">Launch your first card experience in minutes</p>
            </div>
          </div>
        </div>
      </div>
    </section>

    <!-- FAQ Section -->
    <section class="py-20 bg-slate-50">
      <div class="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8">
        <div class="text-center mb-16">
          <h2 class="text-3xl sm:text-4xl font-bold text-slate-900 mb-4">
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
    <section class="py-20 bg-gradient-to-r from-blue-600 to-purple-600 text-white">
      <div class="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 text-center">
        <h2 class="text-3xl sm:text-4xl font-bold mb-6">
          Ready to Transform Your Visitor Experience?
        </h2>
        <p class="text-xl text-blue-100 mb-8 max-w-2xl mx-auto">
          Join hundreds of leading institutions worldwide who trust Cardy to create meaningful, 
          memorable experiences for their visitors.
        </p>
        <div class="flex flex-col sm:flex-row gap-4 justify-center">
          <Button 
            label="Start Your Free Pilot" 
            icon="pi pi-arrow-right"
            iconPos="right"
            @click="router.push('/signup')"
            class="bg-white text-blue-600 hover:bg-blue-50 border-0 px-8 py-4 text-lg font-bold shadow-xl hover:shadow-2xl transition-all"
          />
          <Button 
            label="Schedule a Demo" 
            icon="pi pi-calendar"
            outlined
            @click="openContactModal"
            class="border-2 border-white text-white hover:bg-white hover:text-blue-600 px-8 py-4 text-lg transition-all"
          />
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
              <div class="w-8 h-8 bg-gradient-to-r from-blue-600 to-purple-600 rounded-lg flex items-center justify-center">
                <i class="pi pi-id-card text-white text-lg"></i>
              </div>
              <span class="ml-3 text-xl font-bold">Cardy</span>
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
            © 2025 Cardy. All rights reserved.
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
          Ready to learn more about how Cardy can transform your visitor experience? 
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
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import Button from 'primevue/button'
import Dialog from 'primevue/dialog'
import QrCode from 'qrcode.vue'

const router = useRouter()

// Sample QR code URL for demonstration
const sampleQrUrl = ref(import.meta.env.VITE_SAMPLE_QR_URL || 'https://cardy.example.com/demo/ancient-artifacts')

// Contact modal
const showContactModal = ref(false)

// Contact information from environment variables
const contactEmail = import.meta.env.VITE_CONTACT_EMAIL || 'support@cardy.com'
const contactWhatsApp = import.meta.env.VITE_CONTACT_WHATSAPP_URL || 'https://wa.me/852xxxxxx'
const contactPhone = import.meta.env.VITE_CONTACT_PHONE || '+852 xxxxxx'
const contactWhatsAppDisplay = import.meta.env.VITE_CONTACT_WHATSAPP_DISPLAY || contactPhone

// Environment variables successfully integrated

// Image URLs from environment variables
const heroImageUrl = import.meta.env.VITE_HERO_IMAGE_URL || 'https://images.unsplash.com/photo-1564399580075-5dfe19c205f3?w=400&h=600&fit=crop&crop=center'
const featureImage1Url = import.meta.env.VITE_FEATURE_IMAGE_1_URL || 'https://images.unsplash.com/photo-1564399580075-5dfe19c205f3?w=400&h=300&fit=crop'
const featureImage2Url = import.meta.env.VITE_FEATURE_IMAGE_2_URL || 'https://images.unsplash.com/photo-1539650116574-75c0c6d73c6e?w=400&h=300&fit=crop'
const featureImage3Url = import.meta.env.VITE_FEATURE_IMAGE_3_URL || 'https://images.unsplash.com/photo-1578662996442-48f60103fc96?w=400&h=300&fit=crop'
const featureImage4Url = import.meta.env.VITE_FEATURE_IMAGE_4_URL || 'https://images.unsplash.com/photo-1540575467063-178a50c2df87?w=400&h=300&fit=crop'
const featureImage5Url = import.meta.env.VITE_FEATURE_IMAGE_5_URL || 'https://images.unsplash.com/photo-1596444080749-6ac1ba12a236?w=400&h=300&fit=crop'
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

// FAQ data
const faqs = ref([
  {
    question: "How do we get started with Cardy?",
    answer: "Instantly. Our self-service Card Issuer Portal lets you sign up and begin designing your first interactive card experience in minutes. No waiting, no setup fees."
  },
  {
    question: "Is there a long setup or deployment time?",
    answer: "Zero. Cardy is a cloud-based platform, meaning there's no technical setup or IT integration needed. If you can use a modern web app, you can launch a Cardy experience."
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
    answer: "It's the difference between a monologue and a conversation. Instead of a static recording, Cardy provides a dynamic AI companion that answers your specific questions in real-time. Plus, you get a beautiful physical souvenir."
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
/* Custom animations and transitions */
@keyframes float {
  0%, 100% { transform: translateY(0px) rotate(3deg); }
  50% { transform: translateY(-10px) rotate(3deg); }
}

.group:hover .transform {
  animation: float 3s ease-in-out infinite;
}

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