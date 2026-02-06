<template>
  <VueDraggable class="drag-area" tag="ul" :id="list.id" v-model="list" group="g1" @start="onStart" @end="onEnd">
    <li v-for="el in jsonData" :key="el.label" :id="el.id">
      <p>{{ el.label }}</p>
      <tree-dnd :json-data="el.folders" @drop-tree-item="$emit('drop-tree-item', $event)" @drag-tree-item="$emit('drag-tree-item', $event)"/>
    </li>
  </VueDraggable>
</template>
<script>
import { VueDraggable } from 'vue-draggable-plus'
import mixin from './structMixins.js'

export default {
  name: 'TreeDnd',
  status: 'prototype',
  release: '1.0.0',
  type: 'Element',
  components: {
    VueDraggable,
  },
  mixins: [mixin],
  emits: ["drop-tree-item"],
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
  },
  data: function () {
    return {
      list: JSON.parse(JSON.stringify(this.jsonData))
    }
  },
  methods: {
    onEnd: function (event) {
      this.$emit('drop-tree-item', event)
    },
    onStart: function (event) {
      this.$emit('drag-tree-item', event)
    },
  }
}
</script>
<style scoped>
.drag-area {
  min-height: 50px;
  outline: 1px dashed;
}
</style>
