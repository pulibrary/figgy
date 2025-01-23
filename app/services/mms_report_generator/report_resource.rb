# frozen_string_literal: true
class MmsReportGenerator::ReportResource
  # Database fields we need to generate the fields for this report
  def self.resource_fields
    # [
    #   :id,
    #   :internal_resource,
    #   Sequel[:metadata].pg_jsonb["visibility"][0].as(:visibility),
    #   Sequel[:metadata].pg_jsonb["portion_note"][0].as(:portion_note),
    #   Sequel[:metadata].pg_jsonb["state"][0].as(:state),
    #   Sequel[:metadata].pg_jsonb["source_metadata_identifier"][0].as(:source_metadata_identifier)
    # ]
  end

  attr_reader :resource
  def initialize(resource)
    @resource = resource
  end

  def mms_id
    # resource[:source_metadata_identifier]
    resource.source_metadata_identifier.first
  end

  def public_readable?
    # resource[:state] == "complete" || resource[:state] == "flagged"
    resource.decorate.public_readable_state?
  end

  def to_hash
    {
      visibility: visibility,
      portion_note: Array.wrap(resource.portion_note).first,
      iiif_manifest_url: helper.manifest_url(resource)
    }
  end

  def visibility
    visibility_controlled_vocabulary = ControlledVocabulary.for(:visibility).find(resource.visibility.first)
    {
      value: visibility_controlled_vocabulary.value,
      label: visibility_controlled_vocabulary.label,
      definition: visibility_controlled_vocabulary.definition
    }
  end

  def helper
    @helper ||= ManifestBuilder::ManifestHelper.new
  end
end
