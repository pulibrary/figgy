<template>
  <vue-draggable
    class="dragArea"
    tag="ul"
    :list="tasks"
    :group="{ name: 'g1' }"
    item-key="name"
  >
    <template #item="{ element }">
      <li>
        <p>{{ element.name }}</p>
        <tree-nested :tasks="element.tasks" />
      </li>
    </template>
  </vue-draggable>
</template>
<script>
import { VueDraggable } from "vue-draggable-plus"

export default {
  props: {
    tasks: {
      required: true,
      type: Array
    }
  },
  components: {
    VueDraggable
  },
  name: "tree-nested"
};
</script>
<style scoped>
.dragArea {
  min-height: 50px;
  outline: 1px dashed;
}
</style>