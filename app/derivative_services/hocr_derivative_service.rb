# frozen_string_literal: true

class HocrDerivativeService
  class Factory
    attr_reader :change_set_persister, :processor_factory
    delegate :metadata_adapter, :storage_adapter, to: :change_set_persister
    delegate :query_service, to: :metadata_adapter
    def initialize(change_set_persister:, processor_factory: TesseractProcessor)
      @change_set_persister = change_set_persister
      @processor_factory = processor_factory
    end

    def new(id:)
      HocrDerivativeService.new(change_set_persister: change_set_persister, processor_factory: processor_factory, id: id)
    end
  end

  attr_reader :change_set_persister, :processor, :id
  delegate :mime_type, to: :primary_file
  delegate :resource, to: :change_set
  delegate :metadata_adapter, :storage_adapter, to: :change_set_persister
  delegate :query_service, to: :metadata_adapter
  delegate :primary_file, to: :resource
  def initialize(change_set_persister:, processor_factory:, id:)
    @change_set_persister = change_set_persister
    @id = id
    @processor = processor_factory.new(ocr_language: parent.ocr_language, file_path: filename)
  end

  def valid?
    ["image/tiff", "image/jpeg", "image/png"].include?(mime_type.first)
  end

  def resource
    @resource ||= query_service.find_by(id: id)
  end

  def create_derivatives
    result = processor.run!
    change_set_persister.buffer_into_index do |buffered_persister|
      reloaded = buffered_persister.query_service.find_by(id: id)
      reloaded_change_set = ChangeSet.for(reloaded)
      reloaded_change_set.hocr_content = result.hocr_content
      reloaded_change_set.ocr_content = result.ocr_content
      @resource = buffered_persister.save(change_set: reloaded_change_set)
    end
  end

  # No cleanup necessary - all this does is set a property on FileSet.
  def cleanup_derivatives
  end

  def parent
    @parent ||= Wayfinder.for(resource).parent
  end

  def filename
    return Pathname.new(file_object.io.path) if file_object.io.respond_to?(:path) && File.exist?(file_object.io.path)
  end

  def file_object
    @file_object ||= Valkyrie::StorageAdapter.find_by(id: primary_file.file_identifiers[0])
  end

  class TesseractProcessor
    attr_reader :ocr_language, :file_path
    def initialize(ocr_language:, file_path:)
      @ocr_language = ocr_language
      @file_path = file_path
    end

    def run!
      run_derivatives
      Result.new(hocr_content: created_file.read).tap do
        FileUtils.rm_f(created_file)
      end
    end

    class Result
      attr_reader :hocr_content
      def initialize(hocr_content:)
        @hocr_content = hocr_content
      end

      def ocr_content
        @ocr_content ||= ActionView::Base.full_sanitizer.sanitize(hocr_content).split("\n").map(&:strip).select(&:present?).join("\n")
      end
    end

    private

      def run_derivatives
        system("tesseract", file_path.to_s, temporary_output.path.to_s, "-l", ocr_language.join("+").to_s, "hocr", out: File::NULL, err: File::NULL)
      end

      def temporary_output
        @temporary_file ||= Tempfile.new
      end

      def created_file
        @created_file ||= File.open("#{temporary_output.path}.hocr")
      end
  end
end
