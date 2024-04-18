<template>
  <table
    id="numismatic-monograms"
    class="table table-striped member-resources numismatic-monograms"
  >
    <thead>
      <tr>
        <th />
      </tr>
    </thead>

    <tbody>
      <tr>
        <template v-for="monogram in members" :key="monogram.id">
          <td>
            <issue-monogram
              :key="monogram.id"
              :resource="monogram"
              :attached="monogram.attached"
              @attach="attach"
              @detach="detach"
            />
          </td>
        </template>
      </tr>

      <tr class="d-none">
        <template v-for="monogram in attachedMembers" :key="monogram.id">
          <td>
            <input
              type="hidden"
              name="numismatics_issue[numismatic_monogram_ids][]"
              :value="monogram.id"
            >
          </td>
        </template>
      </tr>
      <tr class="d-none">
        <template v-if="attachedMembers.length === 0">
          <td>
            <input
              type="hidden"
              name="numismatics_issue[numismatic_monogram_ids][]"
              value=""
            >
          </td>
        </template>
      </tr>
    </tbody>

    <tfoot>
      <tr class="">
        <td />
      </tr>
    </tfoot>
  </table>
</template>
<script>
import IssueMonogram from './issue_monogram.vue'

export default {
  name: 'IssueMonograms',
  components: {
    'issue-monogram': IssueMonogram
  },
  props: {
    resource: {
      type: Object,
      default: null
    },
    members: {
      type: Array,
      default: function () { return [] }
    },
    nonMembers: {
      type: Array,
      default: function () { return [] }
    },
    defaultThumbnailUrl: {
      type: String,
      default: null
    }
  },
  data: function () {
    return {
      attachedMembers: this.members.filter((e) => e.attached)
    }
  },
  methods: {
    attach (attached) {
      this.attachedMembers.push(attached)
    },
    detach (detached) {
      const idx = this.attachedMembers.findIndex((e) => e.id === detached.id)
      this.attachedMembers.splice(idx, 1)
    }
  }
}
</script>
