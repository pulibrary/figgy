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
import axios from 'axios'

export default {
  name: 'PlaylistMember',
  props: ['resource'],
  data () {
    // This is due to the fact that Valkyrie::ID objects are not serialized as strings
    const resource_id = this.resource.id
    return {
	    id: resource_id.id
    }
  }
}
</script>
<style scope>
</style>
