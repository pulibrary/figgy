<template>
  <div>
    <h2>Set Properties <small>for this <span v-if="isMultiVolume">multi-volume</span> resource</small></h2>
    <div class="row">
      <!-- Viewing Direction-->
      <div class="form-group col-md-6">
        <fieldset>
          <legend>Viewing Direction</legend>
          <div v-for="viewDir in viewDirs">
            <div class="radio">
              <label>
                <input class="viewDirInput" @change="updateViewDir($event)" v-model="viewingDirection" type="radio" name="viewDir" :value="viewDir.label">
                {{viewDir.label}}
              </label>
            </div>
          </div>
        </fieldset>
      </div>
      <!-- Viewing Hint-->
      <div v-if="!isMultiVolume" class="form-group col-md-6">
        <fieldset>
          <legend>Viewing Hint</legend>
          <div v-for="viewHint in viewHints">
            <div class="radio">
              <label>
                <input class="viewHintInput" @change="updateViewHint($event)" v-model="viewingHint" type="radio" name="viewHint" :value="viewHint.label">
                {{viewHint.label}}
              </label>
            </div>
          </div>
        </fieldset>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'resource-form',
  data: function () {
    return {
      viewDirs: [
        {label: "left-to-right"},
        {label: "right-to-left"},
        {label: "top-to-bottom"},
        {label: "bottom-to-top"},
      ],
      viewHints: [
        {label: "individuals"},
        {label: "paged"},
        {label: "continuous"}
      ]
    }
  },
  computed: {
    isMultiVolume: function () {
      return this.$store.state.isMultiVolume
    },
    viewingDirection: {
      get () {
        return this.$store.state.viewingDirection
      },
      set () {
        // need to have something here or Vue complains
      }
    },
    viewingHint: function () {
      return this.$store.state.viewingHint
    }
  },
  methods: {
    updateViewDir (event) {
      var value = event.target.value
      this.$store.dispatch('updateViewDir', value)
    },
    updateViewHint (event) {
      var value = event.target.value
      this.$store.dispatch('updateViewHint', value)
    }
  }
}
</script>

<!-- Add "scoped" attribute to limit CSS to this component only -->
<style scoped>

fieldset {
  margin: auto;
}

legend {
  font-size: 14px;
  margin: auto;
}

.radio label {
  margin: auto;
  padding-left: 30px;
}

</style>
