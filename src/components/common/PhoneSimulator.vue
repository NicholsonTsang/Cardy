<template>
  <div class="phone-device" :style="phoneStyle">
    <!-- Phone screen - simple rectangle -->
    <div class="phone-screen">
      <slot></slot>
    </div>
  </div>
</template>

<script setup>
import { computed } from 'vue'

const props = defineProps({
  /**
   * Width of the phone device in pixels
   * All other dimensions scale proportionally
   */
  width: {
    type: Number,
    default: 180
  }
})

const phoneStyle = computed(() => ({
  '--phone-width': `${props.width}px`
}))
</script>

<style scoped>
/* Simple Phone Frame - Clean rectangle without rounded screen */
.phone-device {
  --phone-border: calc(var(--phone-width) * 0.025);
  
  position: relative;
  width: var(--phone-width);
  aspect-ratio: 9 / 19.5; /* Phone aspect ratio */
  background: linear-gradient(145deg, #1f1f1f, #2a2a2a);
  border-radius: calc(var(--phone-width) * 0.06);
  padding: var(--phone-border);
  box-shadow: 
    0 25px 50px -12px rgba(0, 0, 0, 0.35),
    0 0 0 1px rgba(255, 255, 255, 0.1) inset,
    0 -1px 0 rgba(0, 0, 0, 0.3) inset;
}

.phone-screen {
  position: relative;
  width: 100%;
  height: 100%;
  background: #0f172a; /* Match mobile client's dark background */
  overflow: hidden;
  /* No border-radius - simple rectangle for exact iframe fit */
}
</style>
