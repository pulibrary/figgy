class GeoPyramidalDerivativeService < VipsDerivativeService
  attr_reader :source_path
  def initialize(id:, change_set_persister:, source_path: nil)
    @source_path = source_path
    super(id: id, change_set_persister: change_set_persister)
  end

  def valid?
    source_path.present? && File.exist?(source_path)
  end

  def filename
    Pathname.new(source_path)
  end

  def compression
    :deflate
  end

  def derivative_filename
    "thumbnail.tif"
  end

  # No scaling needed
  def resize(image)
    image
  end
end
