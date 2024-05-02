<template>
  <lux-wrapper
    type="div"
    class="lux-gallery"
    @click="deselect($event)"
  >
    <lux-card
      v-for="(item) in items"
      :id="item.id"
      :key="item.id"
      class="lux-galleryCard"
      :card-pixel-width="cardPixelWidth"
      size="medium"
      :selected="isSelected(item)"
      :disabled="isDisabled(item)"
      :edited="hasChanged(item.id)"
      @click.capture="select(item.id, $event)"
    >
      <lux-media-image :src="item.mediaUrl" />
      <lux-heading level="h2">
        {{ item.title }}
      </lux-heading>
      <lux-text-style variation="default">
        {{ item.caption }}
      </lux-text-style>
      <lux-input-button
        class="zoom-icon"
        type="button"
        variation="icon"
        size="small"
        icon="search"
        @button-clicked="zoomOnItem(item)"
      />
    </lux-card>
  </lux-wrapper>
</template>

<script>
import store from '../store'
import { mapState } from 'vuex'
/*
 * Gallery is a grid of images with captions.
 */
export default {
  name: 'StructGallery',
  status: 'ready',
  release: '1.0.0',
  type: 'Pattern',
  props: {
    /**
     * Gallery items to be displayed in the gallery.
     */
    galleryItems: {
      required: true,
      type: Array
    },
    /**
     * Pixel width of the cards in the gallery.
     */
    cardPixelWidth: {
      type: Number,
      required: false,
      default: 300
    }
  },
  computed: {
    items: {
      get () {
        return this.gallery.items
      },
      set (value) {
        store.commit('SORT_ITEMS', value)
      }
    },
    ...mapState({
      gallery: state => store.state.gallery,
      zoom: state => store.state.zoom
    })
  },
  beforeMount: function () {
    if (this.galleryItems) {
      // if props are passed in set the cards on mount
      store.commit('SET_GALLERY', this.galleryItems)
    } else {
      // retrieve the data via an asyn action
    }
  },
  methods: {
    deselect: function (event) {
      if (
        event.target.className === 'lux-gallery lux-galleryWrapper lux-wrapper'
      ) {
        this.selectNoneGallery()
      }
    },
    selectNoneGallery: function () {
      this.$store.commit('SELECT', [])
    },
    getItemById: function (id) {
      const elementPos = this.getItemIndexById(id)
      return this.items[elementPos]
    },
    getItemIndexById: function (id) {
      return this.items
        .map(function (item) {
          return item.id
        })
        .indexOf(id)
    },
    hasChanged: function (id) {
      return this.gallery.changeList.indexOf(id) > -1
    },
    isDisabled: function (item) {
      return this.gallery.cut.indexOf(item) > -1
    },
    isSelected: function (item) {
      return this.gallery.selected.indexOf(item) > -1
    },
    zoomOnItem: function (item) {
      this.$store.commit('ZOOM', item)
    },
    select: function (id, event) {
      this.$emit('card-clicked', event)
      if (!this.isDisabled(this.getItemById(id))) {
        // can't select disabled item
        let selected = []
        if (event.metaKey) {
          selected = this.gallery.selected
          // if id is in the selected list,
          // remove it, otherwise, push it
          if (selected.includes(this.getItemById(id))) {
            const indexToRemove = selected.findIndex(obj => obj.id === id)
            selected.splice(indexToRemove, 1)
          } else {
            selected.push(this.getItemById(id))
          }
          store.commit('SELECT', selected)
        } else {
          if (this.gallery.selected.length === 1 && event.shiftKey) {
            const first = this.getItemIndexById(this.gallery.selected[0].id)
            const second = this.getItemIndexById(id)
            const min = Math.min(first, second)
            const max = Math.max(first, second)
            for (let i = min; i <= max; i++) {
              selected.push(this.items[i])
            }
            store.commit('SELECT', selected)
          } else {
            store.commit('SELECT', [this.getItemById(id)])
          }
        }
      }
    }
  }
}
</script>
<style lang="scss">
.lux-gallery {
  display: flex;
  flex-wrap: wrap;
  flex-direction: row;
  align-items: flex-start;
  align-content: flex-start;

  overflow: auto;
  height: calc(100% - 40px);
  border-radius: 4px;
  margin-bottom: 40px;
  clear: both;

  .lux-card {
    margin: 1rem;
    height: auto;
    overflow: hidden;
    white-space: wrap;
    position: relative;

    .lux-media-image img {
      height: auto;
    }
  }
  .lux-card.lux-galleryCard {
    width: auto;
  }
  .zoom-icon {
    position: absolute;
    bottom:0;
    right:0;
    z-index: 10;
  }
}
</style>
