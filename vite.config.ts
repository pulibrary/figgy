import { defineConfig } from 'vite'
import RubyPlugin from 'vite-plugin-ruby'
import vue from '@vitejs/plugin-vue'
import { compression } from 'vite-plugin-compression2'

// see compression documentation at https://vite-ruby.netlify.app/guide/deployment.html#compressing-assets-%F0%9F%93%A6
// and https://github.com/ElMassimo/vite_ruby/discussions/101#discussioncomment-1019222
export default defineConfig({
  resolve: {
    alias: {
      vue: 'vue/dist/vue.esm-bundler'
    }
  },
  build: {
    cssMinify: 'esbuild',
    // Force OSD images to work, it was returning base64.
    assetsInlineLimit: (filePath) =>
      filePath.includes('openseadragon/build/openseadragon/images/')
        ? false
        : undefined,
    rolldownOptions: {
      onwarn (warning, defaultHandler) {
        // Skip verbose warnings about "use client" that aren't relevant in Figgy
        if (warning.code === 'MODULE_LEVEL_DIRECTIVE' && warning.message.includes('"use client"')) return
        defaultHandler(warning)
      }
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
    // Create gzip and brotli copies of relevant assets
    compression({ algorithms: ['gzip', 'brotliCompress'] }),
    {
      config() {
        return { define: {  __VUE_PROD_DEVTOOLS__: true }  }
      },
    },
    {
      // Force openseadragon to not use requirejs, since when we load both Clover & UV
      // (since UV is in uv.js), it complains.
      name: 'openseadragon-disable-amd',
      transform(code, id) {
        if (id.includes('openseadragon') && code.includes("typeof define === 'function' && define.amd")) {
          return code.replace(
            "if (typeof define === 'function' && define.amd) {",
            'if (false) {'
          )
        }
      }
    },
  ]
})
