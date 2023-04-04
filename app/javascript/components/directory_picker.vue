<template>
  <div>
    <ul :class="root ? 'tree' : ''">
      <li
        v-for="child in startChildren"
        :key="child.path"
      >
        <v-details
          v-if="child.expandable"
          v-model="child.expanded"
          @change="tryLoading(child)"
        >
          <summary
            class="item-label"
            :class="{ 'list-focus': isFocused(child) }"
          >
            <div class="expander">
              <svg v-if="child.expanded"><polygon points="5,8 10,13 15,8" /></svg>
              <svg v-else><polygon points="8,5 13,10 8,15" /></svg>
            </div>
            <div
              class="icon"
            >
              <svg viewBox="0 0 25 25"><path d="M11 5h13v17h-24v-20h8l3 3zm-10-2v18h22v-15h-12.414l-3-3h-6.586z" /></svg>
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
            @loadChild="tryLoading"
          />
        </v-details>
      </li>
    </ul>
  </div>
</template>
<script>
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
    }
  },
  methods: {
    tryLoading (child) {
      this.$emit('loadChild', child)
    },
    listFocused (child, event) {
      // Tell the file browser which thing got focused.
      this.$emit('listFocus', child)
      // Try loading if necessary.
      this.tryLoading(child)
      // Clicking the label (span) shouldn't cause collapse.
      if (event) {
        event.preventDefault()
      }
    },
    isFocused (child) {
      return this.listFocus && child.path === this.listFocus.path
    }
  }
}
</script>
<style lang="scss" scope>
.tree {
  --spacing: 1.5rem;
  --radius: 8px;
  --color-bleu-de-france-lightest: rgba(149, 189, 228, .25);
  /* I don't know how to use Lux's color tokens.. */
  /* color-grayscale-warm-lighter */
  --directory-background: rgb(255, 255, 255);
  /* color-grayscale-warm-light */
  --directory-background-hover: rgba(149, 189, 228, .15);
  /* color-grayscale-warm */
  --directory-selected: var(--color-bleu-de-france-lightest);
  padding-left: 0;
  padding: 10px 0 0 0;
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

.item-label {
  &:hover {
    span, .icon {
      background-color: var(--directory-background-hover);
    }
  }
  &.list-focus {
    span, .icon {
      background-color: var(--directory-selected);
    }
  }
  > span {
    display: block;
    flex-grow: 1;
    background-color: var(--directory-background);
    padding-left: 5px;
    padding-top: 2px;
    padding-bottom: 2px;
  }
  .icon {
    display: inline-block;
    margin-left: 0;
    padding: 2px 0px 2px 4px;

    svg {
      width: 16px;
      height: 16px;
    }
  }
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

.tree .icon {
  display: inline-block;
  margin-left: 0;
  padding: 2px 0px 2px 4px;
}

.tree .icon svg {
  width: 16px;
  height: 16px;
}
</style>
