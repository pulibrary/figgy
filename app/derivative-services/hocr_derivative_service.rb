# frozen_string_literal: true
class HocrDerivativeService
  class Factory
    attr_reader :change_set_persister
    delegate :metadata_adapter, :storage_adapter, to: :change_set_persister
    delegate :query_service, to: :metadata_adapter
    def initialize(change_set_persister:)
      @change_set_persister = change_set_persister
    end

    def new(change_set)
      HocrDerivativeService.new(change_set: change_set, change_set_persister: change_set_persister, original_file: original_file(change_set.resource))
    end

    def original_file(resource)
      resource.original_file
    end
  end

  attr_reader :change_set, :change_set_persister, :original_file
  delegate :mime_type, to: :original_file
  delegate :resource, to: :change_set
  delegate :metadata_adapter, :storage_adapter, to: :change_set_persister
  delegate :query_service, to: :metadata_adapter
  def initialize(change_set:, change_set_persister:, original_file:)
    @change_set = change_set
    @change_set_persister = change_set_persister
    @original_file = original_file
  end

  def valid?
    ['image/tiff', 'image/jpeg'].include?(mime_type.first)
  end

  def create_derivatives
    run_derivatives
    change_set.hocr_content = created_file.read
    change_set.ocr_content = ActionView::Base.full_sanitizer.sanitize(change_set.hocr_content).split("\n").map(&:strip).select(&:present?).join(" ")
    FileUtils.rm_f(created_file.path)
    change_set.sync
    change_set_persister.buffer_into_index do |buffered_persister|
      buffered_persister.save(change_set: change_set)
    end
  end

  # No cleanup necessary - all this does is set a property on FileSet.
  def cleanup_derivatives; end

  def parent
    @parent ||= query_service.find_parents(resource: change_set.resource).first
  end

  def run_derivatives
    system("tesseract", filename.to_s, temporary_output.path.to_s, "-l #{parent.ocr_language.join('+')}", "hocr", out: File::NULL, err: File::NULL)
  end

  def temporary_output
    @temporary_file ||= Tempfile.new
  end

  def created_file
    @created_file ||= File.open("#{temporary_output.path}.hocr")
  end

  def filename
    return Pathname.new(file_object.io.path) if file_object.io.respond_to?(:path) && File.exist?(file_object.io.path)
  end

  def file_object
    @file_object ||= Valkyrie::StorageAdapter.find_by(id: original_file.file_identifiers[0])
  end
end
