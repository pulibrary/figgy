<template>
  <VueDraggable class="drag-area" tag="ul" v-model="list" group="g1" @start="onStart" @end="onEnd">
    <li v-for="el in jsonData" :key="el.label">
      <p>{{ el.label }}</p>
      <tree-dnd :json-data="el.folders" />
    </li>
  </VueDraggable>
</template>
<script>
import { VueDraggable } from 'vue-draggable-plus'

export default {
  name: 'TreeDnd',
  status: 'prototype',
  release: '1.0.0',
  type: 'Element',
  components: {
    VueDraggable,
  },
  emits: ["create-folder", "delete-folder", "zoom-file"],
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
      // default () {
      //   return []
      // }
    },
  },
  data: function () {
    return {
      list: JSON.parse(JSON.stringify(this.jsonData))
    }
  },
  methods: {
    onEnd: function (event) {
      console.log(JSON.parse(JSON.stringify(event.item)))
      this.$emit('drop-tree-item', event.item)
    }
  }
}
</script>
<style scoped>
.drag-area {
  min-height: 50px;
  outline: 1px dashed;
}
</style>
