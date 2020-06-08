# frozen_string_literal: true

json.extract! ocr_request, :id, :filename, :state, :note, :user_id, :created_at, :updated_at
json.actions link_to "Delete", ocr_request, method: :delete, class: "btn btn-default", data: { confirm: "Are you sure?" }
