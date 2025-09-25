// Callback function to disable pagination in Datatable if there are 1 or fewer pages
const conditionalPagingCallback = (settings) => {
  const pages = Math.floor(settings.fnRecordsDisplay() / settings._iDisplayLength) + 1
  if (pages <= 1) {
      // Hide the pagination controls if there's one or less pages
      $(settings.nTableWrapper).find('.dataTables_paginate').hide()
  } else {
      // Show the pagination controls if there are multiple pages
      $(settings.nTableWrapper).find('.dataTables_paginate').show()
  }
}

export { conditionalPagingCallback }
