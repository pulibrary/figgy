export const treeState = {
  selected: null,
  cut: null,
  structure: {},
  modified: false,
  loadState: "NOT_LOADED",
  saveState: "NOT_SAVED",
}

export const treeMutations = {
  APPLY_TREE_STATE(state) {
    state.modified = false
    state.saveState = "NOT_SAVED"
  },
  ADD_RESOURCE(state, structure) {
    state.structure = structure
  },
  CUT_FOLDER(state, folderId) {
    state.cut = folderId
  },
  CREATE_FOLDER(state, structure) {
    state.structure = structure
    state.modified = true
  },
  DELETE_FOLDER(state, structure) {
    state.structure = structure
    state.modified = true
  },
  SAVE_LABEL(state, structure) {
    state.structure = structure
    state.modified = true
  },
  SELECT_TREEITEM(state, selectedId) {
    state.selected = selectedId
  },
  SET_STRUCTURE(state, structureObject) {
    state.structure = structureObject
  },
  SET_MODIFIED(state, bool) {
    state.modified = bool
  },
  CHANGE_STRUCTURE_LOAD_STATE(state, loadState) {
    state.loadState = loadState
  },
  SAVED_STRUCTURE_STATE(state, saveStatus) {
    state.saveState = saveStatus
  },
}
