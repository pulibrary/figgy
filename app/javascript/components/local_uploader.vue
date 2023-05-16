<template>
  <div id="local_uploader">
    <template v-for="file in uploadedFiles">
      <input
        :key="file.id"
        type="hidden"
        :name="`metadata_ingest_files[]`"
        :value="JSON.stringify(file)"
      >
    </template>
    <div id="drag-drop" />
    <div id="status-bar" />
  </div>
</template>
<script>
import Uppy, { debugLogger } from '@uppy/core'
import DragDrop from '@uppy/drag-drop'
import StatusBar from '@uppy/status-bar'
import Tus from '@uppy/tus'
import '@uppy/core/dist/style.css'
import '@uppy/drag-drop/dist/style.css'
import '@uppy/status-bar/dist/style.css'
const TUS_ENDPOINT = '/files/'

export default {
  name: 'LocalUploader',
  components: {
  },
  props: {
    formId: {
      type: String,
      required: true
    },
    folderPrefix: {
      type: String,
      default () { return '' }
    }
  },
  data () {
    return {
      uploadedFiles: [],
      uppy: null
    }
  },
  computed: {
    formElement () {
      return document.getElementById(this.formId)
    }
  },
  mounted () {
    const uppy = new Uppy({ logger: debugLogger })
      .use(DragDrop, {
        target: '#drag-drop'
      })
      .use(StatusBar, { target: '#status-bar' })
    uppy.use(Tus, { endpoint: TUS_ENDPOINT, limit: 6 })
    this.uppy = uppy

    uppy.on('complete', (result) => {
      this.uploadComplete(result)
    })
  },
  methods: {
    uploadComplete (result) {
      this.uploadedFiles = result.successful.map((file) => {
        return {
          id: `disk://${this.folderPrefix}/${file.uploadURL.split('/').slice(-1)[0]}`,
          filename: file.name,
          type: file.type
        }
      })
      this.$nextTick(() => {
        this.formElement.submit()
      })
    }
  }
}
</script>
<style lang="scss" scope>
  #local_uploader {
    width: 100%;
    height: 100%;
  }
</style>
