<template>
  <div>
    <div id="file-browser-directory-tree">
      <DirectoryPicker
        :start-children="tree"
        :root="true"
        :list-focus="listFocus"
        @listFocus="listFocused"
      />
    </div>
    <div id="file-browser-preview" />
  </div>
</template>
<script>
// Support choosing a single directory for use in Bulk Ingest.
// TODO: Add multi-select functionality for file select.
import DirectoryPicker from './directory_picker.vue'
export default {
  name: 'FileBrowser',
  components: {
    DirectoryPicker
  },
  props: {
    startTree: {
      type: Array,
      default: null
    }
  },
  data () {
    return {
      'listFocus': null,
      'tree': this.startTree
    }
  },
  computed: {
  },
  methods: {
    listFocused (child) {
      this.listFocus = child
    }
  }
}
</script>
<style scope>
</style>
