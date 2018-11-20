<template>
<div class="panel panel-default">
  <div class="panel-heading">
    <h2 class="panel-title">Tracks</h2>
  </div>
  <div class="row panel-body">
    <form v-on:submit.prevent="submit">
      <table class="table table-striped member-resources member-recordings">
	<thead>
	  <tr>
            <th>Title</th>
            <th>Actions</th>
          </tr>
	</thead>
	<tbody>
	  <template v-for="member in members">
	    <playlist-member :resource="member" v-on:update="detach"></playlist-member>
	  </template>
	</tbody>
      </table>
    </form>
  </div>
</div>
</template>
<script>
import axios from 'axios'
import PlaylistMember from './playlist_member'

export default {
    name: 'playlist-members',
    props: ['resource_id', 'members'],
    components: {
	'playlist-member': PlaylistMember
    },
    data() {
	return { submitting: false }
    },
    methods: {
	buildFormData() {
	    let form = new FormData
	    form.append('_method', 'delete')

	    return form
	},
	submit() { return false },
	detach(proxy_id) {
	    let vm = this
	    this.submitting = true

	    axios.post(`/concern/playlists/${proxy_id}`,
		        this.buildFormData()
		      ).then(function(response) {
		        vm.submitting = false
			window.location.reload()
		      })
	}
    }
}
</script>
<style scope>
</style>
