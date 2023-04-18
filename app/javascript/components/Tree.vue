<template>
  <ul class="lux-tree">
    <tree-item :id="collection.id" :json-data="collection" :selected="selected"> </tree-item>
  </ul>
</template>

<script>
import store from "../store"
import { mapState, mapGetters } from "vuex"
import TreeItem from './TreeItem'

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
      collection: this.jsonData,
    }
  },
  computed: {
    ...mapState({
      tree: state => store.state.tree,
    }),
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
  margin-left: -40px;
}
.lux-tree.lux-button.icon.small {
  padding: 0px;
}
</style>
