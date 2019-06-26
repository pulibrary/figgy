
export default class CollectionBagUploader {
  constructor() {
    this.element = $(".browse-everything")
    this.element.click((event) => event.preventDefault())
    this.mount_browse_everything()
  }

  mount_browse_everything() {
    this.element.browseEverything({
      route: "/browse",
      target: ".new_collection, .edit_collection"
    }).done(this.finished_browsing)
  }

  selectedInputElements () {
    $("input[name*='selected_files']")
  }

  selectedFiles () {
    this.selected_input_elements().map(e => e.val())
  }

  static parseSelectedUrls (data) {
    const urls = data.map(d => d.url)
    return [...new Set(urls)]
  }

  static parseDirectoryUrls (urls) {
    const directories = urls.map(url => {
      const segments = url.split('/')
      const baseSegments = segments.slice(2, -1)
      return baseSegments.join('/')
    })
    const uniq = [...new Set(directories)]
    return uniq.sort((u, v) => u.length - v.length)
  }

  finished_browsing (data) {
    const urls = CollectionBagUploader.parseSelectedUrls(data)
    const directories = CollectionBagUploader.parseDirectoryUrls(urls)
    const directory = directories.shift()
    $('#collection_bag_path').val(directory)
  }

  submit_files() {
    $(".new_collection, .edit_collection").submit()
  }
}
