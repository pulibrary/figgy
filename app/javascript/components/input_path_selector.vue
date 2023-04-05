<template>
  <div id="input-path-selector">
    <div
      class="button-wrapper"
      @click="launchBrowser"
    >
      <button
        type="button"
        class="btn btn-input-path"
        @click="launchBrowser"
      />
    </div>
    <div
      v-if="browserLaunched"
      id="file-browser-modal"
      @click.self="closeBrowser"
    >
      <div class="modal-content">
        <span
          class="close"
          @click="closeBrowser"
        >&times;</span>
        <file-browser
          :start-tree="startTree"
          mode="directoryIngest"
          @folderSelect="folderSelect"
        />
      </div>
    </div>
  </div>
</template>
<script>
import FileBrowser from './file_browser.vue'
export default {
  name: 'InputPathSelector',
  components: {
    FileBrowser
  },
  props: {
    startTree: {
      type: Array,
      default: null
    },
    inputElementId: {
      type: String,
      required: true
    },
    summaryElementId: {
      type: String,
      default: null
    },
    folderPrefix: {
      type: String,
      default () { return '' }
    }
  },
  data () {
    return {
      browserLaunched: false
    }
  },
  computed: {
    summaryElement () {
      return document.getElementById(this.summaryElementId)
    },
    inputElement () {
      return document.getElementById(this.inputElementId)
    }
  },
  methods: {
    launchBrowser () {
      this.browserLaunched = true
    },
    closeBrowser () {
      this.browserLaunched = false
    },
    folderSelect (folder) {
      this.browserLaunched = false
      this.inputElement.value = `${this.folderPrefix}${folder.path}`
      if (this.summaryElement !== null) {
        this.summaryElement.innerHTML = `Will create ${folder.children.length} resource(s).`
      }
    }
  }
}
</script>
<style lang="scss" scope>
  #input-path-selector {
    display: inline-block;
    .button-wrapper {
      cursor: pointer;
    }
  }
  #file-browser-modal {
    position: fixed;
    z-index: 100;
    left: 0;
    top: 0;
    width: 100%;
    height: 100%;
    overflow: none;
    background-color: rgba(0,0,0,0.4);
    .modal-content {
      background-color: white;
      margin: 5% auto;
      padding: 20px;
      border: 1px solid black;
      width: 80%;
      height: 80%;
    }
    /* The Close Button */
    .close {
      color: #aaa;
      position: absolute;
      right: 20px;
      font-size: 28px;
      font-weight: bold;
    }

    .close:hover,
    .close:focus {
      color: black;
      text-decoration: none;
      cursor: pointer;
    }
  }
</style>
