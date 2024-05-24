<template>
  <div id="local_uploader">
    <template v-for="file in uploadedFiles" :key="file.id">
      <input
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
import Uppy from '@uppy/core'
import DragDrop from '@uppy/drag-drop'
import StatusBar from '@uppy/status-bar'
import Tus from '@uppy/tus'
import '@uppy/core/dist/style.css'
import '@uppy/drag-drop/dist/style.css'
import '@uppy/status-bar/dist/style.css'
const TUS_ENDPOINT = '/local_file_upload/'

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
      uploadedFiles: []
    }
  },
  computed: {
    formElement () {
      return document.getElementById(this.formId)
    }
  },
  mounted () {
    const uppy = new Uppy()
      .use(DragDrop, {
        target: '#drag-drop'
      })
      .use(StatusBar, { target: '#status-bar' })
    // chunkSize is set to 5 MB because nginx buffers uploads, so resuming
    // doesn't work without it. Set to this at the recommendation of
    // tus-ruby-server: https://github.com/janko/tus-ruby-server/issues/7#issuecomment-357972164
    uppy.use(Tus, { endpoint: TUS_ENDPOINT, limit: 6, chunkSize: (5 * 1024 * 1024) })

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
