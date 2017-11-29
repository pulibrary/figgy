<template>
  <div class="content">
    <div class="gallery_controls">
      Select:
      <button @click.capture="selectAll()" id="select_all_btn" class="btn btn-default btn-sm"><i class="fa fa-th"></i> All</button>
      <button @click.capture="selectNone()" id="select_none_btn" class="btn btn-default btn-sm"><i class="fa fa-th fa-inverse"></i> None</button>
      <button @click.capture="selectAlternate()" id="select_alternate_btn" class="btn btn-default btn-sm"><i class="fa fa-th fa-inverse"></i> Alternate</button>
      <button @click.capture="selectInverse()" id="select_inverse_btn" class="btn btn-default btn-sm"><i class="fa fa-th fa-inverse"></i> Inverse</button>
      <button @click.capture="uploadFile()" id="upload_file" class="btn btn-default btn-sm"><i class="fa fa-th fa-upload"></i> Upload File</button>
      <div id="img_sizer">
        <i class="fa fa-image"></i>
        <input @input="resizeThumbs($event)" style="display:inline-block;" type="range" min="40" max="400" value="200">
        <i class="fa fa-image fa-lg"></i>
      </div>
    </div>
    <draggable v-model="thumbnails" tag="div" name="list-complete" class="img_gallery">
        <div @click.capture="select(thumbnail.id, $event)"
              v-bind:style="{'max-width': thumbPixelWidth + 'px' }"
              class="thumbnail"
              v-bind:class="{ hasChanged: hasChanged(thumbnail.id), selected: isSelected(thumbnail) }"
              v-for="thumbnail in thumbnails" :key="thumbnail.id">
          <img :src="thumbnail.url" class="thumb">
          <div v-bind:style="{'padding': captionPixelPadding + 'px' }" class="caption">
            {{thumbnail.label}}
          </div>
        </div>
    </draggable>
  </div>
</template>

<script>
import draggable from 'vuedraggable'
export default {
  name: 'thumbnails',
  components: {
    draggable
  },
  data: function () {
    return {
      thumbPixelWidth: 200,
      captionPixelPadding: 9
    }
  },
  computed: {
    thumbnails: {
      get () {
        return this.$store.state.images
      },
      set (value) {
        this.$store.dispatch('sortImages', value)
      }
    }
  },
  methods: {
    getImageById: function (id) {
      var elementPos = this.getImageIndexById(id)
      return this.$store.state.images[elementPos]
    },
    getImageIndexById: function (id) {
      return this.$store.state.images.map(function (image) {
        return image.id
      }).indexOf(id)
    },
    select: function (id, event) {
      var selected = []
      if (event.metaKey) {
        selected = this.$store.state.selected
        selected.push(this.getImageById(id))
        this.$store.dispatch('handleSelect', selected)
      } else {
        if (this.$store.state.selected.length === 1 && event.shiftKey) {
          var first = this.getImageIndexById(this.$store.state.selected[0].id)
          var second = this.getImageIndexById(id)
          var min = Math.min(first, second)
          var max = Math.max(first, second)
          for (var i = min; i <= max; i++) {
            selected.push(this.$store.state.images[i])
          }
          this.$store.dispatch('handleSelect', selected)
        } else {
          this.$store.dispatch('handleSelect', [this.getImageById(id)])
        }
      }
    },
    selectAll: function () {
      this.$store.dispatch('handleSelect', this.$store.state.images)
    },
    selectAlternate: function () {
      var selected = []
      var imgTotal = this.$store.state.images.length
      for (var i = 0; i < imgTotal; i = i + 2) {
        selected.push(this.$store.state.images[i])
      }
      this.$store.dispatch('handleSelect', selected)
    },
    selectInverse: function () {
      var selected = []
      var imgTotal = this.$store.state.images.length
      for (var i = 1; i < imgTotal; i = i + 2) {
        selected.push(this.$store.state.images[i])
      }
      this.$store.dispatch('handleSelect', selected)
    },
    selectNone: function () {
      this.$store.dispatch('handleSelect', [])
    },
    hasChanged: function (id) {
      if (this.$store.state.changeList.indexOf(id) > -1) {
        return true
      } else {
        return false
      }
    },
    isSelected: function (thumbnail) {
      if (this.$store.state.selected.indexOf(thumbnail) > -1) {
        return true
      } else {
        return false
      }
    },
    resizeThumbs: function (event) {
      this.$data.thumbPixelWidth = event.target.value
      if (this.$data.thumbPixelWidth < 75) {
        this.$data.captionPixelPadding = 0
      } else {
        this.$data.captionPixelPadding = 9
      }
    },
    uploadFile: function (event) {
      document.getElementById('browse_everything').click();
    }
  }
}
</script>

<!-- Add "scoped" attribute to limit CSS to this component only -->
<style scoped>

.thumbnail {
  display: inline-block;
  max-width: 200px;
  margin: 10px;
}

.img_gallery {
  overflow: auto;
  height: calc(100% - 40px);
  border-radius: 4px;
  margin-bottom: 40px;
  clear: both;
}

.gallery_controls {
  postion: absolute;
  top: 0;
  width: 100%;
  height: 40px;
  padding: 5px;
  background: #ddd;
}

.gallery_controls button {
  margin-right: 5px;
}

.gallery_controls input[type=range] {
  width: auto;
  display: inline-block;
}

#img_sizer {
  display: inline-block;
  float: right;
  padding: 5px;
}

.selected {
  border: 2px solid #9ecaed;
  box-shadow: 0 0 10px #9ecaed;
}

.hasChanged {
  background-color: Tomato
}

.thumbnail .caption {
  pointer-events: none;
  overflow: hidden;
}

.thumb {
  pointer-events: none;
}

</style>
