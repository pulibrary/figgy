# frozen_string_literal: true
class UniqueArchivalMediaBarcodeValidator < ActiveModel::Validator
  attr_reader :record

  def validate(record)
    # Validators aren't instantiated at the instance level to check if
    # something's valid, so delegate to a class which is and can use instance
    # variables.
    Checker.new(record: record).validate!
  end

  class Checker
    attr_reader :record
    def initialize(record:)
      @record = record
    end

    def validate!
      return if duplicates.empty?
      record.errors.add(:bag_path, "The following barcodes have already been imported to this object. Delete their file sets to reingest: #{previously_imported}")
    end

    private

      def duplicates
        files_to_import & previously_imported
      end

      def files_to_import
        # might be nil (in tests) or "" (coming from form)
        return [] if record.bag_path.blank?
        bag.barcodes
      end

      def previously_imported
        return [] if record.model.id.nil? # it's a new resource
        @previously_imported ||=
          begin
            decorator.members.flat_map do |component_id_resource|
              Wayfinder.for(component_id_resource).members.flat_map(&:local_identifier)
            end
          end
      end

      def decorator
        @decorator ||= record.model.decorate
      end

      def bag
        @bag ||= ArchivalMediaBagParser.new(path: Pathname.new(record.bag_path), component_id: record.source_metadata_identifier)
      end
  end
end
