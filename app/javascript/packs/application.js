import Vue from 'vue/dist/vue.esm'
import system from 'lux-design-system'
import 'lux-design-system/lib/system/system.css'
import store from '../store'
import apollo from '../helpers/apolloClient'
import gql from 'graphql-tag'

Vue.use(system)
Vue.prototype.$apollo = apollo

// mount the filemanager app
document.addEventListener('DOMContentLoaded', () => {
  const app = new Vue({
    el: '[data-behavior="vue"]',
    store,
    async created() {
      const response = await this.$apollo.query({
        query: gql`
        query Resource {
          resource(id: "e8e8c06c-ca78-46c6-9981-ef7f974c3c06") {
            id,
            label
          }
        }`
      })
      console.log(response.data.resource.label)
    }
  })
})
