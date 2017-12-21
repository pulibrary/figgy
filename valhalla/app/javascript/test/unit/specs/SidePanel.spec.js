import 'babel-polyfill'
import Vuex from 'vuex'
import { shallow, createLocalVue } from 'vue-test-utils'
import SidePanel from '@/components/SidePanel'
const localVue = createLocalVue()
localVue.use(Vuex)

describe('SidePanel.vue', () => {
  let wrapper

  beforeEach(() => {
    wrapper = shallow(SidePanel, {
      computed: {
        selectedTotal () {
          return 2
        }
      },
      localVue
    })
  })

  it('selectedTotal function has the expected value', () => {
    expect(wrapper.vm.selectedTotal).toBe(2)
  })

  it('has the expected html structure', () => {
    expect(wrapper.element).toMatchSnapshot()
  })

})
