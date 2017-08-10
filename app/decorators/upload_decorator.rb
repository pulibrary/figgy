# frozen_string_literal: true
class UploadDecorator < Draper::Decorator
  attr_reader :original_filename
  delegate_all
  def initialize(file, original_filename)
    super(file)
    @original_filename = original_filename
  end
end
