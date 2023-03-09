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

const disabledFolder = () => {
  return {
    'label': 'Subdir2',
    'path': '/Dir2/Subdir2',
    'expandable': true,
    'expanded': false,
    'selected': false,
    'selectable': false,
    'loaded': true,
    'children': []
  }
}

test('renders a list view of all children', () => {
  const wrapper = mount(FolderPreview, { propsData: { folder: folder() } })

  expect(wrapper.findAll('li').length).toEqual(2)
})

test('renders an ingest directory button', () => {
  const wrapper = mount(FolderPreview, { propsData: { folder: folder() } })

  expect(wrapper.get('.actions a').text()).toEqual('Ingest Subdir2 directory')
})

test('disables an ingest directory button', () => {
  const wrapper = mount(FolderPreview, { propsData: { folder: disabledFolder() } })

  expect(wrapper.get('.actions a').classes()).toContain('disabled')
})

test('the ingest directory button fires an event', async () => {
  const wrapper = mount(FolderPreview, { propsData: { folder: disabledFolder() } })

  await wrapper.get('.actions a').trigger('click')
  expect(wrapper.emitted()).toHaveProperty('folderSelect')
  expect(wrapper.emitted().folderSelect[0]).toEqual([wrapper.vm.folder])
})
