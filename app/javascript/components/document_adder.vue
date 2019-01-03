<template>
  <div>
    <h2>Search for Recordings to Add Tracks</h2>
    <form @submit.prevent="search">
      <div class="input-group">
        <input
          v-model="recording_query"
          placeholder="Search"
          class="form-control"
        >
        <span class="input-group-btn">
          <button
            class="btn btn-primary"
            @click="search"
          >
            Search
          </button>
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
          <tr
            v-for="recording in recordings"
            :key="recording.id"
          >
            <td>
              <a :href="'/catalog/' + recording.id">
                {{ recording.title }}
              </a>
            </td>
            <td>
              <button
                class="btn btn-primary"
                :disabled="addingTracks || recording.file_set_ids.length == 0"
                @click="addTracks(recording)"
              >
                Add Tracks
              </button>
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
  props: {
    resourceId: {
      type: String,
      required: true
    }
  },
  data () {
    return {
      recordings: [],
      recording_query: '',
      addingTracks: false
    }
  },
  methods: {
    fileSetFormData (recording) {
      let form = new FormData()
      form.append('_method', 'patch')
      for (var id of recording.file_set_ids) {
        form.append('playlist[file_set_ids][]', id)
      }
      return form
    },
    addTracks (recording) {
      if (recording.file_set_ids.length < 1) {
        return
      }
      this.addingTracks = true
      axios.post(`/concern/playlists/${this.resourceId}`,
        this.fileSetFormData(recording)
      )
        .then(function (response) {
          window.location = response.request.responseURL
        })
    },
    search (event) {
      if (this.recording_query.trim() === '') {
        this.recordings = []
        return
      }
      let vm = this
      fetch(`/catalog.json?f[internal_resource_ssim][]=ScannedResource&f[change_set_ssim][]=recording&q=${this.recording_query}`)
        .then(function (response) {
          return response.json()
        })
        .then(function (data) {
          vm.recordings = data['response']['docs'].map(
            function (recordingDocument) {
              return {
                id: recordingDocument['id'],
                title: recordingDocument['title_ssim'][0],
                file_set_ids: (recordingDocument['member_ids_ssim'] || []).map((x) => { return x.replace(/^id-/, '') })
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
