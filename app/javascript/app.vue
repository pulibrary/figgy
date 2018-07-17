<template>
  <div id="order-manager">
    <heading level="h1">The quick brown fox</heading>
    <order-manager></order-manager>
    <transition name="fade">
      <div v-if="manifestLoading" class="overlay">
          <div class="loader"/>
      </div>
    </transition>

    <flash :timeout="5000" :display-icons="true" transition="fade"></flash>
    <sidepanel></sidepanel>
    <thumbnails></thumbnails>
  </div>
</template>

<script>
import Thumbnails from './components/Thumbnails'
import Sidepanel from './components/SidePanel'

export default {
  name: 'app',
  components: {
    Thumbnails,
    Sidepanel
  },
  computed: {
    manifestLoading: function () {
      return this.$store.state.manifestLoadState !== 'LOADED' ? true : false
    }
  }
}
</script>

<style scoped>


</style>
