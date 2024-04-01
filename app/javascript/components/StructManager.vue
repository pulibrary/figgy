<template>
  <div class="lux-structManager">
    <transition name="fade">
      <div
        v-if="saving"
        class="lux-overlay"
      >
        <loader size="medium" />
      </div>
    </transition>
    <alert
      v-if="saved"
      status="success"
      type="alert"
      autoclear
      dismissible
      class="alert"
    >
      Your work has been saved!
    </alert>
    <alert
      v-if="saveError"
      status="error"
      type="alert"
      autoclear
      dismissible
      class="alert"
    >
      Sorry, there was a problem saving your work!
    </alert>
    <toolbar
      @cards-resized="resizeCards($event)"
    />
    <deep-zoom
      v-if="zoomed"
      viewer-id="viewer"
      class="deep-zoom">
    </deep-zoom>
    <div
      class="lux-sidePanel"
    >
      <div class="panelHeader">
        <heading level="h2" size="h6">Logical Structure</heading>
      </div>
      <tree :json-data="tree.structure"></tree>
    </div>
    <div
      class="lux-galleryPanel"
      >
      <div class="panelHeader">
        <heading level="h2" size="h6">Unstructured Files</heading>
      </div>
      <struct-gallery
        class="lux-galleryWrapper"
        :card-pixel-width="cardPixelWidth"
        :gallery-items="galleryItems"
        @card-clicked="galleryClicked()"
      />
    </div>
  </div>
</template>

<script>
import { mapState } from 'vuex'
import Toolbar from '@components/StructManagerToolbar.vue'
import Tree from '@components/Tree.vue'
import StructGallery from '@components/StructGallery.vue'
import DeepZoom from '@components/DeepZoom.vue'

/**
 * StructureManager is a tool for giving structure to a complex object (a book, CD, multi-volume work, etc.).
 * Complex patterns like StructureManager come with their own Vuex store that it needs to manage state.
 *
 * However you will still need to load the corresponding
 * Vuex module, *resourceModule*. Please see [the state management documentation](/#!/State%20Management) for how to manage state in complex patterns.
 */
