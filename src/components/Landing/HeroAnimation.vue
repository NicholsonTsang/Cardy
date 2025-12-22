<template>
  <div class="hero-animation-container" ref="containerRef">
    <canvas ref="canvasRef" class="hero-canvas"></canvas>
    
    <!-- Ambient glow background -->
    <div class="ambient-glow"></div>
    
    <!-- Central glowing orb -->
    <div class="central-orb">
      <div class="orb-outer-glow"></div>
      <div class="orb-core">
        <div class="orb-shine"></div>
      </div>
      <div class="orb-ring ring-1"></div>
      <div class="orb-ring ring-2"></div>
      <div class="orb-ring ring-3"></div>
      
      <!-- QR-like pattern in center -->
      <div class="qr-pattern">
        <div class="qr-grid">
          <div v-for="i in 25" :key="i" 
               :class="['qr-cell', { 'filled': qrPattern[i-1] }]"
               :style="{ animationDelay: `${(i * 40)}ms` }">
          </div>
        </div>
      </div>
    </div>
    
    <!-- Floating icons around the orb -->
    <div class="floating-icons">
      <div v-for="(icon, index) in floatingIcons" :key="index"
           class="floating-icon"
           :style="getIconStyle(index)">
        <div class="icon-glow"></div>
        <div class="icon-inner">
          <i :class="icon.class"></i>
        </div>
      </div>
    </div>
    
    <!-- Particle trails -->
    <div class="particle-container">
      <div v-for="i in particleCount" :key="i" 
           class="particle"
           :style="getParticleStyle(i)">
      </div>
    </div>
    
    <!-- Connection lines from center to icons -->
    <svg class="connection-lines" viewBox="0 0 450 450">
      <defs>
        <linearGradient id="lineGradient" x1="0%" y1="0%" x2="100%" y2="0%">
          <stop offset="0%" stop-color="rgba(167, 139, 250, 0.7)" />
          <stop offset="100%" stop-color="rgba(196, 181, 253, 0.25)" />
        </linearGradient>
      </defs>
      <line v-for="(_, index) in floatingIcons" :key="index"
            :x1="225" :y1="225"
            :x2="getLineEnd(index).x" :y2="getLineEnd(index).y"
            stroke="url(#lineGradient)"
            stroke-width="1"
            :stroke-dasharray="4"
            class="connection-line"
            :style="{ animationDelay: `${index * 0.5}s` }" />
    </svg>
  </div>
</template>

<script setup>
import { ref, onMounted, onUnmounted, computed } from 'vue'

const containerRef = ref(null)
const canvasRef = ref(null)
let animationFrame = null
let ctx = null
let nodes = []
let resizeTimeout = null

// Responsive particle count
const isMobile = typeof window !== 'undefined' ? window.innerWidth < 768 : false
const particleCount = isMobile ? 12 : 20
const nodeCount = isMobile ? 25 : 50

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

// Floating icons representing different venue types
const floatingIcons = [
  { class: 'pi pi-building' },      // Museum
  { class: 'pi pi-star' },          // Restaurant
  { class: 'pi pi-calendar' },      // Events
  { class: 'pi pi-map' },           // Tours
  { class: 'pi pi-shopping-bag' },  // Retail
  { class: 'pi pi-heart' },         // Hospitality
]

const getIconStyle = (index) => {
  const angle = (index / floatingIcons.length) * Math.PI * 2 - Math.PI / 2
  const delay = index * 0.6
  // Base position calculated for CSS --radius variable
  const xUnit = Math.cos(angle)
  const yUnit = Math.sin(angle) * 0.7 // Elliptical orbit
  
  return {
    '--x-unit': xUnit,
    '--y-unit': yUnit,
    '--delay': `${delay}s`
  }
}

const getLineEnd = (index) => {
  const angle = (index / floatingIcons.length) * Math.PI * 2 - Math.PI / 2
  const radius = 145
  return {
    x: 225 + Math.cos(angle) * radius,
    y: 225 + Math.sin(angle) * radius * 0.7
  }
}

const getParticleStyle = (index) => {
  const angle = (index / particleCount) * Math.PI * 2
  const delay = index * 0.25
  
  return {
    '--angle': `${angle * (180 / Math.PI)}deg`,
    '--delay': `${delay}s`,
    '--duration': `${2.5 + Math.random() * 2}s`,
    '--size': `${2 + Math.random() * 3}px`
  }
}

