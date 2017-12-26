import SaveWorkControl from 'form/save_work_control'
import DuplicateResourceDetectorFactory from 'form/detect_duplicates'
import ServerUploader from "./server_uploader"
import StructureManager from "structure_manager"
import ModalViewer from "modal_viewer"
import DerivativeForm from "derivative_form"
import MetadataForm from "metadata_form"
import UniversalViewer from "universal_viewer"
import FileSetForm from "file_set_form"
import SaveAndIngestHandler from "save_and_ingest_handler"

export default class Initializer {
  constructor() {
    this.server_uploader = new ServerUploader
    this.initialize_form()
    this.initialize_timepicker()
    this.structure_manager = new StructureManager
    this.modal_viewer = new ModalViewer
    this.derivative_form = new DerivativeForm
    this.metadata_form = new MetadataForm
    this.universal_viewer = new UniversalViewer
    this.save_and_ingest_handler = new SaveAndIngestHandler
    // Incompatibility in Blacklight with newer versions of jQuery seem to be
    // causing this to not run. Manually calling it so facet more links work.
    Blacklight.ajaxModal.setup_modal()
    $("optgroup").addClass("closed")
    $("select").selectpicker({'liveSearch': true})
    $(".datatable").DataTable()
  }

  initialize_timepicker() {
    $(".timepicker").datetimepicker({
      timeFormat: "HH:mm:ssZ",
      separator: "T",
      dateFormat: "yy-mm-dd",
      timezone: "0",
      showTimezone: false,
      showHour: false,
      showMinute: false,
      showSecond: false,
      hourMax: 0,
      minuteMax: 0,
      secondMax: 0
    })
  }

  initialize_form() {
    if($("#form-progress").length > 0) {
      new SaveWorkControl($("#form-progress"))
    }

    $(".detect-duplicates").each((_i, element) =>
      DuplicateResourceDetectorFactory.build($(element))
    )

    $("form.edit_file_set.admin_controls").each((_i, element) =>
      new FileSetForm($(element))
    )
  }
}
