# frozen_string_literal: true

class DeletionMarkerChangeSet < ChangeSet
  property :resource_id
  property :resource_title
  property :original_filename
  property :preservation_object
  property :parent_id

  def preserve?
    false
  end
end
