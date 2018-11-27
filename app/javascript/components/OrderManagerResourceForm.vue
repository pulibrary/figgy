<template>
  <div>
    <heading level="h2">Set Properties <small>for this <span v-if="isMultiVolume">multi-volume</span> resource</small></heading>
    <span class="lux-file_count"><text-style variation="emphasis">Total files: {{ memberCount }}</text-style></span>
    <span v-if="resource.bibId" class="lux-bibid"> | BibId: {{resource.bibId}}</span>
    <form id="app" novalidate="true">
      <input-radio @change="updateViewDir($event)" vertical id="viewDir" groupLabel="Viewing Direction"
        :options="viewDirs" :value="viewDirs.value"></input-radio>
      <input-radio v-if="!isMultiVolume" @change="updateViewHint($event)" vertical id="viewHint" groupLabel="Viewing Hint"
        :options="viewHints" :value="viewHints.value"></input-radio>
    </form>
  </div>
</template>

<script>
/**
 * This is the Resource Form for the Order Manager in Figgy
 */
import { mapState, mapGetters } from "vuex"
export default {
  name: "ResourceForm",
  status: "ready",
  release: "1.0.0",
  type: "Pattern",
  metaInfo: {
    title: "Resource Form",
    htmlAttrs: {
      lang: "en",
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
    count: {
      type: Number,
      default: 0,
    },
  },
  computed: {
    memberCount: function() {
      return this.$store.getters.getMemberCount
    },
    isMultiVolume() {
      return this.$store.getters.isMultiVolume
    },
    ...mapState({
      resource: state => state.ordermanager.resource,
    }),
    viewHints: function() {
      return [
        {
          name: "viewHint",
          value: "individuals",
          id: "individuals",
          checked: this.resource.viewingHint === "individuals",
        },
        { name: "viewHint", value: "paged", id: "paged", checked: this.resource.viewingHint === "paged" },
        {
          name: "viewHint",
          value: "continuous",
          id: "continuous",
          checked: this.resource.viewingHint === "continuous",
        },
      ]
    },
    viewDirs: function() {
      return [
        {
          name: "viewDir",
          value: "LEFTTORIGHT",
          id: "left-to-right",
          label: "left-to-right",
          checked: this.resource.viewingDirection === "LEFTTORIGHT",
        },
        {
          name: "viewDir",
          value: "RIGHTTOLEFT",
          id: "right-to-left",
          label: "right-to-left",
          checked: this.resource.viewingDirection === "RIGHTTOLEFT",
        },
        {
          name: "viewDir",
          value: "TOPTOBOTTOM",
          id: "top-to-bottom",
          label: "top-to-bottom",
          checked: this.resource.viewingDirection === "TOPTOBOTTOM",
        },
        {
          name: "viewDir",
          value: "BOTTOMTOTOP",
          id: "bottom-to-top",
          label: "bottom-to-top",
          checked: this.resource.viewingDirection === "BOTTOMTOTOP",
        },
      ]
    },
  },
  methods: {
    isIndividuals: function() {
      return this.resource.viewingHint === "individuals"
    },
    isPaged: function() {
      return this.resource.viewingHint === "paged"
    },
    isContinuous: function() {
      return this.resource.viewingHint === "continuous"
    },
    updateViewDir(value) {
      this.$store.dispatch("updateViewDir", value)
    },
    updateViewHint(value) {
      this.$store.dispatch("updateViewHint", value)
    },
  },
}
</script>

<style lang="scss" scoped>
small {
  font-size: 1rem;
  font-weight: 400;
}
</style>
