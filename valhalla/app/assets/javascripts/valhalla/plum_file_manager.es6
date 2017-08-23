import RadioTracker from "valhalla/file_manager/radio_tracker"
import SelectTracker from "valhalla/file_manager/select_tracker"
import {InputTracker, FileManagerMember} from "valhalla/file_manager/member"
import BulkActionManager from "valhalla/file_manager/bulk_actions"
export default class PlumFileManager {
  constructor() {
    this.initialize_radio_buttons()
    this.sortable_placeholder()
    this.manage_iiif_fields()
    this.starting_page()
    this.bulk_actions()
  }

  initialize_radio_buttons() {
    $("*[data-reorder-id] .file_set_viewing_hint").each((index, element) => {
      new RadioTracker($(element))
    })
  }

  sortable_placeholder() {
    $( "#sortable" ).on( "sortstart", function( event, ui ) {
      let found_element = $("#sortable").children("li[data-reorder-id]").first()
      ui.placeholder.width(found_element.width())
      ui.placeholder.height(found_element.height())
    })
  }

  manage_iiif_fields() {
    // Viewing Direction
    new RadioTracker($("#resource-form > div:eq(0)"))
    // Viewing Hint
    new RadioTracker($("#resource-form > div:eq(1)"))
    // OCR Language
    new SelectTracker($("#resource-form select:eq(0)"))
  }

  get resource_manager() {
    return $("#resource-form").parent().data("file_manager_member")
  }

  starting_page() {
    // Track thumbnail ID hidden field
    new InputTracker($("*[data-member-link=start_canvas]"), this.resource_manager)
    $("#sortable *[name=start_canvas]").change(function() {
      let val = $("#sortable *[name=start_canvas]:checked").val()
      $("*[data-member-link=start_canvas]").val(val)
      $("*[data-member-link=start_canvas]").change()
    })
  }

  bulk_actions() {
    this.bulk_action_manager = new BulkActionManager($("#bulk-actions"))
  }
}
