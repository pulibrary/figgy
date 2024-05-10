<template>
  <div>
    <lux-heading level="h2">
      Generate Labels <small class="text-muted">for selected items</small>
    </lux-heading>
    <form
      id="app"
      novalidate="true"
    >
      <lux-input-text
        id="unitLabel"
        :value="unitLabel"
        name="unitLabel"
        label="Label"
        placeholder="e.g., p."
        @input="updateUnitLabel($event)"
        @change="updateUnitLabel($event)"
      />
      <lux-input-text
        id="startNum"
        :value="start"
        name="startNum"
        label="Starting Numeral"
        placeholder="e.g., 10"
        @input="updateStartNum($event)"
      />
      <lux-input-checkbox
        v-if="!isMultiVolume"
        :value="bracket"
        :options="addBracketOpts"
        @change="updateMultiLabels()"
      />

      <lux-input-select
        v-if="bracket"
        id="bracketLocation"
        :value="bracketLocation"
        name="bracketLocation"
        label="Bracket Location"
        :options="bracketLocationOpts"
        @change="updateMultiLabels()"
      />

      <lux-input-select
        v-if="!isMultiVolume"
        id="labelMethod"
        :value="method"
        name="labelMethod"
        label="Labeling Method"
        :options="methodOpts"
        @change="updateMethod($event)"
      />

      <lux-input-select
        id="twoUp"
        :value="twoUp"
        name="twoUp"
        label="Two Up"
        :options="twoUpOpts"
        @change="updateTwoUp($event)"
      />

      <lux-input-text
        v-if="twoUp"
        id="twoUpSeparator"
        :value="twoUpSeparator"
        name="twoUpSeparator"
        label="Two-Up Separator"
        @input="updateTwoUpSeparator($event)"
      />

      <div
        v-if="method === 'foliate'"
        class="lux-row"
      >
        <lux-input-text
          id="frontLabel"
          :value="frontLabel"
          name="frontLabel"
          label="Front Label"
          placeholder="(recto)"
          @input="updateFrontLabel($event)"
        />
        <lux-input-text
          id="backLabel"
          :value="backLabel"
          name="backLabel"
          label="Back Label"
          placeholder="(verso)"
          @input="updateBackLabel($event)"
        />
        <lux-input-select
          v-if="!isMultiVolume"
          id="startWith"
          :value="startWith"
          name="startWith"
          label="Start With"
          :options="startWithOpts"
          @change="updateStartWith($event)"
        />
      </div>
    </form>
  </div>
</template>

<script>
import Lablr from '../utils/page-label-generator'
import { mapState } from 'vuex'
import { debounce } from 'lodash'
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
      frontLabel: 'r.',
      backLabel: 'v.',
      startsWith: 'front',
      unitLabel: 'p. ',
      bracket: false,
      bracketLocation: 'default',
      twoUp: false,
      twoUpSeparator: '/'
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
          checked: this.bracket
        }
      ]
    },
    bracketLocationOpts: function () {
      if (this.twoUp) {
        return [
          {
            label: 'None', value: 'default'
          },
          {
            label: 'Left Side Only', value: 'left'
          },
          {
            label: 'Right Side Only', value: 'right'
          }
        ]
      } else {
        return [
          {
            label: 'All', value: 'default'
          },
          {
            label: 'Evens', value: 'left'
          },
          {
            label: 'Odds', value: 'right'
          }
        ]
      }
    },
    methodOpts: function () {
      return [{ label: 'Paginate (Default)', value: 'paginate' }, { label: 'Foliate', value: 'foliate' }]
    },
    twoUpOpts: function () {
      return [
        {
          label: 'One-up (Default)', value: false
        },
        {
          label: 'Two-up', value: true
        }
      ]
    },
    startWithOpts: function () {
      return [{ label: 'Front (Default)', value: 'front' }, { label: 'Back', value: 'back' }]
    },
    bracketAll: function () {
      return this.bracket && !this.twoUp && this.bracketLocation === 'default'
    },
    bracketEvens: function () {
      return this.bracket && !this.twoUp && this.bracketLocation === 'left'
    },
    bracketOdds: function () {
      return this.bracket && !this.twoUp && this.bracketLocation === 'right'
    },
    twoUpBracketLeftOnly: function () {
      return this.bracket && this.twoUp && this.bracketLocation === 'left'
    },
    twoUpBracketRightOnly: function () {
      return this.bracket && this.twoUp && this.bracketLocation === 'right'
    }
  },
  watch: {
    method: function (val) {
      this.overrideUnitLabel()
    }
  },
  methods: {
    overrideUnitLabel () {
      // This should be generated with calculate() or watch()
      if (this.method === 'paginate') {
        this.unitLabel = 'p. '
      } else if (this.method === 'foliate') {
        this.unitLabel = 'f. '
      }
    },
    updateUnitLabel (event) {
      const label = event.target.value
      this.unitLabel = label
      this.updateMultiLabels()
    },
    updateStartNum (event) {
      const start = event.target.value
      this.start = start
      this.updateMultiLabels()
    },
    updateMethod (event) {
      this.method = event
      this.updateMultiLabels()
    },
    updateTwoUp (event) {
      this.twoUp = event
      this.updateMultiLabels()
    },
    updateTwoUpSeparator (event) {
      this.twoUpSeparator = event.target.value
      this.updateMultiLabels()
    },
    updateFrontLabel (event) {
      this.frontLabel = event.target.value
      this.updateMultiLabels()
    },
    updateBackLabel (event) {
      this.backLabel = event.target.value
      this.updateMultiLabels()
    },
    updateStartWith (event) {
      this.startsWith = event
      this.updateMultiLabels()
    },
    labelerOpts () {
      const unitLabel = this.unitLabel

      const frontLabel = this.method === 'paginate' ? '' : this.frontLabel
      const backLabel = this.method === 'paginate' ? '' : this.backLabel

      return {
        start: this.start,
        method: this.method,
        startsWith: this.startsWith,
        bracket: this.bracketAll,
        bracketEvens: this.bracketEvens,
        bracketOdds: this.bracketOdds,
        frontLabel,
        backLabel,
        unitLabel,
        twoUp: this.twoUp,
        twoUpSeparator: this.twoUpSeparator,
        twoUpBracketLeftOnly: this.twoUpBracketLeftOnly,
        twoUpBracketRightOnly: this.twoUpBracketRightOnly
      }
    },
    isNormalInteger (str) {
      return /^\+?(0|[1-9]\d*)$/.test(str)
    },
    updateMultiLabels: debounce(function () {
      const changeList = this.gallery.changeList
      const items = this.gallery.items
      this.start = this.isNormalInteger(this.start)
        ? this.start - 0
        : this.start
      const generator = Lablr.pageLabelGenerator(this.labelerOpts())
      for (let i = 0; i < this.selectedTotal; i++) {
        const index = this.gallery.items
          .map(function (item) {
            return item.id
          })
          .indexOf(this.gallery.selected[i].id)
        // Allow unnumbered pages / flyleaves
        const caption = !this.start || this.start.length === 0
          ? ''
          : generator.next().value
        items[index].caption = caption

        if (changeList.indexOf(this.gallery.selected[i].id) === -1) {
          changeList.push(this.gallery.selected[i].id)
        }
      }

      this.$store.dispatch('updateChanges', changeList)
      this.$store.dispatch('updateItems', items)
    }, 300, { leading: false, trailing: true })
  }
}
</script>

<style lang="scss" scoped>
small {
  font-size: 1rem;
  font-weight: 400;
}
</style>
