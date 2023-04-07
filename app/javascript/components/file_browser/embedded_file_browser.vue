<template>
  <div id="embedded_file_browser">
    <template v-for="file in selectedFiles">
      <input
        :key="file.path"
        type="hidden"
        :name="`ingest_files[]`"
        :value="file.path"
      >
    </template>
    <file-browser
      :start-tree="startTree"
      mode="fileIngest"
      @filesSelect="filesSelect"
    />
  </div>
</template>
<script>
import FileBrowser from './file_browser.vue'
export default {
  name: 'EmbeddedFileBrowser',
  components: {
    FileBrowser
  },
  props: {
    startTree: {
      type: Array,
      default: null
    },
    formId: {
      type: String,
      required: true
    }
  },
  data () {
    return {
      selectedFiles: []
    }
  },
  computed: {
    formElement () {
      return document.getElementById(this.formId)
    }
  },
  methods: {
    filesSelect (files) {
      this.browserLaunched = false
      this.selectedFiles = files
      // Delay a tick so the hidden inputs render.
      this.$nextTick(() => {
        this.formElement.submit()
      })
    }
  }
}
</script>
<style lang="scss" scope>
  #embedded_file_browser {
    width: 100%;
    height: 100%;
  }
</style>
