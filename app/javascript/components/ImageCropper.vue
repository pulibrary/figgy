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
import * as AnnotoriousOSD from '@annotorious/openseadragon'
import '@annotorious/openseadragon/annotorious-openseadragon.css'
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
      anno: null,
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
        gestureSettingsMouse: {
          clickToZoom: false
        },
        gestureSettingsTouch: {
          pinchRotate: true
        },
        showRotationControl: true,
        tileSources: [this.infoUrl]
      })

      this.anno = AnnotoriousOSD.createOSDAnnotator(this.viewer, {
        autoSave: true,
        drawingEnabled: false,
      })

      this.viewer.addHandler('open', () => {
        const item = this.viewer.world.getItemAt(0);
        const size = item.getContentSize();
        const smallestSide = size['x'] > size['y'] ? size['y'] : size['x']
        const boxSize = smallestSide/2;
        const imageCenter = this.viewer.world.getItemAt(0).viewportToImageCoordinates(this.viewer.viewport.getCenter());

        const x = imageCenter['x'] - (boxSize/2)
        const y = imageCenter['y'] - (boxSize/2)
        this.anno.addAnnotation({
        id: 'annotation',
        target: {
          selector: {
            type: 'RECTANGLE',
            geometry: {
              bounds: {
                minX: x,
                minY: y,
                maxX: boxSize + x,
                maxY: boxSize + y
              },
              x,
              y,
              w: boxSize,
              h: boxSize,
            }
          }
        }});
        this.anno.setSelected('annotation');
      });
      this.anno.on('updateAnnotation', selected => this.updateArea(selected));
      this.anno.on('viewportIntersect', selected => this.updateArea(selected));
    },
    updateArea: function (selected) {
      const annotation = Array.isArray(selected) ? selected[0] : selected;
      const geometry = annotation['target']['selector']['geometry'];
      const x = geometry['x'] < 0 ? 0 : parseInt(geometry['x']);
      const y = geometry['y'] < 0 ? 0 : parseInt(geometry['y']);
      var region = [x, y, parseInt(geometry['w']), parseInt(geometry['h'])]
      let rotation = this.viewer.viewport.getRotation();
      // Note: rotation is broken, we probably want to get this from Annotorious and not the viewport
      console.log('rotation: ' + rotation)
      // if you rotate more than once the rotation is over 360.
      // If you click rotate 5 times, the result is 450, this is not in line with IIIF
      // if you rotate left the number is in negative, i.e. -90 for one click left
      rotation = rotation < 0 ? (rotation + (360 * (parseInt(Math.abs(rotation/360) + 1)))) : rotation - (360 * parseInt(rotation/360)) 
      rotation = rotation == 360 ? 0 : rotation;
      var region_url = `${this.infoUrl.replace("info.json", "")}${region.join(",")}/full/${Math.abs(rotation)}/default.jpg`
      console.log(region_url)
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
  height: 900px;
  width: 600px;
  border: solid black 2px;
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
