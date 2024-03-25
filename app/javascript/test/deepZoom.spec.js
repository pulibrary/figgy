import Vuex from "vuex"
import { createLocalVue, mount, shallowMount } from "@vue/test-utils"
import DeepZoom from "../components/DeepZoom.vue"
import { zoomMutations, zoomGetters } from "../store/zoom"
import { modules } from 'lux-design-system'
import OpenSeadragon from 'openseadragon'

// create an extended `Vue` constructor
const localVue = createLocalVue()
localVue.use(Vuex)

let wrapper
let items = [
  {
    "id": "1",
    "caption": "a_foo",
    "service": "a1_service",
    "mediaUrl": "a1_url",
    "viewingHint": "single"
  },
  {
    "id": "2",
    "caption": "b_baz",
    "service": "b2_service",
    "mediaUrl": "b2_url",
    "viewingHint": null
  },
  {
    "id": "3",
    "caption": "c_fee",
    "service": "c3_service",
    "mediaUrl": "c3_url",
    "viewingHint": null
  }
]

const zoom = {
  state: {
    zoomed: items[2],
  },
  mutations: zoomMutations,
  getters: zoomGetters,
}

const gallery = {
  state: {
    items: items,
    selected: [],
    cut: [],
    changeList: ["2"],
    ogItems: items,
  },
  mutations: modules.galleryModule.mutations,
}

let store = new Vuex.Store({
  modules: {
    gallery: gallery,
    zoom: zoom,
  },
})

describe("DeepZoom.vue", () => {
  beforeEach(() => {

    wrapper = mount(DeepZoom, {
      localVue,
      store,
      stubs: [
        "wrapper",
        "heading",
        "input-button",
      ],
    })
  })

  it("has the right label when zoomed", () => {
    expect(wrapper.text()).toContain('c_fee')
  })

  it("has the no label when not zoomed", () => {
    wrapper.vm.hideZoom()
    expect(wrapper.text()).not.toContain('c_fee')
  })

})
