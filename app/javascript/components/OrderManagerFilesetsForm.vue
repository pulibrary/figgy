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
        v-if="bracket"
        id="bracketLocation"
        v-model="bracketLocation"
        label="Bracket Location"
        :options="bracketLocationOpts"
        @change="updateMultiLabels()"
      />

      <input-select
        v-if="!isMultiVolume"
        id="labelMethod"
        v-model="method"
        label="Labeling Method"
        :options="methodOpts"
        @change="updateUnitLabel"
      />

      <input-select
        id="twoUp"
        v-model="twoUp"
        label="Two Up"
        :options="twoUpOpts"
        @change="updateMultiLabels()"
      />

      <input-text
        v-if="twoUp"
        id="twoUpSeparator"
        v-model="twoUpSeparator"
        label="Two-Up Separator"
        @input="updateMultiLabels()"
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
      frontLabel: 'r. ',
      backLabel: 'v. ',
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
      this.updateUnitLabel()
    }
  },
  methods: {
    updateUnitLabel () {
      // This should be generated with calculate() or watch()
      if (this.method === 'paginate') {
        this.unitLabel = 'p. '
      } else if (this.method === 'foliate') {
        this.unitLabel = 'f. '
      }
    },
    labelerOpts () {
      let unitLabel = this.unitLabel

      let frontLabel = this.method === 'paginate' ? '' : this.frontLabel
      let backLabel = this.method === 'paginate' ? '' : this.backLabel

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
        // Allow unnumbered pages / flyleaves
        let caption = !this.start || this.start.length === 0
          ? ''
          : generator.next().value
        items[index].caption = caption

        if (changeList.indexOf(this.gallery.selected[i].id) === -1) {
          changeList.push(this.gallery.selected[i].id)
        }
      }

      this.$store.dispatch('updateChanges', changeList)
      this.$store.dispatch('updateItems', items)
    }, 300, { 'leading': false, 'trailing': true })
  }
}
</script>

<style lang="scss" scoped>
small {
  font-size: 1rem;
  font-weight: 400;
}
</style>
