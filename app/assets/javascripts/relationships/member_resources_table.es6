import RelatedResourcesTable from 'relationships/related_resources_table';

/**
* Provides functionality to add and remove child works.
*/
export default class MemberResourcesTable extends RelatedResourcesTable {

  constructor(element, form) {
    super(element, form);
    this.attribute = 'append_id';
  }

  /**
  * Builds form data strings.
  */
  buildFormData() {
    let parentId = this.update_url.split("/").pop()
    return {
      'authenticity_token': this.authenticityToken,
      [this.model]: {
        [this.attribute]: parentId
      }
    };
  }

  // replace parent id with new member Id
  get_update_url(attachedId) {
    let stuff = this.update_url.split("/")
    stuff.pop()
    stuff.push(attachedId)
    return stuff.join("/")
  }

  /**
   * Handle click events by the "Add" button in the table, setting a warning
   * message if the input is empty or calling the server to handle the request
   */
  bindAddButton(event) {
    const $this = this;
    $this.element.find('.btn-add-row').click((event) => {
      const $element = $(event.target)
      const $row = $this.element.find('.member-actions')
      const attachedId = $this.element.find('.related_resource_ids').val()

      if (attachedId === '') {
        $this.setWarningMessage($row, 'ID cannot be empty.');
      } else if ($.inArray(attachedId, $this.members) > -1) {
        $this.setWarningMessage($row, 'Resource is already related.');
      } else {
        $this.members.push(attachedId);
        $this.hideWarningMessage($row);
        $element.prop('disabled', true)

        $this.setLoading(true)
        $this.callAjax({
          row: $row,
          members: null,
          member: null,
          url: $this.get_update_url(attachedId),
          element: $element,
          object: $this,
          data: $this.buildFormData(),
          on_error: $this.handleError,
          on_success: $this.reloadTable
        });
      }
    });
  }
}
