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
        v-model="labelerOpts.unitLabel"
        label="Label"
        placeholder="e.g., p."
        @input="updateMultiLabels()"
      />
      <input-text
        id="startNum"
        v-model="labelerOpts.start"
        label="Starting Numeral"
        placeholder="e.g., 10"
        @input="updateMultiLabels()"
      />
      <input-checkbox
        v-if="!isMultiVolume"
        v-model="labelerOpts.bracket"
        :options="addBracketOpts"
        @change="updateMultiLabels()"
      />

      <input-select
        v-if="!isMultiVolume"
        id="labelMethod"
        v-model="labelerOpts.method"
        label="Labeling Method"
        :options="methodOpts"
        @change="updateMultiLabels()"
      />

      <div
        v-if="labelerOpts.method === 'foliate'"
        class="lux-row"
      >
        <input-text
          id="frontLabel"
          v-model="labelerOpts.frontLabel"
          label="Front Label"
          placeholder="(recto)"
          @input="updateMultiLabels()"
        />
        <input-text
          id="backLabel"
          v-model="labelerOpts.backLabel"
          label="Back Label"
          placeholder="(verso)"
          @input="updateMultiLabels()"
        />
        <input-select
          v-if="!isMultiVolume"
          id="startWith"
          v-model="labelerOpts.startWith"
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
      labelerOpts: {
        start: '1',
        method: 'paginate',
        frontLabel: '',
        backLabel: '',
        startWith: 'front',
        unitLabel: 'p. ',
        bracket: false
      }
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
          checked: this.labelerOpts.bracket
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
  methods: {
    isNormalInteger (str) {
      return /^\+?(0|[1-9]\d*)$/.test(str)
    },
    updateMultiLabels () {
      let changeList = this.gallery.changeList
      let items = this.gallery.items
      this.labelerOpts.start = this.isNormalInteger(this.labelerOpts.start)
        ? this.labelerOpts.start - 0
        : this.labelerOpts.start
      let generator = Lablr.pageLabelGenerator(this.labelerOpts)
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
