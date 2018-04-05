import RelatedResourcesTable from 'relationships/related_resources_table';

/**
* Provides functionality to add and remove parent works.
*/
export default class ParentResourcesTable extends RelatedResourcesTable {

  constructor(element, form) {
    super(element, form)
    this.attribute = 'member_ids'
    this.parents = this.table.data('parents')
    this.resourceId = this.table.data('resource-id')
  }

  /**
  * Builds form data strings.
  */
  buildFormData(parentId) {
    return {
      'authenticity_token': this.authenticityToken,
      'parent_resource': {
        id: parentId,
        [this.attribute]: [this.resourceId]
      }
    };
  }

  /**
   * Handle click events by the "Add" button in the table, setting a warning
   * message if the input is empty or calling the server to handle the request
   */
  bindAddButton() {
    const $this = this;
    $this.element.find('.btn-add-row').click(() => {
      const $row = $(this).parents('.parent-resources-attach')
      const parentId = $this.$select.val()

      if ($.inArray(parentId, $this.parents) > -1) {
        $this.setWarningMessage($row, 'Resource is already related.')
      } else {
        $this.hideWarningMessage($row)
        $this.callAjax({
          row: $row,
          members: null,
          member: null,
          url: $this.update_url,
          data: $this.buildFormData(parentId),
          on_error: $this.handleError,
          on_success: $this.reloadTable
        });
      }
    });
  }

  /**
  * Handle click events by the "Remove" buttons in the table, and calling the
  * server to handle the request
  */
  bindRemoveButton() {
    const $this = this;
    $this.element.find('.btn-remove-row').click((event) => {
      const $row = $(event.target).parents('tr:first')

      const parentId = $row.data('resource-id')
      const index = $this.parents.indexOf(parentId)
      $this.parents.splice(index, 1)

      const update_url = $row.data('update-url')
      $this.callAjax({
        row: $row,
        members: null,
        member: null,
        data: $this.buildFormData(parentId),
        url: update_url,
        on_error: $this.handleError,
        on_success: $this.reloadTable
      })
    });
  }
}
