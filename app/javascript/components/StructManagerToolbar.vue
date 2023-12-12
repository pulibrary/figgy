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
        {name: 'Delete Folder', component: 'FolderDelete', disabled: this.rootNodeSelected},
        {name: 'Cut', component: 'Cut', disabled: isCutDisabled()},
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
  data: function() {
    return {
      end_nodes: [],
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
    },
    rootNodeSelected: function() {
      return this.tree.selected === this.tree.structure.id
    },
  },
  methods: {
    cutSelected: function () {
      // if folder is selected, cut folder
      // if cards are selected, cut gallery items
      if (this.gallery.selected.length) {
        this.$store.dispatch('cut', this.gallery.selected)
        this.selectNoneGallery()
      } else if (this.tree.selected) {
        this.$store.commit("CUT_FOLDER", this.tree.selected)
        this.selectNoneTree()
      }

    },
    getItemIndexById: function (id) {
      return this.gallery.items
        .map(function (item) {
          return item.id
        })
        .indexOf(id)
    },
    isCutDisabled: function () {
      return !!this.gallery.cut.length && !!this.tree.cut
    },
    isPasteDisabled: function () {
      return !(this.gallery.cut.length && this.tree.selected) || (this.tree.cut && this.tree.selected)
    },
    paste: function (indexModifier) {
      // figure out what is currently on the clipboard, a gallery item or a tree item
      if (!this.tree.selected) {
        alert('You must select a tree item to paste into.')
        console.log("Nothing is in the clipboard.")
        return false
      } else {
        const parentId = this.tree.selected ? this.tree.selected : this.tree.structure.id
        const rootId = this.tree.structure.id

        if (this.gallery.cut.length) {
          console.log("Gallery items are in the clipboard.")
          let items = this.gallery.items
          items = items.filter(val => !this.gallery.cut.includes(val))
          // Find the selected folder in the tree structure
          let resources = JSON.parse(JSON.stringify(this.gallery.cut))

          // we will need to loop this to convert multiple cut gallery items into tree items
          let newItems = resources.map((resource, index) => {
            resource.label = resource.caption
            resource.file = true
            resource.folders = []
            return resource
          });

          // need to stringify and parse to drop the observer that comes with Vue reactive data
          let folderList = JSON.parse(JSON.stringify(this.tree.structure.folders))
          let structure = {
            id: this.tree.structure.id,
            label: this.tree.structure.label,
          }

          if(parentId === rootId) {
            alert('Sorry, you can\'t do that. You must paste a resource into a sub-folder.')
          } else {
            let parentFolderObject = this.findSelectedFolderById(folderList, parentId)
            let parentFolders = parentFolderObject.folders.concat(newItems)
            parentFolderObject.folders = parentFolders
            structure.folders = this.addNewNode(folderList, parentFolderObject)

            this.$store.commit("ADD_RESOURCE", structure)

            this.$store.dispatch('paste', items)
            this.clearClipboard()
            this.selectNoneGallery()
          }
        } else if (this.tree.cut) {
          console.log("Tree items are in the clipboard.")
          // Get the tree structure
          let folderList = JSON.parse(JSON.stringify(this.tree.structure.folders))
          // Get the structure of the cut item(s)
          let cutTreeStructure = this.findSelectedFolderById(folderList, this.tree.cut)
          // Remove the cut structure from the folderList
          let folders = []
          if(folderList[0] !== cutTreeStructure){
            folders = this.removeFolder(folderList, cutTreeStructure)
          } else {
            alert('You cannot cut the root node.')
            return false
          }
          // get selected tree item
          // Paste cut structure into the selected tree item (prevent pasting into its children)
          // New structure
          let structure = {
            id: this.tree.structure.id,
            label: this.tree.structure.label,
          }
          if(this.tree.selected === rootId) {
            folders.push(cutTreeStructure)
            structure.folders = folders
          } else {
            let selectedFolderObject = this.findSelectedFolderById(folders, this.tree.selected)
            selectedFolderObject.folders.push(cutTreeStructure)
            structure.folders = this.replaceObjectById(folders, this.tree.selected, selectedFolderObject);
          }
          this.$store.commit("SET_STRUCTURE", structure)
          this.SelectNoneTree()
          this.clearClipboard()
        }
      }
    },
    replaceObjectById: function(root, idToReplace, replacementObject) {
      if (root.id === idToReplace) {
          // If the root object has the matching id, replace it
          return replacementObject;
      }

      // Iterate through folders and recursively search for the object to replace
      if (root.folders && root.folders.length > 0) {
          root.folders = root.folders.map(folder =>
              replaceObjectById(folder, idToReplace, replacementObject)
          );
      }

      return root;
    },
    clearClipboard: function () {
      if (this.gallery.cut.length) {
        this.$store.dispatch('cut', [])
      } else if (this.tree.cut) {
        this.$store.commit("CUT_FOLDER", null)
      } else {
        console.log('nothing is on the clipboard')
      }
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
        case 'Paste':
          this.paste(-1)
          break
      }
    },
    createFolder: function (contentsList) {
      const parentId = this.tree.selected ? this.tree.selected : this.tree.structure.id
      const rootId = this.tree.structure.id

      const newFolder = {
        id: this.generateId(),
        folders: contentsList,
        label: "Untitled",
      }
      // need to stringify and parse to drop the observer that comes with Vue reactive data
      let folderList = JSON.parse(JSON.stringify(this.tree.structure.folders))
      let structure = {
        id: this.tree.structure.id,
        label: this.tree.structure.label,
      }
      if(parentId === rootId) {
        folderList.push(newFolder)
        structure.folders = folderList
      } else {
        let parentFolderObject = this.findSelectedFolderById(folderList, parentId)
        let newParent = parentFolderObject.folders.push(newFolder)
        structure.folders = this.addNewNode(folderList, newParent)
      }
      this.$store.commit("CREATE_FOLDER", structure)
    },
    addNewNode: function (array, newParent) {
      for (let item of array) {
        if (item.id === newParent.id) {
          item = newParent
        } else if (item.folders?.length) {
          const innerResult = this.addNewNode(item.folders, newParent)
        }
      }
      return array
    },
    deleteFolder: function () {
      let folderList = JSON.parse(JSON.stringify(this.tree.structure.folders))
      let folderToBeRemoved = this.findSelectedFolderById(folderList, this.tree.selected)
      const selectedNode = this.tree.selected
      const rootId = this.tree.structure.id
      if(selectedNode === rootId) {
        alert("Sorry, you cannot delete the root node.")
        return false
      }
      // if there are sub-folders, warn the user that they will also be deleted.
      if (folderToBeRemoved.folders.length) {
        this.findAllFilesInStructure(folderToBeRemoved.folders)
        let text = "This folder contains subfolders, which will be removed by this action. Do you still want to proceed?";
        if (confirm(text) == true) {
          this.commitRemoveFolder(folderList, folderToBeRemoved)
        }
      } else {
        this.findAllFilesInStructure([folderToBeRemoved])
        this.commitRemoveFolder(folderList, folderToBeRemoved)
      }
    },
    commitRemoveFolder: function(folderList, folderToBeRemoved) {
      let folders = []
      if(folderList[0] !== folderToBeRemoved){
        folders = this.removeFolder(folderList, folderToBeRemoved)
      }
      const structure = {
        id: this.tree.structure.id,
        folders: this.removeFolder(folderList, folderToBeRemoved),
        label: this.tree.structure.label,
      }
      this.$store.commit("DELETE_FOLDER", structure)
      this.$store.commit("SELECT", null)
      if (this.end_nodes.length) {
        // add any images deleted from the tree back into the gallery
        this.addGalleryItems()
      }
    },
    addGalleryItems: function() {
      let galleryItems = JSON.parse(JSON.stringify(this.gallery.items)).concat(this.end_nodes)
      this.$store.commit("UPDATE_ITEMS", galleryItems)
      this.end_nodes = []
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
    findAllFilesInStructure: function (array) {
      for (const item of array) {
        if (item.file) this.end_nodes.push(item)
        if (item.folders?.length) {
          const innerResult = this.findAllFilesInStructure(item.folders);
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
    selectNoneGallery: function () {
      this.$store.dispatch('select', [])
    },
    selectNoneTree: function () {
      this.$store.commit("SELECT_TREEITEM", null)
    }
  },
  mounted: function () {
      this._keyListener = function(e) {
          if (e.key === "x" && (e.ctrlKey || e.metaKey)) {
              e.preventDefault();

              this.cutSelected()
          }
          if (e.key === "v" && (e.ctrlKey || e.metaKey)) {
              e.preventDefault();

              this.paste(-1)
          }
      };

      document.addEventListener('keydown', this._keyListener.bind(this));
  },
  beforeDestroy: function () {
      document.removeEventListener('keydown', this._keyListener);
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
