<template>
  <div class="formPanel actions">
    <p v-if="selectedTotal === 0" id="noneSelected" class="formContent">No items selected.</p>
    <!-- Multiple Selected Form-->
    <div v-if="selectedTotal > 1" id="multiSelected" >
      <h2>Generate Labels <small>for selected items</small></h2>
      <form class="formContent form-inline">
        <!-- <div id="preview" class="row"><p class="text-muted">Example: <em>{{ example }}</em></p></div> -->
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
    <!-- Single Selected Form-->
      <form v-if="selectedTotal === 1" id="singleSelected" class="formContent form-horizontal">
        <div class="form-group">
          <label class="control-label" for="label">Label</label>
          <input @input="updateSingle()" v-model="singleForm.label" type="text" name="label" id="label" value="1" class="form-control">
        </div>
      <div class="form-group">
        <label class="control-label" for="pageType">Page Type</label>
        <select @change="updateSingle()" v-model="singleForm.pageType" id="pageType" class="form-control">
          <option value="single">Single Page (Default)</option>
          <option value="non-paged">Non-Paged</option>
          <option value="facing">Facing Pages</option>
        </select>
      </div>
      <div class="form-group">
        <div class="checkbox">
          <label>
            <input @change="updateThumbnail()" v-model="isThumbnail" id="isThumbnail" type="checkbox" value="">
            Set as Thumbnail <a href="#">(?)</a>
          </label>
      </div>
        <div class="checkbox">
          <label>
            <input @change="updateStartPage()" v-model="isStartPage" id="isStartPage" type="checkbox" value="">
            Set as Start Page <a href="#">(?)</a>
          </label>
        </div>
      </div>
      <input id="canvas_id" type="hidden" name="canvas_id">
    </form>
  </div>
</template>

<script>
import Lablr from 'page-label-generator'

export default {
  name: 'panel',
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
    },
    isStartPage () {
      var id = this.$store.state.selected[0].id
      return this.$store.state.startPage === id
    },
    isThumbnail () {
      var id = this.$store.state.selected[0].id
      return this.$store.state.thumbnail === id
    },
    singleForm () {
      return {
        label: this.$store.state.selected[0].label,
        id: this.$store.state.selected[0].id,
        pageType: this.$store.state.selected[0].pageType,
        url: this.$store.state.selected[0].url
      }
    }
  },
  methods: {
    isNormalInteger (str) {
      return /^\+?(0|[1-9]\d*)$/.test(str)
    },
    updateStartPage () {
      var startPage = this.$store.state.selected[0].id
      this.$store.dispatch('updateStartPage', startPage)
    },
    updateThumbnail () {
      var thumbnail = this.$store.state.selected[0].id
      this.$store.dispatch('updateThumbnail', thumbnail)
    },
    updateSingle () {
      var changeList = this.$store.state.changeList
      var images = this.$store.state.images
      var index = this.$store.state.images.map(function (img) {
        return img.id
      }).indexOf(this.$store.state.selected[0].id)
      images[index] = this.singleForm

      if (changeList.indexOf(this.$store.state.selected[0].id) === -1) {
        changeList.push(this.$store.state.selected[0].id)
      }

      this.$store.dispatch('updateChanges', changeList)
      this.$store.dispatch('updateImages', images)
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
<style>

.form-inline fieldset {
  display: inline-block;
}

.form-inline .row {
  margin-top:15px;
}

</style>
