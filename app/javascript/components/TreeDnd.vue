<template>
  <VueDraggable 
    v-if="showing"
    handle=".handle"
    class="drag-area"
    tag="ul" 
    :id="generateId()" 
    v-model="list" 
    group="g1" 
    @start="onStart" 
    @end="onEnd">
    <!-- The el.id is generated into the data structure at load time in normalizeForLoad() -->
    <li v-for="el in jsonData" 
      :key="el.id" 
      :id="el.id"
      :class="[
        { selected: isSelected(el.id) },
        { disabled: isDisabled(el.id) },
      ]" 
      @click.capture="select(el.id, $event)">

      <div
          v-if="!jsonData.file"
          class="lux-item"
        >
        <lux-input-button
          class="expand-collapse"
          type="button"
          variation="icon"
          size="small"
          :icon="expandCollapseIcon"
          block
          @button-clicked="toggleFolder($event)"
        />
      </div>
      <div class="folder-container">
        <lux-icon-base
          class="handle cursor-move"
          width="20"
          height="20"
          icon-name="End Node"
          icon-color="gray"
        >
          <lux-icon-unsorted></lux-icon-unsorted>
        </lux-icon-base>
      
      <template v-if="editedFieldId === el.id">
        <div
          class="folder-label"
          :dir="viewDir"
        >
          <input
            :ref="`field${el.id}`"
            :id="`input${el.id}`"
            v-model="el.label"
            type="text"
            class="folder-label-input"
            @keyup="saveLabel(el)"
            @keydown.enter="hideLabelInput()"
            @blur="hideLabelInput()"
          >
        </div>
      </template>
      <template v-else>
        <div
          :class="el.file ? 'file-label' : 'folder-label'"
          :dir="viewDir"
        >
          {{ el.label }}
        </div>
        <div :class="el.file ? 'file-edit' : 'folder-edit'">
          <lux-input-button
            v-if="!el.file"
            class="toggle-edit"
            type="button"
            variation="icon"
            size="small"
            icon="edit"
            @button-clicked="toggleEdit(el.id)"
          />
          <lux-input-button
            v-if="!el.file"
            class="create-folder"
            type="button"
            variation="icon"
            size="small"
            icon="add"
            @button-clicked="createFolder(el.id)"
          />
          <lux-input-button
            v-else
            class="zoom-file"
            type="button"
            variation="icon"
            size="small"
            icon="search"
            @button-clicked="zoomFile(el.id)"
          />
          <lux-input-button
            class="delete-folder"
            type="button"
            variation="icon"
            size="small"
            icon="denied"
            @button-clicked="deleteFolder(el.id)"
          />
        </div> 
      </template>
      </div>
      <tree-dnd 
        :showing="expanded"
        v-if="!el.file"
        :json-data="el.folders" 
        @drop-tree-item="$emit('drop-tree-item', $event)" 
        @drag-tree-item="$emit('drag-tree-item', $event)"
        @delete-folder="deleteFolder"
        @create-folder="createFolder"
        @zoom-file="zoomFile"
      />
    </li>
  </VueDraggable>
</template>
<script>
import { VueDraggable } from 'vue-draggable-plus'
import mixin from './structMixins.js'
import store from '../store'
import { mapState } from 'vuex'
import IconEndNode from './IconEndNode.vue'

