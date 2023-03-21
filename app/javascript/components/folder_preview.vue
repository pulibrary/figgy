<template>
  <div id="folder-preview">
    <div class="info-pane" />
    <div class="details">
      <ul>
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
          @click="fileSelect($event, child)"
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
    <div class="actions">
      <a
        v-if="mode === 'directoryIngest'"
        href="#"
        class="button"
        :class="{ disabled: !folder.selectable }"
        @click="folderSelect"
      >
        Ingest {{ folder.label }} directory
      </a>
      <a
        v-if="mode === 'fileIngest'"
        href="#"
        class="button"
        :class="{ disabled: selectedFiles.length === 0 }"
      >
        Ingest selected files
      </a>
    </div>
  </div>
</template>
<script>
// Support choosing a single directory for use in Bulk Ingest.
// TODO: Add multi-select functionality for file select.
export default {
  name: 'FolderPreview',
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
      selectedFiles: []
    }
  },
  computed: {
    childDirectories () {
      return this.folder.children.filter(child => child.expandable === true)
    },
    childFiles () {
      return this.folder.children.filter(child => child.expandable === false)
    }
  },
  methods: {
    folderSelect () {
      this.$emit('folderSelect', this.folder)
    },
    fileSelect (event, child) {
      if (this.isSelected(child)) {
        this.selectedFiles.pop(child)
      } else {
        this.selectedFiles.push(child)
      }
    },
    isSelected (child) {
      return this.selectedFiles.includes(child)
    }
  }
}
</script>
<style lang="scss" scope>
  #folder-preview {
    width: 100%;
    height: 100%;
    --color-bleu-de-france: rgb(44, 110, 175);
    --color-bleu-de-france-darker: rgb(35, 87, 139);
    --color-bleu-de-france-lighter: rgb(149, 189, 228);
  }
  #folder-preview > .info-pane {
    height: 60px;
    padding: 10px;
  }
  #folder-preview > .details {
    height: calc(100% - 120px);
    overflow-y: scroll;
    padding: 10px;
  }
  #folder-preview > .actions {
    height: 60px;
    padding: 10px;
    display: flex;
    align-items: center;
  }
  #folder-preview .icon {
    display: inline-block;
    margin-left: 0;
  }
  #folder-preview .lux-icon {
    margin-left: 0;
  }
  #folder-preview .icon svg {
    width: 25px;
    height: 25px;
  }
  #folder-preview .label {
    display: inline-block;
  }
  #folder-preview li {
    width: 100%;
    padding-bottom: 5px;
    border-bottom: 1px solid gray;
  }

  #folder-preview ul {
    list-style-type: none;
    padding: 0;
    padding-left: 0px;
  }

  #folder-preview .button {
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
