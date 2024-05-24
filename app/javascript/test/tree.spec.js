import { nextTick } from 'vue'
import { createStore } from 'vuex'
import { mount, shallowMount } from "@vue/test-utils"
import Tree from "../components/Tree.vue"
import mixin from "../components/structMixins"
import store from "../store"

let wrapper
const delay = ms => new Promise(res => setTimeout(res, ms));
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

describe("Tree.vue", () => {
  beforeEach( async () => {
    store.commit('SET_STRUCTURE', tree_structure)
    wrapper =  mount(Tree, {
      attachTo: document.body,
      global: {
        plugins: [store],
        stubs: [
          "lux-media-image",
          "lux-icon-base",
          "lux-icon-end-node",
        ],
        mixins: [mixin]
      },
      props: {
        id: tree_structure.id,
        jsonData: tree_structure,
      },
      sync: false,
    })
  })

  test('renders with a root that has the root class', () => {
    expect(wrapper.find('ul').classes()).toEqual([ 'lux-tree', 'root' ])
    expect(wrapper.findAll('ul.root').length).toEqual(1)
  })

  test('clicking createFolder emits a create-folder event', () => {
    wrapper.findAll('lux-input-button.create-folder')[0].trigger('button-clicked')
    expect(wrapper.emitted()).toHaveProperty('create-folder')
  })

  test('clicking deleteFolder emits a delete-folder event', () => {
    wrapper.findAll('.delete-folder')[0].trigger('button-clicked')
    expect(wrapper.emitted()).toHaveProperty('delete-folder')
  })

  test('clicking zoomFile emits a zoom-file event', () => {
    wrapper.findAll('.zoom-file')[0].trigger('button-clicked')
    expect(wrapper.emitted()).toHaveProperty('zoom-file')
  })

  test('toggling the expand-collapse button shows and hides the children', async () => {
    await wrapper.findAll('lux-input-button.expand-collapse')[0].trigger('button-clicked')
    expect(wrapper.find('.lux-tree-sub').isVisible()).toBe(false)
    await wrapper.findAll('lux-input-button.expand-collapse')[0].trigger('button-clicked')
    await nextTick()
    expect(wrapper.find('.lux-tree-sub').isVisible()).toBe(true)
  })

  test('Viewing direction is implemented by the viewingDirection prop', async () => {
    expect(wrapper.findAll('.folder-label')[1].attributes('dir')).toEqual('ltr')
    await wrapper.setProps({ viewingDirection: 'RIGHTTOLEFT' })
    expect(wrapper.findAll('.folder-label')[1].attributes('dir')).toEqual('rtl')
  })

  ///////////////////////////////////////////////////////////////////////////
  // Tree node selection works in the UI due to the reliance on the tree store,
  // but not in this isolated test case. Testing selection features in capybara instead.
  // -----------------------------------------------------------------
  // To get the test below to pass, we need to refactor the Tree to
  // pass selected as a prop but not edit it locally, and just send the event
  // upwards to the root.
  // See the directory_picker component for implementation details
  ///////////////////////////////////////////////////////////////////////////
  // test('clicking a node selects the node and its children', async () => {
  //   await wrapper.findAll('.folder-label').at(0).trigger('click.capture')
  //   expect(wrapper.findAll('.selected').length).toEqual(4)
  //   await wrapper.findAll('.folder-label').at(2).trigger('click')
  //   expect(wrapper.findAll('.selected').length).toEqual(2)
  // })

})
