<template>
  <component
    :is="type"
    :class="['lux-toolbar']"
  >
    <dropdown-menu
      class="dropdown"
      button-label="Actions"
      :menu-items="[
        {name: 'Create New Folder', component: 'FolderCreate'},
        {name: 'Delete Folder', component: 'FolderDelete'},
        {name: 'Cut', component: 'Cut', disabled: true},
        {name: 'Paste', component: 'Paste'}
      ]"
      @menu-item-clicked="menuSelection($event)"
    />
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
        max="500"
        value="300"
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
/**
 * Toolbars allows a user to select a value from a series of options.
 */
export default {
  name: 'StructManagerToolbar',
  status: 'ready',
  release: '1.0.0',
  type: 'Pattern',
  props: {
    /**
     * The html element name used for the container
     */
    type: {
      type: String,
      default: 'div'
    }
  },
  computed: {
    ...mapState({
      resource: state => state.ordermanager.resource,
      tree: state => state.tree,
      gallery: state => state.gallery
    }),
    cut: {
      get () {
        return this.gallery.cut
      }
    }
  },
  methods: {
    cutSelected: function () {
      this.$store.dispatch('cut', this.gallery.selected)
      this.selectNone()
    },
    getItemIndexById: function (id) {
      return this.gallery.items
        .map(function (item) {
          return item.id
        })
        .indexOf(id)
    },
    isCutDisabled: function () {
      return !!this.gallery.cut.length
    },
    isPasteDisabled: function () {
      return !(this.gallery.cut.length && this.gallery.selected.length)
    },
    paste: function (indexModifier) {
      let items = this.gallery.items
      items = items.filter(val => !this.gallery.cut.includes(val))
      let pasteAfterIndex =
        this.getItemIndexById(this.gallery.selected[this.gallery.selected.length - 1].id) + indexModifier
      items.splice(pasteAfterIndex, 0, ...this.gallery.cut)
      this.$store.dispatch('paste', items)
      this.resetCut()
      this.selectNone()
    },
    resetCut: function () {
      this.$store.dispatch('cut', [])
    },
    resizeCards: function (event) {
      this.$emit('cards-resized', event)
    },
    menuSelection (value) {
      switch (value.target.innerText) {
        case 'Create New Folder':
          this.createFolder([])
          break
        case 'Delete Folder':
          this.deleteFolder(value.target)
          break
        case 'Alternate':
          this.selectAlternate()
          break
        case 'Inverse':
          this.selectInverse()
          break
        case 'Cut':
          this.cutSelected()
          break
        case 'Paste Before':
          this.paste(-1)
          break
        case 'Paste After':
          this.paste(1)
          break
      }
    },
    createFolder: function (contentsList) {
      const parentId = this.tree.selected ? this.tree.selected : this.tree.structure.id;
      const newFolder = {
        id: this.generateId(),
        folders: contentsList,
        label: "Untitled",
      }
      // need to stringify and parse to drop the observer that comes with Vue reactive data
      const folderList = JSON.parse(JSON.stringify(this.tree.structure.folders))
      let parentFolderObject = this.findSelectedFolderById(folderList, parentId)
      let newParent = parentFolderObject.folders.push(newFolder)
      const structure = {
        id: this.tree.structure.id,
        folders: this.addNewFolder(folderList, newParent),
        label: this.tree.structure.label,
      }
      this.$store.commit("CREATE_FOLDER", structure)
    },
    addNewFolder: function (array, newParent) {
      for (let item of array) {
        if (item.id === newParent.id) {
          item = newParent
        } else if (item.folders?.length) {
          const innerResult = this.addNewFolder(item.folders, newParent)
        }
      }
      return array
    },
    deleteFolder: function () {
      let folderList = JSON.parse(JSON.stringify(this.tree.structure.folders))
      let folderToBeRemoved = this.findSelectedFolderById(folderList, this.tree.selected)
      const selectedNode = this.tree.selected
      if(folderList.includes(folderToBeRemoved)) {
        if (folderToBeRemoved.folders.length) {
          let text = "This folder contains subfolders, which will be removed by this action. Do you still want to proceed?";
          if (confirm(text) == true) {
            const index = folderList.indexOf(folderToBeRemoved)
            folderList.splice(index, 1)
            const structure = {
              id: this.tree.structure.id,
              folders: folderList,
              label: this.tree.structure.label,
            }
            this.$store.commit("DELETE_FOLDER", structure)
            this.$store.commit("SELECT", null)
          }
        }
      } else {
        // if there are sub-folders, warn the user that they will also be deleted.
        if (folderToBeRemoved.folders.length) {
          let text = "This folder contains subfolders, which will be removed by this action. Do you still want to proceed?";
          if (confirm(text) == true) {
            this.commitRemoveFolder(folderList, folderToBeRemoved)
          }
        } else {
          this.commitRemoveFolder(folderList, folderToBeRemoved)
        }
      }
    },
    commitRemoveFolder: function(folderList, folderToBeRemoved) {
      const structure = {
        id: this.tree.structure.id,
        folders: this.removeFolder(folderList, folderToBeRemoved),
        label: this.tree.structure.label,
      }
      this.$store.commit("DELETE_FOLDER", structure)
      this.$store.commit("SELECT", null)
    },
    removeFolder: function (array, folder) {
      for (const item of array) {
        if (item.folders.includes(folder)) {
          const index = item.folders.indexOf(folder)
          item.folders.splice(index, 1)
        }
        if (item.folders?.length) {
          const innerResult = this.removeFolder(item.folders, folder)
        }
      }
      return array
    },
    findSelectedFolderById: function (array, id) {
      for (const item of array) {
        if (item.id === id) return item;
        if (item.folders?.length) {
          const innerResult = this.findSelectedFolderById(item.folders, id);
          if (innerResult) return innerResult;
        }
      }
    },
    getParentByID: function (array, childFolder) {
      for (const item of array) {
        if (item.id === id) return item;
        if (item.folders?.length) {
          const innerResult = this.getParentByID(item.folders, childFolder);
          if (innerResult) return innerResult;
        }
      }
    },
    generateId: function () {
      return Math.floor(Math.random() * 10000000).toString()
    },
    selectAll: function () {
      this.$store.dispatch('select', this.gallery.items)
    },
    selectAlternate: function () {
      let selected = []
      let itemTotal = this.gallery.items.length
      for (let i = 0; i < itemTotal; i = i + 2) {
        selected.push(this.gallery.items[i])
      }
      this.$store.dispatch('select', selected)
    },
    selectInverse: function () {
      let selected = []
      let itemTotal = this.gallery.items.length
      for (let i = 1; i < itemTotal; i = i + 2) {
        selected.push(this.gallery.items[i])
      }
      this.$store.dispatch('select', selected)
    },
    selectNone: function () {
      this.$store.dispatch('select', [])
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
}
</style>