// Node class for network visualization
class Node {
  constructor(canvas) {
    this.canvas = canvas
    this.reset()
    // Random initial phase to desync animations
    this.phase = Math.random() * Math.PI * 2
  }
  
  reset() {
    const centerX = this.canvas.width / 2
    const centerY = this.canvas.height / 2
    const angle = Math.random() * Math.PI * 2
    const radius = 60 + Math.random() * 140
    
    this.x = centerX + Math.cos(angle) * radius
    this.y = centerY + Math.sin(angle) * radius * 0.7
    this.z = Math.random() * 200 - 100
    this.baseZ = this.z
    this.angle = angle
    this.radius = radius
    this.speed = 0.0003 + Math.random() * 0.0008
    this.size = 1.5 + Math.random() * 2.5
    this.opacity = 0.4 + Math.random() * 0.6
    this.hue = 210 + Math.random() * 50 // Blue to purple range
  }
  
  update(timestamp) {
    const centerX = this.canvas.width / 2
    const centerY = this.canvas.height / 2
    
    // Orbital movement
    this.angle += this.speed
    this.x = centerX + Math.cos(this.angle) * this.radius
    this.y = centerY + Math.sin(this.angle) * this.radius * 0.7
    
    // Z oscillation for 3D effect
    this.z = this.baseZ + Math.sin(timestamp * 0.0008 + this.angle * 2 + this.phase) * 40
    
    // Scale based on Z position (perspective)
    this.scale = (this.z + 150) / 200
  }
  
  draw(ctx) {
    const alpha = this.opacity * Math.max(0.2, this.scale)
    
    // Outer glow
    ctx.beginPath()
    ctx.arc(this.x, this.y, this.size * this.scale * 2.5, 0, Math.PI * 2)
    ctx.fillStyle = `hsla(${this.hue}, 85%, 70%, ${alpha * 0.25})`
    ctx.fill()
    
    // Core
    ctx.beginPath()
    ctx.arc(this.x, this.y, this.size * this.scale, 0, Math.PI * 2)
    ctx.fillStyle = `hsla(${this.hue}, 90%, 85%, ${alpha})`
    ctx.fill()
  }
}

const initCanvas = () => {
  const canvas = canvasRef.value
  if (!canvas) return
  
  ctx = canvas.getContext('2d', { alpha: true }) // Optimize for transparency
  resizeCanvas()
  
  // Create nodes
  nodes = []
  for (let i = 0; i < nodeCount; i++) {
    nodes.push(new Node(canvas))
  }
  
  animate(0)
}

const debouncedResize = () => {
  if (resizeTimeout) clearTimeout(resizeTimeout)
  resizeTimeout = setTimeout(resizeCanvas, 100)
}

const resizeCanvas = () => {
  const canvas = canvasRef.value
  const container = containerRef.value
  if (!canvas || !container) return
  
  const rect = container.getBoundingClientRect()
  const dpr = Math.min(window.devicePixelRatio || 1, 2) // Cap DPR at 2 for performance
  
  canvas.width = rect.width * dpr
  canvas.height = rect.height * dpr
  canvas.style.width = rect.width + 'px'
  canvas.style.height = rect.height + 'px'
  
  ctx?.scale(dpr, dpr)
  
  // Reset nodes positions
  nodes.forEach(node => node.canvas = canvas)
}

const drawConnections = () => {
  const maxDist = 80
  
  // Begin path once for all connections to reduce draw calls
  // Group by rough opacity/color to minimize state changes if needed, 
  // but for simple lines, batching logic is complex. 
  // Standard simple loop is usually fine for <1000 items.
  
  for (let i = 0; i < nodes.length; i++) {
    for (let j = i + 1; j < nodes.length; j++) {
      const dx = nodes[i].x - nodes[j].x
      const dy = nodes[i].y - nodes[j].y
      const distSq = dx * dx + dy * dy
      
      // Using squared distance avoids expensive Math.sqrt
      if (distSq < maxDist * maxDist) {
        const dist = Math.sqrt(distSq)
        const alpha = (1 - dist / maxDist) * 0.4 * Math.min(nodes[i].scale, nodes[j].scale)
        
        ctx.beginPath()
        ctx.moveTo(nodes[i].x, nodes[i].y)
        ctx.lineTo(nodes[j].x, nodes[j].y)
        
        // Use a simpler average hue for performance instead of gradient
        const avgHue = (nodes[i].hue + nodes[j].hue) / 2
        ctx.strokeStyle = `hsla(${avgHue}, 80%, 75%, ${alpha})`
        ctx.lineWidth = 1
        ctx.stroke()
      }
    }
  }
}

