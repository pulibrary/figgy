<template>
  <td>
    <div class="monogram-content">
      <div class="monogram-content-thumbnail">
        <img
          :src="resource.thumbnail"
          alt="Default"
          class="thumbnail-inner"
        >
      </div>
      <p>{{ resource.title }}</p>
    </div>

    <div class="monogram-options">
      <a
        :href="resource.url"
        class="btn btn-secondary"
      >View</a>
      <template v-if="isAttached">
        <button
          name="button"
          class="btn btn-secondary btn btn-danger btn-remove-row"
          @click.prevent="detach"
        >
          Detach
        </button>
      </template>
      <template v-else>
        <button
          name="button"
          class="btn btn-secondary btn btn-primary btn-add-row"
          @click.prevent="attach"
        >
          Attach
        </button>
      </template>
    </div>
  </td>
</template>
<script>
export default {
  name: 'IssueMonogram',
  props: {
    resource: {
      type: Object,
      default: null
    },
    attached: {
      type: Boolean,
      default: false
    }
  },
  data () {
    return {
      isAttached: this.attached
    }
  },
  methods: {
    attach: function () {
      this.isAttached = true
      this.$emit('attach', this.resource)
    },
    detach: function () {
      this.isAttached = false
      this.$emit('detach', this.resource)
    }
  }
}
</script>
