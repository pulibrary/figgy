// resource-store-config.spec.js
import { modules } from 'lux-design-system'
import { resourceState, resourceMutations, resourceGetters } from "@store/resource"

export default {
  state: resourceState,
  mutations: resourceMutations,
  getters: resourceGetters,
  modules: {
    gallery: modules.galleryModule,
  },
}
