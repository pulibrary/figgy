<template>
  <tr>
    <td class="member-checkbox">
      <input
        id="checkbox"
        v-model="checked"
        type="checkbox"
        @change="checkboxChanged"
      >
    </td>
    <td>
      {{ resource.label[0] }} (<a :href="`${resource.recording_url}`">
        {{ resource.recording_title }}
      </a>)
    </td>
    <td>
      <button
        class="btn btn-danger detach-btn"
        @click="detach($event)"
      >
        <loader
          v-if="detachClicked"
          size="x-small"
          wrapper="span"
        /> Detach
      </button>
    </td>
  </tr>
</template>
<script>

export default {
  name: 'PlaylistMember',
  props: {
    resource: {
      type: Object,
      default: null
    }
  },
  data () {
    // This is due to the fact that Valkyrie::ID objects are not serialized as strings
    const resourceId = this.resource.id
    return {
      id: resourceId.id,
      detachClicked: false,
      checked: false
    }
  },
  methods: {
    detach: function (event) {
      // add spinner to button that was clicked
      this.detachClicked = true
      // disable all detach buttons
      const buttons = document.getElementsByClassName('detach-btn')
      for (const b of buttons) {
        b.disabled = true
      }
      // do the detach
      this.$emit('update', [this.id])
    },
    checkboxChanged: function (event) {
      if (event.target.checked) {
        this.$emit('idSelected', this.id)
      } else {
        this.$emit('idRemoved', this.id)
      }
    }
  }
}
</script>
<style scope>
.lux-loader {
  display: inline-block;
}
.detach-btn {
  width: 150px;
}
</style>
