export default class ServerUploader {
  constructor() {
    this.element = $(".browse-everything")
    this.element.click((event) => event.preventDefault())
    this.mount_browse_everything()
  }

  mount_browse_everything() {
    this.element.browseEverything({
      route: "/browse",
      target: "#browse-everything-form"
    }).done(this.finished_browsing)
  }

  get finished_browsing() {
    return () => {
      this.submit_files()
    }
  }

  submit_files() {
    $("#browse-everything-form").submit()
  }
}
