export default {
  methods: {
    findFolderById: function (array, id) {
      for (const item of array) {
        if (item.id === id) return item
        if (item.folders?.length) {
          const innerResult = this.findFolderById(item.folders, id)
          if (innerResult) return innerResult
        }
      }

      return null // Return null if the ID is not found in the array
    },
    findParentFolderById: function (array, id) {
      for (const item of array) {
        // If this item contains the target as one of its children, 
        // return this item
        if (item.folders?.some(f => f.id === id)) {
          return item
        }

        // Otherwise do recursion
        if (item.folders?.length) {
          const parent = this.findParentFolderById(item.folders, id)
          if (parent) return parent
        }
      }
      return null
    },
    generateId: function () {
      return Math.floor(Math.random() * 10000000).toString()
    },
  },
}
