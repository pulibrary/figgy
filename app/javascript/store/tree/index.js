export const treeState = {
  selected: null,
}

export const treeMutations = {
  SELECT(state, selectedId) {
    state.selected = selectedId
  },
}
