<template>
  <component
    :is="type"
    :class="['lux-toolbar']"
  >
    <lux-dropdown-menu
      button-label="Selection Options"
      :menu-items="[
        {name: 'All', component: 'All'},
        {name: 'None', component: 'None'},
        {name: 'Alternate', component: 'Alternate', disabled: true},
        {name: 'Inverse', component: 'Inverse'}
      ]"
      @menu-item-clicked="menuSelection($event)"
    />
    <lux-dropdown-menu
      button-label="With Selected..."
      :menu-items="[
        {name: 'Cut', component: 'Cut', disabled: isCutDisabled()},
        {name: 'Paste Before', component: 'Paste Before', disabled: isPasteDisabled()},
        {name: 'Paste After', component: 'Paste After', disabled: isPasteDisabled()}
      ]"
      @menu-item-clicked="menuSelection($event)"
    />
    <lux-spacer />
    <div class="lux-zoom-slider">
      <lux-icon-base
        class="lux-svg-icon"
        icon-name="shrink"
        icon-color="rgb(0,0,0)"
        width="12"
        height="12"
      >
        <lux-icon-picture />
      </lux-icon-base>
      <label for="img_zoom">
        Image zoom
      </label>
      <input
        id="img_zoom"
        type="range"
        min="40"
        max="500"
        value="300"
        @input="resizeCards($event)"
      >
      <lux-icon-base
        class="lux-svg-icon"
        icon-name="grow"
        icon-color="rgb(0,0,0)"
        width="24"
        height="24"
      >
        <lux-icon-picture />
      </lux-icon-base>
    </div>
  </component>
</template>

<script>
import { mapState } from 'vuex'
/**
 * Toolbars allows a user to select a value from a series of options.
 */
export default {
  name: 'Toolbar',
  status: 'ready',
  release: '1.0.0',
  type: 'Pattern',
  props: {
    /**
     * The html element name used for the container
     */
    type: {
      type: String,
      default: 'div'
    }
  },
  computed: {
    ...mapState({
      resource: state => state.ordermanager.resource,
      gallery: state => state.gallery
    }),
    cut: {
      get () {
        return this.gallery.cut
      }
    }
  },
  methods: {
    cutSelected: function () {
      this.$store.dispatch('cut', this.gallery.selected)
      this.selectNone()
    },
    getItemIndexById: function (id) {
      return this.gallery.items
        .map(function (item) {
          return item.id
        })
        .indexOf(id)
    },
    isCutDisabled: function () {
      return !!this.gallery.cut.length
    },
    isPasteDisabled: function () {
      return !(this.gallery.cut.length && this.gallery.selected.length)
    },
    paste: function (indexModifier) {
      let items = this.gallery.items
      items = items.filter(val => !this.gallery.cut.includes(val))
      const pasteAfterIndex =
        this.getItemIndexById(this.gallery.selected[this.gallery.selected.length - 1].id) + indexModifier
      items.splice(pasteAfterIndex, 0, ...this.gallery.cut)
      this.$store.dispatch('paste', items)
      this.resetCut()
      this.selectNone()
    },
    resetCut: function () {
      this.$store.dispatch('cut', [])
    },
    resizeCards: function (event) {
      this.$emit('cards-resized', event)
    },
    menuSelection (value) {
      switch (value.target.innerText) {
        case 'All':
          this.selectAll()
          break
        case 'None':
          this.selectNone()
          break
        case 'Alternate':
          this.selectAlternate()
          break
        case 'Inverse':
          this.selectInverse()
          break
        case 'Cut':
          this.cutSelected()
          break
        case 'Paste Before':
          this.paste(-1)
          break
        case 'Paste After':
          this.paste(1)
          break
      }
    },
    selectAll: function () {
      this.$store.dispatch('select', this.gallery.items)
    },
    selectAlternate: function () {
      const selected = []
      const itemTotal = this.gallery.items.length
      for (let i = 0; i < itemTotal; i = i + 2) {
        selected.push(this.gallery.items[i])
      }
      this.$store.dispatch('select', selected)
    },
    selectInverse: function () {
      const selected = []
      const itemTotal = this.gallery.items.length
      for (let i = 1; i < itemTotal; i = i + 2) {
        selected.push(this.gallery.items[i])
      }
      this.$store.dispatch('select', selected)
    },
    selectNone: function () {
      this.$store.dispatch('select', [])
    }
  }
}
</script>

<style lang="scss" scoped>
.lux-toolbar {
  box-sizing: border-box;
  margin: 0;
  margin-bottom: 16px;
  font-family: franklin-gothic-urw,Helvetica,Arial,sans-serif;
  font-size: 16px;
  line-height: 1;
  background: #f5f5f5;
  height: 64px;
  align-items: center;
  display: flex;
  padding: 0 24px;
}

.lux-zoom-slider {
  .lux-svg-icon,
  input {
    vertical-align: middle;
    line-height: 1;
    margin: 0;
  }

  input[type="range"] {
    display: inline;
    width: auto;
  }

  label {
    position: absolute;
    clip: rect(1px, 1px, 1px, 1px);
    padding: 0;
    border: 0;
    height: 1px;
    width: 1px;
    overflow: hidden;
  }
}
</style>
