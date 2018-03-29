<template>
  <div class="gallery" @click.capture="deselect($event)">
    <div class="gallery_controls">
      <button v-if="!isMultiVolume" @click.capture="uploadFile()" id="upload_file_btn" class="btn btn-default btn-sm"><i class="fa fa-th fa-upload"></i> Upload Files</button>
      <button v-if="pendingUploads" @click.capture="refreshPage()" id="refresh_page_btn" class="btn btn-default btn-sm"><i class="fa fa-th fa-clock-o"></i> Pending Uploads (Refresh)</button>
      <div class="dropdown">
        <button class="btn btn-default btn-sm dropdown-toggle" type="button" id="selectOptions" data-toggle="dropdown" aria-haspopup="true" aria-expanded="true">
          Selection Options
          <span class="caret"></span>
        </button>
        <ul class="dropdown-menu" aria-labelledby="selectOptions">
          <li><a @click.capture="selectAll()" id="select_all_btn">All</a></li>
          <li><a @click.capture="selectNone()" id="select_none_btn">None</a></li>
          <li><a @click.capture="selectAlternate()" id="select_alternate_btn">Alternate</a></li>
          <li><a @click.capture="selectInverse()" id="select_inverse_btn">Inverse</a></li>
        </ul>
      </div>
      <div v-if="selected.length" class="dropdown">
        <button class="btn btn-default btn-sm dropdown-toggle" type="button" id="withSelected" data-toggle="dropdown" aria-haspopup="true" aria-expanded="true">
          With selected &hellip;
          <span class="caret"></span>
        </button>
        <ul class="dropdown-menu" aria-labelledby="withSelected">
          <li v-bind:class="{ disabled: isCutDisabled() }"><a @click="cutSelected()" id="cut_btn">Cut</a></li>
          <li v-bind:class="{ disabled: isPasteDisabled() }"><a @click="paste(-1)" id="paste_before_btn">Paste Before</a></li>
          <li v-bind:class="{ disabled: isPasteDisabled() }"><a @click="paste(1)" id="paste_after_btn">Paste After</a></li>
        </ul>
      </div>
      <div id="img_sizer">
        <i class="fa fa-image"></i>
        <input @input="resizeThumbs($event)" id="resize_thumbs_input" style="display:inline-block;" type="range" min="40" max="400" value="200">
        <i class="fa fa-image fa-lg"></i>
      </div>
    </div>
    <draggable v-model="thumbnails" tag="div" name="list-complete" class="img_gallery">
        <div @click.capture="select(thumbnail.id, $event)"
              v-bind:style="{'max-width': thumbPixelWidth + 'px' }"
              class="thumbnail"
              v-bind:class="{ hasChanged: hasChanged(thumbnail.id), selected: isSelected(thumbnail), cut: isCut(thumbnail) }"
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
  created: function () {
    var browse_everything = document.getElementById('file-manager-browse-everything')
    var elms = []
    if (browse_everything) {
      elms = [...document.getElementById('file-manager-browse-everything').getElementsByTagName('tr')]
    }
    if (elms.length) {
      this.pendingUploads = true
    }
  },
  components: {
    draggable
  },
  data: function () {
    return {
      thumbPixelWidth: 200,
      captionPixelPadding: 9,
      pendingUploads: false
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
    },
    changeList: {
      get () {
        return this.$store.state.changeList
      }
    },
    isMultiVolume: function () {
      return this.$store.state.isMultiVolume
    },
    selected: {
      get () {
        return this.$store.state.selected
      }
    },
    cut: {
      get () {
        return this.$store.state.cut
      }
    }
  },
  methods: {
    cutSelected: function () {
      this.$store.dispatch('handleCut', this.selected)
      this.selectNone()
    },
    paste: function (indexModifier) {
      let thumbnails = this.thumbnails
      thumbnails = thumbnails.filter(val => !this.cut.includes(val))
      let pasteAfterIndex = this.getImageIndexById(this.selected[this.selected.length-1].id) + indexModifier
      thumbnails.splice(pasteAfterIndex, 0, ...this.cut)
      this.$store.dispatch('handlePaste', thumbnails)
      this.resetCut()
      this.selectNone()
    },
    resetCut: function () {
      this.$store.dispatch('handleCut', [])
    },
    deselect: function (event) {
      if (event.target.className === 'img_gallery') {
        this.selectNone()
      }
    },
    getImageById: function (id) {
      var elementPos = this.getImageIndexById(id)
      return this.thumbnails[elementPos]
    },
    getImageIndexById: function (id) {
      return this.thumbnails.map(function (image) {
        return image.id
      }).indexOf(id)
    },
    hasChanged: function (id) {
      return this.changeList.indexOf(id) > -1
    },
    isCut: function (thumbnail) {
      return this.cut.indexOf(thumbnail) > -1
    },
    isSelected: function (thumbnail) {
      return this.selected.indexOf(thumbnail) > -1
    },
    isCutDisabled: function () {
      return !!this.cut.length
    },
    isPasteDisabled: function () {
      return !(this.cut.length && this.selected.length)
    },
    resizeThumbs: function (event) {
      this.thumbPixelWidth = event.target.value
      if (this.thumbPixelWidth < 75) {
        this.captionPixelPadding = 0
      } else {
        this.captionPixelPadding = 9
      }
    },
    select: function (id, event) {
      event.stopPropagation()
      if (!this.isCut(this.getImageById(id))) { // can't select cut thumbnail
        var selected = []
        if (event.metaKey) {
          selected = this.selected
          selected.push(this.getImageById(id))
          this.$store.dispatch('handleSelect', selected)
        } else {
          if (this.selected.length === 1 && event.shiftKey) {
            var first = this.getImageIndexById(this.selected[0].id)
            var second = this.getImageIndexById(id)
            var min = Math.min(first, second)
            var max = Math.max(first, second)
            for (var i = min; i <= max; i++) {
              selected.push(this.thumbnails[i])
            }
            this.$store.dispatch('handleSelect', selected)
          } else {
            this.$store.dispatch('handleSelect', [this.getImageById(id)])
          }
        }
      }
    },
    selectAll: function () {
      this.$store.dispatch('handleSelect', this.thumbnails)
    },
    selectAlternate: function () {
      var selected = []
      var imgTotal = this.thumbnails.length
      for (var i = 0; i < imgTotal; i = i + 2) {
        selected.push(this.thumbnails[i])
      }
      this.$store.dispatch('handleSelect', selected)
    },
    selectInverse: function () {
      var selected = []
      var imgTotal = this.thumbnails.length
      for (var i = 1; i < imgTotal; i = i + 2) {
        selected.push(this.thumbnails[i])
      }
      this.$store.dispatch('handleSelect', selected)
    },
    selectNone: function () {
      this.$store.dispatch('handleSelect', [])
    },
    refreshPage: function () {
      if (this.$store.getters.stateChanged) {
        if (window.confirm("You have unsaved changes that will be lost on refresh. Do you really want to refresh?")) {
          window.location.reload(true)
        }
      } else {
        window.location.reload(true)
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

.cut {
  opacity: 0.2;
}

.thumbnail .caption {
  pointer-events: none;
  overflow: hidden;
}

.thumb {
  pointer-events: none;
}

.dropdown-menu li {
  cursor: default;
}

.dropdown {
  display: inline-block;
}
</style>
