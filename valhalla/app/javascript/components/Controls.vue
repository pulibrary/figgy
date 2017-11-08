<template>
  <div class="controls">
    <div v-if="orderChanged" id="orderChangedIcon" class="alert alert-info" role="alert">
      <i class="fa fa-exchange"></i> Page order has changed.
    </div>
    <button @click="save" id="save_btn" type="button" class="btn btn-lg btn-primary" :disabled="isDisabled">
      Save
    </button>
  </div>
</template>

<script>
export default {
  name: 'controls',
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
    imageIdList: function () {
      return this.$store.getters.imageIdList
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
    fileSetPayload: function () {
      var changed = this.images.filter(image => this.changeList.indexOf(image.id) !== -1 )
      var payload = changed.map((file) => {
        return {id: file.id, title: file.label, page_type: file.page_type }
      })
      return payload
    }
  },
  methods: {
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
    }
  }
}
</script>

<!-- Add "scoped" attribute to limit CSS to this component only -->
<style>

</style>
