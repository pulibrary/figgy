# frozen_string_literal: true

json.array! @ocr_requests, partial: "ocr_requests/ocr_request", as: :ocr_request
