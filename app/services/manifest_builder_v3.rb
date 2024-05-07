# frozen_string_literal: true
class ManifestBuilderV3
  attr_reader :resource, :services

  # @param [Resource] resource the Resource subject
  def initialize(resource, auth_token = nil, current_ability = nil)
    @resource = RootNode.for(resource, auth_token, current_ability)
  end

  # Build the JSON-serialized Manifest instance
  # @return [JSON]
  def build
    JSON.parse(manifest.to_json, symbolize_keys: true)
  end

  private

    # Instantiate the Manifest
    # @return [IIIFManifest]
    def manifest
      @manifest ||= IIIFManifest::V3::ManifestFactory.new(@resource, manifest_service_locator: ManifestServiceLocator).to_h
    end
end
