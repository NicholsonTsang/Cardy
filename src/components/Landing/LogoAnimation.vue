<template>
  <div class="logo" :class="[`size-${size}`, variant]">
    <!-- Main square container -->
    <div class="logo-square">
      <!-- QR pattern -->
      <div class="qr-grid">
        <div v-for="i in 25" :key="i" 
             :class="['qr-cell', { 'filled': qrPattern[i-1] }]">
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
defineProps({
  size: {
    type: String,
    default: 'md', // 'sm' (32px), 'md' (40px), 'lg' (52px)
    validator: (value) => ['sm', 'md', 'lg'].includes(value)
  },
  variant: {
    type: String,
    default: 'default', // 'default' (for light backgrounds), 'light' (for dark backgrounds)
    validator: (value) => ['default', 'light'].includes(value)
  }
})

// "The Happy AI Guide" Pattern
// Represents the core of FunTell:
// - Fun: The smile :)
// - Tell: The digital face of the AI guide
// - AI: The pixelated/robot aesthetic
const qrPattern = [
  0, 1, 0, 1, 0, // Eyes
  0, 1, 0, 1, 0, // Eyes
  0, 0, 0, 0, 0, // Space
  1, 0, 0, 0, 1, // Mouth corners
  0, 1, 1, 1, 0  // Smile
]
</script>

<style scoped>
.logo {
  position: relative;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}

/* Size variants */
.size-sm {
  width: 32px;
  height: 32px;
}

.size-md {
  width: 40px;
  height: 40px;
}

.size-lg {
  width: 52px;
  height: 52px;
}

/* Main square */
.logo-square {
  width: 100%;
  height: 100%;
  background: linear-gradient(
    135deg,
    #3b82f6 0%,
    #6366f1 45%,
    #8b5cf6 100%
  );
  border-radius: 10px;
  display: flex;
  align-items: center;
  justify-content: center;
  box-shadow: 
    0 2px 10px rgba(99, 102, 241, 0.4),
    0 4px 16px rgba(139, 92, 246, 0.3);
}

.size-sm .logo-square {
  border-radius: 8px;
}

.size-lg .logo-square {
  border-radius: 12px;
}

/* Light variant for dark backgrounds */
.light .logo-square {
  background: linear-gradient(
    135deg,
    #60a5fa 0%,
    #818cf8 50%,
    #a78bfa 100%
  );
  box-shadow: 
    0 2px 12px rgba(147, 197, 253, 0.4),
    0 4px 16px rgba(167, 139, 250, 0.3);
}

/* QR Grid */
.qr-grid {
  display: grid;
  grid-template-columns: repeat(5, 1fr);
  gap: 2px;
  width: 65%;
  height: 65%;
}

.size-sm .qr-grid {
  gap: 1.5px;
}

.size-lg .qr-grid {
  gap: 2.5px;
}

.qr-cell {
  background: rgba(255, 255, 255, 0.15);
  border-radius: 1px;
}

.qr-cell.filled {
  background: rgba(255, 255, 255, 1);
  box-shadow: 0 0 4px rgba(255, 255, 255, 0.5);
}

.size-lg .qr-cell {
  border-radius: 1.5px;
}

/* Hover effect */
.logo:hover .logo-square {
  transform: scale(1.03);
  box-shadow: 
    0 4px 12px rgba(99, 102, 241, 0.4),
    0 6px 16px rgba(139, 92, 246, 0.3);
  transition: all 0.2s ease;
}

.logo .logo-square {
  transition: all 0.2s ease;
}
</style>
