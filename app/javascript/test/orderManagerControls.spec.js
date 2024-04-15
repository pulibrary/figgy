import Vuex from "vuex"
import { createLocalVue, mount, shallowMount } from "@vue/test-utils"
import OrderManagerControls from "../components/OrderManagerControls.vue"
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
  { id: "a", title: "A", caption: "a", mediaUrl: "https://picsum.photos/600/300/?random" },
  { id: "b", title: "B", caption: "b", mediaUrl: "https://picsum.photos/600/300/?random" },
  { id: "c", title: "C", caption: "c", mediaUrl: "https://picsum.photos/600/300/?random" },
]
let resourceObject = {
  id: "aea40813-e0ed-4307-aae9-aec53b26bdda",
  label: "Resource with 3 files",
  viewingHint: "individuals",
  viewingDirection: "LEFTTORIGHT",
  startPage: "8ffd7a03-ec0e-46c1-a347-e4b19cb7839f",
  thumbnail: {
    id: "8ffd7a03-ec0e-46c1-a347-e4b19cb7839f",
    thumbnailUrl:
      "http://localhost:3000/image-service/8ffd7a03-ec0e-46c1-a347-e4b19cb7839f/full/!200,150/0/default.jpg",
    iiifServiceUrl: "http://localhost:3000/image-service/8ffd7a03-ec0e-46c1-a347-e4b19cb7839f",
  },
  __typename: "ScannedResource",
  members: [
    {
      id: "8ffd7a03-ec0e-46c1-a347-e4b19cb7839f",
      label: "a",
      viewingHint: null,
      thumbnail: {
        iiifServiceUrl:
          "https://libimages1.princeton.edu/loris/figgy_prod/f7%2F67%2Ffe%2Ff767fe4247524c5f96e16eba2ff93301%2Fintermediate_file.jp2",
      },
      __typename: "FileSet",
    },
    {
      id: "8f0a0908-317f-414e-a78a-c38a4a3b28e3",
      label: "b",
      viewingHint: null,
      thumbnail: {},
      __typename: "FileSet",
    },
    {
      id: "ea01019e-f644-4416-b99c-1b44bf49d060",
      label: "c",
      viewingHint: null,
      thumbnail: {
        iiifServiceUrl:
          "https://libimages1.princeton.edu/loris/figgy_prod/d9%2Fb5%2F8c%2Fd9b58c8f3e554706bec4d977b12cd4e4%2Fintermediate_file.jp2",
      },
      __typename: "FileSet",
    },
  ],
}

