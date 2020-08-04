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
    valid_mime_types.include?(mime_type.first)
  end

  def create_derivatives
    tiffs = convert_pages
    add_file_sets(tiffs)
    update_pdf_use
  end

  def update_pdf_use
    # pull the resource again to prevent StaleObjectError from when its parent
    # was saved
    pdf_file_set = query_service.find_by(id: id)
    pdf_file_metadata = pdf_file_set.file_metadata.select { |f| f.use == [Valkyrie::Vocab::PCDMUse.OriginalFile] }.select(&:pdf?).first
    return unless pdf_file_metadata

    pdf_file_metadata.use = [Valkyrie::Vocab::PCDMUse.PreservationMasterFile]
    pdf_file_set.file_metadata = pdf_file_set.file_metadata.select { |x| x.id != pdf_file_metadata.id } + [pdf_file_metadata]
    persister.save(resource: pdf_file_set)
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

  # Delete the filesets that were generated from the pdf.
  def cleanup_derivatives
    intermediate_derivatives = Wayfinder.for(parent).members.select do |member|
      member.intermediate_files.present? && member.primary_file.original_filename.first.starts_with?("converted_from_pdf")
    end
    intermediate_derivatives.each { |fs| cleanup_file_set(fs) }
  end

  def cleanup_file_set(file_set)
    change_set = ChangeSet.for(file_set)
    change_set_persister.delete(change_set: change_set)
  end

  def valid_mime_types
    ["application/pdf"]
  end

  def target_file
    @target_file ||= resource.primary_file
  end

  def resource
    @resource ||= query_service.find_by(id: id)
  end

  def convert_pages
    files = []
    page = 0
    loop do
      image = convert_page(page: page)
      break unless image
      page += 1
      files << build_file(page, image)
    end
    files
  end

  def build_file(page, file_path)
    IngestableFile.new(
      file_path: file_path,
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
    location = temporary_output(page).path.to_s
    vips_image.tiffsave(location)
    location
  rescue Vips::Error => error
    return nil if error.message.strip == "pdfload: pages out of range"
    update_error_message(message: error.message)
    raise error
  end

  def temporary_output(page)
    Tempfile.new(["intermediate_file#{page}", ".tif"])
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

  # Updates error message property on the primary file.
  def update_error_message(message:)
    primary_file = resource.primary_file
    primary_file.error_message = [message]
    resource.file_metadata = resource.file_metadata.select { |x| x.id != primary_file.id } + [primary_file]
    persister.save(resource: resource)
  end
end
