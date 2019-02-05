<template>
  <tr>
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
        <loader size="x-small" v-if="detachClicked" wrapper="span"></loader> Detach
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
      detachClicked: false
    }
  },
  methods: {
    detach: function (event) {
      this.detachClicked = true
      this.$emit('update', this.id)
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
