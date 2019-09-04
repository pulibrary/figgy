# frozen_string_literal: true

class TombstoneChangeSet < ChangeSet
  property :resource_id
  property :resource_title
  property :resource_original_filename
  property :preservation_object
  property :parent_id
end
