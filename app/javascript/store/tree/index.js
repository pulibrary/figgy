export const treeState = {
  selected: null,
  structure: {},
}

export const treeMutations = {
  CREATE_FOLDER(state, structure) {
    state.structure = structure
    console.log(structure)
  },
  DELETE_FOLDER(state, structure) {
    state.structure = structure
    // console.log(structure)
  },
  SAVE_LABEL(state, structure) {
    state.structure = structure
  },
  SELECT(state, selectedId) {
    state.selected = selectedId
  },
  SET_STRUCTURE(state, structureObject) {
    state.structure = structureObject
  },
}
