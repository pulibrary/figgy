<template>
  <div id="bag-path-selector">
    <button
      id="browse_everything"
      type="button"
      class="btn btn-bag-path browse-everything"
      @click="launchBrowser"
    />
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
  name: 'BagPathSelector',
  components: {
    FileBrowser
  },
  props: {
    startTree: {
      type: Array,
      default: null
    },
    windowTarget: {
      type: String,
      required: true
    },
    folderPrefix: {
      type: String,
      required: true
    }
  },
  data () {
    return {
      browserLaunched: false
    }
  },
  computed: {
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
      document.getElementById(this.windowTarget).value = `${this.folderPrefix}${folder.path}`
    }
  }
}
</script>
<style lang="scss" scope>
  #bag-path-selector {
    display: inline-block;
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
