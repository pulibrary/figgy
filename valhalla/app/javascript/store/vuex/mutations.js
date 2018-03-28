// mutations
const mutations = {
  CHANGE_MANIFEST_LOAD_STATE (state, loadState) {
    state.manifestLoadState = loadState
  },
  CUT (state, imgArray) {
    state.cut = [ ...imgArray ]
  },
  PASTE (state, imgArray) {
    state.images = [ ...imgArray ]
  },
  SELECT (state, imgArray) {
    state.selected = [ ...imgArray ]
  },
  SET_STATE (state, ImageCollection) {
    state.id = ImageCollection.id
    state.bibid = ImageCollection.bibid
    state.isMultiVolume = ImageCollection.isMultiVolume
    state.resourceClassName = ImageCollection.resourceClassName
    state.startPage = ImageCollection.startPage
    state.thumbnail = ImageCollection.thumbnail
    state.viewingHint = ImageCollection.viewingHint
    state.viewingDirection = ImageCollection.viewingDirection
    state.images = ImageCollection.images
    state.ogImages = ImageCollection.images
    state.ogState = { startPage: ImageCollection.startPage,
                      thumbnail: ImageCollection.thumbnail,
                      viewingHint: ImageCollection.viewingHint,
                      viewingDirection: ImageCollection.viewingDirection
                    }
  },
  SAVE_STATE (state, reset) {
    flash('State saved!', 'success')
    state.ogImages = [ ...state.images ]
    state.changeList = [ ...reset ]
    state.selected = [ ...reset ]
  },
  SORT_IMAGES (state, value) {
    state.images = [ ...value ]
  },
  UPDATE_CHANGES (state, changeList) {
    state.changeList = [ ...changeList ]
  },
  UPDATE_IMAGES (state, images) {
    state.images = [ ...images ]
  },
  UPDATE_STARTPAGE (state, startPage) {
    state.startPage = startPage
  },
  UPDATE_THUMBNAIL (state, thumbnail) {
    state.thumbnail = thumbnail
  },
  UPDATE_VIEWDIR (state, viewDir) {
    state.viewingDirection = viewDir
  },
  UPDATE_VIEWHINT (state, viewHint) {
    state.viewingHint = viewHint
  }
}

export default mutations
