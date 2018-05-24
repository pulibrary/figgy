# frozen_string_literal: true
class UniqueArchivalMediaBarcodeValidator < ActiveModel::Validator
  attr_reader :record

  def validate(record)
    @record = record
    return if duplicates.empty?
    record.errors.add(:bag_path, "The following barcodes have already been imported to this object. Delete their file sets to reingest: #{previously_imported}")
  end

  private

    def duplicates
      files_to_import & previously_imported
    end

    def files_to_import
      return [] if record.bag_path.nil?
      bag.file_groups.keys
    end

    def previously_imported
      return [] if record.model.id.nil? # it's a new resource
      decorator.media_resources.map { |resource| resource.decorate.file_sets }.flatten.map { |file_set| "#{file_set.barcode.first}_#{file_set.part.first}" }
    end

    def decorator
      @decorator ||= record.model.decorate
    end

    def bag
      @bag ||= ArchivalMediaBagParser.new(path: Pathname.new(record.bag_path), component_id: record.source_metadata_identifier)
    end
end
