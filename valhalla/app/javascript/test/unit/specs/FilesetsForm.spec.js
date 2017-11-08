import 'babel-polyfill'
import Vuex from 'vuex'
import { mount, createLocalVue } from 'vue-test-utils'
import FilesetsForm from '@/components/FilesetsForm'
import Fixtures from '@/test/fixtures/image-collection'
const localVue = createLocalVue()
localVue.use(Vuex)

describe('FilesetsForm.vue', () => {
  let wrapper
  let options
  let actions
  let state
  let store

  beforeEach(() => {
    actions = {
      updateChanges: jest.fn(),
      updateImages: jest.fn()
    }
    state = {
      images: Fixtures.imageCollection,
      selected: Fixtures.multipleSelected,
      changeList: Fixtures.changeList,
      thumbnail: Fixtures.thumbnail,
      startPage: Fixtures.startPage
    }
    store = new Vuex.Store({
      state,
      actions
    })

    options = {
      computed: {
        selectedTotal () {
          return state.selected.length
        }
      }
    }
  })

  it('allows the update of multiple labels', () => {
    const wrapper = mount(FilesetsForm, { options, store, localVue })
    wrapper.find('#unitLabel').trigger('input')
    expect(actions.updateChanges).toHaveBeenCalled()
    expect(actions.updateImages).toHaveBeenCalled()
  })

  it('has the expected html structure', () => {
    const wrapper = mount(FilesetsForm, { options, store, localVue })
    expect(wrapper.element).toMatchSnapshot()
  })

})
