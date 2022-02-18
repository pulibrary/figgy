# frozen_string_literal: true

# Model for exposing a IIIF Manifest describing all Collection resources
class IndexCollection
  # Decorates the object (as this is not a Valkyrie::Resource)
  # @return [IndexCollectionDecorator] an instance of the decorator
  def decorate
    IndexCollectionDecorator.new(self)
  end

  def logical_structure
    []
  end

  # @note Added for Valkyrie::Resource compatibility
  def to_model
    self
  end
end
