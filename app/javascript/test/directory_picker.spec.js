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
            'loadChildrenPath': '/loaders/test',
            'expanded': false,
            'selected': false,
            'selectable': false,
            'loaded': false,
            'children': []
          },
          {
            'label': 'SubSubdir2',
            'path': '/Dir1/Subdir1/SubSubdir2',
            'expanded': false,
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
    'selected': false,
    'selectable': true,
    'loaded': true,
    'children': [
      {
        'label': 'Subdir1',
        'path': '/Dir2/Subdir1',
        'expanded': false,
        'selected': false,
        'selectable': false,
        'loaded': true,
        'children': []
      },
      {
        'label': 'Subdir2',
        'path': '/Dir2/Subdir2',
        'expanded': false,
        'selected': false,
        'selectable': false,
        'loaded': true,
        'children': []
      }
    ]
  }
]

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
  const wrapper = mount(DirectoryPicker, { propsData: { startChildren: startChildren } })

  expect(wrapper.find('ul').classes()).toEqual(['tree'])
  expect(wrapper.findAll('ul.tree').length).toEqual(1)
})

test('renders a collapsible detail for every child hierarchy', () => {
  const wrapper = mount(DirectoryPicker, { propsData: { startChildren: startChildren } })

  expect(wrapper.findAll('details').length).toEqual(3)
})

test('renders a checkbox for selectable paths', () => {
  const wrapper = mount(DirectoryPicker, { propsData: { startChildren: startChildren } })

  expect(wrapper.findAll('input[type="checkbox"]').length).toEqual(2)
})

test('checking one checkbox unchecks the other ones', async () => {
  const wrapper = mount(DirectoryPicker, { propsData: { startChildren: startChildren } })

  await wrapper.findAll('input[type="checkbox"]').at(0).trigger('click')
  expect(wrapper.vm.selectedChild.path).toEqual('/Dir1/Subdir1')
  await wrapper.findAll('input[type="checkbox"]').at(1).trigger('click')
  expect(wrapper.vm.selectedChild.path).toEqual('/Dir2')
  expect(wrapper.findAll('input:checked').length).toEqual(1)
  await wrapper.findAll('input[type="checkbox"]').at(0).trigger('click')
  expect(wrapper.vm.selectedChild.path).toEqual('/Dir1/Subdir1')
  expect(wrapper.findAll('input:checked').length).toEqual(1)
})

test('can dynamically load child nodes via loadChildrenPath', async () => {
  const wrapper = mount(DirectoryPicker, { propsData: { startChildren: startChildren } })
  console.log(wrapper.vm.children[0].children[0].children[0].path)
  wrapper.vm.children[0].children[0].children[0].expanded = true

  expect(wrapper.vm.children[0].children[0].children[0].children.length).toEqual(1)
})
