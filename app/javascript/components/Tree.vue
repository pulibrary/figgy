<template>
  <ul :class="root ? 'lux-tree root' : 'lux-tree-sub'">
    <li>
      <div class="container">
        <div
          v-if="!jsonData.file"
          class="lux-item"
        >
          <input-button
            class="expand-collapse"
            type="button"
            variation="icon"
            size="small"
            :icon="expandCollapseIcon"
            block
            @button-clicked="toggleFolder($event)"
          />
        </div>
        <div
          :id="id"
          class="folder-container"
          :class="[
            'lux-item-label', 'branchnode',
            { selected: isSelected },
            { disabled: isDisabled },
          ]"
          @click.capture="select(id, $event)"
        >
          <lux-icon-base
            v-if="jsonData.file && !thumbnail"
            width="30"
            height="30"
            icon-name="End Node"
            icon-color="gray"
          >
            <lux-icon-end-node />
          </lux-icon-base>
          <media-image
            v-if="thumbnail"
            :alt="structureData.label"
            :src="thumbnail"
            height="30px"
            class="file"
            style="border: 1px solid #001123; margin-top: .5em; margin-right: .5em;"
          />
          <template v-if="editedFieldId === id">
            <div
              class="folder-label"
              :dir="viewDir"
            >
              <input
                :ref="`field${id}`"
                v-model="structureData.label"
                type="text"
                class="folder-label-input"
                @keyup.enter="saveLabel(id)"
              >
            </div>
            <div class="folder-edit">
              <input-button
                class="save-label"
                type="button"
                variation="icon"
                size="small"
                icon="approved"
                @button-clicked="saveLabel(id)"
              />
            </div>
          </template>
          <template v-else>
            <div
              class="folder-label"
              :dir="viewDir"
            >
              {{ structureData.label }}
            </div>
            <div class="folder-edit">
              <input-button
                class="toggle-edit"
                type="button"
                variation="icon"
                size="small"
                icon="edit"
                @button-clicked="toggleEdit(id)"
              />

              <input-button
                v-if="!isFile"
                class="create-folder"
                type="button"
                variation="icon"
                size="small"
                icon="add"
                @button-clicked="createFolder(id)"
              />
              <input-button
                v-else
                class="zoom-file"
                type="button"
                variation="icon"
                size="small"
                icon="search"
                @button-clicked="zoomFile(id)"
              />
              <input-button
                class="delete-folder"
                type="button"
                variation="icon"
                size="small"
                icon="denied"
                @button-clicked="deleteFolder(id)"
              />
            </div>
          </template>
        </div>
      </div>
      <ul
        v-show="isOpen"
        class="lux-tree-sub"
      >
        <tree
          v-for="(folder) in jsonData.folders"
          :id="folder.id"
          :key="folder.id"
          :json-data="folder"
          :root="false"
          :viewing-direction="viewingDirection"
          @delete-folder="deleteFolder"
          @create-folder="createFolder"
          @zoom-file="zoomFile"
        />
      </ul>
    </li>
  </ul>
</template>

<script>
import store from '../store'
import { mapState } from 'vuex'
import IconEndNode from '@components/IconEndNode.vue'
import mixin from './structMixins.js'
/**
 * TreeItems are the building blocks of hierarchical navigation.
 */
