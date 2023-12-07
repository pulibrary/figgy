<template>
  <li>
    <div class="container">
      <div class="lux-item" v-if="!isFile">
        <input-button
          @button-clicked="toggleFolder($event)"
          class="expand-collapse"
          type="button"
          variation="icon"
          size="small"
          :icon="expandCollapseIcon"
          block
        >
        </input-button>
      </div>
      <div
        class="folder-container"
        @click.capture="select(jsonData.id, $event)"
        :class="[
          'lux-item-label',
          { selected: isSelected },
          { leafnode: !hasChildren },
          { branchnode: hasChildren },
          { disabled: isDisabled },
        ]"
      >
        <lux-icon-base
          v-if="isFile && !thumbnail"
          width="30"
          height="30"
          icon-name="End Node"
          icon-color="gray"
        >
          <lux-icon-end-node></lux-icon-end-node>
        </lux-icon-base>
        <media-image
          v-if="thumbnail"
          :alt="jsonData.label"
          :src="thumbnail" height="30px"
          style="margin-top: .5em;margin-right: .5em;"></media-image>
        <template v-if="editedFieldId === id">
          <div class="folder-label">
            <input
              type="text"
              v-on:keyup.enter="saveLabel(id)"
              v-model="jsonData.label"
              :ref="`field${id}`" />
          </div>
          <div class="folder-edit">
            <input-button
              @button-clicked="saveLabel(id)"
              class="expand-collapse"
              type="button"
              variation="icon"
              size="small"
              icon="approved"
            >
            </input-button>
          </div>
        </template>
        <template v-else>
          <div class="folder-label">
            {{ this.jsonData.label }}
          </div>
          <div class="folder-edit">
            <input-button
              @button-clicked="toggleEdit(id)"
              class="expand-collapse"
              type="button"
              variation="icon"
              size="small"
              icon="edit"
            >
            </input-button>

            <input-button v-if="!isFile"
              @button-clicked="createFolder(id)"
              class="expand-collapse"
              type="button"
              variation="icon"
              size="small"
              icon="add"
            >
            </input-button>
            <input-button v-else
              @button-clicked="viewFile(id)"
              class="expand-collapse"
              type="button"
              variation="icon"
              size="small"
              icon="search"
            >
            </input-button>
            <input-button
              @button-clicked="deleteFolder()"
              class="expand-collapse"
              type="button"
              variation="icon"
              size="small"
              icon="denied"
            >
            </input-button>
          </div>
        </template>
      </div>
    </div>
    <ul v-show="isOpen && hasChildren">
      <tree-item
        v-for="(folder, index) in this.jsonData.folders"
        :json-data="folder"
        :id="folder.id"
      ></tree-item>
    </ul>
  </li>
</template>

<script>
import store from "../store"
import { mapState, mapGetters } from "vuex"
import IconEndNode from './IconEndNode'
/**
 * TreeItems are the building blocks of hierarchical navigation.
 */
