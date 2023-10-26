<template>
  <wrapper style="max-width:100%;">
    <div class="lux-modal">
      <heading level="h2">
        Zoom <small>on the item</small>
        <input-button
          @button-clicked="hideZoom()"
          class="expand-collapse"
          type="button"
          variation="icon"
          size="small"
          icon="denied"
        />
      </heading>
      <div class="lux-osd-wrapper">
        <div class="lux-osd">
          <div
            :id="viewerId"
            class="lux-viewport"
          />
        </div>
      </div>
    </div>
  </wrapper>
</template>

<script>
import OpenSeadragon from 'openseadragon'
import { mapState } from 'vuex'
/**
 * This is the Persistence and Deep Zoom pieces of the Order Manager interface.
 * Note: use `yarn add openseadragon` for deep zoom to work.
 */
export default {
  name: 'DeepZoom',
  status: 'ready',
  release: '1.0.0',
  type: 'Pattern',
  metaInfo: {
    title: 'Deep Zoom',
    htmlAttrs: {
      lang: 'en'
    }
  },
  props: {
    /**
     * The html element name used for the component.
     */
    type: {
      type: String,
      default: 'div'
    },
    viewerId: {
      type: String,
      default: 'viewer'
    },
    resourceId: {
      type: String,
      default: ''
    },
  },
  data: function () {
    return {
      viewer: null,
      osdId: this.viewerId
    }
  },
  computed: {
    ...mapState({
      resource: state => state.ordermanager.resource,
      tree: state => state.tree,
      gallery: state => state.gallery,
      zoom: state => state.zoom,
    }),
    resourceClassName: function () {
      return this.resource.resourceClassName
    },
    selectedTotal () {
      return this.gallery.selected.length
    },
    zoomed () {
      return this.zoom.zoomed
    }
  },
  updated: function () {
    if (this.zoomed) {
      console.log("zoomed!")
      this.initOSD()
    }
  },
  methods: {
    initOSD: function () {
      if (this.viewer) {
        this.viewer.destroy()
        this.viewer = null
      }
      this.viewer = OpenSeadragon({
        id: this.osdId,
        showNavigationControl: false,
        tileSources: [this.zoom.zoomed.service + '/info.json']
      })
    },
    hideZoom: function () {
      this.$store.commit("RESET_ZOOM")
    },
    hidden: function () {
      if (this.selectedTotal !== 1) {
        return true
      } else {
        return false
      }
    },
  }
}
</script>

<style lang="scss" scoped>
small {
  font-size: 1rem;
  font-weight: 400;
}
#replace-file-button {
  padding: 1.5rem;
  display: inline-block;
}
.lux-is-hidden {
  display: none;
}

.lux-modal {
  background: #FFFFFF;
  padding: 1em;
}

.lux-osd {
  background: #fff;
  height: 100%;
  width: 100%;
}

.lux-osd-wrapper {
  background: #fff;
  flex-basis: 40%;
  border-radius: 4px;
  border: 2px solid #9ecaed;
  box-shadow: 0 0 10px #9ecaed;
  padding: 10px;
  height: 20em;
  width: 100%;
  margin: 0;
}

h3.lux-osd-title {
  font-size: 18px;
}

.lux-viewport {
  height: 100%;
  width: 100%;
}
</style>