describe("OrderManagerControls.vue", () => {
  beforeEach(() => {
    actions = {
      loadImageCollectionGql: vi.fn(),
      saveStateGql: vi.fn()
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
      orderChanged: () => false,
      stateChanged: () => false
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
          viewingHint: null,
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

    wrapper = mount(OrderManagerControls, {
      options,
      localVue,
      store,
      stubs: ["heading", "input-button", "wrapper"],
    })
  })

  it('will not allow save when nothing has changed', () => {
    expect(wrapper.vm.isDisabled).toBeTruthy()
  })

  it('shows the openseadragon div when a single fileset is selected', () => {
    expect(wrapper.find('heading-stub').exists()).toBe(true)
    expect(wrapper.find('.lux-osd-wrapper').exists()).toBe(true)
  })

  it('displays the Manage Page Files button when one item is selected', () => {
    expect(wrapper.vm.hidden()).toBe(false)
  })

  it('isMultiVolume is false when it is not multi-volume', () => {
    expect(wrapper.vm.isMultiVolume).toBe(false)
  })

  it('maps gallery items to resource, to prepare data for save', () => {
    expect(wrapper.vm.galleryToResource(items)).toEqual(["a", "b", "c"])
  })

  it('tests a number of scenarios once something has changed', async () => {
    actions = {
      loadImageCollectionGql: vi.fn(),
      saveStateGql: vi.fn()
    }

    const changedGetters = {
      orderChanged: () => true,
      stateChanged: () => true
    }

    let changedItems = [
      { id: "c", title: "C", caption: "c", mediaUrl: "https://picsum.photos/600/300/?random" },
      { id: "a", title: "A", caption: "a", mediaUrl: "https://picsum.photos/600/300/?random" },
      { id: "b", title: "B", caption: "b", mediaUrl: "https://picsum.photos/600/300/?random" },
    ]

    const changedGallery = {
      state: {
        items: changedItems,
        selected: [items[0]],
        cut: [],
        changeList: [],
        // changeList: ["2"],
        ogItems: items,
      },
      mutations: modules.galleryModule.mutations,
    }

    const changedResource = {
      state: {
        resource: {
          id: "",
          resourceClassName: "",
          bibId: "",
          label: "Resource not available.",
          thumbnail: "",
          startCanvas: "",
          isMultiVolume: false,
          viewingHint: null,
          viewingDirection: null,
          members: [],
          loadState: "NOT_LOADED",
          saveState: "SAVING",
          ogState: {},
        },
      },
      mutations: resourceMutations,
      getters: changedGetters,
      actions: actions,
      modules: {
        gallery: changedGallery,
      },
    }

    store = new Vuex.Store({
      modules: {
        ordermanager: changedResource,
        gallery: changedGallery,
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

    wrapper = mount(OrderManagerControls, {
      options,
      localVue,
      store,
      stubs: ["alert", "heading", "input-button", "wrapper"],
    })

    // orderChanged should be true when items and ogItems don't match
    expect(wrapper.vm.orderChanged).toBe(true)

    // displays an alert when page order has changed
    expect(wrapper.find('alert-stub').exists()).toBe(true)

    // Disable the button while saving.
    expect(wrapper.vm.isDisabled).toBeTruthy()

    // calls the appropriate action on save
    await wrapper.vm.saveHandler()
    expect(actions.saveStateGql).toHaveBeenCalled()
  })

  it('assures saveStateGql is called for MVWs', () => {
    actions = {
      loadImageCollectionGql: vi.fn(),
      saveStateGql: vi.fn()
    }

    const changedGetters = {
      orderChanged: () => true,
      stateChanged: () => true
    }

    let changedItems = [
      { id: "c", title: "C", caption: "c", mediaUrl: "https://picsum.photos/600/300/?random" },
      { id: "a", title: "A", caption: "a", mediaUrl: "https://picsum.photos/600/300/?random" },
      { id: "b", title: "B", caption: "b", mediaUrl: "https://picsum.photos/600/300/?random" },
    ]

    const changedGallery = {
      state: {
        items: changedItems,
        selected: [items[0]],
        cut: [],
        changeList: [],
        // changeList: ["2"],
        ogItems: items,
      },
      mutations: modules.galleryModule.mutations,
    }

    const changedResource = {
      state: {
        resource: {
          id: "",
          resourceClassName: "",
          bibId: "",
          label: "Resource not available.",
          thumbnail: "",
          startCanvas: "",
          isMultiVolume: true,
          viewingHint: null,
          viewingDirection: null,
          members: [],
          loadState: "NOT_LOADED",
          saveState: "NOT_SAVED",
          ogState: {},
        },
      },
      mutations: resourceMutations,
      getters: changedGetters,
      actions: actions,
      modules: {
        gallery: changedGallery,
      },
    }

    store = new Vuex.Store({
      modules: {
        ordermanager: changedResource,
        gallery: changedGallery,
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

    wrapper = mount(OrderManagerControls, {
      options,
      localVue,
      store,
      stubs: ["alert", "heading", "input-button", "wrapper"],
    })

    // calls the appropriate action on save
    wrapper.vm.saveHandler()
    expect(actions.saveStateGql).toHaveBeenCalled()
  })

  it("has the expected html structure", () => {
    expect(wrapper.element).toMatchSnapshot()
  })
})
