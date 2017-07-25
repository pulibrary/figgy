import SaveWorkControl from 'form/save_work_control'
export default class Initializer {
  constructor() {
    this.initialize_form()
  }

  initialize_form() {
    if($("#form-progress").length > 0) {
      new SaveWorkControl($("#form-progress"))
    }
  }
}
