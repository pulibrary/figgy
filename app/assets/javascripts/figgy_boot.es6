import SaveWorkControl from 'form/save_work_control'
import DuplicateResourceDetectorFactory from 'form/detect_duplicates'
import ServerUploader from "./server_uploader"
import CollectionBagUploader from "./collection_bag_uploader"
import StructureManager from "structure_manager"
import ModalViewer from "modal_viewer"
import DerivativeForm from "derivative_form"
import MetadataForm from "metadata_form"
import UniversalViewer from "universal_viewer"
import FileSetForm from "file_set_form"
import SaveAndIngestHandler from "save_and_ingest_handler"
import AutoIngestHandler from "auto_ingest_handler"
import MemberResourcesTables from "relationships/member_resources_table"
import ParentResourcesTables from "relationships/parent_resources_table"
import BulkLabeler from "bulk_labeler/bulk_label"
import BoundingBoxSelector from "bounding_box_selector"

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
    Blacklight.ajaxModal.setup_modal()
    $("optgroup:not([label=Favorites])").addClass("closed")
    $("select:not(.select2)").selectpicker({'liveSearch': true})
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

    $('select.select2').select2({
      tags: true,
      placeholder: "Nothing selected",
      allowClear: true
    }).on('select2:select', (event) => {
      const $target = $(event.target)
      const selected = $target.select2('data')
      const selectedItem = selected.shift()
      const value = selectedItem.text
      const $hidden = $($target.data('hidden'))

      $hidden.val(value)
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
