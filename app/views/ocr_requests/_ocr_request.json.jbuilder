# frozen_string_literal: true
json.extract! ocr_request, :id, :filename, :state, :note, :user_id, :created_at, :updated_at
json.actions ocr_request_actions(ocr_request)
