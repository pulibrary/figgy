# frozen_string_literal: true

class Slug
  attr_reader :slug
  def initialize(slug)
    @slug = slug
  end

  def valid?
    slug.present? && !/^[a-zA-Z0-9_\-]+$/.match(slug).nil?
  end
end
