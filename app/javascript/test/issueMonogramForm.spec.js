import { createLocalVue, mount, shallowMount } from "@vue/test-utils"
import flushPromises from 'flush-promises'
import IssueMonogramForm from "../components/issue_monogram_form.vue"
import moxios from 'moxios'
// import jest from 'jest'
jest.mock('axios')

// create an extended `Vue` constructor
const localVue = createLocalVue()

describe("IssueMonogramForm.vue", () => {
  const options = {
  }

  const wrapper = mount(IssueMonogramForm, {
    options,
    localVue
  })

  beforeEach(() => {
    moxios.install()
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

  it('transmits a POST request when a new monogram is requested', async done => {
    wrapper.vm.title = 'test monogram'
    wrapper.find('input[type="submit"]').trigger('click')
    const eventMap = {}
    const originalMethod = window.addEventListener
    const mockHandler = jest.fn((e) => e)
    window.addEventListener = jest.fn((event) => {
      eventMap[event] = mockHandler
    })

    moxios.stubRequest('', {
      status: 200,
      responseText: JSON.stringify({ data: { id: { id: 'test-id' } } })
    })

    moxios.wait(() => {
      expect(eventMap.hasOwnProperty('attach-monogram'))
      done()
    })

    window.addEventListener = originalMethod
  })

  it('transmits a POST request when a new monogram is requested', () => {
    wrapper.vm.title = 'test monogram'
    wrapper.find('input[type="submit"]').trigger('click')
    wrapper.vm.$nextTick( () => {
      // expect axios to have received
      // done()
    })
  })
})
