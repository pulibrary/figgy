import Vuex from "vuex"
import { createLocalVue, mount, shallowMount } from "@vue/test-utils"
import StructManager from "../components/StructManager.vue"
import DeepZoom from "../components/DeepZoom.vue"
import { resourceMutations, resourceGetters } from "../store/resource"
import { treeMutations } from "../store/tree"
import { zoomMutations, zoomGetters } from "../store/zoom"
import { modules } from 'lux-design-system'

// create an extended `Vue` constructor
const localVue = createLocalVue()
localVue.use(Vuex)

// Work-around in order to ensure that the Global object is accessible from the component
const Global = {
  figgy: {
    resource: {
      defaultThumbnail: "https://institution.edu/repository/assets/random.png"
    }
  }
}
window.Global = Global

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

let resourceObject = {
  id: "aea40813-e0ed-4307-aae9-aec53b26bdda",
  label: "Resource with 3 files",
  viewingHint: "individuals",
  viewingDirection: "LEFTTORIGHT",
  startPage: "1",
  thumbnail: {
    id: "1",
    thumbnailUrl:
      "a1_url",
    iiifServiceUrl: "a1_service",
  },
  __typename: "ScannedResource",
  members: [
    {
      id: "1",
      label: "a",
      viewingHint: "single",
      thumbnail: {
        iiifServiceUrl:
          "a1_service",
      },
      __typename: "FileSet",
    },
    {
      id: "2",
      label: "b",
      viewingHint: null,
      thumbnail: {
        iiifServiceUrl:
          "b2_service",
      },
      __typename: "FileSet",
    },
    {
      id: "3",
      label: "c",
      viewingHint: null,
      thumbnail: {
        iiifServiceUrl:
          "c3_service",
      },
      __typename: "FileSet",
    },
  ],
}
//////////////////////////
let figgy_structure = {
  "id": null,
  "internal_resource": "Structure",
  "created_at": null,
  "updated_at": null,
  "new_record": true,
  "label": [
    "Table of Contents"
  ],
  "nodes": [
    {
      "id": null,
      "internal_resource": "StructureNode",
      "created_at": null,
      "updated_at": null,
      "new_record": true,
      "label": [
        "Chapter 1"
      ],
      "proxy": [],
      "nodes": [
        {
          "id": null,
          "internal_resource": "StructureNode",
          "created_at": null,
          "updated_at": null,
          "new_record": true,
          "label": ['c'],
          "proxy": [
            {
              "id": "3"
            }
          ],
          "nodes": []
        }
      ]
    }
  ]
}
//////////////////////////
let tree_structure = {
  "id": "aea40813-e0ed-4307-aae9-aec53b26bdda",
  "folders": [
    {
      "id": "1234567",
      "label": "Chapter 1",
      "file": false,
      "folders": [
        {
          "id": "3",
          "label": "c",
          "file": true,
          "folders": [],
          "service": "c3_service",
          "mediaUrl": "c3_service/full/300,/0/default.jpg",
          "viewingHint": null
        }
      ]
    }
  ],
  "label": "Table of Contents"
}
//////////////////////////
let unstructured_items = [
  {
    "id": "1",
    "caption": "a",
    "service": "a1_service",
    "mediaUrl": "a1_service/full/300,/0/default.jpg",
    "viewingHint": "single"
  },
  {
    "id": "2",
    "caption": "b",
    "service": "b2_service",
    "mediaUrl": "b2_service/full/300,/0/default.jpg",
    "viewingHint": null
  },
]
const tree = {
  state: {
    selected: "3",
    cut: null,
    structure: { label: "Table of Contents", id: "123", folders: [] },
    modified: false,
    loadState: "NOT_LOADED",
    saveState: "NOT_SAVED",
  },
  mutations: treeMutations,
}

