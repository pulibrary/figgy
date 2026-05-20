<template>
  <div class="image-cropper">
    <div class="form-group">
      <label for="image-cropper-url">Banner image source</label>
      <div class="input-group">
        <input
          id="image-cropper-url"
          v-model="infoUrl"
          type="text"
          class="form-control"
          placeholder="IIIF info.json or image URL"
        />
        <div class="input-group-append">
          <button type="button" class="btn btn-outline-secondary" @click="loadUrl($event)">
            Load
          </button>
        </div>
      </div>
      <small class="form-text text-muted">
        Drag the highlighted rectangle to choose the crop region.
      </small>
    </div>

    <div class="osd-container">
      <div :id="viewerId" class="osd-viewport" />
    </div>
  </div>
</template>

<script>

import * as AnnotoriousOSD from '@annotorious/openseadragon'
import '@annotorious/openseadragon/annotorious-openseadragon.css'
import OpenSeadragon from 'openseadragon'
import { mapState } from 'vuex'

const ASPECT_RATIO = 1.5
const CROP_ANNOTATION_ID = 'crop-annotation'

function parseUrl (raw) {
  if (!raw) return { infoUrl: '', savedRegion: null }

  if (raw.endsWith('/info.json')) {
    return { infoUrl: raw, savedRegion: null }
  }

  let rawComponents = raw.split("/")
  let iiifComponents = rawComponents.slice(-4)
  let urlComponents = rawComponents.slice(0, -4)
  const infoUrl = `${urlComponents.join("/")}/info.json`
  const region = iiifComponents[0].split(",")

  // IIIF region has x,y,w,h
  if (region.length === 4) {
    return {
      infoUrl: infoUrl,
      savedRegion: {
        x: parseInt(region[0], 10),
        y: parseInt(region[1], 10),
        w: parseInt(region[2], 10),
        h: parseInt(region[3], 10)
      }
    }
  }

  // No region, just return URL
  return { infoUrl: infoUrl, savedRegion: null }
}

export default {
  name: 'ImageCropper',
  status: 'ready',
  release: '1.0.0',
  type: 'Pattern',
  metaInfo: {
    title: 'IIIF ImageCropper',
    htmlAttrs: {
      lang: 'en'
    }
  },
  props: {
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
    const parsed = parseUrl(this.url)
    return {
      anno: null,
      viewer: null,
      osdId: this.viewerId,
      infoUrl: parsed.infoUrl,
      initialRegion: parsed.savedRegion,
      imageSize: null,
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
        tileSources: this.infoUrl ? [this.infoUrl] : []
      })

      this.anno = AnnotoriousOSD.createOSDAnnotator(this.viewer, {
        autoSave: true,
        drawingEnabled: false,
      })

      this.viewer.addHandler('open', () => {
        // Clear any previous annotations
        this.anno.clearAnnotations();

        const item = this.viewer.world.getItemAt(0);
        const size = item.getContentSize();
        this.imageSize = size;
        let x, y, w, h
        if (this.initialRegion) {
          // Restore the saved crop
          ({ x, y, w, h } = this.initialRegion)
        } else {
          // Generate default crop selector with proper aspect ratio
          const smallestSide = size['x'] > size['y'] ? size['y'] : size['x']
          h = smallestSide / 2
          w = h * ASPECT_RATIO
          if (w > size['x']) {
            w = size['x']
            h = w / ASPECT_RATIO
          }
          const imageCenter = item.viewportToImageCoordinates(this.viewer.viewport.getCenter());
          x = imageCenter['x'] - (w / 2)
          y = imageCenter['y'] - (h / 2)
        }

        this.anno.addAnnotation(this.buildAnnotation(x,y,w,h))
        this.anno.setSelected(CROP_ANNOTATION_ID);
      });
      this.anno.on('updateAnnotation', selected => this.updateAnnotationHandler(selected));
    },

    buildAnnotation: function (x,y,w,h) {
      return {
        id: CROP_ANNOTATION_ID,
        target: {
          selector: {
            type: 'RECTANGLE',
            geometry: {
              bounds: {
                minX: x,
                minY: y,
                maxX: w + x,
                maxY: h + y
              },
              x,
              y,
              w,
              h,
            }
          }
        }
      }
    },

    updateAnnotationHandler: function () {
      this.clampAnnotation()
      this.updateCollectionBannerUrl()
    },

    clampAnnotation: function () {
      const annotation = this.anno.getAnnotationById(CROP_ANNOTATION_ID);
      const geometry = annotation['target']['selector']['geometry'];

      // Set height so it is no larger than the image size
      let h = Math.min(geometry.h, this.imageSize.y)

      // Calculate the width from the aspect ratio
      let w = h * ASPECT_RATIO

      // Adjust the width and height if the width is larger than the image size
      if (w > this.imageSize.x) {
        w = this.imageSize.x
        h = w / ASPECT_RATIO
      }

      // Keep the crop selector within the bounds of the image
      // See: https://github.com/dominictobias/react-image-crop/blob/master/src/utils.ts#L11
      // See: https://github.com/dominictobias/react-image-crop/blob/master/src/utils.ts#L123
      const x = Math.min(Math.max(geometry.x, 0), this.imageSize.x - w)
      const y = Math.min(Math.max(geometry.y, 0), this.imageSize.y - h)

      // Update the annotation with new values
      const newAnnotation = this.buildAnnotation(x, y, w, h)
      this.anno.updateAnnotation(newAnnotation)
    },

    updateCollectionBannerUrl: function () {
      const annotation = this.anno.getAnnotationById(CROP_ANNOTATION_ID);
      const geometry = annotation['target']['selector']['geometry'];
      const x = geometry['x'] < 0 ? 0 : parseInt(geometry['x']);
      const y = geometry['y'] < 0 ? 0 : parseInt(geometry['y']);
      const region = [x, y, parseInt(geometry['w']), parseInt(geometry['h'])]
      const region_url = `${this.infoUrl.replace("info.json", "")}${region.join(",")}/full/0/default.jpg`
      document.getElementById('collection_banner_image_url').value = region_url
    },

    loadUrl: function () {
      const parsed = parseUrl(this.infoUrl)
      this.infoUrl = parsed.infoUrl
      this.initialRegion = parsed.savedRegion
      if (this.infoUrl) this.viewer.open(this.infoUrl)
    }
  },
  mounted: function () {
    this.initOSD()
  }
}
</script>

<style lang="scss" scoped>
.image-cropper {
  margin-bottom: 1rem;
}

.osd-container {
  background: #f8f9fa;
  border: 1px solid #ced4da;
  border-radius: 0.25rem;
  width: 100%;
  // Match the 1.5:1 banner aspect ratio so the viewport echoes the saved crop.
  aspect-ratio: 1.5 / 1;
  min-height: 320px;
  overflow: hidden;
}

.osd-viewport {
  height: 100%;
  width: 100%;
}
</style>