export default {
  name: "TreeItem",
  status: "prototype",
  release: "1.0.0",
  type: "Element",
  components: {
    'lux-icon-end-node': IconEndNode,
  },
  props: {
    /**
     * id identifies the node in the tree.
     */
    id: {
      default: "",
    },
    jsonData: {
      default: [],
      required: true,
    },
  },
  data: function() {
    return {
      // hasChildren: this.jsonData.folders.length > 0,
      isOpen: true,
      editedFieldId: null,
      isFile: !!this.jsonData.file,
      end_nodes: [],
      // cutItemIDs_array is temporary storage bin for all ids in a given folder
      // which is used for displaying cut items
      cutItemIDs_array: [],
    }
  },
  computed: {
    thumbnail: function() {
      let has_service = !!this.jsonData.service
      if (has_service) {
        return this.jsonData.service + '/full/30,/0/default.jpg'
      } else {
        return false
      }
    },
    expandCollapseIcon: function() {
      if (this.isOpen) {
        return "arrow-down"
      }
      return "arrow-right"
    },
    hasChildren: function() {
      return this.jsonData.folders.length > 0
    },
    isSelected: function() {
      if (this.tree.selected === this.id) {
        return true
      }
      return false
    },
    isDisabled: function() {
      if (this.tree.cut) {
        let folderList = JSON.parse(JSON.stringify(this.tree.structure.folders))
        let cutTreeStructure = this.findSelectedFolderById(folderList, this.tree.cut)
        let disabledTreeItems = this.extractIdsInStructure(cutTreeStructure)
        // return true if id matches any of the ids in cutItemIDs_array
        return disabledTreeItems.includes(this.id);
      }
      return false
    },
    ...mapState({
      tree: state => store.state.tree,
      gallery: state => store.state.gallery,
      zoom: state => store.state.zoom,
    }),
  },
  methods: {
    extractIdsInStructure: function(structure) {
      const result = []

      function traverse(node) {
        if (node && node.id) {
          result.push(node.id)
        }

        if (node && node.folders && node.folders.length > 0) {
          for (const folder of node.folders) {
            traverse(folder)
          }
        }
      }

      traverse(structure)
      return result
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
    createFolder: function(id) {
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
      }
      if(parentId === rootId) {
        folderList.push(newFolder)
        structure.folders = folderList
      } else {
        let parentFolderObject = this.findSelectedFolderById(folderList, parentId)
        let newParent = parentFolderObject.folders.push(newFolder)
        structure.folders = this.addNewFolder(folderList, newParent)
      }
      this.$store.commit("CREATE_FOLDER", structure)
    },
    findSelectedFolderById: function (array, id) {
      for (const item of array) {
        if (item.id === id) return item;
        if (item.folders?.length) {
          const innerResult = this.findSelectedFolderById(item.folders, id);
          if (innerResult) return innerResult;
        }
      }

      return null; // Return null if the ID is not found in the array
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
    addGalleryItems: function() {
      let galleryItems = JSON.parse(JSON.stringify(this.gallery.items)).concat(this.end_nodes)
      this.$store.commit("UPDATE_ITEMS", galleryItems)
      this.end_nodes = []
    },
    commitRemoveFolder: function(folderList, folderToBeRemoved) {
      let folders = []
      if(folderList[0] !== folderToBeRemoved){
        folders = this.removeFolder(folderList, folderToBeRemoved)
      }
      const structure = {
        id: this.tree.structure.id,
        folders: folders,
        label: this.tree.structure.label,
      }
      this.$store.commit("DELETE_FOLDER", structure)
      this.$store.commit("SELECT_TREEITEM", null)
      if (this.end_nodes.length) {
        // add any images deleted from the tree back into the gallery
        this.addGalleryItems()
      }
    },
    removeFolder: function (array, folderToBeRemoved) {
      for (const item of array) {
        if (item.folders.includes(folderToBeRemoved)) {
          const index = item.folders.indexOf(folderToBeRemoved)
          item.folders.splice(index, 1)
        }
        if (item.folders?.length) {
          const innerResult = this.removeFolder(item.folders, folderToBeRemoved)
        }
      }
      return array
    },
    generateId: function () {
      return Math.floor(Math.random() * 10000000).toString()
    },
    select: function(id, event) {
      if (!this.isOpen) {
        this.isOpen = !this.isOpen
      }
      let folderList = JSON.parse(JSON.stringify(this.tree.structure.folders))
      let selected = this.findSelectedFolderById(folderList, id)
      store.commit("SELECT_TREEITEM", id)
      // tree and gallery items cannot be selected simultaneously, so deselect the gallery
      store.commit("SELECT", [])
    },
    saveLabel: function(id) {
      const parentId = this.tree.selected ? this.tree.selected : this.tree.structure.id;
      // need to stringify and parse to drop the observer that comes with Vue reactive data
      const folderList = JSON.parse(JSON.stringify(this.tree.structure.folders))

      let structure = {
        id: this.tree.structure.id,
        folders: folderList,
        label: this.jsonData.label,
      }

      if (id !== this.tree.structure.id) {
        let selectedFolder = this.findSelectedFolderById(folderList, parentId)
        structure = {
          id: this.tree.structure.id,
          folders: this.updateFolderLabel(folderList, selectedFolder),
          label: this.tree.structure.label,
        }
      }

      store.commit("SAVE_LABEL", structure)
      this.editedFieldId = null;
    },
    updateFolderLabel: function (array, selectedFolder) {
      for (let item of array) {
        if (item.id === selectedFolder.id) {
          item.label = this.jsonData.label
        } else if (item.folders?.length) {
          const innerResult = this.updateFolderLabel(item.folders, selectedFolder)
        }
      }
      return array
    },
    toggleFolder: function() {
      this.isOpen = !this.isOpen
    },
    toggleEdit: function(id) {
      if (id) {
        this.editedFieldId = id;
        this.$nextTick(() => {
          if (this.$refs["field" + id]) {
            this.$refs["field" + id].focus();
          }
        });
      } else {
        this.editedFieldId = null;
      }
    },
    viewFile: function (id) {
      let folderList = JSON.parse(JSON.stringify(this.tree.structure.folders))
      let selected = this.findSelectedFolderById(folderList, id)
      this.$store.commit("ZOOM", selected)
    },
  },
}
</script>

<style lang="scss" scoped>
ul.lux-tree li {
  list-style-type: none;
  font-family: sans-serif;
  margin: 0px;
  line-height: 25px;
  font-size: 12px;
}

ul.lux-tree li div.lux-item-label {
  background: rgb(186, 175, 130);
  width: 100%;
  padding: 0.5em 0.5em .5em 1em;
}

ul.lux-tree li div.lux-item-label.selected {
  background: rgb(210, 202, 173);
}

ul.lux-tree li div.lux-item-label.disabled {
  opacity: 0.2;
  cursor: not-allowed;
}

ul.lux-tree .container {
  display: flex;
  margin: 4px;
}

ul.lux-tree .lux-item {
  flex: 1 auto;
  margin-right: 4px;
}

.lux-tree .lux-item .lux-button {
  // position: absolute;
  // top: -2px;
  // left: -7px;
  background: rgb(186, 175, 130);
  width: 36px;
  height: 36px;
  border-radius: 0;
  margin: 0;
}

ul.lux-tree .lux-item-label {
  flex-grow: 1; /* Set the middle element to grow and stretch */
  min-height: 36px;
}

.lux-tree .lux-item-label .lux-icon {
  align-self: start;
  height: 16px;
}

.expand-collapse {
  background: transparent;
}

.leafnode {
  display: flex;
  align-items: center;
  margin-left: 0px;
  hyphens: auto;
  padding-left: 2em;
}

.branchnode {
  hyphens: auto;
  padding-left: 1em;
}

.lux-expanded {
  width: initial;
}
.lux-tree .lux-button.icon.small {
  padding: 4px;
}

.folder-container {
  display: flex;
}

.folder-new,
.folder-edit,
.folder-delete {
  display: inline-block;
}

.folder-label {
  flex: 1;
}

.folder-label input[type=text]  {
  background: transparent;
  border: none;
  width: 80%;
  line-height: 22px;
}

.folder-edit .lux-button.icon.small {
  padding: 0px;
  margin: 0px;
}

</style>
