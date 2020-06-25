<template>
  <dropzone ref="fileUploaderDropzone" id="dropzone" :options="dropzoneOptions" v-on:vdropzone-complete="uploadComplete" :useCustomSlot=true >
    <div class="dropzone-custom-content">
      <div class="dropzone-custom-title">Drag and drop PDFs here to upload</div>
    </div>
  </dropzone>
</template>
<script>
import vue2Dropzone from 'vue2-dropzone'
import 'vue2-dropzone/dist/vue2Dropzone.min.css'

export default {
  name: 'FileUploader',
  components: {
    'dropzone': vue2Dropzone
  },
  props: {
    csrfToken: {
      type: String,
      default: document.getElementsByName('csrf-token')[0].content
    },
    tableName: {
      type: String,
      default: null
    },
    mimeTypes: {
      type: String,
      default: null
    },
    uploadPath: {
      type: String,
      required: true
    }
  },
  data () {
    return {
      options: [],
      dropzoneOptions: {
        acceptedFiles: this.mimeTypes,
        createImageThumbnails: false,
        headers: { 'X-CSRF-Token': this.csrfToken },
        url: this.uploadPath
      }
    }
  },
  methods: {
    uploadComplete (response) {
      // Remove file from dropzone UI
      this.$refs.fileUploaderDropzone.removeFile(response)
    }
  }
}
</script>
