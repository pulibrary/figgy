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
        {name: 'Delete Folder', component: 'FolderDelete', disabled: this.rootNodeSelected},
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
      Save Structure
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
    renamePropertiesForSave: function (arr) {
      return arr.map(obj => {
        const newObj = {};
        for (const key in obj) {
          if (key === "folders") {
            if (obj.file === true) {
              newObj["proxy"] = obj.id;
            }
            newObj["nodes"] = this.renamePropertiesForSave(obj[key]);
          } else {
            newObj[key] = obj[key];
          }
        }
        return newObj;
      });
    },
    cleanNestedArrayForSave: function (arr) {
      return arr.map(obj => {
        let cleanedObj = {}
        if (obj.proxy !== undefined) {
          cleanedObj.proxy = obj.proxy
        } else {
          cleanedObj.nodes = this.cleanNestedArrayForSave(obj.nodes)
          cleanedObj.label = obj.label
        }

        return cleanedObj;
      });
    },
    saveHandler: function (event) {
      console.log(this.isSaveDisabled())
      if(this.isSaveDisabled()) {
        // workaround for a bug in LUX that doesn't style disabled buttons properly
        alert('The structure has not changed, nothing to save.')
      } else {
        let structureNodes = this.renamePropertiesForSave(this.tree.structure.folders)
        console.log('renamePropertiesForSave Output: ' + JSON.stringify(structureNodes))
        structureNodes = this.cleanNestedArrayForSave(structureNodes)
        console.log('cleanNestedArrayForSave Output: ' + JSON.stringify(structureNodes))

        let resourceToSave = {
          id: this.resource.id,
          resourceClassName: this.resource.resourceClassName,
          structure: {
            label: this.tree.structure.label,
            nodes: structureNodes,
          }
        }
        this.$store.dispatch('saveStructureAJAX', resourceToSave)
      }
    },
    cutSelected: function () {
      if (this.gallery.selected.length) {
        // if cards are selected, cut gallery items
        this.$store.dispatch('cut', this.gallery.selected)
        this.selectNoneGallery()
      } else if (this.tree.selected) {
        // if folder is selected, cut tree items
        if(this.rootNodeSelected) {
          alert('Sorry, you can\'t cut the root node.')
        } else {
          this.$store.commit("CUT_FOLDER", this.tree.selected)
          this.selectNoneTree()
        }
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
      } else if (this.tree.selected) {
        let nodeToBeZoomed = this.findFolderById(this.tree.structure.folders, this.tree.selected)
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
        this.$store.commit("SET_MODIFIED", true)
        this.clearClipboard()
        this.selectNoneGallery()
      }
    },
    pasteTreeItem: function() {
      const parentId = this.tree.selected ? this.tree.selected : this.tree.structure.id
      const rootId = this.tree.structure.id
      let folderList = JSON.parse(JSON.stringify(this.tree.structure.folders))
      let cutTreeStructure = this.findFolderById(folderList, this.tree.cut)

      let structure = {
        id: this.tree.structure.id,
        label: this.tree.structure.label,
      }

      // remove the folder if it currently exists
      let selectedFolderObject = this.findFolderById(folderList, this.tree.selected)
      let folders = this.removeNestedObjectById(folderList, cutTreeStructure.id)

      if(this.tree.selected === rootId) {
        folders.push(cutTreeStructure)
        structure.folders = folders
      } else {
        selectedFolderObject.folders.push(cutTreeStructure)
        structure.folders = this.replaceObjectById(folders, this.tree.selected, selectedFolderObject);
      }

      this.$store.commit("SET_STRUCTURE", structure)
      this.$store.commit("SET_MODIFIED", true)
      this.selectNoneTree()
      this.clearClipboard()
    },
    replaceObjectById: function(root, idToReplace, replacementObject) {
      if (root.id === idToReplace) {
          return replacementObject;
      }

      if (root.folders && root.folders.length > 0) {
          root.folders = root.folders.map(folder =>
              this.replaceObjectById(folder, idToReplace, replacementObject)
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
          this.createFolder()
          break
        case 'Group Selected into New Folder (Ctrl-g)':
          this.groupSelectedIntoFolder()
          break
        case 'Delete Folder':
          this.deleteFolder(this.tree.selected)
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
    createFolder: function () {
      const parentId = this.tree.selected ? this.tree.selected : this.tree.structure.id
      const rootId = this.tree.structure.id

      const newFolder = {
        id: this.generateId(),
        folders: [],
        label: "Untitled",
      }
      // need to stringify and parse to drop the observer that comes with Vue reactive data
      let folderList = JSON.parse(JSON.stringify(this.tree.structure.folders))
      let structure = {
        id: this.tree.structure.id,
        label: this.tree.structure.label,
        folders: folderList
      }
      if(parentId === rootId) {
        structure.folders.push(newFolder)
      } else {
        let parentFolderObject = this.findFolderById(folderList, parentId)
        if(parentFolderObject.file) {
          alert("Oops, looks like you tried to add a folder to a file. You can only add a new folder to another folder.")
          return false
        } else {
          let newParent = parentFolderObject.folders.push(newFolder)
          structure.folders = this.addNewNode(folderList, newParent)
        }
      }
      this.$store.commit("CREATE_FOLDER", structure)
      return newFolder.id
    },
    groupSelectedIntoFolder: function() {
      this.cutSelected()
      this.$nextTick(() => {
        let folderId = this.createFolder()
        this.$store.commit("SELECT_TREEITEM", folderId)
        this.$nextTick(() => {
          this.pasteGalleryItem()
        })
      })
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
    deleteFolder: function (folder_id) {
      let folderList = JSON.parse(JSON.stringify(this.tree.structure.folders))
      let folderToBeRemoved = this.findFolderById(folderList, folder_id)
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
      console.log('folderList: ' + JSON.stringify(folderList))
      console.log('folderToBeRemovedID: ' + folderToBeRemoved.id)
      const structure = {
        id: this.tree.structure.id,
        folders: this.removeNestedObjectById(folderList, folderToBeRemoved.id),
        label: this.tree.structure.label,
      }
      this.$store.commit("DELETE_FOLDER", structure)
      this.$store.commit("SELECT", null)
      if (this.end_nodes.length) {
        // add any images deleted from the tree back into the gallery
        this.addGalleryItems()
      }
    },
    changeKeyToCaption: function(array) {
      // Iterate through each object in the array
      for (let i = 0; i < array.length; i++) {
        // Check if the object has a "label" key
        if (array[i].hasOwnProperty('label')) {
          // Create a new key "caption" with the value of the current "label" key
          array[i].caption = array[i].label;
          // Remove the old "label" key
          delete array[i].label;
        }
      }

      return array;
    },
    addGalleryItems: function() {
      let galleryItems = JSON.parse(JSON.stringify(this.gallery.items)).concat(this.changeKeyToCaption(this.end_nodes))
      this.$store.commit("UPDATE_ITEMS", galleryItems)
      this.end_nodes = []
    },
    removeObjectFromArray: function (array, targetObject) {
        // Base case: If the array is empty, or the target object is not found, return the array as it is
        if (array.length === 0) {
            return array;
        }

        // Check if the current element is equal to the target object
        if (this.isEqual(array[0], targetObject)) {
            // If found, remove the current element and return the rest of the array
            return array.slice(1);
        } else {
            // If not found, recursively call the function on the rest of the array
            return [array[0], ...this.removeObjectFromArray(array[0].folders || [], targetObject)];
        }
    },
    // Helper function to check if two objects are equal
    isEqual: function (obj1, obj2) {
        return JSON.stringify(obj1) === JSON.stringify(obj2);
    },
    removeNestedObjectById: function (nestedArray, idToRemove) {
      return nestedArray.map(item => {
          if (item.folders && item.folders.length > 0) {
              // If the current item has folders, recursively call the function
              item.folders = this.removeNestedObjectById(item.folders, idToRemove);
          }

          // Check if the current item's id matches the id parameter
          if (item.id === idToRemove) {
              return undefined; // Exclude the current item
          }

          // Otherwise, keep the item in the result array
          return item;
      }).filter(item => item !== undefined);
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
          const innerResult = this.findAllFilesInStructure(item.folders)
          if (innerResult) return innerResult
        }
      }
    },
    // getParentByID: function (array, childFolder) {
    //   for (const item of array) {
    //     if (item.id === id) return item;
    //     if (item.folders?.length) {
    //       const innerResult = this.getParentByID(item.folders, childFolder)
    //       if (innerResult) return innerResult
    //     }
    //   }
    // },
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
    selectTreeItemById: function (id) {
      this.$store.commit("SELECT_TREEITEM", id)
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
          if (e.key === "g" && (e.ctrlKey || e.metaKey)) {
              e.preventDefault();
              this.groupSelectedIntoFolder()
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
