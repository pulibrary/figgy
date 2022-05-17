/**
  * Provides functionality to add and remove parent resources.
  * Companion to MemberResourcesTable
  * Adapted from the related_works.es6 module in https://github.com/samvera-labs/geo_works
  */

export default class ParentResourcesTable {
  constructor(element, form) {
    this.element = $(element)
    this.table = this.element.find('table')
    this.$tbody = this.table.find('tbody')
    this.parents = this.table.data('parents')
    this.members = this.table.data('members');

    this.update_url = this.table.data('update-url')
    this.query_url = this.table.data('query-url')
    if (!this.query_url) { return }

    this.$form = $(form);
    $(this.$form).submit((e) => e.preventDefault());
    this.$authenticityToken = this.$form.find('input[name="authenticity_token"]');
    this.authenticityToken = this.$authenticityToken.val();

    this.model = this.table.data('param-key');
    this.resourceId = this.table.data('resource-id')

    this.loading = false
    this.$loading = this.table.prev('.loading-status')
    this.bindButtons();
  }

  /**
   * Bind click events to buttons
   */
  bindButtons() {
    const $this = this;
    $this.bindAddButton();
    $this.bindRemoveButton();
  }

  /**
   * Handle click events by the "Add" button in the table, setting a warning
   * message if the input is empty or calling the server to handle the request
   */
  bindAddButton() {
    const $this = this;
    $this.element.find('.btn-add-row').click((event) => {
      const $element = $(event.target)
      const $row = $element.parents('.parent-resources-attach')
      const parentId = $this.element.find('.related_resource_ids').val()

      if ($.inArray(parentId, $this.parents) > -1) {
        $this.setWarningMessage($row, 'Resource is already related.')
      } else {
        $this.hideWarningMessage($row)
        $element.prop('disabled', true)
        $this.setLoading(true)

        $this.callAjax({
          row: $row,
          members: null,
          member: null,
          url: $this.update_url,
          element: $element,
          object: $this,
          data: { [this.model]: { ["append_id"]: parentId }},
          on_error: $this.handleError,
          on_success: $this.reloadTable
        });
      }
      event.preventDefault()
    });
  }

  /**
  * Handle click events by the "Remove" buttons in the table, and calling the
  * server to handle the request
  */
  bindRemoveButton() {
    const $this = this;
    $this.element.find('.btn-remove-row').click((event) => {
      const $element = $(event.target)
      const $row = $element.parents('tr:first')
      const parentId = $row.data('resource-id')
      const index = $this.parents.indexOf(parentId)
      $this.parents.splice(index, 1)
      const update_url = $row.data('update-url')

      $element.prop('disabled', true)
      $this.setLoading(true)

      $this.callAjax({
        row: $row,
        members: null,
        member: null,
        data: {
          'authenticity_token': this.authenticityToken,
          'parent_resource': { id: parentId }
        },
        url: update_url,
        element: $element,
        object: $this,
        on_error: $this.handleError,
        on_success: $this.reloadTable
      })
      event.preventDefault()
    });
  }

  setLoading(state) {
    this.loading = state
    this.update()
  }

  update() {
    if(this.loading) {
      this.$loading.removeClass('hidden')
      this.table.addClass('loading')
    } else {
      this.$loading.addClass('hidden')
      this.table.removeClass('loading')
    }
  }

  /**
   * Set the warning message related to the appropriate row in the table
   * @param {jQuery} row the row containing the warning message to display
   * @param {String} message the warning message text to set
   */
  setWarningMessage(row, message) {
    const $this = this;
    const $warning = $this.element.find('#warning-message');
    $warning.text(message);
    $warning.parent().removeClass('hidden');
  }

  /**
   * Hide the warning message on the appropriate row
   * @param {jQuery} row the row containing the warning message to hide
   */
  hideWarningMessage(row) {
    const $this = this;
    $this.element.find('.message.has-warning').addClass('hidden');
  }

  /**
  * Call the server, then call the appropriate callbacks to handle success and errors
  * @param {Object} args the table, row, input, url, and callbacks
  */
  callAjax(args) {
    const $this = this;
    $.ajax({
      type: 'patch',
      contentType: 'application/json',
      dataType: 'json',
      url: args.url,
      data: JSON.stringify(args.data),
    }).done(() => {
        args.element.prop('disabled', false)
        args.on_success.call($this, args);
    }).fail((jqxhr) => {
        args.element.prop('disabled', false)
        args.on_error.call($this, args, jqxhr);
    });
  }

  /**
  * Reloads the table after ajax call
  * Rebinds the add and remove buttons to the updated table.
  */
  reloadTable() {
    const $this = this;

    $this.$tbody.load(`${$this.query_url} #${this.table[0].id} tbody > *`, () => {
      $this.setLoading(false)
      $this.bindButtons();
      // Clear existing resource input value
      $this.element.find('.related_resource_ids').val('')
    });
  }

  /**
  * Set a warning message to alert the user on an error
  * @param {Object} args the table, row, input, url, and callbacks
  * @param {Object} jqxhr the jQuery XHR response object
  */
  handleError(args, jqxhr) {
    this.setLoading(false)
    let message = jqxhr.statusText;
    if (jqxhr.responseJSON) {
      message = jqxhr.responseJSON.description;
    }
    this.setWarningMessage(args.row, message);
  }
}
