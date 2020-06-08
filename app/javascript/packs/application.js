import Vue from 'vue/dist/vue.esm'
import system from 'lux-design-system'
import 'lux-design-system/dist/system/system.css'
import 'lux-design-system/dist/system/tokens/tokens.scss'
import store from '../store'
import DocumentAdder from '../components/document_adder'
import PlaylistMembers from '../components/playlist_members'
import IssueMonograms from '../components/issue_monograms'
import axios from 'axios'
import OrderManager from '../components/OrderManager.vue'
import setupAuthLinkClipboard from '../packs/auth_link_clipboard.js'
import AjaxSelect from '../components/ajax-select'
import setupAjaxSelect from '../helpers/setup_ajax_select.js'
import vue2Dropzone from 'vue2-dropzone'
import 'vue2-dropzone/dist/vue2Dropzone.min.css'

const csrfToken = document.getElementsByName('csrf-token')[0].content

Vue.use(system)

// mount the filemanager app
document.addEventListener('DOMContentLoaded', () => {
  // Set CSRF token for axios requests.
  axios.defaults.headers.common['X-CSRF-Token'] = document.querySelector('meta[name="csrf-token"]').getAttribute('content')
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
        'dropzone': vue2Dropzone
      },
      data: {
        options: [],
        dropzoneOptions: {
          url: '/ocr_requests/upload_file',
          headers: { "X-CSRF-Token": csrfToken }
        }
      },
      // Functions to run after Vue is mounted
      mounted: function () {
        setupAjaxSelect()
      }
    })
  }
  setupAuthLinkClipboard()
})
