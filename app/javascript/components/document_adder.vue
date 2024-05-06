<template>
  <div class="playlist-tracks">
    <h2>Search for Recordings to Add Tracks</h2>
    <form @submit.prevent="search">
      <div class="input-group">
        <input
          v-model="recording_query"
          name="recording-query"
          placeholder="Search"
          class="form-control"
        >
        <span class="input-group-btn">
          <button
            class="btn btn-primary"
          >
            Search
          </button>
        </span>
      </div>
    </form>
    <div>
      <table class="table table-striped">
        <template v-if="recordings.length > 0">
          <thead>
            <th>Title</th>
            <th>Actions</th>
          </thead>
        </template>
        <tbody>
          <template
            v-for="recording in recordings"
            :key="recording.id"
          >
            <tr>
              <td>
                <a :href="'/catalog/' + recording.id">
                  {{ recording.title }}
                </a>
              </td>
              <td>
                <button
                  class="btn btn-primary"
                  :disabled="addingTracks || recording.tracks.length == 0"
                  @click="addTracks(recording)"
                >
                  Add All Tracks
                </button>
              </td>
            </tr>
            <tr
              v-for="track in recording.tracks"
              :key="track.id"
              class="track-cell"
            >
              <td>
                {{ track.label }}
              </td>
              <td>
                <button
                  class="btn btn-primary"
                  :disabled="addingTracks"
                  @click="addTrack(track)"
                >
                  Add Track
                </button>
              </td>
            </tr>
          </template>
        </tbody>
      </table>
    </div>
  </div>
</template>
<script>
import axios from 'axios'
import apollo from '../helpers/apolloClient'
import gql from 'graphql-tag'
import { reactive } from "vue"
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
    fileSetFormData (fileSetIds) {
      const form = new FormData()
      form.append('_method', 'patch')
      for (const id of fileSetIds) {
        form.append('playlist[file_set_ids][]', id)
      }
      return form
    },
    addTrack (track) {
      this.addingTracks = true
      axios.post(`/concern/playlists/${this.resourceId}`,
        this.fileSetFormData([track.id])
      )
        .then(function (response) {
          window.location = response.request.responseURL
        })
    },
    addTracks (recording) {
      if (recording.tracks.length < 1) {
        return
      }
      this.addingTracks = true
      axios.post(`/concern/playlists/${this.resourceId}`,
        this.fileSetFormData(recording.tracks.map(
          function (track) {
            return track.id
          }
        ))
      )
        .then(function (response) {
          window.location = response.request.responseURL
        })
    },
    tracks_by_recording_id (recordingId) {
      const query = gql`
        query GetResource($id: ID!) {
          resource(id: $id) {
             members {
               id,
               label
             }
          }
        }`

      const variables = {
        id: recordingId
      }
      return apollo.query({
        query, variables
      }).then(function (data) {
        return data.data.resource.members
      })
    },
    async search (event) {
      if (this.recording_query.trim() === '') {
        this.recordings = []
        return
      }
      const vm = this

      // Get all recording titles and IDs from a catalog search (Solr).
      // Ensure that this AJAX request does not trigger the caching of query
      // parameters (this is the default behavior for Blacklight 6 Controllers)
      let data = await fetch(`/catalog.json?f[internal_resource_ssim][]=ScannedResource&f[change_set_ssim][]=recording&q=${this.recording_query}&async=true`)
      data = await data.json()
      data = data.data.map(
            function (recordingDocument) {
              const titles = recordingDocument.attributes.figgy_title_ssi
              return {
                id: recordingDocument.id,
                title: titles.attributes.value,
                tracks: []
              }
            }
          )
      let recordings = reactive(data)
      const promises = []
      // Set tracks for every recording, store promises in an array so we
      // can tell when they resolve.
      for (const recording of recordings) {
        promises.concat(vm.tracks_by_recording_id(recording.id).then(function (tracks) {
          recording.tracks = tracks
        }))
      }
      await Promise.all(promises)
      this.recordings = recordings
    }
  }
}
</script>
<style scope>
.table > tbody > tr.track-cell > td {
  padding-left: 20px;
}
</style>
