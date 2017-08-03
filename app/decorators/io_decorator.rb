# frozen_string_literal: true
class IoDecorator < SimpleDelegator
  attr_accessor :mime_type, :original_name, :container_attributes, :id

  def initialize(file:, mime_type: nil, original_name: nil, container_attributes: nil, id: nil)
    super(file)
    self.mime_type = mime_type
    self.original_name = original_name
    self.container_attributes = container_attributes
    self.id = id
  end

  def original_filename
    original_name
  end

  def content_type
    mime_type
  end
end
