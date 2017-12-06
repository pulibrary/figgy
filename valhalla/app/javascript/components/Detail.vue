<template>
  <div class="sidebar">
    <div id="detail" class="actions">
      <img id="detail_img" :src="selectedImageUrl"></img>
    </div>
  </div>
</template>

<script>
export default {
  name: 'detail',
  computed: {
    selected: {
      get () {
        return this.$store.state.selected
      }
    },
    selectedImageUrl: function () {
      return this.selected.length === 1 ? this.selected[0].url : ''
    }
  }
}
</script>

<!-- Add "scoped" attribute to limit CSS to this component only -->
<style scoped>
#detail {
  height: 100%;
  padding: 15px;
}

#detail img {
  height: 100%;
}
</style>
