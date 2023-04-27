import { defineConfig } from 'vite'
import { resolve } from 'path'
import RubyPlugin from 'vite-plugin-ruby'
import vue from '@vitejs/plugin-vue2'

export default defineConfig({
  base: './',
  resolve: {
    alias: {
      '@figgy': resolve(__dirname, 'app/javascript/figgy'),
      '@viewer': resolve(__dirname, 'app/javascript/viewer'),
      '@images': resolve(__dirname, 'app/javascript/images'),
      '@components': resolve(__dirname, 'app/javascript/components'),
      '@helpers': resolve(__dirname, 'app/javascript/helpers'),
      '@store': resolve(__dirname, 'app/javascript/store'),
    },
  },
  plugins: [
    RubyPlugin(),
    vue(),
  ],
})
