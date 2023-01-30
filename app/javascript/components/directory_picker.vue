<template>
  <div>
    <ul :class="root ? 'tree' : ''">
      <li
        v-for="child in children"
        :key="child.path"
      >
        <details
          v-if="renderChildren(child)"
          :open="child.expanded"
        >
          <summary>
            <label v-if="child.selectable">
              <input type="checkbox">
              {{ child.label }}
            </label>
            <span v-else>
              {{ child.label }}
            </span>
          </summary>
          <DirectoryPicker
            :start-children="child.children"
            :root="false"
          />
        </details>
        <span v-else>
          {{ child.label }}
        </span>
      </li>
    </ul>
  </div>
</template>
<script>
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
    }
  },
  data () {
    return {
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
                  'expanded': false,
                  'selected': false,
                  'selectable': false,
                  'loaded': true,
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
  methods: {
    renderChildren (child) {
      return child.children.length > 0
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
