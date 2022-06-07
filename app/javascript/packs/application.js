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
import FileUploader from '../components/file-uploader'
import Initializer from '../figgy/figgy_boot'

Vue.use(system)

// mount the filemanager app
document.addEventListener('DOMContentLoaded', () => {
  window.figgy = new Initializer()
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
        'file-uploader': FileUploader
      },
      data: {
        options: [],
      },
      beforeCreate: function () {
        setupAjaxSelect()
      }
    })
  }
  setupAuthLinkClipboard()
})