const animate = (timestamp) => {
  if (!ctx || !canvasRef.value) return
  
  const canvas = canvasRef.value
  const dpr = Math.min(window.devicePixelRatio || 1, 2)
  
  // Clear canvas
  ctx.clearRect(0, 0, canvas.width / dpr, canvas.height / dpr)
  
  // Update nodes
  nodes.forEach(node => {
    node.update(timestamp)
  })
  
  // Sort by Z for proper depth
  nodes.sort((a, b) => a.z - b.z)
  
  // Draw connections first (behind nodes)
  drawConnections()
  
  // Draw nodes
  nodes.forEach(node => {
    node.draw(ctx)
  })
  
  animationFrame = requestAnimationFrame(animate)
}

onMounted(() => {
  initCanvas()
  window.addEventListener('resize', debouncedResize)
})

onUnmounted(() => {
  if (animationFrame) {
    cancelAnimationFrame(animationFrame)
  }
  if (resizeTimeout) {
    clearTimeout(resizeTimeout)
  }
  window.removeEventListener('resize', debouncedResize)
})
</script>

<style scoped>
.hero-animation-container {
  position: relative;
  width: 100%;
  height: 100%;
  min-height: 380px;
  display: flex;
  align-items: center;
  justify-content: center;
  perspective: 1000px;
  will-change: transform; /* Hint for browser optimization */
}

.hero-canvas {
  position: absolute;
  inset: 0;
  width: 100%;
  height: 100%;
  pointer-events: none;
}

/* Ambient Glow */
.ambient-glow {
  position: absolute;
  width: 360px;
  height: 360px;
  background: radial-gradient(
    circle,
    rgba(99, 102, 241, 0.4) 0%,
    rgba(139, 92, 246, 0.25) 30%,
    transparent 70%
  );
  border-radius: 50%;
  filter: blur(50px);
  animation: ambient-pulse 4s ease-in-out infinite;
}

@keyframes ambient-pulse {
  0%, 100% { 
    transform: scale(1);
    opacity: 0.8;
  }
  50% { 
    transform: scale(1.15);
    opacity: 1;
  }
}

/* Central Orb */
.central-orb {
  position: relative;
  width: 160px;
  height: 160px;
  display: flex;
  align-items: center;
  justify-content: center;
  animation: float-orb 6s ease-in-out infinite;
  transform-style: preserve-3d;
}

@keyframes float-orb {
  0%, 100% { transform: translateY(0) rotateX(8deg) rotateY(0deg); }
  50% { transform: translateY(-12px) rotateX(-8deg) rotateY(5deg); }
}

.orb-outer-glow {
  position: absolute;
  width: 220px;
  height: 220px;
  background: radial-gradient(
    circle,
    rgba(99, 102, 241, 0.6) 0%,
    rgba(139, 92, 246, 0.35) 40%,
    transparent 70%
  );
  border-radius: 50%;
  filter: blur(25px);
  animation: outer-glow-pulse 3s ease-in-out infinite;
}

@keyframes outer-glow-pulse {
  0%, 100% { 
    transform: scale(1);
    opacity: 0.7;
  }
  50% { 
    transform: scale(1.2);
    opacity: 1;
  }
}

.orb-core {
  position: absolute;
  width: 105px;
  height: 105px;
  background: radial-gradient(
    circle at 35% 35%,
    rgba(255, 255, 255, 1) 0%,
    rgba(199, 210, 254, 1) 15%,
    rgba(129, 140, 248, 0.95) 40%,
    rgba(139, 92, 246, 0.9) 70%,
    rgba(109, 40, 217, 0.85) 100%
  );
  border-radius: 50%;
  box-shadow: 
    0 0 60px rgba(99, 102, 241, 0.8),
    0 0 120px rgba(139, 92, 246, 0.5),
    0 0 180px rgba(99, 102, 241, 0.3),
    inset 0 0 40px rgba(255, 255, 255, 0.5),
    inset -10px -10px 30px rgba(88, 28, 135, 0.4);
  animation: pulse-core 3s ease-in-out infinite;
}

.orb-shine {
  position: absolute;
  top: 12%;
  left: 18%;
  width: 35%;
  height: 25%;
  background: linear-gradient(
    135deg,
    rgba(255, 255, 255, 0.95) 0%,
    rgba(255, 255, 255, 0.3) 100%
  );
  border-radius: 50%;
  filter: blur(2px);
}

