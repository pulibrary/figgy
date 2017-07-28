import SaveWorkControl from 'form/save_work_control'
import ServerUploader from "./server_uploader"
export default class Initializer {
  constructor() {
    this.server_uploader = new ServerUploader
    this.initialize_form()
  }

  initialize_form() {
    if($("#form-progress").length > 0) {
      new SaveWorkControl($("#form-progress"))
    }
  }
}
