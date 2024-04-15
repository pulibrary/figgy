export default {
  methods: {
    findFolderById: function (array, id) {
      for (const item of array) {
        if (item.id === id) return item;
        if (item.folders?.length) {
          const innerResult = this.findFolderById(item.folders, id);
          if (innerResult) return innerResult;
        }
      }

      return null; // Return null if the ID is not found in the array
    },
    generateId: function () {
      return Math.floor(Math.random() * 10000000).toString()
    },
  },
}
