import Vue from 'vue/dist/vue.esm'
import Vuex from 'vuex'
import actions from './vuex/actions'
import { resourceState, resourceMutations, resourceGetters } from "./resource"
import {modules} from 'lux-design-system'
Vue.use(Vuex)

const resourceModule = {
  state: resourceState,
  mutations: resourceMutations,
  getters: resourceGetters,
  modules: {
    gallery: modules.galleryModule,
  }
}

const store = new Vuex.Store({
  actions,
  modules: {
    ordermanager: resourceModule,
    gallery: modules.galleryModule,
  }
})

export default store
