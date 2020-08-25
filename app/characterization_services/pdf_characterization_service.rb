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
    primary_file.checksum = MultiChecksum.for(file_object)
    primary_file.page_count = pdf_page_count
    @file_set = persister.save(resource: file_set) if save
    file_set
  end

  def pdf_page_count
    @pdf_page_count ||= Vips::Image.pdfload(file_object.disk_path.to_s, access: :sequential, memory: true).get_value("pdf-n_pages")
  end

  def file_object
    @file_object ||= Valkyrie::StorageAdapter.find_by(id: primary_file.file_identifiers[0])
  end
end
