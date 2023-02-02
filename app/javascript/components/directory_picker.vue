<template>
  <div>
    <ul :class="root ? 'tree' : ''">
      <li
        v-for="child in children"
        :key="child.path"
      >
        <v-details
          v-if="renderChildren(child)"
          v-model="child.expanded"
          @change="expanding(child)"
        >
          <summary>
            <label v-if="child.selectable">
              <input
                :checked="childSelected(child)"
                type="checkbox"
                @change="requestChildSelect(child, $event)"
              >
              {{ child.label }}
            </label>
            <span v-else>
              {{ child.label }}
            </span>
          </summary>
          <DirectoryPicker
            :start-children="child.children"
            :root="false"
            :selected="root ? selectedChild : selected"
            @selected="requestChildSelect"
          />
        </v-details>
        <span v-else>
          {{ child.label }}
        </span>
      </li>
    </ul>
  </div>
</template>
<script>
// Support choosing a single directory for use in Bulk Ingest.
// TODO: Add an input that stores the selected folder.
// TODO: Add multi-select functionality for file select.
export default {
  name: 'DirectoryPicker',
  props: {
    startChildren: {
      type: Array,
      default: null
    },
    root: {
      type: Boolean,
      default: true
    },
    selected: {
      type: Object,
      default: null
    }
  },
  data () {
    return {
      'selectedChild': this.selected,
      'children': this.startChildren || [
        {
          'label': 'Dir1',
          'path': '/Dir1',
          'expanded': true,
          'selected': false,
          'selectable': false,
          'loaded': true,
          'children': [
            {
              'label': 'Subdir1',
              'path': '/Dir1/Subdir1',
              'expanded': false,
              'selected': false,
              'selectable': true,
              'loaded': true,
              'children': [
                {
                  'label': 'SubSubdir1',
                  'path': '/Dir1/Subdir1/SubSubdir1',
                  'loadChildrenPath': '/test',
                  'expanded': false,
                  'selected': false,
                  'selectable': false,
                  'loaded': false,
                  'children': []
                },
                {
                  'label': 'SubSubdir2',
                  'path': '/Dir1/Subdir1/SubSubdir2',
                  'expanded': false,
                  'selected': false,
                  'selectable': false,
                  'loaded': true,
                  'children': []
                }
              ]
            }
          ]
        },
        {
          'label': 'Dir2',
          'path': '/Dir2',
          'expanded': false,
          'selected': false,
          'selectable': true,
          'loaded': true,
          'children': [
            {
              'label': 'Subdir1',
              'path': '/Dir2/Subdir1',
              'expanded': false,
              'selected': false,
              'selectable': false,
              'loaded': true,
              'children': []
            },
            {
              'label': 'Subdir2',
              'path': '/Dir2/Subdir2',
              'expanded': false,
              'selected': false,
              'selectable': false,
              'loaded': true,
              'children': []
            }
          ]
        }
      ]
    }
  },
  computed: {
    // Root has a data property for selected child because it has to change, but
    // nested components use the `selected` prop so the root's selection will
    // change the child boxes.
    singleSelectedChild () {
      if (this.root) {
        return this.selectedChild
      } else {
        return this.selected
      }
    }
  },
  methods: {
    renderChildren (child) {
      return child.children.length > 0 || (child.loaded === false &&
        child.loadChildrenPath)
    },
    childSelected (child) {
      return child === this.singleSelectedChild
    },
    // If this is the root, then set the selected node. If it's a child
    // directory, tell the parent that a new item was selected.
    requestChildSelect (selectedChild, event) {
      // Handle unselect
      if (event && !event.target.checked) {
        selectedChild = null
      }
      if (this.root) {
        this.selectedChild = selectedChild
      }
      // If it's not the root, propagate the event upwards.
      this.$emit('selected', selectedChild)
    },
    expanding (child) {
      if (child.loaded === false && child.loadChildrenPath) {
        this.loadChildren(child)
      }
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
  border-left : 2px solid #ddd;
}

.tree ul li:last-child{
  border-color : transparent;
}
.tree ul li::before{
  content      : '';
  display      : block;
  position     : absolute;
  top          : calc(var(--spacing) / -2);
  left         : -2px;
  width        : calc(var(--spacing) + 2px);
  height       : calc(var(--spacing) + 1px);
  border       : solid #ddd;
  border-width : 0 0 2px 2px;
}
.tree summary{
  display : inline-block;
  cursor  : pointer;
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
  border-radius : 50%;
  background    : #ddd;
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
