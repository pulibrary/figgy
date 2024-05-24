export const galleryState = {
  items: [],
  selected: [],
  cut: [],
  changeList: [],
  ogItems: [],
}

export const galleryMutations = {
  CUT(state, itemArray) {
    state.cut = [...itemArray]
  },
  PASTE(state, itemArray) {
    state.items = [...itemArray]
  },
  SELECT(state, itemArray) {
    state.selected = [...itemArray]
  },
  SET_GALLERY(state, items) {
    state.items = items
    state.ogItems = items
  },
  SORT_ITEMS(state, value) {
    state.items = [...value]
  },
  UPDATE_CHANGES(state, changeList) {
    state.changeList = [...changeList]
  },
  UPDATE_ITEMS(state, items) {
    state.items = [...items]
  },
}

export const galleryModule = {
  state: galleryState,
  mutations: galleryMutations,
}
