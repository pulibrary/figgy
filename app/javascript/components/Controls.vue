<template>
  <div class="bg">
    <div class="controls">
      <div v-if="orderChanged" id="orderChangedIcon" class="alert alert-info" role="alert">
        <i class="fa fa-exchange"></i> Page order has changed.
      </div>
      <button @click="saveHandler" id="save_btn" type="button" class="btn btn-lg btn-primary" :disabled="isDisabled">
        Apply Changes
      </button>
      <a v-if="!hidden" :href="editLink" id="replace-file-button">Manage Page Files</a>
    </div>
    <h3 v-if="selectedTotal === 1" class="osd-title">Zoom <small>on the selected item</small></h3>
    <div v-if="selectedTotal === 1" class="osd-wrapper">
      <div class="osd">
        <div class="viewport" :id="viewerId"></div>
      </div>
    </div>
  </div>
</template>

<script>
import OpenSeadragon from 'openseadragon'
export default {
  name: 'controls',
  data: function () {
    return {
      viewer: null
    }
  },
  props: {
    viewerId: {
      type: String,
      default: 'viewer'
    }
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
    selected: function () {
      return this.$store.state.selected
    },
    editLink: function () {
      let link = ''
      if (!this.hidden) {
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
    selectedTotal () {
      return this.$store.state.selected.length
    },
    startPage: function () {
      return this.$store.state.startPage
    },
    thumbnail: function () {
      return this.$store.state.thumbnail
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
    initOSD: function () {
<<<<<<< HEAD
        if (this.viewer) {
          this.viewer.destroy()
          this.viewer = null
        }
        this.viewer = OpenSeadragon({
          id: this.viewerId,
          showNavigationControl: false,
          tileSources: [ this.selected[0].service + "/info.json" ]
        })
=======
      if (this.viewer) {
        this.viewer.destroy()
        this.viewer = null
      }
      this.viewer = OpenSeadragon({
        id: this.viewerId,
        showNavigationControl: false,
        tileSources: [ this.selected[0].service + "/info.json" ]
      })
>>>>>>> d8616123... adds lux order manager to figgy
    },
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
        thumbnail_id: this.thumbnail,
        id: this.id
      }
      this.$store.dispatch('saveState', body)
    }
  },
  updated: function () {
    if (this.selectedTotal === 1) {
      this.initOSD()
    }
  }
}
</script>

<!-- Add "scoped" attribute to limit CSS to this component only -->
<style>
#replace-file-button {
  padding: 1.5rem;
  display: inline-block;
}
.is-hidden {
  display: none;
}
.bg {
  background: #f9f9f9;
  margin-left: -30px;
  margin-right: -30px;
  padding: 20px;
  display: flex;
  flex-direction: column;
  height: 100%;
}

.osd {
  background: #fff;
  height: 100%;
  width: 100%;
}

.osd-wrapper {
  background: #fff;
  flex-basis: 40%;
  border-radius: 4px;
  border: 2px solid #9ecaed;
  box-shadow: 0 0 10px #9ecaed;
  padding: 10px;
}

h3.osd-title {
  font-size: 18px;
}

.viewport {
  height: 100%;
  width: 100%;
}

</style>