export default {
  name: 'TreeDnd',
  status: 'prototype',
  release: '1.0.0',
  type: 'Element',
  components: {
    VueDraggable,
    'lux-icon-end-node': IconEndNode,
  },
  mixins: [mixin],
  emits: ["create-folder", "delete-folder", "zoom-file", "drop-tree-item", "drag-tree-item"],
  props: {
    /**
     * id identifies the node in the tree.
     */
    id: {
      type: String,
      default: ''
    },
    jsonData: {
      type: Array,
      required: true,
      default () {
        return []
      }
    },
    showing: {
      type: Boolean,
      default: true
    },
    // Whether text should be displayed Left-to-Right or Right-to-Left
    viewingDirection: {
      type: String,
      default: 'LEFTTORIGHT'
    },
  },
  data: function () {
    return {
      list: JSON.parse(JSON.stringify(this.jsonData)),
      editedFieldId: null,
      expanded: true
    }
  },
  computed: {
    rootNodeSelected: function () {
      return this.tree.selected === this.tree.structure.id
    },
    thumbnail: function () {
      const hasService = !!this.jsonData.service
      if (hasService) {
        return this.jsonData.service + '/full/30,/0/default.jpg'
      } else {
        return false
      }
    },
    expandCollapseIcon: function () {
      if (this.expanded) {
        return 'arrow-down'
      }
      return 'arrow-right'
    },
    viewDir: function () {
      if (this.viewingDirection === 'RIGHTTOLEFT') {
        return 'rtl'
      }
      return 'ltr'
    },
    ...mapState({
      tree: state => store.state.tree,
      gallery: state => store.state.gallery,
      zoom: state => store.state.zoom
    })
  },
  methods: {
    createFolder: function (folderId) {
      this.$emit('create-folder', folderId)
    },
    deleteFolder: function (folderId) {
      this.$emit('delete-folder', folderId)
    },
    isDisabled: function (id) {
      if (this.tree.cut) {
        const folderList = JSON.parse(JSON.stringify(this.tree.structure.folders))
        const cutTreeStructure = this.findFolderById(folderList, this.tree.cut)
        const disabledTreeItems = this.extractIdsInStructure(cutTreeStructure)
        // return true if id matches any of the ids in cutTreeStructure
        return disabledTreeItems.includes(id)
      }
      return false
    },
    isSelected: function (id) {
      // To-Do: get Tree Items selected
      if (this.rootNodeSelected) {
        return true
      }
      if (this.tree.selected) {
        const folderList = JSON.parse(JSON.stringify(this.tree.structure.folders))
        const selectedTreeStructure = this.findFolderById(folderList, this.tree.selected)
        const selectedTreeItems = this.extractIdsInStructure(selectedTreeStructure)
        // return true if id matches any of the ids in selectedTreeItems array
        return selectedTreeItems.includes(id)
      }
      return false
    },
    zoomFile: function (fileId) {
      this.$emit('zoom-file', fileId)
    },
    extractIdsInStructure: function (structure) {
      const result = []

      function traverse (node) {
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
    select: function (id, event) {
      store.commit('SELECT_TREEITEM', id)
      // tree and gallery items cannot be selected simultaneously, so deselect the gallery
      store.commit('SELECT', [])
    },
    saveLabel: function (el) {
      // need to stringify and parse to drop the observer that comes with Vue reactive data
      // folderList is the entire structure for the tree
      const folderList = JSON.parse(JSON.stringify(this.tree.structure.folders))

      // we have to send the entire tree structure
      // we either need to update the label for the root element and send the tree as folderList 
      // in its unchanged form
      // or we need to send back the tree as an updated folderList
      let structure

      if (el.id == this.tree.structure.id) {

        structure = {
          id: this.tree.structure.id,
          folders: folderList,
          label: el.label
        }

      } else {
        const focusedFolder = this.findFolderById(folderList, el.id)
        structure = {
          id: this.tree.structure.id,
          folders: this.updateFolderLabel(folderList, focusedFolder),
          label: this.tree.structure.label
        }
      }
      store.commit('SAVE_LABEL', structure)
    },
    hideLabelInput: function () {
      this.editedFieldId = null
    },
    updateFolderLabel: function (array, selectedFolder) {
      for (const item of array) {
        if (item.id === selectedFolder.id) {
          item.label = selectedFolder.label
        } else if (item.folders?.length) {
          this.updateFolderLabel(item.folders, selectedFolder)
        }
      }
      return array
    },
    onEnd: function (event) {
      this.$emit('drop-tree-item', event)
    },
    onStart: function (event) {
      this.$emit('drag-tree-item', event)
    },
    toggleFolder: function () {
      this.expanded = !this.expanded
    },
    toggleEdit: function (id) {
      if (id) {
        this.editedFieldId = id
        this.$nextTick(() => {
          let fieldId = 'field'+id 
          if (this.$refs['field' + id]) {
            this.$refs['field' + id][0].focus()
          }
        })
      } else {
        this.editedFieldId = null
      }
    }
  }
}
</script>
<style scoped>
.drag-area {
  min-height: 50px;
  outline: 1px dashed;
  list-style: none;
}
.folder-container {
  display: flex;
}
.cursor-move {
  cursor: grab;
}
li.selected {
  background: #fdf6dc;
}

li.disabled {
  opacity: 0.2;
  cursor: not-allowed;
}
</style>
