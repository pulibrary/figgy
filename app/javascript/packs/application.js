import Vue from 'vue/dist/vue.esm'
import system from 'lux-design-system'
import 'lux-design-system/lib/system/system.css'
import store from '../store'
import DocumentAdder from '../components/document_adder'

Vue.use(system)

// mount the filemanager app
document.addEventListener('DOMContentLoaded', () => {
  var elements = document.getElementsByClassName('lux')
  for(var i = 0; i < elements.length; i++){
    new Vue({
      el: elements[i],
      store,
      components: {
        'document-adder': DocumentAdder
      }
    })
  }
})
