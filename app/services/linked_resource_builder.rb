# frozen_string_literal: true
class LinkedResourceBuilder
  ##
  # @param [Resource] resource the Resource subject
  def initialize(resource:)
    @factory = LinkedResourceFactory.new(resource: resource)
  end

  ##
  # Build the JSON-LD-serialized resource instance
  # @return [JSON]
  def build
    linked_resource.to_json
  end

  private

    def linked_resource
      @linked_resource ||= @factory.new
    end
end
