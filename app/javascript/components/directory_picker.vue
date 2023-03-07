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
  --radius: 10px;
  padding-left: 0;
}
.tree li{
  display      : block;
  position     : relative;
  padding-left : calc(2 * var(--spacing) - var(--radius) - 2px);
}

.tree ul{
  margin-left  : calc(var(--radius) - var(--spacing));
  padding-left : 0;
}
.tree ul li{
  /*
  border-left : 2px solid #ddd;
  */
}

.tree ul li:last-child{
  /* border-color : transparent; */
}
.tree ul li::before{
  content      : '';
  display      : block;
  position     : absolute;
  top          : calc(var(--spacing) / -2);
  left         : -2px;
  width        : calc(var(--spacing) + 2px);
  height       : calc(var(--spacing) + 1px);
  /*
  border       : solid #ddd;
  border-width : 0 0 2px 2px;
  */
}
.tree summary{
  display : inline-block;
  cursor  : pointer;
}

.item-label {
  width: 100%;
  background-color: lightgray;
  display: block;
  margin: 1px;
}

.item-label > span {
  display: block;
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
.tree li::after,
.tree summary::before{
  content       : '';
  display       : block;
  position      : absolute;
  top           : calc(var(--spacing) / 2 - var(--radius));
  left          : calc(var(--spacing) - var(--radius) - 1px);
  width         : calc(2 * var(--radius));
  height        : calc(2 * var(--radius));
  /*
  border-radius : 50%;
  background    : #ddd;
  */
}
.tree summary::before{
  content     : '+';
  z-index     : 1;
  background  : #696;
  color       : #fff;
  line-height : calc(2 * var(--radius) - 2px);
  text-align  : center;
}

.tree details[open] > summary::before{
  content : '−';
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
