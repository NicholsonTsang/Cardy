<template>
  <div class="max-w-sm mx-auto">
    <!-- Sample Card Demo -->
    <div class="bg-white rounded-2xl shadow-2xl p-6 transform hover:scale-105 transition-transform duration-500">
      <div class="aspect-[2/3] bg-gradient-to-br from-blue-500 to-purple-600 rounded-xl overflow-hidden relative mb-4">
        <img 
          :src="cardImageUrl" 
          :alt="cardTitle" 
          class="w-full h-full object-cover"
        />
        <div class="absolute inset-0 bg-gradient-to-t from-black/50 to-transparent"></div>
        <div class="absolute bottom-4 left-4 right-4 text-white">
          <h3 class="text-lg font-bold mb-1">{{ cardTitle }}</h3>
          <p class="text-sm opacity-90">{{ cardSubtitle }}</p>
        </div>
      </div>
      
      <!-- QR Code -->
      <div class="text-center">
        <div class="inline-block p-3 bg-white border-2 border-slate-200 rounded-lg hover:border-blue-300 transition-colors">
          <QrCode :value="qrCodeUrl" :size="qrCodeSize" />
        </div>
        <p class="text-xs text-slate-500 mt-2">{{ qrCodeLabel }}</p>
        
        <!-- Interactive Demo Button -->
        <Button
          v-if="showDemoButton"
          label="Try Demo Experience"
          icon="pi pi-external-link"
          text
          @click="openDemo"
          class="mt-3 text-blue-600 hover:text-blue-700"
          size="small"
        />
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed } from 'vue'
import QrCode from 'qrcode.vue'
import Button from 'primevue/button'

const props = defineProps({
  cardTitle: {
    type: String,
    default: 'Ancient Artifacts'
  },
  cardSubtitle: {
    type: String,
    default: 'Interactive Museum Guide'
  },
  cardImageUrl: {
    type: String,
    default: 'https://images.unsplash.com/photo-1564399580075-5dfe19c205f3?w=400&h=600&fit=crop&crop=center'
  },
  qrCodeUrl: {
    type: String,
    default: 'https://cardy.demo/ancient-artifacts'
  },
  qrCodeSize: {
    type: Number,
    default: 80
  },
  qrCodeLabel: {
    type: String,
    default: 'Scan to experience AI guide'
  },
  showDemoButton: {
    type: Boolean,
    default: true
  }
})

const emit = defineEmits(['demo-clicked'])

const openDemo = () => {
  emit('demo-clicked', props.qrCodeUrl)
  // Could open a modal or navigate to a demo page
  window.open(props.qrCodeUrl, '_blank')
}
</script>

<style scoped>
/* Custom animations */
@keyframes float {
  0%, 100% { 
    transform: translateY(0px) scale(1); 
  }
  50% { 
    transform: translateY(-5px) scale(1.02); 
  }
}

.hover\:scale-105:hover {
  animation: float 2s ease-in-out infinite;
}

/* QR Code hover effect */
.hover\:border-blue-300:hover {
  box-shadow: 0 0 0 2px rgba(59, 130, 246, 0.1);
}
</style>