export default {
  name: 'Tree',
  status: 'prototype',
  release: '1.0.0',
  type: 'Element',
  components: {
    'lux-icon-end-node': IconEndNode
  },
  mixins: [mixin],
  props: {
    /**
     * id identifies the node in the tree.
     */
    id: {
      type: String,
      default: ''
    },
    jsonData: {
      type: Object,
      required: true,
      default () {
        return {}
      }
    },
    // Whether this is the root node
    root: {
      type: Boolean,
      default: true
    },
    // Whether text should be displayed Left-to-Right or Right-to-Left
    viewingDirection: {
      type: String,
      default: 'LEFTTORIGHT'
    }
  },
  data: function () {
    return {
      isOpen: true,
      editedFieldId: null,
      isFile: this.jsonData.file,
      structureData: this.jsonData
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
      if (this.isOpen) {
        return 'arrow-down'
      }
      return 'arrow-right'
    },
    isSelected: function () {
      if (this.rootNodeSelected) {
        return true
      }
      if (this.tree.selected) {
        const folderList = JSON.parse(JSON.stringify(this.tree.structure.folders))
        const selectedTreeStructure = this.findFolderById(folderList, this.tree.selected)
        const selectedTreeItems = this.extractIdsInStructure(selectedTreeStructure)
        // return true if id matches any of the ids in selectedTreeItems array
        return selectedTreeItems.includes(this.id)
      }
      return false
    },
    isDisabled: function () {
      if (this.tree.cut) {
        const folderList = JSON.parse(JSON.stringify(this.tree.structure.folders))
        const cutTreeStructure = this.findFolderById(folderList, this.tree.cut)
        const disabledTreeItems = this.extractIdsInStructure(cutTreeStructure)
        // return true if id matches any of the ids in cutTreeStructure
        return disabledTreeItems.includes(this.id)
      }
      return false
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
      if (!this.isOpen) {
        this.isOpen = !this.isOpen
      }
      store.commit('SELECT_TREEITEM', id)
      // tree and gallery items cannot be selected simultaneously, so deselect the gallery
      store.commit('SELECT', [])
    },
    saveLabel: function (id) {
      const parentId = this.tree.selected ? this.tree.selected : this.tree.structure.id
      // need to stringify and parse to drop the observer that comes with Vue reactive data
      const folderList = JSON.parse(JSON.stringify(this.tree.structure.folders))

      let structure = {
        id: this.tree.structure.id,
        folders: folderList,
        label: this.structureData.label
      }

      if (id !== this.tree.structure.id) {
        const selectedFolder = this.findFolderById(folderList, parentId)
        structure = {
          id: this.tree.structure.id,
          folders: this.updateFolderLabel(folderList, selectedFolder),
          label: this.tree.structure.label
        }
      }
      store.commit('SAVE_LABEL', structure)
      this.editedFieldId = null
    },
    updateFolderLabel: function (array, selectedFolder) {
      for (const item of array) {
        if (item.id === selectedFolder.id) {
          item.label = this.structureData.label
        } else if (item.folders?.length) {
          this.updateFolderLabel(item.folders, selectedFolder)
        }
      }
      return array
    },
    toggleFolder: function () {
      this.isOpen = !this.isOpen
    },
    toggleEdit: function (id) {
      if (id) {
        this.editedFieldId = id
        this.$nextTick(() => {
          if (this.$refs['field' + id]) {
            this.$refs['field' + id].focus()
          }
        })
      } else {
        this.editedFieldId = null
      }
    }
  }
}
</script>

<style lang="scss" scoped>

.lux-tree {
  margin-left: -50px;
}
.lux-tree.lux-button.icon.small {
  padding: 0px;
}

ul.lux-tree li {
  list-style-type: none;
  font-family: sans-serif;
  margin: 0px;
  line-height: 25px;
  font-size: 12px;
}

ul.lux-tree-sub li {
  margin-left: -40px;
}

ul.lux-tree li div.lux-item-label {
  // background: rgb(186, 175, 130);
  background: rgb(245, 245, 245);
  width: 100%;
  padding: 0.5em 0.5em .5em 1em;
}

ul.lux-tree li div.lux-item-label.selected {
  // background: rgb(210, 202, 173);
  background: rgb(250, 249, 245);
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
  // background: rgb(186, 175, 130);
  background: rgb(245, 245, 245);
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
  line-height: 1.4em;
}

.folder-label input[type=text]  {
  background: transparent;
  border: none;
  width: 80%;
  line-height: 22px;
}

.folder-label[dir='rtl'] {
    text-align: right;
    list-style-type: none;
    font-family: sans-serif;
    margin: 0px;
    padding-right: 1em;
    line-height: 25px;
    font-size: 12px;
}

.folder-edit .lux-button.icon.small {
  padding: 0px;
  margin: 0px;
}

</style>
