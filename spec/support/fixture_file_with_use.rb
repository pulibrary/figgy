# frozen_string_literal: true
module FixtureFileWithUse
  def fixture_file_with_use(file, mime_type = nil, use = Valkyrie::Vocab::PCDMUse.OriginalFile)
    file_path = Rails.root.join("spec", "fixtures", file)
    file = Rack::Test::UploadedFile.new(file_path, mime_type)
    original_filename = File.basename(file_path)
    IoDecorator.new(file, original_filename, mime_type, use)
  end

  class IoDecorator < SimpleDelegator
    attr_reader :original_filename, :content_type, :use

    # @param [IO] io stream for the file content
    # @param [String] original_filename
    # @param [String] content_type
    # @param [RDF::URI] use the URI for the PCDM predicate indicating the use for this resource
    def initialize(io, original_filename, content_type, use)
      @original_filename = original_filename
      @content_type = content_type
      @use = use
      super(io)
    end
  end
end
