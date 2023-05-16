<template>
  <div id="local_uploader">
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
const UPLOADER = 'tus'
const TUS_ENDPOINT = '/files/'

export default {
  name: 'LocalUploader',
  components: {
  },
  props: {
    formId: {
      type: String,
      required: true
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
      console.log(result)
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
