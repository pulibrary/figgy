import Vuex from "vuex"
import { createLocalVue, mount, shallowMount } from "@vue/test-utils"
import StructManagerToolbar from "../components/StructManagerToolbar.vue"
import { resourceMutations, resourceGetters } from "../store/resource"
import { actions } from "../store/vuex/actions"
import { treeMutations } from "../store/tree"
import { zoomMutations, zoomGetters } from "../store/zoom"
import { modules } from 'lux-design-system'

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
  mutations: modules.galleryModule.mutations,
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

let store = new Vuex.Store({
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
      localVue,
      store,
      stubs: [
        "dropdown-menu",
        "input-button",
        "spacer",
        "lux-icon-base",
        "lux-icon-picture",
      ],
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

  it("Selects a Tree item by id", () => {
    wrapper.vm.selectTreeItemById('1234567')
    const parentId = wrapper.vm.tree.selected ? wrapper.vm.tree.selected : wrapper.vm.tree.structure.id
    expect(parentId).toEqual('1234567')
  })

  it("Creates a new folder on a folder object", () => {
    // in the previous test, we select a Tree item that is not a file, so it should get added
    const parentId = wrapper.vm.tree.selected ? wrapper.vm.tree.selected : wrapper.vm.tree.structure.id
    let newFolderId = wrapper.vm.createFolder()
    let parent = wrapper.vm.findFolderById(wrapper.vm.tree.structure.folders, parentId)
    expect(parent.file).toBe(false)
    expect(parent.folders.map(obj => obj.id).includes(newFolderId)).toBe(true)
  })

  it("Save is not disabled when something has changed", () => {
    wrapper.vm.createFolder()
    expect(wrapper.vm.isSaveDisabled()).toBe(false)
  })

  it("Zoom is disabled when nothing is selected", () => {
    wrapper.vm.selectNoneTree()
    wrapper.vm.selectNoneGallery()
    expect(wrapper.vm.isZoomDisabled()).toBe(true)
  })

  it("Removes a nested object by id", () => {
    let nested_object = wrapper.vm.findFolderById(wrapper.vm.tree.structure.folders, 'abc')
    let nested_removed = wrapper.vm.removeNestedObjectById(JSON.parse(JSON.stringify(wrapper.vm.tree.structure.folders)), 'abc')
    let does_not_exist = wrapper.vm.findFolderById(nested_removed, 'abc')
    expect(does_not_exist).toEqual(undefined)
  })

  it("Deletes a folder that contains a file", () => {
    global.confirm = vi.fn(() => true)
    wrapper.vm.deleteFolder("1234567")
    expect(global.confirm).toHaveBeenCalled()
    expect(wrapper.vm.end_nodes.length).toEqual(0)
    expect(wrapper.vm.findFolderById(wrapper.vm.tree.structure.folders, "1234567")).toBe(undefined)
    // puts the deleted file back in the gallery items list
    expect(wrapper.vm.gallery.items.length).toEqual(3)
  })

  it("Cuts Gallery Items", () => {
    wrapper.vm.selectNoneGallery()
    expect(wrapper.vm.isCutDisabled()).toBe(true)
    expect(wrapper.vm.gallery.selected.length).toEqual(0)
    wrapper.vm.selectAll()
    expect(wrapper.vm.gallery.selected.length).toEqual(3)
    expect(wrapper.vm.isCutDisabled()).toBe(false)
    wrapper.vm.cutSelected()
    expect(wrapper.vm.gallery.selected.length).toEqual(0)
    expect(wrapper.vm.gallery.cut.length).toEqual(3)
    expect(wrapper.vm.isCutDisabled()).toBe(true)
  })

  it("Selects a Tree Folder", () => {
    let empty_folder = wrapper.vm.findFolderById(wrapper.vm.tree.structure.folders, "abc")
    expect(empty_folder.folders.length).toEqual(0)
    wrapper.vm.selectTreeItemById("abc")
    expect(wrapper.vm.tree.selected).toEqual("abc")
  })

  it("Pastes a Gallery Item into a Tree Folder", () => {
    wrapper.vm.paste()
    expect(wrapper.vm.gallery.items.length).toEqual(0)
    let pasted_folder = wrapper.vm.findFolderById(wrapper.vm.tree.structure.folders, "abc")
    expect(pasted_folder.folders.length).toEqual(3)
  })

  it("Saves the structure in a format that Figgy accepts", () => {
    wrapper.vm.saveHandler({});
    expect(wrapper.vm.resourceToSave.id).toEqual("aea40813-e0ed-4307-aae9-aec53b26bdda")
    expect(wrapper.vm.resourceToSave.resourceClassName).toEqual("ScannedResource")
    expect(wrapper.vm.resourceToSave.structure.label).toEqual("Table of Contents")
    expect(wrapper.vm.resourceToSave.structure.nodes[0].label).toEqual("Chapter A")
    expect(wrapper.vm.resourceToSave.structure.nodes[0].nodes.length).toEqual(3)
    expect(wrapper.vm.resourceToSave.structure.nodes[0].nodes[0].proxy).toEqual("1")
    expect(wrapper.vm.resourceToSave.structure.nodes[0].nodes[1].proxy).toEqual("2")
    expect(wrapper.vm.resourceToSave.structure.nodes[0].nodes[2].proxy).toEqual("3")
    expect(actions.saveStructureAJAX).toHaveBeenCalled()
  })
})
