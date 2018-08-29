import Vue from 'vue/dist/vue.esm'
import Vuex from 'vuex'
<<<<<<< HEAD
import state from './vuex/state'
import mutations from './vuex/mutations'
import actions from './vuex/actions'
import getters from './vuex/getters'

Vue.use(Vuex)

const store = new Vuex.Store({
  state,
  mutations,
  actions,
  getters
=======
import actions from './vuex/actions'
import {modules} from 'lux-design-system'
Vue.use(Vuex)

const store = new Vuex.Store({
  actions,
  modules: {
    ordermanager: modules.resourceModule,
    gallery: modules.galleryModule,
  }
>>>>>>> d8616123... adds lux order manager to figgy
})

export default store
