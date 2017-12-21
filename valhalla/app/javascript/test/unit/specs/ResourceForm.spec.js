import Vuex from 'vuex'
import { mount, createLocalVue } from 'vue-test-utils'
import ResourceForm from '@/components/ResourceForm'
const localVue = createLocalVue()
localVue.use(Vuex)

describe('ResourceForm.vue', () => {
  let wrapper
  let options
  let actions
  let state
  let store

  beforeEach(() => {
    actions = {
      updateViewDir: jest.fn(),
      updateViewHint: jest.fn()
    }
    state = {
      viewingDirection: 'bottom-to-top',
      viewingHint: 'continuous'
    }
    store = new Vuex.Store({
      state,
      actions
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
  })

  // it('renders a $store.state value return from computed', () => {
  //   expect(cmp.find('#detail_img').html()).toEqual('<img id="detail_img" src="http://localhost:3000/image-service/50b5e49b-ade7-4278-8265-4f72081f26a5/full/400,/0/default.jpg">')
  // })

  it('allows the selection of a viewing direction', () => {
    const wrapper = mount(ResourceForm, { options, store, localVue })
    wrapper.find('.viewDirInput').trigger('change')
    expect(actions.updateViewDir).toHaveBeenCalled()
  })

  it('allows the selection of a viewing hint', () => {
    const wrapper = mount(ResourceForm, { options, store, localVue })
    wrapper.find('.viewHintInput').trigger('change')
    expect(actions.updateViewHint).toHaveBeenCalled()
  })

  it('has the expected html structure', () => {
    const wrapper = mount(ResourceForm, { options, store, localVue })
    expect(wrapper.element).toMatchSnapshot()
  })

})
