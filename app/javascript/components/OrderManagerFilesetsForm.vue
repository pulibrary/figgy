<template>
  <div>
    <heading level="h2">
      Generate Labels <small>for selected items</small>
    </heading>
    <form
      id="app"
      novalidate="true"
    >
      <input-text
        id="unitLabel"
        v-model="unitLabel"
        label="Label"
        placeholder="e.g., p."
        @input="updateMultiLabels()"
      />
      <input-text
        id="startNum"
        v-model="start"
        label="Starting Numeral"
        placeholder="e.g., 10"
        @input="updateMultiLabels()"
      />
      <input-checkbox
        v-if="!isMultiVolume"
        v-model="bracket"
        :options="addBracketOpts"
        @change="updateMultiLabels()"
      />

      <input-select
        v-if="!isMultiVolume"
        id="labelMethod"
        v-model="method"
        label="Labeling Method"
        :options="methodOpts"
      />

      <div
        v-if="method === 'foliate'"
        class="lux-row"
      >
        <input-text
          id="frontLabel"
          v-model="frontLabel"
          label="Front Label"
          placeholder="(recto)"
          @input="updateMultiLabels()"
        />
        <input-text
          id="backLabel"
          v-model="backLabel"
          label="Back Label"
          placeholder="(verso)"
          @input="updateMultiLabels()"
        />
        <input-select
          v-if="!isMultiVolume"
          id="startWith"
          v-model="startWith"
          label="Start With"
          :options="startWithOpts"
          @change="updateMultiLabels()"
        />
      </div>
    </form>
  </div>
</template>

<script>
// import Lablr from "../utils/lablr"
// const Lablr = require('../utils/lablr').default
import Lablr from 'page-label-generator'
import { mapState } from 'vuex'
/**
 * This is the Filesets Form for the Order Manager in Figgy
 */
export default {
  name: 'FilesetsForm',
  status: 'ready',
  release: '1.0.0',
  type: 'Pattern',
  metaInfo: {
    title: 'Fileset Form',
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
    }
  },
  data: function () {
    return {
      start: '1',
      method: 'paginate',
      frontLabel: 'r. ',
      backLabel: 'v. ',
      startsWith: 'front',
      unitLabel: 'p. ',
      bracket: false
    }
  },
  computed: {
    ...mapState({
      resource: state => state.ordermanager.resource,
      gallery: state => state.gallery
    }),
    isMultiVolume () {
      return this.$store.getters.isMultiVolume
    },
    selectedTotal () {
      return this.gallery.selected.length
    },
    addBracketOpts: function () {
      return [
        {
          name: 'addBrackets',
          value: 'Add Brackets',
          id: 'addBrackets',
          checked: this.labelerOpts().bracket
        }
      ]
    },
    methodOpts: function () {
      return [{ label: 'Paginate (Default)', value: 'paginate' }, { label: 'Foliate', value: 'foliate' }]
    },
    startWithOpts: function () {
      return [{ label: 'Front (Default)', value: 'front' }, { label: 'Back', value: 'back' }]
    }
  },
  watch: {
    method: function (val) {
      this.updateMultiLabels()
    }
  },
  methods: {
    labelerOpts () {
      let unitLabel = this.unitLabel

      // This should be generated with calculate() or watch()
      if (this.method === 'paginate') {
        unitLabel = 'p. '
      } else if (this.method === 'foliate') {
        unitLabel = 'f. '
      }

      let frontLabel = this.method === 'paginate' ? '' : this.frontLabel
      let backLabel = this.method === 'paginate' ? '' : this.backLabel

      return {
        start: this.start,
        method: this.method,
        startsWith: this.startsWith,
        bracket: this.bracket,
        frontLabel,
        backLabel,
        unitLabel
      }
    },
    isNormalInteger (str) {
      return /^\+?(0|[1-9]\d*)$/.test(str)
    },
    updateMultiLabels () {
      let changeList = this.gallery.changeList
      let items = this.gallery.items
      this.start = this.isNormalInteger(this.start)
        ? this.start - 0
        : this.start
      let generator = Lablr.pageLabelGenerator(this.labelerOpts())
      for (let i = 0; i < this.selectedTotal; i++) {
        let index = this.gallery.items
          .map(function (item) {
            return item.id
          })
          .indexOf(this.gallery.selected[i].id)
        items[index].caption = generator.next().value

        if (changeList.indexOf(this.gallery.selected[i].id) === -1) {
          changeList.push(this.gallery.selected[i].id)
        }
      }

      this.$store.dispatch('updateChanges', changeList)
      this.$store.dispatch('updateItems', items)
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
