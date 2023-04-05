import { mount } from '@vue/test-utils'
import EmbeddedFileBrowser from '../components/embedded_file_browser.vue'

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

test('populates a hidden input for files selected and fires a formId', async () => {
  document.body.innerHTML = "<form id='test'></form>"
  const mockSubmit = jest.fn()
  window.HTMLFormElement.prototype.submit = mockSubmit
  const wrapper = mount(EmbeddedFileBrowser, { propsData: { startTree: startChildren(), formId: 'test' } })

  await wrapper.findAll('summary span').at(6).trigger('click')
  await wrapper.get('li.file').trigger('click')
  await wrapper.findAll('li.file').at(1).trigger('click', { ctrlKey: true })
  await wrapper.get('.actions a').trigger('click')
  expect(wrapper.findAll('input[name="ingest_files[]"]').at(0).element.value).toEqual('/Dir2/Subdir2/File1.jpg')
  expect(wrapper.findAll('input[name="ingest_files[]"]').at(1).element.value).toEqual('/Dir2/Subdir2/File2.jpg')
  // Ensure form was submitted
  expect(mockSubmit).toBeCalled()
})
