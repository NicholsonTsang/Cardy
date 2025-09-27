import { fileURLToPath, URL } from 'node:url'

import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import vueDevTools from 'vite-plugin-vue-devtools'

// https://vite.dev/config/
export default defineConfig({
  plugins: [
    vue(),
    vueDevTools(),
  ],
  resolve: {
    alias: {
      '@': fileURLToPath(new URL('./src', import.meta.url))
    },
  },
  define: {
    // Make environment variables available at build time
    __CARD_ASPECT_RATIO_WIDTH__: JSON.stringify(process.env.VITE_CARD_ASPECT_RATIO_WIDTH || '2'),
    __CARD_ASPECT_RATIO_HEIGHT__: JSON.stringify(process.env.VITE_CARD_ASPECT_RATIO_HEIGHT || '3'),
  }
})
