<template>
  <div id="file-browser-container">
    <div id="file-browser-directory-tree">
      <DirectoryPicker
        :start-children="tree"
        :root="true"
        :list-focus="listFocus"
        @listFocus="listFocused"
        @loadChild="loadChild"
      />
    </div>
    <div id="file-browser-preview">
      <DirectoryContents
        :folder="listFocus"
        :mode="mode"
        @folderSelect="folderSelect"
        @filesSelect="filesSelect"
      />
    </div>
  </div>
</template>
<script>
import DirectoryPicker from './directory_picker.vue'
import DirectoryContents from './directory_contents.vue'
export default {
  name: 'FileBrowser',
  components: {
    DirectoryPicker,
    DirectoryContents
  },
  props: {
    startTree: {
      type: Array,
      default: null
    },
    mode: {
      type: String,
      required: true,
      validator (value) {
        return ['directoryIngest', 'fileIngest'].includes(value)
      }
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
    },
    folderSelect (folder) {
      this.$emit('folderSelect', folder)
    },
    filesSelect (files) {
      this.$emit('filesSelect', files)
    },
    loadChild (child) {
      if (child.loaded === false && child.loadChildrenPath) {
        this.loadChildren(child)
      }
    },
    loadChildren (child) {
      return fetch(
        child.loadChildrenPath,
        { credentials: 'include' }
      )
        .then((response) => response.json())
        .then((response) => {
          child.children = response
          child.loaded = true
        })
        .catch(_ => { child.expanded = false })
    }
  }
}
</script>
<style scope>
#file-browser-container {
  display: flex;
  flex-grow: 1;
  width: 100%;
  height: 100%;
}
#file-browser-directory-tree {
  flex-grow: 1;
  overflow-y: scroll;
}
#file-browser-preview {
  flex-grow: 3;
}
</style>
