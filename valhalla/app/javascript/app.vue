<template>
  <div id="filemanager">
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
  overflow-y: hidden;
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

.alert-wrap {
  position: fixed;
  width: 500px;
  height: 200px;
  top: 200px;
  left: 50%;
  margin-top: -100px; /* Negative half of height. */
  margin-left: -250px; /* Negative half of width. */
  /* position: fixed;
  right: 25px;
  bottom: 25px; */
  z-index: 9999;
}


.loader,
.loader:after {
  border-radius: 50%;
  width: 10em;
  height: 10em;
}
.loader {
  display: inline-block;
  position: relative;
  float: left;
  top: 40%;
  left: 50%;
  transform: translate(-50%, -50%);
  text-indent: -9999em;
  border-top: 1.1em solid rgba(255, 255, 255, 0.2);
  border-right: 1.1em solid rgba(255, 255, 255, 0.2);
  border-bottom: 1.1em solid rgba(255, 255, 255, 0.2);
  border-left: 1.1em solid #ffffff;
  -webkit-transform: translateZ(0);
  -ms-transform: translateZ(0);
  transform: translateZ(0);
  -webkit-animation: load8 1.1s infinite linear;
  animation: load8 1.1s infinite linear;
}
@-webkit-keyframes load8 {
  0% {
    -webkit-transform: rotate(0deg);
    transform: rotate(0deg);
  }
  100% {
    -webkit-transform: rotate(360deg);
    transform: rotate(360deg);
  }
}
@keyframes load8 {
  0% {
    -webkit-transform: rotate(0deg);
    transform: rotate(0deg);
  }
  100% {
    -webkit-transform: rotate(360deg);
    transform: rotate(360deg);
  }
}

.overlay {
    position:absolute;
    top:0;
    left:0;
    right:0;
    bottom:0;
    background-color:rgba(0, 0, 0, 0.85);
    background: url(data:;base64,iVBORw0KGgoAAAANSUhEUgAAAAIAAAACCAYAAABytg0kAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAgY0hSTQAAeiYAAICEAAD6AAAAgOgAAHUwAADqYAAAOpgAABdwnLpRPAAAABl0RVh0U29mdHdhcmUAUGFpbnQuTkVUIHYzLjUuNUmK/OAAAAATSURBVBhXY2RgYNgHxGAAYuwDAA78AjwwRoQYAAAAAElFTkSuQmCC) repeat scroll transparent\9; /* ie fallback png background image */
    z-index:9999;
    color:white;
    border-radius: 4px;
}

.fade-enter-active, .fade-leave-active {
  transition: opacity .5s;
}
.fade-enter, .fade-leave-to /* .fade-leave-active below version 2.1.8 */ {
  opacity: 0;
}

</style>
