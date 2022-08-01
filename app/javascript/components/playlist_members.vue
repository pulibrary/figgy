<template>
  <div class="card">
    <div class="card-header">
      <h2 class="card-title">
        Tracks
      </h2>
    </div>
    <div class="card-body playlist-tracks-card">
      <form @submit.prevent="submit">
        <table class="table table-striped member-recordings">
          <thead>
            <tr>
              <th class="member-checkbox">
                <button
                  class="btn btn-danger detach-btn"
                  :disabled="selectedFileIds.length == 0"
                  @click="detachAll"
                >
                  Detach Selected
                </button>
              </th>
              <th>Title</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            <template v-for="member in members">
              <playlist-member
                :key="member.id.id"
                :resource="member"
                @update="detach"
                @idSelected="addId"
                @idRemoved="removeId"
              />
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
  name: 'PlaylistMembers',
  components: {
    'playlist-member': PlaylistMember
  },
  props: {
    resourceId: {
      type: String,
      required: true
    },
    members: {
      type: Array,
      default: function () { return [] }
    }
  },
  data () {
    return { submitting: false, selectedFileIds: [] }
  },
  methods: {
    buildFormData () {
      let form = new FormData()
      form.append('_method', 'delete')

      return form
    },
    submit () { return false },
    detach (proxyIds) {
      let vm = this
      this.submitting = true

      // These have to be detached sequentially because of a race condition.
      // The requests delete the child, which then cleans up membership, but if
      // they happen really close to one another then one member gets
      // reinstated. To fix this we'd have to have a way to tell the parent to
      // delete its children
      let promise = Promise.resolve()
      for (let proxyId of proxyIds) {
        promise = promise.then((response) => {
          return axios.post(`/concern/playlists/${proxyId}`,
            this.buildFormData()
          )
        })
      }
      promise.then(function (response) {
        vm.submitting = false
        window.location.reload()
      })
    },
    detachAll () {
      let buttons = document.getElementsByClassName('detach-btn')
      for (let b of buttons) {
        b.disabled = true
      }
      this.detach(this.selectedFileIds)
    },
    addId (id) {
      this.selectedFileIds.push(id)
    },
    removeId (id) {
      this.selectedFileIds = this.selectedFileIds.filter(item => item !== id)
    }
  }
}
</script>
<style scope>
member-resources > tbody > tr > td.member-checkbox {
    width: 10px;
  }
</style>
