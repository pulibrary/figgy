import { defineConfig } from 'vite'
import { resolve } from 'path'
import RubyPlugin from 'vite-plugin-ruby'
import vue from '@vitejs/plugin-vue2'
import { brotliCompressSync } from 'zlib'
import gzipPlugin from 'rollup-plugin-gzip'

// see compression documentation at https://vite-ruby.netlify.app/guide/deployment.html#compressing-assets-%F0%9F%93%A6
// and https://github.com/ElMassimo/vite_ruby/discussions/101#discussioncomment-1019222
export default defineConfig({
  base: './',
  resolve: {
    alias: {
      '@figgy': resolve(__dirname, 'app/javascript/figgy'),
      '@channels': resolve(__dirname, 'app/javascript/channels'),
      '@viewer': resolve(__dirname, 'app/javascript/viewer'),
      '@images': resolve(__dirname, 'app/javascript/images'),
      '@components': resolve(__dirname, 'app/javascript/components'),
      '@helpers': resolve(__dirname, 'app/javascript/helpers'),
      '@store': resolve(__dirname, 'app/javascript/store')
    }
  },
  test: {
    globals: true,
    environment: 'jsdom',
    setupFiles: ['./test/setup.js']
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
    })
  ]
})
