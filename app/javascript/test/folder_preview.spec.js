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
        'selectable': true
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
test('it renders a list view of all children', () => {
  const wrapper = mount(FolderPreview, { propsData: { folder: folder(), mode: 'directoryIngest' } })

  expect(wrapper.findAll('li').length).toEqual(2)
})

test('in directoryIngest mode it renders an ingest directory button', () => {
  const wrapper = mount(FolderPreview, { propsData: { folder: folder(), mode: 'directoryIngest' } })

  expect(wrapper.get('.actions a').text()).toEqual('Ingest Subdir2 directory')
  expect(wrapper.findAll('.actions a').length).toEqual(1)
})

test('in directoryIngest mode, when selectable is false, it disables the ingest directory button', () => {
  const wrapper = mount(FolderPreview, { propsData: { folder: disabledFolder(), mode: 'directoryIngest' } })

  expect(wrapper.get('.actions a').classes()).toContain('disabled')
})

test('in directoryIngest mode clicking the ingest directory button fires an event', async () => {
  const wrapper = mount(FolderPreview, { propsData: { folder: disabledFolder(), mode: 'directoryIngest' } })

  await wrapper.get('.actions a').trigger('click')
  expect(wrapper.emitted()).toHaveProperty('folderSelect')
  expect(wrapper.emitted().folderSelect[0]).toEqual([wrapper.vm.folder])
})

// fileIngest mode
test('in fileIngest mode it renders an Ingest selected files button', async () => {
  const wrapper = mount(FolderPreview, { propsData: { folder: folder(), mode: 'fileIngest' } })

  expect(wrapper.get('.actions a').text()).toEqual('Ingest selected files')
  // no ingest directory button
  expect(wrapper.findAll('.actions a').length).toEqual(1)
  // button disabled
  expect(wrapper.get('.actions a').classes()).toContain('disabled')
  await wrapper.get('li.file').trigger('click')
  // button enabled
  expect(wrapper.get('.actions a').classes()).not.toContain('disabled')
})

test('in fileIngest mode, when i click a file, it gets added to the files array', async () => {
  const wrapper = mount(FolderPreview, { propsData: { folder: folder(), mode: 'fileIngest' } })

  await wrapper.get('li.file').trigger('click')
  expect(wrapper.vm.selectedFiles).toEqual([wrapper.vm.folder.children[1]])
})

test('in fileIngest mode, when i click a file again, it is removed from the files array', async () => {
  const wrapper = mount(FolderPreview, { propsData: { folder: folder(), mode: 'fileIngest' } })

  await wrapper.get('li.file').trigger('click')
  await wrapper.get('li.file.selected').trigger('click')
  expect(wrapper.vm.selectedFiles.length).toEqual(0)
})

test('in fileIngest mode, when i click a directory, it is not added to the files array', async () => {
  const wrapper = mount(FolderPreview, { propsData: { folder: folder(), mode: 'fileIngest' } })

  await wrapper.get('li.directory').trigger('click')
  expect(wrapper.vm.selectedFiles.length).toEqual(0)
})

// TODO:
// when i list focus a different directory, the selected files get wiped from
// the folder preview component.
// when I click the fileIngest button, it passes the array in the event and the
// elements are in the same order they're in in the children array, regardless
// of what order they were selected in.
// features to add:
//  - shift-click and control-click and select all
// Styling TODO:
//  - directories are greyed out and not selectable in fileIngest mode
//  - highlight selected rows
