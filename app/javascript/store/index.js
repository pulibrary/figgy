import Vue from 'vue/dist/vue.esm'
import Vuex from 'vuex'
import actions from './vuex/actions'
import {modules} from 'lux-design-system'
Vue.use(Vuex)

const store = new Vuex.Store({
  actions,
  modules: {
    ordermanager: modules.resourceModule,
    gallery: modules.galleryModule,
  }
})

export default store
