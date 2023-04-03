<template>
  <div id="directory-contents">
    <div class="info-pane">
      <a
        v-if="mode === 'fileIngest'"
        href="#"
        class="button"
        :class="{ disabled: !folder || childFiles.length === 0 }"
        @click.prevent="selectAll"
      >
        Select All
      </a>
    </div>
    <div
      class="details"
      @click.self.exact="clearSelection"
    >
      <ul
        v-if="folder !== null"
      >
        <li
          v-for="child in childDirectories"
          :key="child.path"
          class="directory"
        >
          <div
            class="icon"
          >
            <svg><path d="M11 5h13v17h-24v-20h8l3 3zm-10-2v18h22v-15h-12.414l-3-3h-6.586z" /></svg>
          </div>
          <span class="label">
            {{ child.label }}
          </span>
        </li>
        <li
          v-for="child in childFiles"
          :key="child.path"
          :class="{ selected: isSelected(child) }"
          class="file"
          @click.exact="fileSelect($event, child)"
          @click.shift="fileRangeSelect($event, child)"
          @click.ctrl.prevent="fileToggleSelect($event, child)"
          @contextmenu.prevent="fileToggleSelect($event, child)"
        >
          <lux-icon-base
            class="icon"
            width="25"
            height="25"
            icon-name="file"
          >
            <lux-icon-file />
          </lux-icon-base>
          <span class="label">
            {{ child.label }}
          </span>
        </li>
      </ul>
    </div>
    <div
      v-if="folder !== null"
      class="actions"
    >
      <a
        v-if="mode === 'directoryIngest'"
        href="#"
        class="button"
        :class="{ disabled: !folder.selectable }"
        @click.prevent="folderSelect"
      >
        Ingest {{ folder.label }} directory
      </a>
      <a
        v-if="mode === 'fileIngest'"
        href="#"
        class="button"
        :class="{ disabled: selectedFiles.length === 0 }"
        @click.prevent="submitFileSelect"
      >
        Ingest {{ selectedFiles.length }} selected file(s)
      </a>
    </div>
  </div>
</template>
<script>
export default {
  name: 'DirectoryContents',
  props: {
    folder: {
      type: Object,
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
      selectedFiles: [],
      lastSelected: null
    }
  },
  computed: {
    childDirectories () {
      return this.folder.children.filter(child => child.expandable === true)
    },
    childFiles () {
      return this.folder.children.filter(child => child.expandable === false)
    },
    orderedSelectedFiles () {
      let copiedFiles = Object.assign([], this.selectedFiles)
      return copiedFiles.sort((a, b) => this.folder.children.indexOf(a) -
        this.folder.children.indexOf(b))
    }
  },
  watch: {
    // When folder changes the context has changed, unselect everything.
    folder () {
      this.selectedFiles = []
    }
  },
  methods: {
    folderSelect () {
      this.$emit('folderSelect', this.folder)
    },
    submitFileSelect () {
      this.$emit('filesSelect', this.orderedSelectedFiles)
    },
    fileSelect (event, child) {
      if (this.isSelected(child) && this.selectedFiles.length === 1) {
        this.selectedFiles.pop(child)
        // Set last selected to null so shift+click won't work.
        this.lastSelected = null
      } else {
        // Set last selected to this one so shift+click can work.
        this.lastSelected = child
        this.selectedFiles = [child]
      }
    },
    fileToggleSelect (event, child) {
      if (this.isSelected(child)) {
        this.selectedFiles = this.selectedFiles.filter(item => item !== child)
      } else {
        this.selectedFiles.push(child)
      }
    },
    fileRangeSelect (event, endChild) {
      if (this.lastSelected !== null) {
        const startIndex = this.folder.children.indexOf(this.lastSelected)
        const endIndex = this.folder.children.indexOf(endChild)
        // Do min/max to support shift+clicking an earlier item in the array.
        const newSelections = this.folder.children.slice(
          Math.min(startIndex, endIndex),
          Math.max(startIndex, endIndex) + 1
        )
        this.selectedFiles = newSelections
      }
    },
    selectAll () {
      this.selectedFiles = this.childFiles
    },
    clearSelection () {
      this.selectedFiles = []
    },
    isSelected (child) {
      return this.selectedFiles.includes(child)
    }
  }
}
</script>
<style lang="scss" scope>
  #directory-contents {
    width: 100%;
    height: 100%;
    --color-bleu-de-france: rgb(44, 110, 175);
    --color-bleu-de-france-darker: rgb(35, 87, 139);
    --color-bleu-de-france-lighter: rgb(149, 189, 228);
  }
  #directory-contents > .info-pane {
    height: 60px;
    padding: 10px;
  }
  #directory-contents > .details {
    height: calc(100% - 120px);
    overflow-y: scroll;
    padding: 10px;
  }
  #directory-contents > .actions {
    height: 60px;
    padding: 10px;
    display: flex;
    align-items: center;
  }
  #directory-contents .icon {
    display: inline-block;
    margin-left: 0;
  }
  #directory-contents .lux-icon {
    margin-left: 0;
  }
  #directory-contents .icon svg {
    width: 25px;
    height: 25px;
  }
  #directory-contents .label {
    display: inline-block;
  }
  #directory-contents li {
    width: 100%;
    padding-bottom: 5px;
    border-bottom: 1px solid gray;
    user-select: none;
    &.selected {
      border: 2px solid var(--color-bleu-de-france-darker);
    }
  }

  #directory-contents ul {
    list-style-type: none;
    padding: 0;
    padding-left: 0px;
  }

  #directory-contents .button {
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
</style>
