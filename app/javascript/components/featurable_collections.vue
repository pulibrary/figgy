<template>
  <div class="form-group featurable-collections">
    <label class="form-control-label">{{ label }}</label>
    <input
      type="hidden"
      :name="inputName"
      value=""
    >
    <p
      v-if="featurableOptions.length === 0"
      class="form-text text-muted featurable-collections-empty"
    >
      {{ emptyMessage }}
    </p>
    <div
      v-for="option in featurableOptions"
      :key="option.id"
      class="form-check"
    >
      <input
        :id="`featurable_${option.id}`"
        v-model="selectedIds"
        type="checkbox"
        class="form-check-input"
        :name="inputName"
        :value="option.id"
      >
      <label
        class="form-check-label"
        :for="`featurable_${option.id}`"
      >
        {{ option.label }}
      </label>
    </div>
  </div>
</template>
<script>

export default {
  name: 'FeaturableCollections',
  props: {
    inputName: {
      type: String,
      required: true
    },
    collectionSelect: {
      type: String,
      required: true
    },
    label: {
      type: String,
      default: ''
    },
    emptyMessage: {
      type: String,
      default: ''
    },
    options: {
      type: Array,
      default: function () { return [] }
    },
    selected: {
      type: Array,
      default: function () { return [] }
    }
  },
  data: function () {
    return {
      selectedIds: [...this.selected],
      collectionSelectElement: null,
      selectedCollections: []
    }
  },
  computed: {
    // All non-collection options (options not from the Collection multi-select)
    nonCollectionOptions () {
      // Return early if the select element is not rendered to prevent errors on
      // intial page load.
      if (!this.collectionSelectElement) return this.options

      // Get an array of all of the Collections a resource could be a member of
      const allCollections = Array.from(this.collectionSelectElement.options).map((option) => option.value)

      // Return only the featurable options that are not Collections (e.g. EphemeraProject)
      return this.options.filter((option) => !allCollections.includes(option.id))
    },
    // Everything the resource could currently be highlighted in
    featurableOptions () {
      return this.selectedCollections.concat(this.nonCollectionOptions)
    }
  },
  mounted () {
    this.collectionSelectElement = document.querySelector(this.collectionSelect)
    // Get the currently selected collections
    this.readSelectedCollections()

    // Setup listener for collection dropdown and multi-select
    this.collectionSelectElement.addEventListener('change', this.readSelectedCollections)
    window.jQuery(this.collectionSelectElement).on('changed.bs.select', this.readSelectedCollections)
  },
  beforeUnmount () {
    // Clean up listeners
    this.collectionSelectElement.removeEventListener('change', this.readSelectedCollections)
    window.jQuery(this.collectionSelectElement).off('changed.bs.select', this.readSelectedCollections)
  },
  methods: {
    readSelectedCollections () {
      this.selectedCollections = Array.from(this.collectionSelectElement.selectedOptions)
        .map((option) => ({ id: option.value, label: option.text }))
    }
  }
}
</script>
