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

// directoryIngest mode
test('renders a list view of all children', () => {
  const wrapper = mount(FolderPreview, { propsData: { folder: folder(), mode: 'directoryIngest' } })

  expect(wrapper.findAll('li').length).toEqual(2)
})

test('renders an ingest directory button', () => {
  const wrapper = mount(FolderPreview, { propsData: { folder: folder(), mode: 'directoryIngest' } })

  expect(wrapper.get('.actions a').text()).toEqual('Ingest Subdir2 directory')
  expect(wrapper.findAll('.actions a').length).toEqual(1)
})

test('disables an ingest directory button', () => {
  const wrapper = mount(FolderPreview, { propsData: { folder: disabledFolder(), mode: 'directoryIngest' } })

  expect(wrapper.get('.actions a').classes()).toContain('disabled')
})

test('the ingest directory button fires an event', async () => {
  const wrapper = mount(FolderPreview, { propsData: { folder: disabledFolder(), mode: 'directoryIngest' } })

  await wrapper.get('.actions a').trigger('click')
  expect(wrapper.emitted()).toHaveProperty('folderSelect')
  expect(wrapper.emitted().folderSelect[0]).toEqual([wrapper.vm.folder])
})

// fileIngest mode
test('does not render an ingest directory button', () => {
  const wrapper = mount(FolderPreview, { propsData: { folder: folder(), mode: 'fileIngest' } })

  expect(wrapper.get('.actions a').text()).toEqual('Ingest selected files')
  expect(wrapper.findAll('.actions a').length).toEqual(1)
})

// TODO: select files, if none are selected ingest button is disabled
