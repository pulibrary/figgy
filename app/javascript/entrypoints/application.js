import { createApp } from 'vue'
import lux from 'lux-design-system'
import 'lux-design-system/dist/style.css'
import { store } from '@/store/index.es6'
import DocumentAdder from '@/components/document_adder.vue'
import EmbeddedFileBrowser from '@/components/file_browser/embedded_file_browser.vue'
import InputPathSelector from '@/components/file_browser/input_path_selector.vue'
import PlaylistMembers from '@/components/playlist_members.vue'
import IssueMonograms from '@/components/issue_monograms.vue'
import axios from 'axios'
import OrderManager from '@/components/OrderManager.vue'
import StructManager from '@/components/StructManager.vue'
import setupAuthLinkClipboard from '@/figgy/auth_link_clipboard'
import AjaxSelect from '@/components/ajax-select.vue'
import { setupAjaxSelect, setupCocoonLinks } from '@/helpers/setup_ajax_select'
import FileUploader from '@/components/file-uploader.vue'
import Initializer from '@/figgy/figgy_boot'
import LocalUploader from '@/components/local_uploader.vue'

const app = createApp(
  {
    data () {
      return { options: [] }
    },
    beforeCreate () {
      setupAjaxSelect()
    },
    onMounted () {
      setupCocoonLinks()
    }
  }
)

const createMyApp = () => createApp(app)

// mount the filemanager app
document.addEventListener('DOMContentLoaded', () => {
  // Set CSRF token for axios requests.
  axios.defaults.headers.common['X-CSRF-Token'] = document.querySelector('meta[name="csrf-token"]') ? document.querySelector('meta[name="csrf-token"]').getAttribute('content') : undefined
  var elements = document.getElementsByClassName('lux')
  for (var i = 0; i < elements.length; i++) {
    createMyApp()
      .use(lux)
      .use(store)
      .component('document-adder', DocumentAdder)
      .component('playlistMembers', PlaylistMembers)
      .component('order-manager', OrderManager)
      .component('issue-monograms', IssueMonograms)
      .component('ajax-select', AjaxSelect)
      .component('file-uploader', FileUploader)
      .component('input-path-selector', InputPathSelector)
      .component('embedded-file-browser', EmbeddedFileBrowser)
      .component('local-uploader', LocalUploader)
      .component('struct-manager', StructManager)
      .mount(elements[i])
  }

  setupAuthLinkClipboard()
  // It's important we initialize Figgy after mounting Vue, otherwise none of
  // the JS will work because Vue takes it all over.
  window.figgy = new Initializer()
})
