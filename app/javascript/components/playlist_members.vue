<template>
  <div class="panel panel-default">
    <div class="panel-heading">
      <h2 class="panel-title">
        Tracks
      </h2>
    </div>
    <div class="row panel-body">
      <form @submit.prevent="submit">
        <table class="table table-striped member-resources member-recordings">
          <thead>
            <tr>
              <th>Title</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            <template v-for="member in members">
              <playlist-member
                :key="member.id"
                :resource="member"
                @update="detach"
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
    return { submitting: false }
  },
  methods: {
    buildFormData () {
      let form = new FormData()
      form.append('_method', 'delete')

      return form
    },
    submit () { return false },
    detach (proxyId) {
      let vm = this
      this.submitting = true

      axios.post(`/concern/playlists/${proxyId}`,
        this.buildFormData()
      ).then(function (response) {
        vm.submitting = false
        window.location.reload()
      })
    }
  }
}
</script>
<style scope>
</style>
