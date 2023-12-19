<template>
  <dropzone
    id="dropzone"
    ref="fileUploaderDropzone"
    :options="dropzoneOptions"
    :use-custom-slot="true"
    @vdropzone-complete="uploadComplete"
    @vdropzone-sending="sendingEvent"
    @vdropzone-complete-multiple="reloadPage"
  >
    <div class="dropzone-custom-content">
      <div class="dropzone-custom-title">
        {{ infoString }}
      </div>
    </div>
  </dropzone>
</template>
<script>
import vue2Dropzone from 'vue2-dropzone'
import 'vue2-dropzone/dist/vue2Dropzone.min.css'

export default {
  name: 'FileUploader',
  components: {
    dropzone: vue2Dropzone
  },
  props: {
    infoString: {
      type: String,
      default: 'Drag and drop files here to upload.'
    },
    csrfToken: {
      type: String,
      default: document.getElementsByName('csrf-token')[0]
        ? document.getElementsByName('csrf-token')[0].content
        : undefined
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
    },
    paramName: {
      type: String,
      default: 'file'
    },
    multiple: {
      type: Boolean,
      default: false
    },
    patch: {
      type: Boolean,
      default: false
    }
  },
  data () {
    return {
      options: [],
      dropzoneOptions: {
        acceptedFiles: this.mimeTypes,
        createImageThumbnails: false,
        headers: { 'X-CSRF-Token': this.csrfToken },
        url: this.uploadPath,
        paramName: this.paramName,
        uploadMultiple: this.multiple,
        maxFilesize: null,
        timeout: 7200000
      }
    }
  },
  methods: {
    uploadComplete (response) {
      // Remove file from dropzone UI
      this.$refs.fileUploaderDropzone.removeFile(response)
    },
    sendingEvent (file, xhr, formData) {
      if (this.patch === true) {
        formData.append('_method', 'patch')
        formData.append(
          this.paramName.replace(/\[.*\]/, '[skip_validation]'),
          'true'
        )
      }
    },
    reloadPage () {
      window.location.reload()
    }
  }
}
</script>
