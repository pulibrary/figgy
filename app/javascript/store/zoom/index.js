export const zoomState = {
  zoomed: null,
}

export const zoomMutations = {
  ZOOM(state, obj) {
    state.zoomed = obj
  },
  RESET_ZOOM(state) {
    state.zoomed = null
  },
}
