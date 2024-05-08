import { defineConfig } from 'vite'
import { resolve } from 'path'
import RubyPlugin from 'vite-plugin-ruby'
import vue from '@vitejs/plugin-vue'
import { brotliCompressSync } from 'zlib'
import gzipPlugin from 'rollup-plugin-gzip'

// see compression documentation at https://vite-ruby.netlify.app/guide/deployment.html#compressing-assets-%F0%9F%93%A6
// and https://github.com/ElMassimo/vite_ruby/discussions/101#discussioncomment-1019222
export default defineConfig({
  resolve: {
    alias: {
      vue: 'vue/dist/vue.esm-bundler'
    }
  },
  test: {
    globals: true,
    environment: 'jsdom',
    setupFiles: ['./test/setup.js'],
    alias: {
      '@/': './app/javascript'
    }
  },
  plugins: [
    RubyPlugin(),
    vue(),
    // Create gzip copies of relevant assets
    gzipPlugin(),
    // Create brotli copies of relevant assets
    gzipPlugin({
      customCompression: (content) => brotliCompressSync(Buffer.from(content)),
      fileName: '.br'
    }),
    {
      config() {
        return { define: {  __VUE_PROD_DEVTOOLS__: true }  }
      },
    },
  ]
})
