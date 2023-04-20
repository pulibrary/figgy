<template>
  <li>
    <div class="container">
      <div class="lux-item" v-if="hasChildren">
        <input-button
          @button-clicked="toggled($event)"
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
        @click.capture="select(structure.id, $event)"
        :class="[
          'lux-item-label',
          { selected: isSelected },
          { leafnode: !hasChildren },
          { branchnode: hasChildren },
        ]"
      >
        <lux-icon-base
          v-if="!hasChildren"
          width="30"
          height="30"
          icon-name="End Node"
          icon-color="gray"
        >
          <lux-icon-end-node></lux-icon-end-node>
        </lux-icon-base>
        <div>
          {{ this.jsonData.label }}
        </div>
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
  // watch: {
  //       jsonData: function(newVal, oldVal) { // watch it
  //         // console.log('jsonData changed: ', JSON.parse(JSON.stringify(newVal)), ' | was: ', JSON.parse(JSON.stringify(oldVal)))
  //       }
  // },
  data: function() {
    return {
      // hasChildren: this.jsonData.folders.length > 0,
      isOpen: true,
      structure: this.jsonData,
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
    select: function(id, event) {
      if (!this.isOpen) {
        this.isOpen = !this.isOpen
      }
      store.commit("SELECT", id)
    },
    toggled: function() {
      this.isOpen = !this.isOpen
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
</style>
