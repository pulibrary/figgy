<template>
  <div>
    <h2>Search for Recordings to Add Tracks</h2>
    <form v-on:submit.prevent="search">
      <div class="input-group">
        <input v-model="recording_query" placeholder="Search" class="form-control">
          <span class="input-group-btn">
            <button v-on:click="search" class="btn btn-primary">Search</button>
          </span>
      </div>
    </form>
    <div>
      <table class="table table-striped">
        <thead>
          <th>Recording</th>
          <th>Actions</th>
        </thead>
        <tbody>
          <tr v-for="recording in recordings">
            <td><a v-bind:href="'/catalog/' + recording.id">{{ recording.title }}</a></td>
            <td>
              <button v-on:click="addTracks(recording)" class="btn btn-primary"
                :disabled="addingTracks || recording.file_set_ids.length == 0">Add Tracks</button>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</template>
<script>
import axios from 'axios'
export default {
  props: ['resource_id', 'resource_member_ids'],
  data() {
    // This is due to the fact that Valkyrie::ID objects are not serialized as strings
    const member_file_set_ids = this.resource_member_ids.map( member_id => member_id.id )

    return {
      recordings: [],
      recording_query: "",
      addingTracks: false,
      member_file_set_ids: member_file_set_ids
    }
  },
  methods: {
    fileSetFormData(recording) {
      let form = new FormData
      form.append('_method', 'patch')
      for(var id of recording.file_set_ids) {
        form.append('playlist[file_set_ids][]', id)
      }
      return form
    },
    addTracks(recording) {
      if (recording.file_set_ids.length < 1) {
        return
      }
	// Ensure that the new FileSet IDs are unique
	const new_file_set_ids = recording.file_set_ids.filter( file_set_id => !this.member_file_set_ids.includes(file_set_id) )
	if (new_file_set_ids.length < 1) {
	    window.location.reload()
	    return
	}
	this.member_file_set_ids = this.member_file_set_ids.concat(new_file_set_ids)

      this.addingTracks = true
      let vm = this
      axios.post(`/concern/playlists/${this.resource_id}`,
        this.fileSetFormData(recording)
      )
      .then(function(response) {
        window.location = response.request.responseURL
      })
    },
    search(event) {
      if(this.recording_query.trim() == '') {
        this.recordings = []
        return
      }
      let vm = this
      fetch(`/catalog.json?f[internal_resource_ssim][]=ScannedResource&f[change_set_ssim][]=recording&q=${this.recording_query}`)
        .then(function(response) {
          return response.json()
        })
        .then(function(data) {
          vm.recordings = data["response"]["docs"].map(
            function(recording_document) {
              return {
                id: recording_document["id"],
                title: recording_document["title_ssim"][0],
                file_set_ids: (recording_document["member_ids_ssim"] || []).map((x) =>
                  { return x.replace(/^id-/,"") })
              }
            }
          )
        })
    }
  }
}
</script>
<style scope>
</style>
