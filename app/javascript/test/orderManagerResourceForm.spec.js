import Vuex from "vuex"
import { createLocalVue, mount, shallowMount } from "@vue/test-utils"
import OrderManagerResourceForm from "../components/OrderManagerResourceForm.vue"
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
  { id: "a", title: "A", viewingHint: "single", caption: "a", mediaUrl: "https://picsum.photos/600/300/?random" },
  { id: "b", title: "B", caption: "b", mediaUrl: "https://picsum.photos/600/300/?random" },
  { id: "c", title: "C", caption: "c", mediaUrl: "https://picsum.photos/600/300/?random" },
]

describe("OrderManagerResourceForm.vue", () => {
  beforeEach(() => {
    actions = {
      updateViewHint: vi.fn(),
      updateViewDir: vi.fn()
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
      getMemberCount: () => 3
    }

    const resource = {
      state: {
        resource: {
          id: "",
          resourceClassName: "",
          bibId: "4609321",
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
        viewingDirection: function () {
          return 'bottom-to-top'
        },
        viewingHint: function () {
          return 'continuous'
        }
      }
    }

    wrapper = mount(OrderManagerResourceForm, {
      options,
      localVue,
      store,
      stubs: ["heading","input-radio","text-style"],
    })
  })

  it('allows the selection of a viewing direction', () => {
    wrapper.find('#viewDir').trigger('change')
    wrapper.vm.updateViewDir('LEFTTORIGHT')
    expect(actions.updateViewDir).toHaveBeenCalled()
  })

  it('allows the selection of a viewing hint', () => {
    wrapper.vm.updateViewHint('individuals')
    expect(actions.updateViewHint).toHaveBeenCalled()
  })

  it('displays the correct image (aka, fileset) count', () => {
    const expanded = wrapper.find('.lux-file_count')
    const fileCount = expanded.text()
    expect(fileCount).toEqual('Total files: 3')
  })

  it('displays the bibid, if it has one', () => {
    const expanded = wrapper.find('.lux-bibid')
    const bibid = expanded.text()
    expect(bibid).toEqual('| BibId: 4609321')
  })

  it("has the expected html structure", () => {
    expect(wrapper.element).toMatchSnapshot()
  })
})
