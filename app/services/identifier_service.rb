# frozen_string_literal: true
class IdentifierService
  def self.mint_or_update(resource:)
    if resource.respond_to?(:geo_resource?) && resource.geo_resource?
      mint_or_update_geo_resource(resource)
    elsif resource.identifier.present?
      update_metadata resource
    else
      assign_new_identifier(resource)
    end
  end

  def self.get_ark_result(ark:)
    return "" if ark.blank?
    initial_result = Faraday.head("http://arks.princeton.edu/#{ark}")
    return "" unless initial_result.status == 301
    final_result = Faraday.head(initial_result.headers["location"])
    return "" unless final_result.status == 302
    final_result.headers["location"]
  end

  def self.url_for(resource)
    return Rails.application.routes.url_helpers.solr_document_url(resource, host: Figgy.default_url_options[:host]) if resource.try(:source_metadata_identifier).blank?
    return "https://catalog.princeton.edu/catalog/#{resource.source_metadata_identifier.first}#view" if PulMetadataServices::Client.bibdata?(resource.source_metadata_identifier.first)
    "http://findingaids.princeton.edu/collections/#{resource.source_metadata_identifier.first.tr('_', '/')}"
  end

  private_class_method def self.mint_identifier(resource)
    resource_metadata = metadata(resource)
    minted = minter.mint(resource_metadata)
    minted.id
  end

  private_class_method def self.assign_new_identifier(resource)
    resource.identifier = mint_identifier(resource)
  end

  private_class_method def self.update_metadata(resource)
    return if minter_user == "apitest"
    ark = Array.wrap(resource.identifier).first
    minter.modify(ark, metadata(resource)) unless get_ark_result(ark: ark).to_s.include?("findingaids")
  end

  private_class_method def self.metadata(resource)
    {
      dc_publisher: "Princeton University Library",
      dc_title: resource.title.join("; "),
      dc_type: "Text",
      target: url_for(resource)
    }
  end

  private_class_method def self.geo_metadata(resource)
    slug = "princeton-#{resource.identifier.first.gsub(%r(ark:/\d{5}/), '')}"
    metadata(resource).merge(target: "https://maps.princeton.edu/catalog/#{slug}")
  end

  private_class_method def self.mint_or_update_geo_resource(resource)
    assign_new_identifier(resource) if resource.identifier.blank?
    update_geo_metadata resource
  end

  private_class_method def self.update_geo_metadata(resource)
    return if minter_user == "apitest"
    ark = Array.wrap(resource.identifier).first
    minter.modify(ark, geo_metadata(resource))
  end

  private_class_method def self.minter_user
    Ezid::Client.config.user
  end

  private_class_method def self.minter
    Ezid::Identifier
  end
end
