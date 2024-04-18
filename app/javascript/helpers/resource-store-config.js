// resource-store-config.spec.js
import { resourceState, resourceMutations, resourceGetters } from "@store/resource"

export default {
  state: resourceState,
  mutations: resourceMutations,
  getters: resourceGetters,
  modules: {
    gallery: galleryModule,
  },
}
