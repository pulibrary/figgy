<template>
  <div>
    <h2>Edit <small>the selected item</small></h2>
    <div class="row">
      <div class="col-md-12">
        <form class="formContent form-inline">
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
          <br/>
          <div class="form-group">
            <div class="checkbox">
              <label>
                <input @change="updateThumbnail()" v-model="isThumbnail" id="isThumbnail" type="checkbox" :value="thumbnail">
                Set as Thumbnail</a>
              </label>
            </div>
            <div class="checkbox">
              <label>
                <input @change="updateStartPage()" v-model="isStartPage" id="isStartPage" type="checkbox" :value="startPage">
                Set as Start Page</a>
              </label>
            </div>
          </div>
          <input id="canvas_id" type="hidden" name="canvas_id">
        </form>
      </div>
      <div class="col-md-12">
          <a :href="singleForm.editLink" id="replace-file-button" class="btn btn-default btn-lg">Replace or Delete File</a>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'fileset-form',
  computed: {
    thumbnail: function () {
      return this.$store.state.thumbnail
    },
    startPage: function () {
      return this.$store.state.startPage
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
        url: this.$store.state.selected[0].url,
        editLink: '/catalog/parent/' + this.$store.state.id + '/' + this.$store.state.selected[0].id
      }
    }
  },
  methods: {
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

#singleSelected .form-group {
  line-height: 3em;
}

.checkbox {
  display: block;
}

#replace-file-button {
  margin-bottom: 10px;
}

</style>
