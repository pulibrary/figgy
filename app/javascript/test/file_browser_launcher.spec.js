import { mount } from '@vue/test-utils'
import FileBrowserLauncher from '../components/file_browser_launcher.vue'

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

test('renders a button to launch a file browser', async () => {
  const wrapper = mount(FileBrowserLauncher, { propsData: { startTree: startChildren(), mode: 'directoryIngest' } })

  expect(wrapper.find('a.button').text()).toEqual('Choose Files')
  await wrapper.get('a.button').trigger('click')
  expect(wrapper.findAll('ul.tree').length).toEqual(1)
  // Close button works.
  await wrapper.get('.close').trigger('click')
  expect(wrapper.findAll('ul.tree').length).toEqual(0)
  await wrapper.get('a.button').trigger('click')
  expect(wrapper.findAll('ul.tree').length).toEqual(1)
  // Clicking background closes modal
  await wrapper.get('#file-browser-modal').trigger('click')
  expect(wrapper.findAll('ul.tree').length).toEqual(0)
})

// TODO:
// * Add a box to display result of selections
// * Add hidden inputs that store the result of selections.
