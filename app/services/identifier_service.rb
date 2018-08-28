# frozen_string_literal: true
class IdentifierService
  def self.mint_or_update(resource:)
    if resource.identifier.present?
      update_metadata resource
    else
      mint_identifier resource
    end
  end

  def self.get_ark_result(ark:)
    return "" unless ark.present?
    initial_result = Faraday.head("http://arks.princeton.edu/#{ark}")
    return "" unless initial_result.status == 301
    final_result = Faraday.head(initial_result.headers["location"])
    return "" unless final_result.status == 302
    final_result.headers["location"]
  end

  class RestrictedArkError < StandardError; end

  private_class_method def self.update_metadata(resource)
    return if minter_user == "apitest"
    ark = Array.wrap(resource.identifier).first
    if get_ark_result(ark: ark).to_s.include?("findingaids")
      raise RestrictedArkError, "Unable to update ARK #{ark}: it points to a Finding Aid URL. Change the identifier before marking this item complete."
    end
    minter.modify(ark, metadata(resource))
  end

  private_class_method def self.mint_identifier(resource)
    resource.identifier = minter.mint(metadata(resource)).id
  end

  private_class_method def self.metadata(resource)
    {
      dc_publisher: "Princeton University Library",
      dc_title: resource.title.join("; "),
      dc_type: "Text",
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
