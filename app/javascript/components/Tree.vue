<template>
  <ul class="lux-tree">
    <tree-item
      :id="tree.structure.id"
      :json-data="tree.structure"
      :selected="selected"
      :delete-folder="handleDeleteFolder"
      :create-folder="handleCreateFolder"
      :zoom-file="handleZoomFile"
      >
    </tree-item>
  </ul>
</template>

<script>
import store from "../store"
import { mapState, mapGetters } from "vuex"
import TreeItem from '@components/TreeItem.vue'

/**
 * Trees are used to display and navigate hierarchical data.
 */
export default {
  name: "Tree",
  status: "prototype",
  release: "1.0.0",
  type: "Element",
  components: {
    'tree-item': TreeItem,
  },
  props: {
    /**
     * id identifies the node in the tree.
     */
    id: {
      default: "",
    },
    selected: {
      default: null,
    },
    jsonData: {
      required: true,
    },
  },
  data: function() {
    return {
      isOpen: false,
      structure: this.jsonData,
    }
  },
  computed: {
    ...mapState({
      tree: state => store.state.tree,
    }),
  },
  methods: {
    handleCreateFolder: function(folder_id) {
      this.$emit('create-folder', folder_id);
    },
    handleDeleteFolder: function(folder_id) {
      this.$emit('delete-folder', folder_id);
    },
    handleZoomFile: function(file_id) {
      this.$emit('zoom-file', file_id);
    },
  },
  beforeMount: function() {
    if (this.selected) {
      // if props are passed in select the appropriate node
      store.commit("SELECT", this.selected)
    }
  },
}
</script>

<style lang="scss" scoped>
.lux-tree {
  margin-left: -50px;
}
.lux-tree.lux-button.icon.small {
  padding: 0px;
}
</style>
