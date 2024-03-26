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
  mutations: modules.galleryModule.mutations,
}

const axions = {
  saveStructureAJAX: vi.fn()
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
    let does_not_exist = wrapper.vm.findFolderById(wrapper.vm.tree.structure.folders, 'abc')
    console.log(JSON.parse(JSON.stringify(wrapper.vm.tree.structure.folders)))
    expect(does_not_exist).toEqual('undefined')
  })

  it("Deletes a folder that contains a file", () => {
    global.confirm = vi.fn(() => true)

    expect(wrapper.vm.end_nodes.length).toEqual(0)
    wrapper.vm.deleteFolder("1234567")
    // expect(global.confirm).toHaveBeenCalled()
    // expect(wrapper.vm.end_nodes.length).toEqual(1)

    // console.log('shoud not exist: ' + JSON.stringify(wrapper.vm.findFolderById(wrapper.vm.tree.structure.folders, "3")))
    // expect(wrapper.vm.findFolderById(wrapper.vm.tree.structure.folders, "12t")).toBe(false)
  })

  // test('triggers a click', async () => {
  //   await wrapper.find('#save_btn').trigger('click')
  //   expect(axions.saveStructureAJAX).toHaveBeenCalled()
  // })



})
