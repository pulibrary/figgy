export const treeState = {
  selected: null,
  structure: {},
}

export const treeMutations = {
  CREATE_FOLDER(state, structure) {
    state.structure = structure
    console.log(structure)
  },
  SELECT(state, selectedId) {
    state.selected = selectedId
  },
  SET_STRUCTURE(state, structureObject) {
    state.structure = structureObject
  },
}
