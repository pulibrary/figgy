/**
  * Provides functionality to add and remove member resources
  * Companion to ParentResourcesTable
  * Adapted from the related_works.es6 module in https://github.com/samvera-labs/geo_works
  */

export default class MemberResourcesTable {
  constructor(element, form) {
    this.element = $(element)
    this.table = this.element.find('table')
    this.$tbody = this.table.find('tbody')
    this.members = this.table.data('members');
    // We initialize datatables here instead of in figgy_boot because we need
    // to hold a specific reference to each one
    this.initializeDataTable()

    this.update_url = this.table.data('update-url')
    this.query_url = this.table.data('query-url')
    if (!this.query_url) {
      return
    }

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
      const $row = $this.element.find('.member-actions')
      const attachedId = $this.element.find('.related_resource_ids').val()

      if (attachedId === '') {
        $this.setWarningMessage($row, 'ID cannot be empty.');
      } else if ($.inArray(attachedId, $this.members) > -1) {
        $this.setWarningMessage($row, 'Resource is already related.');
      } else {
        $this.datatable.destroy();
        $this.members.push(attachedId);
        $this.hideWarningMessage($row);
        $element.prop('disabled', true)

        $this.setLoading(true)
        $this.callAjax({
          row: $row,
          members: null,
          member: null,
          url: $this.get_child_update_url(attachedId),
          element: $element,
          object: $this,
          data: $this.buildChildFormData(),
          on_error: $this.handleError,
          on_success: $this.reloadTable
        });
      }
      event.preventDefault()
    });
  }

  /**
  * Builds form data strings.
  */
  buildChildFormData() {
    let parentId = this.update_url.split("/").pop()
    return {
      'authenticity_token': this.authenticityToken,
      [this.model]: {
        ["append_id"]: parentId
      }
    };
  }

  // replace parent id with new member Id
  get_child_update_url(attachedId) {
    let stuff = this.update_url.split("/")
    stuff.pop()
    stuff.push(attachedId)
    return stuff.join("/")
  }

  /**
  * Handle click events by the "Remove" buttons in the table, and calling the
  * server to handle the request
  */
  bindRemoveButton() {
    const $this = this;
    $this.element.find('.btn-remove-row').click((event) => {
      const $element = $(event.target)
      const $row = $element.parents('tr:first');
      const memberId = $row.data('resource-id');
      const index = $this.members.indexOf(memberId);

      $this.datatable.destroy();
      $this.members.splice(index, 1);
      $element.prop('disabled', true)
      $this.setLoading(true)
      $this.callAjax({
        row: $row,
        members: null,
        member: null,
        data: $this.buildRemoveFormData(),
        url: $this.update_url,
        element: $element,
        object: $this,
        on_error: $this.handleError,
        on_success: $this.reloadTable
      });
      event.preventDefault()
    });
  }

  /**
  * Builds form data strings.
  */
  buildRemoveFormData() {
    return {
      'authenticity_token': this.authenticityToken,
      [this.model]: {
        ['member_ids']: this.members
      }
    };
  }

  setLoading(state) {
    this.loading = state
    this.update()
  }

  update() {
    if(this.loading) {
      this.$loading.removeClass('d-none')
      this.table.addClass('loading')
    } else {
      this.$loading.addClass('d-none')
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
    $warning.parent().removeClass('d-none');
  }

  /**
   * Hide the warning message on the appropriate row
   * @param {jQuery} row the row containing the warning message to hide
   */
  hideWarningMessage(row) {
    const $this = this;
    $this.element.find('.message.has-warning').addClass('d-none');
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
      $this.reBindButtons();
      // Clear existing resource input value
      $this.element.find('.related_resource_ids').val('')
      // reload the datatable
      $this.initializeDataTable()
    });
  }

  initializeDataTable() {
    this.datatable = this.element.find('.member-resources-datatable').DataTable()
  }

  /**
   * Prevents click events from firing twice
   */
  reBindButtons() {
    const $this = this;
    $this.element.find('.btn-add-row').unbind("click")
    $this.element.find('.btn-remove-row').unbind("click")
    $this.bindButtons();
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
