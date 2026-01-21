class SeleneIndexer
  attr_reader :resource
  def initialize(resource:)
    @resource = resource
  end

  def to_solr
    return {} unless resource.try(:selene?)
    {
      parent_title_ssi: scanned_resource_title,
      source_metadata_identifier_ssim: source_metadata_identifier
    }
  end

  def scanned_resource_title
    return unless scanned_resource
    TitleIndexer.new(resource: scanned_resource).title_strings.first
  end

  def source_metadata_identifier
    return unless scanned_resource
    scanned_resource.source_metadata_identifier
  end

  def scanned_resource
    @scanned_resource ||= begin
                            return unless file_set
                            Wayfinder.for(file_set).parent
                          end
  end

  def file_set
    @file_set ||= Wayfinder.for(resource).parent
  end
end
