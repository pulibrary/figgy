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
        <template v-for="monogram in members">
          <td :key="monogram.id">
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

      <tr class="hidden">
        <template v-for="monogram in attachedMembers">
          <td :key="monogram.id">
            <input
              type="hidden"
              name="numismatics_issue[numismatic_monogram_ids][]"
              :value="monogram.id"
            />
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
import IssueMonogram from './issue_monogram'

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
    },
    formId: {
      type: String,
      default: 'nested_new_numismatics_monogram'
    }
  },
  data: function () {
    return {
      attachedMembers: this.members.filter((e) => e.attached)
    }
  },
  computed: {
    form: function () {
      // The form should be a root/parent component
      return document.getElementById(this.formId)
    }
  },
  created: function () {
    // If the form is a root/parent component, this would be $emit elsewhere
    // this.form.addEventListener('attach-monogram', this.addAndAttachMember)
    window.addEventListener('attach-monogram', this.handleAttachMember)
  },
  beforeDestroy: function () {
    // This should not be required
    // this.form.removeEventListener('attach-monogram', this.addAndAttachMember)
    window.removeEventListener('attach-monogram', this.handleAttachMember)
  },
  methods: {
    addMember (member) {
      // This is inefficient, but one must avoid adding any existing members
      const idx = this.members.findIndex((e) => e.id === member.id)
      if (idx === -1) {
        this.members.push(member)
      }
    },
    attach (attached) {
      this.attachedMembers.push(attached)
    },
    handleAttachMember (event) {
      this.addMember(event.detail.data)
      this.attach(event.detail.data)
    },
    detach (detached) {
      const idx = this.attachedMembers.findIndex((e) => e.id === detached.id)
      this.attachedMembers.splice(idx, 1)
    }
  }
}
</script>
