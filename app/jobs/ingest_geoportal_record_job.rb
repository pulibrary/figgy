# frozen_string_literal: true
class IngestGeoportalRecordJob < ApplicationJob
  # @param [String] fgdc_path File path to old geoportal FGDC document
  # @param [String] user User to ingest as
  # @param [String] ark Existing ARK ID, optional
  # @param [String] base_data_path Path to shapefile directory, optional
  def perform(fgdc_path:, user:, ark: nil, base_data_path: "/mnt/hydra_sources/maplab/geoportal/data")
    logger.info "Ingesting Geoportal Record #{fgdc_path}"
    @fgdc_path = fgdc_path
    @user = user
    @ark = ark
    @base_data_path = base_data_path

    return unless valid_record?
    return unless dataset_path

    changeset_persister.buffer_into_index do |buffered_persister|
      Ingester.for(fgdc_path: @fgdc_path, dataset_path: dataset_path, ark: @ark, user: @user, changeset_persister: buffered_persister).ingest
    end
  end

  def changeset_persister
    @changeset_persister ||= ChangeSetPersister.new(metadata_adapter: metadata_adapter,
                                                    storage_adapter: storage_adapter,
                                                    queue: queue_name)
  end

  def dataset_path
    path = onlink.gsub("http://map.princeton.edu/download/data", @base_data_path)
    return path if File.exist? path
  end

  def fgdc_doc
    @fgdc_doc ||= Nokogiri::XML(File.open(@fgdc_path).read)
  end

  def geoform
    node = fgdc_doc.at_xpath("//idinfo/citation/citeinfo/geoform")
    return nil if node.nil?
    node.text
  end

  def metadata_adapter
    Valkyrie::MetadataAdapter.find(:indexing_persister)
  end

  def onlink
    node = fgdc_doc.at_xpath("//idinfo/citation/citeinfo/onlink")
    return nil if node.nil?
    node.text
  end

  def storage_adapter
    Valkyrie::StorageAdapter.find(:disk_via_copy)
  end

  def valid_record?
    return true if geoform == "vector digital data"
  end

  class Ingester
    delegate :metadata_adapter, to: :changeset_persister
    delegate :query_service, to: :metadata_adapter
    def self.for(fgdc_path:, dataset_path:, ark:, user:, changeset_persister:)
      new(fgdc_path: fgdc_path, dataset_path: dataset_path, ark: ark, user: user, changeset_persister: changeset_persister)
    end

    attr_reader :fgdc_path, :user, :changeset_persister
    def initialize(fgdc_path:, dataset_path:, ark:, user:, changeset_persister:)
      @fgdc_path = fgdc_path
      @dataset_path = dataset_path
      @user = user
      @ark = ark
      @changeset_persister = changeset_persister
    end

    def ingest
      resource.title = geoportal_guid
      resource.identifier = @ark if @ark
      resource.local_identifier = geoportal_guid
      resource.visibility = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED
      resource.state = "final_review"
      resource.files = files
      output = changeset_persister.save(change_set: resource)
      extract_fgdc_metadata(output)
      mint_ark(output) unless @ark
      complete_record(output)
    rescue StandardError
      return false
    end

    def apply_attributes(change_set, attributes)
      attributes.each do |key, value|
        change_set.send("#{key}=".to_sym, value) if change_set.respond_to?(key)
      end
      changeset_persister.save(change_set: change_set)
    end

    def complete_record(output)
      new_resource = DynamicChangeSet.new(output)
      new_resource.state = "complete"
      changeset_persister.save(change_set: new_resource)
    end

    def extract_fgdc_metadata(output)
      new_resource = DynamicChangeSet.new(output)
      members = new_resource.model.decorate.members
      metadata_node = members.find { |m| m.original_file.original_filename == ["fgdc.xml"] }
      return unless metadata_node
      file_object = Valkyrie::StorageAdapter.find_by(id: metadata_node.original_file.file_identifiers[0])
      metadata_xml = Nokogiri::XML(file_object.read)
      attributes = GeoMetadataExtractor::Fgdc.new(metadata_xml).extract
      apply_attributes(new_resource, attributes)
    end

    def files
      [vector_file, fgdc_file]
    end

    def fgdc_file
      IngestableFile.new(
        file_path: @fgdc_path,
        mime_type: "application/xml",
        original_filename: "fgdc.xml"
      )
    end

    def geoportal_guid
      File.basename(@fgdc_path, ".*")
    end

    def mint_ark(output)
      new_resource = DynamicChangeSet.new(output)
      IdentifierService.mint_or_update(resource: new_resource.model) unless @ark
      changeset_persister.save(change_set: new_resource)
    end

    def resource
      @resource ||=
        begin
          DynamicChangeSet.new(VectorResource.new)
        end
    end

    def vector_file
      IngestableFile.new(
        file_path: @dataset_path,
        mime_type: "application/zip",
        original_filename: "shapefile.zip"
      )
    end
  end
end
