import Vue from 'vue/dist/vue.esm'
import system from 'lux-design-system'
import 'lux-design-system/dist/system/system.css'
import 'lux-design-system/dist/system/tokens/tokens.scss'
import store from '../store'
import DocumentAdder from '../components/document_adder'
import DirectoryPicker from '../components/directory_picker'
import FileBrowser from '../components/file_browser'
import EmbeddedFileBrowser from '../components/embedded_file_browser'
import InputPathSelector from '../components/input_path_selector'
import PlaylistMembers from '../components/playlist_members'
import IssueMonograms from '../components/issue_monograms'
import axios from 'axios'
import OrderManager from '../components/OrderManager.vue'
import setupAuthLinkClipboard from '../packs/auth_link_clipboard.js'
import AjaxSelect from '../components/ajax-select'
import { setupAjaxSelect, setupCocoonLinks } from '../helpers/setup_ajax_select.js'
import FileUploader from '../components/file-uploader'
import Initializer from '../figgy/figgy_boot'
import VueDetails from 'vue-details'

Vue.use(system)
Vue.component('v-details', VueDetails)

// mount the filemanager app
document.addEventListener('DOMContentLoaded', () => {
  // Set CSRF token for axios requests.
  axios.defaults.headers.common['X-CSRF-Token'] = document.querySelector('meta[name="csrf-token"]') ? document.querySelector('meta[name="csrf-token"]').getAttribute('content') : undefined
  var elements = document.getElementsByClassName('lux')
  for (var i = 0; i < elements.length; i++) {
    new Vue({
      el: elements[i],
      store,
      components: {
        'document-adder': DocumentAdder,
        'playlistMembers': PlaylistMembers,
        'order-manager': OrderManager,
        'issue-monograms': IssueMonograms,
        'ajax-select': AjaxSelect,
        'file-uploader': FileUploader,
        'directory-picker': DirectoryPicker,
        'file-browser': FileBrowser,
        'input-path-selector': InputPathSelector,
        'embedded-file-browser': EmbeddedFileBrowser
      },
      data: {
        options: []
      },
      beforeCreate: function () {
        setupAjaxSelect()
      },
      mounted: function () {
        setupCocoonLinks()
      }
    })
  }
  setupAuthLinkClipboard()
  // It's important we initialize Figgy after mounting Vue, otherwise none of
  // the JS will work because Vue takes it all over.
  window.figgy = new Initializer()
})
