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
              <a rel="nofollow" data-method="put"
                v-bind:href="addTracksUrl(recording)" class="btn btn-primary">Add Tracks</a>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</template>
<script>
export default {
  props: ['resource_id'],
  data() {
    return {
      recordings: [
      ],
      recording_query: ""
    }
  },
  methods: {
    addTracksUrl(recording) {
      return `/concern/playlists/${this.resource_id}?${this.playlist_params(recording)}`
    },
    playlist_params(recording) {
      return recording.file_set_ids.map((x) => {
        return `playlist[file_set_ids][]=${x}`
      }).join("&")
    },
    search(event) {
      if(this.recording_query.trim() == '') {
        this.recordings = []
        return
      }
      let vm = this
      fetch(`/catalog.json?f[internal_resource_ssim][]=ScannedResource&f[change_set_ssim][]=media_reserve&q=${this.recording_query}`)
        .then(function(response) {
          return response.json()
        })
        .then(function(data) {
          vm.recordings = data["response"]["docs"].map(
            function(recording_document) {
              return {
                id: recording_document["id"],
                title: recording_document["title_ssim"][0],
                file_set_ids: recording_document["member_ids_ssim"].map((x) =>
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
