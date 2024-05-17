<template>
  <lux-wrapper class="lux-bg">
    <div class="lux-controls">
      <lux-alert
        v-if="orderChanged"
        status="info"
      >
        Page order has changed.
      </lux-alert>
      <lux-input-button
        id="save_btn"
        variation="solid"
        size="medium"
        :disabled="isDisabled"
        @button-clicked="saveHandler($event)"
      >
        Apply Changes
      </lux-input-button>
      <a
        v-if="!hidden"
        id="replace-file-button"
        :href="editLink"
      >
        Manage Page Files
      </a>
    </div>
    <lux-heading
      v-if="selectedTotal === 1"
      level="h2"
    >
      Zoom <small>on the selected item</small>
    </lux-heading>
    <div
      v-if="selectedTotal === 1"
      class="lux-osd-wrapper"
    >
      <div class="lux-osd">
        <div
          :id="viewerId"
          class="lux-viewport"
        />
      </div>
    </div>
  </lux-wrapper>
</template>

<script>
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
    type: {
      type: String,
      default: 'div'
    },
    viewerId: {
      type: String,
      default: 'viewer'
    },
    selected: {
      type: Array,
      default: []
    }
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
      gallery: state => state.gallery
    }),
    editLink: function () {
      let link = ''
      if (!this.hidden) {
        link = '/catalog/parent/' + this.resource.id + '/' + this.gallery.selected[0].id
      }
      return link
    },
    isMultiVolume: function () {
      return this.resource.isMultiVolume
    },
    isDisabled: function () {
      if (this.resource.saveState === 'SAVING') {
        return true
      } else if (this.$store.getters.stateChanged) {
        return false
      } else {
        return true
      }
    },
    orderChanged: function () {
      return this.$store.getters.orderChanged
    },
    payloadFileset: function () {
      const changed = this.gallery.items.filter(item => this.gallery.changeList.indexOf(item.id) !== -1)
      const payload = changed.map(file => {
        return { id: file.id, title: file.title, page_type: file.viewingHint }
      })
      return payload
    },
    payloadVolume: function () {
      const changed = this.gallery.items.filter(item => this.gallery.changeList.indexOf(item.id) !== -1)
      const payload = changed.map(file => {
        return { id: file.id, title: file.title }
      })
      return payload
    },
    resourceClassName: function () {
      return this.resource.resourceClassName
    },
    selectedTotal () {
      return this.gallery.selected.length
    },
  },
  updated: function () {
    if (this.selected.length === 1) {
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
        tileSources: [this.gallery.selected[0].service + '/info.json']
      })
    },
    hidden: function () {
      if (this.selectedTotal !== 1) {
        return true
      } else {
        return false
      }
    },
    galleryToFileset: function (items) {
      const members = items.filter(item => this.gallery.changeList.indexOf(item.id) > -1).map(item => {
        return { id: item.id, label: item.caption, viewingHint: item.viewingHint }
      })
      return members
    },
    galleryToResource: function (items) {
      const members = items.map(item => {
        return item.id
      })
      return members
    },
    saveHandler: function (event) {
      if (this.isMultiVolume) {
        this.saveMVW()
      } else {
        this.save()
      }
    },
    save: function () {
      const resource = {}
      resource.body = {
        id: this.resource.id,
        viewingDirection: this.resource.viewingDirection
          ? this.resource.viewingDirection.replace(/-/g, '').toUpperCase()
          : this.resource.viewingDirection,
        viewingHint: this.resource.viewingHint,
        startPage: this.resource.startCanvas,
        thumbnailId: this.resource.thumbnail,
        memberIds: this.galleryToResource(this.gallery.items)
      }
      resource.filesets = []
      const membersBody = this.galleryToFileset(this.gallery.items)
      const memberNum = membersBody.length
      for (let i = 0; i < memberNum; i++) {
        resource.filesets.push(membersBody[i])
      }
      this.$store.dispatch('saveStateGql', resource)
    },
    saveMVW: function () {
      const body = {
        resource: {},
        volumes: this.payloadVolume
      }
      body.resource[this.resourceClassName] = {
        member_ids: this.imageIdList,
        viewing_direction: this.viewingDirection,
        thumbnail_id: this.thumbnail,
        id: this.id
      }
      this.$store.dispatch('saveStateGql', body)
    }
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
}

h3.lux-osd-title {
  font-size: 18px;
}

.lux-viewport {
  height: 100%;
  width: 100%;
}
</style>
