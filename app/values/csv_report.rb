# frozen_string_literal: true
# Convert an enumerable of resources into a CSV by converting it to a hash,
# merging in imported properties, and selecting each property as a field. Right
# now useful for ad-hoc reports, but could be used as a tool for generic report
# generation.
class CSVReport
  attr_reader :resources, :fields
  # @param resources [Enumerable<Valkyrie::Resource>] resources to convert to a
  #   CSV
  # @param fields [Array<Symbol>] fields which act as the header of the CSV
  def initialize(resources, fields: [:title])
    @resources = resources
    @fields = fields
  end

  def csv_rows
    @csv_rows ||= resources.lazy.map do |resource|
      Row.new(resource, fields: fields)
    end
  end

  def write(path:)
    CSV.open(path, "w") do |csv|
      csv << headers
      csv_rows.each do |row|
        csv << row.to_h.values_at(*fields)
      end
    end
  end

  def headers
    fields.map(&:to_s).map(&:humanize)
  end

  def to_csv
    CSV.generate(headers: true) do |csv|
      csv << fields.map { |_k, v| v }
      resources.each do |record|
        csv << fields.map { |k, _v| values_or_labels(record, k) }
      end
    end
  end

  def hashes_to_csv
    CSV.generate(headers: true) do |csv|
      csv << fields
      resources.each do |h|
        csv << fields.map { |field| h[field.to_sym] }
      end
    end
  end

  class Row
    attr_reader :resource, :fields
    def initialize(resource, fields: [])
      @resource = resource
      @fields = fields
    end

    def to_h
      Hash[
        # __attributes__ is much faster and doesn't include nil values.
        resource.__attributes__.merge(attributes_without_reserved(imported_metadata)).map do |key, values|
          values = Array.wrap(values).map(&:to_s).join(", ")
          [key, values]
        end
      ].merge(special_fields)
    end

    def special_fields
      {}.tap do |hsh|
        if fields.include?(:collections)
          hsh[:collections] = Wayfinder.for(resource).try(:collections)&.map(&:decorate)&.map(&:title)&.join(", ")
        end
        if fields.include?(:file_count)
          hsh[:file_count] = Wayfinder.for(resource).try(:file_sets_count)
        end
        if fields.include?(:vocabulary_breadcrumbs)
          hsh[:vocabulary_breadcrumbs] = vocabulary_breadcrumbs(resource)
        end
      end
    end

    def vocabulary_breadcrumbs(resource)
      parent_vocab = Wayfinder.for(resource).try(:vocabularies)&.first
      grandparent_vocab = Wayfinder.for(parent_vocab).try(:parent_vocabularies)&.first
      [parent_vocab, grandparent_vocab].compact.reverse.map(&:label).join(" | ")
    end

    # Only get the non-reserved attributes - gets rid of things like
    # internal_resource for merging purposes. Also gets rid of blank values to
    # make it safe for merging.
    def attributes_without_reserved(resource)
      resource.__attributes__.reject do |key, v|
        resource.class.reserved_attributes.include?(key) || v.blank?
      end
    end

    # Return the imported metadata or use a blank one as a null object.
    def imported_metadata
      Array.wrap(resource.try(:imported_metadata))[0] || ImportedMetadata.new
    end
  end

  private

    def values_or_labels(record, field)
      val = record.send(field)
      Array.wrap(val).map { |v| v.respond_to?(:label) ? v.label : v }.join(";")
    end
end
