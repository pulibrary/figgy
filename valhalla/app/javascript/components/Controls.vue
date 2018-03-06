<template>
  <div class="bg">
    <div class="controls">
      <div v-if="orderChanged" id="orderChangedIcon" class="alert alert-info" role="alert">
        <i class="fa fa-exchange"></i> Page order has changed.
      </div>
      <button @click="saveHandler" id="save_btn" type="button" class="btn btn-lg btn-primary" :disabled="isDisabled">
        Apply Changes
      </button>
      <a :href="editLink" id="replace-file-button" v-bind:class="{'is-hidden' : hidden }">Manage Page Files</a>
    </div>
  </div>
</template>

<script>
export default {
  name: 'controls',
  data: {
    hidden: true
  },
  computed: {
    id: function () {
      return this.$store.state.id
    },
    resourceClassName: function () {
      return this.$store.state.resourceClassName
    },
    images: function () {
      return this.$store.state.images
    },
    editLink: function () {
      let link = ''
      if (!this.isEditDisabled) {
        link = '/catalog/parent/' + this.$store.state.id + '/' + this.$store.state.selected[0].id
      }
      return link
    },
    imageIdList: function () {
      return this.$store.getters.imageIdList
    },
    isMultiVolume: function () {
      return this.$store.state.isMultiVolume
    },
    thumbnail: function () {
      return this.$store.state.thumbnail
    },
    startPage: function () {
      return this.$store.state.startPage
    },
    viewingHint: function () {
      return this.$store.state.viewingHint
    },
    viewingDirection: function () {
      return this.$store.state.viewingDirection
    },
    changeList: function () {
      return this.$store.state.changeList
    },
    orderChanged: function () {
      return this.$store.getters.orderChanged
    },
    isDisabled: function () {
      if (this.$store.getters.stateChanged) {
        return false
      } else {
        return true
      }
    },
    hidden: function () {
      if (this.$store.getters.selectedTotal != 1) {
        return true
      } else {
        return false
      }
    },
    fileSetPayload: function () {
      var changed = this.images.filter(image => this.changeList.indexOf(image.id) !== -1 )
      var payload = changed.map((file) => {
        return {id: file.id, title: file.label, page_type: file.page_type }
      })
      return payload
    },
    volumePayload: function () {
      var changed = this.images.filter(image => this.changeList.indexOf(image.id) !== -1 )
      var payload = changed.map((file) => {
        return {id: file.id, title: file.label }
      })
      return payload
    }
  },
  methods: {
    saveHandler: function () {
      if (this.isMultiVolume) {
        this.saveMVW()
      } else {
        this.save()
      }
    },
    save: function () {
      let body = {
        resource : {},
        file_sets: this.fileSetPayload
      }
      body.resource[this.resourceClassName] = {
        member_ids: this.imageIdList,
        thumbnail_id: this.thumbnail,
        start_canvas: this.startPage,
        viewing_hint: this.viewingHint,
        viewing_direction: this.viewingDirection,
        id: this.id
      }
      this.$store.dispatch('saveState', body)
    },
    saveMVW: function () {
      let body = {
        resource : {},
        volumes: this.volumePayload
      }
      body.resource[this.resourceClassName] = {
        member_ids: this.imageIdList,
        viewing_direction: this.viewingDirection,
        id: this.id
      }
      this.$store.dispatch('saveState', body)
    }
  }
}
</script>

<!-- Add "scoped" attribute to limit CSS to this component only -->
<style>
#replace-file-button {
  padding: 1.5rem;
}
.is-hidden {
  display: none;
}
.bg {
  background: #f9f9f9;
  margin-left: -30px;
  margin-right: -30px;
  padding: 20px;
  overflow: hidden;
  height: 100%;
}


</style>
