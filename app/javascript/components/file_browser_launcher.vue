<template>
  <div id="file-browser-launcher">
    <a
      class="button"
      href="#"
      @click="launchBrowser"
    >
      Choose Files
    </a>
    <div
      v-if="mode === 'directoryIngest'"
      id="directory-ingest-pane"
      class="ingest-pane"
    >
      <input
        v-if="selectedFolder"
        type="hidden"
        name="ingest_directory"
        :value="selectedFolder.path"
      >
      <div class="summary">
        Selected Directory: {{ selectedFolderLabel }}
      </div>
    </div>
    <div
      v-if="mode === 'fileIngest'"
      id="file-ingest-pane"
      class="ingest-pane"
    >
      <template v-for="(file, idx) in selectedFiles">
        <input
          :key="file.path"
          type="hidden"
          :name="`ingest_files[${idx}]`"
          :value="file.path"
        >
      </template>
      <div class="summary">
        Selected Files ({{ selectedFiles.length }}):
        <ul>
          <li
            v-for="file in selectedFiles"
            :key="file.path"
          >
            {{ file.label }} ({{ file.path }})
          </li>
        </ul>
      </div>
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
          :mode="mode"
          @folderSelect="folderSelect"
          @filesSelect="filesSelect"
        />
      </div>
    </div>
  </div>
</template>
<script>
import FileBrowser from './file_browser.vue'
export default {
  name: 'FileBrowserLauncher',
  components: {
    FileBrowser
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
      browserLaunched: false,
      selectedFolder: null,
      selectedFiles: []
    }
  },
  computed: {
    selectedFolderLabel () {
      if (this.selectedFolder) {
        return `${this.selectedFolder.label} (${this.selectedFolder.path})`
      } else {
        return ''
      }
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
      this.selectedFolder = folder
      this.browserLaunched = false
    },
    filesSelect (files) {
      this.browserLaunched = false
      this.selectedFiles = files
    }
  }
}
</script>
<style lang="scss" scope>
  #file-browser-launcher {
    width: 100%;
    height: 100%;
    --color-bleu-de-france: rgb(44, 110, 175);
    --color-bleu-de-france-darker: rgb(35, 87, 139);
    --color-bleu-de-france-lighter: rgb(149, 189, 228);
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
  #file-browser-launcher .button {
    background: var(--color-bleu-de-france);
    color: white;
    text-decoration: none;
    line-height: 1.6;
    border: 0;
    border-radius: 4px;
    cursor: pointer;
    padding: 0.5rem 1rem;
    text-decoration: none;
    text-align: center;
    transition: background 250ms ease-in-out, transform 150ms ease;
    margin: 0 0.25rem;
    &:hover,
    &:focus {
      background: var(--color-bleu-de-france-darker);
      box-shadow: none;
    }
    &.disabled {
      background: var(--color-bleu-de-france-lighter);
      pointer-events: none;
      cursor: default;
    }
  }

  .ingest-pane {
    margin-left: 5px;
    margin-top: 8px;
  }
</style>
