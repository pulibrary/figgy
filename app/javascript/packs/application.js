import Vue from 'vue/dist/vue.esm'
import system from 'lux-design-system'
import 'lux-design-system/lib/system/system.css'
import store from '../store'
import DocumentAdder from '../components/document_adder'
import PlaylistMember from '../components/playlist_member'
import PlaylistMembers from '../components/playlist_members'
import axios from 'axios'

Vue.use(system)

// mount the filemanager app
document.addEventListener('DOMContentLoaded', () => {
  // Set CSRF token for axios requests.
  axios.defaults.headers.common['X-CSRF-Token'] = document.querySelector('meta[name="csrf-token"]').getAttribute('content')
  var elements = document.getElementsByClassName('lux')
  for(var i = 0; i < elements.length; i++){
    new Vue({
      el: elements[i],
      store,
      components: {
        'document-adder': DocumentAdder,
	'playlistMembers': PlaylistMembers
      }
    })
  }
})
