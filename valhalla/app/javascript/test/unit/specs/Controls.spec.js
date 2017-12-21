import Vuex from 'vuex'
import { mount, createLocalVue } from 'vue-test-utils'
import Controls from '@/components/Controls'
import Fixtures from '@/test/fixtures/image-collection'
const localVue = createLocalVue()
localVue.use(Vuex)

describe('Controls.vue', () => {
  let wrapper
  let options
  let actions
  let getters
  let state
  let store

  beforeEach(() => {
    actions = {
      saveState: jest.fn()
    }
    getters = {
      orderChanged: () => false,
      stateChanged: () => false,
      imageIdList: () => ['e7208ea3-21f3-43d4-9b14-489e15e9791e',
                          '50b5e49b-ade7-4278-8265-4f72081f26a5',
                          'dae7619f-16a7-4306-93e4-70b4b192955c',
                          'b484cd88-fdf2-477c-afe9-d46a49d8822b',
                          '80b02791-4bd9-4566-9a9f-4b3062ba2e0d',
                          '0a3e268f-5872-444e-bdbd-b1a7b01dcb57']
    }
    state = Fixtures.initState
    store = new Vuex.Store({
      getters,
      actions,
      state
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
  })

  it('will not allow save when nothing has changed', () => {
    const wrapper = mount(Controls, { options, store, localVue })
    expect(wrapper.vm.isDisabled).toBeTruthy()
  })

  // make sure saveState button can be tested
  it('allows save once something has changed', () => {
    actions = {
      saveState: jest.fn()
    }
    getters = {
      orderChanged: () => true,
      stateChanged: () => true
    }
    state = Fixtures.initState
    store = new Vuex.Store({
      getters,
      actions,
      state
    })

    const wrapper = mount(Controls, { options, store, localVue })

    expect(wrapper.find('#save_btn').exists()).toBeTruthy()
    wrapper.find('#save_btn').trigger('click')
    expect(actions.saveState).toHaveBeenCalled()
  })

  it('has the expected html structure', () => {
    const wrapper = mount(Controls, { options, store, localVue })
    expect(wrapper.element).toMatchSnapshot()
  })

})
