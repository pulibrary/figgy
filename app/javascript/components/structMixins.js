export default {
  methods: {
    enforceOrder: function (original_order, file_list) {
      // To-Do
      // this function will put items from the file_list array into the 
      // order in which they are found in the original_order array

    },
    findFolderById: function (array, id) {
      id= id.toString()
      if (!Array.isArray(array)) return null;

      for (const item of array) {
        if (item.id === id) return item
        if (Array.isArray(item.folders) && item.folders?.length) {
          const innerResult = this.findFolderById(item.folders, id)
          if (innerResult) return innerResult
        }
      }

      return null // Return null if the ID is not found in the array
    },
    findParentFolderById: function (array, id) {   
      id= id.toString()   
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
