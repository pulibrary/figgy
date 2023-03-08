import { mount } from '@vue/test-utils'
import FolderPreview from '../components/folder_preview.vue'

const folder = () => {
  return {
    'label': 'Subdir2',
    'path': '/Dir2/Subdir2',
    'expandable': true,
    'expanded': false,
    'selected': false,
    'selectable': true,
    'loaded': true,
    'children': [
      {
        'label': 'Subsubdir1',
        'path': '/Dir2/Subdir2/Subsubdir1',
        'expandable': true,
        'expanded': false,
        'selected': false,
        'selectable': false,
        'loaded': true,
        'children': []
      },
      {
        'label': 'File1.jpg',
        'path': '/Dir2/Subdir2/File1.jpg',
        'expandable': false,
        'selectable': false
      }
    ]
  }
}

test('renders a list view of all children', () => {
  const wrapper = mount(FolderPreview, { propsData: { folder: folder() } })

  expect(wrapper.findAll('li').length).toEqual(2)
})

// Missing tests: Ingest directory button exists, is disabled for non-selectable
// directories, and when clicked fires an event.
