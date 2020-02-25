import Vuex from "vuex"
import { createLocalVue, mount, shallowMount } from "@vue/test-utils"
import OrderManagerFilesetsForm from "../components/OrderManagerFilesetsForm.vue"
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

describe("OrderManagerFilesetsForm.vue", () => {
  beforeEach(() => {
    actions = {
      updateItems: jest.fn(),
      updateChanges: jest.fn()
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

    wrapper = mount(OrderManagerFilesetsForm, {
      options,
      localVue,
      store,
      stubs: ["heading","input-select", "input-text", "input-checkbox"],
    })
  })

  it('allows the update of multiple labels', () => {
    wrapper.vm.updateMultiLabels()
    expect(actions.updateChanges).toHaveBeenCalled()
    expect(actions.updateItems).toHaveBeenCalled()
  })

  it('updates default label when switching pagination method', () => {
    expect(wrapper.vm.labelerOpts().unitLabel).toEqual('p. ')

    wrapper.vm.method = 'foliate'
    expect(wrapper.vm.labelerOpts().unitLabel).toEqual('f. ')

    wrapper.vm.method = 'paginate'
    expect(wrapper.vm.labelerOpts().unitLabel).toEqual('p. ')
  })

  it('does not set frontLabel/backLabel by default', () => {
    expect(wrapper.vm.labelerOpts().frontLabel).toEqual('')
    expect(wrapper.vm.labelerOpts().backLabel).toEqual('')

    wrapper.vm.method = 'foliate'
    expect(wrapper.vm.labelerOpts().frontLabel).toEqual('r. ')
    expect(wrapper.vm.labelerOpts().backLabel).toEqual('v. ')

    wrapper.vm.method = 'paginate'
    expect(wrapper.vm.labelerOpts().frontLabel).toEqual('')
    expect(wrapper.vm.labelerOpts().backLabel).toEqual('')
  })


  it("has the expected html structure", () => {
    expect(wrapper.element).toMatchSnapshot()
  })
})
