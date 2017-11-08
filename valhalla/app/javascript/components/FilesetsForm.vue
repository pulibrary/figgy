<template>
  <div>
    <h2>Generate Labels <small>for selected items</small></h2>
    <form class="formContent">
      <div class="row">
        <div class="form-group">
          <label class="control-label" for="unitLabel">Unit Label</label>
          <input @input="updateMultiLabels()" v-model="labelerOpts.unitLabel" type="text" name="unitLabel" id="unitLabel" value="" placeholder="p." class="form-control">
        </div>
        <div class="form-group">
          <label class="control-label" for="startNum">Starting Numeral</label>
          <input @input="updateMultiLabels()" v-model="labelerOpts.start" type="text" name="startNum" id="startNum" value="" placeholder="10" class="form-control">
        </div>
        <div class="form-group">
         <div class="checkbox">
           <label>
             <input @change="updateMultiLabels()" v-model="labelerOpts.bracket" name="addBrackets" id="addBrackets" type="checkbox" value="">
             <label for="addBrackets">Add Brackets</label>
           </label>
         </div>
        </div>
      </div>
      <div class="row">
        <div class="form-group">
          <label class="control-label" for="labelMethod">Labeling Method</label>
          <select @change="updateMultiLabels()" v-model="labelerOpts.method" id="labelMethod" class="form-control">
            <option value="paginate">Paginate (Default)</option>
            <option value="foliate">Foliate</option>
          </select>
        </div>
      </div>
      <div v-if="labelerOpts.method === 'foliate'" class="row">
        <fieldset>
          <div class="form-group">
            <label class="control-label" for="frontLabel">Front Label</label>
            <input @input="updateMultiLabels()" v-model="labelerOpts.frontLabel" type="text" name="frontLabel" id="frontLabel" value="" placeholder="(recto)" class="form-control">
          </div>
          <div class="form-group">
            <label class="control-label" for="backLabel">Back Label</label>
            <input @input="updateMultiLabels()" v-model="labelerOpts.backLabel" type="text" name="backLabel" id="backLabel" value="" placeholder="(verso)" class="form-control">
          </div>
          <div class="form-group">
            <label class="control-label" for="startWith">Start With</label>
            <select @change="updateMultiLabels()" v-model="labelerOpts.startWith" id="startWith" class="form-control">
              <option value="front">Front (Default)</option>
              <option value="back">Back</option>
            </select>
          </div>
        </fieldset>
      </div>
    </form>
  </div>
</template>

<script>
import Lablr from 'page-label-generator'

export default {
  name: 'filesets-form',
  data: function () {
    return {
      labelerOpts: {
        'start': '1',
        'method': 'paginate',
        'frontLabel': '',
        'backLabel': '',
        'startWith': 'front',
        'unitLabel': 'p. ',
        'bracket': false
      }
    }
  },
  computed: {
    selectedTotal () {
      return this.$store.state.selected.length
    }
  },
  methods: {
    isNormalInteger (str) {
      return /^\+?(0|[1-9]\d*)$/.test(str)
    },
    updateMultiLabels () {
      var changeList = this.$store.state.changeList
      var images = this.$store.state.images
      this.labelerOpts.start = this.isNormalInteger(this.labelerOpts.start) ? this.labelerOpts.start - 0 : this.labelerOpts.start
      var generator = Lablr.pageLabelGenerator(this.labelerOpts)
      for (let i = 0; i < this.selectedTotal; i++) {
        var index = this.$store.state.images.map(function (img) {
          return img.id
        }).indexOf(this.$store.state.selected[i].id)
        images[index].label = generator.next().value

        if (changeList.indexOf(this.$store.state.selected[i].id) === -1) {
          changeList.push(this.$store.state.selected[i].id)
        }
      }
      this.$store.dispatch('updateChanges', changeList)
      this.$store.dispatch('updateImages', images)
    }
  }
}
</script>

<!-- Add "scoped" attribute to limit CSS to this component only -->
<style scoped>

.form-inline fieldset {
  display: inline-block;
}

.form-inline .row {
  margin-top:15px;
}

.checkbox {
  display: block;
}

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
