import { createStore } from "vuex"
import { mount, shallowMount } from "@vue/test-utils"
import StructManager from "../components/StructManager.vue"
import mixin from "../components/structMixins"
import DeepZoom from "../components/DeepZoom.vue"
import { resourceMutations, resourceGetters } from "../store/resource"
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
  },
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
    }
  ],
}
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
            "proxy": "3"
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

const actions = {
  loadImageCollectionGql: vi.fn(),
  saveStructureAJAX: vi.fn(),
}

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
  actions: actions,
}

let store = createStore({
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
      global: {
        plugins: [store],
        mixins: [mixin],
        stubs: [
          "toolbar",
          "deep-zoom",
          "controls",
          "lux-loader",
          "lux-heading",
          "lux-media-image",
          "lux-icon-base",
          "lux-text-style",
          "lux-input-button",
          "lux-card",
          "lux-wrapper",
        ],
      },
      props: {
        resourceObject: resourceObject,
        structure: figgy_structure,
      },
    })
  })

  it("has the right gallery items", () => {
    let items = wrapper.vm.galleryItems
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

  it("Selects a Tree Folder", () => {
    let empty_folder = wrapper.vm.findFolderById(wrapper.vm.tree.structure.folders, "abc")
    expect(empty_folder.folders.length).toEqual(0)
    wrapper.vm.selectTreeItemById("abc")
    expect(wrapper.vm.tree.selected).toEqual("abc")
  })

  it("Creates a new folder on a folder object", () => {
    // in the previous test, we select a Tree item that is not a file, so it should get added
    let parentId = wrapper.vm.tree.selected ? wrapper.vm.tree.selected : wrapper.vm.tree.structure.id
    let newFolderId = wrapper.vm.createFolder(parentId)
    let parent = wrapper.vm.findFolderById(wrapper.vm.tree.structure.folders, parentId)
    expect(parent.file).toBe(false)
    expect(parent.folders.map(obj => obj.id).includes(newFolderId)).toBe(true)
  })

  it("resizes cards properly", () => {
    expect(wrapper.vm.cardPixelWidth).toBe(150)
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
      global: {
        plugins: [store],
        mixins: [mixin],
        stubs: [
          "toolbar",
          "deep-zoom",
          "controls",
          "lux-loader",
          "lux-heading",
          "lux-media-image",
          "lux-icon-base",
          "lux-text-style",
          "lux-input-button",
          "lux-card",
          "lux-wrapper",
        ],
      },
      props: {
        resourceId: "foo",
        structure: figgy_structure,
      },
    })
    expect(actions.loadImageCollectionGql).toHaveBeenCalled()
  })

  it("has the expected html structure", () => {
    expect(wrapper.element).toMatchSnapshot()
  })

  it("renders the links thumbnail", () => {
    expect(wrapper.vm.gallery.items.length).toEqual(2)
    expect(wrapper.vm.gallery.items[0]['mediaUrl']).toEqual('a1_service/full/300,/0/default.jpg')
  })

  it("generates a random id for tree nodes", () => {
    const id1 = wrapper.vm.generateId()
    const id2 = wrapper.vm.generateId()
    expect(id1).not.toEqual(id2)
  })

  it("Selects a Tree item by id", () => {
    wrapper.vm.selectTreeItemById('1234567')
    const parentId = wrapper.vm.tree.selected ? wrapper.vm.tree.selected : wrapper.vm.tree.structure.id
    expect(parentId).toEqual('1234567')
  })

  it("Removes a nested object by id", () => {
    let nested_removed = wrapper.vm.removeNestedObjectById(JSON.parse(JSON.stringify(wrapper.vm.tree.structure.folders)), 'abc')
    let does_not_exist = wrapper.vm.findFolderById(nested_removed, 'abc')
    expect(does_not_exist).toEqual(null)
  })

  it("Deletes a folder that contains a file", () => {
    global.confirm = vi.fn(() => true)
    wrapper.vm.deleteFolder("1234567")
    expect(global.confirm).toHaveBeenCalled()
    expect(wrapper.vm.end_nodes.length).toEqual(0)
    expect(wrapper.vm.findFolderById(wrapper.vm.tree.structure.folders, "1234567")).toBe(null)
    // puts the deleted file back in the gallery items list
    expect(wrapper.vm.gallery.items.length).toEqual(3)
  })

  it("Cuts Gallery Items", () => {
    wrapper.vm.selectNoneGallery()
    expect(wrapper.vm.gallery.selected.length).toEqual(0)
    wrapper.vm.selectAllGallery()
    expect(wrapper.vm.gallery.selected.length).toEqual(2)
    wrapper.vm.cutSelected()
    expect(wrapper.vm.gallery.selected.length).toEqual(0)
    expect(wrapper.vm.gallery.cut.length).toEqual(2)
  })

  it("Selects a Tree Folder", () => {
    let folder = wrapper.vm.findFolderById(wrapper.vm.tree.structure.folders, "abc")
    expect(folder.folders.length).toEqual(1)
    wrapper.vm.selectTreeItemById("abc")
    expect(wrapper.vm.tree.selected).toEqual("abc")
  })

  it("Pastes a Gallery Item into a Tree Folder", () => {
    wrapper.vm.paste()
    let pasted_folder = wrapper.vm.findFolderById(wrapper.vm.tree.structure.folders, "abc")
    expect(pasted_folder.folders.length).toEqual(3)
  })

  it("Saves the structure in a format that Figgy accepts", () => {
    wrapper.vm.saveHandler({})
    expect(wrapper.vm.resourceToSave.id).toEqual("aea40813-e0ed-4307-aae9-aec53b26bdda")
    expect(wrapper.vm.resourceToSave.resourceClassName).toEqual("ScannedResource")
    expect(wrapper.vm.resourceToSave.structure.label).toEqual("Table of Contents")
    expect(wrapper.vm.resourceToSave.structure.nodes[0].label).toEqual("Chapter A")
    expect(wrapper.vm.resourceToSave.structure.nodes[0].nodes.length).toEqual(3)
    expect(wrapper.vm.resourceToSave.structure.nodes[0].nodes[1].proxy).toEqual("1")
    expect(wrapper.vm.resourceToSave.structure.nodes[0].nodes[2].proxy).toEqual("2")
    expect(actions.saveStructureAJAX).toHaveBeenCalled()
  })
})


