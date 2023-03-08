<template>
  <div id="folder-preview">
    <div class="info-pane" />
    <div class="details" />
    <div class="actions" />
  </div>
</template>
<script>
// Support choosing a single directory for use in Bulk Ingest.
// TODO: Add multi-select functionality for file select.
export default {
  name: 'FolderPreview',
  props: {
    folder: {
      type: Object,
      default: null
    }
  },
  data () {
    return {}
  },
  computed: {
  },
  methods: {
  }
}
</script>
<style scope>
  #folder-preview {
    width: 100%;
    height: 100%;
  }
  #folder-preview > .info-pane {
    height: 30px;
  }
  #folder-preview > .details {
    height: calc(100% - 60px);
    overflow-y: scroll;
  }
  #folder-preview > .actions {
    height: 30px;
  }
</style>