export default {
  name: 'StructManager',
  status: 'ready',
  release: '1.0.0',
  type: 'Pattern',
  components: {
    'toolbar': Toolbar,
    'tree': Tree,
    'deep-zoom': DeepZoom,
    'struct-gallery': StructGallery,
  },
  props: {
    /**
     * The resource object in json format.
     */
    resourceObject: {
      type: Object,
      default: null
    },
    /**
     * The structure object in json format.
     */
    structure: {
     type: Object,
     default: null
    },
    /**
     * The resource id. Requires host app to have async lookup of resource.
     */
    resourceId: {
      type: String,
      default: null
    },
    defaultThumbnail: {
      type: String,
      default: 'https://picsum.photos/600/300/?random'
    }
  },
  data: function () {
    return {
      end_nodes: [],
      cardPixelWidth: 300,
      captionPixelPadding: 9,
      ga: null,
      s: null,
      id: this.resourceId,
    }
  },
  computed: {
    galleryItems () {
      return this.resource.members.map(member => ({
        id: member.id,
        caption: member.label,
        service:
          member['thumbnail'] && typeof (member.thumbnail.iiifServiceUrl) !== 'undefined'
            ? member.thumbnail.iiifServiceUrl
            : this.defaultThumbnail,
        mediaUrl:
          member['thumbnail'] && typeof (member.thumbnail.iiifServiceUrl) !== 'undefined'
            ? member.thumbnail.iiifServiceUrl + '/full/300,/0/default.jpg'
            : this.defaultThumbnail,
        viewingHint: member.viewingHint
      }))
    },
    selectedTotal () {
      return this.gallery.selected.length
    },
    selectedTreeNode () {
      return this.tree.selected
    },
    ...mapState({
      resource: state => state.ordermanager.resource,
      tree: state => state.tree,
      gallery: state => state.gallery,
      zoom: state => state.zoom,
    }),
    zoomed: function () {
      return this.zoom.zoomed
    },
    loaded: function () {
      return this.resource.loadState === 'LOADED'
    },
    loading: function () {
      return this.resource.loadState !== 'LOADED'
    },
    saved () {
      return this.tree.saveState === 'SAVED'
    },
    saveError () {
      return this.tree.saveState === 'ERROR'
    },
    saving () {
      return this.tree.saveState === 'SAVING'
    },
  },
  watch: {
    loaded (newVal) {
      this.filterGallery(newVal)
    }
  },
  beforeMount: function () {
    if (this.resourceObject) {
      // if props are passed in set the resource on mount
      this.id = this.resourceObject.id
      this.$store.commit('SET_RESOURCE', this.resourceObject)
      this.$store.commit('CHANGE_RESOURCE_LOAD_STATE', 'LOADED')
    } else {
      let resource = { id: this.id }
      this.$store.commit('CHANGE_RESOURCE_LOAD_STATE', 'LOADING')
      this.$store.dispatch('loadImageCollectionGql', resource)
    }
  },
  methods: {
    handleDeleteFolder: function (data) {
      console.log(data)
    },
    filterGallery: function (newVal) {
      if (this.structure) {
        // If structure prop is provided,
        // convert to figgy-friendly structure
        let structureFolders = this.renamePropertiesForLoad(this.structure.nodes)

        // Reconcile unstructured_objects with structured
        // Loop through each galleryItem object and
        // If found, replace the object that has the same id in structure_folders,
        // Then remove it from the galleryItems list and update the state
        // For both the Tree and the Gallery
        let ga = JSON.parse(JSON.stringify(this.galleryItems))

        function replaceObjects() {

          for (let i = 0; i < ga.length; i++) {
            for (let j = 0; j < structureFolders.length; j++) {
              if (replaceObjectRecursively(ga[i], structureFolders[j])) {
                // Remove the object from gallery_items after replacing in structure_folders
                ga.splice(i, 1);
                i--;  // Decrement i to account for the removed item
                break;  // break inner loop if a match is found
              }
            }
          }
        }

        function replaceObjectRecursively(galleryItem, structureFolder) {
          if (galleryItem.id === structureFolder.id) {
            // Change "caption" key to "label" before replacing the object
            galleryItem.label = galleryItem.caption
            delete galleryItem.caption
            delete structureFolder.proxy
            // Replace the object in structure_folders with the galleryItem
            Object.assign(structureFolder, galleryItem);
            return true  // Indicate that a match is found
          } else {
            // Continue searching in nested folders
            for (let i = 0; i < structureFolder.folders.length; i++) {
              if (replaceObjectRecursively(galleryItem, structureFolder.folders[i])) {
                return true  // Stop searching if a match is found in nested folders
              }
            }
          }
          return false;  // No match found in this folder or its nested folders
        }

        // Call the function to replace matching objects
        replaceObjects();

        // setting the newly filtered values as component data properties makes this
        // function much easier to test
        this.ga = ga;
        this.s = {
          id: this.id,
          folders: this.removeProxyProperty(structureFolders),
          label: this.structure.label[0],
        }

        this.$store.commit('SET_STRUCTURE', this.s)
        this.$store.commit('SET_GALLERY', this.ga)
      } else {
        // load empty/default structure
      }
    },
    generateId: function () {
      return Math.floor(Math.random() * 10000000).toString()
    },
    removeProxyProperty: function (arr) {
      // we are not able to recursively remove the proxy property from the figgy structure
      // so we pass the tree structure through this function before storing it
      return arr.map(obj => {
        const newObj = {};
        for (const key in obj) {
          if (key === "proxy") {
            delete obj.proxy
          }
          if (key === "folders") {
            newObj["folders"] = this.removeProxyProperty(obj[key])
          } else {
            newObj[key] = obj[key]
          }
        }
        return newObj
      })
    },
    renamePropertiesForLoad: function (arr) {
      const allowedProperties = ['id', 'label', 'folders', 'proxy', 'file']
      return arr.map(obj => {
        const newObj = {};
        for (const key in obj) {
          if (key === "nodes") {
            if (obj.proxy.length) {
              newObj["id"] = obj.proxy[0].id
              newObj["file"] = true
            } else {
              newObj["id"] = this.generateId()
              newObj["file"] = false
            }
            newObj["label"] = obj.label[0]
            newObj["folders"] = this.renamePropertiesForLoad(obj[key])
          } else {
            if (!allowedProperties.includes(key)) {
              delete obj[key]
            } else {
              newObj[key] = obj[key]
            }
          }
        }
        return newObj
      })
    },
    galleryClicked() {
      this.$store.commit('SELECT_TREEITEM', null)
    },
    resizeCards: function (event) {
      this.cardPixelWidth = event.target.value
      if (this.cardPixelWidth < 75) {
        this.captionPixelPadding = 0
      } else {
        this.captionPixelPadding = 9
      }
    },
  }
}
</script>
<style lang="scss" scoped>

