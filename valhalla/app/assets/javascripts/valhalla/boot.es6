import FileManager from 'valhalla/file_manager'
import PlumFileManager from 'valhalla/plum_file_manager'
import BulkLabeler from "valhalla/bulk_labeler/bulk_label"
export class Initializer {
  constructor() {
    this.file_manager = new FileManager
    this.file_manager_extensions = new PlumFileManager
    this.bulk_labeler = new BulkLabeler
    this.sortable_placeholder()
  }

  sortable_placeholder() {
    $( "#sortable" ).on( "sortstart", function( event, ui ) {
      let found_element = $("#sortable").find("li[data-reorder-id]").last()
      ui.placeholder.width(found_element.width())
      ui.placeholder.height(found_element.height())
    })
  }
}
