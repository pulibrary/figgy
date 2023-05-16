import { mount } from '@vue/test-utils'
import LocalUploader from '../components/local_uploader.vue'

test('populates a hidden input for files uploaded and fires a formId', async () => {
  document.body.innerHTML = "<form id='test'><div id='bla'></div></form>'"
  const div = document.getElementById('bla')
  const mockSubmit = jest.fn()
  window.HTMLFormElement.prototype.submit = mockSubmit
  const wrapper = mount(LocalUploader, { attachTo: div, propsData: { folderPrefix: '/prefix', formId: 'test' } })
  wrapper.vm.uploadComplete({ successful: [{ uploadURL: 'http://localhost:3000/files/561688f1e9dd0fd1865125c2f45c0', type: 'image/tiff', name: 'test1.tif' }] })
  await wrapper.vm.$nextTick()
  expect(wrapper.findAll('input[name="metadata_ingest_files[]"]').at(0).element.value).toEqual(JSON.stringify({ id: 'disk:///prefix/561688f1e9dd0fd1865125c2f45c0', filename: 'test1.tif', type: 'image/tiff' }))

  // Ensure form was submitted
  expect(mockSubmit).toBeCalled()
})
