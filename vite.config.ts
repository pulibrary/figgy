import { defineConfig } from 'vite'
import RubyPlugin from 'vite-plugin-ruby'
import { createVuePlugin } from 'vite-plugin-vue2'

export default defineConfig({
  plugins: [
    RubyPlugin(),
    createVuePlugin()
  ]
})
