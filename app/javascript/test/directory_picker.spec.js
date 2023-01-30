import { mount } from '@vue/test-utils'
import DirectoryPicker from '../components/directory_picker.vue'

const startChildren = [
  {
    'label': 'Dir1',
    'path': '/Dir1',
    'expanded': true,
    'selected': false,
    'selectable': false,
    'loaded': true,
    'children': [
      {
        'label': 'Subdir1',
        'path': '/Dir1/Subdir1',
        'expanded': false,
        'selected': false,
        'selectable': true,
        'loaded': true,
        'children': [
          {
            'label': 'SubSubdir1',
            'path': '/Dir1/Subdir1/SubSubdir1',
            'expanded': false,
            'selected': false,
            'selectable': true,
            'loaded': false,
            'children': []
          },
          {
            'label': 'SubSubdir2',
            'path': '/Dir1/Subdir1/SubSubdir2',
            'expanded': false,
            'selected': false,
            'selectable': true,
            'loaded': false,
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
    'selected': false,
    'selectable': false,
    'loaded': false,
    'children': []
  }
]
test('renders with a root that has the tree class', () => {
  const wrapper = mount(DirectoryPicker, { propsData: { startChildren: startChildren } })

  expect(wrapper.find('ul').classes()).toEqual(['tree'])
  expect(wrapper.findAll('ul.tree').length).toEqual(1)
})

test('renders a collapsible detail for every child hierarchy', () => {
  const wrapper = mount(DirectoryPicker, { propsData: { startChildren: startChildren } })

  expect(wrapper.findAll('details').length).toEqual(2)
})
