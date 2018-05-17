import 'babel-polyfill'
import Vue from 'vue/dist/vue.esm'
import App from '../app.vue'
import store from '../store'
import Flash from 'vue-flash'

// global flash messaging component
Vue.component('flash', Flash);
window.events = new Vue()
window.flash = function(message, type) {
    window.events.$emit('flash', message, type)
};

// mount the filemanager app
document.addEventListener('DOMContentLoaded', () => {
  const app = new Vue({
    el: '#order-manager',
    template: '<App/>',
    components: { App },
    store,
    data: {resource: null},
    beforeMount: function () {
        this.resource = {}
        this.resource.id = this.$el.attributes['data-resource'].value
        this.resource.class_name = this.$el.attributes['data-class-name'].value
        this.$store.dispatch('loadImageCollection', this.resource)
        this.$store.dispatch('changeManifestLoadState', 'LOADING')
    },
  })
})
