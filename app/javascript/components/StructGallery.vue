<template>
  <wrapper type="div" class="lux-gallery" @click.native="deselect($event)">
    <card
      v-for="(item, index) in items"
      :id="item.id"
      :key="item.id"
      class="lux-galleryCard"
      :cardPixelWidth="cardPixelWidth"
      size="medium"
      :selected="isSelected(item)"
      :disabled="isDisabled(item)"
      :edited="hasChanged(item.id)"
      @click.capture="select(item.id, $event)"
    >
      <media-image :src="item.mediaUrl"></media-image>
      <heading level="h2">{{ item.title }}</heading>
      <text-style variation="default">{{ item.caption }}</text-style>
    </card>
  </wrapper>
</template>

<script>
import store from "../store"
import { mapState, mapGetters } from "vuex"
/*
 * Gallery is a grid of images with captions.
 */
export default {
  name: "StructGallery",
  status: "ready",
  release: "1.0.0",
  type: "Pattern",
  computed: {
    items: {
      get() {
        return this.gallery.items
      },
      set(value) {
        store.commit("SORT_ITEMS", value)
      },
    },
    ...mapState({
      gallery: state => store.state.gallery,
    }),
  },
  props: {
    /**
     * Gallery items to be displayed in the gallery.
     */
    galleryItems: {
      required: true,
      type: Array,
    },
    /**
     * Pixel width of the cards in the gallery.
     */
    cardPixelWidth: {
      required: false,
      default: 300,
    },
  },
  methods: {
    deselect: function(event) {
      if (
        event.target.className === "lux-gallery lux-galleryWrapper lux-wrapper"
      ) {
        this.selectNone()
      }
    },
    selectNone: function() {
      store.commit("SELECT", [])
    },
    getItemById: function(id) {
      var elementPos = this.getItemIndexById(id)
      return this.items[elementPos]
    },
    getItemIndexById: function(id) {
      return this.items
        .map(function(item) {
          return item.id
        })
        .indexOf(id)
    },
    hasChanged: function(id) {
      return this.gallery.changeList.indexOf(id) > -1
    },
    isDisabled: function(item) {
      return this.gallery.cut.indexOf(item) > -1
    },
    isSelected: function(item) {
      return this.gallery.selected.indexOf(item) > -1
    },
    select: function(id, event) {
      this.$emit("card-clicked", event)
      if (!this.isDisabled(this.getItemById(id))) {
        // can't select disabled item
        let selected = []
        if (event.metaKey) {
          selected = this.gallery.selected
          selected.push(this.getItemById(id))
          store.commit("SELECT", selected)
        } else {
          if (this.gallery.selected.length === 1 && event.shiftKey) {
            var first = this.getItemIndexById(this.gallery.selected[0].id)
            var second = this.getItemIndexById(id)
            var min = Math.min(first, second)
            var max = Math.max(first, second)
            for (var i = min; i <= max; i++) {
              selected.push(this.items[i])
            }
            store.commit("SELECT", selected)
          } else {
            store.commit("SELECT", [this.getItemById(id)])
          }
        }
      }
    },
  },
  beforeMount: function() {
    if (this.galleryItems) {
      // if props are passed in set the cards on mount
      // window.app = this
      store.commit("SET_GALLERY", this.galleryItems)
    } else {
      // retrieve the data via an asyn action
    }
  },
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

    .lux-media-image img {
      height: auto;
    }
  }
  .lux-card.lux-galleryCard {
    width: auto;
  }
}
</style>
