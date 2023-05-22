import Vuex from "vuex"
import { createLocalVue, mount, shallowMount } from "@vue/test-utils"
import OrderManagerFilesetForm from "../components/OrderManagerFilesetForm.vue"
import { resourceMutations, resourceGetters } from "../store/resource"
import { modules } from 'lux-design-system'

// create an extended `Vue` constructor
const localVue = createLocalVue()
localVue.use(Vuex)

let wrapper
let getters
let options
let store
let actions
let items = [
  { id: "a", title: "A", viewingHint: "single", mediaUrl: "https://picsum.photos/600/300/?random" },
  { id: "b", title: "B", caption: "b", mediaUrl: "https://picsum.photos/600/300/?random" },
  { id: "c", title: "C", caption: "c", mediaUrl: "https://picsum.photos/600/300/?random" },
]

describe("OrderManagerFilesetForm.vue", () => {
  beforeEach(() => {
    actions = {
      updateStartCanvas: vi.fn(),
      updateThumbnail: vi.fn(),
      updateItems: vi.fn(),
      updateChanges: vi.fn()
    }

    const gallery = {
      state: {
        items: items,
        selected: [items[0]],
        cut: [],
        changeList: [],
        ogItems: items,
      },
      mutations: modules.galleryModule.mutations,
    }

    const getters = {
      isMultiVolume: () => false
    }

    const resource = {
      state: {
        resource: {
          id: "",
          resourceClassName: "",
          bibId: "",
          label: "Resource not available.",
          thumbnail: "",
          startCanvas: "",
          isMultiVolume: false,
          viewingHint: "single",
          viewingDirection: null,
          members: [],
          loadState: "NOT_LOADED",
          saveState: "NOT_SAVED",
          ogState: {},
        },
      },
      mutations: resourceMutations,
      getters: getters,
      actions: actions,
      modules: {
        gallery: gallery,
      },
    }

    store = new Vuex.Store({
      modules: {
        ordermanager: resource,
        gallery: gallery,
      },
    })

    options = {
      computed: {
        orderChanged: function () {
          return getters.orderChanged
        },
        isDisabled: function () {
          if (getters.stateChanged) {
            return false
          } else {
            return true
          }
        }
      }
    }

    wrapper = mount(OrderManagerFilesetForm, {
      options,
      localVue,
      store,
      stubs: ["heading","input-select", "input-text", "input-checkbox"],
    })
  })

  it('isViewHint should return true if the value is a viewHint', () => {
    expect(wrapper.vm.isViewHint('single')).toBe(true)
  })

  it('updateStartCanvas action gets called when updateStartCanvas method is called', () => {
    wrapper.vm.updateStartCanvas(true)
    expect(actions.updateStartCanvas).toHaveBeenCalled()
  })

  it('updateThumbnail action gets called when updateStartCanvas method is called', () => {
    wrapper.vm.updateThumbnail(true)
    expect(actions.updateThumbnail).toHaveBeenCalled()
  })

  it('updateSingle should call the updateChanges and updateItems actions', async () => {
    wrapper.vm.updateSingle()
    expect(actions.updateChanges).toHaveBeenCalled()
    expect(actions.updateItems).toHaveBeenCalled()
  })

  it('pageType and  should not display for MVWs', () => {
    actions = {
      updateStartCanvas: vi.fn(),
      updateThumbnail: vi.fn(),
      updateItems: vi.fn(),
      updateChanges: vi.fn()
    }

    const gallery = {
      state: {
        items: items,
        selected: [items[0]],
        cut: [],
        changeList: [],
        ogItems: items,
      },
      mutations: modules.galleryModule.mutations,
    }

    const getters = {
      isMultiVolume: () => true
    }

    const mvwResource = {
      state: {
        resource: {
          id: "",
          resourceClassName: "",
          bibId: "",
          label: "Resource not available.",
          thumbnail: "",
          startCanvas: "",
          isMultiVolume: true,
          viewingHint: "single",
          viewingDirection: null,
          members: [],
          loadState: "NOT_LOADED",
          saveState: "NOT_SAVED",
          ogState: {},
        },
      },
      mutations: resourceMutations,
      getters: getters,
      actions: actions,
      modules: {
        gallery: gallery,
      },
    }

    store = new Vuex.Store({
      modules: {
        ordermanager: mvwResource,
        gallery: gallery,
      },
    })

    options = {
      computed: {
        isMultiVolume: function() {
          return getters.isMultiVolume
        }
      }
    }

    wrapper = mount(OrderManagerFilesetForm, {
      options,
      localVue,
      store,
      stubs: ["heading","input-select", "input-text", "input-checkbox"],
    })
    expect(wrapper.find('#pageType').exists()).toBe(false)
    expect(wrapper.find('#startCanvasCheckbox').exists()).toBe(false)
    expect(wrapper.find('#thumbnailCheckbox').exists()).toBe(true)
  })

  it("has the expected html structure", () => {
    expect(wrapper.element).toMatchSnapshot()
  })
})
