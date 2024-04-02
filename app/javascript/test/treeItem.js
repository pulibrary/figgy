import Vuex from "vuex"
import { createLocalVue, mount, shallowMount } from "@vue/test-utils"
import TreeItem from "../components/TreeItem.vue"
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

let store = new Vuex.Store({
  modules: {
    gallery: gallery,
    zoom: zoom,
    tree: tree,
  },
})

describe("TreeItem.vue", () => {
  beforeEach(() => {

    wrapper = mount(TreeItem, {
      localVue,
      store,
      propsData: {
        id: '12345',
        jsonData: figgy_structure,
      },
      stubs: [
        "lux-icon-base",
        "media-image",
        "input-button",
      ],
    })
  })
  //
  it("root node can be selected", () => {
    wrapper.vm.select('123',{});
    expect(wrapper.vm.tree.selected).toEqual("123")
  })
  //
  // it("root node label can be edited", () => {
  // })
  //
  // it("root node cannot be deleted", () => {
  // })
  //
  // it("node can be selected", () => {
  //
  // })
  //
  // it("node label can be edited", () => {
  // })
  //
  // it("node can be deleted", () => {
  // })
  //
  // it("node can be opened and closed", () => {
  // })
  //
  // it("folder can have a child", () => {
  // })
  //
  // it("file cannot have a child", () => {
  // })
  //
  // it("folder can be cut with its children", () => {
  // })
  //
  // it("folder can be pasted with its children", () => {
  // })

})
