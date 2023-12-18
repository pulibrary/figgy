<template>
  <div>
    <heading level="h2">
      Set Properties <small class="text-muted">
        for this <span v-if="isMultiVolume">
          multi-volume
        </span> resource
      </small>
    </heading>
    <span class="lux-file_count">
      <text-style variation="emphasis">
        Total files: {{ memberCount }}
      </text-style>
      <text-style
        v-if="memberCount < 1"
        variation="strong"
      >Please add files to this Resource
        before proceeding.</text-style>
    </span>
    <span
      v-if="resource.bibId"
      class="lux-bibid"
    >
      | BibId: {{ resource.bibId }}
    </span>
    <form
      id="app"
      novalidate="true"
    >
      <input-radio
        id="viewDir"
        vertical
        group-label="Viewing Direction"
        :options="viewDirs"
        :value="viewDirs.value"
        @change="updateViewDir($event)"
      />
      <input-radio
        v-if="!isMultiVolume"
        id="viewHint"
        vertical
        group-label="Viewing Hint"
        :options="viewHints"
        :value="viewHints.value"
        @change="updateViewHint($event)"
      />
    </form>
  </div>
</template>

<script>
/**
 * This is the Resource Form for the Order Manager in Figgy
 */
import { mapState } from 'vuex'
export default {
  name: 'ResourceForm',
  status: 'ready',
  release: '1.0.0',
  type: 'Pattern',
  metaInfo: {
    title: 'Resource Form',
    htmlAttrs: {
      lang: 'en'
    }
  },
  props: {
    /**
     * The html element name used for the component.
     */
    type: {
      type: String,
      default: 'div'
    },
    count: {
      type: Number,
      default: 0
    }
  },
  computed: {
    memberCount: function () {
      return this.$store.getters.getMemberCount
    },
    isMultiVolume () {
      return this.$store.getters.isMultiVolume
    },
    ...mapState({
      resource: state => state.ordermanager.resource
    }),
    viewHints: function () {
      return [
        {
          name: 'viewHint',
          value: 'individuals',
          id: 'individuals',
          checked: this.resource.viewingHint === 'individuals'
        },
        { name: 'viewHint', value: 'paged', id: 'paged', checked: this.resource.viewingHint === 'paged' },
        {
          name: 'viewHint',
          value: 'continuous',
          id: 'continuous',
          checked: this.resource.viewingHint === 'continuous'
        }
      ]
    },
    viewDirs: function () {
      return [
        {
          name: 'viewDir',
          value: 'LEFTTORIGHT',
          id: 'left-to-right',
          label: 'left-to-right',
          checked: this.resource.viewingDirection === 'LEFTTORIGHT'
        },
        {
          name: 'viewDir',
          value: 'RIGHTTOLEFT',
          id: 'right-to-left',
          label: 'right-to-left',
          checked: this.resource.viewingDirection === 'RIGHTTOLEFT'
        },
        {
          name: 'viewDir',
          value: 'TOPTOBOTTOM',
          id: 'top-to-bottom',
          label: 'top-to-bottom',
          checked: this.resource.viewingDirection === 'TOPTOBOTTOM'
        },
        {
          name: 'viewDir',
          value: 'BOTTOMTOTOP',
          id: 'bottom-to-top',
          label: 'bottom-to-top',
          checked: this.resource.viewingDirection === 'BOTTOMTOTOP'
        }
      ]
    }
  },
  methods: {
    isIndividuals: function () {
      return this.resource.viewingHint === 'individuals'
    },
    isPaged: function () {
      return this.resource.viewingHint === 'paged'
    },
    isContinuous: function () {
      return this.resource.viewingHint === 'continuous'
    },
    updateViewDir (value) {
      this.$store.dispatch('updateViewDir', value)
    },
    updateViewHint (value) {
      this.$store.dispatch('updateViewHint', value)
    }
  }
}
</script>

<style lang="scss" scoped>
small {
  font-size: 1rem;
  font-weight: 400;
}
</style>