const zoom = {
  state: {
    zoomed: null,
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

const actions = {
  loadImageCollectionGql: vi.fn()
}

let resource = {
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
  getters: resourceGetters,
  actions: actions,
  modules: {
    gallery: gallery,
  },
}

let store = new Vuex.Store({
  modules: {
    ordermanager: resource,
    gallery: gallery,
    zoom: zoom,
    tree: tree,
  },
})

describe("StructManager.vue", () => {
  beforeEach(() => {

    wrapper = mount(StructManager, {
      localVue,
      store,
      propsData: {
        resourceObject: resourceObject,
        structure: figgy_structure,
      },
      stubs: [
        "toolbar",
        "struct-gallery",
        "deep-zoom",
        "tree",
        "wrapper",
        "alert",
        "controls",
        "loader",
      ],
    })
  })

  it("has the right gallery items", () => {
    const items = wrapper.vm.galleryItems
    expect(items[0].caption).toBe("a")
    expect(items[0].mediaUrl).toBe(
      "a1_service/full/300,/0/default.jpg"
    )
    expect(items[1].mediaUrl).toBe("b2_service/full/300,/0/default.jpg")
  })

  it("returns whether or not the resource is Loading", () => {
    expect(wrapper.vm.loading).toBe(false)
  })

  it("returns whether or not the structure has a saveError", () => {
    expect(wrapper.vm.saveError).toBe(false)
  })

  it("has the right selectedTotal", () => {
    expect(wrapper.vm.selectedTotal).toBe(0)
  })

  it("deselects the tree when a gallery is clicked", () => {
    wrapper.vm.galleryClicked()
    expect(wrapper.vm.selectedTreeNode).toBe(null)
  })

  it("resizes cards properly", () => {
    expect(wrapper.vm.cardPixelWidth).toBe(300)
    expect(wrapper.vm.captionPixelPadding).toBe(9)
    wrapper.vm.resizeCards({ target: { value: 70 } })
    expect(wrapper.vm.cardPixelWidth).toBe(70)
    expect(wrapper.vm.captionPixelPadding).toBe(0)
    wrapper.vm.resizeCards({ target: { value: 100 } })
    expect(wrapper.vm.captionPixelPadding).toBe(9)
  })

  it("calls the right action when no resourceObject is passed in", () => {
    // need to remount since the action only fires before mounting
    const wrapper2 = mount(StructManager, {
      localVue,
      store,
      propsData: {
        resourceId: "foo",
      },
      stubs: [
        "toolbar",
        "struct-gallery",
        "deep-zoom",
        "tree",
        "wrapper",
        "alert",
        "controls",
        "loader",
      ],
    })
    expect(actions.loadImageCollectionGql).toHaveBeenCalled()
  })

  it("has the expected html structure", () => {
    expect(wrapper.element).toMatchSnapshot()
  })

  it("renders the links thumbnail", () => {
    expect(wrapper.vm.galleryItems.length).toEqual(3)
    expect(wrapper.vm.galleryItems[0]['mediaUrl']).toEqual('a1_service/full/300,/0/default.jpg')
  })

  it("generates a random id for tree nodes", () => {
    const id1 = wrapper.vm.generateId()
    const id2 = wrapper.vm.generateId()
    expect(id1).not.toEqual(id2)
  })

  it("updates the state of the tree and gallery after resource data is loaded", () => {
    const generateIdStub = vi.fn(() => '1234567')
    wrapper.setMethods({ generateId: generateIdStub })
    // the loading of data should trigger the watcher which calls wrapper.vm.filterGallery(true),
    // but we can test the function
    wrapper.vm.filterGallery(true)
    expect(wrapper.vm.ga).toEqual(unstructured_items)
    expect(wrapper.vm.s).toEqual(tree_structure)
  })
})

describe('when the tree structure errors on Save', () => {

  const error_tree = {
    state: {
      selected: null,
      cut: null,
      structure: { label: "Table of Contents", id: "123", folders: [] },
      modified: false,
      loadState: "NOT_LOADED",
      saveState: "ERROR",
    },
    mutations: treeMutations,
  }

  store = new Vuex.Store({
    modules: {
      ordermanager: resource,
      gallery: gallery,
      zoom: zoom,
      tree: error_tree,
    },
  })

  let wrapper3 = mount(StructManager, {
    localVue,
    store,
    propsData: {
      resourceObject: resourceObject,
      structure: figgy_structure,
    },
    stubs: [
      "toolbar",
      "struct-gallery",
      "deep-zoom",
      "tree",
      "wrapper",
      "alert",
      "controls",
      "loader",
    ],
  })

  it("returns whether or not there was an error on save", () => {
    expect(wrapper3.vm.saveError).toBe(true)
  })

  it("displays an alert with an error message", () => {
    expect(wrapper3.text()).toContain('Sorry, there was a problem saving your work!')
  })
})

describe('when the tree structure is Saved', () => {

  const saved_tree = {
    state: {
      selected: null,
      cut: null,
      structure: { label: "Table of Contents", id: "123", folders: [] },
      modified: false,
      loadState: "NOT_LOADED",
      saveState: "SAVED",
    },
    mutations: treeMutations,
  }

  store = new Vuex.Store({
    modules: {
      ordermanager: resource,
      gallery: gallery,
      zoom: zoom,
      tree: saved_tree,
    },
  })

  let wrapper4 = mount(StructManager, {
    localVue,
    store,
    propsData: {
      resourceObject: resourceObject,
      structure: figgy_structure,
    },
    stubs: [
      "toolbar",
      "struct-gallery",
      "deep-zoom",
      "tree",
      "wrapper",
      "alert",
      "controls",
      "loader",
    ],
  })

  it("returns whether or not the structure is saved", () => {
    expect(wrapper4.vm.saved).toBe(true)
  })

  it("displays an alert with a success message", () => {
    expect(wrapper4.text()).toContain('Your work has been saved!')
  })
})

describe('when an item is zoomed ', () => {

  const zoomed = {
    state: {
      zoomed: {
        "id": "3",
        "caption": "c_fee",
        "service": "c3_service",
        "mediaUrl": "c3_url",
        "viewingHint": null
      },
    },
    mutations: zoomMutations,
    getters: zoomGetters,
  }

  store = new Vuex.Store({
    modules: {
      ordermanager: resource,
      gallery: gallery,
      zoom: zoomed,
      tree: tree,
    },
  })

  let wrapperZoom = mount(StructManager, {
    localVue,
    store,
    propsData: {
      resourceObject: resourceObject,
      structure: figgy_structure,
    },
    stubs: [
      "toolbar",
      "struct-gallery",
      "tree",
      "wrapper",
      "deep-zoom",
      "alert",
      "controls",
      "loader",
    ],
  })

  it("returns whether or not an item is being zoomed", () => {
    expect(wrapperZoom.vm.zoomed.id).toEqual("3")
  })

  it("displays the Zoom modal", () => {
    const zoomModal = wrapper.find('.deep-zoom')
    expect(zoomModal.exists()).toBe(true)
  })
})
