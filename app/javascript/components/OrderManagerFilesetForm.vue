<template>
  <div>
    <heading level="h2">Edit <small>the selected item</small></heading>
    <form id="app" novalidate="true">
      <input-text v-on:input="updateSingle()" v-model="singleForm.caption" id="itemLabel" label="Label" placeholder="e.g., example.tif" />

      <input-select v-if="!isMultiVolume" v-on:change="updateViewHint($event)"
        label="Page Type" id="pageType"
        :options="viewHintOpts"></input-select>

      <input-checkbox
          v-if="!isMultiVolume"
          v-on:change="updateStartCanvas($event)"
          :options="startCanvasOpts" />
      <input-checkbox
          v-on:change="updateThumbnail($event)"
          :options="thumbnailOpts" />
    </form>
  </div>
</template>

<script>
import { mapState, mapGetters } from "vuex"
/**
 * This is the Fileset Form for the Order Manager in Figgy.
 * The only reason you can currently see this pattern is because hiding it causes an OpenSeadragon bug in the Order Manager.
 * Nothing to see here...
 */
export default {
  name: "FilesetForm",
  status: "ready",
  release: "1.0.0",
  type: "Pattern",
  metaInfo: {
    title: "Fileset Form",
    htmlAttrs: {
      lang: "en",
    },
  },
  computed: {
    ...mapState({
      resource: state => state.ordermanager.resource,
      gallery: state => state.gallery,
    }),
    memberViewHint: function() {
      let id = this.gallery.selected[0].id
      let selectedMember = resource.members.find(member => member.id === id)
      return selectedMember.viewingHint
    },
    startCanvas: function() {
      return this.resource.startCanvas
    },
    thumbnail: function() {
      return this.resource.thumbnail
    },
    isMultiVolume() {
      return this.$store.getters.isMultiVolume
    },
    isStartCanvas: function() {
      let id = this.gallery.selected[0].id
      return this.resource.startCanvas === id
    },
    isThumbnail: function() {
      let id = this.gallery.selected[0].id
      return this.resource.thumbnail === id
    },
    startCanvasOpts: function() {
      return [
        {
          name: "isStartCanvas",
          value: "Set as Start Page",
          id: "isStartCanvas",
          checked: this.isStartCanvas,
        },
      ]
    },
    thumbnailOpts: function() {
      return [
        {
          name: "isThumbnail",
          value: "Set as Resource Thumbnail",
          id: "isThumbnail",
          checked: this.isThumbnail,
        },
      ]
    },
    viewHintOpts: function() {
      return [
        { label: "Single Page (Default)", value: "single", selected: this.isViewHint("single") },
        { label: "Non-paged", value: "non-paged", selected: this.isViewHint("non-paged") },
        { label: "Facing Pages", value: "facing", selected: this.isViewHint("facing") },
      ]
    },
    singleForm() {
      return {
        caption: this.gallery.selected[0].caption,
        id: this.gallery.selected[0].id,
        mediaUrl: this.gallery.selected[0].mediaUrl,
        service: this.gallery.selected[0].service,
        title: this.gallery.selected[0].title,
        viewingHint: this.gallery.selected[0].viewingHint,
      }
    },
  },
  props: {
    /**
     * The html element name used for the component.
     */
    type: {
      type: String,
      default: "div",
    },
  },
  methods: {
    isViewHint(hint) {
      return this.singleForm.viewingHint === hint
    },
    updateStartCanvas(checked) {
      let startCanvas = null
      if (checked) {
        startCanvas = this.gallery.selected[0].id
      }
      this.$store.commit("UPDATE_STARTCANVAS", startCanvas)
    },
    updateThumbnail(checked) {
      let thumbnail = null
      if (checked) {
        thumbnail = this.gallery.selected[0].id
      }
      this.$store.commit("UPDATE_THUMBNAIL", thumbnail)
    },
    updateViewHint(event) {
      let viewHint = this.gallery.selected[0].viewingHint
      if (event.target.value) {
        viewHint = event.target.value
      }
      this.singleForm.viewingHint = viewHint
      this.updateSingle()
    },
    updateSingle() {
      var changeList = this.gallery.changeList
      var items = this.gallery.items
      var index = this.gallery.items
        .map(function(item) {
          return item.id
        })
        .indexOf(this.gallery.selected[0].id)
      items[index] = this.singleForm

      if (changeList.indexOf(this.gallery.selected[0].id) === -1) {
        changeList.push(this.gallery.selected[0].id)
      }

      this.$store.commit("UPDATE_CHANGES", changeList)
      this.$store.commit("UPDATE_ITEMS", items)
    },
  },
}
</script>

<style lang="scss" scoped>
small {
  font-size: 1rem;
  font-weight: 400;
}
.lux-vertical {
  display: block;
}
</style>