describe('when the tree structure errors on Save', () => {

  const error_tree = {
    state: {
      selected: null,
      cut: null,
      structure: tree_structure,
      modified: false,
      loadState: "NOT_LOADED",
      saveState: "ERROR",
    },
    mutations: treeMutations,
  }

  store = createStore({
    modules: {
      ordermanager: resource,
      gallery: gallery,
      zoom: zoom,
      tree: error_tree,
    },
  })

  let wrapper3 = mount(StructManager, {
    global: {
      plugins: [store],
      mixins: [mixin],
      stubs: [
        "toolbar",
        "struct-gallery",
        "tree",
        "lux-wrapper",
        "deep-zoom",
        "controls",
        "lux-loader",
      ],
    },
    props: {
      resourceObject: resourceObject,
      structure: figgy_structure,
    },
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

  store = createStore({
    modules: {
      ordermanager: resource,
      gallery: gallery,
      zoom: zoom,
      tree: saved_tree,
    },
  })

  let wrapper4 = mount(StructManager, {
    global: {
      plugins: [store],
      mixins: [mixin],
      stubs: [
        "toolbar",
        "struct-gallery",
        "tree",
        "lux-wrapper",
        "deep-zoom",
        "controls",
        "lux-loader",
        "lux-heading",
      ],
    },
    props: {
      resourceObject: resourceObject,
      structure: figgy_structure,
    },
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

  store = createStore({
    modules: {
      ordermanager: resource,
      gallery: gallery,
      zoom: zoomed,
      tree: tree,
    },
  })

  let wrapperZoom = mount(StructManager, {
    global: {
      plugins: [store],
      mixins: [mixin],
      stubs: [
        "toolbar",
        "struct-gallery",
        "tree",
        "lux-wrapper",
        "deep-zoom",
        "lux-alert",
        "controls",
        "lux-loader",
        "lux-heading",
      ],
    },
    props: {
      resourceObject: resourceObject,
      structure: figgy_structure,
    },
  })

  it("returns whether or not an item is being zoomed", () => {
    expect(wrapperZoom.vm.zoomed.id).toEqual("3")
  })

  it("displays the Zoom modal", () => {
    const zoomModal = wrapper.find('.deep-zoom')
    expect(zoomModal.exists()).toBe(true)
  })
})
