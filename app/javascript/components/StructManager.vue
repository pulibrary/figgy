<template>
  <div class="lux-structManager">
    <transition name="fade">
      <div
        v-if="saving"
        class="lux-overlay"
      >
        <loader size="medium" />
      </div>
    </transition>
    <alert
      v-if="saved"
      status="success"
      type="alert"
      autoclear
      dismissible
      class="alert"
    >
      Your work has been saved!
    </alert>
    <alert
      v-if="saveError"
      status="error"
      type="alert"
      autoclear
      dismissible
      class="alert"
    >
      Sorry, there was a problem saving your work!
    </alert>
    <toolbar
      @cards-resized="resizeCards($event)"
      @clear-clipboard="clearClipboard"
      @cut-selected="cutSelected"
      @delete-folder="deleteFolder"
      @create-folder="createFolder"
      @group-selected="groupSelectedIntoFolder"
      @paste-items="paste"
      @save-structure="saveHandler"
      @zoom-on-item="zoomOnItem"
    />
    <deep-zoom
      v-if="zoomed"
      viewer-id="viewer"
      class="deep-zoom">
    </deep-zoom>
    <div
      class="lux-sidePanel"
    >
      <div class="panelHeader">
        <heading level="h2" size="h6">Logical Structure</heading>
      </div>
      <tree
        :id="tree.structure.id"
        :json-data="tree.structure"
        @delete-folder="deleteFolder"
        @create-folder="createFolder"
        @zoom-file="zoomFile"
      >
      </tree>
    </div>
    <div
      class="lux-galleryPanel"
      >
      <div class="panelHeader">
        <heading level="h2" size="h6">Unstructured Files</heading>
      </div>
      <struct-gallery
        class="lux-galleryWrapper"
        :card-pixel-width="cardPixelWidth"
        :gallery-items="galleryItems"
        @card-clicked="galleryClicked()"
      />
    </div>
  </div>
</template>

<script>
import { mapState } from 'vuex'
import Toolbar from '@components/StructManagerToolbar.vue'
import Tree from '@components/Tree.vue'
import StructGallery from '@components/StructGallery.vue'
import DeepZoom from '@components/DeepZoom.vue'
import mixin from "./structMixins.js";

/**
 * StructureManager is a tool for giving structure to a complex object (a book, CD, multi-volume work, etc.).
 * Complex patterns like StructureManager come with their own Vuex store that it needs to manage state.
 *
 * However you will still need to load the corresponding
 * Vuex module, *resourceModule*. Please see [the state management documentation](/#!/State%20Management) for how to manage state in complex patterns.
 */
