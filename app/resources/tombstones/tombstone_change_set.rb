# frozen_string_literal: true

class TombstoneChangeSet < ChangeSet
  property :file_set_id
  property :file_set_title
  property :file_set_original_filename
  property :preservation_object
end
