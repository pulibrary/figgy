# frozen_string_literal: true
class Valkyrie::ResourceDecorator < ApplicationDecorator
  self.display_attributes = [:internal_resource, :created_at, :updated_at]

  def created_at
    super.strftime("%D %r %Z")
  end

  def updated_at
    super.strftime("%D %r %Z")
  end

  def header
    title.to_sentence
  end

  def manageable_files?
    true
  end
end