@keyframes pulse-core {
  0%, 100% { 
    transform: scale(1);
    box-shadow: 
      0 0 60px rgba(99, 102, 241, 0.8),
      0 0 120px rgba(139, 92, 246, 0.5),
      0 0 180px rgba(99, 102, 241, 0.3),
      inset 0 0 40px rgba(255, 255, 255, 0.5),
      inset -10px -10px 30px rgba(88, 28, 135, 0.4);
  }
  50% { 
    transform: scale(1.03);
    box-shadow: 
      0 0 80px rgba(99, 102, 241, 0.9),
      0 0 150px rgba(139, 92, 246, 0.6),
      0 0 220px rgba(99, 102, 241, 0.4),
      inset 0 0 50px rgba(255, 255, 255, 0.6),
      inset -10px -10px 40px rgba(88, 28, 135, 0.5);
  }
}

/* Orbital Rings */
.orb-ring {
  position: absolute;
  border: 1.5px solid;
  border-radius: 50%;
  animation: spin-ring linear infinite;
  opacity: 0.8;
}

.ring-1 {
  width: 135px;
  height: 135px;
  border-color: rgba(147, 197, 253, 0.8);
  animation-duration: 10s;
  transform: rotateX(75deg) rotateZ(0deg);
  box-shadow: 0 0 15px rgba(147, 197, 253, 0.5);
}

.ring-2 {
  width: 155px;
  height: 155px;
  border-color: rgba(167, 139, 250, 0.7);
  animation-duration: 15s;
  animation-direction: reverse;
  transform: rotateX(75deg) rotateZ(60deg);
  box-shadow: 0 0 15px rgba(167, 139, 250, 0.4);
}

.ring-3 {
  width: 175px;
  height: 175px;
  border-color: rgba(34, 211, 238, 0.6);
  animation-duration: 20s;
  transform: rotateX(75deg) rotateZ(120deg);
  box-shadow: 0 0 15px rgba(34, 211, 238, 0.35);
}

@keyframes spin-ring {
  from { transform: rotateX(75deg) rotateZ(0deg); }
  to { transform: rotateX(75deg) rotateZ(360deg); }
}

/* QR Pattern */
.qr-pattern {
  position: absolute;
  z-index: 10;
}

.qr-grid {
  display: grid;
  grid-template-columns: repeat(5, 1fr);
  gap: 3px;
  width: 48px;
  height: 48px;
}

.qr-cell {
  width: 100%;
  aspect-ratio: 1;
  border-radius: 1px;
  background: rgba(255, 255, 255, 0.15);
  animation: qr-pulse 2.5s ease-in-out infinite;
}

.qr-cell.filled {
  background: rgba(255, 255, 255, 1);
  box-shadow: 0 0 10px rgba(255, 255, 255, 0.9), 0 0 20px rgba(147, 197, 253, 0.5);
}

@keyframes qr-pulse {
  0%, 100% { opacity: 1; }
  50% { opacity: 0.6; }
}

/* SVG Connection Lines */
.connection-lines {
  position: absolute;
  width: 450px;
  height: 450px;
  pointer-events: none;
  opacity: 0.6;
}

.connection-line {
  animation: line-dash 3s linear infinite;
}

@keyframes line-dash {
  from { stroke-dashoffset: 0; }
  to { stroke-dashoffset: 20; }
}

/* Floating Icons */
.floating-icons {
  position: absolute;
  width: 100%;
  height: 100%;
  pointer-events: none;
}

.floating-icon {
  --radius: 150px;
  position: absolute;
  top: 50%;
  left: 50%;
  width: 48px;
  height: 48px;
  display: flex;
  align-items: center;
  justify-content: center;
  transform: translate(
    calc(-50% + var(--x-unit) * var(--radius)), 
    calc(-50% + var(--y-unit) * var(--radius))
  );
  animation: icon-float 4s ease-in-out infinite;
  animation-delay: var(--delay);
}

.icon-inner {
  width: 44px;
  height: 44px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: linear-gradient(135deg, rgba(139, 92, 246, 0.4), rgba(99, 102, 241, 0.35));
  border: 1.5px solid rgba(199, 210, 254, 0.6);
  border-radius: 14px;
  backdrop-filter: blur(12px);
  box-shadow: 
    0 4px 24px rgba(139, 92, 246, 0.3),
    0 0 25px rgba(99, 102, 241, 0.2),
    inset 0 1px 0 rgba(255, 255, 255, 0.25);
  transition: all 0.3s ease;
}

