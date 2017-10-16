# frozen_string_literal: true
# Model for exposing IIIF Manifests for all Collection resources
class IndexCollection
  # Decorates the object (as this is not a Valkyrie::Resource)
  # @return [IndexCollectionDecorator] an instance of the decorator
  def decorate
    IndexCollectionDecorator.new(self)
  end

  def logical_structure
    []
  end
end
