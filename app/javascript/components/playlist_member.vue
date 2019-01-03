<template>
  <tr>
    <td>{{ resource.label[0] }}</td>
    <td>
      <button
        class="btn btn-danger"
        @click="$emit('update', id)"
      >
        Detach
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
      id: resourceId.id
    }
  }
}
</script>
<style scope>
</style>
