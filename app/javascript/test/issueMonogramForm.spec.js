import { createLocalVue, mount, shallowMount } from "@vue/test-utils"
import flushPromises from 'flush-promises'
import IssueMonogramForm from "../components/issue_monogram_form.vue"
import moxios from 'moxios'

jest.mock('axios')

// create an extended `Vue` constructor
const localVue = createLocalVue()

describe("IssueMonogramForm.vue", () => {
  let wrapper

  const response = {
    data: {
      id: {
        id: 'test-id'
      }
    }
  }

  beforeEach(() => {
    moxios.install()

    wrapper = mount(IssueMonogramForm, {
      localVue
    })
  })

  afterEach(() => {
    moxios.uninstall()
  })

  it('disables form submissions when the component is mounted', () => {
    expect(wrapper.vm.disabled).toBeTruthy()
  })

  it('enables form submissions when the title for a new monogram is entered', () => {
    wrapper.vm.title = 'test monogram'
    expect(wrapper.vm.disabled).toBeFalsy()
  })

  it('disables form submissions when a new monogram has been requested', () => {
    wrapper.vm.title = 'test monogram'
    wrapper.vm.requesting = true
    expect(wrapper.vm.disabled).toBeTruthy()
    wrapper.vm.requesting = false
    expect(wrapper.vm.disabled).toBeFalsy()
  })

  describe('#reset', () => {
    it('clears the ID for a newly-created Monogram and the title', () => {
      wrapper.vm.title = 'test monogram'
      wrapper.vm.id = 'test-id'
      wrapper.vm.reset()
      expect(wrapper.vm.title).toBeFalsy()
      expect(wrapper.vm.id).toBeFalsy()
    })
  })

  describe('#created', () => {
    it('parses the response from the Rails Controller endpoint and mutates "id"', () => {
      expect(wrapper.vm.id).toBeFalsy()
      wrapper.vm.created(response)
      expect(wrapper.vm.id).toEqual('test-id')
    })
  })

  it('transmits a POST request when a new monogram is requested', () => {
    const originalMethod = window.dispatchEvent
    const mockHandler = jest.fn(e => e)
    window.dispatchEvent = mockHandler

    moxios.wait(() => {
      moxios.stubRequest(wrapper.vm.action, {
        status: 200,
        responseText: JSON.stringify(response)
      })

      wrapper.vm.title = 'test monogram'
      wrapper.find('form').trigger('submit')
      expect(wrapper.vm.id).toEqual('test-id')
    })

    window.dispatchEvent = originalMethod
  })
})
