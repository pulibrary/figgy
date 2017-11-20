# frozen_string_literal: true
class PDFGenerator
  attr_reader :resource, :storage_adapter
  def initialize(resource:, storage_adapter:)
    @resource = resource
    @storage_adapter = storage_adapter
  end

  def render
    CoverPageGenerator.new(self).apply(prawn_document)
    canvas_downloaders.each_with_index do |downloader, _index|
      prawn_document.start_new_page layout: downloader.layout
      page_size = [Canvas::LETTER_WIDTH, Canvas::LETTER_HEIGHT]
      page_size.reverse! unless downloader.portrait?
      prawn_document.image downloader.download, width: downloader.width, height: downloader.height, fit: page_size
    end
    prawn_document.render_file(tmp_file.path)
    build_node
  end

  def build_node
    file = IngestableFile.new(file_path: tmp_file.path, mime_type: 'application/pdf', original_filename: 'derivative_pdf.pdf')
    node = FileMetadata.for(file: file).new(id: SecureRandom.uuid)
    stored_file = storage_adapter.upload(resource: node, file: file, original_filename: Array.wrap(node.original_filename).first)
    node.file_identifiers = stored_file.id
    node
  end

  def prawn_document
    @prawn_document ||= Prawn::Document.new(prawn_options)
  end

  def prawn_options
    default_options = { margin: 0 }
    default_options[:page_layout] = :portrait if canvas_downloaders.first
    default_options
  end

  def canvas_images
    @canvas_images ||= manifest['sequences'][0]['canvases'].map { |x| x['images'][0] }.map do |x|
      Canvas.new(x)
    end
  end

  def manifest
    @manifest ||= ManifestBuilder.new(resource).build
  end

  def canvas_downloaders
    @canvas_images ||= canvas_images.map do |image|
      CanvasDownloader.new(image, quality: resource.pdf_type.first)
    end
  end

  def tmp_file
    @tmp_file ||= Tempfile.new("pdf")
  end
end
