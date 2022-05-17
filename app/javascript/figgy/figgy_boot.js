import SaveWorkControl from 'figgy/form/save_work_control'
import DuplicateResourceDetectorFactory from 'figgy/form/detect_duplicates'
import ServerUploader from "figgy/server_uploader"
import CollectionBagUploader from "figgy/collection_bag_uploader"
import StructureManager from "figgy/structure_manager"
import ModalViewer from "figgy/modal_viewer"
import DerivativeForm from "figgy/derivative_form"
import MetadataForm from "figgy/metadata_form"
import UniversalViewer from "figgy/universal_viewer"
import FileSetForm from "figgy/file_set_form"
import SaveAndIngestHandler from "figgy/save_and_ingest_handler"
import AutoIngestHandler from "figgy/auto_ingest_handler"
import MemberResourcesTables from "figgy/relationships/member_resources_table"
import ParentResourcesTables from "figgy/relationships/parent_resources_table"
import BulkLabeler from "figgy/bulk_labeler/bulk_label"
import BoundingBoxSelector from "figgy/bounding_box_selector"

export default class Initializer {
  constructor() {
    this.server_uploader = new ServerUploader
    this.collection_bag_uploader = new CollectionBagUploader
    this.initialize_form()
    this.initialize_timepicker()
    this.initialize_bbox()
    this.structure_manager = new StructureManager
    this.modal_viewer = new ModalViewer
    this.derivative_form = new DerivativeForm
    this.metadata_form = new MetadataForm
    this.universal_viewer = new UniversalViewer
    this.save_and_ingest_handler = new SaveAndIngestHandler
    this.auto_ingest_handler = new AutoIngestHandler
    this.bulk_labeler = new BulkLabeler
    this.sortable_placeholder()

    // Incompatibility in Blacklight with newer versions of jQuery seem to be
    // causing this to not run. Manually calling it so facet more links work.
    // Blacklight.ajaxModal.setup_modal()
    $("optgroup:not([label=Favorites])").addClass("closed")
    $("select:not(.select2)").selectpicker({'liveSearch': true})

    this.initialize_datatables()
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

  // most datatables can be initialized here
  // note that member resources datatables are initialized in that class
  initialize_datatables() {
    $(".datatable").DataTable()
    // Set an initial sort order of data table for coins
    $(".coin-datatable").DataTable({
      "order": [[ 2, "asc" ]]
    })
    // Set an initial sort order of data table for ocr requests
    $("#requests-table").DataTable({
      order: [[1, "desc"]],
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

    $('select.select2').select2({
      tags: true,
      placeholder: "Nothing selected",
      allowClear: true
    })

    $(".document div.member-resources").each((_i, element) => {
      const $element = $(element)
      const $form = $element.parent('form')
      new MemberResourcesTables($element, $form)
    })

    $(".document div.parent-resources").each((_i, element) => {
      const $element = $(element)
      const $form = $element.parent('form')
      new ParentResourcesTables($element, $form)
    })
  }

  initialize_bbox() {
    $("#bbox").each((_i, element) => {
      const $element = $(element)
      new BoundingBoxSelector($element)
    })
  }

  sortable_placeholder() {
    $( "#sortable" ).on( "sortstart", function( event, ui ) {
      let found_element = $("#sortable").find("li[data-reorder-id]").last()
      ui.placeholder.width(found_element.width())
      ui.placeholder.height(found_element.height())
    })
  }
}
