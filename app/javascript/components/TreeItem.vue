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
        ]"
      >
        <lux-icon-base
          v-if="isFile"
          width="30"
          height="30"
          icon-name="End Node"
          icon-color="gray"
        >
          <lux-icon-end-node></lux-icon-end-node>
        </lux-icon-base>
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
              icon="globe"
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
    }
  },
  computed: {
    expandCollapseIcon: function() {
      if (this.isOpen) {
        return "arrow-down"
      }
      return "arrow-right"
    },
    hasChildren: function() {
      return this.jsonData.folders.length > 0
    },
    isFile: function() {
      return false
    },
    isSelected: function() {
      if (this.tree.selected === this.id) {
        return true
      }
      return false
    },
    ...mapState({
      tree: state => store.state.tree,
    }),
  },
  methods: {
    findSelectedFolderById: function (array, id) {
      for (const item of array) {
        if (item.id === id) return item;
        if (item.folders?.length) {
          const innerResult = this.findSelectedFolderById(item.folders, id);
          if (innerResult) return innerResult;
        }
      }
    },
    select: function(id, event) {
      if (!this.isOpen) {
        this.isOpen = !this.isOpen
      }
      store.commit("SELECT", id)
    },
    saveLabel: function(id) {
      const parentId = this.tree.selected ? this.tree.selected : this.tree.structure.id;
      // need to stringify and parse to drop the observer that comes with Vue reactive data
      const folderList = JSON.parse(JSON.stringify(this.tree.structure.folders))
      let selectedFolder = this.findSelectedFolderById(folderList, parentId)
      const structure = {
        id: this.tree.structure.id,
        folders: this.updateFolderLabel(folderList, selectedFolder),
        label: this.tree.structure.label,
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
