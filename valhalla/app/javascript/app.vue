<template>
  <div id="filemanager">
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
  }
}
</script>

<style scope>
#app {
  font-family: 'Avenir', Helvetica, Arial, sans-serif;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
  text-align: center;
  color: #2c3e50;
  margin-top: 60px;
}

/* start presentation styles */

.layout {
  position: relative;
  height: 75vh;
  width: 100vw;
}

#filemanager {
  position: relative;
  height: 80vh;
  width: 98vw;
}

.actions {
  padding: 0 30px 0 30px;
  height: 100%;
  overflow-y: auto;
}

.sidePanel {
  position: absolute;
  top: 20px;
  right: 10px;
  height: 95%;
  width: 28.5%;
  border: 1px solid #ddd;
  border-radius: 4px;
}

.gallery {
  position: relative;
  top: 20px;
  left: 0;
  height: 95%;
  width: 70%;
  border-radius: 4px;
  border: 1px solid #ddd;
}

</style>
