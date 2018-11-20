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
    ogState: {},
  },
}

export const resourceMutations = {
  APPLY_STATE(state) {
    state.gallery.ogItems = state.gallery.items
    state.gallery.changeList = []
    state.resource.ogState = {
      startCanvas: resource.startPage,
      thumbnail: resource.thumbnail,
      viewingHint: resource.viewingHint,
      viewingDirection: resource.viewingDirection,
    }
    state.resource.saveState = "NOT_SAVED"
  },
  CHANGE_RESOURCE_LOAD_STATE(state, loadState) {
    state.resource.loadState = loadState
  },
  SAVED_STATE(state, saveStatus) {
    state.resource.saveState = saveStatus
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
        typeof member.thumbnail.iiifServiceUrl != "undefined"
          ? member.thumbnail.iiifServiceUrl
          : "https://picsum.photos/600/300/?random",
      mediaUrl:
        typeof member.thumbnail.iiifServiceUrl != "undefined"
          ? member.thumbnail.iiifServiceUrl + "/full/300,/0/default.jpg"
          : "https://picsum.photos/600/300/?random",
    }))
    state.gallery.items = items
    state.gallery.ogItems = items
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
}

export const resourceGetters = {
  getMemberCount: state => {
    return state.resource.members.length
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
