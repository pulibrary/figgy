# frozen_string_literal: true

class PDFCharacterizationService
  def self.supported_formats
    ["application/pdf"]
  end

  attr_reader :file_set, :persister
  delegate :primary_file, to: :file_set

  # Constructor
  # @param file_set [FileSet] FileSet being characterized
  # @param persister [Valkyrie::MetadataAdapter::Persister] persister for the file_set
  def initialize(file_set:, persister:)
    @file_set = file_set
    @persister = persister
  end

  def valid?
    !(file_set.mime_type & self.class.supported_formats).empty?
  end

  # @return [FileSet]
  def characterize(save: true)
    [:original_file, :intermediate_file, :preservation_file].each do |type|
      target_file = @file_set.try(type)
      next unless target_file
      @file_object = Valkyrie::StorageAdapter.find_by(id: target_file.file_identifiers[0])
      target_file.checksum = MultiChecksum.for(@file_object)
      target_file.page_count = pdf_page_count
      @file_set.file_metadata = @file_set.file_metadata.select { |x| x.id != target_file.id } + [target_file]
    end
    @file_set = persister.save(resource: @file_set) if save
    @file_set
  end

  def pdf_page_count
    @pdf_page_count ||= Vips::Image.pdfload(@file_object.disk_path.to_s, access: :sequential, memory: true).get_value("pdf-n_pages")
  end
end
