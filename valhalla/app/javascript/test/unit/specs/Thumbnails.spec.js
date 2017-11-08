import Vuex from 'vuex'
import { mount, createLocalVue } from 'vue-test-utils'
import Thumbnails from '@/components/Thumbnails'
import Fixtures from '@/test/fixtures/image-collection'
const localVue = createLocalVue()
localVue.use(Vuex)

describe('Thumbnails.vue', () => {
  let wrapper
  let options
  let actions
  let state
  let store

  beforeEach(() => {
    actions = {
      handleSelect: jest.fn(),
      resizeThumbs: jest.fn(()=>{event: {target: {value: '100'}}}),
      sortImages: jest.fn()
    }
    state = {
      images: Fixtures.imageCollection,
      selected: Fixtures.selected,
      ogImages: Fixtures.imageCollection,
      changeList: Fixtures.emptyChangeList
    }
    store = new Vuex.Store({
      state,
      actions
    })

    options = {
      computed: {
        thumbnails: {
          get () {
            return state.images
          }
        },
        changelist: {
          get () {
            return state.changeList
          }
        },
        selected: {
          get () {
            return state.selected
          }
        }
      }
    }

  })

  it('renders a $store.state value return from computed', () => {
    const wrapper = mount(Thumbnails, { options, store, localVue })
    let expanded = wrapper.find('.thumbnail')
    const thumb = expanded.html().replace(/(<(pre|script|style|textarea)[^]+?<\/\2)|(^|>)\s+|\s+(?=<|$)/g, "$1$3")
    expect(thumb).toEqual('<div class="thumbnail" style="max-width: 200px;"><img src="http://example.com" class="thumb"><div class="caption" style="padding: 9px;">baz</div></div>')
  })

  it('has the expected html structure', () => {
    const wrapper = mount(Thumbnails, { options, store, localVue })
    expect(wrapper.element).toMatchSnapshot()
  })

  it('allows the selection of a thumbnail', () => {
    const wrapper = mount(Thumbnails, { options, store, localVue })
    wrapper.find('.thumbnail').trigger('click')
    expect(actions.handleSelect).toHaveBeenCalled()
  })

  it('allows the selection of multiple thumbnails via Shift+click', () => {
    const wrapper = mount(Thumbnails, { options, store, localVue })
    wrapper.findAll('.thumbnail').at(0).trigger('click')
    wrapper.findAll('.thumbnail').at(1).trigger('click', {
      shiftKey: true
    })

    // the first click selects one element, while the second sekects two (with Shift+Click)
    expect(actions.handleSelect.mock.calls[0][1].length).toBe(1)
    expect(actions.handleSelect.mock.calls[1][1].length).toBe(2)
    expect(actions.handleSelect.mock.calls.length).toBe(2)

  })

  // Todo: once the above can pass write one for selection of multiples via META+click

  it('selects all thumbnails when Select All button is clicked', () => {
    const wrapper = mount(Thumbnails, { options, store, localVue })
    wrapper.find('#select_all_btn').trigger('click')
    expect(actions.handleSelect).toHaveBeenCalled()
  })

  it('selects alternate thumbnails when Select Alternate button is clicked', () => {
    const wrapper = mount(Thumbnails, { options, store, localVue })
    wrapper.find('#select_alternate_btn').trigger('click')
    expect(actions.handleSelect).toHaveBeenCalled()
  })

  it('selects inverse thumbnails when Select Inverse button is clicked', () => {
    const wrapper = mount(Thumbnails, { options, store, localVue })
    wrapper.find('#select_inverse_btn').trigger('click')
    expect(actions.handleSelect).toHaveBeenCalled()
  })

  it('deselects all thumbnails when Select None button is clicked', () => {
    const wrapper = mount(Thumbnails, { options, store, localVue })
    wrapper.find('#select_none_btn').trigger('click')
    expect(actions.handleSelect).toHaveBeenCalled()
  })

  it('changes thumbnail size when range input changes', () => {
    const wrapper = mount(Thumbnails, { options, store, localVue })
    const input = wrapper.find('#resize_thumbs_input')
    input.element.value = 100
    input.trigger('input')
    const resizedThumb = wrapper.find('.thumbnail')
    expect(resizedThumb.hasStyle('max-width', '100px')).toBe(true)
  })


})
