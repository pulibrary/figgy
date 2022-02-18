# frozen_string_literal: true

class UniqueSlugValidator < ActiveModel::Validator
  def validate(record)
    unless Slug.new(Array.wrap(record.slug).first).valid?
      record.errors.add(:slug, "contains invalid characters, please only use alphanumerics, dashes, and underscores")
    end

    return if find_duplicates(record).empty?
    record.errors.add(:slug, "is already in use by another collection")
  end

  private

    def find_duplicates(record)
      slug = Array.wrap(record.slug).first
      query_service.custom_queries.find_by_property(property: :slug, value: slug).select { |r| r.id != record.id }
    end

    def query_service
      Valkyrie.config.metadata_adapter.query_service
    end
end
