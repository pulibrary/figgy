import Vue from 'vue/dist/vue.esm'
import system from 'lux-design-system'
import 'lux-design-system/dist/system/system.css'
import 'lux-design-system/dist/system/tokens/tokens.scss'
import store from '@store'
import DocumentAdder from '@components/document_adder.vue'
import EmbeddedFileBrowser from '@components/file_browser/embedded_file_browser.vue'
import InputPathSelector from '@components/file_browser/input_path_selector.vue'
import PlaylistMembers from '@components/playlist_members.vue'
import IssueMonograms from '@components/issue_monograms.vue'
import axios from 'axios'
import OrderManager from '@components/OrderManager.vue'
import StructManager from '@components/StructManager.vue'
import setupAuthLinkClipboard from '@figgy/auth_link_clipboard'
import AjaxSelect from '@components/ajax-select.vue'
import { setupAjaxSelect, setupCocoonLinks } from '@helpers/setup_ajax_select'
import FileUploader from '@components/file-uploader.vue'
import Initializer from '@figgy/figgy_boot'
import VueDetails from 'vue-details'
import LocalUploader from '@components/local_uploader.vue'

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
        'input-path-selector': InputPathSelector,
        'embedded-file-browser': EmbeddedFileBrowser,
        'local-uploader': LocalUploader,
        'struct-manager': StructManager,
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
