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
      var changed = this.$store.state.images.filter(image => this.$store.state.changeList.indexOf(image.id) !== -1 )
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
      body.resource[this.$store.state.resourceClassName] = {
        member_ids: this.$store.getters.imageIdList,
        thumbnail_id: this.$store.state.thumbnail,
        start_canvas: this.$store.state.startPage,
        viewing_hint: this.$store.state.viewingHint,
        viewing_direction: this.$store.state.viewingDirection,
        id: this.$store.state.id
      }
      this.$store.dispatch('saveState', body)
    }
  }
}
</script>

<!-- Add "scoped" attribute to limit CSS to this component only -->
<style>

</style>