.lux-toolbar {
  position: absolute;
  width: 100%;
  top: 0;
}

.lux-alert {
  position: fixed;
  top: 100px;
}

.deep-zoom {
  // position: absolute;
  // z-index: 3; /* put .gold-box above .green-box and .dashed-box */
  max-width: 100%;
  display: flex;
  justify-content: center;
  align-items: center;
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background-color: rgba(0, 0, 0, 0.85);
  background: url(data:;base64,iVBORw0KGgoAAAANSUhEUgAAAAIAAAACCAYAAABytg0kAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAgY0hSTQAAeiYAAICEAAD6AAAAgOgAAHUwAADqYAAAOpgAABdwnLpRPAAAABl0RVh0U29mdHdhcmUAUGFpbnQuTkVUIHYzLjUuNUmK/OAAAAATSURBVBhXY2RgYNgHxGAAYuwDAA78AjwwRoQYAAAAAElFTkSuQmCC)
    repeat scroll transparent\9; /* ie fallback png background image */
  z-index: 9999;
  color: white;
  border-radius: 4px;
  border-color: #ffffff;
}

.lux-resourceTitle {
  background-color: grey;
  margin-bottom: 10em;
}

.lux-label {
  font-weight: bold;
}
.lux-structManager {
  position: relative;
  height: 80vh;
}
.lux-structManager .lux-heading {
  margin: 12px 0 12px 0;
  line-height: 0.75;
  color: #001123;
}
.lux-structManager h2 {
  letter-spacing: 0;
  font-size: 24px;
}
.lux-sidePanel {
  position: absolute;
  top: 70px;
  left: 0px;
  height: 85%;
  width: 28.5%;
  border: 1px solid #ddd;
  border-radius: 4px;

  padding: 0 5px 0 5px;
  // height: 100%;
  overflow-y: scroll;
}
.lux-sidePanel .lux-input {
  display: block;
}
.lux-galleryPanel {
  position: absolute;
  top: 70px;
  left: 30%;
  height: 85%;
  width: 70%;
  border-radius: 4px;
  border: 1px solid #ddd;
}
.lux-icon {
  margin: auto;
}
.lux-galleryWrapper {
  overflow: auto;
  height: calc(100% - 80px);
  border-radius: 4px;
  margin-bottom: 80px;
  clear: both;
}

.loader {
  position: absolute;
  width: 100%;
  height: 100%;
  text-align: center;
  padding-bottom: 64px;
  z-index: 500;
  margin-top: -16px;
}
.loader .galleryLoader {
  width: 100%;
  height: 100%;
  background-color: rgba(0,0,0,0.85);
  display: flex;
}
.loader .galleryLoader .lux-loader {
  margin: auto;
}
.panelHeader {
  background-color: #e1f1fd;
  border-radius: 4px;
  padding: .5em .5em .5em 1em;
  margin: .5em;

  h2 {
    font-size: 12px;
    color: #333;
  }
}
</style>