.floating-icon:hover .icon-inner {
  border-color: rgba(199, 210, 254, 0.9);
  background: linear-gradient(135deg, rgba(139, 92, 246, 0.5), rgba(99, 102, 241, 0.45));
  box-shadow: 
    0 4px 35px rgba(139, 92, 246, 0.4),
    0 0 40px rgba(99, 102, 241, 0.3),
    inset 0 1px 0 rgba(255, 255, 255, 0.35);
  transform: scale(1.1);
}

.floating-icon i {
  color: rgba(255, 255, 255, 0.95);
  font-size: 18px;
  z-index: 1;
  text-shadow: 0 0 10px rgba(147, 197, 253, 0.5);
}

.icon-glow {
  position: absolute;
  inset: -10px;
  background: radial-gradient(
    circle,
    rgba(147, 197, 253, 0.5),
    transparent 70%
  );
  border-radius: 20px;
  opacity: 0;
  animation: icon-glow-pulse 3s ease-in-out infinite;
  animation-delay: var(--delay);
}

@keyframes icon-float {
  0%, 100% { margin-top: 0; }
  50% { margin-top: -10px; }
}

@keyframes icon-glow-pulse {
  0%, 100% { opacity: 0; transform: scale(1); }
  50% { opacity: 0.8; transform: scale(1.15); }
}

/* Particle Trails */
.particle-container {
  position: absolute;
  width: 100%;
  height: 100%;
  pointer-events: none;
}

.particle {
  position: absolute;
  top: 50%;
  left: 50%;
  width: var(--size);
  height: var(--size);
  background: linear-gradient(135deg, #bfdbfe, #c4b5fd);
  border-radius: 50%;
  box-shadow: 0 0 12px rgba(191, 219, 254, 0.8), 0 0 20px rgba(167, 139, 250, 0.4);
  animation: particle-orbit var(--duration) linear infinite;
  animation-delay: var(--delay);
  transform-origin: center;
}

@keyframes particle-orbit {
  0% {
    transform: rotate(var(--angle)) translateX(50px) scale(0);
    opacity: 0;
  }
  15% {
    opacity: 1;
    transform: rotate(var(--angle)) translateX(70px) scale(1);
  }
  85% {
    opacity: 0.4;
    transform: rotate(calc(var(--angle) + 200deg)) translateX(150px) scale(0.4);
  }
  100% {
    opacity: 0;
    transform: rotate(calc(var(--angle) + 220deg)) translateX(170px) scale(0);
  }
}

/* Responsive adjustments */
@media (max-width: 1024px) {
  .hero-animation-container {
    min-height: 300px;
  }
}

@media (max-width: 640px) {
  .hero-animation-container {
    min-height: 260px;
    transform: scale(0.9);
  }
  
  .ambient-glow {
    width: 220px;
    height: 220px;
  }
  
  .central-orb {
    width: 110px;
    height: 110px;
  }
  
  .orb-core {
    width: 70px;
    height: 70px;
  }
  
  .orb-outer-glow {
    width: 140px;
    height: 140px;
  }
  
  .ring-1 { width: 90px; height: 90px; }
  .ring-2 { width: 102px; height: 102px; }
  .ring-3 { width: 114px; height: 114px; }
  
  .floating-icon {
    --radius: 95px;
    width: 36px;
    height: 36px;
  }
  
  .icon-inner {
    width: 32px;
    height: 32px;
    border-radius: 10px;
    background: linear-gradient(135deg, rgba(139, 92, 246, 0.45), rgba(99, 102, 241, 0.4));
  }
  
  .floating-icon i {
    font-size: 12px;
  }
  
  .qr-grid {
    width: 30px;
    height: 30px;
    gap: 2px;
  }
  
  .connection-lines {
    width: 340px;
    height: 340px;
  }
}

/* Reduced motion */
@media (prefers-reduced-motion: reduce) {
  .central-orb,
  .orb-core,
  .orb-ring,
  .orb-outer-glow,
  .ambient-glow,
  .floating-icon,
  .particle,
  .qr-cell,
  .connection-line,
  .icon-glow {
    animation: none;
  }
  
  .icon-glow {
    opacity: 0.5;
  }
}
</style>
