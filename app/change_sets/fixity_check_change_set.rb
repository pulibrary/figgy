# frozen_string_literal: true
class FixityCheckChangeSet < Valkyrie::ChangeSet
  property :file_set_id, multiple: false, required: true
  property :file_id, multiple: false, required: true
  property :expected_checksum, multiple: false
  property :actual_checksum, multiple: false
  property :success, multiple: false
  property :last_success_date, multiple: false
end
