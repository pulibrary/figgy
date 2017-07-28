import SaveWorkControl from 'form/save_work_control'
import ServerUploader from "server_uploader"
export default class Initializer {
  constructor() {
    this.initialize_form()
    this.server_uploader = new ServerUploader
  }

  initialize_form() {
    if($("#form-progress").length > 0) {
      new SaveWorkControl($("#form-progress"))
    }
  }
}
