json.extract! ocr_request, :id, :filename, :state, :note, :user_id, :created_at, :updated_at
json.url ocr_request_url(ocr_request, format: :json)
