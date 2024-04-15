import Vue from 'vue/dist/vue.esm'
import Vuex from 'vuex'
import actions from './vuex/actions'
import { resourceState, resourceMutations, resourceGetters } from "./resource"
import {modules} from 'lux-design-system'
import { treeState, treeMutations } from "./tree/index"
import { zoomState, zoomMutations, zoomGetters } from "./zoom/index"
Vue.use(Vuex)

const resourceModule = {
  state: resourceState,
  mutations: resourceMutations,
  getters: resourceGetters,
  modules: {
    gallery: modules.galleryModule,
  }
}

export const treeModule = {
  state: treeState,
  mutations: treeMutations,
}

export const zoomModule = {
  state: zoomState,
  mutations: zoomMutations,
  getters: zoomGetters,
}

const store = new Vuex.Store({
  actions,
  modules: {
    ordermanager: resourceModule,
    gallery: modules.galleryModule,
    tree: treeModule,
    zoom: zoomModule,
  }
})

export default store
