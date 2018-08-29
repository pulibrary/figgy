import Vue from 'vue/dist/vue.esm'
import system from 'lux-design-system'
import 'lux-design-system/lib/system/system.css'
<<<<<<< HEAD
=======
import store from '../store'
>>>>>>> d8616123... adds lux order manager to figgy

Vue.use(system)

// mount the filemanager app
document.addEventListener('DOMContentLoaded', () => {
  const app = new Vue({
    el: '[data-behavior="vue"]',
<<<<<<< HEAD
=======
    store,
>>>>>>> d8616123... adds lux order manager to figgy
  })
})
