<template>
  <VueDraggable class="lux-gallery" v-model="items" tag="div" @click="deselect($event)" ref="el">
    <template v-for="element in items" :key="element.id">
      <lux-card
        :id="element.id"
        class="lux-galleryCard"
        :cardPixelWidth="cardPixelWidth"
        size="medium"
        :selected="isSelected(element)"
        :disabled="isDisabled(element)"
        :edited="hasChanged(element.id)"
        @click.capture="select(element.id, $event)"
      >
        <lux-media-image :src="element.mediaUrl"></lux-media-image>
        <lux-heading level="h2">{{ element.title }}</lux-heading>
        <lux-text-style variation="default">{{ element.caption }}</lux-text-style>
      </lux-card>
    </template>
  </VueDraggable>
</template>

<script>
import store from "../store"
import { VueDraggable } from "vue-draggable-plus"
/*
 * Gallery is a grid of images with captions.
 */
export default {
  name: "OrderManagerGallery",
  emits: [ "card-clicked" ],
  components: {
    VueDraggable,
  },
  // computed: mapState([
  //   // map this.count to store.state.count
  //   'gallery'
  // ]),
  computed: {
    items: {
      get() {
        return store.state.gallery.items
      },
      set(value) {
        store.commit("SORT_ITEMS", value)
      },
    },
    // ...mapState({
    //   gallery: state => store.gallery.state,
    // }),
    selected() {
      return store.state.gallery.selected
    },
    cut() {
      return store.state.gallery.cut
    },
    changeList() {
      return store.state.gallery.changeList
    },
    ogItems() {
      return store.state.gallery.ogItems
    },
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
    deselect: function (event) {
      if (
        event.target.className === "lux-gallery" ||
        event.target.className === "lux-gallery lux-galleryWrapper"
      ) {
        this.selectNone()
      }
    },
    selectNone: function () {
      store.commit("SELECT", [])
    },
    getItemById: function (id) {
      let elementPos = this.getItemIndexById(id)
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
      return this.changeList.indexOf(id) > -1
    },
    isDisabled: function (item) {
      return this.cut.indexOf(item) > -1
    },
    isSelected: function (item) {
      return this.selected.indexOf(item) > -1
    },
    select: function (id, event) {
      this.$emit("card-clicked", event)
      if (!this.isDisabled(this.getItemById(id))) {
        // can't select disabled item
        let selected = []
        if (event.metaKey) {
          selected = this.selected
          selected.push(this.getItemById(id))
          store.commit("SELECT", selected)
        } else {
          if (this.selected.length === 1 && event.shiftKey) {
            let first = this.getItemIndexById(this.selected[0].id)
            let second = this.getItemIndexById(id)
            let min = Math.min(first, second)
            let max = Math.max(first, second)
            for (let i = min; i <= max; i++) {
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
  beforeMount: function () {
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
