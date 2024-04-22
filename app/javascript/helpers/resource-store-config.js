// resource-store-config.spec.js
import { resourceState, resourceMutations, resourceGetters } from "../store/resource"
import { galleryModule } from "../store/gallery"

export default {
  state: resourceState,
  mutations: resourceMutations,
  getters: resourceGetters
  modules: {
    gallery: galleryModule,
  },
}
