import { createStore } from 'vuex'
import { mount, shallowMount } from "@vue/test-utils"
import StructManagerToolbar from "../components/StructManagerToolbar.vue"
import { resourceMutations, resourceGetters } from "../store/resource"
import { actions } from "../store/vuex/actions"
import { treeMutations } from "../store/tree"
import { zoomMutations, zoomGetters } from "../store/zoom"
import { galleryModule } from '../store/gallery'

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
  }
]

//////////////////////////
let figgy_structure = {
  "id": "89e28e8f-2025-4ef6-bf10-a7be36cabfbe",
  "resourceClassName": "ScannedResource",
  "structure": {
    "label": "Table of Contents",
    "nodes": [
      {
        "nodes": [],
        "label": "Chapter 1"
      },
      {
        "nodes": [
          {
            "proxy": "1c3e9ca9-7aa0-4f4d-957f-f42cb43c254a"
          },
          {
            "proxy": "ba6731e9-f8a7-4065-a4eb-f422926b3719"
          },
          {
            "proxy": "50be643a-4225-4424-ab3e-964b8edccead"
          }
        ],
        "label": "Chapter 2"
      }
    ]
  }
}
//////////////////////////
let tree_structure = {
  "id": "aea40813-e0ed-4307-aae9-aec53b26bdda",
  "folders": [
    {
      "id": "abc",
      "label": "Chapter A",
      "file": false,
      "folders": [],
    },
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
    structure: tree_structure,
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

actions = {
  saveStructureAJAX: vi.fn(),
}

const gallery = {
  state: {
    items: items,
    selected: [],
    cut: [],
    changeList: ["2"],
    ogItems: items,
  },
  mutations: galleryModule.mutations,
}

// let saveStructureAJAX: vi.fn();

let resource = {
  state: {
    resource: {
      id: "aea40813-e0ed-4307-aae9-aec53b26bdda",
      resourceClassName: "ScannedResource",
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
  modules: {
    gallery: gallery,
  },
}

const store = createStore({
  actions: actions,
  modules: {
    ordermanager: resource,
    gallery: gallery,
    zoom: zoom,
    tree: tree,
  },
})


describe("StructManagerToolbar.vue", () => {
  beforeEach(() => {

    wrapper = mount(StructManagerToolbar, {
      global: {
        plugins: [store],
        stubs: [
          "dropdown-menu",
          "spacer",
          "lux-icon-base",
          "lux-icon-picture",
        ],
      }
    })
  })

  it("Save is disabled when nothing has changed", () => {
    expect(wrapper.vm.isSaveDisabled()).toBe(true)
  })

  it("Zoom is not disabled when a Tree item with a service is selected", () => {
    // since we mounted with a selected Tree item, Zoom should not be disabled
    expect(wrapper.vm.isZoomDisabled()).toBe(false)
  })

  it("Does not create a new folder on a file object", () => {
    // we mounted with a selected Tree item that is a file, so it should not have been added
    const parentId = wrapper.vm.tree.selected ? wrapper.vm.tree.selected : wrapper.vm.tree.structure.id
    let newFolderId = wrapper.vm.createFolder()
    let parent = wrapper.vm.findFolderById(wrapper.vm.tree.structure.folders, parentId)
    expect(parent.file).toBe(true)
    expect(parent.folders.map(obj => obj.id).includes(newFolderId)).toBe(false)
  })

  it('Emits a save-structure custom event when Save Structure is clicked', async () => {
    // we need to modify the structure to disable Save
    store.commit('SET_MODIFIED', true)
    expect(wrapper.vm.isSaveDisabled()).toBe(false)
    await wrapper.findAll('#save_btn')[0].trigger('button-clicked')
    expect(wrapper.emitted()).toHaveProperty('save-structure')
  })

})
