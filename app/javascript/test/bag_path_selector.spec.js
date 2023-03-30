import { mount } from '@vue/test-utils'
import BagPathSelector from '../components/bag_path_selector.vue'

const startChildren = () => {
  return [
    {
      'label': 'Dir1',
      'path': 'Dir1',
      'expanded': true,
      'expandable': true,
      'selected': false,
      'selectable': false,
      'loaded': true,
      'children': [
        {
          'label': 'Subdir1',
          'path': 'Dir1/Subdir1',
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
  document.body.innerHTML = "<input id='test' type='text'>"
  const wrapper = mount(BagPathSelector, { propsData: { startTree: startChildren(), folderPrefix: '/bla/', windowTarget: 'test' } })

  await wrapper.get('button').trigger('click')
  expect(wrapper.findAll('ul.tree').length).toEqual(1)
  // Close button works.
  await wrapper.get('.close').trigger('click')
  expect(wrapper.findAll('ul.tree').length).toEqual(0)
  await wrapper.get('button').trigger('click')
  expect(wrapper.findAll('ul.tree').length).toEqual(1)
  // Clicking background closes modal
  await wrapper.get('#file-browser-modal').trigger('click')
  expect(wrapper.findAll('ul.tree').length).toEqual(0)
})

test('populates a target input', async () => {
  document.body.innerHTML = "<input id='test' type='text'>"
  const wrapper = mount(BagPathSelector, { propsData: { startTree: startChildren(), folderPrefix: '/bla/', windowTarget: 'test' } })

  await wrapper.get('button').trigger('click')
  expect(wrapper.findAll('ul.tree').length).toEqual(1)
  await wrapper.findAll('summary span').at(1).trigger('click')
  await wrapper.get('.actions a').trigger('click')
  expect(wrapper.findAll('ul.tree').length).toEqual(0)
  expect(document.getElementById('test').value).toEqual('/bla/Dir1/Subdir1')
})
