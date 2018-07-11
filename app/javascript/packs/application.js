import Vue from 'vue/dist/vue.esm'
import system from 'lux-design-system'
import 'lux-design-system/lib/system/system.css'
import store from '../store'

Vue.use(system)

// mount the filemanager app
document.addEventListener('DOMContentLoaded', () => {
  const app = new Vue({
    el: '[data-behavior="vue"]',
    store,
    beforeMount: function () {
        this.resource = {}
        this.resource.id = '4f9e91e1-2e9c-404d-a8ca-30b8c9d01d0d'
        this.$store.dispatch('loadImageCollectionGql', this.resource)
    },
  })
})
