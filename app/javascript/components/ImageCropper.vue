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
          <button type="button" class="btn btn-outline-secondary" @click="clearUrl">
            Clear
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
import OpenSeadragon from 'openseadragon'
import { parseUrl } from "../helpers/imageCropperHelpers.js"

const ASPECT_RATIO = 1.5

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
    },
    hiddenFieldId: {
      type: String,
      default: ''
    }
  },
  data: function () {
    const parsed = parseUrl(this.url)
    return {
      viewer: null,
      selector: null,
      infoUrl: parsed.infoUrl,
      initialRegion: parsed.savedRegion,
      imageSize: null
    }
  },
  mounted: async function () {
    // We need a global OSD for this plugin before we load it
    window.OpenSeadragon = OpenSeadragon
    await import('openseadragon-areaselector/src/areaselector.js')
    this.initOSD()
  },
  beforeUnmount: function () {
    if (this.viewer) this.viewer.destroy()
  },
  methods: {
    initOSD: function () {
      this.viewer = OpenSeadragon({
        id: this.viewerId,
        showNavigationControl: false,
        gestureSettingsMouse: { clickToZoom: false },
        preserveOverlays: true,
        tileSources: this.infoUrl ? [this.infoUrl] : []
      })
      this.viewer.addHandler('open', this.onOpen)
    },

    onOpen: function () {
      const item = this.viewer.world.getItemAt(0)
      this.imageSize = item.getContentSize()

      const initialImg = this.initialRegion
        ? this.fitAspect(this.initialRegion)
        : this.defaultRect()
      const initialViewPort = this.imageToViewportRect(initialImg)
      const boundaryViewport = this.imageToViewportRect({
        x: 0, y: 0, w: this.imageSize.x, h: this.imageSize.y
      })

      if (this.selector) {
        // Reset existing selector after hitting the load button
        this.selector.boundary = boundaryViewport
        this.selector.setLocation(initialViewPort)
      } else {
        this.selector = this.viewer.activateAreaSelector({
          rect: initialViewPort,
          boundary: boundaryViewport,
          handleSize: 12,
          handleOffset: 6,
          borderWidth: 2,
        })
        // Ensures the selector box is styled correctly
        this.selector.element.style.width = '100%'
        this.selector.element.style.height = '100%'
        this.selector.redraw()
        this.selector.addHandler('redraw', this.onRedraw)
      }

      this.updateHiddenField(initialImg)
    },

    // Default selector at the correct aspect ratio
    defaultRect: function () {
      const smallest = Math.min(this.imageSize.x, this.imageSize.y)
      let h = smallest / 2
      let w = h * ASPECT_RATIO
      if (w > this.imageSize.x) {
        w = this.imageSize.x
        h = w / ASPECT_RATIO
      }
      return {
        x: (this.imageSize.x - w) / 2,
        y: (this.imageSize.y - h) / 2,
        w,
        h
      }
    },

    // Recalculate selector rectangle so it conforms to aspect ratio
    fitAspect: function (rect) {
      let h = rect.h
      let w = h * ASPECT_RATIO
      if (w > this.imageSize.x) {
        w = this.imageSize.x
        h = w / ASPECT_RATIO
      }
      return { x: rect.x, y: rect.y, w, h }
    },

    // Ensure that the selector is always at the correct aspect ratio
    onRedraw: function () {
      // convert viewport coordinates to image coordinates
      const img = this.viewportToImageRect(this.selector.rect)
      const fixed = this.fitAspect(img)

      // If the fitAspect ratio changes the selector size by a minimum value,
      // then reset the selector location before updating the banner url
      if (Math.abs(fixed.w - img.w) > 0.5 || Math.abs(fixed.h - img.h) > 0.5) {
        this.selector.setLocation(this.imageToViewportRect(fixed))
        this.updateHiddenField(this.viewportToImageRect(this.selector.rect))
      } else {
        this.updateHiddenField(img)
      }
    },

    imageToViewportRect: function (r) {
      return this.viewer.viewport.imageToViewportRectangle(
        new OpenSeadragon.Rect(r.x, r.y, r.w, r.h)
      )
    },

    viewportToImageRect: function (viewportRect) {
      const r = this.viewer.viewport.viewportToImageRectangle(viewportRect)
      return { x: r.x, y: r.y, w: r.width, h: r.height }
    },

    updateHiddenField: function (rect) {
      if (!this.infoUrl) return
      // Round values to whole numbers
      const region = [
        Math.round(rect.x),
        Math.round(rect.y),
        Math.round(rect.w),
        Math.round(rect.h)
      ]
      const base = this.infoUrl.replace('info.json', '')
      const field = document.getElementById(this.hiddenFieldId)
      if (field) field.value = `${base}${region.join(',')}/full/0/default.jpg`
    },

    loadUrl: function () {
      const parsed = parseUrl(this.infoUrl)
      this.infoUrl = parsed.infoUrl
      this.initialRegion = parsed.savedRegion
      if (this.infoUrl) this.viewer.open(this.infoUrl)
    },

    clearUrl: function () {
      this.infoUrl = ''
      this.initialRegion = null
      const field = document.getElementById(this.hiddenFieldId)
      if (field) field.value = ''
      if (this.selector) {
        this.viewer.removeOverlay(this.selector.element)
        this.selector = null
      }
      this.viewer.close()
    },
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
  aspect-ratio: 1.5 / 1;
  min-height: 320px;
  overflow: hidden;
}

.osd-viewport {
  height: 100%;
  width: 100%;
}

// We need the :deep selector to override css in the osd plugin
// https://vuejs.org/api/sfc-css-features.html#deep-selectors
:deep(.openseadragon-areaselector) {
  // Set the selector color
  border-color: yellow !important;
}

</style>
