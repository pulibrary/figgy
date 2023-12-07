export const treeState = {
  selected: null,
  cut: null,
  structure: {},
}

export const treeMutations = {
  ADD_RESOURCE(state, structure) {
    state.structure = structure
  },
  CUT_FOLDER(state, folderId) {
    state.cut = folderId
  },
  CREATE_FOLDER(state, structure) {
    state.structure = structure
  },
  DELETE_FOLDER(state, structure) {
    state.structure = structure
  },
  SAVE_LABEL(state, structure) {
    state.structure = structure
  },
  SELECT_TREEITEM(state, selectedId) {
    state.selected = selectedId
  },
  SET_STRUCTURE(state, structureObject) {
    state.structure = structureObject
  },
}
