# frozen_string_literal: true
class IdentifierService
  def self.mint_or_update(resource:)
    if identifier_for(resource).present?
      update_metadata resource
    else
      mint_identifier resource
    end
  end

  private_class_method def self.identifier_for(resource)
    return resource.identifier if resource.identifier.present?
    return unless resource.respond_to? :imported_metadata
    ark_url = resource.imported_metadata&.first&.identifier&.first
    ark_url&.gsub(/.*ark:/, "ark:")
  end

  private_class_method def self.update_metadata(resource)
    return if minter_user == "apitest"
    minter.modify(Array.wrap(identifier_for(resource)).first, metadata(resource))
  end

  private_class_method def self.mint_identifier(resource)
    resource.identifier = minter.mint(metadata(resource)).id
  end

  private_class_method def self.metadata(resource)
    {
      dc_publisher: 'Princeton University Library',
      dc_title: resource.title.join('; '),
      dc_type: 'Text',
      target: url_for(resource)
    }
  end

  private_class_method def self.url_for(resource)
    return Rails.application.routes.url_helpers.solr_document_url(resource, host: Figgy.default_url_options[:host]) if resource.try(:source_metadata_identifier).blank?
    return "https://catalog.princeton.edu/catalog/#{resource.source_metadata_identifier.first}#view" if PulMetadataServices::Client.bibdata?(resource.source_metadata_identifier.first)
    "http://findingaids.princeton.edu/collections/#{resource.source_metadata_identifier.first.tr('_', '/')}"
  end

  private_class_method def self.minter_user
    Ezid::Client.config.user
  end

  private_class_method def self.minter
    Ezid::Identifier
  end
end
