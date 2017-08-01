import SaveWorkControl from 'form/save_work_control'
import ServerUploader from "./server_uploader"
import StructureManager from "structure_manager"
export default class Initializer {
  constructor() {
    this.server_uploader = new ServerUploader
    this.initialize_form()
    this.structure_manager = new StructureManager
  }

  initialize_form() {
    if($("#form-progress").length > 0) {
      new SaveWorkControl($("#form-progress"))
    }
  }
}
