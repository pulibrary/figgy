# frozen_string_literal: true
class PDFDerivativeService
  class Factory
    attr_reader :change_set_persister
    def initialize(change_set_persister:)
      @change_set_persister = change_set_persister
    end

    def new(id:)
      PDFDerivativeService.new(id: id, change_set_persister: change_set_persister)
    end
  end

  attr_reader :change_set_persister, :id
  delegate :mime_type, to: :target_file
  delegate :query_service, to: :change_set_persister
  def initialize(id:, change_set_persister:)
    @id = id
    @change_set_persister = change_set_persister
  end

  def valid?
    valid_mime_types.include?(mime_type.first) && !resource.preservation_file.nil?
  end

  def create_derivatives
    tiffs = convert_pages
    add_file_sets(tiffs)
    update_pdf_use
  end

  def update_pdf_use
    cached_resource = resource
    pdf_file_metadata = cached_resource.file_metadata.select { |f| f.use == [Valkyrie::Vocab::PCDMUse.OriginalFile] }.select(&:pdf?).first
    return unless pdf_file_metadata

    pdf_file_metadata.use = [Valkyrie::Vocab::PCDMUse.PreservationMasterFile]
    cached_resource.file_metadata = cached_resource.file_metadata.select { |x| x.id != pdf_file_metadata.id } + [pdf_file_metadata]
    persister.save(resource: cached_resource)
  end

  def add_file_sets(files)
    change_set = parent_change_set
    change_set.validate(files: files)
    change_set_persister.save(change_set: change_set)
  end

  def parent_change_set
    ChangeSet.for(parent)
  end

  def parent
    Wayfinder.for(resource).parent
  end

  def cleanup_derivatives
    # TODO: this should delete the filesets that were generated from the pdf.
    # This means we should split pdf pages from an original file or a
    # preservation master, so that derivatives can be re-generated.
    nil
  end

  def valid_mime_types
    ["application/pdf"]
  end

  def target_file
    @target_file ||= resource.original_file
  end

  # don't memoize; it needs to be reloaded to save correctly
  def resource
    query_service.find_by(id: id)
  end

  # TODO: it would be better to just know how many pages are in the pdf
  def convert_pages
    files = []
    page = 0
    loop do
      image = convert_page(page: page)
      break unless image
      page += 1
      files << build_file(page)
    end
    files
  end

  def build_file(page)
    IngestableFile.new(
      file_path: temporary_output(page).path.to_s,
      mime_type: "image/tiff",
      use: Valkyrie::Vocab::PCDMUse.IntermediateFile,
      original_filename: "converted_from_pdf_page_#{page}.tiff",
      container_attributes: {
        title: page # TODO: pad with 0s?
      }
    )
  end

  def convert_page(page:)
    vips_image = Vips::Image.pdfload(filename, page: page)
    vips_image.tiffsave(
      temporary_output(page).path.to_s
    )
    true
  # Vips::Error: pdfload: pages out of range
  rescue Vips::Error
    Rails.logger.info "vips error page #{page}"
    nil
  end

  def temporary_output(page)
    @temporary_file ||= Tempfile.new(["intermediate_file#{page}", ".tif"])
  end

  def filename
    Pathname.new(file_object.disk_path).to_s
  end

  def file_object
    @file_object ||= Valkyrie::StorageAdapter.find_by(id: target_file.file_identifiers[0])
  end

  def persister
    change_set_persister.metadata_adapter.persister
  end
end
