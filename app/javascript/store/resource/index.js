export const resourceState = {
  resource: {
    id: "",
    resourceClassName: "",
    bibId: "",
    label: "Resource not available.",
    thumbnail: "",
    startCanvas: "",
    isMultiVolume: false,
    viewingHint: null,
    viewingDirection: null,
    members: [],
    loadState: "NOT_LOADED",
    saveState: "NOT_SAVED",
    errMsg: "",
    ogState: {},
  },
}

export const resourceMutations = {
  APPLY_STATE(state) {
    this.state.gallery.ogItems = state.gallery.items
    this.state.gallery.changeList = []
    state.resource.saveState = "NOT_SAVED"
  },
  CHANGE_RESOURCE_LOAD_STATE(state, loadState) {
    state.resource.loadState = loadState
  },
  SAVED_STATE(state, saveStatus) {
    state.resource.saveState = saveStatus
  },
  ERROR_MESSAGE(state, err) {
    state.resource.errMsg = err
  },
  SET_RESOURCE(state, resource) {
    state.resource.id = resource.id
    state.resource.resourceClassName = resource.__typename
    state.resource.label = resource.label
    state.resource.startCanvas = resource.startPage
    state.resource.viewingHint = resource.viewingHint
    state.resource.viewingDirection = resource.viewingDirection
    state.resource.thumbnail = resource.thumbnail != null ? resource.thumbnail.id : null
    state.resource.members = resource.members

    const items = resource.members.map(member => ({
      id: member.id,
      viewingHint: member.viewingHint != null ? member.viewingHint : "single",
      caption: member.label, // member.__typename + " : " + member.id,
      service:
        member["thumbnail"] && typeof(member.thumbnail.iiifServiceUrl) != "undefined"
          ? member.thumbnail.iiifServiceUrl
          : Global.figgy.resource.defaultThumbnail,
      mediaUrl:
        member["thumbnail"] && typeof(member.thumbnail.iiifServiceUrl) != "undefined"
          ? member.thumbnail.iiifServiceUrl + "/full/300,/0/default.jpg"
          : Global.figgy.resource.defaultThumbnail,
    }))

    this.state.gallery.items = items
    this.state.gallery.ogItems = items
    state.resource.loadState = "LOADED"
    state.resource.ogState = {
      startCanvas: resource.startPage,
      thumbnail: resource.thumbnail != null ? resource.thumbnail.id : null,
      viewingHint: resource.viewingHint,
      viewingDirection: resource.viewingDirection,
    }
  },
  UPDATE_STARTCANVAS(state, startCanvas) {
    state.resource.startCanvas = startCanvas
  },
  UPDATE_THUMBNAIL(state, thumbnail) {
    state.resource.thumbnail = thumbnail
  },
  UPDATE_VIEWDIR(state, viewDir) {
    state.resource.viewingDirection = viewDir
  },
  UPDATE_VIEWHINT(state, viewHint) {
    state.resource.viewingHint = viewHint
  },
  UPDATE_GALLERYITEMS(state, items) {
    this.state.gallery.items = items
  },
}

export const resourceGetters = {
  getMemberCount: state => {
    return state.resource.members.length
  },
  saved: state => {
    return state.resource.saveState === 'SAVED'
  },
  saveError: state => {
    return state.resource.saveState === 'ERROR'
  },
  isMultiVolume: state => {
    const volumes = state.resource.members.filter(member => member.__typename === "ScannedResource")
    return volumes.length > 0 ? true : false
  },
  orderChanged: state => {
    let ogOrder = JSON.stringify(state.gallery.ogItems.map(item => item.id))
    let imgOrder = JSON.stringify(state.gallery.items.map(item => item.id))
    return ogOrder !== imgOrder
  },
  stateChanged: (state, getters) => {
    var propsChanged = []
    propsChanged.push(state.resource.ogState.thumbnail !== state.resource.thumbnail)
    propsChanged.push(state.resource.ogState.startCanvas !== state.resource.startCanvas)
    propsChanged.push(state.resource.ogState.viewingHint !== state.resource.viewingHint)
    propsChanged.push(state.resource.ogState.viewingDirection !== state.resource.viewingDirection)
    propsChanged.push(state.gallery.changeList.length > 0)
    propsChanged.push(getters.orderChanged)
    if (propsChanged.indexOf(true) > -1) {
      return true
    } else {
      return false
    }
  },
}
