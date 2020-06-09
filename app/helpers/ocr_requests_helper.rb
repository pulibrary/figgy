# frozen_string_literal: false
module OcrRequestsHelper
  # Return action button for ocr requests table.
  def ocr_request_actions(ocr_request)
    delete_link = link_to("View", ocr_request, class: "btn btn-default")
    view_link = link_to("Delete", ocr_request, method: :delete, class: "btn btn-default", data: { confirm: "Are you sure?" })
    safe_join([delete_link, view_link])
  end
end
