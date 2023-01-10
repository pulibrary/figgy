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
    update_pdf_use
    tiffs = convert_pages
    add_file_sets(tiffs)
  rescue StandardError => e
    update_error_message(message: e.message)
    raise e
  ensure
    FileUtils.remove_entry(tmpdir, true) if File.exist?(tmpdir)
  end

  def add_file_sets(files)
    resource = parent
    change_set_persister.buffer_into_index do |buffered_change_set_persister|
      files.each_slice(200) do |file_slice|
        change_set = ChangeSet.for(resource)
        change_set.validate(files: file_slice)
        resource = buffered_change_set_persister.save(change_set: change_set)
      end
    end
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
    image = Vips::Image.pdfload(filename, access: :sequential, memory: true)
    pages = image.get_value("pdf-n_pages")
    files = Array.new(pages).lazy.each_with_index.map do |_, page|
      # Ruby's set to mark and sweep for GC, and we can't explicitly close VIPS
      # references. The file handles aren't freed up until the garbage collector
      # runs, but it's 4 handles per VIPS access. So force a GC to keep the
      # handles low.
      # See https://github.com/libvips/ruby-vips/issues/67
      GC.start
      page_image = Vips::Image.new_from_file(filename, access: :sequential, memory: true, page: page, dpi: 300)
      location = temporary_output(page).to_s
      page_image.tiffsave(location)
      build_file(page + 1, location)
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
        title: pad_with_zeroes(page)
      },
      copyable: true
    )
  end

  def pad_with_zeroes(n)
    format("%08d", n)
  end

  def tmpdir
    @tmpdir ||= Pathname.new(Dir.mktmpdir("pdf_derivatives"))
  end

  def temporary_output(page)
    tmpdir.join("intermediate_file#{page}.tif")
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

  def update_pdf_use
    pdf_file_metadata = resource.file_metadata.select { |f| f.use == [Valkyrie::Vocab::PCDMUse.OriginalFile] }.find(&:pdf?)
    return unless pdf_file_metadata

    pdf_file_metadata.use = [Valkyrie::Vocab::PCDMUse.PreservationFile]
    resource.file_metadata = resource.file_metadata.select { |x| x.id != pdf_file_metadata.id } + [pdf_file_metadata]
    persister.save(resource: resource)
  end

  # Updates error message property on the primary file.
  def update_error_message(message:)
    # refresh the resource to prevent StaleObjectError from update_pdf_use
    file_set = query_service.find_by(id: id)
    primary_file = file_set.primary_file
    primary_file.error_message = [message]
    file_set.file_metadata = file_set.file_metadata.select { |x| x.id != primary_file.id } + [primary_file]
    persister.save(resource: file_set)
  end
end
