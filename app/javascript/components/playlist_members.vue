<template>
<div class="panel panel-default">
  <div class="panel-heading">
    <h2 class="panel-title">Recordings</h2>
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
    name: 'playlistMembers',
    props: ['resource_id', 'members'],
    components: {
	'playlist-member': PlaylistMember
    },
    data() {
	return {
	    detached_member_ids: []
	}
    },
    methods: {
	getFileSetIds() {
	    return this.members.map((file_set) => {
		// This is due to the fact that Valkyrie::ID objects are not serialized as strings
		const file_set_id = file_set.id
		return file_set_id.id
	    })
	},
	submit() {},
	buildFormData() {
	    let form = new FormData
	    form.append('_method', 'patch')

	    for(var id of this.detached_member_ids) {
		form.append('playlist[detached_member_ids][]', id)
	    }
	    return form
	},
	detach(file_set_id) {
	    let vm = this
	    this.submitting = true

	    // Filter for the detached FileSet
	    if (!this.detached_member_ids.includes(file_set_id)) {
		this.detached_member_ids.push(file_set_id)
	    }

	    axios.post(`/concern/playlists/${this.resource_id}`,
		       this.buildFormData()
		      ).then(function(response) {
			  vm.submitting = false
			  window.location = response.request.responseURL
		      })
	}
    }
}
</script>
<style scope>
</style>
