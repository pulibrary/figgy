<template>
  <div>
    <ul :class="root ? 'tree' : ''">
      <li
        v-for="child in children"
        :key="child.path"
      >
        <v-details
          v-if="child.expandable"
          v-model="child.expanded"
          @change="expanding(child)"
        >
          <summary
            class="item-label"
            :class="{ 'list-focus': isFocused(child) }"
          >
            <div class="expander">
              <svg v-if="child.expanded"><polygon points="5,8 10,13 15,8" /></svg>
              <svg v-else><polygon points="8,5 13,10 8,15" /></svg>
            </div>
            <span
              @click="listFocused(child, $event)"
            >
              {{ child.label }}
            </span>
          </summary>
          <DirectoryPicker
            :start-children="child.children"
            :root="false"
            :list-focus="listFocus"
            @listFocus="listFocused"
          />
        </v-details>
        <span
          v-else
          class="item-label"
        >
          {{ child.label }}
        </span>
      </li>
    </ul>
  </div>
</template>
<script>
// Support choosing a single directory for use in Bulk Ingest.
// TODO: Add multi-select functionality for file select.
export default {
  name: 'DirectoryPicker',
  props: {
    // What the tree is initialized with.
    startChildren: {
      type: Array,
      default: null
    },
    // Whether this is the root node
    root: {
      type: Boolean,
      default: true
    },
    listFocus: {
      type: Object,
      default: null
    }
  },
  data () {
    return {
      'children': this.startChildren
    }
  },
  methods: {
    expanding (child) {
      if (child.loaded === false && child.loadChildrenPath) {
        this.loadChildren(child)
      }
    },
    listFocused (child, event) {
      // Tell the file browser which thing got focused.
      this.$emit('listFocus', child)
      // Clicking the label (span) shouldn't cause collapse.
      if (event) {
        event.preventDefault()
      }
    },
    isFocused (child) {
      return this.listFocus && child.path === this.listFocus.path
    },
    loadChildren (child) {
      return fetch(
        child.loadChildrenPath,
        { credentials: 'include' }
      )
        .then((response) => response.json())
        .then((response) => {
          child.children = response
          child.loaded = true
        })
        .catch(_ => { child.expanded = false })
    }
  }
}
</script>
<style scope>
.tree {
  --spacing: 1.5rem;
  --radius: 8px;
  /* I don't know how to use Lux's color tokens.. */
  /* color-grayscale-warm-lighter */
  --directory-background: rgb(250, 249, 245);
  /* color-grayscale-warm-light */
  --directory-background-hover: rgb(210, 202, 173);
  /* color-grayscale-warm */
  --directory-selected: rgb(186, 175, 130);
  padding-left: 0;
}
.tree li{
  display      : block;
  position     : relative;
}

.tree ul{
  margin-left  : calc(var(--radius) - var(--spacing));
}

.tree summary{
  cursor  : pointer;
}

.item-label {
  display: flex;
  align-items: center;
  margin: 1px;
}

.expander {
  width: 20px;
  display: flex;
  align-self: stretch;
  align-items: center;
  margin-right: 2px;
  pointer-events: none;
}
.expander > svg {
  width: 20px;
  height: 20px;
  display: block;
  pointer-events: none;
}

.item-label > span {
  display: block;
  flex-grow: 1;
  background-color: var(--directory-background);
  padding-left: 5px;
}
.item-label > span:hover {
  background-color: var(--directory-background-hover);
}
.item-label.list-focus > span {
  background-color: var(--directory-selected);
}

.tree summary::marker,
.tree summary::-webkit-details-marker{
  display : none;
}

.tree summary:focus{
  outline : none;
}

.tree summary:focus-visible{
  outline : 1px dotted #000;
}
label {
  display: inline-block;
  position: relative;
}
input[type="checkbox"] {
  margin-left: 2px;
  margin-right: 2px;
}
</style>
