import Vuex from 'vuex'
import { shallow, mount, createLocalVue } from 'vue-test-utils'
import FilesetForm from '@/components/FilesetForm'
import Fixtures from '@/test/fixtures/image-collection'
const localVue = createLocalVue()
localVue.use(Vuex)

describe('FilesetForm.vue', () => {
  let wrapper
  let options
  let actions
  let state
  let store
  let cmp

  beforeEach(() => {
    actions = {
      updateStartPage: jest.fn(),
      updateThumbnail: jest.fn(),
      updateChanges: jest.fn(),
      updateImages: jest.fn()
    }
    state = {
      images: Fixtures.imageCollection,
      selected: Fixtures.selected,
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
        thumbnail: function () {
          return state.thumbnail
        },
        startPage: function () {
          return state.startPage
        },
        isStartPage () {
          var id = state.selected[0].id
          return state.startPage === id
        },
        isThumbnail () {
          var id = state.selected[0].id
          return state.thumbnail === id
        },
        singleForm () {
          return {
            label: state.selected[0].label,
            id: state.selected[0].id,
            page_type: state.selected[0].page_type,
            url: state.selected[0].url,
            editLink: '/catalog/parent/' + state.id + '/' + state.selected[0].id
          }
        }
      }
    }
  })

  it('allows the selection of a thumbnail image', () => {
    const wrapper = mount(FilesetForm, { options, store, localVue })
    wrapper.find('#isThumbnail').trigger('change')
    expect(actions.updateThumbnail).toHaveBeenCalled()
  })

  it('allows the selection of a start page', () => {
    const wrapper = mount(FilesetForm, { options, store, localVue })
    wrapper.find('#isStartPage').trigger('change')
    expect(actions.updateStartPage).toHaveBeenCalled()
  })

  it('allows the selection of a page type', () => {
    const wrapper = mount(FilesetForm, { options, store, localVue })
    wrapper.find('#pageType').trigger('change')
    expect(actions.updateChanges).toHaveBeenCalled()
    expect(actions.updateImages).toHaveBeenCalled()
  })

  it('allows the input of a label', () => {
    const wrapper = mount(FilesetForm, { options, store, localVue })
    wrapper.find('#label').trigger('input')
    expect(actions.updateChanges).toHaveBeenCalled()
    expect(actions.updateImages).toHaveBeenCalled()
  })

  it('has a singleForm function that conforms to the images data structure', () => {
    cmp = shallow(FilesetForm, { options, store, localVue })
    for (var key in state.selected[0]) {
      if (state.selected[0].hasOwnProperty(key)) {
        expect(cmp.vm.singleForm.hasOwnProperty(key)).toBeTruthy()
      }
    }
  })

  it('has the expected html structure', () => {
    const wrapper = mount(FilesetForm, { options, store, localVue })
    expect(wrapper.element).toMatchSnapshot()
  })

})