export default {
  name: 'StructManager',
  status: 'ready',
  release: '1.0.0',
  type: 'Pattern',
  mixins: [mixin],
  components: {
    'toolbar': Toolbar,
    'tree': Tree,
    'deep-zoom': DeepZoom,
    'struct-gallery': StructGallery,
  },
  props: {
    /**
     * The resource object in json format.
     */
    resourceObject: {
      type: Object,
      default: null
    },
    /**
     * The structure object in json format.
     */
    structure: {
     type: Object,
     default: null
    },
    /**
     * The resource id. Requires host app to have async lookup of resource.
     */
    resourceId: {
      type: String,
      default: null
    },
    defaultThumbnail: {
      type: String,
      default: 'https://picsum.photos/600/300/?random'
    }
  },
  data: function () {
    return {
      end_nodes: [],
      cardPixelWidth: 150,
      captionPixelPadding: 9,
      ga: null,
      s: null,
      id: this.resourceId,
    }
  },
  computed: {
    galleryItems () {
      return this.resource.members.map(member => ({
        id: member.id,
        caption: member.label,
        service:
          member['thumbnail'] && typeof (member.thumbnail.iiifServiceUrl) !== 'undefined'
            ? member.thumbnail.iiifServiceUrl
            : this.defaultThumbnail,
        mediaUrl:
          member['thumbnail'] && typeof (member.thumbnail.iiifServiceUrl) !== 'undefined'
            ? member.thumbnail.iiifServiceUrl + '/full/300,/0/default.jpg'
            : this.defaultThumbnail,
        viewingHint: member.viewingHint
      }))
    },
    selectedTotal () {
      return this.gallery.selected.length
    },
    selectedTreeNode () {
      return this.tree.selected
    },
    ...mapState({
      resource: state => state.ordermanager.resource,
      tree: state => state.tree,
      gallery: state => state.gallery,
      zoom: state => state.zoom,
    }),
    zoomed: function () {
      return this.zoom.zoomed
    },
    loaded: function () {
      return this.resource.loadState === 'LOADED'
    },
    loading: function () {
      return this.resource.loadState !== 'LOADED'
    },
    saved () {
      return this.tree.saveState === 'SAVED'
    },
    saveError () {
      return this.tree.saveState === 'ERROR'
    },
    saving () {
      return this.tree.saveState === 'SAVING'
    },
  },
  watch: {
    loaded (newVal) {
      this.filterGallery(newVal)
    }
  },
  beforeMount: function () {
    if (this.resourceObject) {
      // if props are passed in set the resource on mount
      this.id = this.resourceObject.id
      this.$store.commit('SET_RESOURCE', this.resourceObject)
      this.$store.commit('CHANGE_RESOURCE_LOAD_STATE', 'LOADED')
    } else {
      let resource = { id: this.id }
      this.$store.commit('CHANGE_RESOURCE_LOAD_STATE', 'LOADING')
      this.$store.dispatch('loadImageCollectionGql', resource)
    }
  },
  methods: {
    addGalleryItems: function() {
      let galleryItems = JSON.parse(JSON.stringify(this.gallery.items)).concat(this.changeKeyToCaption(this.end_nodes))
      this.$store.commit("UPDATE_ITEMS", galleryItems)
      this.end_nodes = []
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
    changeKeyToCaption: function(array) {
      // Iterate through each object in the array
      // and change "label" property (used by tree) to "caption" (used by gallery)
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
    clearClipboard: function () {
      this.$store.commit('CUT', [])
      this.$store.commit("CUT_FOLDER", null)
    },
    commitRemoveFolder: function(folderList, folderToBeRemoved) {
      const structure = {
        id: this.tree.structure.id,
        folders: this.removeNestedObjectById(folderList, folderToBeRemoved.id),
        label: this.tree.structure.label,
      }
      this.$store.commit("DELETE_FOLDER", structure)
      this.$store.commit("SELECT_TREEITEM", null)
      if (this.end_nodes.length) {
        // add any images deleted from the tree back into the gallery
        this.addGalleryItems()
      }
    },
    createFolder: function (parentId) {
      // const parentId = this.tree.selected ? this.tree.selected : this.tree.structure.id
      const rootId = this.tree.structure.id

      const newFolder = {
        id: this.generateId(),
        folders: [],
        label: "Untitled",
        file: false,
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
    cutSelected: function () {
      if (this.gallery.selected.length) {
        // if cards are selected, cut gallery items
        this.$store.commit("CUT", this.gallery.selected)
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
    deleteFolder: function (folder_id) {
      let folderList = JSON.parse(JSON.stringify(this.tree.structure.folders))
      let folderToBeRemoved = this.findFolderById(folderList, folder_id)
      const selectedNode = this.tree.selected
      const rootId = this.tree.structure.id
      if(selectedNode === rootId) {
        alert("Sorry, you cannot delete the top-level folder.")
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
    findAllFilesInStructure: function (array) {
      for (const item of array) {
        if (!!item.file) this.end_nodes.push(item)
        if (item.folders?.length) {
          const innerResult = this.findAllFilesInStructure(item.folders)
          if (innerResult) return innerResult
        }
      }
    },
    filterGallery: function (newVal) {
      if (this.structure.nodes) {
        // If structure prop is provided,
        // convert to tree-friendly structure
        let structureFolders = this.renamePropertiesForLoad(this.structure.nodes)

        // Reconcile unstructured_objects with structured
        // Loop through each galleryItem object and
        // If found, replace the object that has the same id in structure_folders,
        // Then remove it from the galleryItems list and update the state
        // For both the Tree and the Gallery
        let ga = JSON.parse(JSON.stringify(this.galleryItems))

        function replaceObjects() {

          for (let i = 0; i < ga.length; i++) {
            for (let j = 0; j < structureFolders.length; j++) {
              if (replaceObjectRecursively(ga[i], structureFolders[j])) {
                // Remove the object from gallery_items after replacing in structure_folders
                ga.splice(i, 1);
                i--;  // Decrement i to account for the removed item
                break;  // break inner loop if a match is found
              }
            }
          }
        }

        function replaceObjectRecursively(galleryItem, structureFolder) {
          if (galleryItem.id === structureFolder.id) {
            // Change "caption" key to "label" before replacing the object
            galleryItem.label = galleryItem.caption
            delete galleryItem.caption
            delete structureFolder.proxy
            // Replace the object in structure_folders with the galleryItem
            Object.assign(structureFolder, galleryItem);
            return true  // Indicate that a match is found
          } else {
            // Continue searching in nested folders
            for (let i = 0; i < structureFolder.folders.length; i++) {
              if (replaceObjectRecursively(galleryItem, structureFolder.folders[i])) {
                return true  // Stop searching if a match is found in nested folders
              }
            }
          }
          return false;  // No match found in this folder or its nested folders
        }

        // Call the function to replace matching objects
        replaceObjects();

        // setting the newly filtered values as component data properties makes this
        // function much easier to test
        this.ga = ga;
        this.s = {
          id: this.id,
          folders: this.removeProxyProperty(structureFolders),
          label: this.structure.label[0],
        }

        this.$store.commit('SET_STRUCTURE', this.s)
        this.$store.commit('SET_GALLERY', this.ga)
      } else {
        // load empty/default structure
      }
    },
    groupSelectedIntoFolder: function() {
      this.cutSelected()
      this.$nextTick(() => {
        let folderId = this.createFolder(this.tree.structure.id)
        this.$store.commit("SELECT_TREEITEM", folderId)
        this.$nextTick(() => {
          this.pasteGalleryItem()
        })
      })
    },
    paste: function () {
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

        this.$store.commit("ADD_FILES", structure)

        this.$store.commit('PASTE', items)

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
    removeNestedObjectById: function (nestedArray, idToRemove) {
      return nestedArray.map(item => {
          // Check if the current item's id matches the id parameter
          if (item.id === idToRemove) {
              return undefined; // Exclude the current item
          }
          if (item.folders && item.folders.length > 0) {
              // If the current item has folders, recursively call the function
              item.folders = this.removeNestedObjectById(item.folders, idToRemove);
          }

          // Otherwise, keep the item in the result array
          return item;
      }).filter(item => item !== undefined);
    },
    removeProxyProperty: function (arr) {
      // we are not able to recursively remove the proxy property from the figgy structure
      // so we pass the tree structure through this function before storing it
      return arr.map(obj => {
        const newObj = {};
        for (const key in obj) {
          if (key === "proxy") {
            delete obj.proxy
          }
          if (key === "folders") {
            newObj["folders"] = this.removeProxyProperty(obj[key])
          } else {
            newObj[key] = obj[key]
          }
        }
        return newObj
      })
    },
    renamePropertiesForLoad: function (arr) {
      const allowedProperties = ['id', 'label', 'folders', 'proxy', 'file']
      return arr.map(obj => {
        const newObj = {};
        for (const key in obj) {
          if (key === "nodes") {
            if (obj.proxy.length) {
              newObj["id"] = obj.proxy[0].id
              newObj["file"] = true
            } else {
              newObj["id"] = this.generateId()
              newObj["file"] = false
            }
            newObj["label"] = obj.label[0]
            newObj["folders"] = this.renamePropertiesForLoad(obj[key])
          } else {
            if (!allowedProperties.includes(key)) {
              delete obj[key]
            } else {
              newObj[key] = obj[key]
            }
          }
        }
        return newObj
      })
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
    galleryClicked() {
      this.$store.commit('SELECT_TREEITEM', null)
    },
    resizeCards: function (event) {
      this.cardPixelWidth = event.target.value
      if (this.cardPixelWidth < 75) {
        this.captionPixelPadding = 0
      } else {
        this.captionPixelPadding = 9
      }
    },
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
      let structureNodes = this.renamePropertiesForSave(this.tree.structure.folders)
      structureNodes = this.cleanNestedArrayForSave(structureNodes)

      this.resourceToSave = {
        id: this.resource.id,
        resourceClassName: this.resource.resourceClassName,
        structure: {
          label: this.tree.structure.label,
          nodes: structureNodes,
        }
      }

      this.$store.dispatch('saveStructureAJAX', this.resourceToSave)
    },
    selectAllGallery: function () {
      this.$store.commit("SELECT", this.gallery.items)
    },
    selectNoneGallery: function () {
      this.$store.commit("SELECT", [])
    },
    selectNoneTree: function () {
      this.$store.commit("SELECT_TREEITEM", null)
    },
    selectTreeItemById: function (id) {
      this.$store.commit("SELECT_TREEITEM", id)
      this.selectNoneGallery()
    },
    zoomFile: function (file_id) {
      let folderList = JSON.parse(JSON.stringify(this.tree.structure.folders))
      let selected = this.findFolderById(folderList, file_id)
      selected.caption = selected.label
      this.$store.commit("ZOOM", selected)
    },
    zoomOnItem: function() {
      // if a tree item is selected, make sure it is a file and get the obj
      if (this.tree.selected) {
        let folderList = JSON.parse(JSON.stringify(this.tree.structure.folders))
        let nodeToBeZoomed = this.findFolderById(folderList, this.tree.selected)
        let has_service = !!nodeToBeZoomed.service
        if(has_service) {
          nodeToBeZoomed.caption = nodeToBeZoomed.label
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
  }
}
</script>
<style lang="scss" scoped>

.lux-toolbar {
  position: absolute;
  width: 100%;
  top: 0;
}

.lux-alert {
  position: fixed;
  top: 100px;
}

.deep-zoom {
  // position: absolute;
  // z-index: 3; /* put .gold-box above .green-box and .dashed-box */
  max-width: 100%;
  display: flex;
  justify-content: center;
  align-items: center;
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background-color: rgba(0, 0, 0, 0.85);
  background: url(data:;base64,iVBORw0KGgoAAAANSUhEUgAAAAIAAAACCAYAAABytg0kAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAgY0hSTQAAeiYAAICEAAD6AAAAgOgAAHUwAADqYAAAOpgAABdwnLpRPAAAABl0RVh0U29mdHdhcmUAUGFpbnQuTkVUIHYzLjUuNUmK/OAAAAATSURBVBhXY2RgYNgHxGAAYuwDAA78AjwwRoQYAAAAAElFTkSuQmCC)
    repeat scroll transparent\9; /* ie fallback png background image */
  z-index: 9999;
  color: white;
  border-radius: 4px;
  border-color: #ffffff;
}

.lux-resourceTitle {
  background-color: grey;
  margin-bottom: 10em;
}

.lux-label {
  font-weight: bold;
}
.lux-structManager {
  position: relative;
  height: 80vh;
}
.lux-structManager .lux-heading {
  margin: 12px 0 12px 0;
  line-height: 0.75;
  color: #001123;
}
.lux-structManager h2 {
  letter-spacing: 0;
  font-size: 24px;
}
.lux-sidePanel {
  position: absolute;
  top: 70px;
  left: 0px;
  height: 85%;
  width: 28.5%;
  border: 1px solid #ddd;
  border-radius: 4px;

  padding: 0 5px 0 5px;
  // height: 100%;
  overflow-y: scroll;
}
.lux-sidePanel .lux-input {
  display: block;
}
.lux-galleryPanel {
  position: absolute;
  top: 70px;
  left: 30%;
  height: 85%;
  width: 70%;
  border-radius: 4px;
  border: 1px solid #ddd;
}
.lux-icon {
  margin: auto;
}
.lux-galleryWrapper {
  overflow: auto;
  height: calc(100% - 80px);
  border-radius: 4px;
  margin-bottom: 80px;
  clear: both;
}

.loader {
  position: absolute;
  width: 100%;
  height: 100%;
  text-align: center;
  padding-bottom: 64px;
  z-index: 500;
  margin-top: -16px;
}
.loader .galleryLoader {
  width: 100%;
  height: 100%;
  background-color: rgba(0,0,0,0.85);
  display: flex;
}
.loader .galleryLoader .lux-loader {
  margin: auto;
}
.panelHeader {
  background-color: #e1f1fd;
  border-radius: 4px;
  padding: .5em .5em .5em 1em;
  margin: .5em;

  h2 {
    font-size: 12px;
    color: #333;
  }
}

.lux-overlay {
  display: flex;
  justify-content: center;
  align-items: center;
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background-color: rgba(0, 0, 0, 0.60);
  background: url(data:;base64,iVBORw0KGgoAAAANSUhEUgAAAAIAAAACCAYAAABytg0kAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAgY0hSTQAAeiYAAICEAAD6AAAAgOgAAHUwAADqYAAAOpgAABdwnLpRPAAAABl0RVh0U29mdHdhcmUAUGFpbnQuTkVUIHYzLjUuNUmK/OAAAAATSURBVBhXY2RgYNgHxGAAYuwDAA78AjwwRoQYAAAAAElFTkSuQmCC)
    repeat scroll transparent\6; /* ie fallback png background image */
  z-index: 9999;
  color: white;
  border-radius: 4px;

  // $border-color: var(--color-white);
  border-color: rgb(231, 117, 0);
}
</style>
