<template>
  <component
    :is="type"
    :class="['lux-toolbar']"
  >
    <dropdown-menu
      class="dropdown"
      button-label="Actions"
      :menu-items="[
        {name: 'Create New Folder (Ctrl-n)', component: 'FolderCreate'},
        {name: 'Group Selected into New Folder (Ctrl-g)', component: 'SelectedCreate', disabled: isCutDisabled()},
        {name: 'Delete Folder (Ctrl-d)', component: 'FolderDelete', disabled: rootNodeSelected},
        {name: 'Undo Cut (Ctrl-z)', component: 'UndoCut', disabled: !isCutDisabled()},
        {name: 'Cut (Ctrl-x)', component: 'Cut', disabled: isCutDisabled()},
        {name: 'Paste (Ctrl-v)', component: 'Paste', disabled: isPasteDisabled()},
        {name: 'Zoom on Selected (Ctrl-o)', component: 'Zoom', disabled: isZoomDisabled()}
      ]"
      @menu-item-clicked="menuSelection($event)"
    />
    <input-button
      id="save_btn"
      variation="solid"
      size="medium"
      @button-clicked="saveHandler($event)"
    >
      Save Structure (Ctrl-s)
    </input-button>
    <spacer />
    <div class="lux-zoom-slider">
      <lux-icon-base
        class="lux-svg-icon"
        icon-name="shrink"
        icon-color="rgb(0,0,0)"
        width="12"
        height="12"
      >
        <lux-icon-picture />
      </lux-icon-base>
      <label for="img_zoom">
        Image zoom
      </label>
      <input
        id="img_zoom"
        type="range"
        min="40"
        max="300"
        value="150"
        @input="resizeCards($event)"
      >
      <lux-icon-base
        class="lux-svg-icon"
        icon-name="grow"
        icon-color="rgb(0,0,0)"
        width="24"
        height="24"
      >
        <lux-icon-picture />
      </lux-icon-base>
    </div>
  </component>
</template>

<script>
import { mapState } from 'vuex'
import mixin from './structMixins.js'
/**
 * Toolbars allows a user to select a value from a series of options.
 */
export default {
  name: 'StructManagerToolbar',
  status: 'ready',
  release: '1.0.0',
  type: 'Pattern',
  mixins: [mixin],
  props: {
    /**
     * The html element name used for the container
     */
    type: {
      type: String,
      default: 'div'
    }
  },
  data: function () {
    return {
      end_nodes: [],
      resourceToSave: null
    }
  },
  computed: {
    ...mapState({
      resource: state => state.ordermanager.resource,
      tree: state => state.tree,
      gallery: state => state.gallery,
      zoom: state => state.zoom
    }),
    cut: {
      get () {
        return this.gallery.cut
      }
    },
    rootNodeSelected: function () {
      return this.tree.selected === this.tree.structure.id
    }
  },
  mounted: function () {
    this._keyListener = function (e) {
      if (e.key === 'x' && (e.ctrlKey || e.metaKey)) {
        e.preventDefault()
        this.cutSelected()
      }
      if (e.key === 'v' && (e.ctrlKey || e.metaKey)) {
        e.preventDefault()
        this.paste()
      }
      if (e.key === 'd' && (e.ctrlKey || e.metaKey)) {
        e.preventDefault()
        this.deleteFolder(this.tree.selected)
      }
      if (e.key === 'z' && (e.ctrlKey || e.metaKey)) {
        e.preventDefault()
        this.clearClipboard()
      }
      if (e.key === 'n' && (e.ctrlKey || e.metaKey)) {
        e.preventDefault()
        this.createFolder()
      }
      if (e.key === 'g' && (e.ctrlKey || e.metaKey)) {
        e.preventDefault()
        this.groupSelectedIntoFolder()
      }
      if (e.key === 'o' && (e.ctrlKey || e.metaKey)) {
        e.preventDefault()
        this.zoomOnItem()
      }
      if (e.key === 's' && (e.ctrlKey || e.metaKey)) {
        e.preventDefault()
        this.saveHandler(e)
      }
    }

    document.addEventListener('keydown', this._keyListener.bind(this))
  },
  beforeDestroy: function () {
    document.removeEventListener('keydown', this._keyListener)
  },
  methods: {
    saveHandler: function (event) {
      if (this.isSaveDisabled()) {
        // workaround for a bug in LUX that doesn't style disabled buttons properly
        alert('The structure has not changed, nothing to save.')
      } else {
        this.$emit('save-structure', event)
      }
    },
    cutSelected: function () {
      this.$emit('cut-selected')
    },
    isCutDisabled: function () {
      if (this.gallery.selected.length) {
        return false
      }
      if (this.tree.selected) {
        return false
      }
      return true
    },
    isPasteDisabled: function () {
      return !(this.gallery.cut.length || this.tree.cut)
    },
    isSaveDisabled: function () {
      if (this.tree.saveState === 'SAVING') {
        return true
      } else if (this.tree.modified) {
        return false
      } else {
        return true
      }
    },
    isZoomDisabled: function () {
      if (this.gallery.selected.length === 1) {
        return false
      } else if (this.tree.selected && !this.rootNodeSelected) {
        const nodeToBeZoomed = this.findFolderById(this.tree.structure.folders, this.tree.selected)
        const hasService = !!nodeToBeZoomed.service
        if (hasService) {
          return false
        }
      }
      return true
    },
    paste: function () {
      this.$emit('paste-items')
    },
    clearClipboard: function () {
      this.$emit('clear-clipboard')
    },
    resizeCards: function (event) {
      this.$emit('cards-resized', event)
    },
    menuSelection (value) {
      switch (value.target.innerText) {
        case 'Create New Folder (Ctrl-n)':
          this.createFolder()
          break
        case 'Group Selected into New Folder (Ctrl-g)':
          this.groupSelectedIntoFolder()
          break
        case 'Delete Folder (Ctrl-d)':
          this.deleteFolder(this.tree.selected)
          break
        case 'Undo Cut (Ctrl-z)':
          this.clearClipboard()
          break
        case 'Cut (Ctrl-x)':
          this.cutSelected()
          break
        case 'Paste (Ctrl-v)':
          this.paste()
          break
        case 'Zoom on Selected (Ctrl-o)':
          this.zoomOnItem()
          break
      }
    },
    createFolder: function () {
      const parentId = this.tree.selected ? this.tree.selected : this.tree.structure.id
      this.$emit('create-folder', parentId)
    },
    groupSelectedIntoFolder: function () {
      this.$emit('group-selected')
    },
    deleteFolder: function (folderId) {
      this.$emit('delete-folder', folderId)
    },
    zoomOnItem: function () {
      this.$emit('zoom-on-item')
    }
  }
}
</script>

<style lang="scss" scoped>
.lux-toolbar {
  box-sizing: border-box;
  margin: 0;
  margin-bottom: 16px;
  font-family: franklin-gothic-urw,Helvetica,Arial,sans-serif;
  font-size: 16px;
  line-height: 1;
  background: #f5f5f5;
  height: 64px;
  align-items: center;
  display: flex;
  padding: 0 24px;
}

.lux-zoom-slider {
  margin-top: -10px;

  .lux-svg-icon,
  input {
    vertical-align: middle;
    line-height: 1;
    margin: 0;
  }

  input[type="range"] {
    display: inline;
    width: auto;
  }

  label {
    position: absolute;
    clip: rect(1px, 1px, 1px, 1px);
    padding: 0;
    border: 0;
    height: 1px;
    width: 1px;
    overflow: hidden;
  }
}
.dropdown {
  top: 10px;
  text-align: left;
  width: 14em;
}
</style>
