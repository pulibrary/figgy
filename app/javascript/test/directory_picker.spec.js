import { mount } from '@vue/test-utils'
import DirectoryPicker from '../components/directory_picker.vue'
import flushPromises from 'flush-promises'

const startChildren = () => {
  return [
    {
      'label': 'Dir1',
      'path': '/Dir1',
      'expanded': true,
      'expandable': true,
      'selected': false,
      'selectable': false,
      'loaded': true,
      'children': [
        {
          'label': 'Subdir1',
          'path': '/Dir1/Subdir1',
          'expanded': false,
          'expandable': true,
          'selected': false,
          'selectable': true,
          'loaded': true,
          'children': [
            {
              'label': 'SubSubdir1',
              'path': '/Dir1/Subdir1/SubSubdir1',
              'loadChildrenPath': '/loaders/test',
              'expanded': false,
              'expandable': true,
              'selected': false,
              'selectable': false,
              'loaded': false,
              'children': []
            },
            {
              'label': 'SubSubdir2',
              'path': '/Dir1/Subdir1/SubSubdir2',
              'expanded': false,
              'expandable': true,
              'selected': false,
              'selectable': false,
              'loaded': true,
              'children': []
            }
          ]
        }
      ]
    },
    {
      'label': 'Dir2',
      'path': '/Dir2',
      'expanded': false,
      'expandable': true,
      'selected': false,
      'selectable': true,
      'loaded': true,
      'children': [
        {
          'label': 'Subdir1',
          'path': '/Dir2/Subdir1',
          'expandable': true,
          'expanded': false,
          'selected': false,
          'selectable': false,
          'loaded': true,
          'children': []
        },
        {
          'label': 'Subdir2',
          'path': '/Dir2/Subdir2',
          'expandable': true,
          'expanded': false,
          'selected': false,
          'selectable': false,
          'loaded': true,
          'children': [
            {
              'label': 'File1.jpg',
              'path': '/Dir2/Subdir2/File1.jpg',
              'expandable': false,
              'selectable': true
            }
          ]
        }
      ]
    }
  ]
}

function stubFailedChildLoad () {
  global.fetch = jest.fn(() =>
    Promise.resolve({
      status: 404,
      json: () => { throw Error('broken') }
    })
  )
}
function stubChildLoad () {
  global.fetch = jest.fn(() =>
    Promise.resolve({
      status: 200,
      json: () => Promise.resolve(
        [
          {
            'label': 'SubSubSubdir1',
            'path': '/Dir1/Subdir1/SubSubdir1/SubSubSubdir1',
            'expanded': false,
            'selected': false,
            'selectable': false,
            'loaded': true,
            'children': []
          }
        ]
      )
    })
  )
}

test('renders with a root that has the tree class', () => {
  const wrapper = mount(DirectoryPicker, { propsData: { startChildren: startChildren() } })

  expect(wrapper.find('ul').classes()).toEqual(['tree'])
  expect(wrapper.findAll('ul.tree').length).toEqual(1)
})

test('renders a collapsible detail for every child hierarchy', () => {
  const wrapper = mount(DirectoryPicker, { propsData: { startChildren: startChildren() } })

  expect(wrapper.findAll('details').length).toEqual(7)
})

test('clicking a label emits a list-focus event', async () => {
  const wrapper = mount(DirectoryPicker, { propsData: { startChildren: startChildren() } })
  await wrapper.findAll('summary span').at(0).trigger('click')

  expect(wrapper.emitted()).toHaveProperty('listFocus')
})

test('only displays expandable nodes', async () => {
  const wrapper = mount(DirectoryPicker, { propsData: { startChildren: startChildren() } })

  expect(wrapper.findAll('li .item-label').length).toEqual(7)
})
