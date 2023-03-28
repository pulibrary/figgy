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
            },
            {
              'label': 'File2.jpg',
              'path': '/Dir2/Subdir2/File2.jpg',
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

test('populates a hidden input in directoryIngest mode', async () => {
  const wrapper = mount(FileBrowserLauncher, { propsData: { startTree: startChildren(), mode: 'directoryIngest' } })

  expect(wrapper.find('a.button').text()).toEqual('Choose Files')
  await wrapper.get('a.button').trigger('click')
  expect(wrapper.findAll('ul.tree').length).toEqual(1)
  await wrapper.findAll('summary span').at(1).trigger('click')
  await wrapper.get('.actions a').trigger('click')
  expect(wrapper.findAll('ul.tree').length).toEqual(0)
  expect(wrapper.find('input[name="ingest_directory"]').element.value).toEqual('/Dir1/Subdir1')
  expect(wrapper.get('#file-browser-launcher .summary').text()).toEqual('Selected Directory: Subdir1 (/Dir1/Subdir1)')
})

test('populates a hidden input in fileIngest mode', async () => {
  const wrapper = mount(FileBrowserLauncher, { propsData: { startTree: startChildren(), mode: 'fileIngest' } })

  expect(wrapper.find('a.button').text()).toEqual('Choose Files')
  await wrapper.get('a.button').trigger('click')
  await wrapper.findAll('summary span').at(6).trigger('click')
  await wrapper.get('li.file').trigger('click')
  await wrapper.findAll('li.file').at(1).trigger('click', { ctrlKey: true })
  await wrapper.get('.actions a').trigger('click')
  expect(wrapper.findAll('ul.tree').length).toEqual(0)
  expect(wrapper.find('input[name="ingest_files[0]"]').element.value).toEqual('/Dir2/Subdir2/File1.jpg')
  expect(wrapper.find('input[name="ingest_files[1]"]').element.value).toEqual('/Dir2/Subdir2/File2.jpg')
  expect(wrapper.find('.summary ul li').text()).toEqual('File1.jpg (/Dir2/Subdir2/File1.jpg)')
})

// TODO:
// * Add a box to display result of selections
// * Add hidden inputs that store the result of selections.
