import { mount } from '@vue/test-utils'
import FileBrowser from '../components/file_browser.vue'

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

test('renders a directory picker pane', () => {
  const wrapper = mount(FileBrowser, { propsData: { startTree: startChildren(), mode: 'directoryIngest' } })

  expect(wrapper.find('ul').classes()).toEqual(['tree'])
  expect(wrapper.findAll('ul.tree').length).toEqual(1)
})

test('highlights a list-focused pane', async () => {
  const wrapper = mount(FileBrowser, { propsData: { startTree: startChildren(), mode: 'directoryIngest' } })

  await wrapper.findAll('summary span').at(0).trigger('click')

  expect(wrapper.findAll('summary.list-focus').length).toEqual(1)
  expect(wrapper.vm.listFocus.path).toEqual('/Dir1')

  await wrapper.findAll('summary span').at(1).trigger('click')
  expect(wrapper.vm.listFocus.path).toEqual('/Dir1/Subdir1')
  expect(wrapper.findAll('summary.list-focus').length).toEqual(1)
})
