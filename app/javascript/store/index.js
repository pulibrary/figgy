import { compile } from 'vue'
import { createStore } from 'vuex'
import actions from './vuex/actions'
import { resourceState, resourceMutations, resourceGetters } from "./resource"
import { galleryState, galleryMutations, galleryModule } from './gallery'
import { treeState, treeMutations } from "./tree/index"
import { zoomState, zoomMutations, zoomGetters } from "./zoom/index"

const resourceModule = {
  state: resourceState,
  mutations: resourceMutations,
  getters: resourceGetters,
  // galleryModule is no longer exported from Lux
  modules: {
    gallery: galleryModule,
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

export const store = createStore({
  actions,
  modules: {
    ordermanager: resourceModule,
    gallery: galleryModule,
    tree: treeModule,
    zoom: zoomModule,
  }
})

export default store
