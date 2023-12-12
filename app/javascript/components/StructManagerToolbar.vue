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
        {name: 'Delete Folder', component: 'FolderDelete', disabled: this.rootNodeSelected},
        {name: 'Undo Cut (Ctrl-z)', component: 'UndoCut', disabled: !isCutDisabled()},
        {name: 'Cut (Ctrl-x)', component: 'Cut', disabled: isCutDisabled()},
        {name: 'Paste (Ctrl-v)', component: 'Paste', disabled: isPasteDisabled()},
        {name: 'Zoom on Selected (Ctrl-o)', component: 'Zoom', disabled: isZoomDisabled()}
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
      gallery: state => state.gallery,
      zoom: state => store.state.zoom,
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
      return !!this.gallery.cut.length || !!this.tree.cut
    },
    isPasteDisabled: function () {
      return !(this.gallery.cut.length || this.tree.cut)
    },
    isZoomDisabled: function () {
      if (this.gallery.selected.length === 1) {
        return false
      } else if (this.tree.selected) {
        let nodeToBeZoomed = this.findFolderById(folderList, this.tree.selected)
        let has_service = !!nodeToBeZoomed.service
        if (has_service) {
          return false
        }
      }
      return true
    },
    paste: function (indexModifier) {
      // figure out what is currently on the clipboard, a gallery item or a tree item
      if (!this.tree.selected) {
        alert('You must select a tree item to paste into.')
        return false
      } else {
        if (this.gallery.cut.length) {
          this.pasteGalleryItem()
        } else if (this.tree.cut) {
          this.pasteTreeItem()
        }
      }
    },
    pasteGalleryItem: function() {
      const parentId = this.tree.selected ? this.tree.selected : this.tree.structure.id
      const rootId = this.tree.structure.id
      let items = this.gallery.items
      items = items.filter(val => !this.gallery.cut.includes(val))
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
        let parentFolderObject = this.findFolderById(folderList, parentId)
        let parentFolders = parentFolderObject.folders.concat(newItems)
        parentFolderObject.folders = parentFolders
        structure.folders = this.addNewNode(folderList, parentFolderObject)

        this.$store.commit("ADD_RESOURCE", structure)

        this.$store.dispatch('paste', items)
        this.clearClipboard()
        this.selectNoneGallery()
      }
    },
    pasteTreeItem: function() {
      const parentId = this.tree.selected ? this.tree.selected : this.tree.structure.id
      const rootId = this.tree.structure.id
      let folderList = JSON.parse(JSON.stringify(this.tree.structure.folders))
      let cutTreeStructure = this.findFolderById(folderList, this.tree.cut)

      let folders = []
      if(folderList[0] !== cutTreeStructure){
        folders = this.removeFolder(folderList, cutTreeStructure)
      } else {
        alert('You cannot cut the root node.')
        return false
      }

      let structure = {
        id: this.tree.structure.id,
        label: this.tree.structure.label,
      }

      if(this.tree.selected === rootId) {
        folders.push(cutTreeStructure)
        structure.folders = folders
      } else {
        let selectedFolderObject = this.findFolderById(folders, this.tree.selected)
        selectedFolderObject.folders.push(cutTreeStructure)
        structure.folders = this.replaceObjectById(folders, this.tree.selected, selectedFolderObject);
      }
      this.$store.commit("SET_STRUCTURE", structure)
      this.selectNoneTree()
      this.clearClipboard()
    },
    replaceObjectById: function(root, idToReplace, replacementObject) {
      if (root.id === idToReplace) {
          return replacementObject;
      }

      if (root.folders && root.folders.length > 0) {
          root.folders = root.folders.map(folder =>
              replaceObjectById(folder, idToReplace, replacementObject)
          );
      }

      return root;
    },
    clearClipboard: function () {
      this.$store.dispatch('cut', [])
      this.$store.commit("CUT_FOLDER", null)
    },
    resizeCards: function (event) {
      this.$emit('cards-resized', event)
    },
    menuSelection (value) {
      switch (value.target.innerText) {
        case 'Create New Folder (Ctrl-n)':
          this.createFolder([])
          break
        case 'Delete Folder':
          this.deleteFolder(value.target)
          break
        case 'Undo Cut (Ctrl-z)':
          this.clearClipboard()
          break
        case 'Cut (Ctrl-x)':
          this.cutSelected()
          break
        case 'Paste (Ctrl-v)':
          this.paste(-1)
          break
        case 'Zoom on Selected (Ctrl-o)':
          this.zoomOnItem()
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
        let parentFolderObject = this.findFolderById(folderList, parentId)
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
      let folderToBeRemoved = this.findFolderById(folderList, this.tree.selected)
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
    findFolderById: function (array, id) {
      for (const item of array) {
        if (item.id === id) return item;
        if (item.folders?.length) {
          const innerResult = this.findFolderById(item.folders, id);
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
    },
    zoomOnItem: function() {
      // if a tree item is selected, make sure it is a file and get the obj
      if (this.tree.selected) {
        let folderList = JSON.parse(JSON.stringify(this.tree.structure.folders))
        let nodeToBeZoomed = this.findFolderById(folderList, this.tree.selected)
        let has_service = !!nodeToBeZoomed.service
        if(has_service) {
          this.$store.commit("ZOOM", nodeToBeZoomed)
        } else {
          alert('You may have tried to zoom on a folder. You can only zoom on files that have a service.')
        }
      } else if (this.gallery.selected.length){
        if (this.gallery.selected.length > 1) {
          alert('Please select only one item to zoom in on.')
        } else {
          this.$store.commit("ZOOM", this.gallery.selected[0])
        }
      } else {
        alert('You need to select an item to zoom in on it.')
      }
    },
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
          if (e.key === "z" && (e.ctrlKey || e.metaKey)) {
              e.preventDefault();

              this.clearClipboard()
          }
          if (e.key === "n" && (e.ctrlKey || e.metaKey)) {
              e.preventDefault();

              this.createFolder([])
          }
          if (e.key === "o" && (e.ctrlKey || e.metaKey)) {
              e.preventDefault();

              this.zoomOnItem()
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
  text-align: left;
  width: 14em;
}
</style>
