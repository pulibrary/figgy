# frozen_string_literal: true
class PDFDerivativeService
  class ZeroByteError < StandardError; end

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
    buffered do
      tiffs = convert_pages
      add_pages(tiffs)
      update_error_message(message: nil) if target_file.error_message.present?
    rescue StandardError => e
      change_set_persister.after_rollback.add do
        update_error_message(message: e.message)
      end
      raise e
    ensure
      FileUtils.remove_entry(tmpdir, true) if File.exist?(tmpdir)
    end
  end

  def buffered
    change_set_persister.buffer_into_index do |buffered_change_set_persister|
      old_persister = change_set_persister
      @change_set_persister = buffered_change_set_persister
      yield
      @change_set_persister = old_persister
    end
  end

  def add_pages(files)
    change_set.files = files.to_a
    change_set_persister.buffer_into_index do |buffered_persister|
      @resource = buffered_persister.save(change_set: change_set)
    end
  end

  def change_set
    @change_set ||= ChangeSet.for(resource)
  end

  def parent
    Wayfinder.for(resource).parent
  end

  # Delete the filesets that were generated from the pdf.
  # TODO: Also cleanup the old versions if they're around.
  def cleanup_derivatives
    deleted_file_metadata_identifiers = resource.derivative_partial_files.select(&:derivative_partial?).flat_map(&:file_identifiers)
    change_set.file_metadata = change_set.file_metadata.reject(&:derivative_partial?)
    buffered do
      @resource = change_set_persister.save(change_set: change_set)
    end
    CleanupFilesJob.perform_later(file_identifiers: deleted_file_metadata_identifiers.map(&:to_s))
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

  def page_slice
    50
  end

  def convert_pages
    image = Vips::Image.pdfload(filename, access: :sequential, memory: true)
    pages = image.get_value("pdf-n_pages")
    files = Array.new(pages).lazy.each_with_index.map do |_, page|
      location = temporary_output(page).to_s
      generate_pdf_image(filename, location, page)
    end
    files
  end

  def generate_pdf_image(filename, location, page)
    FiggyUtils.with_rescue([PDFDerivativeService::ZeroByteError], retries: 1) do
      convert_pdf_page(filename, location, page)
    end
  end

  def convert_pdf_page(filename, location, page)
    image = Vips::Image.pdfload(filename, access: :sequential, page: page, n: 1)
    VipsDerivativeService.save_tiff(image, location.to_s)
    raise(PDFDerivativeService::ZeroByteError, "Failed to generate PDF derivative #{location} - page #{page}.") if File.size(location).zero?
    build_file(image, page + 1, location)
  end

  def build_file(image, page, file_path)
    upload_options = {
      metadata: {
        "width" => image.width.to_s,
        "height" => image.height.to_s
      }
    }

    IngestableFile.new(
      file_path: file_path.to_s,
      mime_type: "image/tiff",
      original_filename: "page_#{page}.tif",
      use: ::PcdmUse::ServiceFilePartial,
      upload_options: upload_options,
      node_attributes: { page: page, label: pad_with_zeroes(page), width: image.width.to_s, height: image.height.to_s }
    )
  end

  def pad_with_zeroes(n)
    format("%08d", n)
  end

  def tmpdir
    @tmpdir ||= Pathname.new(FileUtils.mkdir_p("#{Dir.tmpdir}/derivative_generation/pdf-#{SecureRandom.uuid}").first)
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
