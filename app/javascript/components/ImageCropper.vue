<template>
  <div>
    <label>Banner Image URL</label>
    <input id="image-cropper-url" type="text" v-model="infoUrl" />
    <button type="button" class="btn btn-outline-secondary"
      @click="loadUrl($event)">Load</button>
  </div>
  <div>
    <div class="lux-osd">
      <div
        :id="viewerId"
        class="lux-viewport"
      />
    </div>
  </div>
</template>

<script>
/* here's another one
https://iiif-cloud.princeton.edu/iiif/2/51%2F13%2F9e%2F51139e35a5bc49ec9c474c8e6f4fbe0b%2Fintermediate_file/info.json
*/
import OpenSeadragon from 'openseadragon'
import { mapState } from 'vuex'
/**
 * This is the Persistence and Deep Zoom pieces of the Order Manager interface.
 * Note: use `yarn add openseadragon` for deep zoom to work.
 */
export default {
  name: 'Controls',
  status: 'ready',
  release: '1.0.0',
  type: 'Pattern',
  metaInfo: {
    title: 'OrderManager Controls',
    htmlAttrs: {
      lang: 'en'
    }
  },
  props: {
    /**
     * The html element name used for the component.
     */
    viewerId: {
      type: String,
      default: 'viewer'
    },
    url: {
      type: String,
      default: ''
    }
  },
  data: function () {
    return {
      viewer: null,
      osdId: this.viewerId,
      infoUrl: this.url
    }
  },
  computed: {
  },
  methods: {
    initOSD: function () {
      this.viewer = OpenSeadragon({
        id: this.osdId,
        showNavigationControl: false,
        tileSources: [this.infoUrl]
      })
    },

    loadUrl: function () {
      this.viewer.open(this.infoUrl)
    }
  },
  mounted: function () {
    this.initOSD()
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
.lux-bg {
  background: #f9f9f9;
  margin-left: -30px;
  margin-right: -30px;
  padding: 20px;
  display: flex;
  flex-direction: column;
  height: 100%;
}

.lux-osd {
  background: #fff;
  height: 300px;
  width: 450px;
}

.lux-osd-wrapper {
  background: #fff;
  flex-basis: 40%;
  border-radius: 4px;
  border: 2px solid #9ecaed;
  box-shadow: 0 0 10px #9ecaed;
  padding: 10px;
}

h3.lux-osd-title {
  font-size: 18px;
}

.lux-viewport {
  height: 100%;
  width: 100%;
}
</style>
