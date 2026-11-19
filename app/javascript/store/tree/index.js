export const treeState = {
  selected: null,
  cut: null,
  structure: { label: "Table of Contents", id: "123", folders: [] },
  modified: false,
  loadState: "NOT_LOADED",
  saveState: "NOT_SAVED",
}

// Helper functions to traverse the live state without cloning
function findNodeById(folders, id) {
  if (id === null || id === undefined) return null
  const targetId = String(id)

  for (const item of folders) {
    if (String(item.id) === targetId) return item
    if (item.folders?.length) {
      const found = findNodeById(item.folders, targetId)
      if (found) return found
    }
  }
  return null
}

function collectSubtreeIds(node, idSet = new Set()) {
  if (!node) return idSet
  if (node.id) idSet.add(node.id)
  if (node.folders?.length) {
    for (const child of node.folders) {
      collectSubtreeIds(child, idSet)
    }
  }
  return idSet
}

export const treeGetters = {
  selectedIdsSet(state) {
   if (!state.selected) return new Set()
    if (String(state.selected) === String(state.structure.id)) {
      return collectSubtreeIds(state.structure)
    }
    const target = findNodeById(state.structure.folders, state.selected)
    return collectSubtreeIds(target)
  },

  disabledIdsSet(state) {
    if (!state.cut) return new Set()
    const target = findNodeById(state.structure.folders, state.cut)
    return collectSubtreeIds(target)
  }
}

export const treeMutations = {
  APPLY_TREE_STATE(state) {
    state.modified = false
    state.saveState = "NOT_SAVED"
  },
  ADD_FILES(state, structure) {
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
  SAVE_LABEL(state, { id, label }) {
    if (state.structure.id === id) {
      state.structure.label = label
    } else {
      const target = findNodeById(state.structure.folders, id)
      if (target) {
        target.label = label
      }
    }
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
  MOVE_UP(state, structure) {
    state.structure = structure
    state.modified = true
  },
  MOVE_DOWN(state, structure) {
    state.structure = structure
    state.modified = true
  },
}
