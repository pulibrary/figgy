import 'babel-polyfill'
import Vue from 'vue/dist/vue.esm'
import App from '../app.vue'
import store from '../store'

document.addEventListener('DOMContentLoaded', () => {
  const app = new Vue({
    el: '#filemanager',
    template: '<App/>',
    components: { App },
    store,
    data: {resource: null},
    beforeMount: function () {
        this.resource = {}
        this.resource.id = this.$el.attributes['data-resource'].value
        this.resource.class_name = this.$el.attributes['data-class-name'].value
        this.$store.dispatch('loadImageCollection', this.resource)
    },
  })
})
